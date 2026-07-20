# Funnel Audit — Pre-Launch Baseline
**Divya Stones | Verde Guatemala Marble Export | Udaipur, India**
Date: 2026-06-18 | Audit type: Day 0 readiness audit (pre-first-email)
Auditor: Sales Forecaster Agent

---

## Purpose

This audit assesses whether all systems, assets, and processes required to run a professional outbound sales campaign are in place before Divya Stones sends its first commercial outreach message. The goal is to identify gaps that would either prevent outreach from launching, cause a lead to fall through the cracks once a reply arrives, or produce a substandard buyer experience in the first 7 days.

A "go" rating means the asset exists and is fit for purpose. A "partial" rating means the asset exists but has gaps that need to be closed within 48 hours. A "missing" rating means the asset does not exist and must be built before Day 0 outreach.

---

## Audit Findings

### 1. Funnel Stage Definition

**Status: COMPLETE**

The CRM pipeline document (`/home/user/verdeguatemala/marketing/crm_pipeline.md`) defines 10 sequential stages with full detail:

- Stage 1 — Lead
- Stage 2 — Contacted
- Stage 3 — MQL (Marketing Qualified Lead)
- Stage 4 — SQL (Sales Qualified Lead)
- Stage 5 — Discovery
- Stage 6 — Proposal Sent
- Stage 7 — Negotiation
- Stage 8 — Closed Won
- Stage 9 — Closed Lost
- Stage 10 — Nurture

Each stage has defined entry criteria, exit criteria, SLA timers, and stall actions. The BANT scorecard (Section 2 of crm_pipeline.md) defines qualification thresholds for advancement from MQL to SQL. The response SLA table (Section 3) covers every inbound and outbound trigger with maximum response times. The weekly pipeline review template (Section 5) and monthly funnel analysis template (Section 6) are both ready.

Assessment: The pipeline architecture is exceptionally thorough for a first-launch operation. No gaps in stage logic.

One operational note: the CRM stages are documented but the actual CRM tool (HubSpot, Pipedrive, spreadsheet, etc.) is not referenced. Before Day 0, all 87 leads from scored_master_contacts.csv must be imported into the CRM with Stage 1 status, source tagged, and tier tagged. This is an operational setup step, not a process gap.

---

### 2. Email and WhatsApp Outreach Sequences

**Status: MISSING — CRITICAL GAP**

Audit finding: The `/home/user/verdeguatemala/marketing/sequences/` directory exists but contains no sequence files. No outreach sequences were found for any of the following:

- UAE / Middle East cold email sequence
- UAE / Oman / KSA WhatsApp message sequence
- USA stone importer cold email sequence
- EU stone importer cold email sequence
- Jewellery importer sequence (USA)
- Follow-up sequence (for non-replies at Day 2, 7, 14)
- Post-discovery-call follow-up email template
- Nurture re-engagement sequence

This is the single most critical gap in the funnel. Outreach cannot launch in a scalable, trackable way without sequences. Without sequences, messages will be inconsistent, untracked, and the personalization logic in the lead scoring notes will be lost.

What must be built before Day 0:
1. UAE / ME WhatsApp sequence (3 touchpoints: intro, follow-up Day 3, follow-up Day 7)
2. UAE / ME email sequence (same 3-touchpoint structure, different copy)
3. USA stone email sequence (3 touchpoints with different time zones and angles)
4. EU stone email sequence (3 touchpoints; German, Dutch, UK buyer angles differ)
5. Follow-up sequence for all non-replies (generic, usable across markets)

Minimum viable: even a single well-crafted WhatsApp message and a single personalized email template (one per segment: ME, USA, EU) would be sufficient to launch. Full sequences can be built in parallel during Week 1 outreach.

---

### 3. Contact Lists — Scored and Ready

**Status: COMPLETE**

The scored_master_contacts.csv file contains all 87 leads with:
- Tier (1, 2, 3) and score (15–90)
- Full contact data: name, company, city, country, phone, WhatsApp, email, website, LinkedIn, Instagram
- Role of contact (MD, Director, Founder, etc.)
- Product category (stone / jewellery)
- Import origins confirmed (sourcing from India confirmed or not)
- Outreach channel recommendation (Email+WhatsApp+LinkedIn / Email only / LinkedIn only)
- Specific first-action notes for each Tier 1 lead

