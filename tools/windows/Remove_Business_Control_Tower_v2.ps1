#requires -Version 5.1
<#
.SYNOPSIS
  Business Control Tower — complete removal, v2.1 (safe, auditable, recoverable).
.DESCRIPTION
  v2.1 changes after adversarial review (20 findings addressed):
    - Postgres dump via in-container file + docker cp (PS 5.1 pipeline corrupted UTF-8 dumps)
    - Backup failures now BLOCK destruction behind a typed confirmation (no timed-sleep "consent")
    - Stopped/renamed containers found via docker ps -a + compose project labels, started for dump
    - ALL project Docker volumes tar-exported before teardown (n8n credentials/workflows live there)
    - Task XMLs / service configs / startup registry values exported BEFORE removal
    - Env-var backup always taken (even with -SkipBackup), verified, and gates sensitive deletions
    - Process kill pattern narrowed (bare 'parity' no longer kills unrelated software)
    - robocopy /XJ + reparse-point pre-removal (junctions no longer follow outside the project)
    - wsl.exe UTF-16 output handled (WSL distro cleanup was a silent no-op)
    - Project zip via .NET ZipFile (hidden files included, >2GB supported), robocopy fallback
    - Elevated window pauses before closing; parent propagates the exit code
    - v1 coverage restored: bct_* startup items, Pause/Resume .cmd artifacts, Start Menu folders
.PARAMETER DryRun
  Preview mode. Detects and lists everything, changes nothing. RUN THIS FIRST.
.PARAMETER SkipBackup
  Skip the heavy backups (zip/dump/volumes). Env-var backup is still taken. Counts as explicit consent.
.PARAMETER RemoveSharedTools
  Also remove Docker Desktop, Ollama, Node, Python, Git, VS Code without the second interactive prompt.
.EXAMPLE
  .\Remove_Business_Control_Tower_v2.ps1 -DryRun      # ALWAYS do this first
  .\Remove_Business_Control_Tower_v2.ps1              # real removal, with full backup
#>
[CmdletBinding()]
param(
  [switch]$DryRun,
  [switch]$SkipBackup,
  [switch]$RemoveSharedTools,
  [switch]$Elevated   # internal: set when the script relaunches itself as admin
)

$ErrorActionPreference = 'Continue'
$Root        = 'D:\Business-Control-Tower'
$Desktop     = [Environment]::GetFolderPath('Desktop')
$Stamp       = Get-Date -Format 'yyyyMMdd_HHmmss'
$Log         = Join-Path $Desktop "BCT_Removal_$Stamp.log"
$BackupDir   = Join-Path $Desktop "BCT_Backup_$Stamp"
$CurrentPid  = $PID
$ComposeFile = Join-Path $Root '10_Docker\docker-compose.yml'
# compose default project name = lowercased directory containing the compose file
$ComposeProject = 'business-control-tower'
if(Test-Path $ComposeFile){ $ComposeProject = (Split-Path (Split-Path $ComposeFile -Parent) -Leaf).ToLower() }

# Detection pattern (tasks/shortcuts/services/audit): word-bounded Parity to avoid 'disparity' etc.
$NamePat = '(?i)\bBCT\b|bct[_-]|Business Control Tower|Business Tower|Business Rhythm|Business Followup|DivyaStones|\bParity\b'
$PathPat = '(?i)D:\\Business-Control-Tower|Business-Control-Tower|\bbct_|\bparity\b|DivyaStones'
# Kill pattern (process termination): strict — must reference the project path/prefix, never bare 'parity'
$KillPat = '(?i)D:\\Business-Control-Tower|Business-Control-Tower|\bbct_|DivyaStones'

$script:Counts       = @{}
$script:Warnings     = 0
$script:BackupIssues = @()
$script:EnvBackupOk  = $false

function Log([string]$Message,[string]$Level='INFO') {
  $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
  Add-Content -LiteralPath $Log -Value $line -Encoding UTF8
  $colors = @{INFO='White';OK='Green';WARN='Yellow';ERROR='Red';DRY='Cyan'}
  $color = $colors[$Level]; if(-not $color){ $color='White' }
  Write-Host $line -ForegroundColor $color
  if($Level -eq 'WARN' -or $Level -eq 'ERROR'){ $script:Warnings++ }
}

function Count([string]$Category){ if($script:Counts.ContainsKey($Category)){ $script:Counts[$Category]++ } else { $script:Counts[$Category]=1 } }

function Act([string]$What,[string]$Category,[scriptblock]$Do) {
  if($DryRun){ Log "WOULD REMOVE: $What" 'DRY'; Count $Category; return $true }
  try { & $Do; Log $What 'OK'; Count $Category; return $true }
  catch { Log ("FAILED: {0} -- {1}" -f $What, $_.Exception.Message) 'WARN'; return $false }
}

function Is-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Phase([string]$Title){ Write-Host ''; Write-Host ("== {0} ==" -f $Title) -ForegroundColor Magenta; Log ("PHASE: {0}" -f $Title) }

# ---------------------------------------------------------------- detection --

function Get-BctTasks {
  Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $a = ($_.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments) $($_.WorkingDirectory)" }) -join ' '
    ("$($_.TaskPath)$($_.TaskName)" -match $NamePat) -or ($a -match $PathPat)
  }
}

function Get-BctServices {
  Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | Where-Object {
    ($_.PathName -match $PathPat) -or ($_.DisplayName -match $NamePat)
  }
}

