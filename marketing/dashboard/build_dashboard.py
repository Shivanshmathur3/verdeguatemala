#!/usr/bin/env python3
"""
Divya Stones — Global Export Command Center dashboard generator.

Reads the live campaign files across the repo and emits a single self-contained
index.html. Re-run it any time (or from the lead engine) to refresh the numbers.

    python3 marketing/dashboard/build_dashboard.py

No third-party dependencies. Safe to run repeatedly.
"""
import csv, os, glob, html, datetime, json, urllib.parse

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MK   = os.path.join(REPO, "marketing")
GH   = "https://github.com/Shivanshmathur3/verdeguatemala/blob/claude/marketing-email-drafts-cpZlm"

def rows(path):
    p = os.path.join(REPO, path)
    if not os.path.exists(p): return []
    with open(p, newline="", encoding="utf-8", errors="replace") as f:
        return [r for r in csv.DictReader(f)]

def count(path):
    p = os.path.join(REPO, path)
    if not os.path.exists(p): return 0
    with open(p, encoding="utf-8", errors="replace") as f:
        return max(0, sum(1 for _ in f) - 1)

def files(pattern):
    return sorted(glob.glob(os.path.join(REPO, pattern)))

GULF = {"UAE","SAUDI ARABIA","SAUDI","QATAR","OMAN","KUWAIT","BAHRAIN"}
EURO = {"GERMANY","ITALY","SPAIN","UK","UNITED KINGDOM","NETHERLANDS","BELGIUM","FRANCE","IRELAND","PORTUGAL"}
AMER = {"USA","UNITED STATES","US","CANADA"}

def region_of(country):
    c = (country or "").strip().upper()
    if c in GULF: return "Gulf"
    if c in EURO: return "Europe"
    if c in AMER: return "Americas"
    if c: return "Other"
    return "Unknown"

# ---- gather live data --------------------------------------------------------
scored = rows("marketing/scored_master_contacts.csv")
tiers = {"1":0,"2":0,"3":0}
regions = {}
for r in scored:
    t = (r.get("Tier") or "").strip()
    if t in tiers: tiers[t]+=1
    reg = region_of(r.get("Country"))
    regions[reg] = regions.get(reg,0)+1

candidates = rows("marketing/lead_engine/pending_approval/run_2026-07-15_global/candidate_companies.csv")
cand_regions = {}
for r in candidates:
    reg = region_of(r.get("country"))
    cand_regions[reg] = cand_regions.get(reg,0)+1

contact_lists = [
    ("USA stone importers (enriched)", "marketing/usa_stone_importers_enriched.csv"),
    ("Middle East stone importers",    "marketing/middleeast_stone_importers.csv"),
    ("EU stone importers",             "marketing/eu_stone_importers.csv"),
    ("India jewellery importers (USA)", "marketing/india_jewelry_importers_usa.csv"),
]
contacts_total = sum(count(p) for _,p in contact_lists)

agents      = files(".claude/agents/*.md")
sequences   = files("marketing/sequences/*.md")
mailers     = files("marketing/sequences/mailer_usa_*.html")
reports     = files("marketing/reports/*.md")
creatives   = files("marketing/linkedin_creatives/*.html")
pricing     = files("proposals/pricing_sheet_*.html")
proposals   = files("proposals/*.md") + files("proposals/*.html")

# growth experiments (active)
experiments = [
    ("EXP-001","Customs-data reverse-targeting (US tariff hook)",504,"lead-gen","running"),
    ("EXP-002","WhatsApp named-video selling (Gulf)",448,"conversion","running"),
    ("EXP-003","Tariff-reset content + FOB benchmark",384,"inbound","running"),
]

# forecast (from reports/sales_forecast_q3_2026.md — narrative figures)
forecast = {
    "leads": 87, "t1": 41, "t2": 26, "t3": 20,
    "funnel": [("Prospects contacted",1200),("Replies (2–5%)",42),
               ("Quote / sample requests",20),("Proposals sent",12),("Containers closed",3)],
    "scenarios": [("Pessimistic (90d)",90),("Realistic (90d)",171),("Optimistic (90d)",342)],
    "realistic90": "$36K–54K", "optimistic90": "$72K–90K",
}

now = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")

# WhatsApp one-tap click-to-send entries
wa_sends = []
wa_path = os.path.join(REPO, "marketing/lead_engine/whatsapp_sends.json")
if os.path.exists(wa_path):
    try:
        wa_sends = json.load(open(wa_path, encoding="utf-8")).get("sends", [])
    except Exception:
        wa_sends = []

def wa_link(number, message):
    return f"https://wa.me/{number}?text={urllib.parse.quote(message)}"

# ---- html helpers ------------------------------------------------------------
def esc(s): return html.escape(str(s if s is not None else ""))

def stat(label, value, sub=""):
    return f'''<div class="stat"><div class="stat-val">{value}</div>
      <div class="stat-lab">{esc(label)}</div>{f'<div class="stat-sub">{sub}</div>' if sub else ''}</div>'''

def pill(text, kind):
    return f'<span class="pill pill-{kind}">{esc(text)}</span>'

def bar(label, val, maxv, kind="accent"):
    pct = 0 if maxv==0 else round(100*val/maxv)
    return f'''<div class="bar-row"><div class="bar-lab">{esc(label)}</div>
      <div class="bar-track"><div class="bar-fill bar-{kind}" style="width:{pct}%"></div></div>
      <div class="bar-num">{val}</div></div>'''

def linkcard(title, href, meta=""):
    return f'''<a class="lc" href="{esc(href)}" target="_blank" rel="noopener">
      <span class="lc-t">{esc(title)}</span>{f'<span class="lc-m">{esc(meta)}</span>' if meta else ''}
      <span class="lc-arrow">&#8599;</span></a>'''

maxreg = max(regions.values()) if regions else 1
region_bars = "".join(bar(k, regions[k], maxreg, "accent")
                      for k in sorted(regions, key=lambda x:-regions[x]))

fmax = forecast["funnel"][0][1]
funnel_html = "".join(
    f'''<div class="fn-step"><div class="fn-bar" style="width:{max(6,round(100*v/fmax))}%"></div>
    <div class="fn-lab">{esc(l)}</div><div class="fn-val">{v:,}</div></div>'''
    for l,v in forecast["funnel"])

smax = max(v for _,v in forecast["scenarios"])
scen_html = "".join(bar(l, v, smax, "gold" if "Realistic" in l else "muted")
                    for l,v in forecast["scenarios"])

wa_cards = []
for s in wa_sends:
    ready = s.get("verified") and s.get("number")
    if ready:
        href = wa_link(s["number"], s["message"])
        btn = f'<a class="wa-btn" href="{esc(href)}" target="_blank" rel="noopener">Send on WhatsApp &#8599;</a>'
        badge = pill("number verified", "good")
    else:
        btn = '<span class="wa-btn wa-btn-off">number needed</span>'
        badge = pill("find number first", "warn")
    note = f'<div class="wa-note">{esc(s["note"])}</div>' if s.get("note") else ""
    wa_cards.append(f'''<div class="wa-card">
      <div class="wa-head"><span class="wa-co">{esc(s["company"])}</span>{badge}</div>
      <div class="wa-city">{esc(s.get("city",""))}</div>
      <div class="wa-msg">{esc(s["message"][:150])}…</div>{note}{btn}</div>''')
wa_html = "".join(wa_cards) if wa_cards else '<div class="notice">No WhatsApp sends staged yet.</div>'

exp_html = "".join(
    f'''<div class="exp"><div class="exp-head"><span class="exp-id">{esc(i)}</span>
    {pill(st, "good" if st=="running" else "warn")}</div>
    <div class="exp-name">{esc(n)}</div>
    <div class="exp-meta"><span>ICE {ice}</span><span>{esc(cat)}</span></div></div>'''
    for i,n,ice,cat,st in experiments)

def agent_name(p): return os.path.basename(p)[:-3]
agents_html = "".join(f'<span class="chip">{esc(agent_name(a))}</span>' for a in agents)

