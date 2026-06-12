"""
Builds the client-facing JOBBees MVP sprint plan PDF.

How to run:
    cd /Volumes/Development/Projects/Saiju/JOBBees/docs/client
    pip3 install reportlab            # one-time
    python3 build_client_sprint_plan.py

Output:
    ./sprint-plan-client.pdf
"""

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm, mm
from reportlab.lib.colors import HexColor, white
from reportlab.lib.enums import TA_LEFT
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, PageBreak,
    Table, TableStyle, KeepTogether,
)

# -----------------------------------------------------------------------
# Brand
# -----------------------------------------------------------------------
PRIMARY = HexColor("#FF6B2C")     # coral orange
DARK    = HexColor("#1A1A2E")     # deep navy
GREY    = HexColor("#5A5A6E")
LIGHT   = HexColor("#F4F4F6")
BORDER  = HexColor("#D8D8DE")

# -----------------------------------------------------------------------
# Styles
# -----------------------------------------------------------------------
styles = getSampleStyleSheet()

TITLE = ParagraphStyle(
    "Title", parent=styles["Heading1"], fontName="Helvetica-Bold",
    fontSize=28, leading=34, textColor=DARK, spaceAfter=4,
)
SUBTITLE = ParagraphStyle(
    "Sub", parent=styles["BodyText"], fontName="Helvetica",
    fontSize=13, leading=18, textColor=PRIMARY, spaceAfter=18,
)
COVER_META = ParagraphStyle(
    "Meta", parent=styles["BodyText"], fontName="Helvetica",
    fontSize=10, leading=14, textColor=GREY, spaceAfter=2,
)
H1 = ParagraphStyle(
    "H1", parent=styles["Heading1"], fontName="Helvetica-Bold",
    fontSize=18, leading=22, textColor=DARK, spaceBefore=10, spaceAfter=8,
)
H2 = ParagraphStyle(
    "H2", parent=styles["Heading2"], fontName="Helvetica-Bold",
    fontSize=12, leading=16, textColor=DARK, spaceBefore=10, spaceAfter=6,
)
BODY = ParagraphStyle(
    "Body", parent=styles["BodyText"], fontName="Helvetica",
    fontSize=10, leading=14, textColor=DARK, spaceAfter=6, alignment=TA_LEFT,
)
BODY_GREY = ParagraphStyle(
    "BodyGrey", parent=BODY, textColor=GREY,
)
BULLET = ParagraphStyle(
    "Bullet", parent=BODY, leftIndent=14, bulletIndent=4, spaceAfter=4,
)
TABLE_HEAD = ParagraphStyle(
    "TableHead", parent=BODY, fontName="Helvetica-Bold",
    fontSize=10, textColor=white,
)
TABLE_CELL = ParagraphStyle(
    "TableCell", parent=BODY, fontSize=9.5, leading=12, spaceAfter=0,
)
TABLE_CELL_BOLD = ParagraphStyle(
    "TableCellBold", parent=TABLE_CELL, fontName="Helvetica-Bold",
)

# -----------------------------------------------------------------------
# Page furniture
# -----------------------------------------------------------------------
PAGE_W, PAGE_H = A4
MARGIN = 18 * mm


def page_chrome(c, doc):
    """Header + footer drawn on every page."""
    c.saveState()
    # Header brand bar
    c.setFillColor(PRIMARY)
    c.rect(0, PAGE_H - 6 * mm, PAGE_W, 6 * mm, fill=1, stroke=0)
    # Header text
    c.setFont("Helvetica-Bold", 9)
    c.setFillColor(DARK)
    c.drawString(MARGIN, PAGE_H - 12 * mm, "JOBBees")
    c.setFont("Helvetica", 8)
    c.setFillColor(GREY)
    c.drawRightString(PAGE_W - MARGIN, PAGE_H - 12 * mm,
                      "MVP Sprint Plan  |  Jun – Dec 2026")
    # Footer
    c.setStrokeColor(BORDER)
    c.setLineWidth(0.5)
    c.line(MARGIN, 12 * mm, PAGE_W - MARGIN, 12 * mm)
    c.setFont("Helvetica", 8)
    c.setFillColor(GREY)
    c.drawString(MARGIN, 8 * mm, "JOBBees MVP  —  Sprint Plan")
    c.drawRightString(PAGE_W - MARGIN, 8 * mm, f"Page {doc.page}")
    c.restoreState()