# Kill list: strict pattern + known host executables. Audit uses raw scan instead (see Final-Audit).
function Get-BctKillProcesses {
  Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessId -ne $CurrentPid -and
    $_.Name -match '^(powershell|pwsh|cmd|wscript|cscript|python|pythonw|node|codex|streamlit)\.exe$' -and
    $_.CommandLine -match $KillPat
  }
}

function Test-DockerUp {
  if(!(Get-Command docker -ErrorAction SilentlyContinue)){ return $false }
  & docker info *> $null
  return ($LASTEXITCODE -eq 0)
}

# BCT-owned containers: name pattern OR compose project label OR compose working_dir under $Root
function Get-BctContainers {
  & docker ps -a --format '{{.ID}}|{{.Names}}|{{.Image}}|{{.State}}|{{.Label "com.docker.compose.project"}}|{{.Label "com.docker.compose.project.working_dir"}}' 2>$null | ForEach-Object {
    $p = $_ -split '\|',6
    if($p.Count -lt 4){ return }
    $owned = ($p[1] -match '(?i)^bct_|business-control|divyastones') -or
             ($p.Count -ge 5 -and $p[4] -and $p[4] -eq $ComposeProject) -or
             ($p.Count -ge 6 -and $p[5] -and $p[5] -like "$Root*")
    if($owned){ [pscustomobject]@{ Id=$p[0]; Name=$p[1]; Image=$p[2]; State=$p[3] } }
  }
}

function Get-BctVolumes {
  & docker volume ls --format '{{.Name}}|{{.Label "com.docker.compose.project"}}' 2>$null | ForEach-Object {
    $p = $_ -split '\|',2
    $owned = ($p[0] -match '(?i)^bct_|business.control|business-control|divyastones') -or
             ($p.Count -ge 2 -and $p[1] -and $p[1] -eq $ComposeProject)
    if($owned){ $p[0] }
  }
}

# ------------------------------------------------------- phase 1: config backup --

function Export-BctConfigs {
  Phase 'Config backup (task XMLs, service configs, startup entries, env vars) - BEFORE removal'
  if($DryRun){ Log "WOULD EXPORT task XMLs, service configs, startup registry values and env vars to $BackupDir" 'DRY'; return }
  New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

  # Scheduled task definitions -> XML (restorable with Register-ScheduledTask)
  $taskDir = Join-Path $BackupDir 'tasks'
  $tasks = @(Get-BctTasks)
  if($tasks.Count -gt 0){
    New-Item -ItemType Directory -Path $taskDir -Force | Out-Null
    foreach($t in $tasks){
      try {
        $xml = Export-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction Stop
        $safe = ($t.TaskName -replace '[\\/:*?"<>|]','_')
        Set-Content -LiteralPath (Join-Path $taskDir "$safe.xml") -Value $xml -Encoding Unicode -ErrorAction Stop
      } catch { Log "Could not export task $($t.TaskName): $($_.Exception.Message)" 'WARN'; $script:BackupIssues += "task-xml:$($t.TaskName)" }
    }
    Log "Exported $($tasks.Count) scheduled task definition(s) to $taskDir" 'OK'
  }

  # Service configs
  $svcs = @(Get-BctServices)
  if($svcs.Count -gt 0){
    $svcFile = Join-Path $BackupDir 'services_config.txt'
    $svcs | ForEach-Object { "{0}`t{1}`t{2}`t{3}" -f $_.Name,$_.DisplayName,$_.StartMode,$_.PathName } | Set-Content -LiteralPath $svcFile -Encoding UTF8
    Log "Exported $($svcs.Count) service config(s) to $svcFile" 'OK'
  }

  # Startup registry values
  $regLines = @()
  foreach($rk in @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Run','HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce','HKLM:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce')){
    if(!(Test-Path $rk)){ continue }
    $props = Get-ItemProperty $rk -ErrorAction SilentlyContinue
    if(-not $props){ continue }
    foreach($prop in $props.PSObject.Properties){
      if($prop.Name -match '^PS'){ continue }
      if(([string]$prop.Value) -match $PathPat){ $regLines += "{0}`t{1}`t{2}" -f $rk,$prop.Name,$prop.Value }
    }
  }
  if($regLines.Count -gt 0){
    Set-Content -LiteralPath (Join-Path $BackupDir 'startup_registry.txt') -Value $regLines -Encoding UTF8
    Log "Exported $($regLines.Count) startup registry value(s)" 'OK'
  }

  # Env vars: ALWAYS backed up (tiny file; N8N_ENCRYPTION_KEY loss is unrecoverable). Verified.
  $envNames = @('BCT_ROOT','BUSINESS_CONTROL_TOWER','BUSINESS_TOWER_STATE','N8N_ENCRYPTION_KEY','POSTGRES_DB','POSTGRES_USER','POSTGRES_PASSWORD','DASHBOARD_PASSWORD','WHATSAPP_PHONE_NUMBER_ID','WHATSAPP_ACCESS_TOKEN','TELEGRAM_BOT_TOKEN','TELEGRAM_CHAT_ID')
  $envBackup = Join-Path $BackupDir 'bct_env_vars_SENSITIVE.txt'
  $lines = @('# BCT environment variable backup - CONTAINS SECRETS. Store safely, then delete.',"# Created $Stamp")
  foreach($scope in @('User','Machine')){
    foreach($name in $envNames){
      $v = [Environment]::GetEnvironmentVariable($name,$scope)
      if($null -ne $v){ $lines += "$scope`t$name=$v" }
    }
  }
  if($lines.Count -gt 2){
    try {
      Set-Content -LiteralPath $envBackup -Value $lines -Encoding UTF8 -ErrorAction Stop
      $check = @(Get-Content -LiteralPath $envBackup -ErrorAction Stop)
      if($check.Count -eq $lines.Count){ $script:EnvBackupOk = $true; Log "Environment variables backed up and verified: $envBackup" 'OK' }
      else { throw "verification mismatch ($($check.Count) vs $($lines.Count) lines)" }
    } catch {
      Log "Env-var backup FAILED: $($_.Exception.Message) - sensitive variables will NOT be deleted." 'ERROR'
      $script:BackupIssues += 'env-vars'
    }
  } else { $script:EnvBackupOk = $true; Log 'No BCT environment variables found to back up.' }
}