cand_html = "".join(
    f'''<tr><td>{esc(r.get("company"))}</td><td>{esc(r.get("city"))} · {esc(r.get("country"))}</td>
    <td class="td-mat">{esc((r.get("materials") or "")[:42])}</td>
    <td>{pill("India ✓" if (r.get("india_import_confirmed","")=="YES") else "likely",
              "good" if r.get("india_import_confirmed","")=="YES" else "info")}</td></tr>'''
    for r in candidates)

def linkgroup(title, items):
    inner = "".join(items)
    return f'<div class="grp"><h3>{esc(title)}</h3><div class="lc-wrap">{inner}</div></div>'

reports_links = [linkcard(os.path.basename(p).replace("_"," ").replace(".md",""),
                          f"{GH}/marketing/reports/{os.path.basename(p)}") for p in reports]
plan_links = [
    linkcard("Master Acquisition Plan", f"{GH}/marketing/MASTER_ACQUISITION_PLAN.md","strategy of record"),
    linkcard("90-Day Timeline", f"{GH}/marketing/90_day_timeline.md"),
    linkcard("Weekly Cadence", f"{GH}/marketing/weekly_cadence.md"),
    linkcard("KPI Tracker", f"{GH}/marketing/kpi_weekly_tracker.csv","13 weeks"),
    linkcard("BCT Lite v2 Manual", f"{GH}/docs/BCT_Lite_v2_Replication_Manual.md"),
]
engine_links = [
    linkcard("Lead Engine Pipeline", f"{GH}/marketing/lead_engine/PIPELINE.md","4-stage + parity"),
    linkcard("Approval Queue", f"{GH}/marketing/lead_engine/approval_queue.md"),
    linkcard("Latest run (2026-07-15)", f"{GH}/marketing/lead_engine/pending_approval/run_2026-07-15_global/STATUS.md","partial"),
    linkcard("GitHub Actions workflow", f"{GH}/.github/workflows/lead-engine.yml","daily 06:53 IST"),
]
seq_links = [
    linkcard("US tariff sequence (5 touches)", f"{GH}/marketing/sequences/us_tariff_sequence_README.md"),
    linkcard("Gulf WhatsApp sequence", f"{GH}/marketing/sequences/gulf_whatsapp_sequence.md"),
    linkcard("Sales scripts", f"{GH}/marketing/scripts/sales_scripts.md"),
    linkcard("Objection map", f"{GH}/marketing/objection_map.md"),
    linkcard(f"USA HTML mailers", f"{GH}/marketing/sequences/mailer_index.md", f"{len(mailers)} personalized"),
]
asset_links = [
    linkcard(f"Pricing sheets", f"{GH}/proposals", f"{len(pricing)} markets"),
    linkcard("Proforma invoice template", f"{GH}/proposals/proforma_invoice_template.html"),
    linkcard("Sales proposal template", f"{GH}/proposals/sales_proposal_template.html"),
    linkcard(f"LinkedIn creatives", f"{GH}/marketing/linkedin_creatives/post_captions.md", f"{len(creatives)} posts"),
    linkcard("Content calendar (30-day)", f"{GH}/marketing/social_outreach/content_calendar_july2026.md"),
]

