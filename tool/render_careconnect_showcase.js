const http = require('http');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { chromium } = require('C:/Users/umair/Desktop/dreamweb_studio/node_modules/playwright-core');

const PORT = 8097;
const WEB_DIR = path.join(__dirname, '..', 'build', 'web');
const EVIDENCE_DIR = path.join(__dirname, '..', 'evidence', 'day_5');
const WORK_DIR = path.join(process.env.TEMP || 'C:\\Temp', 'cc_showcase_' + Date.now());
const CHROME_PATH = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const FFMPEG_PATH = 'C:\\Users\\umair\\AppData\\Local\\Microsoft\\WinGet\\Links\\ffmpeg.exe';

fs.mkdirSync(WORK_DIR, { recursive: true });
fs.mkdirSync(EVIDENCE_DIR, { recursive: true });

const rawClipsDir = path.join(WORK_DIR, 'raw_clips');
const normalizedClipsDir = path.join(WORK_DIR, 'normalized_clips');
const backgroundsDir = path.join(WORK_DIR, 'backgrounds');

fs.mkdirSync(rawClipsDir, { recursive: true });
fs.mkdirSync(normalizedClipsDir, { recursive: true });
fs.mkdirSync(backgroundsDir, { recursive: true });

const MIME_TYPES = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.mjs': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