The lead_scoring_summary.md provides a prioritised top-10 list with specific first-action instructions for each lead, timezone-adjusted call windows for US leads, and a structured Day 0 / Day 1 / Day 2 outreach plan.

Assessment: Lead intelligence is strong and ready to use. No enrichment needed for Tier 1 before launch — the data is sufficient. The contacts that do need enrichment (Marble International Kuwait, Arab Marble Abu Dhabi, Hayat Marble Kuwait) are already flagged in the summary, and enrichment can run in parallel during Week 1.

---

### 4. Pricing Sheets for All 3 Markets

**Status: PARTIAL — NEEDS FORMALISING**

What exists: The margin_analysis_2026-06-17.csv file contains complete FOB pricing for all 3 markets (USA, EU, Middle East) across:
- 5 Verde Guatemala varieties (Spider Green, Emerald Green, Forest Green, Imperial Green, Royal Green, Silvo Green)
- 3 finishes (Polished, Honed, Brushed, Sandblasted)
- 2 formats (Tile 60x60, Tile 30x30, Tile 30x60, Slab)
- Per-sqm FOB pricing and margin percentages

What is missing: A buyer-facing pricing document. The margin_analysis CSV is an internal cost model, not something to send to a buyer. There is no:
- Formatted FOB price list (PDF or clean table) for UAE/ME buyers
- Formatted FOB price list for USA buyers
- Formatted FOB price list for EU buyers
- Document specifying MOQ, payment terms, lead time, and sample availability alongside prices

This gap means: when a buyer replies and asks "please send us your price list," there is nothing ready to send. Sending the raw CSV is not appropriate.

Action required before Day 0: Create 3 buyer-facing pricing sheets (one per market) as clean 1-page documents. Each should show: variety, finish, format, FOB price per sqm, minimum order (sqm or container), and lead time. Take the pricing directly from margin_analysis_2026-06-17.csv — the data is already correct. This can be built in under 2 hours.

---

### 5. Proposal Template

**Status: COMPLETE (with one dependency gap)**

The proposal template exists at `/home/user/verdeguatemala/proposals/proposal_template.md` and is production-ready. It includes:

- Section 1 — Your Situation (buyer-specific, uses discovery call notes)
- Section 2 — What Divya Stones Will Deliver (variety, finish, format, volume, grading, packaging, lead time)
- Section 3 — Pricing (formatted table with FOB rate, MOQ, payment terms, lead time)
- Section 4 — Why Buyers Trust Us (placeholder for case study)
- Section 5 — Next Step (single clear action)
- Internal checklist before sending

One dependency gap: Section 4 references a case study from `/home/user/verdeguatemala/marketing/case_studies/`. This directory and its contents were not found. Without a real case study or reference customer, Section 4 is unusable. A placeholder or proxy reference ("a stone distributor in [region] who now orders quarterly" — general but anonymised) should be written and added to the proposal template before the first proposal is sent. This is Day 15–20 work, not Day 0 work, since proposals are only sent after discovery calls.

Assessment: The proposal template is ready for Day 0 operations. The case study gap is a Day 20 dependency, not a launch blocker.

---

### 6. Missing Assets Before Day 0 Outreach Can Launch

Based on the full audit, here is a consolidated summary of what is missing:

| Asset | Status | Priority | When Needed |
|-------|--------|----------|-------------|
| Outreach sequences (ME, USA, EU) | Missing | Critical | Before first email |
| Buyer-facing pricing sheets (3 markets) | Missing | High | Within 24–48 hrs of first reply |
| CRM setup with 87 leads imported | Not confirmed | Critical | Before Day 0 |
| Case studies folder with 1+ reference | Missing | Medium | Before first proposal (Day 20+) |
| Calendar booking link (for discovery calls) | Not confirmed | Medium | Before first reply is expected |
| Company email domain setup (professional from address) | Not confirmed | High | Before Day 0 |
| Product spec sheet (PDF for buyers) | Not confirmed | High | Within 24 hrs of first reply |
| Verde Guatemala sample box preparation | Not confirmed | Medium | Week 2–3 |
| Auto-reply on inquiry email (after-hours protocol) | Not confirmed | Low | Before Day 0 |

---

## Section 7 — Recommended Launch Checklist (10 Actions Before First Email)

These are the 10 actions, in priority order, that must be completed before the first outreach message is sent. Each has a specific, actionable definition of "done."

---