HTML = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Divya Stones — Export Command Center</title>
<style>
:root {{
  --bg:#F2F1EA; --panel:#FBFAF5; --panel-2:#F6F5EE; --ink:#1C231A; --ink-soft:#586052;
  --line:#DEDCCF; --accent:#2F6B3C; --accent-soft:#E4EBDD; --gold:#A6843F;
  --good:#2E7D46; --good-bg:#E2EFE3; --warn:#9C6A1E; --warn-bg:#F3E9D3;
  --crit:#A8402E; --crit-bg:#F3DED8; --info:#3C6377; --info-bg:#DDE8ED;
  --mono:ui-monospace,"SF Mono",Menlo,Consolas,monospace;
  --sans:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  --serif:"Iowan Old Style","Palatino Linotype",Palatino,Georgia,"Times New Roman",serif;
}}
@media (prefers-color-scheme:dark) {{
  :root {{
    --bg:#11150F; --panel:#191E15; --panel-2:#1F251A; --ink:#EAEDE4; --ink-soft:#9AA391;
    --line:#2C3326; --accent:#5FA46E; --accent-soft:#233021; --gold:#C6A768;
    --good:#5FA46E; --good-bg:#20301F; --warn:#C6942E; --warn-bg:#33280F;
    --crit:#D26A55; --crit-bg:#331C16; --info:#6FA0B4; --info-bg:#182A31;
  }}
}}
:root[data-theme="light"] {{
  --bg:#F2F1EA; --panel:#FBFAF5; --panel-2:#F6F5EE; --ink:#1C231A; --ink-soft:#586052;
  --line:#DEDCCF; --accent:#2F6B3C; --accent-soft:#E4EBDD; --gold:#A6843F;
  --good:#2E7D46; --good-bg:#E2EFE3; --warn:#9C6A1E; --warn-bg:#F3E9D3;
  --crit:#A8402E; --crit-bg:#F3DED8; --info:#3C6377; --info-bg:#DDE8ED;
}}
:root[data-theme="dark"] {{
  --bg:#11150F; --panel:#191E15; --panel-2:#1F251A; --ink:#EAEDE4; --ink-soft:#9AA391;
  --line:#2C3326; --accent:#5FA46E; --accent-soft:#233021; --gold:#C6A768;
  --good:#5FA46E; --good-bg:#20301F; --warn:#C6942E; --warn-bg:#33280F;
  --crit:#D26A55; --crit-bg:#331C16; --info:#6FA0B4; --info-bg:#182A31;
}}
* {{ box-sizing:border-box; }}
body {{ margin:0; background:var(--bg); color:var(--ink); font-family:var(--sans);
  line-height:1.5; -webkit-font-smoothing:antialiased; }}
.wrap {{ max-width:1180px; margin:0 auto; padding:26px 22px 60px; }}
.tnum {{ font-variant-numeric:tabular-nums; font-family:var(--mono); }}

header.top {{ display:flex; align-items:flex-start; justify-content:space-between; gap:16px;
  border-bottom:1px solid var(--line); padding-bottom:20px; margin-bottom:24px; flex-wrap:wrap; }}
.brand h1 {{ font-family:var(--serif); font-weight:600; font-size:29px; margin:0; letter-spacing:.01em;
  text-wrap:balance; }}
.brand .sub {{ color:var(--ink-soft); font-size:13px; margin-top:4px; letter-spacing:.02em; }}
.brand .mark {{ display:inline-block; width:9px; height:9px; border-radius:2px; background:var(--accent);
  margin-right:8px; transform:rotate(45deg); }}
.top-right {{ display:flex; flex-direction:column; align-items:flex-end; gap:8px; }}
.phase {{ font-size:12px; color:var(--ink-soft); }}
.gen {{ font-size:11px; color:var(--ink-soft); font-family:var(--mono); }}
.toggle {{ background:var(--panel); border:1px solid var(--line); color:var(--ink); cursor:pointer;
  font-size:12px; padding:6px 12px; border-radius:7px; font-family:var(--sans); }}
.toggle:hover {{ border-color:var(--accent); }}
.toggle:focus-visible {{ outline:2px solid var(--accent); outline-offset:2px; }}

.stats {{ display:grid; grid-template-columns:repeat(4,1fr); gap:14px; margin-bottom:26px; }}
.stat {{ background:var(--panel); border:1px solid var(--line); border-radius:12px; padding:16px 18px;
  border-left:3px solid var(--accent); }}
.stat-val {{ font-family:var(--serif); font-size:32px; font-weight:600; line-height:1;
  font-variant-numeric:tabular-nums; }}
.stat-lab {{ font-size:12px; color:var(--ink-soft); margin-top:7px; text-transform:uppercase;
  letter-spacing:.06em; }}
.stat-sub {{ font-size:12px; color:var(--accent); margin-top:3px; font-weight:600; }}

.cols {{ display:grid; grid-template-columns:1.55fr 1fr; gap:20px; align-items:start; }}
.card {{ background:var(--panel); border:1px solid var(--line); border-radius:12px; padding:18px 20px;
  margin-bottom:20px; }}
.card h2 {{ font-family:var(--serif); font-size:17px; font-weight:600; margin:0 0 14px;
  display:flex; align-items:center; justify-content:space-between; }}
.card h2 .eyebrow {{ font-family:var(--sans); font-size:11px; font-weight:600; letter-spacing:.08em;
  text-transform:uppercase; color:var(--ink-soft); }}

