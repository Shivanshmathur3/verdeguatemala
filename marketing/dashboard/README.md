# Export Command Center — Dashboard

A single self-contained `index.html` that aggregates the entire Divya Stones campaign:
leads, tiers, regional coverage, conversion funnel, 90-day forecast, lead-engine run
status, growth experiments, automation health, and one-click links to every asset.

## How it's connected
`build_dashboard.py` reads the **live repo files** each time it runs — no data is hand-typed:

| Panel | Source file(s) |
|-------|----------------|
| Lead tiers + regional bars | `scored_master_contacts.csv` |
| Latest engine run table | `lead_engine/pending_approval/run_*/candidate_companies.csv` |
| Contact list counts | `usa_/eu_/middleeast_stone_importers.csv`, jewellery list |
| Conversion funnel + scenarios | `reports/sales_forecast_q3_2026.md` figures |
| Asset library links | `reports/`, `sequences/`, `proposals/`, `linkedin_creatives/`, plans |
| Agent roster | `.claude/agents/*.md` |
| Growth experiments | `growth_experiments/active_experiments.md` |

## Refresh it
```bash
python3 marketing/dashboard/build_dashboard.py
```
Regenerates `index.html`. The lead engine runs this automatically at the end of every
daily run (PIPELINE.md Stage 4), so the committed dashboard always reflects the latest data.

## View it
- **Open locally:** open `marketing/dashboard/index.html` in any browser (offline, self-contained).
- **Hosted preview:** published as a Claude Artifact — a snapshot at publish time.
- **"Open" links** point to GitHub blob URLs, so they work from anywhere.

## Design
Operational treatment grounded in the product: Verde Guatemala green accent on warm
stone-grey neutrals, Georgia/serif headings with tabular-numeric data type, semantic
status pills (green=good, amber=attention, blue=info). Light + dark themes, responsive.
No external assets or fonts — CSP-safe, works fully offline.
