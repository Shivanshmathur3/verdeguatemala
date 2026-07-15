#requires -Version 5.1
<#
.SYNOPSIS
  Business Control Tower — complete removal, v2 (safer, auditable, recoverable).
.DESCRIPTION
  Improvements over v1:
    - -DryRun switch: full preview of everything that WOULD be removed, removes nothing
    - Automatic data backup (leads/reports/config zip + Postgres dump + env-var backup) BEFORE anything is destroyed
    - Shortcut removal restricted to .lnk/.url files (v1 could delete personal files matching 'Parity'/'BCT')
    - Docker cleanup verifies exit codes, falls back to docker-compose, removes locally-built images
    - Docker Desktop only shut down if no unrelated containers are running
    - Env vars backed up before removal (N8N_ENCRYPTION_KEY loss = unrecoverable n8n credentials)
    - Windows services + RunOnce keys + empty Task Scheduler folders covered
    - Attribute-clearing + robocopy-mirror fallback for stubborn folder deletion
    - Auto-elevation, structured phases, final audit with summary table and exit code
.PARAMETER DryRun
  Preview mode. Detects and lists everything, changes nothing. RUN THIS FIRST.
.PARAMETER SkipBackup
  Skip the data backup phase (not recommended).
.PARAMETER RemoveSharedTools
  Also remove Docker Desktop, Ollama, Node, Python, Git, VS Code without the second interactive prompt.
.EXAMPLE
  .\Remove_Business_Control_Tower_v2.ps1 -DryRun      # ALWAYS do this first
  .\Remove_Business_Control_Tower_v2.ps1              # real removal, with backup
#>
[CmdletBinding()]
param(
  [switch]$DryRun,
  [switch]$SkipBackup,
  [switch]$RemoveSharedTools
)

$ErrorActionPreference = 'Continue'
$Root       = 'D:\Business-Control-Tower'
$Desktop    = [Environment]::GetFolderPath('Desktop')
$Stamp      = Get-Date -Format 'yyyyMMdd_HHmmss'
$Log        = Join-Path $Desktop "BCT_Removal_$Stamp.log"
$BackupDir  = Join-Path $Desktop "BCT_Backup_$Stamp"
$CurrentPid = $PID
$NamePat    = '(?i)\bBCT\b|Business Control Tower|Business Tower|Business Rhythm|Business Followup|DivyaStones|Parity'
$PathPat    = '(?i)D:\\Business-Control-Tower|Business-Control-Tower|bct_|parity|DivyaStones'
$script:Counts   = @{}
$script:Warnings = 0

function Log([string]$Message,[string]$Level='INFO') {
  $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
  Add-Content -LiteralPath $Log -Value $line -Encoding UTF8
  $colors = @{INFO='White';OK='Green';WARN='Yellow';ERROR='Red';DRY='Cyan'}
  $color = $colors[$Level]; if(-not $color){ $color='White' }
  Write-Host $line -ForegroundColor $color
  if($Level -eq 'WARN' -or $Level -eq 'ERROR'){ $script:Warnings++ }
}

function Count([string]$Category){ if($script:Counts.ContainsKey($Category)){ $script:Counts[$Category]++ } else { $script:Counts[$Category]=1 } }

# Central do-or-preview wrapper: every destructive action goes through this.
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

function Get-BctProcesses {
  Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessId -ne $CurrentPid -and
    $_.Name -match '^(powershell|pwsh|cmd|wscript|cscript|python|pythonw|node|codex|streamlit)\.exe$' -and
    $_.CommandLine -match $PathPat
  }
}

# ------------------------------------------------------------------- phases --

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
  # Clean now-empty task folders v1 left behind
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
  Phase 'Windows services (missed by v1)'
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
  $runKeys = @(
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce'
  )
  foreach($rk in $runKeys){
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
  $startupFolders = @([Environment]::GetFolderPath('Startup'), "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup")
  foreach($folder in $startupFolders){
    if(!(Test-Path $folder)){ continue }
    Get-ChildItem $folder -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $NamePat } | ForEach-Object {
      $item = $_
      Act "Startup item $($item.FullName)" 'Startup' { Remove-Item $item.FullName -Recurse -Force -ErrorAction Stop } | Out-Null
    }
  }
}