.pill {{ font-size:11px; font-weight:600; padding:2px 9px; border-radius:20px; letter-spacing:.02em;
  white-space:nowrap; }}
.pill-good {{ background:var(--good-bg); color:var(--good); }}
.pill-warn {{ background:var(--warn-bg); color:var(--warn); }}
.pill-crit {{ background:var(--crit-bg); color:var(--crit); }}
.pill-info {{ background:var(--info-bg); color:var(--info); }}

.fn-step {{ margin-bottom:9px; }}
.fn-bar {{ height:26px; background:linear-gradient(90deg,var(--accent),var(--gold)); border-radius:5px;
  min-width:6%; }}
.fn-lab {{ display:inline-block; font-size:12.5px; color:var(--ink-soft); margin-top:4px; }}
.fn-val {{ float:right; font-family:var(--mono); font-size:12.5px; font-weight:600; margin-top:4px;
  font-variant-numeric:tabular-nums; }}

.bar-row {{ display:grid; grid-template-columns:120px 1fr 42px; align-items:center; gap:10px;
  margin-bottom:8px; }}
.bar-lab {{ font-size:12.5px; color:var(--ink-soft); }}
.bar-track {{ background:var(--panel-2); border:1px solid var(--line); height:16px; border-radius:8px;
  overflow:hidden; }}
.bar-fill {{ height:100%; }}
.bar-accent {{ background:var(--accent); }}
.bar-gold {{ background:var(--gold); }}
.bar-muted {{ background:var(--ink-soft); opacity:.55; }}
.bar-num {{ font-family:var(--mono); font-size:12.5px; text-align:right; font-variant-numeric:tabular-nums; }}

.tier-grid {{ display:grid; grid-template-columns:repeat(3,1fr); gap:10px; margin-bottom:4px; }}
.tier {{ text-align:center; border:1px solid var(--line); border-radius:9px; padding:11px 6px;
  background:var(--panel-2); }}
.tier b {{ font-family:var(--serif); font-size:26px; display:block; font-variant-numeric:tabular-nums; }}
.tier span {{ font-size:11px; color:var(--ink-soft); text-transform:uppercase; letter-spacing:.05em; }}
.tier.t1 {{ border-color:var(--accent); }} .tier.t1 b {{ color:var(--accent); }}

table {{ width:100%; border-collapse:collapse; font-size:12.5px; }}
.tbl-wrap {{ overflow-x:auto; }}
th {{ text-align:left; font-size:11px; text-transform:uppercase; letter-spacing:.05em; color:var(--ink-soft);
  border-bottom:1px solid var(--line); padding:6px 8px; font-weight:600; }}
td {{ padding:7px 8px; border-bottom:1px solid var(--line); vertical-align:top; }}
tr:last-child td {{ border-bottom:none; }}
.td-mat {{ color:var(--ink-soft); }}

.exp {{ border:1px solid var(--line); border-radius:9px; padding:11px 13px; margin-bottom:10px;
  background:var(--panel-2); }}
.exp-head {{ display:flex; justify-content:space-between; align-items:center; }}
.exp-id {{ font-family:var(--mono); font-size:11.5px; font-weight:600; color:var(--gold); }}
.exp-name {{ font-size:13px; margin:6px 0 5px; }}
.exp-meta {{ display:flex; gap:14px; font-size:11.5px; color:var(--ink-soft); font-family:var(--mono); }}

.chips {{ display:flex; flex-wrap:wrap; gap:6px; }}
.chip {{ font-size:11px; background:var(--accent-soft); color:var(--accent); border-radius:6px;
  padding:3px 8px; font-family:var(--mono); }}

.grp {{ margin-bottom:16px; }}
.grp h3 {{ font-size:11px; text-transform:uppercase; letter-spacing:.07em; color:var(--ink-soft);
  margin:0 0 8px; font-weight:600; }}
.lc-wrap {{ display:flex; flex-direction:column; gap:6px; }}
.lc {{ display:flex; align-items:center; gap:8px; text-decoration:none; color:var(--ink);
  border:1px solid var(--line); border-radius:8px; padding:8px 11px; background:var(--panel-2);
  font-size:13px; transition:border-color .12s, background .12s; }}
