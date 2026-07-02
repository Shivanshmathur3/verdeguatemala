# Cold Email Infrastructure Setup — Non-Negotiable Foundation
**Build BEFORE sending anything (plan §2). Total: ~$150/mo email infra line.**

## Why this exists
**Never send cold volume from divyastones.com.** One spam-flag wave and the main domain's deliverability dies — every quote, every invoice, every reply to a real buyer starts landing in spam. The main domain is for real conversations only; cold volume runs on burner-adjacent secondary domains that can be replaced if burned.

---

## Step 1 — Buy 2–3 Secondary Domains (Day 1, ~$30/yr total)
- [ ] Candidates: **divyastonesexport.com**, **divyastone.co**, **divyastonesindia.com** (close to the brand = credible; not identical = main domain protected)
- [ ] Registrar: Namecheap or Cloudflare (cheap, clean DNS panel)
- [ ] Set each domain to redirect (301) to divyastones.com — prospects who type the domain land somewhere real

## Step 2 — Mailboxes (Day 1–2)
- [ ] Google Workspace, 2–3 mailboxes per domain (~$6/mailbox/mo)
- [ ] Naming: real-person format — `[firstname]@divyastonesexport.com`. NOT sales@ or info@ (generic = spam signal on cold)
- [ ] Real display name + photo on every mailbox

## Step 3 — DNS Records (Day 2 — all three, on every sending domain)
| Record | Example value (Google Workspace) | What it does |
|--------|----------------------------------|--------------|
| SPF | `v=spf1 include:_spf.google.com ~all` | Authorizes Google to send for the domain |
| DKIM | Generate in Admin Console → paste TXT record | Cryptographically signs each email |
| DMARC | `v=DMARC1; p=quarantine; rua=mailto:dmarc@divyastonesexport.com` | Tells receivers what to do with failures + sends reports |

- [ ] Verify all three with mxtoolbox.com or Google Admin Toolbox before warmup starts

## Step 4 — Warmup (Weeks 1–3 — no cold sends until complete)
**Tool choice:**
| | Instantly.ai | Smartlead |
|---|---|---|
| Price | ~$37/mo entry | ~$39/mo entry |
| Warmup | Built-in, automatic | Built-in, automatic |
| Best for | Simplicity, fast setup | More mailboxes per dollar at scale |
| **Pick** | **Instantly for start** — simpler; revisit at >6 mailboxes | |

**Warmup schedule per mailbox (tool automates this — do not skip ahead):**
| Days | Volume/day |
|------|-----------|
| 1–3 | 5 |
| 4–7 | 10 |
| 8–12 | 20 |
| 13–17 | 30 |
| 18–21 | 40 → cold sending may begin, warmup stays ON |

## Step 5 — Sending Rules (permanent)
- [ ] Max 30–50 cold sends per mailbox per day (6 mailboxes ≈ 250–400/week comfortably — matches plan cadence)
- [ ] Plain-text-first emails; max 1 link, no images in Touch 1
- [ ] Attachments only after a reply (Day 4 slab photos go as links early on if deliverability dips)
- [ ] Every email: working unsubscribe line ("reply 'no' and I won't write again") — CAN-SPAM + reply-signal
- [ ] Rotate mailboxes; never blast one list from one mailbox in one day

## Step 6 — CRM (Day 2–3)
**HubSpot free tier** (preferred): pipeline stages mirroring `marketing/crm_pipeline.md` (Lead → Contacted → MQL → SQL → Discovery → Proposal → Negotiation → Closed) · log email opens/replies automatically · tasks for call follow-ups.
**Alternative:** disciplined sheet — `scored_master_contacts.csv` format + one row per touch.
**The rule either way: every prospect, every touch, logged. No exceptions.**

## Step 7 — WhatsApp Business Catalog (Day 3)
- [ ] WhatsApp Business on the +91-94141-67278 number
- [ ] Catalog: 12 best-selling materials — photo, name, format, MOQ (1 container / mixed available), lead time (3–4 weeks), "FOB price on request"
- [ ] Quick replies saved: pricing request, sample request, packing photos, payment terms
- [ ] Business profile: hours, website, address, credentials line

## Step 8 — Weekly Deliverability Health Check (every Friday, 10 min)
| Metric | Healthy | Breach action |
|--------|---------|---------------|
| Bounce rate | <3% | Stop sends, clean list (verify with NeverBounce/ZeroBounce) |
| Spam complaints | <0.1% | Stop sends, review copy + list source |
| Open rate | >40% on cold (post-warmup) | Below 25% = deliverability problem, not copy problem — rewarm |
| Blacklist check | Clean on mxtoolbox | Follow delisting process, pause domain |

**Breach protocol: stop → diagnose → fix → rewarm at half volume for a week → resume. Never "push through" a deliverability drop.**

## Cost Summary (matches plan budget)
| Item | $/mo |
|------|------|
| Domains (amortized) | ~5 |
| Google Workspace (6 mailboxes) | ~36 |
| Instantly.ai | ~37–74 |
| Verification credits | ~15 |
| **Total** | **~$100–150** ✅ plan line: $150 |
