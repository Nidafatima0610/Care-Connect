import os
import sys
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

PROJECT_DIR = r"D:\Internship daily projects\care_connect"
OUTPUT_DOCX = os.path.join(PROJECT_DIR, "CareConnect_Weekly_Final_Report.docx")

# Real CareConnect Teal-Green Branding Palette
COLOR_TEAL_DARK = RGBColor(12, 74, 90)     # #0C4A5A - Primary Headings
COLOR_TEAL = RGBColor(14, 116, 144)        # #0E7490 - Brand Primary & Section Titles
COLOR_TEAL_LIGHT = RGBColor(8, 145, 178)   # #0891B2 - Sub-headings & accents
COLOR_MINT = RGBColor(4, 120, 87)          # #047857 - Mint Green status/tags
COLOR_TEXT = RGBColor(15, 23, 42)          # #0F172A - Body text dark slate
COLOR_MUTED = RGBColor(71, 85, 105)        # #475569 - Secondary text / captions

HEX_TEAL = "0E7490"
HEX_TEAL_DARK = "0C4A5A"
HEX_TEAL_LIGHT = "0891B2"
HEX_TEAL_50 = "F0FDFA"                     # Soft teal background
HEX_BORDER = "CCFBF1"                      # Soft teal border
HEX_SLATE_BORDER = "E2E8F0"

def set_cell_background(cell, hex_color):
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{hex_color}"/>')
    cell._tc.get_or_add_tcPr().append(shd)

def set_cell_margins(cell, top=80, bottom=80, left=120, right=120):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(f'''
        <w:tcMar {nsdecls("w")}>
            <w:top w:w="{top}" w:type="dxa"/>
            <w:bottom w:w="{bottom}" w:type="dxa"/>
            <w:left w:w="{left}" w:type="dxa"/>
            <w:right w:w="{right}" w:type="dxa"/>
        </w:tcMar>
    ''')
    tcPr.append(tcMar)

def set_cell_borders(cell, top="none", bottom="none", left="none", right="none", 
                     color="CCCCCC", sz="4"):
    tcPr = cell._tc.get_or_add_tcPr()
    tcBorders = parse_xml(f'''
        <w:tcBorders {nsdecls("w")}>
            <w:top w:val="{top}" w:sz="{sz}" w:space="0" w:color="{color}"/>
            <w:left w:val="{left}" w:sz="{sz}" w:space="0" w:color="{color}"/>
            <w:bottom w:val="{bottom}" w:sz="{sz}" w:space="0" w:color="{color}"/>
            <w:right w:val="{right}" w:sz="{sz}" w:space="0" w:color="{color}"/>
        </w:tcBorders>
    ''')
    tcPr.append(tcBorders)

def add_heading_1(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(14)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text)
    run.font.name = "Segoe UI"
    run.font.size = Pt(15)
    run.font.bold = True
    run.font.color.rgb = COLOR_TEAL_DARK
    return p

def add_heading_2(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(10)
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text)
    run.font.name = "Segoe UI"
    run.font.size = Pt(12)
    run.font.bold = True
    run.font.color.rgb = COLOR_TEAL
    return p

def add_body_p(doc, text, bold_prefix=None, space_after=4):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(space_after)
    p.paragraph_format.line_spacing = 1.15
    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        r_pre.font.name = "Segoe UI"
        r_pre.font.size = Pt(10)
        r_pre.font.bold = True
        r_pre.font.color.rgb = COLOR_TEAL_DARK
    run = p.add_run(text)
    run.font.name = "Segoe UI"
    run.font.size = Pt(10)
    run.font.color.rgb = COLOR_TEXT
    return p

def add_bullet_p(doc, text, bold_prefix=None):
    p = doc.add_paragraph(style='List Bullet')
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(2.5)
    p.paragraph_format.line_spacing = 1.15
    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        r_pre.font.name = "Segoe UI"
        r_pre.font.size = Pt(10)
        r_pre.font.bold = True
        r_pre.font.color.rgb = COLOR_TEAL_DARK
    run = p.add_run(text)
    run.font.name = "Segoe UI"
    run.font.size = Pt(10)
    run.font.color.rgb = COLOR_TEXT
    return p

