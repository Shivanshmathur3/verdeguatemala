# Growth Engine Runbook — How the Automated System Works

The growth-experiment-engine agent (`.claude/agents/growth-experiment-engine.md`) is a repeating cycle that generates NEW styles of lead generation and client conversion — permanently. This folder is its memory.

## How to Run a Cycle (takes ~10 minutes of your time)

**Every 2 weeks**, open Claude Code in this repo and say:

> "Run the growth engine"

Claude will automatically:
1. Read `experiment_log.csv` + `active_experiments.md` + `conversion_tracker.csv`
2. Ask you for results of the active experiments (replies, captures, bookings)
3. Status each active experiment: **scale** (→ becomes permanent playbook), **kill** (→ logged with cause of death), or **extend** (once max)
4. Generate 5+ genuinely NEW experiment ideas (checked against the log so nothing dead is re-proposed)
5. ICE-score them into `experiment_backlog.md`
6. Promote the top backlog item into the freed slot with owner agent, brief, metric, kill condition
7. Commit everything to git

## The Files

| File | What it is |
|------|-----------|
| `experiment_backlog.md` | Scored idea bank — 10 ideas ready now, refreshed every cycle |
| `active_experiments.md` | The ≤3 currently running, with day counters and this-week actions |
| `experiment_log.csv` | Permanent record of every experiment ever — the system's memory |
| `playbooks/` | Experiments that WON, written up as permanent repeatable playbooks |

## Why This Never Runs Out of Ideas

Each cycle the engine draws from: adjacent export industries, new channels, new offer structures, new buyer segments, new geographies, and live web research on current B2B tactics — minus everything already in the log. The idea space grows faster than the log does.

## Calendar Anchors (put these in your phone)

| When | What |
|------|------|
| Every 2nd Monday | "Run the growth engine" — 10 min review cycle |
| Late July 2026 | EXP decision: Marmomacc pre-show campaign must start (show is Sept 22-25) |
| Every quarter | FOB Benchmark Report refresh (Q4 edition due Oct 1) |
| Cycle 4 (~end Aug) | Revisit wild bet: container-share marketplace |

## First Cycle Status (bootstrapped 2026-07-02)

- Backlog: 10 ideas scored (top: import-records reverse-targeting, ICE 504)
- Active: EXP-001 (reverse-targeting), EXP-002 (WhatsApp named videos), EXP-003 (FOB benchmark magnet)
- Your immediate actions: record the 10 named videos (EXP-002) — everything else Claude's agents execute
