# Lead Engine Inbox — Drop raw CSVs here

This is the fuel tank for the **free, no-AI lead pipeline**. Drop any importer/buyer
CSV export here, commit + push, and the pipeline (running 24/7 on GitHub Actions, no
credentials) normalizes → dedups → scores → tiers → queues it for your approval.

## What to drop
Any CSV with company + contact/website columns. The pipeline auto-maps common headers,
so exports from these work as-is:
- **ImportYeti / Volza / Panjiva** customs-data exports (your #1 source per the plan)
- **Trade-show exhibitor/attendee lists** (Coverings, TISE, Marmomac, Big 5)
- **Directory exports** (Natural Stone Institute, Stone Federation GB, chamber lists)
- **Any spreadsheet** you build by hand

Column names don't have to match — see `../pipeline/column_map.json` for the aliases
recognized (company, consignee, buyer, importer / email / phone / website / country /
materials / origin / port / evidence_url …). Unmatched columns are ignored; missing
fields stay blank (the pipeline never invents data).

## How it runs
1. You drop `whatever.csv` here and push.
2. GitHub Actions (free) runs `pipeline/normalize_and_score.py` on schedule (or on push).
3. New leads land in `../pending_approval/run_<date>/leads_scored.csv` with scores + tiers.
4. Processed source files move to `_processed/` so they're never re-ingested.
5. The dashboard rebuilds automatically.
6. You approve the batch.

## The scoring (deterministic — same rubric as the AI engine)
| Signal | Points |
|--------|--------|
| Stone/marble/granite importer | +30 |
| Imports from India | +25 (switchable origin +18) |
| Named contact + direct (non-generic) email | +15 |
| Phone / WhatsApp present | +10 |
| Priority geography (US / Gulf) | +10 |
| Distributor / warehouse / volume signal | +10 |

Tier 1 ≥ 60 · Tier 2 40–59 · Tier 3 < 40. Rows with no contact channel or no source of
truth are rejected (logged in the ledger), never contacted.

## Where to get free customs data
- ImportYeti — free searches, CSV export on many company pages
- Volza / Panjiva — free-tier previews, exportable samples
- Government trade portals (US Census USA Trade, EU Access2Markets) — open CSV downloads
- Trade-show sites publish exhibitor lists publicly — copy into a CSV

The more you drop in, the more the engine produces. It dedups forever, so volume
compounds into coverage.
