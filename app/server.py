#!/usr/bin/env python3
"""
Divya Stones — Local Control Tower web app.

A multi-page, interactive local server. One page per function. Runs on your
machine and is reachable at http://127.0.0.1:8600 and http://<your-LAN-IP>:8600.

    pip install -r requirements.txt
    python server.py

Then open the printed URL. Runs until you stop it — see README for 24/7 setup.
"""
import html, os
from flask import Flask, request, redirect, url_for, Response
import data as D

app = Flask(__name__)
PORT = int(os.environ.get("BCT_PORT", "8600"))

NAV = [("/", "Overview"), ("/leads", "Leads"), ("/approvals", "Approvals"),
       ("/inbox", "Add Leads"), ("/whatsapp", "WhatsApp"), ("/runs", "Runs"),
       ("/drafts", "Drafts")]

def esc(s): return html.escape(str(s if s is not None else ""))

def page(title, body, active=""):
    nav = "".join(
        f'<a href="{p}" class="{"on" if p==active else ""}">{esc(t)}</a>' for p,t in NAV)
    return Response(f"""<!doctype html><html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{esc(title)} · Divya Stones Control Tower</title>
<style>
:root{{--bg:#F2F1EA;--panel:#FBFAF5;--p2:#F6F5EE;--ink:#1C231A;--soft:#586052;--line:#DEDCCF;
--accent:#2F6B3C;--asoft:#E4EBDD;--gold:#A6843F;--good:#2E7D46;--goodbg:#E2EFE3;--warn:#9C6A1E;
--warnbg:#F3E9D3;--info:#3C6377;--infobg:#DDE8ED;--crit:#A8402E;--critbg:#F3DED8;
--mono:ui-monospace,"SF Mono",Menlo,Consolas,monospace;--sans:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Arial,sans-serif;
--serif:"Iowan Old Style",Palatino,Georgia,serif;}}
@media(prefers-color-scheme:dark){{:root{{--bg:#11150F;--panel:#191E15;--p2:#1F251A;--ink:#EAEDE4;
--soft:#9AA391;--line:#2C3326;--accent:#5FA46E;--asoft:#233021;--gold:#C6A768;--good:#5FA46E;
--goodbg:#20301F;--warn:#C6942E;--warnbg:#33280F;--info:#6FA0B4;--infobg:#182A31;--crit:#D26A55;--critbg:#331C16;}}}}
*{{box-sizing:border-box}}body{{margin:0;background:var(--bg);color:var(--ink);font-family:var(--sans);line-height:1.5}}
.tnum{{font-variant-numeric:tabular-nums;font-family:var(--mono)}}
header{{background:var(--panel);border-bottom:1px solid var(--line);padding:0 20px;position:sticky;top:0;z-index:9}}
.hrow{{max-width:1180px;margin:0 auto;display:flex;align-items:center;gap:18px;height:56px}}
.logo{{font-family:var(--serif);font-weight:600;font-size:17px;white-space:nowrap}}
.logo .m{{display:inline-block;width:9px;height:9px;background:var(--accent);transform:rotate(45deg);margin-right:7px}}
nav{{display:flex;gap:2px;flex-wrap:wrap;overflow-x:auto}}
nav a{{color:var(--soft);text-decoration:none;font-size:13.5px;padding:7px 12px;border-radius:7px;white-space:nowrap}}
nav a:hover{{background:var(--p2);color:var(--ink)}}
nav a.on{{background:var(--asoft);color:var(--accent);font-weight:600}}
.wrap{{max-width:1180px;margin:0 auto;padding:24px 20px 60px}}
h1{{font-family:var(--serif);font-weight:600;font-size:24px;margin:0 0 4px}}
.sub{{color:var(--soft);font-size:13px;margin-bottom:20px}}
.stats{{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:12px;margin-bottom:22px}}
.stat{{background:var(--panel);border:1px solid var(--line);border-left:3px solid var(--accent);border-radius:11px;padding:14px 16px}}
.stat b{{font-family:var(--serif);font-size:27px;font-variant-numeric:tabular-nums;display:block;line-height:1}}
.stat span{{font-size:11.5px;color:var(--soft);text-transform:uppercase;letter-spacing:.05em;margin-top:6px;display:block}}
.card{{background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:18px 20px;margin-bottom:18px}}
.card h2{{font-family:var(--serif);font-size:16px;margin:0 0 12px}}
table{{width:100%;border-collapse:collapse;font-size:13px}}
.tbl{{overflow-x:auto}}
th{{text-align:left;font-size:11px;text-transform:uppercase;letter-spacing:.05em;color:var(--soft);border-bottom:1px solid var(--line);padding:7px 8px}}
td{{padding:7px 8px;border-bottom:1px solid var(--line);vertical-align:top}}
tr:hover td{{background:var(--p2)}}
a.link{{color:var(--accent)}}
.pill{{font-size:11px;font-weight:600;padding:2px 9px;border-radius:20px}}
.t1{{background:var(--goodbg);color:var(--good)}}.t2{{background:var(--infobg);color:var(--info)}}.t3{{background:var(--warnbg);color:var(--warn)}}
.pill-good{{background:var(--goodbg);color:var(--good)}}.pill-warn{{background:var(--warnbg);color:var(--warn)}}
input,select,textarea{{font-family:var(--sans);font-size:13.5px;padding:8px 11px;border:1px solid var(--line);border-radius:8px;background:var(--bg);color:var(--ink)}}
textarea{{width:100%;min-height:150px;font-family:var(--mono);font-size:12px}}
.btn{{display:inline-block;background:var(--accent);color:#fff;border:none;text-decoration:none;font-weight:600;font-size:13.5px;padding:9px 16px;border-radius:8px;cursor:pointer}}
.btn:hover{{filter:brightness(1.07)}}
.btn.wa{{background:#25D366;color:#0a2417}}
.btn.ghost{{background:var(--p2);color:var(--ink);border:1px solid var(--line)}}
.filters{{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:16px}}
.flash{{background:var(--goodbg);color:var(--good);border:1px solid var(--good);border-radius:8px;padding:10px 14px;margin-bottom:16px;font-size:13.5px}}
.flash.err{{background:var(--critbg);color:var(--crit);border-color:var(--crit)}}
pre{{background:var(--p2);border:1px solid var(--line);border-radius:8px;padding:12px;overflow-x:auto;font-size:12px;white-space:pre-wrap}}
.wa-card{{border:1px solid var(--line);border-radius:10px;padding:13px 15px;margin-bottom:11px;background:var(--p2)}}
.muted{{color:var(--soft);font-size:12.5px}}
</style></head><body>
<header><div class="hrow"><div class="logo"><span class="m"></span>Divya Stones · Control Tower</div><nav>{nav}</nav></div></header>
<div class="wrap">{body}</div></body></html>""", mimetype="text/html")