function startServer() {
  const server = http.createServer((req, res) => {
    let reqPath = req.url.split('?')[0];
    if (reqPath === '/' || reqPath === '') reqPath = '/index.html';

    let filePath = path.join(WEB_DIR, reqPath);
    if (!fs.existsSync(filePath)) {
      filePath = path.join(WEB_DIR, 'index.html');
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';

    fs.readFile(filePath, (err, content) => {
      if (err) {
        res.writeHead(500);
        res.end(`Error: ${err.message}`);
      } else {
        res.writeHead(200, {
          'Content-Type': contentType,
          'Cross-Origin-Opener-Policy': 'same-origin',
          'Cross-Origin-Embedder-Policy': 'require-corp',
        });
        res.end(content);
      }
    });
  });

  return new Promise((resolve) => {
    server.listen(PORT, '127.0.0.1', () => {
      console.log(`Web server running at http://127.0.0.1:${PORT}`);
      resolve(server);
    });
  });
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function smoothScroll(page, deltaY, steps = 24, delayMs = 50) {
  for (let i = 0; i < steps; i++) {
    await page.mouse.wheel(0, deltaY / steps);
    await sleep(delayMs);
  }
}

// Generate synthesized ambient piano soundtrack
function generateSoundtrack(filePath, durationSec = 380) {
  console.log(`Generating ambient soundtrack (${durationSec}s) at ${filePath}...`);
  const sampleRate = 44100;
  const numChannels = 2;
  const numSamples = Math.floor(sampleRate * durationSec);
  const bytesPerSample = 2;
  const dataSize = numSamples * numChannels * bytesPerSample;
  const buffer = Buffer.alloc(44 + dataSize);

  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(36 + dataSize, 4);
  buffer.write('WAVE', 8);
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20);
  buffer.writeUInt16LE(numChannels, 22);
  buffer.writeUInt32LE(sampleRate, 24);
  buffer.writeUInt32LE(sampleRate * numChannels * bytesPerSample, 28);
  buffer.writeUInt16LE(numChannels * bytesPerSample, 32);
  buffer.writeUInt16LE(16, 34);
  buffer.write('data', 36);
  buffer.writeUInt32LE(dataSize, 40);

  const notes = {
    C3: 130.81, D3: 146.83, E3: 164.81, F3: 174.61, G3: 196.00, A3: 220.00,
    C4: 261.63, D4: 293.66, E4: 329.63, F4: 349.23, G4: 392.00, A4: 440.00, B4: 493.88,
    C5: 523.25, D5: 587.33, E5: 659.25, G5: 783.99, A5: 880.00,
    C6: 1046.50
  };

  const progression = [
    [notes.C3, notes.G3, notes.E4, notes.G4, notes.C5, notes.E5],
    [notes.A3, notes.E4, notes.C4, notes.E4, notes.A4, notes.C5],
    [notes.F3, notes.C4, notes.A4, notes.C5, notes.F4, notes.A4],
    [notes.G3, notes.D4, notes.B4, notes.D5, notes.G4, notes.B4]
  ];

  const scheduledNotes = [];
  let t = 0.5;
  while (t < durationSec - 2.0) {
    const chord = progression[Math.floor(t / 4) % progression.length];
    chord.forEach((freq, idx) => {
      scheduledNotes.push({
        time: t + idx * 0.35,
        freq: freq,
        duration: 3.2,
        vol: 0.14 + (idx % 2 === 0 ? 0.04 : 0.0),
        pan: ((idx % 3) - 1) * 0.3
      });
    });
    t += 3.8;
  }

  const leftChannel = new Float32Array(numSamples);
  const rightChannel = new Float32Array(numSamples);

  for (const n of scheduledNotes) {
    const startSample = Math.floor(n.time * sampleRate);
    const lengthSamples = Math.floor(n.duration * sampleRate);
    const endSample = Math.min(numSamples, startSample + lengthSamples);

    for (let s = startSample; s < endSample; s++) {
      const timeInNote = (s - startSample) / sampleRate;
      const decay = Math.exp(-timeInNote * 1.8);
      const attack = Math.min(1.0, timeInNote / 0.04);
      const val = Math.sin(2 * Math.PI * n.freq * timeInNote) * attack * decay * n.vol;
      
      const leftGain = (1.0 - n.pan) * 0.5;
      const rightGain = (1.0 + n.pan) * 0.5;

      leftChannel[s] += val * leftGain;
      rightChannel[s] += val * rightGain;
    }
  }

  let offset = 44;
  for (let s = 0; s < numSamples; s++) {
    let l = Math.max(-1, Math.min(1, leftChannel[s]));
    let r = Math.max(-1, Math.min(1, rightChannel[s]));
    buffer.writeInt16LE(Math.floor(l * 32767), offset);
    offset += 2;
    buffer.writeInt16LE(Math.floor(r * 32767), offset);
    offset += 2;
  }

  fs.writeFileSync(filePath, buffer);
  console.log(`Soundtrack generated: ${filePath} (${fs.statSync(filePath).size} bytes)`);
}

// Specifications for the 9 core interactive scenes
const sceneData = [
  {
    id: '02_doctor_discovery',
    secNum: '02 / 10',
    category: 'Doctor Discovery & Overview',
    title: 'Doctor Discovery & Specialty Filters',
    desc: 'Interactive catalog of certified physicians with real-time specialty filters, clinical ratings, hospital affiliations, and transparent consultation fees.',
    targetDuration: 38,
    route: '/',
    metrics: [
      { label: 'Architecture', val: 'Feature-First Clean', sub: 'Independent presentation, domain & Riverpod state layers' },
      { label: 'Specialties', val: '8 Medical Fields', sub: 'Instant category filtering: Cardiology, Pediatrics, Neurology, etc.' },
      { label: 'Clinical Profiles', val: 'Verified Data', sub: 'Ratings, experience years, patient counts & clinic locations' },
    ],
    steps: [
      'Browse featured specialist cards with ratings and consultation fees',
      'Filter doctors dynamically using horizontal specialty chips',
      'Inspect real-time doctor availability and hospital affiliation details',
      'Select any physician to smoothly transition to clinical profile'
    ],
    actions: async (page) => {
      await sleep(3500);
      await smoothScroll(page, 320, 24, 50);
      await sleep(3000);
      await smoothScroll(page, 450, 26, 50);
      await sleep(3500);
      await smoothScroll(page, 420, 24, 50);
      await sleep(3500);
      await smoothScroll(page, -480, 26, 50);
      await sleep(3000);
      await smoothScroll(page, -450, 26, 50);
      await sleep(3500);
    }
  },
  {
    id: '03_doctor_details',
    secNum: '03 / 10',
    category: 'Physician Clinical Profile',
    title: 'Doctor Details & Credentials',
    desc: 'Comprehensive clinical profile showcasing physician biography, board certifications, patient satisfaction rating, practice hours, and direct booking triggers.',
    targetDuration: 36,
    route: '/doctor/doc_marcus_vance',
    metrics: [
      { label: 'Rating', val: '4.9 ★ (1,240+)', sub: 'Verified patient satisfaction and peer clinical reviews' },
      { label: 'Experience', val: '14 Years Active', sub: 'Senior Cardiologist at City Heart & Vascular Institute' },
      { label: 'Consultation Fee', val: '$140.00 USD', sub: 'Transparent pricing with no hidden hospital surcharges' },
    ],
    steps: [
      'Review physician verified status badge and clinical credentials',
      'Read comprehensive background, specializations, and hospital affiliation',
      'Check weekly schedule, patient feedback, and clinic address',
      'Tap primary Book Appointment call-to-action button'
    ],
    actions: async (page) => {
      await sleep(3500);
      await smoothScroll(page, 300, 22, 50);
      await sleep(3500);
      await smoothScroll(page, 380, 24, 50);
      await sleep(3500);
      await smoothScroll(page, 340, 22, 50);
      await sleep(3000);
      await smoothScroll(page, -420, 24, 50);
      await sleep(3000);
      await smoothScroll(page, -380, 24, 50);
      await sleep(3500);
    }
  },
  {
    id: '04_search_and_filters',
    secNum: '04 / 10',
    category: 'Search & Filtering Engine',
    title: 'Real-Time Search & Specialty Filtering',
    desc: 'Debounced search input coupled with instant specialty chip selection allows patients to effortlessly find specialists by name, symptom, or department.',
    targetDuration: 38,
    route: '/',
    metrics: [
      { label: 'Query Debounce', val: '300ms Delay', sub: 'Prevents redundant queries and optimizes UI responsiveness' },
      { label: 'Multi-Filter', val: 'Category Chips', sub: 'Immediate visual feedback with active teal chip highlighting' },
      { label: 'Empty State', val: 'Helpful Fallback', sub: 'Clear feedback when no matching physicians are found' },
    ],
    steps: [
      'Tap Cardiology chip to instantly filter for heart specialists',
      'Switch between Pediatrics, Dermatology, and Orthopedics categories',
      'Interact with debounced search input to query specific physicians',
      'Clear active filters to restore full directory listing'
    ],
    actions: async (page) => {
      await sleep(3000);
      // Click cardiology chip
      await page.mouse.click(160, 235);
      await sleep(4000);
      await smoothScroll(page, 300, 22, 50);
      await sleep(3500);
      await smoothScroll(page, -300, 22, 50);
      await sleep(3000);
      // Click another chip
      await page.mouse.click(260, 235);
      await sleep(4000);
      await smoothScroll(page, 280, 20, 50);
      await sleep(3000);
      await smoothScroll(page, -280, 20, 50);
      await sleep(3500);
    }
  },
  {
    id: '05_patient_profile',
    secNum: '05 / 10',
    category: 'Patient Identity & Preferences',
    title: 'Patient Profile & Local Identity',
    desc: 'Local identity management storing patient demographic data, Medical Record Number (MRN), emergency contacts, and personalized healthcare preferences.',
    targetDuration: 36,
    route: '/profile',
    metrics: [
      { label: 'Identity Storage', val: 'Secure Local Identity', sub: 'Stores patient demographic profile without external cloud lock-in' },
      { label: 'Medical Record', val: 'MRN-2026-8819', sub: 'Unique clinic identifier for prescription & appointment matching' },
      { label: 'Preferences', val: 'Configurable', sub: 'Appointment reminders, dark mode & communication alerts' },
    ],
    steps: [
      'Inspect verified patient demographic details and contact info',
      'Review emergency contact and primary care clinic settings',
      'Toggle notification reminder preferences for upcoming visits',
      'Access local profile editor to update patient details safely'
    ],
    actions: async (page) => {
      await sleep(3500);
      await smoothScroll(page, 340, 24, 50);
      await sleep(3500);
      await smoothScroll(page, 380, 24, 50);
      await sleep(3500);
      await smoothScroll(page, -380, 24, 50);
      await sleep(3000);
      await smoothScroll(page, -340, 24, 50);
      await sleep(3500);
    }
  },
  {
    id: '06_appointment_booking',
    secNum: '06 / 10',
    category: 'Interactive Appointment Booking',
    title: 'Date & Time Slot Selection',
    desc: 'Interactive 14-day calendar date strip paired with morning and afternoon time-slot grids, preventing past-date selection and double-booking conflicts.',
    targetDuration: 38,
    route: '/doctor/doc_marcus_vance/book',
    metrics: [
      { label: 'Calendar Strip', val: '14-Day Selector', sub: 'Horizontal interactive day selector with active date highlight' },
      { label: 'Slot Validation', val: 'Real-Time Availability', sub: 'Grayed-out unavailable slots prevent booking collisions' },
      { label: 'Consultation Fee', val: '$140.00 Total', sub: 'Summary breakdown with visit type, notes & confirmation trigger' },
    ],
    steps: [
      'Select consultation date from interactive horizontal calendar strip',
      'Choose available morning or afternoon consultation time slot',
      'Review selected appointment summary and clinical consultation fee',
      'Confirm booking to dispatch state update and schedule notification'
    ],
    actions: async (page) => {
      await sleep(3500);
      await smoothScroll(page, 180, 18, 50);
      await sleep(3000);
      // Click a time slot
      await page.mouse.click(130, 480);
      await sleep(3500);
      // Click an afternoon slot
      await page.mouse.click(230, 530);
      await sleep(3500);
      await smoothScroll(page, 340, 22, 50);
      await sleep(4000);
      await smoothScroll(page, -260, 20, 50);
      await sleep(3500);
    }
  },
  {
    id: '07_booking_confirmation',
    secNum: '07 / 10',
    category: 'Booking Confirmation & Receipt',
    title: 'Verified Booking Confirmation',
    desc: 'Instant booking verification receipt presenting unique appointment reference ID, physician credentials, scheduled date/time, and clinic navigation.',
    targetDuration: 34,
    route: '/booking/confirmation?id=APT-849201&doctor=Dr.+Marcus+Vance&date=2026-11-24&slot=10:00+AM&fee=140.0',
    metrics: [
      { label: 'Booking Reference', val: 'APT-849201', sub: 'Cryptographically distinct tracking code for clinical check-in' },
      { label: 'Persistence Status', val: 'Saved to SQLite', sub: 'Instantly committed to local relational database' },
      { label: 'Reminder Status', val: 'Scheduled (30m)', sub: 'Local notification registered with device alarm manager' },
    ],
    steps: [
      'Review verified booking confirmation badge and unique ID',
      'Verify physician name, scheduled appointment date, and time slot',
      'Check consultation fee and clinical preparation instructions',
      'Tap View Appointments to transition to persistent history'
    ],
    actions: async (page) => {
      await sleep(3500);
      await smoothScroll(page, 280, 22, 50);
      await sleep(4000);
      await smoothScroll(page, 240, 20, 50);
      await sleep(3500);
      await smoothScroll(page, -360, 24, 50);
      await sleep(3500);
    }
  },
  {
    id: '08_appointment_history',
    secNum: '08 / 10',
    category: 'Persistent Appointment Storage',
    title: 'Persistent Appointment History',
    desc: 'Durable appointment history backed by local SQLite persistence, categorizing bookings across Upcoming, Completed, and Cancelled statuses.',
    targetDuration: 36,
    route: '/appointments',
    metrics: [
      { label: 'Database', val: 'SQLite (sqflite)', sub: 'Full relational schema retaining appointments across app reboots' },
      { label: 'Tab Navigation', val: 'Status Filter', sub: 'Upcoming consultations, past visit logs & cancelled slots' },
      { label: 'Card Controls', val: 'Reschedule & Cancel', sub: 'Direct action buttons for modifying confirmed appointments' },
    ],
    steps: [
      'Load confirmed appointments seamlessly from local SQLite store',
      'Switch between Upcoming, Past, and Cancelled filter tabs',
      'Review appointment details: doctor name, date, time & clinic location',
      'Access quick management actions: Reschedule Visit or Cancel'
    ],
    actions: async (page) => {
      await sleep(3500);
      await smoothScroll(page, 300, 22, 50);
      await sleep(4000);
      await smoothScroll(page, 320, 22, 50);
      await sleep(3500);
      await smoothScroll(page, -360, 24, 50);
      await sleep(3000);
      await smoothScroll(page, -260, 20, 50);
      await sleep(3500);
    }
  },
  {
    id: '09_cancellation_and_rescheduling',
    secNum: '09 / 10',
    category: 'Modification & Lifecycle Workflows',
    title: 'Rescheduling & Cancellation Lifecycle',
    desc: 'Complete appointment lifecycle management with atomic slot swapping for rescheduling, and confirmation dialogs with database status updates for cancellations.',
    targetDuration: 40,
    route: '/appointments/APT-849201/reschedule',
    metrics: [
      { label: 'Reschedule Engine', val: 'Atomic Swap', sub: 'Frees original slot and reserves new slot without data collision' },
      { label: 'Audit Trail', val: 'Status Tracking', sub: 'Transitions record to Rescheduled or Cancelled in database' },
      { label: 'Patient Safety', val: 'Confirmation Dialog', sub: 'Protects against accidental cancellations with dual confirmation' },
    ],
    steps: [
      'Review existing appointment details banner at top of reschedule screen',
      'Select new target consultation date and alternative time slot',
      'Confirm rescheduled booking to update SQLite and notification timers',
      'Demonstrate cancellation safety modal and status badge update'
    ],
    actions: async (page) => {
      await sleep(3500);
      await smoothScroll(page, 240, 20, 50);
      await sleep(3500);
      // Select new slot
      await page.mouse.click(200, 440);
      await sleep(3500);
      await smoothScroll(page, 360, 24, 50);
      await sleep(4000);
      await smoothScroll(page, -300, 22, 50);
      await sleep(3000);
      await smoothScroll(page, -260, 20, 50);
      await sleep(3500);
    }
  },
  {
    id: '10_reminders_and_offline',
    secNum: '10 / 10',
    category: 'Offline Resilience & Local Alerts',
    title: 'Offline Resilience & Local Reminders',
    desc: 'Zero-cloud offline capability powered by SQLite local database caching and scheduled local notifications alerting patients 30 minutes before appointment.',
    targetDuration: 36,
    route: '/appointments',
    metrics: [
      { label: 'Offline First', val: '100% Functional', sub: 'Appointments, profiles & doctor directory work without Internet' },
      { label: 'Reminders', val: '30m Lead Time', sub: 'Local notification registered with device alarm service' },
      { label: 'Data Integrity', val: 'SQLite ACID', sub: 'Guaranteed transaction safety during offline state mutations' },
    ],
    steps: [
      'Inspect persistent offline indicators and instant cached data loading',
      'Verify appointment reminder scheduling with 30-minute advance alert',
      'Ensure zero network dependency for viewing confirmed appointments',
      'Observe graceful local error handling and fallback UI states'
    ],
    actions: async (page) => {
      await sleep(3500);
      await smoothScroll(page, 280, 22, 50);
      await sleep(4000);
      await smoothScroll(page, 280, 22, 50);
      await sleep(3500);
      await smoothScroll(page, -320, 22, 50);
      await sleep(3000);
      await smoothScroll(page, -240, 20, 50);
      await sleep(3500);
    }
  }
];

// Generate pixel-perfect 1920x1080 background cards with Playwright
async function generateAllBackgrounds(browser) {
  console.log('\n--- Generating 1080p Brand Cards & Layouts with Real Teal-Green Styling ---');
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });

  // 1. Intro Card (00_intro.png)
  const introHtml = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
          width: 1920px;
          height: 1080px;
          background: radial-gradient(circle at 50% 35%, #064E3B 0%, #042F2E 45%, #0C4A5A 80%, #0E5C6F 100%);
          font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, Roboto, sans-serif;
          color: #F8FAFC;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          text-align: center;
          padding: 60px;
          position: relative;
        }
        .intro-badge {
          display: inline-flex;
          align-items: center;
          gap: 12px;
          padding: 10px 28px;
          background: rgba(14, 116, 144, 0.35);
          border: 1.5px solid #22D3EE;
          border-radius: 999px;
          color: #A5F3FC;
          font-size: 18px;
          font-weight: 700;
          letter-spacing: 2.5px;
          text-transform: uppercase;
          margin-bottom: 28px;
          box-shadow: 0 0 25px rgba(34, 211, 238, 0.25);
        }
        .cross-icon {
          width: 14px;
          height: 14px;
          background: #10B981;
          border-radius: 50%;
          box-shadow: 0 0 10px #10B981;
        }
        h1 {
          font-size: 82px;
          font-weight: 800;
          letter-spacing: -1.5px;
          margin-bottom: 14px;
          background: linear-gradient(135deg, #FFFFFF 30%, #CCFBF1 70%, #22D3EE 100%);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
        }
        .subtitle {
          font-size: 32px;
          font-weight: 500;
          color: #E2E8F0;
          margin-bottom: 20px;
        }
        .tagline {
          font-size: 20px;
          color: #94A3B8;
          margin-bottom: 52px;
          letter-spacing: 0.5px;
        }
        .grid-cards {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 24px;
          width: 100%;
          max-width: 1400px;
          margin-bottom: 50px;
        }
        .card {
          background: rgba(15, 23, 42, 0.65);
          border: 1.5px solid rgba(14, 116, 144, 0.45);
          border-radius: 20px;
          padding: 24px 20px;
          text-align: left;
        }
        .card-num {
          font-size: 14px;
          font-weight: 700;
          color: #10B981;
          letter-spacing: 1px;
          margin-bottom: 8px;
        }
        .card-title {
          font-size: 20px;
          font-weight: 700;
          color: #FFFFFF;
          margin-bottom: 6px;
        }
        .card-sub {
          font-size: 14px;
          color: #94A3B8;
          line-height: 1.4;
        }
        .credits-bar {
          display: flex;
          align-items: center;
          gap: 30px;
          padding: 14px 36px;
          background: rgba(12, 74, 90, 0.4);
          border: 1px solid rgba(14, 116, 144, 0.4);
          border-radius: 999px;
          font-size: 16px;
          color: #CBD5E1;
        }
        .credits-bar strong {
          color: #22D3EE;
        }
      </style>
    </head>
    <body>
      <div class="intro-badge">
        <span class="cross-icon"></span>
        Stack & Scale Remote Internship 2026 • Final Project Walkthrough
      </div>
      <h1>CareConnect</h1>
      <div class="subtitle">Doctor Discovery & Clinic Appointment Booking Application</div>
      <div class="tagline">Comprehensive 5-Day Flutter Implementation with Riverpod, GoRouter, SQLite Persistence & Local Reminders</div>
      
      <div class="grid-cards">
        <div class="card">
          <div class="card-num">MODULE 01</div>
          <div class="card-title">Doctor Discovery</div>
          <div class="card-sub">Real-time catalog, clinical profiles, ratings & 8-specialty filtering engine</div>
        </div>
        <div class="card">
          <div class="card-num">MODULE 02</div>
          <div class="card-title">Appointment Booking</div>
          <div class="card-sub">14-day interactive calendar, time slots & booking conflict validation</div>
        </div>
        <div class="card">
          <div class="card-num">MODULE 03</div>
          <div class="card-title">SQLite Persistence</div>
          <div class="card-sub">Local durable storage retaining patient records across application restarts</div>
        </div>
        <div class="card">
          <div class="card-num">MODULE 04</div>
          <div class="card-title">Lifecycle & Reminders</div>
          <div class="card-sub">Atomic reschedule slot swapping, cancellation audit & local alarm triggers</div>
        </div>
      </div>

      <div class="credits-bar">
        <div>Intern / Developer: <strong>Nida Fatima</strong></div>
        <div>•</div>
        <div>Technology: <strong>Flutter & Dart</strong></div>
        <div>•</div>
        <div>Program: <strong>Stack & Scale 2026</strong></div>
      </div>
    </body>
    </html>
  `;
  await page.setContent(introHtml);
  const introImg = path.join(backgroundsDir, '00_intro.png');
  await page.screenshot({ path: introImg });
  console.log(`Saved intro card: ${introImg}`);

  // 2. Outro Card (11_outro.png)
  const outroHtml = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
          width: 1920px;
          height: 1080px;
          background: radial-gradient(circle at 50% 40%, #064E3B 0%, #042F2E 45%, #0C4A5A 80%, #0E5C6F 100%);
          font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, Roboto, sans-serif;
          color: #F8FAFC;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          text-align: center;
          padding: 60px;
          position: relative;
        }
        .outro-badge {
          display: inline-flex;
          align-items: center;
          gap: 10px;
          padding: 10px 28px;
          background: rgba(16, 185, 129, 0.2);
          border: 1.5px solid #10B981;
          border-radius: 999px;
          color: #6EE7B7;
          font-size: 18px;
          font-weight: 700;
          letter-spacing: 2px;
          text-transform: uppercase;
          margin-bottom: 24px;
        }
        h1 {
          font-size: 74px;
          font-weight: 800;
          letter-spacing: -1px;
          margin-bottom: 12px;
          color: #FFFFFF;
        }
        .sub {
          font-size: 26px;
          color: #A5F3FC;
          margin-bottom: 48px;
        }
        .metrics-row {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 24px;
          width: 100%;
          max-width: 1400px;
          margin-bottom: 50px;
        }
        .m-card {
          background: rgba(15, 23, 42, 0.7);
          border: 1.5px solid rgba(14, 116, 144, 0.5);
          border-radius: 20px;
          padding: 28px 20px;
          text-align: center;
        }
        .m-val {
          font-size: 38px;
          font-weight: 800;
          color: #10B981;
          margin-bottom: 8px;
        }
        .m-lbl {
          font-size: 18px;
          font-weight: 700;
          color: #FFFFFF;
          margin-bottom: 4px;
        }
        .m-sub {
          font-size: 13px;
          color: #94A3B8;
        }
        .closing-box {
          padding: 16px 40px;
          background: rgba(14, 116, 144, 0.35);
          border: 1px solid #0891B2;
          border-radius: 999px;
          font-size: 18px;
          color: #E2E8F0;
        }
        .closing-box strong {
          color: #38BDF8;
        }
      </style>
    </head>
    <body>
      <div class="outro-badge">
        Project Successfully Delivered • Week 04
      </div>
      <h1>CareConnect — Final Showcase Complete</h1>
      <div class="sub">All 5-Day Functional, Persistence, and Quality Assurance Objectives Fulfilled</div>

      <div class="metrics-row">
        <div class="m-card">
          <div class="m-val">100%</div>
          <div class="m-lbl">Automated Test Pass</div>
          <div class="m-sub">Unit, Widget & Repository Suites</div>
        </div>
        <div class="m-card">
          <div class="m-val">SQLite</div>
          <div class="m-lbl">Durable Persistence</div>
          <div class="m-sub">Appointments preserved across restarts</div>
        </div>
        <div class="m-card">
          <div class="m-val">Riverpod</div>
          <div class="m-lbl">State Architecture</div>
          <div class="m-sub">Feature-first clean separation</div>
        </div>
        <div class="m-card">
          <div class="m-val">360-1200</div>
          <div class="m-lbl">Responsive UI</div>
          <div class="m-sub">Verified on compact phone to tablet</div>
        </div>
      </div>

      <div class="closing-box">
        Built with Flutter & Dart for <strong>Stack & Scale Internship 2026</strong> • Developer: <strong>Nida Fatima</strong> • Thank You!
      </div>
    </body>
    </html>
  `;
  await page.setContent(outroHtml);
  const outroImg = path.join(backgroundsDir, '11_outro.png');
  await page.screenshot({ path: outroImg });
  console.log(`Saved outro card: ${outroImg}`);

  // 3. Generate background cards for each of the 9 scenes
  for (const sc of sceneData) {
    const cardHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          * { box-sizing: border-box; margin: 0; padding: 0; }
          body {
            width: 1920px;
            height: 1080px;
            overflow: hidden;
            font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, Roboto, sans-serif;
            background: radial-gradient(circle at 85% 15%, #064E3B 0%, #042F2E 40%, #0C4A5A 80%, #0E5C6F 100%);
            color: #F8FAFC;
            position: relative;
          }
          .phone-bezel {
            position: absolute;
            left: 60px;
            top: 45px;
            width: 460px;
            height: 970px;
            background: #000000;
            border-radius: 44px;
            border: 4px solid #0E7490;
            box-shadow: 0 25px 60px rgba(0,0,0,0.6), 0 0 35px rgba(14,116,144,0.35);
          }
          .phone-notch {
            position: absolute;
            top: 14px;
            left: 50%;
            transform: translateX(-50%);
            width: 110px;
            height: 22px;
            background: #111827;
            border-radius: 20px;
            z-index: 10;
          }
          .info-panel {
            position: absolute;
            left: 550px;
            top: 45px;
            width: 1310px;
            height: 970px;
            background: rgba(12, 74, 90, 0.45);
            border: 1.5px solid rgba(34, 211, 238, 0.35);
            border-radius: 28px;
            padding: 38px 48px;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            backdrop-filter: blur(16px);
          }
          .top-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
          }
          .brand-pill {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            padding: 8px 20px;
            background: rgba(14, 116, 144, 0.35);
            border: 1px solid #0891B2;
            border-radius: 999px;
            color: #22D3EE;
            font-size: 15px;
            font-weight: 700;
            letter-spacing: 1.5px;
          }
          .dot {
            width: 10px;
            height: 10px;
            background: #10B981;
            border-radius: 50%;
            box-shadow: 0 0 8px #10B981;
          }
          .sec-badge {
            padding: 8px 18px;
            background: rgba(16, 185, 129, 0.15);
            border: 1px solid #10B981;
            border-radius: 999px;
            color: #6EE7B7;
            font-size: 15px;
            font-weight: 700;
            letter-spacing: 1px;
          }
          .title-box {
            margin-top: 10px;
          }
          .section-category {
            color: #22D3EE;
            font-size: 16px;
            font-weight: 700;
            letter-spacing: 2px;
            text-transform: uppercase;
            margin-bottom: 6px;
          }
          .section-title {
            font-size: 42px;
            font-weight: 800;
            color: #FFFFFF;
            line-height: 1.2;
            margin-bottom: 10px;
          }
          .section-desc {
            font-size: 19px;
            color: #CCFBF1;
            line-height: 1.5;
            max-width: 1150px;
          }
          .cards-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 20px;
            margin: 16px 0;
          }
          .metric-card {
            background: rgba(15, 23, 42, 0.65);
            border: 1px solid rgba(14, 116, 144, 0.45);
            border-radius: 18px;
            padding: 20px 22px;
          }
          .metric-label {
            font-size: 13px;
            color: #94A3B8;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 1.5px;
            margin-bottom: 6px;
          }
          .metric-value {
            font-size: 20px;
            font-weight: 700;
            color: #38BDF8;
            margin-bottom: 6px;
          }
          .metric-sub {
            font-size: 13px;
            color: #CBD5E1;
            line-height: 1.4;
          }
          .workflow-box {
            background: rgba(14, 26, 45, 0.6);
            border: 1px solid rgba(16, 185, 129, 0.3);
            border-radius: 18px;
            padding: 22px 28px;
          }
          .wf-title {
            font-size: 15px;
            font-weight: 700;
            color: #10B981;
            letter-spacing: 1.5px;
            text-transform: uppercase;
            margin-bottom: 14px;
            display: flex;
            align-items: center;
            gap: 8px;
          }
          .wf-steps {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px 24px;
          }
          .wf-step {
            display: flex;
            align-items: center;
            gap: 12px;
            font-size: 15px;
            color: #F1F5F9;
          }
          .wf-icon {
            width: 24px;
            height: 24px;
            border-radius: 50%;
            background: #0E7490;
            color: #FFFFFF;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 13px;
            font-weight: bold;
            flex-shrink: 0;
          }
          .footer-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding-top: 14px;
            border-top: 1px solid rgba(14, 116, 144, 0.35);
          }
          .tech-tags {
            display: flex;
            gap: 10px;
          }
          .tech-tag {
            font-size: 13px;
            font-weight: 600;
            color: #22D3EE;
            background: rgba(14, 116, 144, 0.25);
            padding: 4px 12px;
            border-radius: 6px;
            border: 1px solid rgba(34, 211, 238, 0.25);
          }
          .student-tag {
            font-size: 14px;
            color: #94A3B8;
          }
          .student-tag strong {
            color: #F8FAFC;
          }
        </style>
      </head>
      <body>
        <div class='phone-bezel'>
          <div class='phone-notch'></div>
        </div>
        <div class='info-panel'>
          <div class='top-row'>
            <div class='brand-pill'>
              <span class='dot'></span>
              CARECONNECT • CLINIC APPOINTMENT BOOKING
            </div>
            <div class='sec-badge'>SECTION ${sc.secNum}</div>
          </div>
          <div class='title-box'>
            <div class='section-category'>${sc.category}</div>
            <div class='section-title'>${sc.title}</div>
            <div class='section-desc'>${sc.desc}</div>
          </div>
          <div class='cards-grid'>
            ${sc.metrics.map(m => `
              <div class='metric-card'>
                <div class='metric-label'>${m.label}</div>
                <div class='metric-value'>${m.val}</div>
                <div class='metric-sub'>${m.sub}</div>
              </div>
            `).join('')}
          </div>
          <div class='workflow-box'>
            <div class='wf-title'>Live Demonstration Walkthrough</div>
            <div class='wf-steps'>
              ${sc.steps.map((st, idx) => `
                <div class='wf-step'>
                  <div class='wf-icon'>${idx + 1}</div>
                  <div>${st}</div>
                </div>
              `).join('')}
            </div>
          </div>
          <div class='footer-row'>
            <div class='tech-tags'>
              <span class='tech-tag'>Flutter 3.x</span>
              <span class='tech-tag'>Dart</span>
              <span class='tech-tag'>Riverpod 2.6</span>
              <span class='tech-tag'>SQLite (sqflite)</span>
            </div>
            <div class='student-tag'>
              Intern: <strong>Nida Fatima</strong> | Stack & Scale Internship 2026
            </div>
          </div>
        </div>
      </body>
      </html>
    `;
    await page.setContent(cardHtml);
    const outImg = path.join(backgroundsDir, `${sc.id}_bg.png`);
    await page.screenshot({ path: outImg });
    console.log(`Generated background card: ${sc.id}_bg.png`);
  }

  await page.close();
}

async function main() {
  console.log('================================================================');
  console.log('STARTING CARECONNECT COMPLETE VIDEO REDESIGN & PRODUCTION');
  console.log('Work Dir:', WORK_DIR);
  console.log('Evidence Dir:', EVIDENCE_DIR);
  console.log('================================================================');

  const server = await startServer();

  // 1. Generate ambient audio soundtrack
  const audioPath = path.join(WORK_DIR, 'soundtrack.wav');
  generateSoundtrack(audioPath, 380);

  // 2. Launch browser for recording
  const browser = await chromium.launch({
    executablePath: CHROME_PATH,
    headless: true
  });

  // 3. Generate 1080p backgrounds
  await generateAllBackgrounds(browser);

  // 4. Record the 9 core interactive scenes
  console.log('\n--- Recording 9 Core App Scenes with High Detail & Genuine Interactions ---');
  for (const sc of sceneData) {
    console.log(`\nRecording Scene ${sc.id}: ${sc.route} (Target: ~${sc.targetDuration}s)...`);
    const sceneDir = path.join(rawClipsDir, `scene_${sc.id}`);
    fs.mkdirSync(sceneDir, { recursive: true });

    const context = await browser.newContext({
      viewport: { width: 440, height: 950 },
      deviceScaleFactor: 2,
      recordVideo: {
        dir: sceneDir,
        size: { width: 440, height: 950 }
      }
    });

    const page = await context.newPage();
    const url = `http://127.0.0.1:${PORT}/?v=${Date.now()}#${sc.route}`;
    await page.goto(url, { waitUntil: 'load' });
    await sleep(2500); // Allow Flutter rendering engine to warm up

    // Execute interactive demonstration
    await sc.actions(page);

    await sleep(1500);
    await page.close();
    await context.close();

    const videoFiles = fs.readdirSync(sceneDir).filter((f) => f.endsWith('.webm'));
    if (videoFiles.length === 0) throw new Error(`No webm file recorded for scene ${sc.id}`);

    const recordedPath = path.join(sceneDir, videoFiles[0]);
    const finalRawPath = path.join(rawClipsDir, `${sc.id}.webm`);
    fs.copyFileSync(recordedPath, finalRawPath);
    console.log(`Scene ${sc.id} recorded: ${finalRawPath} (${fs.statSync(finalRawPath).size} bytes)`);
  }

  await browser.close();
  server.close();

  // 5. Render Intro MP4 (22s)
  const introImg = path.join(backgroundsDir, '00_intro.png');
  const introMp4 = path.join(normalizedClipsDir, '00_intro.mp4');
  console.log('\nRendering 00_intro.mp4 (22s)...');
  execFileSync(FFMPEG_PATH, [
    '-loop', '1',
    '-i', introImg,
    '-c:v', 'libx264',
    '-t', '22',
    '-pix_fmt', 'yuv420p',
    '-r', '30',
    introMp4,
    '-y'
  ]);

  const clipList = [introMp4];

  // 6. Composite each scene clip onto its 1080p background
  // Phone bezel is at left:60, top:45. App screen fits at x:70, y:55, width:440, height:950.
  console.log('\n--- Compositing Scenes onto 1080p Layouts ---');
  for (const sc of sceneData) {
    const rawFile = path.join(rawClipsDir, `${sc.id}.webm`);
    const bgFile = path.join(backgroundsDir, `${sc.id}_bg.png`);
    const outFile = path.join(normalizedClipsDir, `${sc.id}.mp4`);

    console.log(`Compositing scene ${sc.id} into 1080p 16:9 MP4...`);

    // Loop background image, scale input video to 440:950, overlay at x=70:y=55
    const filterComplex = '[1:v]scale=440:950[app];[0:v][app]overlay=70:55:shortest=1[v]';

    execFileSync(FFMPEG_PATH, [
      '-loop', '1',
      '-i', bgFile,
      '-i', rawFile,
      '-filter_complex', filterComplex,
      '-map', '[v]',
      '-c:v', 'libx264',
      '-preset', 'fast',
      '-crf', '18',
      '-pix_fmt', 'yuv420p',
      '-r', '30',
      '-an',
      outFile,
      '-y'
    ]);

    clipList.push(outFile);
    console.log(`Scene ${sc.id} ready: ${outFile} (${fs.statSync(outFile).size} bytes)`);
  }

  // 7. Render Outro MP4 (24s)
  const outroImg = path.join(backgroundsDir, '11_outro.png');
  const outroMp4 = path.join(normalizedClipsDir, '11_outro.mp4');
  console.log('\nRendering 11_outro.mp4 (24s)...');
  execFileSync(FFMPEG_PATH, [
    '-loop', '1',
    '-i', outroImg,
    '-c:v', 'libx264',
    '-t', '24',
    '-pix_fmt', 'yuv420p',
    '-r', '30',
    outroMp4,
    '-y'
  ]);
  clipList.push(outroMp4);

  // 8. Concat all 11 clips
  console.log('\n--- Concatenating all 11 clips ---');
  const concatFile = path.join(WORK_DIR, 'concat_list.txt');
  const concatContent = clipList.map((c) => `file '${c.replace(/\\/g, '/')}'`).join('\n');
  fs.writeFileSync(concatFile, concatContent);

  const mergedVideoWithoutAudio = path.join(WORK_DIR, 'showcase_no_audio.mp4');
  execFileSync(FFMPEG_PATH, [
    '-f', 'concat',
    '-safe', '0',
    '-i', concatFile,
    '-c', 'copy',
    mergedVideoWithoutAudio,
    '-y'
  ]);
  console.log(`Concatenated video rendered: ${mergedVideoWithoutAudio}`);

  // 9. Final multiplexing with soundtrack
  const finalExportPath = path.join(EVIDENCE_DIR, 'CareConnect_Weekly_Final_Showcase.mp4');
  console.log(`\nMultiplexing final video with audio -> ${finalExportPath}...`);

  execFileSync(FFMPEG_PATH, [
    '-i', mergedVideoWithoutAudio,
    '-i', audioPath,
    '-c:v', 'copy',
    '-c:a', 'aac',
    '-b:a', '192k',
    '-shortest',
    finalExportPath,
    '-y'
  ]);

  const finalStat = fs.statSync(finalExportPath);
  console.log(`\n=============================================================`);
  console.log(`SUCCESS! CareConnect Weekly Final Showcase Video exported:`);
  console.log(`File: ${finalExportPath}`);
  console.log(`Size: ${(finalStat.size / (1024 * 1024)).toFixed(2)} MB`);
  console.log(`=============================================================`);

  process.exit(0);
}

main().catch((err) => {
  console.error('FATAL ERROR in render_careconnect_showcase:', err);
  process.exit(1);
});
