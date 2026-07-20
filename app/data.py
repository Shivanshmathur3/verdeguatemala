"""
Data layer for the Divya Stones local Control Tower web app.
Pure Python (no Flask) so it can be unit-tested on its own. Reads and writes the
live repo files — the same source of truth the pipeline and dashboard use.
"""
import csv, os, glob, json, subprocess, datetime, urllib.parse, re

APP   = os.path.dirname(os.path.abspath(__file__))
REPO  = os.path.abspath(os.path.join(APP, ".."))
MK    = os.path.join(REPO, "marketing")
EN    = os.path.join(MK, "lead_engine")
LEDGER= os.path.join(EN, "lead_ledger.csv")
MASTER= os.path.join(MK, "scored_master_contacts.csv")
INBOX = os.path.join(EN, "inbox")
PIPE  = os.path.join(EN, "pipeline", "normalize_and_score.py")
GH    = "https://github.com/Shivanshmathur3/verdeguatemala/blob/claude/marketing-email-drafts-cpZlm"

# ---------- readers ----------
def _rows(path):
    if not os.path.exists(path): return []
    with open(path, newline="", encoding="utf-8", errors="replace") as f:
        return list(csv.DictReader(f))

def master_leads():
    return _rows(MASTER)

def ledger():
    return _rows(LEDGER)

def overview():
    m = master_leads(); led = ledger()
    tiers = {"1":0,"2":0,"3":0}
    regions = {}
    for r in m:
        t = (r.get("Tier") or "").strip()
        if t in tiers: tiers[t]+=1
        c = (r.get("Country") or "").strip().upper()
        reg = ("Gulf" if c in {"UAE","SAUDI ARABIA","QATAR","OMAN","KUWAIT","BAHRAIN"} else
               "Americas" if c in {"USA","UNITED STATES","US","CANADA","MEXICO"} else
               "Europe" if c in {"UK","UNITED KINGDOM","GERMANY","ITALY","SPAIN","IRELAND","NETHERLANDS","FRANCE"} else
               "Other" if c else "Unknown")
        regions[reg] = regions.get(reg,0)+1
    return {
        "total": len(m), "tiers": tiers, "regions": regions,
        "ledger": len(led),
        "approved": sum(1 for r in led if r.get("status")=="approved"),
        "runs": len(glob.glob(os.path.join(EN, "pending_approval", "run_*"))),
        "agents": len(glob.glob(os.path.join(REPO, ".claude/agents/*.md"))),
        "sequences": len(glob.glob(os.path.join(MK, "sequences/*.md"))),
        "reports": len(glob.glob(os.path.join(MK, "reports/*.md"))),
    }

def leads(q="", tier="", region=""):
    out = []
    for r in master_leads():
        blob = " ".join(str(v) for v in r.values()).lower()
        if q and q.lower() not in blob: continue
        if tier and (r.get("Tier") or "").strip() != tier: continue
        c = (r.get("Country") or "").strip().upper()
        reg = ("Gulf" if c in {"UAE","SAUDI ARABIA","QATAR","OMAN","KUWAIT","BAHRAIN"} else
               "Americas" if c in {"USA","UNITED STATES","US","CANADA","MEXICO"} else
               "Europe" if c in {"UK","UNITED KINGDOM","GERMANY","ITALY","SPAIN","IRELAND","NETHERLANDS","FRANCE"} else "Other")
        if region and reg != region: continue
        r["_region"] = reg
        out.append(r)
    out.sort(key=lambda r: (r.get("Tier") or "9", -int(r.get("Score") or 0)))
    return out

def pending_runs():
    runs = []
    for d in sorted(glob.glob(os.path.join(EN, "pending_approval", "run_*")), reverse=True):
        rid = os.path.basename(d)
        scored = os.path.join(d, "leads_scored.csv")
        n = len(_rows(scored)) if os.path.exists(scored) else 0
        t1 = sum(1 for r in _rows(scored) if (r.get("tier") or "")=="1") if os.path.exists(scored) else 0
        rec = "—"
        gov = os.path.join(d, "governance_report.md")
        if os.path.exists(gov):
            txt = open(gov, encoding="utf-8", errors="replace").read()
            m = re.search(r"RECOMMENDATION:\s*(\w+)", txt)
            if m: rec = m.group(1)
        runs.append({"id": rid, "leads": n, "tier1": t1, "rec": rec,
                     "has_scored": os.path.exists(scored)})
    return runs