function Stop-BctProcesses {
  Phase 'Running processes'
  $procs = @(Get-BctProcesses)
  if($procs.Count -eq 0){ Log 'No matching processes running.'; return }
  foreach($p in $procs){
    Act "Process $($p.Name) PID $($p.ProcessId)" 'Processes' { Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop } | Out-Null
  }
}

function Backup-BctData {
  Phase 'Backup (BEFORE anything is destroyed)'
  if($SkipBackup){ Log 'Backup skipped by -SkipBackup.' 'WARN'; return }
  if($DryRun){ Log "WOULD CREATE backup folder $BackupDir with: project-data zip, Postgres dump (if running), env-var backup" 'DRY'; return }
  New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

  # 1. Postgres dump while the container is still alive (v1 destroyed volumes with zero backup)
  if(Get-Command docker -ErrorAction SilentlyContinue){
    & docker info *> $null
    if($LASTEXITCODE -eq 0){
      $pgc = & docker ps --format '{{.ID}}|{{.Names}}' 2>$null | ForEach-Object {
        $p = $_ -split '\|',2
        if($p.Count -eq 2 -and $p[1] -match '(?i)(bct|business|divya).*(postgres|db)|postgres.*(bct|divya)'){ $p[0] }
      } | Select-Object -First 1
      if($pgc){
        $pgUser = [Environment]::GetEnvironmentVariable('POSTGRES_USER','User')
        if(-not $pgUser){ $pgUser = [Environment]::GetEnvironmentVariable('POSTGRES_USER','Machine') }
        if(-not $pgUser){ $pgUser = 'postgres' }
        $dump = Join-Path $BackupDir 'bct_postgres_dumpall.sql'
        & docker exec $pgc pg_dumpall -U $pgUser 2>$null | Out-File -LiteralPath $dump -Encoding UTF8
        if($LASTEXITCODE -eq 0 -and (Get-Item $dump -ErrorAction SilentlyContinue).Length -gt 0){
          Log "Postgres database dumped to $dump" 'OK'
        } else {
          Remove-Item $dump -Force -ErrorAction SilentlyContinue
          Log 'Postgres dump failed - database contents will be LOST when volumes are removed. Ctrl+C now if you need them.' 'WARN'
          Start-Sleep 8
        }
      } else { Log 'No BCT postgres container running; no database dump taken.' }
    } else { Log 'Docker engine not running; no database dump possible. Volume data will be lost.' 'WARN' }
  }

  # 2. Project folder zip (leads, reports, config, .env files)
  if(Test-Path $Root){
    $sizeMB = [math]::Round(((Get-ChildItem $Root -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum)/1MB)
    $zip = Join-Path $BackupDir 'bct_project_files.zip'
    if($sizeMB -le 1500){
      try { Compress-Archive -Path (Join-Path $Root '*') -DestinationPath $zip -Force -ErrorAction Stop; Log "Project folder ($sizeMB MB) zipped to $zip" 'OK' }
      catch { Log ("Full zip failed ({0}); falling back to data-only zip." -f $_.Exception.Message) 'WARN'; $sizeMB = 999999 }
    }
    if($sizeMB -gt 1500){
      $dataDirs = Get-ChildItem $Root -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '(?i)data|report|lead|export|config|output|csv|db' }
      $dataFiles = Get-ChildItem $Root -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match '(?i)\.(env|csv|db|sqlite|json|md)$' }
      $targets = @($dataDirs.FullName) + @($dataFiles.FullName) | Where-Object { $_ }
      if($targets.Count -gt 0){
        try { Compress-Archive -Path $targets -DestinationPath $zip -Force -ErrorAction Stop; Log "Data-only backup zipped to $zip (full folder was $sizeMB MB - too large)" 'OK' }
        catch { Log 'Data zip also failed. Copy anything you need out of the folder manually before continuing. Ctrl+C now to abort.' 'ERROR'; Start-Sleep 10 }
      } else { Log 'No obvious data folders found to back up.' 'WARN' }
    }
  } else { Log "Project folder $Root not found; nothing to zip." }

  # 3. Environment variable backup (N8N_ENCRYPTION_KEY loss = unrecoverable credentials)
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
    Set-Content -LiteralPath $envBackup -Value $lines -Encoding UTF8
    Log "Environment variables backed up to $envBackup (contains secrets - move it somewhere safe)" 'OK'
  } else { Log 'No BCT environment variables found to back up.' }
}

