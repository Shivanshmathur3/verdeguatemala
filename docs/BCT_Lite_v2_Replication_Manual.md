# Business Control Tower LITE v2 — Replication Manual

**Primary business:** DivyaStones · Udaipur, Rajasthan, India
**Purpose:** Local, approval-gated system for the parts the cloud can't do — dashboard, approved sends, reply ingestion, order pipeline.
**Strategy of record:** `marketing/MASTER_ACQUISITION_PLAN.md` (July 2026) — US 60% / Gulf 30% / rest inbound-only.
**Companion system:** the cloud lead engine (`marketing/lead_engine/PIPELINE.md`) already runs discovery → scoring → drafts → approval queue on GitHub. **The Lite tower does not duplicate it.**
**Timezone:** Asia/Kolkata · **Dashboard:** http://127.0.0.1:8501

---

## 0. What changed from v1 and why

| v1 (full tower) | Lite v2 | Why |
|---|---|---|
| 7 containers (postgres, redis, n8n main + 3 workers, dashboard) | **3 containers** (postgres, n8n, dashboard) | Redis/queue-mode/workers serve thousands of jobs/hour; you run ~100/day |
| 16 workflows | **6 workflows** | Every workflow is maintenance; each must earn its place |
| ~40 tables | **14 tables** | Same guarantees, less surface |
| 17 dashboard pages | **5 pages** | You'll only ever open 5 |
| Global rotation across 19 regions | **Hard-coded tiers from the acquisition plan** | "Global scanning" is the mediocre-in-ten-markets trap the plan forbids |
| Search APIs as discovery | **Customs data as discovery, search as enrichment** | Search finds websites; customs data finds proven container-buyers |
| Ends at "approved draft" | **Full revenue loop: send → reply ingestion → pipeline** | Drafts don't pay; replies do |
| Codex CLI Governor every 15 min | **Rules-first Governor, LLM batched hourly** | Deterministic checks don't expire logins or time out |
| Backup to same disk | **Nightly offsite pg_dump + monthly restore drill** | A dead D: drive must not take the business with it |
| Resume manual-only always | **Auto-resume after unexpected reboot if state was `running`** | Windows Update at 3 AM must not silently kill the tower |

**Unchanged from v1 (these were right):** approval-gated externals, the hard prohibition list, the result gate, Absolute Pause semantics, Postgres as source of truth, honest verification-before-trust.

---

## 1. The prohibition list (unchanged, non-negotiable)

The system must never: send unsolicited mass email · send WhatsApp automatically · post to LinkedIn automatically · book meetings without approval · commit prices/stock/delivery/payment terms/orders automatically · bypass logins, paywalls, CAPTCHA, robots.txt · invent buyers, contacts, certifications, projects, prices, or stock.

**Success is never claimed unless verified** — every checklist item in §12 confirmed on the actual machine.

---

## 2. Division of labor — cloud vs local

```
CLOUD (GitHub Actions lead engine — already deployed, zero maintenance)
  ├─ Daily discovery (15 leads/day quota, evidence URLs required)
  ├─ Scoring vs acquisition plan, tiering
  ├─ Draft generation from sequence templates
  ├─ Governance parity checks (P1–P5, C1–C4)
  └─ pending_approval/ queue → committed to repo

LOCAL LITE TOWER (this manual — the parts that need your accounts/machine)
  ├─ Dashboard (approvals, pipeline, KPIs) — reads repo + local DB
  ├─ APPROVED SEND: Gmail drafts via your account, WhatsApp via your phone
  ├─ REPLY INGESTION: IMAP poll of sales@ → lead matching → pipeline stage flip
  ├─ Order pipeline: inquiry → quote → sample → negotiation → order
  ├─ Follow-up control (Day 4/9/14/21 due-date engine)
  └─ Daily report + KPI tripwires
```

A `git pull` of the repo is the interface between the two. No duplicate discovery, no duplicate scoring, no parity systems fighting each other.

