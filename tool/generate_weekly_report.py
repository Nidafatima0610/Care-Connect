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

# Brand Color Palette (Deep Navy, Teal, Warm Ivory, Mint)
COLOR_NAVY = RGBColor(14, 26, 45)        # #0E1A2D
COLOR_TEAL = RGBColor(14, 116, 144)      # #0E7490
COLOR_DARK_TEAL = RGBColor(15, 118, 110) # #0F766E
COLOR_MINT = RGBColor(16, 185, 129)      # #10B981
COLOR_MUTED = RGBColor(100, 116, 139)    # #64748B
COLOR_TEXT = RGBColor(30, 41, 59)        # #1E293B

HEX_NAVY = "0E1A2D"
HEX_TEAL = "0E7490"
HEX_LIGHT_BG = "F8FAFC"
HEX_BORDER = "E2E8F0"
HEX_IVORY = "FBFBFA"

def set_cell_background(cell, hex_color):
    shading_elm = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{hex_color}"/>')
    cell._tc.get_or_add_tcPr().append(shading_elm)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
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
    p.paragraph_format.space_before = Pt(18)
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text)
    run.font.name = "Arial"
    run.font.size = Pt(15)
    run.font.bold = True
    run.font.color.rgb = COLOR_NAVY
    return p

def add_heading_2(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(14)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text)
    run.font.name = "Arial"
    run.font.size = Pt(12.5)
    run.font.bold = True
    run.font.color.rgb = COLOR_TEAL
    return p

def add_heading_3(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(10)
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text)
    run.font.name = "Arial"
    run.font.size = Pt(11)
    run.font.bold = True
    run.font.color.rgb = COLOR_NAVY
    return p

def add_body_p(doc, text, bold_prefix=None, space_after=5):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(space_after)
    p.paragraph_format.line_spacing = 1.15
    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        r_pre.font.name = "Arial"
        r_pre.font.size = Pt(10)
        r_pre.font.bold = True
        r_pre.font.color.rgb = COLOR_NAVY
    run = p.add_run(text)
    run.font.name = "Arial"
    run.font.size = Pt(10)
    run.font.color.rgb = COLOR_TEXT
    return p

def add_bullet_p(doc, text, bold_prefix=None):
    p = doc.add_paragraph(style='List Bullet')
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.line_spacing = 1.15
    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        r_pre.font.name = "Arial"
        r_pre.font.size = Pt(10)
        r_pre.font.bold = True
        r_pre.font.color.rgb = COLOR_NAVY
    run = p.add_run(text)
    run.font.name = "Arial"
    run.font.size = Pt(10)
    run.font.color.rgb = COLOR_TEXT
    return p

def add_image_pair(doc, img_path1, caption1, img_path2, caption2, target_width=Inches(3.1)):
    tbl = doc.add_table(rows=2, cols=2)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.autofit = False

    cell_img1 = tbl.cell(0, 0)
    cell_img2 = tbl.cell(0, 1)
    cell_img1.width = Inches(3.35)
    cell_img2.width = Inches(3.35)
    
    set_cell_background(cell_img1, HEX_LIGHT_BG)
    set_cell_background(cell_img2, HEX_LIGHT_BG)
    set_cell_margins(cell_img1, top=70, bottom=50, left=50, right=50)
    set_cell_margins(cell_img2, top=70, bottom=50, left=50, right=50)
    set_cell_borders(cell_img1, top="single", bottom="none", left="single", right="single", color=HEX_BORDER, sz="4")
    set_cell_borders(cell_img2, top="single", bottom="none", left="single", right="single", color=HEX_BORDER, sz="4")

    p1 = cell_img1.paragraphs[0]
    p1.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p1.paragraph_format.space_before = Pt(0)
    p1.paragraph_format.space_after = Pt(0)
    if os.path.exists(img_path1):
        p1.add_run().add_picture(img_path1, width=target_width)
    else:
        p1.add_run(f"[Image Missing: {os.path.basename(img_path1)}]")

    p2 = cell_img2.paragraphs[0]
    p2.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p2.paragraph_format.space_before = Pt(0)
    p2.paragraph_format.space_after = Pt(0)
    if os.path.exists(img_path2):
        p2.add_run().add_picture(img_path2, width=target_width)
    else:
        p2.add_run(f"[Image Missing: {os.path.basename(img_path2)}]")

    cell_cap1 = tbl.cell(1, 0)
    cell_cap2 = tbl.cell(1, 1)
    cell_cap1.width = Inches(3.35)
    cell_cap2.width = Inches(3.35)
    
    set_cell_background(cell_cap1, HEX_LIGHT_BG)
    set_cell_background(cell_cap2, HEX_LIGHT_BG)
    set_cell_margins(cell_cap1, top=30, bottom=70, left=50, right=50)
    set_cell_margins(cell_cap2, top=30, bottom=70, left=50, right=50)
    set_cell_borders(cell_cap1, top="none", bottom="single", left="single", right="single", color=HEX_BORDER, sz="4")
    set_cell_borders(cell_cap2, top="none", bottom="single", left="single", right="single", color=HEX_BORDER, sz="4")

    cp1 = cell_cap1.paragraphs[0]
    cp1.alignment = WD_ALIGN_PARAGRAPH.CENTER
    cp1.paragraph_format.space_before = Pt(0)
    cp1.paragraph_format.space_after = Pt(0)
    r_cap1 = cp1.add_run(caption1)
    r_cap1.font.name = "Arial"
    r_cap1.font.size = Pt(8.5)
    r_cap1.font.italic = True
    r_cap1.font.color.rgb = COLOR_MUTED

    cp2 = cell_cap2.paragraphs[0]
    cp2.alignment = WD_ALIGN_PARAGRAPH.CENTER
    cp2.paragraph_format.space_before = Pt(0)
    cp2.paragraph_format.space_after = Pt(0)
    r_cap2 = cp2.add_run(caption2)
    r_cap2.font.name = "Arial"
    r_cap2.font.size = Pt(8.5)
    r_cap2.font.italic = True
    r_cap2.font.color.rgb = COLOR_MUTED

    p_spacer = doc.add_paragraph()
    p_spacer.paragraph_format.space_before = Pt(0)
    p_spacer.paragraph_format.space_after = Pt(6)