def flash(msg, err=False):
    return f'<div class="flash{" err" if err else ""}">{esc(msg)}</div>' if msg else ""

# ---------------- pages ----------------
@app.route("/")
def overview():
    o = D.overview()
    reg = "".join(f'<tr><td>{esc(k)}</td><td class="tnum">{v}</td></tr>'
                  for k,v in sorted(o["regions"].items(), key=lambda x:-x[1]))
    stats = "".join([
        f'<div class="stat"><b class="tnum">{o["total"]}</b><span>Leads in pipeline</span></div>',
        f'<div class="stat"><b class="tnum">{o["tiers"]["1"]}</b><span>Tier 1</span></div>',
        f'<div class="stat"><b class="tnum">{o["approved"]}</b><span>Approved</span></div>',
        f'<div class="stat"><b class="tnum">{o["runs"]}</b><span>Engine runs</span></div>',
        f'<div class="stat"><b class="tnum">{o["agents"]}</b><span>Agents</span></div>',
        f'<div class="stat"><b class="tnum">{o["reports"]}</b><span>Reports</span></div>',
    ])
    body = f"""<h1>Command Overview</h1><div class="sub">Live from the repo · everything below is interactive</div>
    {stats}
    <div class="card"><h2>Leads by region</h2><div class="tbl"><table>
    <thead><tr><th>Region</th><th>Leads</th></tr></thead><tbody>{reg}</tbody></table></div></div>
    <div class="card"><h2>Quick actions</h2>
    <a class="btn" href="/inbox">Add leads &amp; run engine</a>
    <a class="btn ghost" href="/approvals">Review approvals</a>
    <a class="btn wa" href="/whatsapp">WhatsApp send</a></div>"""
    return page("Overview", body, "/")