def add_image_pair(doc, img_path1, caption1, img_path2, caption2, target_width=Inches(3.0)):
    tbl = doc.add_table(rows=2, cols=2)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.autofit = False

    cell_img1, cell_img2 = tbl.cell(0, 0), tbl.cell(0, 1)
    cell_img1.width = Inches(3.35)
    cell_img2.width = Inches(3.35)
    
    set_cell_background(cell_img1, HEX_TEAL_50)
    set_cell_background(cell_img2, HEX_TEAL_50)
    set_cell_margins(cell_img1, top=60, bottom=40, left=40, right=40)
    set_cell_margins(cell_img2, top=60, bottom=40, left=40, right=40)
    set_cell_borders(cell_img1, top="single", bottom="none", left="single", right="single", color=HEX_BORDER, sz="4")
    set_cell_borders(cell_img2, top="single", bottom="none", left="single", right="single", color=HEX_BORDER, sz="4")

    p1 = cell_img1.paragraphs[0]
    p1.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p1.paragraph_format.space_before = Pt(0)
    p1.paragraph_format.space_after = Pt(0)
    if os.path.exists(img_path1):
        p1.add_run().add_picture(img_path1, width=target_width)
    else:
        p1.add_run(f"[Image: {os.path.basename(img_path1)}]")

    p2 = cell_img2.paragraphs[0]
    p2.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p2.paragraph_format.space_before = Pt(0)
    p2.paragraph_format.space_after = Pt(0)
    if os.path.exists(img_path2):
        p2.add_run().add_picture(img_path2, width=target_width)
    else:
        p2.add_run(f"[Image: {os.path.basename(img_path2)}]")

    cell_cap1, cell_cap2 = tbl.cell(1, 0), tbl.cell(1, 1)
    cell_cap1.width = Inches(3.35)
    cell_cap2.width = Inches(3.35)
    
    set_cell_background(cell_cap1, HEX_TEAL_50)
    set_cell_background(cell_cap2, HEX_TEAL_50)
    set_cell_margins(cell_cap1, top=20, bottom=60, left=40, right=40)
    set_cell_margins(cell_cap2, top=20, bottom=60, left=40, right=40)
    set_cell_borders(cell_cap1, top="none", bottom="single", left="single", right="single", color=HEX_BORDER, sz="4")
    set_cell_borders(cell_cap2, top="none", bottom="single", left="single", right="single", color=HEX_BORDER, sz="4")

    cp1 = cell_cap1.paragraphs[0]
    cp1.alignment = WD_ALIGN_PARAGRAPH.CENTER
    cp1.paragraph_format.space_before = Pt(0)
    cp1.paragraph_format.space_after = Pt(0)
    r1 = cp1.add_run(caption1)
    r1.font.name = "Segoe UI"
    r1.font.size = Pt(8.5)
    r1.font.italic = True
    r1.font.color.rgb = COLOR_MUTED

    cp2 = cell_cap2.paragraphs[0]
    cp2.alignment = WD_ALIGN_PARAGRAPH.CENTER
    cp2.paragraph_format.space_before = Pt(0)
    cp2.paragraph_format.space_after = Pt(0)
    r2 = cp2.add_run(caption2)
    r2.font.name = "Segoe UI"
    r2.font.size = Pt(8.5)
    r2.font.italic = True
    r2.font.color.rgb = COLOR_MUTED

    doc.add_paragraph().paragraph_format.space_after = Pt(4)

