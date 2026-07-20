# A/B Subject Line Variants — Stone Importer Sequence, Email 1 (Day 0)

**Campaign:** Stone Importer Cold Outreach
**Email:** Day 0 — The Opener
**Test window:** Send variant to first 20% of list; deploy winner to remaining 80%
**Winning criteria:** Reply rate (not open rate)
**Minimum per variant:** 10 recipients

---

## Variant Group 1 — Name / City / Product Formula

These are the most personalised — highest perceived relevance, best for smaller, targeted lists.

| ID | Subject Line | Notes |
|----|-------------|-------|
| A1 | `[Company] — Verde Guatemala pricing, direct from [City]` | Baseline. Combines brand name + product + location signal. Use as control. |
| A2 | `[Company] — Indian Green Marble, FOB Udaipur` | Swaps city personalisation for technical buyer language (FOB). Tests whether buyers respond to trade terminology. |

---

## Variant Group 2 — Question Format

Questions create an open loop — the brain wants to resolve it. Best for lists where you know the contact's pain point.

| ID | Subject Line | Notes |
|----|-------------|-------|
| B1 | `Still sourcing Verde Guatemala through a broker?` | Direct pain-point challenge. High risk / high reward — works well if the list is confirmed broker-buyers. |
| B2 | `Where does [Company] currently source Indian green marble?` | Softer. Frames the email as discovery, not pitch. Lower friction for colder contacts. |

---

## Variant Group 3 — Social Proof Format

Borrow trust before the email is even opened. Best for lists in competitive, high-skepticism markets.

| ID | Subject Line | Notes |
|----|-------------|-------|
| C1 | `Why 40+ US importers source Verde Guatemala direct from Udaipur` | Specificity ("40+") signals scale. "Direct from Udaipur" triggers price curiosity. |
| C2 | `The quarry behind your competitors' Indian green marble` | Intrigue + competitive instinct. Works on buyers who track what their rivals stock. Use carefully — can feel presumptuous with very cold lists. |

---

## Variant Group 4 — Urgency / Scarcity Format

Creates a reason to act now rather than later. Must be true — do not use unless the lot or constraint is genuine.

| ID | Subject Line | Notes |
|----|-------------|-------|
| D1 | `[Company] — 2 containers of Forest Green left this shipment` | Hard scarcity. Only use when inventory genuinely constrains. High open rate when real; destroys trust if fabricated. |
| D2 | `Verde Guatemala pricing holds until end of [Month] — [Company]` | Deadline-based. Swap [Month] for the actual cutoff. Pairs well with a genuine price movement or shipping window. |

---

## Testing Log

Record results in `/home/user/verdeguatemala/marketing/ab_tests.csv`

| Date | Variant ID | Subject Line | Recipients | Opens | Open Rate | Replies | Reply Rate | Winner? | Notes |
|------|------------|-------------|------------|-------|-----------|---------|------------|---------|-------|
| | A1 | | | | | | | | Control |
| | A2 | | | | | | | | |
| | B1 | | | | | | | | |
| | B2 | | | | | | | | |
| | C1 | | | | | | | | |
| | C2 | | | | | | | | |
| | D1 | | | | | | | | |
| | D2 | | | | | | | | |

---

## Recommended Test Order

1. Start with A1 (control) vs. B1 (question / pain) — these are the most structurally different and will give the clearest signal
2. Once a winner emerges between A1 and B1, test the winner against C1 (social proof)
3. Only run D1 or D2 during periods when the scarcity claim is genuinely true

## Rules
- Change ONE variable per test (subject line only, or CTA only — never both simultaneously)
- Do not conclude a test with fewer than 10 recipients per variant
- Reply rate is the only metric that counts — opens alone do not pay bills