@app.route("/leads")
def leads():
    q = request.args.get("q","").strip()
    tier = request.args.get("tier","").strip()
    region = request.args.get("region","").strip()
    rows = D.leads(q, tier, region)
    def opt(name, val, cur, sel):
        return f'<option value="{val}"{" selected" if val==cur else ""}>{sel}</option>'
    trs = ""
    for r in rows[:400]:
        t = (r.get("Tier") or "").strip()
        web = r.get("Website","")
        link = f'<a class="link" href="{esc(web)}" target="_blank" rel="noopener">site</a>' if web else ""
        wa = r.get("WhatsApp","")
        walink = (f' · <a class="link" href="https://wa.me/{esc("".join(c for c in wa if c.isdigit()))}" target="_blank">wa</a>'
                  if wa else "")
        trs += (f'<tr><td><span class="pill t{t or "3"}">T{esc(t)}</span></td>'
                f'<td class="tnum">{esc(r.get("Score",""))}</td><td>{esc(r.get("Company",""))}</td>'
                f'<td>{esc(r.get("City",""))}, {esc(r.get("Country",""))}</td>'
                f'<td class="muted">{esc((r.get("Imports_From","") or "")[:28])}</td>'
                f'<td>{link}{walink}</td></tr>')
    body = f"""<h1>Leads <span class="muted">({len(rows)})</span></h1>
    <div class="sub">Search and filter the full pipeline</div>
    <form class="filters" method="get">
    <input name="q" placeholder="search company, country, material…" value="{esc(q)}" style="min-width:260px">
    <select name="tier"><option value="">All tiers</option>{opt("t","1",tier,"Tier 1")}{opt("t","2",tier,"Tier 2")}{opt("t","3",tier,"Tier 3")}</select>
    <select name="region"><option value="">All regions</option>{opt("r","Gulf",region,"Gulf")}{opt("r","Americas",region,"Americas")}{opt("r","Europe",region,"Europe")}{opt("r","Other",region,"Other")}</select>
    <button class="btn" type="submit">Filter</button>
    <a class="btn ghost" href="/leads">Reset</a></form>
    <div class="card"><div class="tbl"><table>
    <thead><tr><th>Tier</th><th>Score</th><th>Company</th><th>Location</th><th>Imports from</th><th>Links</th></tr></thead>
    <tbody>{trs or '<tr><td colspan=6 class=muted>No matches.</td></tr>'}</tbody></table></div>
    {"<div class='muted' style='margin-top:10px'>Showing first 400.</div>" if len(rows)>400 else ""}</div>"""
    return page("Leads", body, "/leads")

@app.route("/approvals")
def approvals():
    msg = request.args.get("msg",""); err = request.args.get("err","")
    runs = D.pending_runs()
    cards = ""
    for r in runs:
        rec = r["rec"]
        pill = "pill-good" if rec=="APPROVE" else "pill-warn"
        actions = (f'<form method="post" action="/action/approve" style="display:inline">'
                   f'<input type="hidden" name="run_id" value="{esc(r["id"])}">'
                   f'<button class="btn" type="submit">Approve &amp; merge to pipeline</button></form> '
                   f'<a class="btn ghost" href="/runs?run={esc(r["id"])}">View leads</a>') if r["has_scored"] else '<span class="muted">no scored file</span>'
        cards += (f'<div class="card"><h2>{esc(r["id"])} '
                  f'<span class="pill {pill}">{esc(rec)}</span></h2>'
                  f'<div class="muted" style="margin-bottom:10px">{r["leads"]} leads · {r["tier1"]} Tier 1</div>'
                  f'{actions}</div>')
    body = f"""<h1>Approvals</h1><div class="sub">Approve a run to merge its leads into the working pipeline</div>
    {flash(msg)}{flash(err, True)}{cards or '<div class="card muted">No runs yet.</div>'}"""
    return page("Approvals", body, "/approvals")

@app.route("/inbox")
def inbox():
    msg = request.args.get("msg",""); err = request.args.get("err","")
    files = D.inbox_files()
    fl = "".join(f'<li class="tnum">{esc(f)}</li>' for f in files) or '<li class="muted">empty</li>'
    body = f"""<h1>Add Leads &amp; Run Engine</h1>
    <div class="sub">Paste a customs/directory CSV, save it, then run the free pipeline — scores &amp; queues it</div>
    {flash(msg)}{flash(err, True)}
    <div class="card"><h2>1 · Paste CSV</h2>
    <form method="post" action="/action/add-leads">
    <textarea name="csv" placeholder="company,contact_name,email,phone,website,city,country,materials,supplier_country,evidence_url,source_tag
Acme Stone,Jane Doe,jane@acme.com,+1..,https://acme.com,Dallas,USA,granite marble slabs,India,https://importyeti.com/company/acme,my_source"></textarea>
    <div style="margin-top:10px"><input name="name" placeholder="source name (optional)" style="min-width:220px">
    <button class="btn" type="submit">Save to inbox</button></div></form></div>
    <div class="card"><h2>2 · Run the engine</h2>
    <p class="muted">Processes everything in the inbox: normalize → dedup (vs {D.overview()["total"]} existing) → score → tier → govern → queue.</p>
    <form method="post" action="/action/run-pipeline"><button class="btn" type="submit">▶ Run pipeline now</button></form>
    <div style="margin-top:12px"><b>Inbox:</b><ul>{fl}</ul></div></div>"""
    return page("Add Leads", body, "/inbox")