.lc:hover {{ border-color:var(--accent); background:var(--accent-soft); }}
.lc:focus-visible {{ outline:2px solid var(--accent); outline-offset:1px; }}
.lc-t {{ flex:1; }}
.lc-m {{ font-size:11px; color:var(--ink-soft); font-family:var(--mono); }}
.lc-arrow {{ color:var(--accent); font-size:13px; }}

.wa-card {{ border:1px solid var(--line); border-radius:9px; padding:11px 13px; margin-bottom:10px;
  background:var(--panel-2); }}
.wa-head {{ display:flex; justify-content:space-between; align-items:center; gap:8px; }}
.wa-co {{ font-weight:600; font-size:13.5px; }}
.wa-city {{ font-size:11.5px; color:var(--ink-soft); margin-top:2px; }}
.wa-msg {{ font-size:11.5px; color:var(--ink-soft); margin:7px 0 9px; line-height:1.45; }}
.wa-note {{ font-size:11px; color:var(--warn); margin-bottom:8px; }}
.wa-btn {{ display:inline-block; background:#25D366; color:#0a2417; text-decoration:none; font-weight:600;
  font-size:12.5px; padding:7px 14px; border-radius:7px; }}
.wa-btn:hover {{ filter:brightness(1.06); }}
.wa-btn:focus-visible {{ outline:2px solid var(--accent); outline-offset:2px; }}
.wa-btn-off {{ background:var(--panel); color:var(--ink-soft); border:1px solid var(--line);
  cursor:default; font-weight:500; }}
.notice {{ font-size:12.5px; color:var(--ink-soft); border-top:1px solid var(--line); margin-top:8px;
  padding-top:10px; }}
footer {{ margin-top:34px; padding-top:18px; border-top:1px solid var(--line); font-size:12px;
  color:var(--ink-soft); display:flex; justify-content:space-between; flex-wrap:wrap; gap:8px; }}
@media (max-width:820px) {{
  .stats {{ grid-template-columns:repeat(2,1fr); }}
  .cols {{ grid-template-columns:1fr; }}
}}
</style>
</head>
<body>
<div class="wrap">

<header class="top">
  <div class="brand">
    <h1><span class="mark"></span>Divya Stones — Export Command Center</h1>
    <div class="sub">Global B2B stone-export campaign · Udaipur, India · US 60% · Gulf 30% · Global scout 10%</div>
  </div>
  <div class="top-right">
    <button class="toggle" id="themeBtn" aria-label="Toggle light or dark theme">◐ Theme</button>
    <div class="phase">Phase: <strong>Assets ready — pre-launch</strong></div>
    <div class="gen">generated {now}</div>
  </div>
</header>

<div class="stats">
  {stat("Leads in system", f'{len(scored)+len(candidates)}', f'{len(scored)} scored · {len(candidates)} new')}
  {stat("Tier 1 (act now)", tiers["1"], "highest-probability")}
  {stat("90-day forecast", forecast["realistic90"], "realistic · FOB")}
  {stat("Assets built", f'{len(agents)+len(sequences)+len(reports)+len(creatives)}', f'{len(agents)} agents · {len(reports)} reports')}
</div>

