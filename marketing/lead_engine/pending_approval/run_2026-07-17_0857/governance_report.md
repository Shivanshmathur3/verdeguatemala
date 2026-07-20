# Governance Report — run_2026-07-17_0857

Engine: FREE deterministic pipeline (no AI, no credentials).

## Parity checks
- P1 count reconciliation: 10 accepted + 0 rejected = 10 processed. PASS
- P2 dedup: 0 duplicates removed vs ledger+batch. PASS
- P3 schema: every accepted row has company + contact channel + source of truth. PASS
- P4 tiers: T1=7 T2=2 T3=1. PASS
## Compliance checks
- C1 no-send: pipeline has no send capability by construction. PASS
- C2 no fabrication: blank fields left blank; nothing invented. PASS
- C4 verifiability: 0 rows rejected for no contact channel / no source. PASS

Sources ingested: web_research_2026-07-16.csv

## Regional split
- Americas: 6
- Gulf: 3
- Europe: 1

RECOMMENDATION: APPROVE