# -----------------------------------------------------------------------
# Content
# -----------------------------------------------------------------------
def build_doc(out_path="sprint-plan-client.pdf"):
    doc = SimpleDocTemplate(
        out_path, pagesize=A4,
        leftMargin=MARGIN, rightMargin=MARGIN,
        topMargin=20 * mm, bottomMargin=18 * mm,
    )
    story = []

    # ----------------- COVER -----------------
    story.append(Spacer(1, 40 * mm))
    story.append(Paragraph("JOBBees MVP", TITLE))
    story.append(Paragraph("Development sprint plan", SUBTITLE))
    story.append(Spacer(1, 6 * mm))
    story.append(Paragraph(
        "A clear, two-week-cadence delivery schedule from foundation to soft launch.",
        BODY
    ))
    story.append(Spacer(1, 14 * mm))
    story.append(Paragraph("Project period: <b>Mon 1 Jun  —  Fri 4 Dec 2026</b>  (27 weeks)", COVER_META))
    story.append(Paragraph("Cadence: <b>2-week sprints</b>, weekly Friday demos", COVER_META))
    story.append(Paragraph("Total: <b>1 foundation sprint  +  12 build sprints</b>", COVER_META))
    story.append(Spacer(1, 8 * mm))
    story.append(Paragraph("Prepared 12 June 2026", COVER_META))

    # ----------------- AT A GLANCE -----------------
    story.append(PageBreak())
    story.append(Paragraph("At a glance", H1))
    story.append(Paragraph(
        "JOBBees is an Australian peer-to-peer task marketplace. "
        "This plan delivers the MVP across 12 two-week build sprints, "
        "preceded by a three-week foundation sprint. "
        "Soft launch in one Sydney suburb is scheduled for Sprint 12, "
        "the final week of November and first week of December 2026.",
        BODY
    ))
    story.append(Spacer(1, 4))

    summary = [
        ["Foundation sprint (Sprint 0)", "Mon 1 Jun  —  Fri 19 Jun"],
        ["First build sprint (Sprint 1)", "Mon 22 Jun  —  Fri 3 Jul"],
        ["First user-visible demo (end of Sprint 2)", "Fri 17 Jul"],
        ["Tax / GST / RCTI work begins (Sprint 6)", "Mon 31 Aug"],
        ["TestFlight + real-device testing (Sprint 11)", "Mon 9 Nov"],
        ["Soft launch (Sprint 12)", "Mon 23 Nov  —  Fri 4 Dec"],
    ]
    t = Table(summary, colWidths=[8.0 * cm, 9.0 * cm])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), white),
        ("ROWBACKGROUNDS", (0, 0), (-1, -1), [LIGHT, white]),
        ("TEXTCOLOR", (0, 0), (-1, -1), DARK),
        ("FONT", (0, 0), (0, -1), "Helvetica-Bold", 10),
        ("FONT", (1, 0), (1, -1), "Helvetica", 10),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ("LINEBELOW", (0, 0), (-1, -1), 0.25, BORDER),
        ("LINEABOVE", (0, 0), (-1, 0), 0.5, PRIMARY),
    ]))
    story.append(t)
    story.append(Spacer(1, 14))

    story.append(Paragraph("How the plan works", H2))
    story.append(Paragraph(
        "Sprints run for two working weeks. Every fortnight ends with a "
        "Friday demo: a screen-recorded walk-through of what landed, plus a "
        "stoplight summary of what worked, what slipped, and what is blocked. "
        "There is also a mid-sprint Friday sync that you can join optionally.",
        BODY
    ))
    story.append(Paragraph(
        "From Sprint 2 onward, every Friday demo is a click-through of the "
        "mobile app showing real user flows. Sprint 1 is intentionally "
        "backend-only — its demo is a technical walk-through of the API and "
        "database. The reason is simple: building the authentication API "
        "first, then layering mobile on top of a stable backend, saves "
        "several weeks of rework that would otherwise come from building "
        "mobile against a changing API.",
        BODY
    ))

    # ----------------- SPRINT TIMELINE -----------------
    story.append(PageBreak())
    story.append(Paragraph("Sprint timeline", H1))
    story.append(Paragraph(
        "Each sprint runs two weeks and ends with a Friday demo. "
        "What you will see on demo day is in the right column.",
        BODY_GREY
    ))
    story.append(Spacer(1, 6))

    sprint_rows = [
        ("0",
         "Mon 1 Jun  —  Fri 19 Jun",
         "Foundation",
         "Repo walkthrough, architecture decisions, security gates, "
         "and confirmation that everything is ready for Sprint 1."),
        ("1",
         "Mon 22 Jun  —  Fri 3 Jul",
         "Backend authentication foundation",
         "Technical walk-through: API endpoints in Postman, live database "
         "queries, and security checks. No mobile app this sprint by design."),
        ("2",
         "Mon 6 Jul  —  Fri 17 Jul",
         "Mobile auth, onboarding, tasker upgrade",
         "First user-visible demo. Cold-launch the app, see welcome carousel, "
         "sign up, verify, become a tasker, complete Stripe Connect, verify ABN."),
        ("3",
         "Mon 20 Jul  —  Fri 31 Jul",
         "Task posting, AI extraction, guest mode",
         "Browse as a guest, post a task by photo, watch the AI extract "
         "category and budget, sign up, and publish — all in one flow."),
        ("4",
         "Mon 3 Aug  —  Fri 14 Aug",
         "Discovery, bidding, license verification",
         "Tasker sees ranked feed, places bids, license guard enforces "
         "trade licences (plumber, electrician, builder over $5K), "
         "admin approves licence, poster sees 'Verified Plumber' badge."),
        ("5",
         "Mon 17 Aug  —  Fri 28 Aug",
         "Messaging, payments core, real OTP",
         "Live in-app chat, payment hold via Stripe, "
         "and the real SMS provider goes live for phone verification."),
        ("6",
         "Mon 31 Aug  —  Fri 11 Sep",
         "Job execution, tax / RCTI / GST / ATO",
         "Tasker checks in at the job, uploads completion proof, "
         "auto-capture fires, tax invoice and RCTI generated as PDFs."),
        ("7",
         "Mon 14 Sep  —  Fri 25 Sep",
         "Reviews, AI-assisted dispute mediation",
         "Both sides leave reviews. A dispute is opened. The AI mediator "
         "proposes a resolution that humans can accept, reject, or escalate."),
        ("8",
         "Mon 28 Sep  —  Fri 9 Oct",
         "Notifications, trust & safety, privacy",
         "Push notifications fire across the lifecycle, content moderation "
         "catches suspicious uploads, privacy data-subject requests work end-to-end."),
        ("9",
         "Mon 12 Oct  —  Fri 23 Oct",
         "Admin console",
         "Full admin walk-through: today's queue, KYC review, license review, "
         "dispute resolution, refund processing, tax reporting."),
        ("10",
         "Mon 26 Oct  —  Fri 6 Nov",
         "Cloud deploy + WAF",
         "Same flows running on Azure with Cloudflare protection in front "
         "of a public URL. No more localhost."),
        ("11",
         "Mon 9 Nov  —  Fri 20 Nov",
         "TestFlight, bug fix, launch hardening",
         "Real iOS and Android devices. App Store / Play Store listings, "
         "tooltips, 'How it works' page, polish."),
        ("12",
         "Mon 23 Nov  —  Fri 4 Dec",
         "Soft launch + first real users",
         "A real Sydney tasker, in one Sydney suburb, completes a real task "
         "posted by a real poster, with real money flowing. The MVP is live."),
    ]

    sprint_table = [
        [Paragraph("Sprint", TABLE_HEAD),
         Paragraph("Dates", TABLE_HEAD),
         Paragraph("Theme", TABLE_HEAD),
         Paragraph("What you will see on Friday", TABLE_HEAD)],
    ]
    for n, d, th, demo in sprint_rows:
        sprint_table.append([
            Paragraph(f"<b>{n}</b>", TABLE_CELL_BOLD),
            Paragraph(d, TABLE_CELL),
            Paragraph(f"<b>{th}</b>", TABLE_CELL_BOLD),
            Paragraph(demo, TABLE_CELL),
        ])

    st = Table(
        sprint_table,
        colWidths=[1.2 * cm, 3.4 * cm, 5.0 * cm, 7.9 * cm],
        repeatRows=1,
    )
    st.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), DARK),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [white, LIGHT]),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 7),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
        ("GRID", (0, 0), (-1, -1), 0.25, BORDER),
        ("BOX", (0, 0), (-1, -1), 0.5, DARK),
        ("LINEBEFORE", (0, 1), (0, 1), 3, PRIMARY),       # Sprint 0
        ("LINEBEFORE", (0, 13), (0, 13), 3, PRIMARY),     # Sprint 12
    ]))
    story.append(st)

    # ----------------- WHAT IS LOCKED IN -----------------
    story.append(PageBreak())
    story.append(Paragraph("What is already locked in", H1))
    story.append(Paragraph(
        "These decisions have been made during the foundation sprint. "
        "They are not subject to change without an explicit re-plan.",
        BODY_GREY
    ))
    story.append(Spacer(1, 6))
    locked = [
        ["Tasker verification model",
         "Stripe Connect handles legal identity. JOBBees verifies ABN via the "
         "free ABR API, and checks professional licences (plumber, electrician, "
         "builder etc.) manually via an admin queue. No identity-verification vendor."],
        ["Hosting and data residency",
         "Microsoft Azure, Australia East region. Cloudflare Pro at the edge "
         "for WAF and DDoS protection."],
        ["Payment processor",
         "Stripe with Stripe Connect Express. Test mode through Sprint 11, "
         "live mode flipped at the start of Sprint 12."],
        ["Auth tokens and edge security",
         "Bearer tokens for mobile, HttpOnly cookie + CSRF for the web admin. "
         "Cloudflare Pro WAF at $20 per month annually."],
        ["Brand colours and theme",
         "Locked from the original prototype with a Material You modernisation pass."],
        ["Stripe / Apple / Google accounts",
         "All in place. No enrolment lead-time blockers."],
        ["Map / geocoding provider",
         "Google Maps. Best AU coverage including regional NSW and the "
         "inner-Sydney suburb mix we are targeting at soft launch."],
    ]
    lt = Table(locked, colWidths=[5.2 * cm, 12.0 * cm])
    lt.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), white),
        ("ROWBACKGROUNDS", (0, 0), (-1, -1), [LIGHT, white]),
        ("FONT", (0, 0), (0, -1), "Helvetica-Bold", 10),
        ("FONT", (1, 0), (1, -1), "Helvetica", 10),
        ("TEXTCOLOR", (0, 0), (-1, -1), DARK),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 7),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
        ("GRID", (0, 0), (-1, -1), 0.25, BORDER),
        ("LINEBEFORE", (0, 0), (0, -1), 3, PRIMARY),
    ]))
    story.append(lt)
    story.append(Spacer(1, 14))

    # ----------------- DECISIONS STILL AHEAD -----------------
    story.append(Paragraph("Decisions still ahead", H1))
    story.append(Paragraph(
        "These are not blockers today, but each must be resolved before its "
        "matching sprint starts. We will surface each one again two weeks "
        "before it is needed.",
        BODY_GREY
    ))
    story.append(Spacer(1, 6))
    pending = [
        ["Phone OTP provider", "Sprint 5 D1  —  Mon 17 Aug",
         "Choose between Firebase Phone Auth, Notifyre, and Twilio Verify. "
         "Recommendation will be presented one sprint earlier."],
        ["Product analytics", "Sprint 11 D1  —  Mon 9 Nov",
         "PostHog (self-hostable in Australia) or Mixpanel."],
        ["Tax advisor — formal review", "Before Sprint 12 launch",
         "RFP and shortlist by mid-Sprint 5. Formal paid review in Sprint 11."],
        ["Lawyer review of Terms / Privacy", "Sprint 11",
         "Privacy Policy and Terms drafted in-house during Sprint 8. "
         "Lawyer review in Sprint 11 before live mode."],
    ]
    pt = Table(pending, colWidths=[4.5 * cm, 4.4 * cm, 8.3 * cm])
    pt.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), white),
        ("ROWBACKGROUNDS", (0, 0), (-1, -1), [LIGHT, white]),
        ("FONT", (0, 0), (0, -1), "Helvetica-Bold", 10),
        ("FONT", (1, 0), (1, -1), "Helvetica-Bold", 10),
        ("FONT", (2, 0), (2, -1), "Helvetica", 10),
        ("TEXTCOLOR", (0, 0), (-1, -1), DARK),
        ("TEXTCOLOR", (1, 0), (1, -1), PRIMARY),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 7),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
        ("GRID", (0, 0), (-1, -1), 0.25, BORDER),
    ]))
    story.append(pt)

    # ----------------- RISKS + NOT IN SCOPE -----------------
    story.append(PageBreak())
    story.append(Paragraph("Headline risks and how we manage them", H1))
    risks = [
        ("Australian tax law (GST + RCTI + ATO sharing-economy reporting) is "
         "complex.",
         "A tax advisor will be on retainer-light before Sprint 6 starts, "
         "and a formal review happens before launch."),
        ("Real iOS and Android devices behave differently from simulators.",
         "Sprint 11 is dedicated to TestFlight and Play Store internal testing "
         "with a 15-hour buffer for issues found on real devices."),
        ("Soft launch in one suburb can reveal problems we did not anticipate.",
         "That is exactly why the soft launch is restricted to a single "
         "Sydney suburb with 30-50 manually onboarded taskers."),
        ("AI extraction quality could underperform on real photos.",
         "Sprint 3 includes an evaluation harness with a 20-hour buffer "
         "in Sprint 4 for prompt refinement."),
        ("Stripe Connect onboarding requires Australian business test data.",
         "Stripe supports a documented test-mode flow that we already validated."),
    ]
    for risk, mit in risks:
        story.append(Paragraph(f"<b>Risk.</b> {risk}", BODY))
        story.append(Paragraph(f"<b>Mitigation.</b> {mit}", BODY_GREY))
        story.append(Spacer(1, 4))

    story.append(Spacer(1, 10))

    story.append(Paragraph("Explicitly not in scope for MVP", H1))
    story.append(Paragraph(
        "These are deliberately deferred to post-MVP releases. "
        "Calling them out so there are no surprises later.",
        BODY_GREY
    ))
    not_scope = [
        "<b>No multi-state engineering at MVP.</b> Per-state builder "
        "thresholds, per-state licence-register cross-checks, and "
        "time-zone-aware UI are deferred. The single-Sydney-suburb soft "
        "launch is an operational restriction (so we can monitor closely) "
        "and can expand to other Sydney suburbs at any time without "
        "code changes.",
        "International posters or taskers (Australia only).",
        "<b>Fine-grained admin role enforcement.</b> The schema and "
        "access-control policy already distinguish ADMIN from SUPER_ADMIN; "
        "at MVP both share the same permissions in the admin console. "
        "When the team grows beyond one admin, separate enforcement is "
        "roughly 4-6 hours of work.",
        "Police checks / Working-with-Children checks "
        "(only if child-related categories are added).",
        "Tasker insurance verification (post-MVP).",
        "Tasker availability calendar.",
        "Counter-offer or back-and-forth negotiation "
        "(replaced by public Q&A).",
    ]
    for item in not_scope:
        story.append(Paragraph(f"&#8226;  {item}", BULLET))

    # ----------------- WHAT WE NEED FROM YOU -----------------
    story.append(PageBreak())
    story.append(Paragraph("What we need from you", H1))
    story.append(Paragraph(
        "Most of the work happens on our side. These are the things we will "
        "ask of you, sprint by sprint, as they come up.",
        BODY_GREY
    ))
    story.append(Spacer(1, 6))

    asks = [
        ("Fri 19 Jun  (end of Sprint 0)",
         "Sign-off on the foundation demo and the development plan."),
        ("Fri 17 Jul  (end of Sprint 2)",
         "Sign-off on the first user-visible demo and the mobile look-and-feel."),
        ("Mon 17 Aug  (Sprint 5 D1)",
         "Phone OTP provider choice and tax advisor shortlist."),
        ("Mid Sep  (during Sprint 6)",
         "Availability for tax-advisor questions on RCTI / GST logic."),
        ("Mon 9 Nov  (Sprint 11 D1)",
         "Lawyer engaged for Terms + Privacy Policy review. "
         "Analytics provider choice."),
        ("Fri 20 Nov  (end of Sprint 11)",
         "Sign-off on TestFlight + Play Store builds. "
         "Confirm soft-launch suburb and tasker list."),
        ("Mon 23 Nov  (Sprint 12 D1)",
         "Final go / no-go on switching Stripe from test to live mode. "
         "This is a one-way decision."),
    ]
    asks_table = Table(
        [[Paragraph(f"<b>{when}</b>", TABLE_CELL_BOLD),
          Paragraph(what, TABLE_CELL)] for when, what in asks],
        colWidths=[5.4 * cm, 11.8 * cm],
    )
    asks_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), white),
        ("ROWBACKGROUNDS", (0, 0), (-1, -1), [LIGHT, white]),
        ("TEXTCOLOR", (0, 0), (0, -1), PRIMARY),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 7),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
        ("GRID", (0, 0), (-1, -1), 0.25, BORDER),
    ]))
    story.append(asks_table)

    # Build
    doc.build(story, onFirstPage=page_chrome, onLaterPages=page_chrome)
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    build_doc()