def add_single_image(doc, img_path, caption, target_width=Inches(3.0)):
    tbl = doc.add_table(rows=2, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.autofit = False

    cell_img = tbl.cell(0, 0)
    cell_img.width = Inches(6.7)
    set_cell_background(cell_img, HEX_TEAL_50)
    set_cell_margins(cell_img, top=60, bottom=30, left=40, right=40)
    set_cell_borders(cell_img, top="single", bottom="none", left="single", right="single", color=HEX_BORDER, sz="4")

    p = cell_img.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(0)
    if os.path.exists(img_path):
        p.add_run().add_picture(img_path, width=target_width)
    else:
        p.add_run(f"[Image: {os.path.basename(img_path)}]")

    cell_cap = tbl.cell(1, 0)
    cell_cap.width = Inches(6.7)
    set_cell_background(cell_cap, HEX_TEAL_50)
    set_cell_margins(cell_cap, top=20, bottom=60, left=40, right=40)
    set_cell_borders(cell_cap, top="none", bottom="single", left="single", right="single", color=HEX_BORDER, sz="4")

    cp = cell_cap.paragraphs[0]
    cp.alignment = WD_ALIGN_PARAGRAPH.CENTER
    cp.paragraph_format.space_before = Pt(0)
    cp.paragraph_format.space_after = Pt(0)
    r = cp.add_run(caption)
    r.font.name = "Segoe UI"
    r.font.size = Pt(8.5)
    r.font.italic = True
    r.font.color.rgb = COLOR_MUTED

    doc.add_paragraph().paragraph_format.space_after = Pt(4)


def build_document():
    doc = Document()

    # Configure A4 Page Setup (matching SkyCast / SpendWise)
    section = doc.sections[0]
    section.page_width = Inches(8.27)
    section.page_height = Inches(11.69)
    section.top_margin = Inches(0.8)
    section.bottom_margin = Inches(0.8)
    section.left_margin = Inches(0.8)
    section.right_margin = Inches(0.8)

    # Header and Footer
    header = section.header
    hp = header.paragraphs[0]
    hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    hrun = hp.add_run("CareConnect – Weekly Final Project Report")
    hrun.font.name = "Segoe UI"
    hrun.font.size = Pt(8.5)
    hrun.font.color.rgb = COLOR_MUTED

    footer = section.footer
    fp = footer.paragraphs[0]
    fp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    frun = fp.add_run("Stack & Scale Remote Internship 2026  •  Week 04 Final Submission")
    frun.font.name = "Segoe UI"
    frun.font.size = Pt(8.5)
    frun.font.color.rgb = COLOR_MUTED

    # ==========================================
    # COVER PAGE (Matching SkyCast & SpendWise Series Style)
    # ==========================================
    p_subm = doc.add_paragraph()
    p_subm.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_subm.paragraph_format.space_before = Pt(36)
    p_subm.paragraph_format.space_after = Pt(8)
    r_subm = p_subm.add_run("STACK & SCALE REMOTE INTERNSHIP 2026  •  WEEK 04 FINAL SUBMISSION")
    r_subm.font.name = "Segoe UI"
    r_subm.font.size = Pt(9.5)
    r_subm.font.bold = True
    r_subm.font.color.rgb = COLOR_TEAL

    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_title.paragraph_format.space_before = Pt(4)
    p_title.paragraph_format.space_after = Pt(6)
    r_title = p_title.add_run("CareConnect – Clinic Appointment Booking App")
    r_title.font.name = "Segoe UI"
    r_title.font.size = Pt(24)
    r_title.font.bold = True
    r_title.font.color.rgb = COLOR_TEXT

    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_sub.paragraph_format.space_before = Pt(0)
    p_sub.paragraph_format.space_after = Pt(20)
    r_sub = p_sub.add_run("Comprehensive Final Technical & Internship Completion Report")
    r_sub.font.name = "Segoe UI"
    r_sub.font.size = Pt(12)
    r_sub.font.color.rgb = COLOR_MUTED

    # Executive Overview Callout Box (matching SkyCast Table 0)
    callout_tbl = doc.add_table(rows=1, cols=1)
    callout_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    callout_cell = callout_tbl.cell(0, 0)
    callout_cell.width = Inches(6.67)
    set_cell_background(callout_cell, HEX_TEAL_50)
    set_cell_margins(callout_cell, top=100, bottom=100, left=140, right=140)
    set_cell_borders(callout_cell, top="single", bottom="single", left="single", right="single", color=HEX_BORDER, sz="8")
    
    cp = callout_cell.paragraphs[0]
    cp.paragraph_format.space_after = Pt(0)
    cp.paragraph_format.line_spacing = 1.15
    r_c_title = cp.add_run("Executive Overview: ")
    r_c_title.font.name = "Segoe UI"
    r_c_title.font.size = Pt(10)
    r_c_title.font.bold = True
    r_c_title.font.color.rgb = COLOR_TEAL_DARK

    r_c_body = cp.add_run(
        "CareConnect is a cross-platform Flutter application engineered for clinic discovery, doctor scheduling, and appointment management. "
        "Built during Week 04 (16–20 November 2026), the application integrates a clean feature-first architecture, reactive Riverpod state management, "
        "declarative GoRouter routing, durable local SQLite database persistence, and local push notifications with 30-minute lead time reminders. "
        "Every layer has been verified with 117 automated unit and widget tests (100% pass rate) and zero analyzer issues."
    )
    r_c_body.font.name = "Segoe UI"
    r_c_body.font.size = Pt(9.5)
    r_c_body.font.color.rgb = COLOR_TEXT

    doc.add_paragraph().paragraph_format.space_after = Pt(12)

    # Submission Metadata Table (matching SkyCast & SpendWise series)
    meta_tbl = doc.add_table(rows=6, cols=2)
    meta_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    meta_tbl.autofit = False

    meta_rows = [
        ("Intern / Student Name", "Nida Fatima"),
        ("Contact Email Address", "nidafatima0610@gmail.com"),
        ("Internship Program", "Stack & Scale Remote Internship 2026"),
        ("Project Duration & Track", "Day 1 to Day 5 (Week 04) • Flutter Mobile App Development"),
        ("Technology Stack", "Flutter, Dart, Riverpod, GoRouter, SQLite (sqflite), Local Notifications"),
        ("Final Verification Status", "117 / 117 Tests Passed (100%), 0 Analyzer Issues, Verified on 360x800 & 412x915")
    ]

    for idx, (label, val) in enumerate(meta_rows):
        row = meta_tbl.rows[idx]
        c0, c1 = row.cells[0], row.cells[1]
        c0.width = Inches(2.2)
        c1.width = Inches(4.47)
        set_cell_background(c0, HEX_TEAL_50 if idx % 2 == 0 else "FFFFFF")
        set_cell_background(c1, HEX_TEAL_50 if idx % 2 == 0 else "FFFFFF")
        set_cell_margins(c0, top=60, bottom=60, left=90, right=90)
        set_cell_margins(c1, top=60, bottom=60, left=90, right=90)
        set_cell_borders(c0, top="single", bottom="single", left="none", right="none", color=HEX_SLATE_BORDER, sz="4")
        set_cell_borders(c1, top="single", bottom="single", left="none", right="none", color=HEX_SLATE_BORDER, sz="4")

        p0 = c0.paragraphs[0]
        p0.paragraph_format.space_after = Pt(0)
        r0 = p0.add_run(label)
        r0.font.name = "Segoe UI"
        r0.font.size = Pt(9)
        r0.font.bold = True
        r0.font.color.rgb = COLOR_TEAL_DARK

        p1 = c1.paragraphs[0]
        p1.paragraph_format.space_after = Pt(0)
        r1 = p1.add_run(val)
        r1.font.name = "Segoe UI"
        r1.font.size = Pt(9)
        r1.font.color.rgb = COLOR_TEXT

    doc.add_page_break()

    # ==========================================
    # SECTION 1: PROJECT TITLE, PURPOSE & OVERVIEW
    # ==========================================
    add_heading_1(doc, "1. Project Title, Purpose & Overview")
    
    add_body_p(doc,
        "CareConnect is a cross-platform clinic appointment booking and reminder mobile application developed with Flutter and Dart. "
        "It provides patients with a reliable, straightforward way to find healthcare specialists, schedule consultations, and keep track of upcoming appointments.",
        bold_prefix="Project Overview: "
    )

    add_body_p(doc,
        "Finding the right doctor and managing medical appointments often involves phone calls, uncertain availability, and missed consultations. "
        "CareConnect was built to give patients clear information about doctors, transparent consultation fees, available dates and times, and timely appointment reminders. "
        "The app is designed to work smoothly even when internet connectivity is intermittent, storing saved appointments safely on the device.",
        bold_prefix="Problem Statement & Purpose: "
    )

    add_body_p(doc,
        "Patients can browse specialists across 8 medical departments (such as Cardiology, Pediatrics, and Neurology), search for doctors by name or clinic, "
        "view doctor profiles with patient reviews and fees, and pick an appointment slot from a 14-day calendar. Confirmed bookings are saved to a local SQLite database, "
        "allowing patients to review their booking history, reschedule visits, or cancel appointments when plans change.",
        bold_prefix="How It Helps Users: "
    )

    add_body_p(doc,
        "The application follows a clean feature-first architecture, separating presentation widgets, business logic, and local data storage. "
        "Riverpod manages application state reactively, GoRouter handles screen navigation, sqflite stores appointment records persistently on the device, "
        "and flutter_local_notifications schedules reminders 30 minutes before each visit. The user interface uses a calming teal-green color palette with warm neutral surfaces.",
        bold_prefix="Architecture & Technology Workflow: "
    )

    # ==========================================
    # SECTION 2: DAY 1–DAY 5 PROGRESS EVIDENCE
    # ==========================================
    add_heading_1(doc, "2. Day 1–Day 5 Progress Evidence")
    add_body_p(doc, "The following sections summarize each day's development progress, accompanied by genuine evidence screenshots from the project.")

    # Day 1
    add_heading_2(doc, "Day 1 — Doctor Discovery & Application Foundation")
    add_body_p(doc,
        "On Day 1, the core UI design system and doctor discovery experience were built. "
        "The home screen was created with a greeting header, hero banner, specialty chips, and featured doctor cards. "
        "The doctor details view was implemented showing credentials, patient metrics, weekly schedule, and consultation fee."
    )
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_1", "01_home_screen.png"),
        "Figure 2.1: Day 1 Home Doctor Discovery Screen",
        os.path.join(PROJECT_DIR, "evidence", "day_1", "03_doctor_detail_screen.png"),
        "Figure 2.2: Day 1 Doctor Details Screen with Clinical Metrics"
    )

    # Day 2
    add_heading_2(doc, "Day 2 — Search, Specialty Filters & Patient Profile")
    add_body_p(doc,
        "Day 2 introduced an asynchronous doctor search pipeline with real-time query debouncing and department filtering. "
        "A patient profile screen backed by local storage was created with an editable demographic form and input validation. "
        "Loading shimmer skeletons, contextual empty states, and error retry screens were also implemented."
    )
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_2", "01_doctor_search_results.png"),
        "Figure 2.3: Day 2 Real-Time Debounced Doctor Search",
        os.path.join(PROJECT_DIR, "evidence", "day_2", "03_patient_profile_screen.png"),
        "Figure 2.4: Day 2 Patient Profile Screen with Demographics"
    )

    # Day 3
    add_heading_2(doc, "Day 3 — Appointment Booking & Scheduling")
    add_body_p(doc,
        "Day 3 completed the booking flow with an interactive 14-day calendar strip and dynamic Morning, Afternoon, and Evening time slots. "
        "Defensive validation rules were added to block past dates, conflicting slots, and duplicate bookings for the same doctor. "
        "A booking summary card and digital confirmation receipt screen were also established."
    )
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_3", "01_booking_screen.png"),
        "Figure 2.5: Day 3 Appointment Booking with 14-Day Calendar",
        os.path.join(PROJECT_DIR, "evidence", "day_3", "05_booking_confirmation.png"),
        "Figure 2.6: Day 3 Booking Confirmation Receipt Screen"
    )

    # Day 4
    add_heading_2(doc, "Day 4 — Local Persistence, Cancellation & Reminders")
    add_body_p(doc,
        "Day 4 upgraded storage to a local SQLite database (sqflite) so all appointments persist across app restarts. "
        "Appointment cancellation was implemented with a confirmation dialog that releases time slots, alongside an appointment rescheduling screen. "
        "Local notification reminders were configured to trigger 30 minutes before consultations, with an in-app test reminder button."
    )
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_4", "01_persistent_appointment_history.png"),
        "Figure 2.7: Day 4 Persistent Appointment History Screen",
        os.path.join(PROJECT_DIR, "evidence", "day_4", "03_cancellation_confirmation.png"),
        "Figure 2.8: Day 4 Appointment Cancellation Confirmation Modal"
    )

    # Day 5
    add_heading_2(doc, "Day 5 — Final Testing, Quality Assurance & Documentation")
    add_body_p(doc,
        "Day 5 focused on thorough testing and verification. All 117 automated unit and widget tests passed with a 100% success rate, and flutter analyze reported 0 issues. "
        "The interface was verified across both small (360x800) and standard (412x915) screen sizes with zero pixel overflow defects, and documentation was finalized."
    )
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_5", "07_cancellation_and_rescheduling.png"),
        "Figure 2.9: Day 5 Reschedule Slot Review Screen",
        os.path.join(PROJECT_DIR, "evidence", "day_5", "09_responsive_small_360x800_home.png"),
        "Figure 2.10: Day 5 Responsive Small Phone View (360x800)"
    )

    # ==========================================
    # SECTION 3: FINAL WEEKLY PROJECT OUTPUT
    # ==========================================
    add_heading_1(doc, "3. Final Weekly Project Output")
    add_body_p(doc, "The following gallery presents genuine screenshots of the completed CareConnect application in its final, verified state.")

    add_heading_2(doc, "Home Dashboard & Doctor Clinical Details")
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_5", "01_home_doctor_discovery.png"),
        "Figure 3.1: Final Home Screen — Header, Hero Banner, Specialties & Doctors",
        os.path.join(PROJECT_DIR, "evidence", "day_5", "02_doctor_details.png"),
        "Figure 3.2: Final Doctor Details Screen — Credentials, Metrics & Sticky Fee Bar"
    )

    add_heading_2(doc, "Booking Flow & Confirmation Receipt")
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_5", "04_appointment_booking.png"),
        "Figure 3.3: Final Booking Screen — Calendar Strip & Time Slot Selection",
        os.path.join(PROJECT_DIR, "evidence", "day_5", "05_booking_confirmation.png"),
        "Figure 3.4: Final Confirmation Screen — Digital Receipt with Appointment ID"
    )

    add_heading_2(doc, "Appointment History & Patient Profile")
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_5", "06_appointment_history.png"),
        "Figure 3.5: Final History Screen — Confirmed Cards with Actions & Reminder Pill",
        os.path.join(PROJECT_DIR, "evidence", "day_5", "08_patient_profile.png"),
        "Figure 3.6: Final Patient Profile — Demographics, Clinical Details & Edit Action"
    )

    # ==========================================
    # SECTION 4: COMPLETED FEATURES & DELIVERABLES
    # ==========================================
    add_heading_1(doc, "4. Completed Features & Deliverables")
    add_body_p(doc, "The following features were fully implemented and verified in the CareConnect project:")

    deliverables = [
        ("Doctor Discovery & Details: ", "Browse physicians categorized by department. Featured doctor horizontal carousel, comprehensive doctor profiles with patient counts, experience years, star ratings, review counts, clinical biography, weekly schedule, and consultation fee."),
        ("Real-Time Search & Specialty Filtering: ", "Instant doctor search with 250ms debouncing across names, subspecialties, and clinics. Horizontal filter selector covering 8 medical specialties (Cardiology, Neurology, Pediatrics, Orthopedics, Dermatology, Psychiatry, General Medicine, Ophthalmology)."),
        ("Patient Profile Management: ", "Local patient demographic storage using SharedPreferences. Displays patient avatar, MRN badge, contact information, emergency contact, blood group, allergies, and preferred clinic facility, with an editable profile form."),
        ("14-Day Calendar & Slot Selection: ", "Horizontal calendar strip showing the next 14 days. Time slots grouped into Morning, Afternoon, and Evening intervals with availability status chips."),
        ("Booking Confirmation & Digital Receipt: ", "Review summary card calculating total fees before submission. Generates a confirmation receipt card with a unique Appointment ID badge, doctor details, and deep-link navigation."),
        ("Persistent Appointment History: ", "Upcoming and Past consultation tabs displaying doctor details, scheduled dates, fees, reminder status indicators, and action buttons."),
        ("Appointment Cancellation & Slot Release: ", "Cancel upcoming visits with a confirmation dialog. Updates status to cancelled in SQLite, preserves medical history records, and immediately frees the time slot for future bookings."),
        ("Appointment Rescheduling: ", "Rescheduling screen displaying the current booking banner and allowing selection of a new date and available slot with atomic slot swapping and reminder updates."),
        ("SQLite Local-First Persistence: ", "Persistent local database (sqflite v2 schema) ensuring all confirmed, rescheduled, and cancelled appointments remain saved after application restart."),
        ("Offline Access: ", "Previously saved appointments and doctor listings remain accessible without an active internet connection. Shows an offline indicator banner when disconnected."),
        ("Local Push Reminders: ", "Android notification channel with high importance. Calculates 30-minute lead time exact alarms before appointments, with an in-app instant demo reminder button for testing."),
        ("Booking Validation Rules: ", "Prevents selecting past dates or elapsed times on the current day, blocks conflicting bookings for the same doctor, and prevents duplicate appointments."),
        ("Responsive Layouts: ", "Verified responsive layouts for small phone viewports (360x800) and standard modern screens (412x915) with zero pixel overflows."),
        ("Automated Quality Assurance: ", "117 passing automated unit and widget tests with zero static analysis issues (flutter analyze clean).")
    ]

    for title, desc in deliverables:
        add_bullet_p(doc, desc, bold_prefix=title)

    # ==========================================
    # SECTION 5: MAIN APPLICATION FLOW
    # ==========================================
    add_heading_1(doc, "5. Main Application Flow & Key Functions")
    add_body_p(doc, "The patient experience follows a 9-step journey from initial doctor exploration to persistent appointment tracking:")

    flow_steps = [
        ("Step 1: Open CareConnect & Explore Dashboard",
         "The patient opens the application to the Home dashboard (/home). A personalized header welcomes the patient by name, displays the hero care banner, and presents specialty categories and featured doctors."),
        
        ("Step 2: Browse Medical Specialties",
         "The patient taps a specialty category chip (such as Cardiology or Pediatrics) to instantly filter the doctor directory to relevant medical specialists."),
        
        ("Step 3: Search Doctors by Query",
         "The patient types into the search bar. The debounced search filter matches doctor names, subspecialties, and clinic facility locations without lag."),
        
        ("Step 4: Inspect Physician Clinical Details",
         "Tapping a doctor card opens the Doctor Detail Screen (/doctors/:id). The patient reviews the doctor's metrics, biography, hospital location, and consultation fee before deciding to book."),
        
        ("Step 5: Pick Date & Time Slot",
         "The patient taps 'Book Appointment' to open the Booking Screen (/booking/:doctorId). They pick an available date from the 14-day calendar strip and select a convenient time slot from the Morning, Afternoon, or Evening grid."),
        
        ("Step 6: Confirm the Booking & Review Receipt",
         "The patient reviews the booking summary card and taps 'Confirm Booking'. Upon validation, the confirmation screen displays a verified receipt with a unique Appointment ID."),
        
        ("Step 7: View Persistent Appointment History",
         "The patient navigates to the Appointment History Screen (/appointments). The confirmed consultation appears under the Upcoming tab with a green reminder indicator and action buttons."),
        
        ("Step 8: Cancel or Reschedule Appointments",
         "If schedule changes occur, the patient can tap 'Reschedule' to select a new slot, or tap 'Cancel Visit' to open a confirmation dialog. Cancelling releases the time slot immediately and updates the reminder."),
        
        ("Step 9: Reopen Application & Verify Stored Data",
         "When the patient restarts the application, all confirmed appointments, rescheduled dates, and cancelled statuses load directly from the local SQLite database.")
    ]

    for title, desc in flow_steps:
        add_heading_2(doc, title)
        add_body_p(doc, desc)

    # Add 4 key representative screenshots to illustrate the journey
    add_heading_2(doc, "Representative Flow Screenshots")
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_5", "02_doctor_details.png"),
        "Figure 5.1: Reviewing Physician Clinical Profile (Step 4)",
        os.path.join(PROJECT_DIR, "evidence", "day_5", "04_appointment_booking.png"),
        "Figure 5.2: Selecting Date & Available Time Slot (Step 5)"
    )
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_5", "06_appointment_history.png"),
        "Figure 5.3: Viewing Confirmed Bookings in History (Step 7)",
        os.path.join(PROJECT_DIR, "evidence", "day_4", "03_cancellation_confirmation.png"),
        "Figure 5.4: Managing Cancellations with Confirmation Dialog (Step 8)"
    )

    # ==========================================
    # SECTION 6: WEEKLY LEARNING OUTCOMES
    # ==========================================
    add_heading_1(doc, "6. Weekly Learning Outcomes")
    add_body_p(doc,
        "The 5-day CareConnect internship project provided valuable practical experience across the mobile application development lifecycle. "
        "The following core technical competencies were gained during the week:"
    )

    outcomes = [
        ("Flutter & Dart Fundamentals: ", "Learned to build responsive user interfaces using sound null safety, immutable data models, custom theme tokens, and reusable widgets."),
        ("State Management with Riverpod: ", "Gained practical experience using Riverpod 2.x, including FutureProvider for async data, AsyncNotifier for mutation controllers, and query debouncing."),
        ("Declarative Navigation with GoRouter: ", "Configured structured app routing with path parameters, query parameters, deep links, and smooth page transitions."),
        ("Local Persistence with SQLite: ", "Implemented local database storage using sqflite, including table creation, CRUD operations, slot availability checks, and preserving records across restarts."),
        ("Device Local Notifications: ", "Integrated flutter_local_notifications to configure Android notification channels and calculate 30-minute lead time exact alarms for upcoming appointments."),
        ("Validation & Defensive Programming: ", "Implemented defensive checks to reject past dates, prevent double-bookings, and release time slots safely upon cancellation."),
        ("Responsive UI Testing: ", "Tested layouts across different phone screen sizes (360x800 and 412x915), using flexible widgets to eliminate pixel overflow errors."),
        ("Automated Testing & QA: ", "Wrote and maintained 117 unit and widget tests, achieving 100% test passing rate and zero analyzer issues."),
        ("Technical Documentation: ", "Learned to write clear, honest project documentation detailing implemented features, test metrics, and architectural decisions.")
    ]

    for title, desc in outcomes:
        add_bullet_p(doc, desc, bold_prefix=title)

    # Save Document to Project Root
    doc.save(OUTPUT_DOCX)
    print(f"\nSuccessfully generated revised document: {OUTPUT_DOCX}")
    stat = os.stat(OUTPUT_DOCX)
    print(f"File size: {stat.st_size / (1024 * 1024):.2f} MB ({stat.st_size} bytes)")

    # Also save to evidence/final_submission/
    import shutil
    final_sub_dir = os.path.join(PROJECT_DIR, "evidence", "final_submission")
    os.makedirs(final_sub_dir, exist_ok=True)
    final_sub_docx = os.path.join(final_sub_dir, "CareConnect_Weekly_Final_Report.docx")
    shutil.copy2(OUTPUT_DOCX, final_sub_docx)
    print(f"Successfully copied document to: {final_sub_docx}")

if __name__ == "__main__":
    build_document()