function Remove-BctDockerAssets {
  Phase 'Docker assets (compose stack, containers, volumes, networks, local images)'
  if(!(Get-Command docker -ErrorAction SilentlyContinue)){ Log 'Docker CLI not found; skipping.' 'WARN'; return }
  & docker info *> $null
  if($LASTEXITCODE -ne 0){ Log 'Docker engine not running; live Docker cleanup skipped. Volumes may survive - rerun with Docker started if you want them gone.' 'WARN'; return }

  $composeFile = Join-Path $Root '10_Docker\docker-compose.yml'
  if(Test-Path $composeFile){
    Act 'Compose stack (down --volumes --rmi local)' 'Docker' {
      Push-Location (Split-Path $composeFile -Parent)
      try {
        & docker compose version *> $null
        if($LASTEXITCODE -eq 0){ & docker compose down --remove-orphans --volumes --rmi local }
        elseif(Get-Command docker-compose -ErrorAction SilentlyContinue){ & docker-compose down --remove-orphans --volumes --rmi local }
        else { throw 'Neither "docker compose" nor "docker-compose" is available.' }
        if($LASTEXITCODE -ne 0){ throw "compose down exited with $LASTEXITCODE" }
      } finally { Pop-Location }
    } | Out-Null
  }

  & docker ps -a --format '{{.ID}}|{{.Names}}' 2>$null | ForEach-Object {
    $p = $_ -split '\|',2
    if($p.Count -eq 2 -and $p[1] -match '(?i)^bct_|business-control|divyastones'){
      $id=$p[0]; $name=$p[1]
      Act "Container $name" 'Docker' { & docker rm -f $id *> $null; if($LASTEXITCODE -ne 0){ throw "docker rm exited $LASTEXITCODE" } } | Out-Null
    }
  }
  & docker volume ls --format '{{.Name}}' 2>$null | Where-Object { $_ -match '(?i)bct_|business.control|business-control|divyastones' } | ForEach-Object {
    $v=$_
    Act "Volume $v" 'Docker' { & docker volume rm -f $v *> $null; if($LASTEXITCODE -ne 0){ throw "volume rm exited $LASTEXITCODE" } } | Out-Null
  }
  & docker network ls --format '{{.ID}}|{{.Name}}' 2>$null | ForEach-Object {
    $p = $_ -split '\|',2
    if($p.Count -eq 2 -and $p[1] -match '(?i)bct_|business.control|business-control|divyastones'){
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
  $others = @(& docker ps --format '{{.Names}}' 2>$null | Where-Object { $_ -and $_ -notmatch '(?i)^bct_|business-control|divyastones' })
  if($others.Count -gt 0 -and -not $RemoveSharedTools){
    Log ("Docker Desktop left RUNNING - other active containers depend on it: {0}" -f ($others -join ', ')) 'WARN'
    return
  }
  if($DryRun){ Log 'WOULD SHUT DOWN Docker Desktop' 'DRY'; return }
  $cli = "$env:ProgramFiles\Docker\Docker\DockerCli.exe"
  if(Test-Path $cli){ try { & $cli -Shutdown; Start-Sleep 5; Log 'Requested Docker Desktop shutdown.' 'OK' } catch {} }
  Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -in @('Docker Desktop','com.docker.backend','com.docker.build','vpnkit')
  } | Stop-Process -Force -ErrorAction SilentlyContinue
}

function Remove-Shortcuts {
  Phase 'Shortcuts (.lnk/.url ONLY - v1 could delete personal files)'
  $places = @(
    [Environment]::GetFolderPath('Desktop'),
    "$env:PUBLIC\Desktop",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
  )
  $wsh = $null
  try { $wsh = New-Object -ComObject WScript.Shell } catch {}
  foreach($place in $places){
    if(!(Test-Path $place)){ continue }
    Get-ChildItem $place -Recurse -Force -ErrorAction SilentlyContinue |
      Where-Object { -not $_.PSIsContainer -and $_.Extension -match '^\.(lnk|url)$' } |
      ForEach-Object {
        $sc = $_; $hit = $false
        if($sc.Name -match $NamePat){ $hit = $true }
        elseif($wsh -and $sc.Extension -eq '.lnk'){
          try {
            $t = $wsh.CreateShortcut($sc.FullName)
            if("$($t.TargetPath) $($t.Arguments) $($t.WorkingDirectory)" -match $PathPat){ $hit = $true }
          } catch {}
        }
        if($hit){ Act "Shortcut $($sc.FullName)" 'Shortcuts' { Remove-Item $sc.FullName -Force -ErrorAction Stop } | Out-Null }
      }
  }
}

function Remove-FirewallRules {
  Phase 'Firewall rules'
  Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object {
    $_.DisplayName -match '(?i)BCT|Business Control Tower|Business Tower|DivyaStones|n8n.*5678|Streamlit.*8501'
  } | ForEach-Object {
    $r = $_
    Act "Firewall rule $($r.DisplayName)" 'Firewall' { Remove-NetFirewallRule -Name $r.Name -ErrorAction Stop } | Out-Null
  }
}

function Remove-BctEnvVars {
  Phase 'Environment variables (backed up in the Backup phase)'
  $names = @('BCT_ROOT','BUSINESS_CONTROL_TOWER','BUSINESS_TOWER_STATE','N8N_ENCRYPTION_KEY','POSTGRES_DB','POSTGRES_USER','POSTGRES_PASSWORD','DASHBOARD_PASSWORD','WHATSAPP_PHONE_NUMBER_ID','WHATSAPP_ACCESS_TOKEN','TELEGRAM_BOT_TOKEN','TELEGRAM_CHAT_ID')
  foreach($scope in @('User','Machine')){
    foreach($name in $names){
      if($null -ne [Environment]::GetEnvironmentVariable($name,$scope)){
        Act "$scope environment variable $name" 'EnvVars' { [Environment]::SetEnvironmentVariable($name,$null,$scope) } | Out-Null
      }
    }
  }
  Log 'OPENAI_API_KEY deliberately left untouched (other programs may use it).'
  Log 'NOTE: POSTGRES_* / DASHBOARD_PASSWORD are generic names - if another app used them, restore from the backup file.' 'WARN'
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

  # Don't hold a lock on the folder we're deleting
  if((Get-Location).Path -like "$Root*"){ Set-Location $env:SystemDrive\ }

  # Clear read-only/system/hidden attributes - the most common Remove-Item failure
  & cmd.exe /c "attrib -r -s -h `"$Root\*`" /s /d" *> $null

  try { Remove-Item $Root -Recurse -Force -ErrorAction Stop; Log "Deleted $Root" 'OK'; Count 'Folder'; return } catch {}

  & cmd.exe /c "rmdir /s /q `"$Root`"" *> $null
  if(!(Test-Path $Root)){ Log "Deleted $Root (rmdir fallback)" 'OK'; Count 'Folder'; return }

  # Robocopy mirror-empty: handles long paths and stubborn ACLs
  $empty = Join-Path $env:TEMP "bct_empty_$Stamp"
  New-Item -ItemType Directory -Path $empty -Force | Out-Null
  & robocopy $empty $Root /MIR /R:1 /W:1 *> $null
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
    $distros = (& wsl.exe --list --quiet 2>$null) | ForEach-Object { $_.Trim([char]0).Trim() }
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

  $procs = @(Get-BctProcesses)
  if($procs.Count -eq 0){ Log 'Audit: no BCT processes remain.' 'OK' } else { $problems++; $procs | ForEach-Object { Log "Audit: process remains $($_.Name) PID $($_.ProcessId)" 'WARN' } }

  if(Test-Path $Root){ $problems++; Log "Audit: project folder still exists: $Root" 'WARN' } else { Log 'Audit: project folder removed.' 'OK' }

  if(Get-Command docker -ErrorAction SilentlyContinue){
    & docker info *> $null
    if($LASTEXITCODE -eq 0){
      $left = @(& docker ps -a --format '{{.Names}}' 2>$null | Where-Object { $_ -match '(?i)^bct_|business-control|divyastones' })
      if($left.Count -eq 0){ Log 'Audit: no BCT docker containers remain.' 'OK' } else { $problems++; Log ("Audit: containers remain: {0}" -f ($left -join ', ')) 'WARN' }
    }
  }

  Write-Host ''
  Write-Host '==================== SUMMARY ====================' -ForegroundColor Cyan
  $mode = 'REMOVED'; if($DryRun){ $mode = 'WOULD REMOVE (dry-run)' }
  foreach($k in ($script:Counts.Keys | Sort-Object)){ Write-Host ("  {0,-12} {1,4}  {2}" -f $k, $script:Counts[$k], $mode) }
  if(-not $DryRun -and -not $SkipBackup){ Write-Host ("  Backup:      {0}" -f $BackupDir) -ForegroundColor Green }
  Write-Host ("  Log:         {0}" -f $Log)
  Write-Host ("  Warnings:    {0}" -f $script:Warnings)
  Write-Host '=================================================' -ForegroundColor Cyan
  return $problems
}

# --------------------------------------------------------------------- main --

if(!(Is-Admin)){
  if($DryRun){
    Log 'Not elevated - dry-run continues but task/service/firewall detection may be incomplete.' 'WARN'
  } else {
    Write-Host 'Elevation required - requesting administrator rights...' -ForegroundColor Yellow
    $fwd = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"")
    foreach($k in $PSBoundParameters.Keys){ if($PSBoundParameters[$k] -eq $true){ $fwd += "-$k" } }
    try { Start-Process -FilePath 'powershell.exe' -ArgumentList $fwd -Verb RunAs; exit 0 }
    catch { Write-Host 'Elevation declined. Run this script in PowerShell as Administrator.' -ForegroundColor Red; exit 1 }
  }
}