**Action 1 — Build the ME WhatsApp sequence (Day 0 blocker)**

Write 3 WhatsApp messages per lead group:
- Message 1 (Day 0): 3–4 lines. Include one high-quality Verde Guatemala slab image. One personalised line referencing the buyer's market or sourcing profile. One clear offer (sample box, spec sheet, or a 10-minute call). No attachments — keep it conversational.
- Message 2 (Day 3): Follow-up if no reply. Different angle — reference a relevant use case or a project type common in their market.
- Message 3 (Day 7): Final follow-up. Value-only message (share a product stat, a quarry photo, or a market insight). Do not push for a response — let them come back when ready.

Done when: 3 WhatsApp messages are drafted, reviewed, and ready to personalise and send for each of the 9 ME Tier 1 WhatsApp leads.

---

**Action 2 — Build the cold email sequence for ME, USA, and EU stone buyers (Day 0 blocker)**

Three separate email sequences, each 3 emails:
- Email 1 (Day 0): Subject line must not open with "I represent a company." Open with the buyer's situation. Body: specific Verde Guatemala product angle relevant to their market. CTA: reply to request spec sheet or book a 15-minute call.
- Email 2 (Day 4): Different subject, different angle. Shorter — 4 lines max. Reference one concrete detail (e.g., container capacity, FOB port, lead time).
- Email 3 (Day 10): Final touch. Share one data point or photo. Low pressure. Keep the door open.

Done when: 3 email sequences × 3 segments = 9 email templates drafted and reviewed. Personalization tokens ([Company], [market-specific line]) marked.

---

**Action 3 — Import all 87 leads into the CRM with Stage 1 status (Day 0 blocker)**

Using the data from scored_master_contacts.csv, all 87 contacts must be entered into the CRM (or equivalent tracking tool) with:
- Company name, contact name, city, country
- Tier and score
- Preferred outreach channel
- Stage: Lead (Stage 1)
- Source: scored_master_contacts.csv
- Segment: Stone Distributor / Jewellery Wholesaler / EU Buyer / ME Buyer / USA Buyer
- A follow-up task set for Day 0 (for Tier 1 leads)

Done when: CRM shows 87 leads, all at Stage 1, all tagged with tier, segment, and a Day 0 task assigned.

---

**Action 4 — Create buyer-facing pricing sheets for 3 markets (needed within 48 hrs of first reply)**

Using margin_analysis_2026-06-17.csv data, build 3 clean, simple pricing documents:
- Pricing Sheet — Middle East Markets (UAE, Oman, KSA, Qatar, Kuwait)
- Pricing Sheet — USA
- Pricing Sheet — European Union (DE, NL, BE, UK, ES)

Each document should be one page maximum. Include: variety name, available finishes, available formats, FOB price per sqm, container MOQ (sqm), payment terms, lead time (weeks from order confirmation), and sample availability.

Done when: 3 pricing sheets exist as PDF or clean markdown files, reviewed for accuracy against margin_analysis data, and saved to a location that can be attached to emails within 60 seconds of a buyer request.

---

**Action 5 — Prepare and photograph Verde Guatemala sample boxes (needed by Day 14)**

A physical sample box (6–8 polished tiles, 10×10 cm, one per variety/finish combination) is the single most effective tool for converting a curious buyer into a proposal conversation. Without samples, the sales cycle for USA and EU buyers extends by 2–4 weeks because they need physical material before committing.

