# 24/7 Lead Engine — Daily Pipeline Definition
**Executed automatically by a scheduled Routine (fresh Claude session each run). Version 1.0.**
**Cardinal rule: this engine NEVER sends anything. It generates, verifies, and queues for human approval.**

---

## Run Procedure (execute stages in order)

### Stage 0 — Setup
1. `git fetch origin claude/marketing-email-drafts-cpZlm && git checkout claude/marketing-email-drafts-cpZlm && git pull origin claude/marketing-email-drafts-cpZlm`
2. Read this file fully. Read `lead_ledger.csv` (dedup memory), `marketing/MASTER_ACQUISITION_PLAN.md` (strategy of record), and `marketing/scored_master_contacts.csv`.
3. Set RUN_ID = `run_YYYY-MM-DD` (today's date). Create `marketing/lead_engine/pending_approval/RUN_ID/`.

### Stage 1 — MARKETING AGENT (find leads)
**Role:** prospect researcher. **Global tiered quota — quality over quantity; stop at quota.**

| Tier | Regions | Daily quota | Rationale |
|------|---------|------------|-----------|
| 1 | USA (TX, FL, CA, NY, GA) | 8 | Post-tariff restocking window — 60% effort per plan |
| 1 | Gulf (UAE, Saudi, Qatar, Oman, Kuwait) | 5 | Vision 2030 demand, fastest lane — 30% effort |
| 2 | Global scout — ROTATING: one region per run from {UK/Ireland, Canada, Australia/NZ, SE Asia (SG/MY/VN), East Asia (JP/KR/TW), Northern Europe, Southern Europe, Eastern Europe, Latin America, East/Southern Africa, North Africa/Levant} | 3 | Global coverage without diluting focus — advance to the next region each run, note which in the governance report |
| — | **Total** | **16/day** | |

- US targets (Priority 1 per plan): slab importers/distributors and $5M+ fabricators. Search: ImportYeti/Volza public pages, "granite distributor [metro]", "slab warehouse [metro]", stone association directories, Coverings/TISE exhibitor lists.
- Gulf targets (Priority 2): fit-out contractors (Riyadh, Jeddah, Dubai, Abu Dhabi), building-material traders. Search trade directories, giga-project supplier news.
- Global scout targets: natural stone importers, tile/slab wholesalers, and India-sourcing distributors in the rotation region. A scout lead scoring Tier 1 twice in consecutive runs earns its region a standing quota review.
- For each lead capture: company, named contact + title (required — no named contact, no lead), email, phone/WhatsApp, website, LinkedIn, city, country, materials they buy, evidence URL, why_qualified (one line).
- **Dedup DURING research**: skip any company already in `lead_ledger.csv` or `scored_master_contacts.csv` (match on company name or domain).

**Output:** `pending_approval/RUN_ID/leads_raw.csv` with headers:
`company,contact_name,contact_title,email,phone,whatsapp,website,linkedin,city,country,materials,evidence_url,why_qualified`
Also record: `RAW_COUNT` (number of rows).

### Stage 2 — STRATEGY AGENT (score + fit + drafts)
**Role:** qualification against the master plan. Runs AFTER Stage 1 completes.

1. Score each lead 0–100: confirmed stone importer +30 · imports from India or switchable origin (Brazil/Turkey/China) +25 · named decision-maker with direct email +15 · phone/WhatsApp +10 · priority geography +10 · size signal (warehouse/multi-location/$5M+) +10.
2. Tier: ≥60 = Tier 1 · 40–59 = Tier 2 · <40 = REJECT (log reason).
3. For every Tier 1 lead, draft the personalized Day-1 email by filling the tokens in `marketing/sequences/us_tariff_email_1_day1.md` (US) or Touch-1 in `marketing/sequences/gulf_whatsapp_sequence.md` (Gulf). Save each to `pending_approval/RUN_ID/drafts/[company-slug].md`. **Drafts only — never send.**
4. **Output:** `pending_approval/RUN_ID/leads_scored.csv` = raw headers + `score,tier,sequence_assigned,draft_file`. Record `SCORED_COUNT`, `TIER1_COUNT`, `REJECTED_COUNT`.

### Stage 3 — GOVERNING AGENT (parity check + compliance) — MUST be a separate agent/pass from Stages 1–2
**Role:** independent verifier. Recomputes everything; trusts nothing from prior stages.

**Parity checks (all must PASS):**
| # | Check | Rule |
|---|-------|------|
| P1 | Count reconciliation | RAW_COUNT = SCORED_COUNT = TIER1+TIER2+REJECTED (recount the actual CSV rows yourself) |
| P2 | Dedup parity | Zero rows matching `lead_ledger.csv` or `scored_master_contacts.csv` (recheck independently, company AND domain) |
| P3 | Schema parity | Every row has all required columns non-empty: company, contact_name, country, ≥1 contact channel, evidence_url |
| P4 | Draft parity | Every Tier 1 row has an existing draft file; every draft has zero unfilled [TOKENS] |
| P5 | Evidence spot-check | Open 3 random evidence_urls — company is real and matches the claim |

**Compliance checks (all must PASS):**
| # | Check | Rule |
|---|-------|------|
| C1 | No-send guarantee | No email/message was sent by this run (no send-capable tool calls occurred) |
| C2 | Domain rule | Every draft's operator notes say send-from secondary domain; zero references to sending from divyastones.com |
| C3 | Market discipline | Leads only from US/Gulf (plan §1); anything else → REJECT |
| C4 | Honesty | No fabricated contacts: every email/phone traceable to evidence_url. Suspicious rows → REJECT with reason |

**Output:** `pending_approval/RUN_ID/governance_report.md` — every check with PASS/FAIL + evidence, rejected-lead list with reasons, and a final line: `RECOMMENDATION: APPROVE` (all pass) or `RECOMMENDATION: HOLD — [reason]` (any fail). **A failed parity check means the batch is queued as HOLD, never silently fixed.**

### Stage 4 — Ledger + Queue + Commit
1. Append every lead (all tiers incl. rejected) to `lead_ledger.csv` with status `pending` / `rejected`.
2. Add a row to `approval_queue.md`: run id, date, counts, recommendation, path.
3. `git add marketing/lead_engine/ && git commit -m "Lead engine RUN_ID: X leads (Y Tier1) — [APPROVE/HOLD]" && git push origin claude/marketing-email-drafts-cpZlm` (pull --rebase first if push rejected).
4. End the run with a short summary: counts, recommendation, top 3 leads by score.

## Failure Handling
- Any stage errors → write `pending_approval/RUN_ID/FAILED.md` with the error, commit what exists, mark run FAILED in approval_queue.md. Never leave uncommitted work.
- Web search yields <5 qualified leads → smaller batch is fine; note it in the governance report. Never pad with weak leads to hit quota.

## Human Approval Protocol (the only path to outreach)
1. Owner reviews `pending_approval/RUN_ID/` (leads_scored.csv + drafts + governance report).
2. To approve: tell Claude in any session "approve lead batch RUN_ID" → statuses flip to `approved` in lead_ledger.csv, leads merge into `scored_master_contacts.csv`, drafts move to the send queue for manual sending per `weekly_cadence.md`.
3. To reject rows: "reject [company] from RUN_ID — [reason]" → status `rejected`, reason logged (feeds C4/dedup learning).
4. **Nothing is contacted until a human approves. No exceptions.**
