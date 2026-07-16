# Always-On Lead Generation — How It Runs 24/7

This is a **lead generation system**, not a scaffold. Here is exactly how it produces
data around the clock, how much, and the one switch only you can flip.

## The engine (server-side, no machine of yours running)

```
3× every day (07:47 / 15:47 / 23:47 IST)  — GitHub Actions, on GitHub's servers
        │
        ├─ discover  (9 regions IN PARALLEL, one job each)
        │     US·Gulf·UK·Canada·ANZ·EU·SE-Asia·LatAm·Africa
        │     each finds ~5–12 net-new leads, deduped, evidence-required
        │
        └─ aggregate (one job)
              merge → dedup again → score → tier → draft Tier-1 outreach
              → governance parity check → append ledger → rebuild dashboard
              → commit + push
        │
   pending_approval/run_<id>/   → you approve → outreach
```

## Volume — "the most amount of data"

| Lever | Value |
|-------|-------|
| Regions per run (parallel) | 9 |
| Leads/region/run | 5–12 |
| Runs per day | 3 |
| **Theoretical ceiling** | **~200 net-new candidate leads/day** |
| Realistic (after dedup + evidence filter) | **60–120 quality leads/day** |
| Dedup memory | `lead_ledger.csv` — never re-proposes a company, so volume compounds into coverage, not repeats |

Every lead still requires a real evidence URL and a named/verifiable contact — high volume of *usable* data, not scraped junk that bounces. This is deliberate: 100 real importers beat 10,000 scraped emails.

## The ONE thing only you can do (2 minutes)

Scheduled runs need two things, both one-time:

1. **Add the API key** — GitHub → repo **Settings → Secrets and variables → Actions → New repository secret**: name `ANTHROPIC_API_KEY`, value from console.anthropic.com. *(The engine cannot run without this — I can't add secrets for you.)*
2. **Enable the schedule** — GitHub only fires `schedule:` triggers from the **default branch**. Either merge this branch's `.github/workflows/lead-engine.yml` to the default branch (the PR does this), **or** run it on demand any time via the **Actions tab → Lead Engine → Run workflow** button (works from this branch right now, no merge needed).

Until step 1 is done, the workflow is deployed but idle. After it, the system runs itself 3× a day, forever, with zero further action from you beyond approving batches.

## Cost note (be aware)

High volume burns Anthropic API tokens. 3 runs/day × 10 agents ≈ 30 agent-runs/day.
Start with the default quotas; if cost matters, lower `quota_per_region` in the workflow or
drop to 1–2 runs/day by removing cron lines. The `workflow_dispatch` button lets you test a
single run and see the token spend before committing to the full schedule.

## Your only recurring job: approve (10 min/morning)

1. Open `approval_queue.md` → newest run
2. Skim `governance_report.md` (it recomputed everything independently)
3. Say "approve lead batch run_<id>" — approved Tier-1 drafts move to your send queue
4. Watch it all on the dashboard (`marketing/dashboard/index.html`), auto-rebuilt each run

## What it will never do
Send anything without your approval · invent contacts, emails, or evidence · scrape
Google/paywalls · re-propose a company already in the ledger. The approval gate is the
point: the engine generates at volume, you decide what gets contacted.

## Interim runner (while the secret is pending)
A session cron (`7eee32c2`, 06:53 IST) runs the engine from the active Claude session for
up to 7 days as a bridge. The GitHub Actions layer above is the permanent one — switch it on
and the interim runner becomes redundant.
