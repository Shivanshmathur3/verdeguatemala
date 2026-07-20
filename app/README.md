# Divya Stones — Local Control Tower (web app)

A multi-page, interactive web app that runs **on your own machine**, reachable from a
browser at a local IP address. One page per function — approve leads with buttons, run
the engine with a click, add leads through a form, send WhatsApp from the page.

## Pages
| Page | What you do there |
|------|-------------------|
| **Overview** | Live KPIs, leads by region, quick actions |
| **Leads** | Search + filter the full 126-lead pipeline; open sites & WhatsApp |
| **Approvals** | See each engine run; **Approve & merge** into the pipeline with one button |
| **Add Leads** | Paste a customs/directory CSV → save → **Run pipeline** button (scores + queues) |
| **WhatsApp** | One-tap send cards (opens WhatsApp with the draft pre-typed) |
| **Runs** | Every run + its governance report |
| **Drafts** | The AI-written outreach drafts |

---

## Run it (2 minutes)

### Windows
1. Install Python 3.12 from python.org (tick **"Add to PATH"**)
2. Double-click **`START_SERVER.bat`**
3. It prints your URLs — open one in a browser

### macOS / Linux
```bash
cd app
./start_server.sh
```

You'll see:
```
Local:   http://127.0.0.1:8600
Network: http://192.168.1.42:8600   (open from any device on your Wi-Fi)
```

- **`http://127.0.0.1:8600`** — this machine
- **`http://<your-LAN-IP>:8600`** — your phone, laptop, anyone on the same Wi-Fi
  (find the IP anytime with `ipconfig` on Windows / `ifconfig` on Mac). To reach it from
  other devices, allow the port through Windows Firewall the first time (Windows will prompt).

Change the port with an env var: `set BCT_PORT=9000` (Windows) before launching.

---

## Make it run 24/7

The app runs as long as the window is open. For always-on, pick one:

### Option A — Windows Task Scheduler (simplest, survives reboot)
1. Open **Task Scheduler → Create Task**
2. **General:** name "Divya Control Tower"; check *Run whether user is logged on or not*
3. **Triggers:** New → *At startup*
4. **Actions:** New → Program: `python`, Arguments: `server.py`, Start in: the full path to this `app` folder
5. **Settings:** check *If the task fails, restart every 1 minute*
6. OK. It now starts on every boot and restarts if it crashes.

### Option B — NSSM (runs as a true Windows service, most robust)
1. Download NSSM (nssm.cc), unzip
2. `nssm install DivyaControlTower` → set Application path to `python.exe`, Arguments `server.py`, Startup dir to this folder
3. `nssm start DivyaControlTower` — now it's a background service, auto-starts, auto-restarts

### Keep leads generating 24/7 too
Add a **second** scheduled task so the free pipeline runs itself even when you're away:
- Program: `python`, Arguments: `marketing/lead_engine/pipeline/normalize_and_score.py`,
  Start in: the repo root
- Trigger: *Daily*, repeat every 6 hours
Drop CSVs into `marketing/lead_engine/inbox/` and they get processed automatically; refresh
the Approvals page to review.

---

## How it connects to everything
The app reads and writes the **same repo files** as the pipeline and dashboard —
`scored_master_contacts.csv`, `lead_ledger.csv`, the run folders, `whatsapp_sends.json`.
Approving in the web app updates the ledger and master list; running the pipeline from the
web app is the same engine the GitHub workflow uses. One source of truth, three front doors
(web app, static dashboard, GitHub).

## Notes
- **Local only** by default (binds to your LAN, not the public internet). Don't port-forward it.
- No credentials, no API key — pure Flask + the free pipeline.
- Nothing sends automatically; every outreach is a human tap.
