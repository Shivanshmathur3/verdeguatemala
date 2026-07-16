# Governance Report — run_2026-07-16_2115

Engine: FREE deterministic pipeline (no AI, no credentials).

## Parity checks
- P1 count reconciliation: 9 accepted + 0 rejected = 9 processed. PASS
- P2 dedup: 0 duplicates removed vs ledger+batch. PASS
- P3 schema: every accepted row has company + contact channel + source of truth. PASS
- P4 tiers: T1=2 T2=7 T3=0. PASS
## Compliance checks
- C1 no-send: pipeline has no send capability by construction. PASS
- C2 no fabrication: blank fields left blank; nothing invented. PASS
- C4 verifiability: 0 rows rejected for no contact channel / no source. PASS

Sources ingested: candidates_2026-07-15.csv

## Regional split
- Americas: 6
- Europe: 3

RECOMMENDATION: APPROVE
