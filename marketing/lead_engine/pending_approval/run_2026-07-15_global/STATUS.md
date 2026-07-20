# Run 2026-07-15 Global — STATUS: PARTIAL (interrupted)

## What happened
The global sweep launched 5 parallel finder agents (US, Gulf, UK/Ireland, Canada, ANZ+SE Asia).
All 5 hit the **account session limit** (resets 02:50 UTC) mid-research — before any agent wrote its CSV.
No fabricated data was saved. Their progress notes named real companies (e.g. Alfurat — listed in the
NEOM suppliers directory; Baasar, Shankar Trades World, Universal Granite NZ) but contact details were
not captured, so those are NOT recorded here — recording unverified contacts would violate the engine's
no-invented-contacts rule (C4).

## What WAS captured (main-thread WebSearch, budget separate from the exhausted subagent pool)
`candidate_companies.csv` — 9 real, evidence-backed companies across 3 regions:
- **USA (6):** Granite Liquidators, Colorado Stone Imports, Natural Stone Sales (Denver); Cactus Stone,
  The Stone Collection, Mexi-Tile (Phoenix) — all confirmed or likely direct India importers
- **UK (3):** Paving Slabs Direct, Paving Slabs UK/Westone, Stone Paving Direct — all confirmed direct
  Indian sandstone importers (exact fit for Divya's sandstone/cobbles/porcelain lines)

Every row has a real website + evidence URL + a draft personalization hook.
**contact_name/email = PENDING ENRICHMENT** — deliberately not invented.

## Next step (automatic — no action needed)
The deployed engine resumes on its own:
- Session cron `7eee32c2` fires daily 06:53 IST
- GitHub Actions `lead-engine.yml` fires daily (once ANTHROPIC_API_KEY secret is added)

When the limit resets, the next run will (a) enrich these 9 candidates to full named-contact leads via
contact-enricher, and (b) complete the Gulf/Canada/ANZ/SE-Asia quotas that were cut off.

## To resume manually after 02:50 UTC
Say "run the global lead sweep" and the 5 finders relaunch, skipping these 9 already-captured companies.