---

## 3. Stack

| Component | Purpose | Notes |
|---|---|---|
| Docker Desktop + WSL2 | Container host | Start-on-login OFF |
| `bct_postgres` | Source of truth | One container |
| `bct_n8n` | 6 workflows | Single instance, SQLite→Postgres backend, NO queue mode |
| `bct_dashboard` | Streamlit, 5 pages | Bound to 127.0.0.1 only |
| Python 3.12, Git | Scripts + repo sync | |
| Ollama (optional) | Local LLM for borderline governor calls | Fallback only |

Removed vs v1: Redis, n8n workers, heavy worker, Codex-CLI-as-backbone, Tailscale, VS Code as requirement.

---

## 4. Folder structure

```
D:\BCT-Lite
├── 01_Repo\                  <- git clone of verdeguatemala (the cloud engine's output)
├── 02_Config\
│   ├── tower_state.json      (running | stopped + STOPPED.flag)
│   ├── business_profile.json (DivyaStones products, buyers, terms)
│   ├── market_tiers.json     (hard-coded from acquisition plan, quarterly review)
│   ├── tripwires.json        (governor thresholds — §8)
│   └── .env                  (DB password, IMAP app-password, notification tokens)
├── 03_Docker\  (docker-compose.yml, initdb\)
├── 04_Dashboard\ (app.py, requirements.txt)
├── 05_Scripts\  (~10 scripts, not 45 — §10)
├── 06_Backups\  (staging only — real backups go offsite)
└── 07_Logs\
```

---

## 5. The revenue loop (v1's missing half — the most important section)

### 5a. Approved → Sent
When you approve a draft on the dashboard:
1. **Email**: dashboard creates a **Gmail draft** via API in your account (never auto-sends). You open Gmail, give it one human look, press send. Sent status syncs back via the sent-folder poll.
2. **WhatsApp**: dashboard shows the message + number with one-tap `wa.me` link; you send from WhatsApp Business. Mark-as-sent button logs it.
3. Every send is logged to `sent_log` with timestamp, channel, sequence step.

### 5b. Reply ingestion (workflow #3 — build this before anything else)
- IMAP poll of sales@divyastones.com every 15 minutes while `running`
- Match sender domain/address against `leads` → flip stage to REPLIED, stamp `replied_at`
- Classify reply (interested / question / not-now / unsubscribe) — rules first, Ollama for ambiguous
- **Alert you within minutes (Telegram/WhatsApp notification): the plan's 2-hour response SLA starts at receipt, not at discovery**
- Unmatched replies land in a triage list on the dashboard

### 5c. Pipeline propagation
REPLIED → discovery call logged → QUOTE (48h timer starts, breach = red banner + tripwire) → SAMPLE (21-day sample-converter sequence auto-scheduled) → NEGOTIATION → ORDER. Every stage change writes `pipeline_events`. Nothing advances silently; nothing commits prices — quotes are drafted from `proposals/pricing_sheet_*.html`, approved by you.

