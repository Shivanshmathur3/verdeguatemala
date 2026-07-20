# Governance Report — run_2026-07-20_0835

Engine: FREE deterministic pipeline (no AI, no credentials).

## Parity checks
- P1 count reconciliation: 6 accepted + 4 rejected = 10 processed. PASS
- P2 dedup: 4 duplicates removed vs ledger+batch. PASS
- P3 schema: every accepted row has company + contact channel + source of truth. PASS
- P4 tiers: T1=2 T2=4 T3=0. PASS
## Compliance checks
- C1 no-send: pipeline has no send capability by construction. PASS
- C2 no fabrication: blank fields left blank; nothing invented. PASS
- C4 verifiability: 0 rows rejected for no contact channel / no source. PASS

Sources ingested: web_research_2026-07-17.csv

## Regional split
- Americas: 4
- Gulf: 2

RECOMMENDATION: APPROVE