# ------------------------------------------------------------------- removal --

function Remove-BctTasks {
  Phase 'Scheduled tasks'
  $tasks = @(Get-BctTasks)
  if($tasks.Count -eq 0){ Log 'No matching scheduled tasks found.'; return }
  $folders = @{}
  foreach($t in $tasks){
    if($t.TaskPath -and $t.TaskPath -ne '\'){ $folders[$t.TaskPath] = $true }
    Act "Scheduled task $($t.TaskPath)$($t.TaskName)" 'Tasks' {
      Stop-ScheduledTask    -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction SilentlyContinue
      Disable-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction SilentlyContinue | Out-Null
      Unregister-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath -Confirm:$false -ErrorAction Stop
    } | Out-Null
  }
  if(-not $DryRun -and $folders.Count -gt 0){
    try {
      $svc = New-Object -ComObject 'Schedule.Service'; $svc.Connect()
      foreach($fp in $folders.Keys){
        try {
          $trimmed = $fp.TrimEnd('\'); if(-not $trimmed){ continue }
          $parent  = Split-Path $trimmed -Parent; if(-not $parent){ $parent='\' }
          $leaf    = Split-Path $trimmed -Leaf
          $pf = $svc.GetFolder($parent)
          if(($pf.GetFolder($leaf).GetTasks(1) | Measure-Object).Count -eq 0){
            $pf.DeleteFolder($leaf,0); Log "Removed empty task folder $fp" 'OK'
          }
        } catch {}
      }
    } catch {}
  }
}

function Remove-BctServices {
  Phase 'Windows services'
  $svcs = @(Get-BctServices)
  if($svcs.Count -eq 0){ Log 'No matching services found.'; return }
  foreach($s in $svcs){
    Act "Service $($s.Name) ($($s.DisplayName))" 'Services' {
      Stop-Service -Name $s.Name -Force -ErrorAction SilentlyContinue
      & sc.exe delete $s.Name | Out-Null
      if($LASTEXITCODE -ne 0){ throw "sc.exe delete returned $LASTEXITCODE" }
    } | Out-Null
  }
}

function Remove-StartupEntries {
  Phase 'Startup entries (Run + RunOnce + Startup folders)'
  foreach($rk in @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Run','HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce','HKLM:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce')){
    if(!(Test-Path $rk)){ continue }
    $props = Get-ItemProperty $rk -ErrorAction SilentlyContinue
    if(-not $props){ continue }
    foreach($prop in $props.PSObject.Properties){
      if($prop.Name -match '^PS'){ continue }
      if(([string]$prop.Value) -match $PathPat){
        Act "Startup registry entry $rk\$($prop.Name)" 'Startup' {
          Remove-ItemProperty -Path $rk -Name $prop.Name -Force -ErrorAction Stop
        } | Out-Null
      }
    }
  }
  foreach($folder in @([Environment]::GetFolderPath('Startup'), "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup")){
    if(!(Test-Path $folder)){ continue }
    Get-ChildItem $folder -Force -ErrorAction SilentlyContinue | Where-Object {
      ($_.Name -match $NamePat) -or ($_.Name -match $PathPat)
    } | ForEach-Object {
      $item = $_
      Act "Startup item $($item.FullName)" 'Startup' { Remove-Item $item.FullName -Recurse -Force -ErrorAction Stop } | Out-Null
    }
  }
}

function Stop-BctProcesses {
  Phase 'Running processes (strict pattern - project path required)'
  $procs = @(Get-BctKillProcesses)
  if($procs.Count -eq 0){ Log 'No matching processes running.'; return }
  foreach($p in $procs){
    Act "Process $($p.Name) PID $($p.ProcessId)" 'Processes' { Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop } | Out-Null
  }
}

# ------------------------------------------------------ phase 6: data backup --

function Backup-BctData {
  Phase 'Data backup (database dump, volume exports, project zip) - BEFORE destruction'
  if($SkipBackup){ Log 'Heavy backups skipped by -SkipBackup (explicit consent). Env vars were still backed up.' 'WARN'; return }
  if($DryRun){ Log "WOULD CREATE in ${BackupDir}: Postgres dump, tar export of every project Docker volume, full project zip" 'DRY'; return }
  New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

  # --- Docker-side backups ---
  if(Test-DockerUp){
    $containers = @(Get-BctContainers)

    # 1. Postgres dump - find EVERY postgres container (running or stopped), start if needed
    $pgs = @($containers | Where-Object { $_.Image -match '(?i)postgres' -or $_.Name -match '(?i)postgres|(^|[_-])db([_-]|$)' })
    if($pgs.Count -eq 0){
      if(Test-Path $ComposeFile){
        Log 'Compose stack exists but NO postgres container was found - if the database matters, abort now.' 'WARN'
        $script:BackupIssues += 'no-postgres-dump'
      } else { Log 'No postgres container found; no database dump taken.' }
    }
    foreach($pg in $pgs){
      $started = $false
      if($pg.State -ne 'running'){
        & docker start $pg.Id *> $null
        if($LASTEXITCODE -eq 0){ $started = $true; Start-Sleep 8; Log "Started stopped container $($pg.Name) for backup." }
        else { Log "Could not start $($pg.Name) to dump it." 'WARN'; $script:BackupIssues += "pg-start:$($pg.Name)"; continue }
      }
      # user: Windows env var -> project .env file -> default
      $pgUser = [Environment]::GetEnvironmentVariable('POSTGRES_USER','User')
      if(-not $pgUser){ $pgUser = [Environment]::GetEnvironmentVariable('POSTGRES_USER','Machine') }
      if(-not $pgUser){
        $envFile = Join-Path (Split-Path $ComposeFile -Parent) '.env'
        if(Test-Path $envFile){
          $m = Select-String -LiteralPath $envFile -Pattern '^\s*POSTGRES_USER=(.+)$' | Select-Object -First 1
          if($m){ $pgUser = $m.Matches[0].Groups[1].Value.Trim() }
        }
      }
      if(-not $pgUser){ $pgUser = 'postgres' }
      $dump = Join-Path $BackupDir ("postgres_dumpall_{0}.sql" -f ($pg.Name -replace '[\\/:*?"<>|]','_'))
      # dump INSIDE the container, then docker cp - avoids PS 5.1 pipeline re-encoding corruption
      & docker exec $pg.Id sh -c "pg_dumpall -U $pgUser -f /tmp/bct_dumpall.sql" 2>$null
      $execCode = $LASTEXITCODE
      if($execCode -eq 0){
        & docker cp "$($pg.Id):/tmp/bct_dumpall.sql" $dump 2>$null
        if($LASTEXITCODE -eq 0 -and (Test-Path $dump) -and (Get-Item $dump).Length -gt 100){
          Log "Postgres dump OK: $dump ($([math]::Round((Get-Item $dump).Length/1KB)) KB)" 'OK'
          & docker exec $pg.Id rm -f /tmp/bct_dumpall.sql 2>$null
        } else { Log "docker cp of dump failed for $($pg.Name)." 'ERROR'; $script:BackupIssues += "pg-cp:$($pg.Name)" }
      } else {
        Log "pg_dumpall failed in $($pg.Name) (user '$pgUser', exit $execCode)." 'ERROR'
        $script:BackupIssues += "pg-dump:$($pg.Name)"
      }
      if($started){ & docker stop $pg.Id *> $null }
    }

    # 2. Stop remaining running BCT containers gracefully, then tar-export EVERY project volume
    foreach($c in ($containers | Where-Object { $_.State -eq 'running' })){
      & docker stop $c.Id *> $null
      if($LASTEXITCODE -eq 0){ Log "Stopped container $($c.Name) for consistent volume export." }
    }
    $vols = @(Get-BctVolumes)
    foreach($v in $vols){
      $tgz = "volume_{0}.tgz" -f ($v -replace '[\\/:*?"<>|]','_')
      & docker run --rm -v "${v}:/v:ro" -v "${BackupDir}:/b" alpine tar czf "/b/$tgz" -C /v . 2>$null
      if($LASTEXITCODE -eq 0 -and (Test-Path (Join-Path $BackupDir $tgz))){
        Log "Volume exported: $v -> $tgz" 'OK'
      } else {
        Log "Volume export FAILED: $v (offline? alpine image unavailable?)" 'ERROR'
        $script:BackupIssues += "volume:$v"
      }
    }
    if($vols.Count -eq 0 -and (Test-Path $ComposeFile)){ Log 'No project volumes matched - check names manually with: docker volume ls' 'WARN' }
  } else {
    if(Test-Path $ComposeFile){
      Log 'Docker engine NOT running but a compose stack exists - database/volume contents CANNOT be backed up and WILL BE LOST if volumes are removed.' 'ERROR'
      $script:BackupIssues += 'docker-down-no-dump'
    }
  }

  # --- Project folder zip: .NET ZipFile (hidden files included, >2GB entries OK) ---
  if(Test-Path $Root){
    $zip = Join-Path $BackupDir 'bct_project_files.zip'
    $zipOk = $false
    try {
      Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
      [System.IO.Compression.ZipFile]::CreateFromDirectory($Root, $zip, [System.IO.Compression.CompressionLevel]::Optimal, $false)
      $zipOk = $true
      Log "Project folder zipped: $zip ($([math]::Round((Get-Item $zip).Length/1MB)) MB)" 'OK'
    } catch {
      Log "Zip failed ($($_.Exception.Message)) - falling back to robocopy file copy." 'WARN'
      Remove-Item $zip -Force -ErrorAction SilentlyContinue
    }
    if(-not $zipOk){
      $copyDir = Join-Path $BackupDir 'project_files'
      & robocopy $Root $copyDir /E /R:1 /W:1 /XJ /XD node_modules .venv venv __pycache__ .git *> $null
      # robocopy exit codes 0-7 = success variants; >=8 = failure
      if($LASTEXITCODE -lt 8){ Log "Project files copied to $copyDir (junk dirs excluded, junctions not followed)" 'OK' }
      else { Log 'Project file backup FAILED via both zip and robocopy.' 'ERROR'; $script:BackupIssues += 'project-files' }
    }
  } else { Log "Project folder $Root not found; nothing to zip." }
}

# Backup gate: destruction only proceeds past failures with explicit typed consent.
function Assert-BackupGate([string]$About){
  if($DryRun -or $SkipBackup){ return }
  if($script:BackupIssues.Count -eq 0){ return }
  Log ("BACKUP INCOMPLETE ({0}) - consent required to {1}." -f ($script:BackupIssues -join ', '), $About) 'ERROR'
  Write-Host ''
  Write-Host "One or more backups FAILED: $($script:BackupIssues -join ', ')" -ForegroundColor Red
  Write-Host "Continuing will $About with NO complete backup. Data loss may be permanent." -ForegroundColor Red
  $c = Read-Host 'Type CONTINUE WITHOUT BACKUP to proceed anyway (anything else aborts safely)'
  if($c -cne 'CONTINUE WITHOUT BACKUP'){
    Log 'Aborted at backup gate. Nothing further was removed. Fix the backup issue and rerun.' 'ERROR'
    if($Elevated){ Read-Host 'Press Enter to close this window' | Out-Null }
    exit 3
  }
  Log 'User explicitly consented to continue without complete backup.' 'WARN'
  $script:BackupIssues = @()   # consent given once covers the rest of the run
}

function Remove-BctDockerAssets {
  Phase 'Docker assets (compose stack, containers, volumes, networks, local images)'
  if(!(Get-Command docker -ErrorAction SilentlyContinue)){ Log 'Docker CLI not found; skipping.' 'WARN'; return }
  if(!(Test-DockerUp)){ Log 'Docker engine not running; live Docker cleanup skipped. Rerun with Docker started to remove volumes.' 'WARN'; return }

  if(Test-Path $ComposeFile){
    Act 'Compose stack (down --volumes --rmi local)' 'Docker' {
      Push-Location (Split-Path $ComposeFile -Parent)
      try {
        & docker compose version *> $null
        if($LASTEXITCODE -eq 0){ & docker compose down --remove-orphans --volumes --rmi local }
        elseif(Get-Command docker-compose -ErrorAction SilentlyContinue){ & docker-compose down --remove-orphans --volumes --rmi local }
        else { throw 'Neither "docker compose" nor "docker-compose" is available.' }
        if($LASTEXITCODE -ne 0){ throw "compose down exited with $LASTEXITCODE" }
      } finally { Pop-Location }
    } | Out-Null
  }

  foreach($c in @(Get-BctContainers)){
    Act "Container $($c.Name)" 'Docker' { & docker rm -f $c.Id *> $null; if($LASTEXITCODE -ne 0){ throw "docker rm exited $LASTEXITCODE" } } | Out-Null
  }
  foreach($v in @(Get-BctVolumes)){
    Act "Volume $v" 'Docker' { & docker volume rm -f $v *> $null; if($LASTEXITCODE -ne 0){ throw "volume rm exited $LASTEXITCODE" } } | Out-Null
  }
  & docker network ls --format '{{.ID}}|{{.Name}}|{{.Label "com.docker.compose.project"}}' 2>$null | ForEach-Object {
    $p = $_ -split '\|',3
    if($p.Count -ge 2 -and (($p[1] -match '(?i)bct_|business.control|business-control|divyastones') -or ($p.Count -ge 3 -and $p[2] -eq $ComposeProject))){
      $id=$p[0]; $name=$p[1]
      Act "Network $name" 'Docker' { & docker network rm $id *> $null; if($LASTEXITCODE -ne 0){ throw "network rm exited $LASTEXITCODE" } } | Out-Null
    }
  }
  & docker images --format '{{.ID}}|{{.Repository}}:{{.Tag}}' 2>$null | ForEach-Object {
    $p = $_ -split '\|',2
    if($p.Count -eq 2 -and $p[1] -match '(?i)bct|business-control|divyastones'){
      $id=$p[0]; $name=$p[1]
      Act "Image $name" 'Docker' { & docker rmi -f $id *> $null; if($LASTEXITCODE -ne 0){ throw "rmi exited $LASTEXITCODE" } } | Out-Null
    }
  }
}

function Stop-DockerDesktop {
  Phase 'Docker Desktop shutdown'
  if(!(Get-Command docker -ErrorAction SilentlyContinue)){ Log 'Docker CLI not present; nothing to shut down.'; return }
  $psOutput = & docker ps --format '{{.Names}}|{{.Label "com.docker.compose.project"}}' 2>$null
  $psFailed = ($LASTEXITCODE -ne 0)
  $others = @()
  if(-not $psFailed -and $psOutput){
    $others = @($psOutput | ForEach-Object {
      $p = $_ -split '\|',2
      $bct = ($p[0] -match '(?i)^bct_|business-control|divyastones') -or ($p.Count -ge 2 -and $p[1] -eq $ComposeProject)
      if(-not $bct){ $p[0] }
    })
  }
  if($psFailed -and -not $RemoveSharedTools){
    Log 'Could not query docker ps - failing CLOSED: Docker Desktop left running (unknown container state).' 'WARN'
    return
  }
  if($others.Count -gt 0){
    if(-not $RemoveSharedTools){
      Log ("Docker Desktop left RUNNING - other active containers depend on it: {0}" -f ($others -join ', ')) 'WARN'
      return
    }
    Log ("Stopping non-BCT containers gracefully before shutdown: {0}" -f ($others -join ', ')) 'WARN'
    if(-not $DryRun){ foreach($o in $others){ & docker stop $o *> $null } }
  }
  if($DryRun){ Log 'WOULD SHUT DOWN Docker Desktop' 'DRY'; return }
  $cli = "$env:ProgramFiles\Docker\Docker\DockerCli.exe"
  if(Test-Path $cli){ try { & $cli -Shutdown; Start-Sleep 5; Log 'Requested Docker Desktop shutdown.' 'OK' } catch {} }
  Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -in @('Docker Desktop','com.docker.backend','com.docker.build','vpnkit')
  } | Stop-Process -Force -ErrorAction SilentlyContinue
}

function Remove-Shortcuts {
  Phase 'Shortcuts and control scripts'
  $places = @(
    [Environment]::GetFolderPath('Desktop'),
    "$env:PUBLIC\Desktop",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
  )
  $startMenus = @("$env:APPDATA\Microsoft\Windows\Start Menu\Programs","$env:ProgramData\Microsoft\Windows\Start Menu\Programs")
  $wsh = $null
  try { $wsh = New-Object -ComObject WScript.Shell } catch {}

  foreach($place in $places){
    if(!(Test-Path $place)){ continue }
    Get-ChildItem $place -Recurse -Force -ErrorAction SilentlyContinue |
      Where-Object { -not $_.PSIsContainer -and $_.Extension -match '^\.(lnk|url|bat|cmd|ps1|vbs)$' } |
      ForEach-Object {
        $sc = $_; $hit = $false
        if($sc.Name -match $NamePat){ $hit = $true }
        elseif($wsh -and $sc.Extension -eq '.lnk'){
          try {
            $t = $wsh.CreateShortcut($sc.FullName)
            if("$($t.TargetPath) $($t.Arguments) $($t.WorkingDirectory)" -match $PathPat){ $hit = $true }
          } catch {}
        }
        elseif($sc.Extension -match '^\.(bat|cmd|ps1|vbs)$' -and $sc.Length -lt 64KB){
          try { if((Get-Content -LiteralPath $sc.FullName -TotalCount 30 -ErrorAction Stop) -join ' ' -match $PathPat){ $hit = $true } } catch {}
        }
        if($hit){ Act "Shortcut/script $($sc.FullName)" 'Shortcuts' { Remove-Item $sc.FullName -Force -ErrorAction Stop } | Out-Null }
      }
  }
  # Start Menu FOLDERS named after the tower (never touches Desktop folders)
  foreach($menu in $startMenus){
    if(!(Test-Path $menu)){ continue }
    Get-ChildItem $menu -Recurse -Force -Directory -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -match $NamePat } | ForEach-Object {
        $d = $_
        Act "Start Menu folder $($d.FullName)" 'Shortcuts' { Remove-Item $d.FullName -Recurse -Force -ErrorAction Stop } | Out-Null
      }
  }
}

function Remove-FirewallRules {
  Phase 'Firewall rules'
  Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object {
    $_.DisplayName -match '(?i)\bBCT\b|Business Control Tower|Business Tower|DivyaStones|n8n.*5678|Streamlit.*8501'
  } | ForEach-Object {
    $r = $_
    Act "Firewall rule $($r.DisplayName)" 'Firewall' { Remove-NetFirewallRule -Name $r.Name -ErrorAction Stop } | Out-Null
  }
}

function Remove-BctEnvVars {
  Phase 'Environment variables'
  # BCT-specific names are always safe to remove; sensitive/generic names require a verified backup.
  $bctOnly    = @('BCT_ROOT','BUSINESS_CONTROL_TOWER','BUSINESS_TOWER_STATE')
  $sensitive  = @('N8N_ENCRYPTION_KEY','POSTGRES_DB','POSTGRES_USER','POSTGRES_PASSWORD','DASHBOARD_PASSWORD','WHATSAPP_PHONE_NUMBER_ID','WHATSAPP_ACCESS_TOKEN','TELEGRAM_BOT_TOKEN','TELEGRAM_CHAT_ID')
  foreach($scope in @('User','Machine')){
    foreach($name in $bctOnly){
      if($null -ne [Environment]::GetEnvironmentVariable($name,$scope)){
        Act "$scope environment variable $name" 'EnvVars' { [Environment]::SetEnvironmentVariable($name,$null,$scope) } | Out-Null
      }
    }
    foreach($name in $sensitive){
      if($null -ne [Environment]::GetEnvironmentVariable($name,$scope)){
        if($script:EnvBackupOk -or $DryRun){
          Act "$scope environment variable $name" 'EnvVars' { [Environment]::SetEnvironmentVariable($name,$null,$scope) } | Out-Null
        } else {
          Log "KEPT $scope $name - env-var backup was not verified (delete manually after backing it up)." 'WARN'
        }
      }
    }
  }
  Log 'OPENAI_API_KEY deliberately left untouched (other programs may use it).'
  Log 'NOTE: POSTGRES_*/DASHBOARD_PASSWORD are generic names - if another app used them, restore from the backup file.' 'WARN'
}

function Restore-PowerPlan {
  Phase 'Power plan'
  Act 'Windows Balanced power plan restored' 'Power' {
    & powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e *> $null
    if($LASTEXITCODE -ne 0){ throw "powercfg exited $LASTEXITCODE" }
  } | Out-Null
}

function Remove-ProjectFolder {
  Phase "Project folder $Root"
  if(!(Test-Path $Root)){ Log 'Project folder already absent.'; return }
  if($DryRun){ Log "WOULD DELETE $Root (after backup)" 'DRY'; Count 'Folder'; return }

  if((Get-Location).Path -like "$Root*"){ Set-Location $env:SystemDrive\ }

  # Remove reparse points FIRST so nothing can follow a junction out of the project tree
  Get-ChildItem $Root -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint } |
    Sort-Object { $_.FullName.Length } -Descending | ForEach-Object {
      $rp = $_
      try {
        if($rp.PSIsContainer){ & cmd.exe /c "rmdir `"$($rp.FullName)`"" *> $null }
        else { Remove-Item -LiteralPath $rp.FullName -Force -ErrorAction Stop }
        Log "Removed junction/symlink (link only, target untouched): $($rp.FullName)" 'OK'
      } catch { Log "Could not remove reparse point $($rp.FullName)" 'WARN' }
    }

  & cmd.exe /c "attrib -r -s -h `"$Root\*`" /s /d" *> $null

  try { Remove-Item $Root -Recurse -Force -ErrorAction Stop; Log "Deleted $Root" 'OK'; Count 'Folder'; return } catch {}

  & cmd.exe /c "rmdir /s /q `"$Root`"" *> $null
  if(!(Test-Path $Root)){ Log "Deleted $Root (rmdir fallback)" 'OK'; Count 'Folder'; return }

  $empty = Join-Path $env:TEMP "bct_empty_$Stamp"
  New-Item -ItemType Directory -Path $empty -Force | Out-Null
  & robocopy $empty $Root /MIR /XJ /R:1 /W:1 *> $null
  Remove-Item $Root  -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item $empty -Recurse -Force -ErrorAction SilentlyContinue
  if(Test-Path $Root){ Log "Could not completely delete $Root - a process may still lock it. Reboot, then delete manually." 'ERROR' }
  else { Log "Deleted $Root (robocopy fallback)" 'OK'; Count 'Folder' }
}

function Winget-Uninstall([string]$Id,[string]$Name){
  if(!(Get-Command winget -ErrorAction SilentlyContinue)){ Log "winget missing; uninstall $Name manually." 'WARN'; return }
  Act "Uninstalled $Name" 'SharedTools' {
    & winget uninstall --id $Id --exact --silent --accept-source-agreements --disable-interactivity
    if($LASTEXITCODE -ne 0){ throw "$Name not removed by winget (may not be installed as $Id)" }
  } | Out-Null
}

function Remove-SharedTools {
  Phase 'Shared development tools (affects other projects!)'
  Log 'Removing shared development tools. These may be used by unrelated software.' 'WARN'
  if((Get-Command npm -ErrorAction SilentlyContinue) -and -not $DryRun){ & npm uninstall -g @openai/codex *> $null; Log 'Attempted npm removal of Codex CLI.' }

  foreach($p in @(
    @('Docker.DockerDesktop','Docker Desktop'),
    @('Ollama.Ollama','Ollama'),
    @('OpenJS.NodeJS.LTS','Node.js LTS'),
    @('Python.Python.3.12','Python 3.12'),
    @('Git.Git','Git'),
    @('Microsoft.VisualStudioCode','Visual Studio Code')
  )){ Winget-Uninstall $p[0] $p[1] }

  foreach($path in @(
    "$env:USERPROFILE\.codex", "$env:USERPROFILE\.ollama", "$env:USERPROFILE\.docker",
    "$env:APPDATA\Docker", "$env:APPDATA\Docker Desktop",
    "$env:LOCALAPPDATA\Docker", "$env:LOCALAPPDATA\Docker Desktop",
    "$env:PROGRAMDATA\Docker", "$env:PROGRAMDATA\DockerDesktop",
    "$env:APPDATA\npm\node_modules\@openai\codex", "$env:APPDATA\npm\codex.cmd", "$env:APPDATA\npm\codex"
  )){
    if(Test-Path $path){ Act "Removed $path" 'SharedTools' { Remove-Item $path -Recurse -Force -ErrorAction Stop } | Out-Null }
  }

  if(Get-Command wsl.exe -ErrorAction SilentlyContinue){
    # wsl.exe emits UTF-16LE; strip embedded NULs or names never match on PS 5.1
    $distros = (& wsl.exe --list --quiet 2>$null) | ForEach-Object { ($_ -replace "`0",'').Trim() } | Where-Object { $_ }
    foreach($d in $distros){
      if($d -in @('docker-desktop','docker-desktop-data')){
        Act "Unregistered Docker WSL distribution $d" 'SharedTools' { & wsl.exe --unregister $d; if($LASTEXITCODE -ne 0){ throw "wsl --unregister exited $LASTEXITCODE" } } | Out-Null
      }
    }
  }
}

function Final-Audit {
  Phase 'Final audit'
  $problems = 0

  $tasks = @(Get-BctTasks)
  if($tasks.Count -eq 0){ Log 'Audit: no BCT scheduled tasks remain.' 'OK' }
  else { $problems++; $tasks | ForEach-Object { Log "Audit: task remains $($_.TaskPath)$($_.TaskName) [$($_.State)]" 'WARN' } }

  $svcs = @(Get-BctServices)
  if($svcs.Count -eq 0){ Log 'Audit: no BCT services remain.' 'OK' } else { $problems++; $svcs | ForEach-Object { Log "Audit: service remains $($_.Name)" 'WARN' } }

  # Raw scan - no executable whitelist (catches BCT code hosted by ANY binary)
  $procs = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessId -ne $CurrentPid -and $_.CommandLine -match $KillPat
  })
  if($procs.Count -eq 0){ Log 'Audit: no BCT processes remain.' 'OK' } else { $problems++; $procs | ForEach-Object { Log "Audit: process remains $($_.Name) PID $($_.ProcessId)" 'WARN' } }

  if(Test-Path $Root){ $problems++; Log "Audit: project folder still exists: $Root" 'WARN' } else { Log 'Audit: project folder removed.' 'OK' }

  if(Test-DockerUp){
    $left = @(Get-BctContainers)
    if($left.Count -eq 0){ Log 'Audit: no BCT docker containers remain.' 'OK' }
    else { $problems++; Log ("Audit: containers remain: {0}" -f (($left | ForEach-Object {$_.Name}) -join ', ')) 'WARN' }
  }

  Write-Host ''
  Write-Host '==================== SUMMARY ====================' -ForegroundColor Cyan
  $mode = 'REMOVED'; if($DryRun){ $mode = 'WOULD REMOVE (dry-run)' }
  foreach($k in ($script:Counts.Keys | Sort-Object)){ Write-Host ("  {0,-12} {1,4}  {2}" -f $k, $script:Counts[$k], $mode) }
  if(-not $DryRun){ Write-Host ("  Backup:      {0}" -f $BackupDir) -ForegroundColor Green }
  Write-Host ("  Log:         {0}" -f $Log)
  Write-Host ("  Warnings:    {0}" -f $script:Warnings)
  Write-Host '=================================================' -ForegroundColor Cyan
  return $problems
}