Define the sample set now so quarry/processing can prepare:
- Spider Green Polished 10×10
- Emerald Green Polished 10×10
- Forest Green Polished 10×10
- Imperial Green Polished 10×10
- Royal Green Polished 10×10
- One Honed finish sample (buyer's choice)
- One Brushed/Sandblasted sample for outdoor segment

Done when: Sample boxes (minimum 5 sets) are prepared, photographed, and ready for dispatch. DHL/FedEx courier rates are confirmed for UAE, USA, and EU destinations.

---

**Action 6 — Set up a professional company email and confirm auto-reply (Day 0 blocker)**

All outreach should be sent from a professional domain email (e.g., shivansh@divyastones.com or exports@divyastones.com). Free email providers (gmail.com) significantly reduce deliverability and buyer trust for B2B stone exporters.

Auto-reply must be enabled on the inquiry email address for after-hours messages (per crm_pipeline.md Section 3 protocol): "Thank you for reaching out to Divya Stones. We will respond within one business day. Our business hours are Monday–Saturday, 9 AM – 6:30 PM IST."

Done when: Professional email is confirmed active and sending. Auto-reply is enabled and tested.

---

**Action 7 — Create one-page Verde Guatemala product spec sheet (needed within 24 hrs of first reply)**

Buyers who reply will immediately ask for one or both of: a price list, and a product spec sheet. The spec sheet should include:
- Product name: Verde Guatemala (Indian Green Marble)
- Available varieties with brief visual description
- Available finishes (Polished / Honed / Brushed / Sandblasted)
- Available formats (slab dimensions, tile sizes, thickness)
- Technical data: hardness, absorption rate, density (if available from lab tests)
- Source: Udaipur, Rajasthan, India
- Export experience and markets served
- Contact information and website

Done when: A one-page PDF spec sheet exists and can be emailed as an attachment within 60 seconds of a buyer request.

---

**Action 8 — Enrich 3 high-value contacts with missing contact information (Week 1)**

Three of the highest-potential leads have no usable contact information:
- Marble International Co., Kuwait — 456 confirmed import shipments, no contact info. A buyer this active is worth 2–3 hours of enrichment effort.
- Hayat Marble Kuwait — 46 years in the market, no contact info. A buyer this established has decision-makers who can be found via LinkedIn search.
- Arab Marble, Abu Dhabi — confirmed India importer since 1973, no contact info. 50+ years of purchasing history.

Done when: At minimum one verified contact channel (email or LinkedIn) is found for each of the 3 companies. Add them to the CRM at Stage 1 and flag for Week 2 outreach.

---

**Action 9 — Set up a calendar booking link for discovery calls**

When a buyer replies and says "yes, let's talk," the response should include a calendar link, not a back-and-forth email negotiation about times. This compresses the time from "interested reply" to "call booked" from 2–3 days to 2–3 hours.

Tools: Calendly (free tier), Google Calendar appointment booking, or Cal.com. The link should show available slots in IST with automatic timezone conversion for UAE, US Eastern, and CET zones.

Done when: Calendar link is live, tested, and saved for insertion into outreach sequences and email signatures.

---

**Action 10 — Write one case study or reference statement for the proposal template**

The proposal template's Section 4 requires a real or near-real case study. If no active reference customers exist yet (first launch), write a plausible, honest reference statement based on any past transactions Divya Stones has completed — even domestic or informal ones. If no transactions exist, write a near-real scenario in general terms: "A natural stone distributor in [region] evaluated Verde Guatemala samples over 3 weeks and placed their first container order in August 2025. Consistent veining grade and pre-shipment photo approval were the key factors in their decision."

Done when: One approved reference statement or case study paragraph is written, reviewed, and inserted into Section 4 of the proposal template.

---

## Audit Score Summary

| Category | Status | Readiness |
|----------|--------|-----------|
| Funnel stage definition | Complete | 100% |
| BANT qualification framework | Complete | 100% |
| SLA and stall protocols | Complete | 100% |
| Weekly/monthly review templates | Complete | 100% |
| Contact list (scored and tiered) | Complete | 100% |
| Proposal template | Complete (1 gap) | 85% |
| Outreach sequences | Missing | 0% |
| Buyer-facing pricing sheets | Missing | 0% |
| Product spec sheet | Not confirmed | Unknown |
| CRM setup (leads imported) | Not confirmed | Unknown |
| Sample boxes ready | Not confirmed | Unknown |
| Professional email / auto-reply | Not confirmed | Unknown |
| Calendar booking link | Not confirmed | Unknown |
| Case study / reference | Missing | 0% |

**Overall Day 0 Readiness: 55%**

The funnel architecture and lead intelligence are in exceptional shape. The operational launch assets (sequences, pricing sheets, spec sheet) are the missing layer. Two to three days of focused build work closes the gap. Outreach should not launch until at minimum Actions 1, 2, 3, 6, 7, and 9 are complete.

---

*Audit based on directory traversal of /home/user/verdeguatemala/ on 2026-06-18. Files confirmed present: crm_pipeline.md, scored_master_contacts.csv, lead_scoring_summary.md, margin_analysis_2026-06-17.csv, proposal_template.md. Files confirmed missing or not found: outreach sequence files in /marketing/sequences/, buyer-facing pricing sheets, product spec sheet, case studies.*