def add_single_image(doc, img_path, caption, target_width=Inches(3.2)):
    tbl = doc.add_table(rows=2, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.autofit = False

    cell_img = tbl.cell(0, 0)
    cell_img.width = Inches(6.77)
    set_cell_background(cell_img, HEX_LIGHT_BG)
    set_cell_margins(cell_img, top=70, bottom=30, left=50, right=50)
    set_cell_borders(cell_img, top="single", bottom="none", left="single", right="single", color=HEX_BORDER, sz="4")

    p = cell_img.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(0)
    if os.path.exists(img_path):
        p.add_run().add_picture(img_path, width=target_width)
    else:
        p.add_run(f"[Image Missing: {os.path.basename(img_path)}]")

    cell_cap = tbl.cell(1, 0)
    cell_cap.width = Inches(6.77)
    set_cell_background(cell_cap, HEX_LIGHT_BG)
    set_cell_margins(cell_cap, top=20, bottom=70, left=50, right=50)
    set_cell_borders(cell_cap, top="none", bottom="single", left="single", right="single", color=HEX_BORDER, sz="4")

    cp = cell_cap.paragraphs[0]
    cp.alignment = WD_ALIGN_PARAGRAPH.CENTER
    cp.paragraph_format.space_before = Pt(0)
    cp.paragraph_format.space_after = Pt(0)
    r_cap = cp.add_run(caption)
    r_cap.font.name = "Arial"
    r_cap.font.size = Pt(8.5)
    r_cap.font.italic = True
    r_cap.font.color.rgb = COLOR_MUTED

    p_spacer = doc.add_paragraph()
    p_spacer.paragraph_format.space_before = Pt(0)
    p_spacer.paragraph_format.space_after = Pt(6)


def build_document():
    doc = Document()

    # Configure A4 Page Setup
    section = doc.sections[0]
    section.page_width = Inches(8.27)
    section.page_height = Inches(11.69)
    section.top_margin = Inches(0.75)
    section.bottom_margin = Inches(0.75)
    section.left_margin = Inches(0.75)
    section.right_margin = Inches(0.75)

    # Configure Header and Footer
    header = section.header
    hp = header.paragraphs[0]
    hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    hrun = hp.add_run("CareConnect — Weekly Final Project Report")
    hrun.font.name = "Arial"
    hrun.font.size = Pt(8.5)
    hrun.font.color.rgb = COLOR_MUTED

    footer = section.footer
    fp = footer.paragraphs[0]
    fp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    frun1 = fp.add_run("Stack & Scale Internship 2026  |  Final Project Submission")
    frun1.font.name = "Arial"
    frun1.font.size = Pt(8.5)
    frun1.font.color.rgb = COLOR_MUTED

    # ==========================================
    # COVER PAGE
    # ==========================================
    p_tag = doc.add_paragraph()
    p_tag.paragraph_format.space_before = Pt(72)
    p_tag.paragraph_format.space_after = Pt(12)
    r_tag = p_tag.add_run("STACK & SCALE INTERNSHIP 2026  |  FINAL PROJECT SUBMISSION")
    r_tag.font.name = "Arial"
    r_tag.font.size = Pt(10)
    r_tag.font.bold = True
    r_tag.font.color.rgb = COLOR_TEAL

    p_title = doc.add_paragraph()
    p_title.paragraph_format.space_before = Pt(0)
    p_title.paragraph_format.space_after = Pt(8)
    r_title = p_title.add_run("CareConnect")
    r_title.font.name = "Arial"
    r_title.font.size = Pt(36)
    r_title.font.bold = True
    r_title.font.color.rgb = COLOR_NAVY

    p_sub = doc.add_paragraph()
    p_sub.paragraph_format.space_before = Pt(0)
    p_sub.paragraph_format.space_after = Pt(28)
    r_sub = p_sub.add_run("Doctor Discovery, Clinical Appointment Booking & Persistent Reminders Application")
    r_sub.font.name = "Arial"
    r_sub.font.size = Pt(14)
    r_sub.font.color.rgb = COLOR_MUTED

    # Meta Information Table
    meta_tbl = doc.add_table(rows=6, cols=2)
    meta_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    meta_tbl.autofit = False
    
    meta_data = [
        ("Project Name", "CareConnect"),
        ("Internship Program", "Stack & Scale Flutter Internship 2026"),
        ("Project Duration", "Day 1 to Day 5 (5-Day Curriculum)"),
        ("Technology Stack", "Flutter & Dart (Riverpod, GoRouter, SQLite, Local Notifications)"),
        ("Quality Assurance Status", "117 / 117 Automated Tests Passed (100% Pass Rate), 0 Analyzer Issues"),
        ("Document Classification", "Weekly Final Project Documentation")
    ]

    for idx, (label, val) in enumerate(meta_data):
        row = meta_tbl.rows[idx]
        cell_lbl, cell_val = row.cells[0], row.cells[1]
        cell_lbl.width = Inches(2.2)
        cell_val.width = Inches(4.57)
        
        set_cell_background(cell_lbl, HEX_LIGHT_BG)
        set_cell_background(cell_val, HEX_LIGHT_BG)
        set_cell_margins(cell_lbl, top=80, bottom=80, left=100, right=100)
        set_cell_margins(cell_val, top=80, bottom=80, left=100, right=100)
        set_cell_borders(cell_lbl, top="single", bottom="single", left="none", right="none", color=HEX_BORDER, sz="4")
        set_cell_borders(cell_val, top="single", bottom="single", left="none", right="none", color=HEX_BORDER, sz="4")

        p_lbl = cell_lbl.paragraphs[0]
        p_lbl.paragraph_format.space_after = Pt(0)
        r_l = p_lbl.add_run(label)
        r_l.font.name = "Arial"
        r_l.font.size = Pt(9.5)
        r_l.font.bold = True
        r_l.font.color.rgb = COLOR_NAVY

        p_val = cell_val.paragraphs[0]
        p_val.paragraph_format.space_after = Pt(0)
        r_v = p_val.add_run(val)
        r_v.font.name = "Arial"
        r_v.font.size = Pt(9.5)
        r_v.font.color.rgb = COLOR_TEXT

    doc.add_page_break()

    # ==========================================
    # SECTION A: PROJECT TITLE, PURPOSE & OVERVIEW
    # ==========================================
    add_heading_1(doc, "A. Project Title, Purpose & Overview")
    
    add_body_p(doc, 
        "CareConnect is a production-quality clinic appointment booking and reminder application developed using Flutter and Dart. "
        "The project provides a modern, patient-first mobile experience engineered to address the complexities of modern outpatient healthcare scheduling, "
        "physician discovery, and clinical reminder tracking.",
        bold_prefix="Project Name: CareConnect. "
    )

    add_body_p(doc,
        "The primary purpose of CareConnect is to eliminate patient scheduling friction and bridge the communication gap between individuals and specialized healthcare providers. "
        "Traditional healthcare appointment systems often suffer from opaque physician credentials, cumbersome scheduling channels, lack of timely pre-visit reminders, and data vulnerability during offline mobile usage. "
        "CareConnect solves these clinical challenges by delivering an authoritative, reassuring, and privacy-respecting healthcare interface that empowers patients to manage consultations independently and securely.",
        bold_prefix="Application Purpose: "
    )

    add_body_p(doc,
        "CareConnect streamlines the patient journey through a cohesive multi-step workflow. Patients can explore specialized physicians across comprehensive clinical categories, "
        "inspect detailed physician profiles with transparent consultation fees and clinical metrics, search for doctors with real-time debounced query filtering, "
        "and select future consultation dates and available time slots. Confirmed bookings are immediately persisted to a local-first SQLite database, ensuring appointment records, "
        "past visit histories, and cancellation statuses survive device restarts and function seamlessly offline without depending on external cloud servers.",
        bold_prefix="Patient Discovery & Management: "
    )

    add_body_p(doc,
        "The application is structured upon a feature-first clean architecture separating the codebase into Domain, Data, and Presentation layers. "
        "Domain models and repository interfaces maintain strict business rules and defensive validation. "
        "The Data layer incorporates persistent SQLite storage via sqflite, demographic persistence via SharedPreferences, and high-importance local notification reminders via flutter_local_notifications. "
        "The Presentation layer employs Riverpod 2.x for declarative, reactive state management and GoRouter for deep-linked routing, wrapped within a custom healthcare visual system featuring Deep Navy (#0E1A2D), Sophisticated Teal (#0E7490), Warm Ivory (#FBFBFA), and Mint (#10B981).",
        bold_prefix="Architecture & Workflow: "
    )

    # ==========================================
    # SECTION B: DAY 1–DAY 5 PROGRESS EVIDENCE
    # ==========================================
    add_heading_1(doc, "B. Day 1–Day 5 Progress Evidence")

    # --- Day 1 ---
    add_heading_2(doc, "Day 1 — Doctor Discovery & Application Foundation")
    add_body_p(doc,
        "Day 1 established the application's foundational visual system, design token architecture, and core doctor discovery experience. "
        "The home screen was implemented with a dynamic clinic header, hero promotional card, horizontal specialty selector, featured specialist carousel, and physician directory. "
        "The doctor details view was created with a comprehensive 4-point clinical metrics bar, weekly working hours, clinical bio, and consultation fee sticky bar."
    )
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_1", "01_home_screen.png"),
        "Figure 1.1: Day 1 Home Doctor Discovery Screen with Header & Hero Banner",
        os.path.join(PROJECT_DIR, "evidence", "day_1", "03_doctor_detail_screen.png"),
        "Figure 1.2: Day 1 Doctor Details Profile with 4-Point Clinical Metrics Bar"
    )
    add_single_image(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_1", "04_booking_roadmap_modal.png"),
        "Figure 1.3: Day 1 Appointment Booking Roadmap Bottom Sheet",
        target_width=Inches(3.1)
    )

    # --- Day 2 ---
    add_heading_2(doc, "Day 2 — Search, Specialty Filters & Patient Profile")
    add_body_p(doc,
        "Day 2 integrated an asynchronous doctor repository pipeline with debounced real-time query searching and multi-attribute specialty filtering. "
        "A persistent local patient profile backed by SharedPreferences was developed, complete with an editable demographic form featuring client-side validation. "
        "Comprehensive asynchronous states were introduced, including pulse-animated loading shimmer skeletons, contextual empty search states, and resilient error retry views."
    )
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_2", "01_doctor_search_results.png"),
        "Figure 2.1: Day 2 Real-Time Debounced Doctor Search Results",
        os.path.join(PROJECT_DIR, "evidence", "day_2", "02_specialty_filter_results.png"),
        "Figure 2.2: Day 2 Multi-Specialty Category Filter Results"
    )
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_2", "03_patient_profile_screen.png"),
        "Figure 2.3: Day 2 Patient Clinical Profile & Identity Screen",
        os.path.join(PROJECT_DIR, "evidence", "day_2", "04_edit_patient_profile.png"),
        "Figure 2.4: Day 2 Demographic Form Editor with Input Validation"
    )
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_2", "05_doctor_loading_state.png"),
        "Figure 2.5: Day 2 Shimmer Pulse Loading Skeleton State",
        os.path.join(PROJECT_DIR, "evidence", "day_2", "06_doctor_error_state.png"),
        "Figure 2.6: Day 2 Resilient Error View with Retry Action"
    )

    # --- Day 3 ---
    add_heading_2(doc, "Day 3 — Appointment Booking & Scheduling")
    add_body_p(doc,
        "Day 3 implemented the complete clinical appointment scheduling journey, featuring an interactive 14-day horizontal calendar date strip and dynamic time-slot grid. "
        "A rigorous defensive booking validation matrix was engineered to prevent past-date selections, unavailable slots, and duplicate double-bookings. "
        "The flow culminated in an animated booking confirmation screen with digital receipt details and an initial appointment history list."
    )
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_3", "01_booking_screen.png"),
        "Figure 3.1: Day 3 Appointment Booking Screen with 14-Day Calendar",
        os.path.join(PROJECT_DIR, "evidence", "day_3", "03_available_time_slots.png"),
        "Figure 3.2: Day 3 Dynamic Morning, Afternoon & Evening Time Slots"
    )
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_3", "05_booking_confirmation.png"),
        "Figure 3.3: Day 3 Booking Confirmation Screen & Digital Receipt",
        os.path.join(PROJECT_DIR, "evidence", "day_3", "06_appointment_history.png"),
        "Figure 3.4: Day 3 Initial Appointment History Card Presentation"
    )
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_3", "07_booking_validation_error.png"),
        "Figure 3.5: Day 3 Past Date & Time Validation Error Notification",
        os.path.join(PROJECT_DIR, "evidence", "day_3", "08_booking_conflict.png"),
        "Figure 3.6: Day 3 Double-Booking Conflict Prevention Guard"
    )

    # --- Day 4 ---
    add_heading_2(doc, "Day 4 — Local Persistence, Cancellation & Reminders")
    add_body_p(doc,
        "Day 4 upgraded storage from transient mock data to a persistent SQLite database (sqflite) with version 2 schema migrations, ensuring records persist across restarts. "
        "Functional appointment cancellation was delivered with safety confirmation modals, immediate slot release, and reminder teardown, alongside atomic appointment rescheduling. "
        "Local notification reminders were implemented via flutter_local_notifications with 30-minute lead time calculations, test demo triggers, and offline resilience banners."
    )
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_4", "01_persistent_appointment_history.png"),
        "Figure 4.1: Day 4 Persistent Appointment History Screen (SQLite)",
        os.path.join(PROJECT_DIR, "evidence", "day_4", "02_appointment_after_restart.png"),
        "Figure 4.2: Day 4 Appointment State Preserved After Application Restart"
    )
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_4", "03_cancellation_confirmation.png"),
        "Figure 4.3: Day 4 Appointment Cancellation Confirmation Dialog",
        os.path.join(PROJECT_DIR, "evidence", "day_4", "04_cancelled_appointment.png"),
        "Figure 4.4: Day 4 Preserved Cancelled Record in Medical Audit History"
    )
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_4", "05_rescheduling_screen.png"),
        "Figure 4.5: Day 4 Appointment Rescheduling Date & Time Selector",
        os.path.join(PROJECT_DIR, "evidence", "day_4", "07_reminder_configuration.png"),
        "Figure 4.6: Day 4 Local Notification Reminder Configuration Sheet"
    )
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_4", "08_notification_demo.png"),
        "Figure 4.7: Day 4 Instant Demo Reminder Feedback Banner",
        os.path.join(PROJECT_DIR, "evidence", "day_4", "09_offline_state.png"),
        "Figure 4.8: Day 4 Offline-First Local Storage Persistence Banner"
    )

    # --- Day 5 ---
    add_heading_2(doc, "Day 5 — Final Testing, Quality Assurance & Documentation")
    add_body_p(doc,
        "Day 5 conducted exhaustive quality assurance, achieving 100% passing rate across all 117 automated unit and widget tests with 0 analyzer issues. "
        "Full responsive verification was completed on both standard (412 × 915) and small (360 × 800) phone screen sizes with zero RenderFlex overflow defects. "
        "Genuine final evidence artifacts were captured, the documentation suite was finalized, and project submission readiness was established."
    )
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_5", "01_home_doctor_discovery.png"),
        "Figure 5.1: Day 5 Final Doctor Discovery Dashboard (Standard 412x915)",
        os.path.join(PROJECT_DIR, "evidence", "day_5", "07_cancellation_and_rescheduling.png"),
        "Figure 5.2: Day 5 Reschedule Slot Review & Summary Card State"
    )
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_5", "09_responsive_small_360x800_home.png"),
        "Figure 5.3: Day 5 Responsive Verification: Small Phone Home (360x800)",
        os.path.join(PROJECT_DIR, "evidence", "day_5", "10_responsive_small_360x800_booking.png"),
        "Figure 5.4: Day 5 Responsive Verification: Small Phone Booking (360x800)"
    )
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_5", "11_responsive_small_360x800_history.png"),
        "Figure 5.5: Day 5 Responsive Verification: Small Phone History (360x800)",
        os.path.join(PROJECT_DIR, "evidence", "day_5", "12_responsive_small_360x800_reschedule.png"),
        "Figure 5.6: Day 5 Responsive Verification: Small Phone Rescheduling (360x800)"
    )

    # ==========================================
    # SECTION C: FINAL WEEKLY PROJECT OUTPUT
    # ==========================================
    add_heading_1(doc, "C. Final Weekly Project Output")
    add_body_p(doc,
        "The following gallery showcases genuine screenshots of the completed, verified CareConnect application operating in its final release state. "
        "All visual elements adhere strictly to the established clinical design system, ensuring visual comfort, clinical authority, and clear hierarchy."
    )

    add_heading_2(doc, "Core Clinical Discovery & Profile Screens")
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_5", "01_home_doctor_discovery.png"),
        "Figure C.1: Final Home Screen — Clinic Header, Hero Banner, Specialties & Doctors",
        os.path.join(PROJECT_DIR, "evidence", "day_5", "02_doctor_details.png"),
        "Figure C.2: Final Doctor Details Screen — Metrics, Bio, Modalities & Sticky Fee Bar"
    )

    add_heading_2(doc, "Search Filtering & Patient Profile Screens")
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_5", "03_search_specialty_filters.png"),
        "Figure C.3: Final Doctor Search Screen — Filtered by Specialty & Name Query",
        os.path.join(PROJECT_DIR, "evidence", "day_5", "08_patient_profile.png"),
        "Figure C.4: Final Patient Profile Screen — Clinical Demographics, MRN & Allergies"
    )

    add_heading_2(doc, "Appointment Booking & Confirmation Screens")
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_5", "04_appointment_booking.png"),
        "Figure C.5: Final Booking Screen — 14-Day Calendar Strip & Time Slot Grid",
        os.path.join(PROJECT_DIR, "evidence", "day_5", "05_booking_confirmation.png"),
        "Figure C.6: Final Confirmation Screen — Digital Receipt & Navigation CTAs"
    )

    add_heading_2(doc, "Persistent History & Appointment Management Screens")
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_5", "06_appointment_history.png"),
        "Figure C.7: Final Appointment History — Upcoming Confirmed Visit Cards with Actions",
        os.path.join(PROJECT_DIR, "evidence", "day_5", "07_cancellation_and_rescheduling.png"),
        "Figure C.8: Final Rescheduling Screen — Interactive Date/Slot Modification Interface"
    )

    add_heading_2(doc, "Responsive Small Phone Form Factor (360 × 800 Viewport)")
    add_image_pair(doc,
        os.path.join(PROJECT_DIR, "evidence", "day_5", "09_responsive_small_360x800_home.png"),
        "Figure C.9: Small Phone (360x800) Home Screen — Overflow-Free Responsive Layout",
        os.path.join(PROJECT_DIR, "evidence", "day_5", "11_responsive_small_360x800_history.png"),
        "Figure C.10: Small Phone (360x800) History Screen — Proportional Spacing & Touch Targets"
    )

    # ==========================================
    # SECTION D: COMPLETED FEATURES & DELIVERABLES
    # ==========================================
    add_heading_1(doc, "D. Completed Features & Deliverables")
    add_body_p(doc,
        "Every feature listed below has been fully implemented, integrated into the clean architecture layers, and verified through automated tests and manual inspections:"
    )

    features = [
        ("Doctor Discovery & Clinical Details: ", 
         "Displays specialized physicians categorized by department. Featured doctor horizontal carousel, comprehensive physician profiles with 4-point clinical metrics bar (Patients, Experience, Rating, Reviews), medical biography, weekly availability schedule, hospital facility, and consultation fee breakdown."),
        
        ("Doctor Search & Multi-Specialty Filtering: ", 
         "Real-time debounced query search across doctor names, subspecialties, and clinic facilities. Interactive horizontal category selector filtering across 8 medical specialties (Cardiology, Neurology, Pediatrics, Orthopedics, Dermatology, Psychiatry, General Medicine, and Ophthalmology)."),
        
        ("Patient Profile & Local Identity Management: ", 
         "Persistent patient identity backed by SharedPreferences with pre-seeded demo records. Manages full name, MRN, email, phone, date of birth, blood group, allergies, emergency contact, and preferred clinic facility. Includes a dedicated demographic editor with rigorous form validation."),
        
        ("Appointment Date & Time Selection: ", 
         "Interactive horizontal scrolling calendar displaying the next 14 available consultation days. Categorized Morning, Afternoon, and Evening time-slot grid with availability chips that adapt dynamically based on doctor schedules and existing bookings."),
        
        ("Booking Confirmation & Digital Receipt: ", 
         "Summary review card computing consultation fees and booking parameters prior to submission. Upon confirmation, generates a digital receipt card featuring unique Appointment ID, confirmed status badge, physician credentials, and GoRouter deep-link navigation."),
        
        ("Persistent Appointment History: ", 
         "Chronologically ordered consultation history partitioned into 'Upcoming' and 'Past' tabs. Renders elevated doctor cards with clinic details, scheduled timestamps, reminder badges, and quick-action buttons for rescheduling and cancellation."),
        
        ("Appointment Cancellation & Slot Release: ", 
         "Patient-initiated cancellation with explicit safety confirmation dialog to prevent accidental triggers. Updates persistent SQLite status to 'cancelled', preserves the record for medical audit trails, immediately releases the time slot for future bookings, and cancels the scheduled reminder."),
        
        ("Appointment Rescheduling & Atomic Slot Swap: ", 
         "Rescheduling workflow displaying current appointment summary banner and allowing selection of a new date and available slot. Atomically validates availability, swaps slot reservations, updates modified timestamps while preserving original ID and creation dates, and reschedules reminders."),
        
        ("SQLite Local-First Persistence: ", 
         "Production-ready sqflite database implementation (v2 schema) durably storing all appointments. Guarantees that bookings, reschedules, and cancellations remain intact after full application restarts without relying on transient memory or remote synchronization."),
        
        ("Offline Access & Source Handling: ", 
         "Local-first architecture ensuring all saved appointments, doctor profiles, and historical records remain fully operational offline. Features offline banner indicators, resilient error views with retry mechanisms, and zero false claims of cloud synchronization."),
        
        ("Appointment Reminder Functionality: ", 
         "Local notification reminders powered by flutter_local_notifications (v23.0.3). Configures high-importance Android notification channels, calculates 30-minute lead time exact alarms, and includes an in-app demo trigger to demonstrate instantaneous alert delivery."),
        
        ("Defensive Booking Validation Matrix: ", 
         "Multi-tier validation preventing booking in past dates or elapsed times on the current day, rejecting duplicate bookings for the same patient/doctor slot, and enforcing slot lockouts during scheduling conflicts."),
        
        ("Responsive Multi-Screen UI: ", 
         "Fluid responsive layout adapting seamlessly across small phone viewports (360 × 800) and standard modern devices (412 × 915). Text wrapping with ellipsis, flexible containers, and touch-target padding prevent RenderFlex overflows."),
        
        ("Automated Quality Assurance & Testing: ", 
         "117 automated unit and widget tests achieving a 100% pass rate. Verified with 0 static analysis issues across all 82 project source files.")
    ]

    for title, desc in features:
        add_bullet_p(doc, desc, bold_prefix=title)

    # ==========================================
    # SECTION E: MAIN APPLICATION FLOW
    # ==========================================
    add_heading_1(doc, "E. Main Application Flow")
    add_body_p(doc,
        "The CareConnect patient journey follows a logical, frictionless, 9-stage workflow that guides the patient from initial discovery to persistent appointment management:"
    )

    journey_steps = [
        ("Step 1: Open CareConnect & Experience Brand Identity",
         "The patient launches the application into the Doctor Discovery dashboard (/home). "
         "The personalized header greets the patient by name, displays their avatar initials, and introduces the hero promotional banner. "
         "The patient immediately observes available clinical departments and spotlighted specialists.",
         os.path.join(PROJECT_DIR, "evidence", "day_5", "01_home_doctor_discovery.png"),
         "Figure E.1: Launching CareConnect — Home Doctor Discovery Dashboard"),

        ("Step 2: Explore Specialties & Specialty Categories",
         "The patient browses through the horizontal specialty selector. Tapping a category chip (such as Cardiology, Neurology, or Pediatrics) "
         "instantly filters the directory to physicians practicing in that medical discipline with zero lag.",
         os.path.join(PROJECT_DIR, "evidence", "day_2", "02_specialty_filter_results.png"),
         "Figure E.2: Filtering Directory by Medical Specialty (Cardiology)"),

        ("Step 3: Search Doctors with Real-Time Debounce",
         "To locate a specific physician or clinic location, the patient types into the search bar. "
         "A 250ms debouncer prevents UI stutter while filtering across physician names, subspecialties, and clinic addresses.",
         os.path.join(PROJECT_DIR, "evidence", "day_2", "01_doctor_search_results.png"),
         "Figure E.3: Real-Time Debounced Doctor Search Input"),

        ("Step 4: Open Detailed Physician Clinical Profile",
         "Selecting a physician card navigates to the Doctor Detail Screen (/doctors/:id). "
         "The patient reviews the 4-point clinical metrics bar (Patients, Experience, Rating, Reviews), reads the professional biography, "
         "verifies hospital affiliations, checks weekly working hours, and inspects the consultation fee before proceeding.",
         os.path.join(PROJECT_DIR, "evidence", "day_5", "02_doctor_details.png"),
         "Figure E.4: Detailed Physician Profile & Clinical Metrics"),

        ("Step 5: Select Consultation Date & Time Slot",
         "The patient taps 'Book Appointment' to open the Booking Screen (/booking/:doctorId). "
         "An interactive 14-day calendar strip displays available days. Selecting a day dynamically populates the Morning, Afternoon, "
         "and Evening time-slot grid. The patient taps their preferred slot and reviews the summary card computing total fees.",
         os.path.join(PROJECT_DIR, "evidence", "day_5", "04_appointment_booking.png"),
         "Figure E.5: 14-Day Calendar Date & Time Slot Selection"),

        ("Step 6: Confirm Appointment & Receive Digital Receipt",
         "The patient taps 'Confirm Booking'. The system executes defensive validation checks against the SQLite database to confirm slot availability. "
         "Upon success, the Booking Confirmation Screen (/booking/confirmation) generates a verified digital receipt card with a unique Appointment ID.",
         os.path.join(PROJECT_DIR, "evidence", "day_5", "05_booking_confirmation.png"),
         "Figure E.6: Digital Appointment Confirmation Receipt"),

        ("Step 7: View Persistent Appointment History",
         "The patient navigates to the Appointment History Screen (/appointments). "
         "All active bookings appear under the 'Upcoming' tab with doctor details, consultation fees, and reminder active indicators. "
         "The patient can switch tabs to inspect previous consultations.",
         os.path.join(PROJECT_DIR, "evidence", "day_5", "06_appointment_history.png"),
         "Figure E.7: Persistent Appointment History Screen"),

        ("Step 8: Cancel or Reschedule Appointments with Slot Sync",
         "If schedule changes occur, the patient taps 'Reschedule' to select a new date/time slot with atomic slot swapping, "
         "or taps 'Cancel Visit' to open a confirmation dialog. Confirming cancellation soft-deletes the record to 'cancelled', "
         "instantly releases the slot for other patients, and cancels the local notification reminder.",
         os.path.join(PROJECT_DIR, "evidence", "day_4", "03_cancellation_confirmation.png"),
         "Figure E.8: Appointment Cancellation Confirmation Dialog"),

        ("Step 9: Reopen Application & Verify Data Durability",
         "When the patient terminates and relaunches CareConnect, all confirmed appointments, rescheduled timings, and cancelled statuses "
         "load immediately from the local SQLite database. Local notification exact alarms remain scheduled on device without data loss.",
         os.path.join(PROJECT_DIR, "evidence", "day_4", "02_appointment_after_restart.png"),
         "Figure E.9: Appointment State Retained Across Application Restarts")
    ]

    for step_title, step_desc, img_path, img_caption in journey_steps:
        add_heading_2(doc, step_title)
        add_body_p(doc, step_desc)
        add_single_image(doc, img_path, img_caption, target_width=Inches(3.1))

    # ==========================================
    # SECTION F: WEEKLY LEARNING OUTCOMES
    # ==========================================
    add_heading_1(doc, "F. Weekly Learning Outcomes")
    add_body_p(doc,
        "The 5-day CareConnect internship curriculum provided immersive, hands-on engineering experience spanning the complete modern mobile application development lifecycle. "
        "The following core technical competencies and practical software engineering methodologies were acquired and demonstrated:"
    )

    outcomes = [
        ("Advanced Flutter & Modern Dart: ",
         "Mastered sound null safety, immutable data structures, factory constructors, mixins, custom typographic scales, and design token architectures. Developed deep proficiency in building custom tactile widgets without relying on generic pre-packaged templates."),
        
        ("Reactive State Management with Riverpod: ",
         "Acquired comprehensive experience with Riverpod 2.x, utilizing FutureProvider, AsyncNotifier, StateProvider, and Family providers. Gained mastery in provider lifecycle scoping, caching, invalidation patterns, and debounced state mutations."),
        
        ("Declarative Routing & Deep Linking with GoRouter: ",
         "Implemented robust declarative navigation using GoRouter, handling path parameters, query parameters, custom transition animations, fallback error routing, and programmatic navigation stacks."),
        
        ("Local-First SQLite Database Engineering: ",
         "Engineered a production-ready SQLite database via sqflite and sqflite_common_ffi. Implemented schema version migrations, CRUD operations, atomic slot-swap transactions, soft-deletion audit patterns, and desktop/test in-memory isolate fallbacks."),
        
        ("Mobile Device Services & Notification Management: ",
         "Configured native Android notification channels with high-importance priority, vibration patterns, and exact-alarm scheduling via flutter_local_notifications. Mastered lead-time calculations, permission request flows, and deterministic notification ID hashing."),
        
        ("Defensive System Architecture & Input Validation: ",
         "Designed multi-tier validation matrices to prevent invalid booking states, past-date selections, conflicting doctor appointments, and duplicate records, decoupling validation logic from widgets into domain and repository contracts."),
        
        ("Fluid Responsive Layout Engineering: ",
         "Developed responsive mobile layouts capable of adapting between small form factors (360 × 800) and standard modern viewports (412 × 915). Mastered layout constraints, SingleChildScrollView hierarchies, Expanded/Flexible text boundaries, and zero-overflow defensive design."),
        
        ("Multi-Tier Automated Testing & Quality Assurance: ",
         "Authored and maintained a comprehensive 117-test automated test suite spanning unit tests, repository mocks, isolate test harnesses, and widget pump tests. Gained expertise in isolating native FFI method channels in headless test environments and achieving clean static analysis."),
        
        ("Professional Engineering Documentation: ",
         "Acquired executive-level technical reporting discipline, producing comprehensive architectural guides, testing audits, and verified milestone documentation that transparently distinguish completed, verified, and environment-constrained deliverables.")
    ]

    for title, desc in outcomes:
        add_bullet_p(doc, desc, bold_prefix=title)

    # Save Document
    doc.save(OUTPUT_DOCX)
    print(f"\nSuccessfully generated document: {OUTPUT_DOCX}")
    stat = os.stat(OUTPUT_DOCX)
    print(f"File size: {stat.st_size / (1024 * 1024):.2f} MB ({stat.st_size} bytes)")

if __name__ == "__main__":
    build_document()