Write-Host ''
if($DryRun){
  Write-Host 'BUSINESS CONTROL TOWER REMOVAL - DRY RUN (nothing will be changed)' -ForegroundColor Cyan
} else {
  Write-Host 'BUSINESS CONTROL TOWER COMPLETE REMOVAL v2' -ForegroundColor Red
  Write-Host 'Removes: tower, parity tasks, services, database, Docker assets, scripts.' -ForegroundColor Yellow
  Write-Host 'A backup (data zip + Postgres dump + env vars) is taken FIRST unless -SkipBackup.' -ForegroundColor Green
  $confirm = Read-Host 'Type REMOVE BUSINESS CONTROL TOWER to continue'
  if($confirm -cne 'REMOVE BUSINESS CONTROL TOWER'){ Write-Host 'Cancelled. Nothing was removed.' -ForegroundColor Yellow; exit 0 }
}

Log ("Removal started. DryRun={0} SkipBackup={1} RemoveSharedTools={2}" -f [bool]$DryRun,[bool]$SkipBackup,[bool]$RemoveSharedTools)

Remove-BctTasks        # 1. kill respawn triggers first
Remove-BctServices     # 2. services too (v1 missed these)
Remove-StartupEntries  # 3. Run/RunOnce/startup folders
Stop-BctProcesses      # 4. now stop what's running (files unlock for backup)
Backup-BctData         # 5. BACKUP while Docker is still up
Remove-BctDockerAssets # 6. only now tear down containers/volumes
Stop-DockerDesktop     # 7. only if nothing else depends on it
Remove-Shortcuts
Remove-FirewallRules
Remove-BctEnvVars
Restore-PowerPlan
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
  exit 0
}
Write-Host "Removal finished. Log: $Log" -ForegroundColor Green
if(-not $SkipBackup){ Write-Host "Backup: $BackupDir  (move bct_env_vars_SENSITIVE.txt somewhere safe, then delete it)" -ForegroundColor Green }
Write-Host 'Restart Windows after reviewing the log.' -ForegroundColor Yellow
if($leftovers -gt 0){ exit 2 } else { exit 0 }