# --------------------------------------------------------------------- main --

if(!(Is-Admin)){
  # Elevate for real runs AND dry runs (unelevated previews miss HKLM/services/machine env vars)
  Write-Host 'Elevation required for a complete view - requesting administrator rights...' -ForegroundColor Yellow
  $fwd = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"",'-Elevated')
  foreach($k in $PSBoundParameters.Keys){
    if($k -ne 'Elevated' -and $PSBoundParameters[$k] -eq $true){ $fwd += "-$k" }
  }
  try {
    $proc = Start-Process -FilePath 'powershell.exe' -ArgumentList $fwd -Verb RunAs -Wait -PassThru
    exit $proc.ExitCode
  } catch {
    if($DryRun){ Log 'Elevation declined - dry-run continues UNELEVATED: HKLM/services/machine-scope items may be missing from this preview.' 'WARN' }
    else { Write-Host 'Elevation declined. Run this script in PowerShell as Administrator.' -ForegroundColor Red; exit 1 }
  }
}

Write-Host ''
if($DryRun){
  Write-Host 'BUSINESS CONTROL TOWER REMOVAL - DRY RUN (nothing will be changed)' -ForegroundColor Cyan
} else {
  Write-Host 'BUSINESS CONTROL TOWER COMPLETE REMOVAL v2.1' -ForegroundColor Red
  Write-Host 'Removes: tower, parity tasks, services, database, Docker assets, scripts.' -ForegroundColor Yellow
  Write-Host 'Backups taken FIRST: configs + env vars + Postgres dump + ALL project volumes + project zip.' -ForegroundColor Green
  $confirm = Read-Host 'Type REMOVE BUSINESS CONTROL TOWER to continue'
  if($confirm -cne 'REMOVE BUSINESS CONTROL TOWER'){
    Write-Host 'Cancelled. Nothing was removed.' -ForegroundColor Yellow
    if($Elevated){ Read-Host 'Press Enter to close this window' | Out-Null }
    exit 0
  }
}

