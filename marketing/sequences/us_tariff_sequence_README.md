# US Post-Tariff 5-Touch Cold Email Sequence — Index & Usage Rules

**Implements:** `marketing/MASTER_ACQUISITION_PLAN.md`, Section 2 ("US cold email — 5 touches / 21 days")
**Market:** United States, Priority 1 (60% of effort) — post-tariff restocking window (tariff struck down Feb 20, 2026; collection ended Feb 24)
**Targets:** slab importers/distributors, then large fabricators ($5M+), then commercial GCs (cut-to-size only)
**Geography:** TX, FL, CA, NY, GA — ports of Houston, Miami/Port Everglades, LA/Long Beach, NY/NJ, Savannah

---

## Sequence index

| Touch | Day | File | Angle | Single CTA |
|---|---|---|---|---|
| 1 | Day 1 | `us_tariff_email_1_day1.md` | Tariff-removal hook + landed-cost comparison vs. 2025 | "Worth a quote?" |
| 2 | Day 4 | `us_tariff_email_2_day4.md` | Full-slab photos + indicative FOB in the body | Reply "QUOTE" |
| 3 | Day 9 | `us_tariff_email_3_day9.md` | Consistency proof: packing, tolerance, resin, loading photos | Reply for packing spec |
| 4 | Day 14 | `us_tariff_email_4_day14.md` | 90-second facility video | 15-minute call |
| 5 | Day 21 | `us_tariff_email_5_day21.md` | Breakup — WhatsApp left as the open door | Save/message WhatsApp |

---

## Personalization tokens (filled from customs data — Volza / ImportGenius / Panjiva)

| Token | Source | Example fill |
|---|---|---|
| `[FIRST_NAME]` | LinkedIn / enrichment | "Mark" |
| `[COMPANY]` | Customs record consignee | "Lone Star Stone Distributors" |
| `[MATERIALS_THEY_IMPORT]` | Customs HS-code + product descriptions | "Steel Grey and Black Galaxy granite" |
| `[PORT]` | Customs record port of unlading | "Houston" |
| `[CURRENT_SUPPLIER_COUNTRY]` | Customs record country of origin | "Brazil" |
| `[MATERIAL_1..3]`, `[FOB_PRICE_1..3]`, `[LOT_NO_*]`, `[THICKNESS]` | Current price list + live inventory | "Steel Grey", "28", "SG-2607", "2cm" |
| `[SLAB_PHOTO_*]`, `[CONTAINER_LOADING_PHOTO_*]`, `[FACILITY_VIDEO_LINK]` | `marketing/proof_assets/` | real lot photos, unlisted video URL |
| `[SENDER_NAME]` | Sending mailbox owner | — |

**Rule: no customs data, no sequence.** Prospects without a verified import profile do not enter this sequence — they get a different track. Pitch what the buyer already imports (granite, marble, quartz, porcelain, veneer) — not only Verde Guatemala.

---

## Day 1 subject line — 6 A/B variants

**Tariff-angle:**
1. `The 50% tariff is gone — [MATERIALS_THEY_IMPORT] math for [COMPANY]`
2. `Indian stone landed cost just dropped 30%+ — [COMPANY]`

**Material-specific:**
3. `[MATERIALS_THEY_IMPORT] — FOB direct from India, into [PORT]`
4. `[COMPANY]: [MATERIALS_THEY_IMPORT] without the [CURRENT_SUPPLIER_COUNTRY] premium`

**Question format:**
5. `Still paying 2025 prices for [MATERIALS_THEY_IMPORT]?`
6. `Have you re-run your [MATERIALS_THEY_IMPORT] landed cost since February?`

### A/B testing rules
- Test 2 variants at a time on the first 20% of each list; send the winner to the rest.
- Change ONE variable per test (subject only, or CTA only — never both).
- Minimum 10 recipients per variant.
- **Winning metric: reply rate, not open rate** — opens don't pay bills.
- Log every test in `marketing/ab_tests.csv`.

---

## Sending rules (non-negotiable — Plan Section 2 infrastructure)

1. **Never send cold volume from divyastones.com.** Secondary domains only (divyastonesexport.com, divyastone.co), 2–3 mailboxes per domain, warmed 2–3 weeks, SPF/DKIM/DMARC live before touch 1.
2. **Max 150 words per email body. One CTA per email.** No walls of text, no double asks.
3. **Any reply removes the prospect from the sequence immediately.** A human takes over; quote/sample out within 24–48h — if quote turnaround exceeds 48h in any week, stop adding volume and fix operations (Plan Section 8).
4. **Day 21 is final.** After the breakup email, no further sequence emails — nurture pool only (LinkedIn, quarterly touches, inbound WhatsApp).
5. **Parallel channels:** LinkedIn connect (no pitch) alongside the sequence; prospects with 2+ opens and no reply by Day 9 enter the cold-call queue (`marketing/scripts/us_cold_call_script.md`).
6. **Log every send and outcome** in the CRM and `marketing/conversion_tracker.csv` (by email number and subject line, weekly review).
7. **Health check:** reply rate below 1.5% after 3 weeks means fix the list or the hook — NOT the volume.
8. **Verify FOB fills against the live price list on every batch.** Stale pricing in Day 4 destroys credibility with buyers who track the market.