### 5d. Follow-up engine
Unanswered sent emails get their Day 4/9/14/21 sequence steps queued as approval items on the due date. A reply anywhere in the thread cancels the remaining sequence automatically (v1 never specified this — it's how you avoid embarrassing "breakup email after they replied" incidents).

---

## 6. Sources — customs data first

| Priority | Source | How it enters |
|---|---|---|
| 1 | **Customs data** (Volza/ImportYeti/Panjiva exports) | Monthly CSV export → `ingest-customs.ps1` → cloud engine dedup ledger + local `leads`. Proven container-buyers with materials + ports — feeds the US sequence's personalization tokens directly |
| 2 | Cloud lead engine daily runs | `git pull` — already deduped, scored, governed |
| 3 | Trade-show exhibitor lists (Coverings, TISE, Marmomac, Big 5) | CSV ingest, tagged by show |
| 4 | Search APIs (Brave/SerpAPI) | **Enrichment only** — fill missing emails/LinkedIn on existing leads, never primary discovery |
| 5 | Manual URLs | Dashboard paste box |

Deleted from v1: the 19-region global seeding, rotation policies, `todays_global_markets.json`. Replaced by `market_tiers.json`: **Tier 1 = US (60% of quota), Tier 2 = Gulf (30%), Tier 3 = inbound-only.** Rescored quarterly by you, not daily by a robot.

---

## 7. Workflows — 6, not 16

| # | Workflow | Cadence | Replaces v1's |
|---|---|---|---|
| 1 | Repo sync + lead import | hourly | Lead Discovery + Processing cycles |
| 2 | Approved-send executor (Gmail drafts, wa.me queue) | on approval | (didn't exist) |
| 3 | **Reply ingestion + SLA alerts** | 15 min | (didn't exist — the big one) |
| 4 | Follow-up + pipeline timers (Day 4/9/14/21, 48h quote timer, sample sequence) | hourly | Followup/Meeting/Order cycles |
| 5 | Daily report + KPI/tripwire evaluation | 20:00 | Reporter + Rhythm + Governor cycles |
| 6 | Nightly maintenance + offsite backup | 23:30 | Night Maintenance |

Every workflow: checks `tower_state` first, records output count to the **result gate** (kept verbatim from v1: zero-result runs need a reason, 3 consecutive zeros = auto-pause + dashboard alert).

---

## 8. Governor — rules first, LLM last

The v1 Governor called an LLM every 15 minutes. Lite's governor is a **deterministic rule table evaluated by workflow #5**, in `tripwires.json`:

| Rule | Threshold | Action |
|---|---|---|
| Reply rate | <1.5% after 3 weeks of sends | Pause new sends for that sequence, flag "fix hook/list, not volume" |
| Quote turnaround | >48h on any open quote | Red banner + stop new lead imports until cleared |
| Approval queue age | any item >48h | Escalating notification |
| Deliverability | bounce >3% or complaints >0.1% | Pause sending mailbox, alert |
| Result gate | 3 zero-output runs | Pause workflow, alert |
| Disk/CPU | <30 GB free / >90% sustained | Pause heavy work |
| Data honesty | lead without evidence URL | Reject at import (mirrors cloud C4) |

LLM (Ollama, or Claude in the repo session) is consulted **only** for: ambiguous reply classification, borderline compliance calls — batched, never on a schedule. Every decision (rule or LLM) is written to `governor_decisions` with its reason.

---

## 9. Database — 14 tables

`leads` (canonical — v1 schema **plus** `materials_imported`, `import_evidence_url`, `current_supplier_country`, `port`, `replied_at`, `sequence_step`) · `companies` · `contacts` · `sent_log` · `replies` · `approval_queue` · `order_pipeline` · `pipeline_events` · `followup_due` · `governor_decisions` · `result_gate` · `kpi_daily` · `provider_usage` · `audit_log`

Deleted: 26 v1 tables whose jobs moved to the cloud engine, the repo's CSVs, or nowhere (autopilot_heartbeats et al.).

**Score calibration (new):** monthly job joins `leads.grade` × outcomes (replied? quoted? ordered?) → grade-vs-reality table on the dashboard → adjust scoring weights in the cloud engine's PIPELINE.md. v1 logged learning; Lite closes the loop.

**Extractor golden tests (new):** 10 frozen sample pages with expected extractions in the repo; run after any prompt/template change; failures block deployment of the change.

---

## 10. Scripts — ~10, not 45

`resume-tower.ps1` · `pause-everything.ps1` (v1 semantics kept exactly) · `tower-status.ps1` · `healthcheck.ps1` · `ingest-customs.ps1` · `ingest-tradeshow.ps1` · `backup-offsite.ps1` · `restore-drill.ps1` · `run-golden-tests.ps1` · `boot-check.ps1`

**`boot-check.ps1` (new, fixes v1's dead-after-reboot gap):** runs at logon. If `tower_state == running` AND no `STOPPED.flag` → the previous shutdown was unexpected (power cut, Windows Update) → auto-resume and notify you. If STOPPED.flag exists → do nothing (Absolute Pause is sacred).

---

## 11. Dashboard — 5 pages

1. **Today** — approval queue (with age), replies awaiting response (SLA countdown), quotes on the 48h clock, KPI tiles vs plan targets
2. **Leads** — filterable table, evidence links, grade-vs-outcome calibration view
3. **Pipeline** — order stages, follow-ups due, meeting list
4. **Diagnostics** — result gate, provider status/spend, deliverability, last backup + last successful restore drill
5. **Control** — tower state, Pause Everything, workflow toggles

Morning ritual (put it in your phone): **08:45 IST, 15 minutes** — approve/reject the queue, answer replies, clear the quote clock. An approval queue nobody drains is how this system dies; the ritual is part of the architecture.

---

## 12. Backups that survive the machine

- Nightly (workflow #6): `pg_dumpall` + `02_Config\` (minus `.env`) + zip → **rclone push to OneDrive/Google Drive**
- `.env` secrets: stored once in your password manager, never in backups
- **Monthly restore drill** (`restore-drill.ps1`): restore last dump to a scratch DB, count rows, diff vs production counts, write result to Diagnostics. An untested backup is a hope, not a backup.
- The repo itself is the second offsite copy of all lead/campaign data (already on GitHub).

---

## 13. Replication sequence (one afternoon, not a week)

1. **Windows prep:** WSL2, Docker Desktop (autostart OFF), Python, Git
2. **Clone:** `git clone https://github.com/Shivanshmathur3/verdeguatemala D:\BCT-Lite\01_Repo`
3. **Secrets:** fresh Postgres password, Gmail app-password (IMAP), notification token → `02_Config\.env` (never copied from another machine)
4. **Stack up:** `docker compose config` → `docker compose up -d` → verify 3 containers healthy
5. **DB:** run initdb migrations → verify 14 tables → import current leads from repo CSVs
6. **Workflows:** import the 6, activate ONLY #1 (repo sync) → verify result gate records output → activate #3 (reply ingestion) → test with a self-sent email to sales@ → activate the rest one at a time
7. **Dashboard:** open all 5 pages, confirm database-first reads
8. **Pause test:** Pause Everything → verify nothing survives, nothing resurrects → resume from shortcut → **reboot the machine mid-`running`** → verify boot-check auto-resumes
9. **Backup test:** run backup-offsite → run restore-drill → both green on Diagnostics
10. **First live test:** import one customs CSV (25 rows) → expect: deduped leads with evidence, drafts queued, ZERO sends without approval, reply to a test send detected within 15 min

---

## 14. Verification checklist

**Infrastructure:** ☐ 3 containers healthy ☐ Docker autostart off ☐ dashboard on 127.0.0.1 only ☐ boot-check installed
**Revenue loop:** ☐ approval → Gmail draft works ☐ reply detected + alert <15 min ☐ 48h quote timer visible ☐ reply cancels pending follow-ups
**Sources:** ☐ customs ingest produces rows with materials+port ☐ repo sync pulls cloud runs ☐ search APIs enrichment-only
**Safety:** ☐ zero send paths without approval ☐ prohibition list enforced ☐ result gate pauses on 3 zeros ☐ Absolute Pause total ☐ tripwires fire on test data
**Resilience:** ☐ offsite backup ran ☐ restore drill passed ☐ reboot auto-resume works ☐ STOPPED.flag survives reboot

---

## 15. Judge it by (unchanged from v1, still right)

Qualified replies · sample/BOQ/quote requests · meetings · orders · revenue · low error rate · low manual burden · full control.

Never by processes running.