<div class="cols">
  <div class="main">

    <div class="card">
      <h2>Conversion funnel <span class="eyebrow">Q3 forecast · pre-launch baseline</span></h2>
      {funnel_html}
      <div class="notice">Realistic 90-day outcome <strong>{forecast['realistic90']} FOB</strong> (2–3 containers),
      upside <strong>{forecast['optimistic90']}</strong>. Source: sales_forecast_q3_2026.</div>
    </div>

    <div class="card">
      <h2>Lead tiers &amp; regional coverage <span class="eyebrow">scored master list</span></h2>
      <div class="tier-grid">
        <div class="tier t1"><b class="tnum">{tiers['1']}</b><span>Tier 1</span></div>
        <div class="tier"><b class="tnum">{tiers['2']}</b><span>Tier 2</span></div>
        <div class="tier"><b class="tnum">{tiers['3']}</b><span>Tier 3</span></div>
      </div>
      <div style="margin-top:14px">{region_bars}</div>
    </div>

    <div class="card">
      <h2>Lead engine — latest global run <span class="eyebrow">run 2026-07-15</span></h2>
      <div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:12px">
        {pill(f"{len(candidates)} candidates captured","good")}
        {pill("contacts pending enrichment","warn")}
        {pill("awaiting approval","info")}
      </div>
      <div class="tbl-wrap"><table>
        <thead><tr><th>Company</th><th>Location</th><th>Materials</th><th>India</th></tr></thead>
        <tbody>{cand_html}</tbody>
      </table></div>
      <div class="notice">5 finder agents were interrupted by an account limit mid-run; these {len(candidates)}
      were captured with verified evidence URLs. The daily engine completes enrichment automatically on reset.</div>
    </div>

    <div class="card">
      <h2>90-day revenue scenarios <span class="eyebrow">USD thousands</span></h2>
      {scen_html}
    </div>

  </div>

  <aside class="side">

    <div class="card">
      <h2>WhatsApp — one-tap send <span class="eyebrow">tap → review → send</span></h2>
      {wa_html}
      <div class="notice">Opens WhatsApp with the message pre-typed. Replace “[your name]”,
      glance, and hit send — nothing sends automatically.</div>
    </div>

    <div class="card">
      <h2>Growth experiments <span class="eyebrow">3 active</span></h2>
      {exp_html}
      <div class="notice">Self-refreshing engine — say “run the growth engine” every 2 weeks to rescore.</div>
    </div>

    <div class="card">
      <h2>Automation status</h2>
      <div class="lc-wrap">
        <div class="lc"><span class="lc-t">Daily lead engine (cron 06:53 IST)</span>{pill("armed","good")}</div>
        <div class="lc"><span class="lc-t">GitHub Actions runner</span>{pill("needs API key","warn")}</div>
        <div class="lc"><span class="lc-t">Approval gate before any send</span>{pill("enforced","good")}</div>
        <div class="lc"><span class="lc-t">Reply ingestion (BCT Lite v2)</span>{pill("designed","info")}</div>
      </div>
    </div>

    <div class="card">
      <h2>Contact lists</h2>
      <div class="lc-wrap">
        {"".join(f'<div class="lc"><span class="lc-t">{esc(n)}</span><span class="lc-m tnum">{count(p)}</span></div>' for n,p in contact_lists)}
        <div class="lc"><span class="lc-t"><strong>Scored master list</strong></span><span class="lc-m tnum">{len(scored)}</span></div>
      </div>
    </div>

  </aside>
</div>

<div class="card">
  <h2>Asset library <span class="eyebrow">everything, one click away</span></h2>
  <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:22px">
    {linkgroup("Strategy &amp; plans", plan_links)}
    {linkgroup("Lead engine", engine_links)}
    {linkgroup("Market research", reports_links)}
    {linkgroup("Sequences &amp; scripts", seq_links)}
    {linkgroup("Sales assets", asset_links)}
  </div>
</div>

<div class="card">
  <h2>Agent roster <span class="eyebrow">{len(agents)} specialists</span></h2>
  <div class="chips">{agents_html}</div>
</div>

<footer>
  <span>Divya Stones · sales@divyastones.com · +91-94141-67278</span>
  <span class="tnum">Rebuild: python3 marketing/dashboard/build_dashboard.py</span>
</footer>

</div>
<script>
(function(){{
  var root=document.documentElement, btn=document.getElementById('themeBtn');
  btn.addEventListener('click',function(){{
    var cur=root.getAttribute('data-theme');
    if(!cur){{ cur = matchMedia('(prefers-color-scheme:dark)').matches ? 'dark':'light'; }}
    root.setAttribute('data-theme', cur==='dark' ? 'light':'dark');
  }});
}})();
</script>
</body>
</html>
"""

out = os.path.join(os.path.dirname(__file__), "index.html")
with open(out, "w", encoding="utf-8") as f:
    f.write(HTML)
print(f"Dashboard written: {out}")
print(f"  {len(scored)} scored leads, {len(candidates)} candidates, {len(agents)} agents, "
      f"{len(reports)} reports, {len(sequences)} sequences")