@app.route("/whatsapp")
def whatsapp():
    sends = D.whatsapp_sends()
    cards = ""
    for s in sends:
        if s.get("_link"):
            btn = f'<a class="btn wa" href="{esc(s["_link"])}" target="_blank" rel="noopener">Send on WhatsApp ↗</a>'
            badge = '<span class="pill pill-good">verified</span>'
        else:
            btn = '<span class="muted">number needed</span>'
            badge = '<span class="pill pill-warn">find number</span>'
        note = f'<div class="muted" style="color:var(--warn)">{esc(s["note"])}</div>' if s.get("note") else ""
        cards += (f'<div class="wa-card"><div style="display:flex;justify-content:space-between;align-items:center">'
                  f'<b>{esc(s["company"])}</b>{badge}</div>'
                  f'<div class="muted">{esc(s.get("city",""))}</div>'
                  f'<div class="muted" style="margin:8px 0">{esc(s["message"][:170])}…</div>{note}{btn}</div>')
    body = f"""<h1>WhatsApp — one-tap send</h1>
    <div class="sub">Opens WhatsApp with the message pre-typed. Replace “[your name]”, review, send. Nothing auto-sends.</div>
    {cards or '<div class="card muted">No sends staged.</div>'}"""
    return page("WhatsApp", body, "/whatsapp")

@app.route("/runs")
def runs():
    which = request.args.get("run","")
    if which:
        rows = D.run_leads(which)
        trs = "".join(f'<tr><td><span class="pill t{esc(r.get("tier","3"))}">T{esc(r.get("tier",""))}</span></td>'
                      f'<td class="tnum">{esc(r.get("score",""))}</td><td>{esc(r.get("company",""))}</td>'
                      f'<td>{esc(r.get("country",""))}</td><td class="muted">{esc((r.get("why_qualified","") or "")[:44])}</td></tr>'
                      for r in rows)
        body = f"""<h1>{esc(which)}</h1><a class="link" href="/runs">← all runs</a>
        <div class="card" style="margin-top:14px"><div class="tbl"><table>
        <thead><tr><th>Tier</th><th>Score</th><th>Company</th><th>Country</th><th>Why</th></tr></thead><tbody>{trs}</tbody></table></div></div>
        <div class="card"><h2>Governance report</h2><pre>{esc(D.run_governance(which))}</pre></div>"""
        return page("Run", body, "/runs")
    rows = D.pending_runs()
    trs = "".join(f'<tr><td><a class="link" href="/runs?run={esc(r["id"])}">{esc(r["id"])}</a></td>'
                  f'<td class="tnum">{r["leads"]}</td><td class="tnum">{r["tier1"]}</td>'
                  f'<td><span class="pill {"pill-good" if r["rec"]=="APPROVE" else "pill-warn"}">{esc(r["rec"])}</span></td></tr>'
                  for r in rows)
    body = f"""<h1>Engine Runs</h1><div class="sub">Every pipeline run with its governance verdict</div>
    <div class="card"><div class="tbl"><table><thead><tr><th>Run</th><th>Leads</th><th>Tier 1</th><th>Governance</th></tr></thead>
    <tbody>{trs}</tbody></table></div></div>"""
    return page("Runs", body, "/runs")

@app.route("/drafts")
def drafts():
    ds = D.drafts()
    body = "<h1>Outreach Drafts</h1><div class='sub'>AI-written first-touch drafts · nothing sent</div>"
    for d in ds:
        body += f'<div class="card"><h2 class="muted tnum" style="font-size:12px">{esc(d["path"])}</h2><pre>{esc(d["text"])}</pre></div>'
    if not ds: body += '<div class="card muted">No drafts yet.</div>'
    return page("Drafts", body, "/drafts")

# ---------------- actions ----------------
@app.route("/action/run-pipeline", methods=["POST"])
def act_run():
    ok, out = D.run_pipeline()
    tail = out.splitlines()[-1] if out else "done"
    return redirect(url_for("inbox", **({"msg": tail} if ok else {"err": tail})))

@app.route("/action/add-leads", methods=["POST"])
def act_add():
    try:
        name = D.add_inbox_csv(request.form.get("csv",""), request.form.get("name",""))
        return redirect(url_for("inbox", msg=f"Saved {name} to inbox. Now click Run pipeline."))
    except Exception as e:
        return redirect(url_for("inbox", err=str(e)))

@app.route("/action/approve", methods=["POST"])
def act_approve():
    run_id = request.form.get("run_id","")
    try:
        n = D.approve_run(run_id)
        return redirect(url_for("approvals", msg=f"Approved {run_id}: merged {n} new leads into the pipeline."))
    except Exception as e:
        return redirect(url_for("approvals", err=str(e)))

if __name__ == "__main__":
    ips = D.local_ips()
    print("\n  Divya Stones Control Tower — running")
    print(f"  Local:   http://127.0.0.1:{PORT}")
    for ip in ips:
        print(f"  Network: http://{ip}:{PORT}   (open from any device on your Wi-Fi)")
    print("  Stop with Ctrl+C\n")
    app.run(host="0.0.0.0", port=PORT, debug=False)