Log ("Removal started. DryRun={0} SkipBackup={1} RemoveSharedTools={2} ComposeProject={3}" -f [bool]$DryRun,[bool]$SkipBackup,[bool]$RemoveSharedTools,$ComposeProject)

Export-BctConfigs        # 1. task XMLs / service configs / registry / env vars saved BEFORE removal
Remove-BctTasks          # 2. kill respawn triggers
Remove-BctServices       # 3. services
Remove-StartupEntries    # 4. Run/RunOnce/startup folders
Stop-BctProcesses        # 5. stop what's running (files unlock for backup)
Backup-BctData           # 6. pg dump (starts stopped containers), volume tars, project zip
Assert-BackupGate 'destroy Docker containers and volumes'
Remove-BctDockerAssets   # 7. teardown only after backup gate
Stop-DockerDesktop
Remove-Shortcuts
Remove-FirewallRules
Remove-BctEnvVars
Restore-PowerPlan
Assert-BackupGate 'permanently delete the project folder'
Remove-ProjectFolder

if(-not $DryRun){
  Write-Host ''
  Write-Host 'The Business Control Tower itself has been removed.' -ForegroundColor Green
  if($RemoveSharedTools){ Remove-SharedTools }
  else {
    Write-Host 'Docker, Ollama, Codex CLI, Node.js, Python, Git and VS Code may be used by other software.' -ForegroundColor Yellow
    $shared = Read-Host 'Type REMOVE SHARED TOOLS to uninstall those tools and their data too'
    if($shared -ceq 'REMOVE SHARED TOOLS'){ Remove-SharedTools }
    else { Log 'Shared development tools retained (second confirmation not supplied).' }
  }
} elseif($RemoveSharedTools){ Remove-SharedTools }

$leftovers = Final-Audit
Write-Host ''
if($DryRun){
  Write-Host "Dry run complete. Review the log, then run without -DryRun to remove. Log: $Log" -ForegroundColor Cyan
  if($Elevated){ Read-Host 'Press Enter to close this window' | Out-Null }
  exit 0
}
Write-Host "Removal finished. Log: $Log" -ForegroundColor Green
Write-Host "Backup: $BackupDir" -ForegroundColor Green
Write-Host '  -> move bct_env_vars_SENSITIVE.txt somewhere safe, then delete it from the Desktop.' -ForegroundColor Yellow
Write-Host 'Restart Windows after reviewing the log.' -ForegroundColor Yellow
if($Elevated){ Read-Host 'Press Enter to close this window' | Out-Null }
if($leftovers -gt 0){ exit 2 } else { exit 0 }