def run_leads(run_id):
    return _rows(os.path.join(EN, "pending_approval", run_id, "leads_scored.csv"))

def run_governance(run_id):
    p = os.path.join(EN, "pending_approval", run_id, "governance_report.md")
    return open(p, encoding="utf-8", errors="replace").read() if os.path.exists(p) else "No report."

def whatsapp_sends():
    p = os.path.join(EN, "whatsapp_sends.json")
    if not os.path.exists(p): return []
    try: sends = json.load(open(p, encoding="utf-8")).get("sends", [])
    except Exception: return []
    for s in sends:
        if s.get("verified") and s.get("number"):
            s["_link"] = f"https://wa.me/{s['number']}?text={urllib.parse.quote(s['message'])}"
        else:
            s["_link"] = ""
    return sends

def drafts():
    out = []
    for d in sorted(glob.glob(os.path.join(EN, "pending_approval", "run_*", "drafts", "*.md"))):
        out.append({"path": d.replace(REPO+"/", ""),
                    "text": open(d, encoding="utf-8", errors="replace").read()})
    return out

def inbox_files():
    return [os.path.basename(f) for f in glob.glob(os.path.join(INBOX, "*.csv"))
            if os.path.basename(f) != "EXAMPLE_source_format.csv"]

# ---------- actions ----------
def run_pipeline():
    """Run the free deterministic pipeline; return (ok, output)."""
    try:
        r = subprocess.run(["python3", PIPE], capture_output=True, text=True, timeout=300, cwd=REPO)
        return (r.returncode == 0, (r.stdout + r.stderr).strip())
    except Exception as e:
        return (False, str(e))

def add_inbox_csv(text, name=None):
    """Save pasted/uploaded CSV text into the inbox. Returns the filename."""
    text = (text or "").strip()
    if not text or "," not in text.splitlines()[0]:
        raise ValueError("That doesn't look like CSV (need a header row with commas).")
    safe = re.sub(r"[^a-z0-9_.-]", "_", (name or "manual").lower()) or "manual"
    if not safe.endswith(".csv"): safe += ".csv"
    # avoid clobbering: prefix a counter timestamp-free (Date.now unavailable elsewhere, but here fine)
    dest = os.path.join(INBOX, safe)
    i = 1
    while os.path.exists(dest):
        dest = os.path.join(INBOX, safe[:-4] + f"_{i}.csv"); i += 1
    with open(dest, "w", encoding="utf-8", newline="") as f:
        f.write(text if text.endswith("\n") else text + "\n")
    return os.path.basename(dest)

def approve_run(run_id):
    """Flip this run's ledger rows to approved and merge its leads into the master. Returns count merged."""
    led = ledger()
    for r in led:
        if r.get("run_id") == run_id and r.get("status") == "pending":
            r["status"] = "approved"
    if led:
        with open(LEDGER, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=led[0].keys()); w.writeheader(); w.writerows(led)
    # merge into master (dedup by website domain)
    existing = master_leads()
    have = set()
    for r in existing:
        d = (r.get("Website") or r.get("Email") or "").lower()
        d = d.replace("https://","").replace("http://","").replace("www.","").strip("/").split("/")[0]
        if d: have.add(d)
    added = 0
    with open(MASTER, "a", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        for r in run_leads(run_id):
            web = (r.get("website") or "").lower()
            dom = web.replace("https://","").replace("http://","").replace("www.","").strip("/").split("/")[0]
            if dom and dom in have: continue
            reg = r.get("region","")
            ch = "WhatsApp+Phone" if reg=="Gulf" else ("Email+LinkedIn" if r.get("email") else "Email+Web-form")
            w.writerow([r.get("tier",""), r.get("score",""), r.get("contact_name",""), r.get("company",""),
                        r.get("city",""), r.get("country",""), r.get("phone",""), r.get("whatsapp",""),
                        r.get("email",""), r.get("website",""), r.get("linkedin",""), "",
                        r.get("contact_title",""), "stone", r.get("supplier_country",""), ch,
                        r.get("why_qualified","")])
            added += 1
            if dom: have.add(dom)
    return added

def local_ips():
    """Best-effort list of LAN IPs this server is reachable at."""
    ips = set()
    try:
        import socket
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80)); ips.add(s.getsockname()[0]); s.close()
    except Exception: pass
    try:
        import socket
        for info in socket.getaddrinfo(socket.gethostname(), None):
            ip = info[4][0]
            if "." in ip and not ip.startswith("127."): ips.add(ip)
    except Exception: pass
    return sorted(ips)
