# 24/7 Automated Lead Engine — Divya Stones

## What this is
A scheduled Routine (server-side cron, independent of any open session) fires **daily at ~06:53 IST**. Each firing creates a fresh Claude session in this environment that executes `PIPELINE.md`:

```
MARKETING agent  →  finds 15 net-new leads/day (10 US, 5 Gulf) with evidence
STRATEGY agent   →  scores vs MASTER_ACQUISITION_PLAN, drafts Day-1 outreach
GOVERNING agent  →  independent parity check (counts, dedup, schema, drafts,
                    evidence) + compliance (no-send, domain rule, market
                    discipline, no fabricated contacts)
      ↓
pending_approval/run_DATE/  →  committed + pushed  →  push/email notification
      ↓
HUMAN APPROVAL  →  only then do leads enter the outreach pipeline
```

## Safety properties
- **Never sends anything.** Output is leads + drafts in an approval queue. Sending stays manual per `weekly_cadence.md`.
- **Parity-checked:** the governing agent independently recomputes what the marketing agent claims; mismatch = batch HOLD, not silent fix.
- **Dedup memory:** `lead_ledger.csv` records every lead ever seen — the engine never re-proposes a company.
- **Honest failure:** a bad run commits a FAILED.md instead of vanishing.

## Daily use (2 minutes)
1. Morning notification arrives → open `approval_queue.md`
2. Skim the run's `governance_report.md` + `leads_scored.csv`
3. Say "approve lead batch run_YYYY-MM-DD" (or reject specific rows)
4. Approved Tier-1 drafts get sent by you via Instantly/WhatsApp per the weekly cadence

## Controls
- **Pause:** "pause the lead engine" (disables the Routine)
- **Resume:** "resume the lead engine"
- **Change quota/cadence:** edit PIPELINE.md Stage 1 quota, or ask to change the cron
- **Kill:** "delete the lead engine trigger"

## Volume math
15 leads/day × ~5 weekday-quality runs/week ≈ **75 qualified prospects/week — exactly the plan §2 cadence target**, produced automatically instead of manually.
