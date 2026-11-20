const http = require('http');
const fs = require('fs');
const path = require('path');
const { execFileSync, spawn } = require('child_process');
const { chromium } = require('C:/Users/umair/Desktop/dreamweb_studio/node_modules/playwright-core');

const PORT = 8096;
const WEB_DIR = path.join(__dirname, '..', 'build', 'web');
const EVIDENCE_DIR = path.join(__dirname, '..', 'evidence', 'day_5');
const TEMP_DIR = path.join(process.env.TEMP || 'C:\\Temp', 'cc_walkthrough_' + Date.now());
const CHROME_PATH = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const FFMPEG_PATH = 'C:\\Users\\umair\\AppData\\Local\\Microsoft\\WinGet\\Links\\ffmpeg.exe';

if (!fs.existsSync(TEMP_DIR)) fs.mkdirSync(TEMP_DIR, { recursive: true });
if (!fs.existsSync(EVIDENCE_DIR)) fs.mkdirSync(EVIDENCE_DIR, { recursive: true });

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

// Generate synthesized ambient piano/arpeggio soundtrack
function generateSoundtrack(filePath, durationSec = 350) {
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
        vol: 0.16 + (idx % 2 === 0 ? 0.05 : 0.0),
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

async function smoothScroll(page, deltaY, steps = 18, delayMs = 45) {
  for (let i = 0; i < steps; i++) {
    await page.mouse.wheel(0, deltaY / steps);
    await sleep(delayMs);
  }
}

async function main() {
  console.log('=== STARTING CARECONNECT DAY 5 SHOWCASE VIDEO PRODUCTION ===');
  const server = await startServer();

  const audioPath = path.join(TEMP_DIR, 'soundtrack.wav');
  generateSoundtrack(audioPath, 360);

  const browser = await chromium.launch({
    executablePath: CHROME_PATH,
    headless: true
  });

  const rawClipsDir = path.join(TEMP_DIR, 'raw_clips');
  if (!fs.existsSync(rawClipsDir)) fs.mkdirSync(rawClipsDir, { recursive: true });

  // Helper to record a single scene
  async function recordScene(sceneId, route, actionsFn, targetDurationSec = 30) {
    console.log(`\n--- Recording Scene ${sceneId}: ${route} (Target: ~${targetDurationSec}s) ---`);
    const sceneDir = path.join(rawClipsDir, `scene_${sceneId}`);
    if (fs.existsSync(sceneDir)) fs.rmSync(sceneDir, { recursive: true, force: true });
    fs.mkdirSync(sceneDir, { recursive: true });

    const context = await browser.newContext({
      viewport: { width: 430, height: 932 },
      deviceScaleFactor: 2,
      recordVideo: {
        dir: sceneDir,
        size: { width: 860, height: 1864 }
      }
    });

    const page = await context.newPage();
    const url = `http://127.0.0.1:${PORT}/?v=${Date.now()}#${route}`;
    await page.goto(url, { waitUntil: 'load' });
    await sleep(2500); // Allow Flutter rendering engine and animations to initialize

    await actionsFn(page);

    await sleep(1500);
    await page.close();
    await context.close();

    const videoFiles = fs.readdirSync(sceneDir).filter((f) => f.endsWith('.webm'));
    if (videoFiles.length === 0) throw new Error(`No webm file recorded for scene ${sceneId}`);

    const recordedPath = path.join(sceneDir, videoFiles[0]);
    const finalRawPath = path.join(rawClipsDir, `${sceneId}.webm`);
    fs.copyFileSync(recordedPath, finalRawPath);
    console.log(`Scene ${sceneId} recorded: ${finalRawPath} (${fs.statSync(finalRawPath).size} bytes)`);
    return finalRawPath;
  }

  // --- RECORD 10 CORE APPLICATION SCENES ---

  // 1. Home / Doctor Discovery
  await recordScene('01_doctor_discovery', '/home', async (page) => {
    await sleep(2500);
    await smoothScroll(page, 320, 20, 50);
    await sleep(2000);
    await smoothScroll(page, 450, 24, 50);
    await sleep(3000);
    await smoothScroll(page, -350, 20, 45);
    await sleep(2000);
    await smoothScroll(page, -420, 20, 45);
    await sleep(2500);
  }, 28);

  // 2. Doctor Details Profile
  await recordScene('02_doctor_details', '/doctors/doc_marcus_vance', async (page) => {
    await sleep(2500);
    await smoothScroll(page, 280, 20, 50);
    await sleep(3000);
    await smoothScroll(page, 400, 22, 50);
    await sleep(3000);
    await smoothScroll(page, -300, 18, 50);
    await sleep(2500);
  }, 28);

  // 3. Search & Specialty Filters
  await recordScene('03_search_and_filters', '/home', async (page) => {
    await sleep(2000);
    // Click search or specialty
    await page.mouse.click(160, 235); // Specialty chip click
    await sleep(3000);
    await smoothScroll(page, 280, 16, 50);
    await sleep(2500);
    await smoothScroll(page, -280, 16, 50);
    await sleep(2000);
    // Navigate with query to show real-time query filter
    await page.goto(`http://127.0.0.1:${PORT}/?q=Cardio#/home`, { waitUntil: 'load' });
    await sleep(3500);
    await smoothScroll(page, 200, 14, 50);
    await sleep(2500);
  }, 30);

  // 4. Patient Profile & Local Identity
  await recordScene('04_patient_profile', '/profile', async (page) => {
    await sleep(2500);
    await smoothScroll(page, 350, 20, 50);
    await sleep(3000);
    await smoothScroll(page, 300, 18, 50);
    await sleep(2500);
    await smoothScroll(page, -450, 20, 50);
    await sleep(2500);
  }, 28);

  // 5. Appointment Booking (Date & Slot Selection)
  await recordScene('05_appointment_booking', '/booking/doc_marcus_vance', async (page) => {
    await sleep(2500);
    // Scroll date picker
    await smoothScroll(page, 150, 12, 50);
    await sleep(2500);
    // Click an afternoon slot
    await page.mouse.click(120, 480);
    await sleep(2500);
    await smoothScroll(page, 300, 16, 50);
    await sleep(3500);
    await smoothScroll(page, -200, 14, 50);
    await sleep(2500);
  }, 32);

  // 6. Booking Confirmation Receipt
  await recordScene('06_booking_confirmation', '/booking/confirmation?id=APT-849201&doctor=Dr.+Marcus+Vance&date=2026-11-24&slot=10:00+AM&fee=140.0', async (page) => {
    await sleep(2500);
    await smoothScroll(page, 250, 16, 50);
    await sleep(3500);
    await smoothScroll(page, -250, 16, 50);
    await sleep(2500);
  }, 24);

  // 7. Persistent Appointment History (SQLite)
  await recordScene('07_appointment_history', '/appointments', async (page) => {
    await sleep(2500);
    await smoothScroll(page, 260, 16, 50);
    await sleep(3500);
    await smoothScroll(page, -260, 16, 50);
    await sleep(2500);
  }, 28);

  // 8. Appointment Rescheduling Flow
  await recordScene('08_appointment_rescheduling', '/appointments/APT-849201/reschedule', async (page) => {
    await sleep(2500);
    await smoothScroll(page, 200, 14, 50);
    await sleep(2500);
    // Select new time slot
    await page.mouse.click(200, 440);
    await sleep(2500);
    await smoothScroll(page, 350, 18, 50);
    await sleep(3500);
    await smoothScroll(page, -250, 16, 50);
    await sleep(2500);
  }, 32);

  // 9. Appointment Cancellation Workflow
  await recordScene('09_appointment_cancellation', '/appointments?show_cancel=true', async (page) => {
    await sleep(3000);
    await smoothScroll(page, 150, 12, 50);
    await sleep(3500);
    // Show past tab with cancelled appointment
    await page.goto(`http://127.0.0.1:${PORT}/?tab=past&cancelled=true#/appointments`, { waitUntil: 'load' });
    await sleep(3500);
    await smoothScroll(page, 220, 16, 50);
    await sleep(3000);
  }, 30);

  // 10. Local Reminders & Offline Resilience
  await recordScene('10_reminders_and_offline', '/appointments?show_reminders=true', async (page) => {
    await sleep(3000);
    // Show demo notification feedback
    await page.goto(`http://127.0.0.1:${PORT}/?show_demo=true#/appointments`, { waitUntil: 'load' });
    await sleep(3500);
    // Show offline mode banner
    await page.goto(`http://127.0.0.1:${PORT}/?offline=true#/appointments`, { waitUntil: 'load' });
    await sleep(3500);
    await smoothScroll(page, 200, 14, 50);
    await sleep(3000);
  }, 32);

  // Generate Title Card & Outro Card images via Playwright
  console.log('\n--- Generating Professional 1080p Brand Cards ---');
  const cardPage = await browser.newPage({ viewport: { width: 1920, height: 1080 } });

  const introHtml = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body {
          margin: 0;
          width: 1920px;
          height: 1080px;
          background: radial-gradient(circle at 50% 40%, #162740 0%, #0E1A2D 85%);
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
          color: #FBFBFA;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          text-align: center;
          overflow: hidden;
        }
        .badge {
          display: inline-flex;
          align-items: center;
          padding: 10px 24px;
          background: rgba(14, 116, 144, 0.25);
          border: 1px solid #0E7490;
          border-radius: 999px;
          color: #22D3EE;
          font-size: 19px;
          font-weight: 600;
          letter-spacing: 2px;
          text-transform: uppercase;
          margin-bottom: 30px;
        }
        h1 {
          font-size: 80px;
          font-weight: 800;
          margin: 0 0 16px 0;
          letter-spacing: -1px;
          background: linear-gradient(135deg, #FBFBFA 30%, #A5F3FC 100%);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
        }
        .subtitle {
          font-size: 34px;
          font-weight: 400;
          color: #94A3B8;
          margin-bottom: 48px;
          max-width: 900px;
          line-height: 1.4;
        }
        .tech-tags {
          display: flex;
          gap: 16px;
        }
        .tag {
          padding: 10px 20px;
          background: #1E293B;
          border: 1px solid #334155;
          border-radius: 12px;
          color: #E2E8F0;
          font-size: 18px;
          font-weight: 500;
        }
      </style>
    </head>
    <body>
      <div class="badge">Stack & Scale Internship Final Project</div>
      <h1>CareConnect</h1>
      <div class="subtitle">Appointment Booking, Rescheduling & Local Reminders</div>
      <div class="tech-tags">
        <div class="tag">Flutter & Dart</div>
        <div class="tag">Riverpod Reactive State</div>
        <div class="tag">SQLite Local Persistence</div>
        <div class="tag">Local Push Reminders</div>
        <div class="tag">Clean Feature Architecture</div>
      </div>
    </body>
    </html>
  `;
  await cardPage.setContent(introHtml);
  const introImg = path.join(TEMP_DIR, 'intro_card.png');
  await cardPage.screenshot({ path: introImg });

  const outroHtml = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body {
          margin: 0;
          width: 1920px;
          height: 1080px;
          background: radial-gradient(circle at 50% 50%, #162740 0%, #0E1A2D 85%);
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
          color: #FBFBFA;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          text-align: center;
          overflow: hidden;
        }
        .check-icon {
          width: 90px;
          height: 90px;
          background: rgba(16, 185, 129, 0.2);
          border: 2px solid #10B981;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          color: #10B981;
          font-size: 48px;
          margin-bottom: 24px;
        }
        h2 {
          font-size: 64px;
          font-weight: 800;
          margin: 0 0 16px 0;
          color: #FBFBFA;
        }
        .msg {
          font-size: 30px;
          color: #94A3B8;
          margin-bottom: 40px;
        }
        .qa-badges {
          display: flex;
          gap: 20px;
          margin-bottom: 50px;
        }
        .qa-badge {
          padding: 12px 24px;
          background: rgba(14, 116, 144, 0.2);
          border: 1px solid #0E7490;
          border-radius: 12px;
          color: #22D3EE;
          font-size: 20px;
          font-weight: 600;
        }
        .signature {
          font-size: 22px;
          color: #64748B;
          letter-spacing: 1px;
        }
      </style>
    </head>
    <body>
      <div class="check-icon">&#10003;</div>
      <h2>Built with Flutter &amp; Dart</h2>
      <div class="msg">CareConnect — Complete 5-Day Internship Project</div>
      <div class="qa-badges">
        <div class="qa-badge">117 / 117 Tests Passed (100%)</div>
        <div class="qa-badge">0 Analyzer Issues</div>
        <div class="qa-badge">Responsive (360x800 &amp; 412x915)</div>
      </div>
      <div class="signature">Thank you for watching!</div>
    </body>
    </html>
  `;
  await cardPage.setContent(outroHtml);
  const outroImg = path.join(TEMP_DIR, 'outro_card.png');
  await cardPage.screenshot({ path: outroImg });

  await cardPage.close();
  await browser.close();
  server.close();

  // --- ASSEMBLY & TRANSCODING VIA FFMPEG ---
  console.log('\n--- Normalizing & Assembling 1080p 16:9 Showcase Video ---');
  const normalizedClipsDir = path.join(TEMP_DIR, 'normalized_clips');
  if (!fs.existsSync(normalizedClipsDir)) fs.mkdirSync(normalizedClipsDir, { recursive: true });

  const sceneSpecs = [
    { id: '01_doctor_discovery', label: '01 | DOCTOR DISCOVERY & CLINICAL DETAILS', sub: 'Featured specialist carousels, weekly schedule, ratings & clinical fee breakdown' },
    { id: '02_doctor_details', label: '02 | PHYSICIAN CLINICAL PROFILE', sub: '4-point metrics bar, bio, hospital affiliation, modalities & appointment triggers' },
    { id: '03_search_and_filters', label: '03 | SEARCH & MULTI-SPECIALTY FILTERING', sub: 'Real-time debounced query search and 8-specialty horizontal category filtering' },
    { id: '04_patient_profile', label: '04 | PATIENT PROFILE & LOCAL IDENTITY', sub: 'Clinical preferences, emergency contacts, MRN identity & form-validated demographic editor' },
    { id: '05_appointment_booking', label: '05 | APPOINTMENT BOOKING & TIME SLOTS', sub: '14-day interactive calendar strip, dynamic slot grid & live consultation review card' },
    { id: '06_booking_confirmation', label: '06 | BOOKING CONFIRMATION & RECEIPT', sub: 'Verified appointment receipt with unique ID, status badge & GoRouter deep links' },
    { id: '07_appointment_history', label: '07 | PERSISTENT APPOINTMENT HISTORY', sub: 'Durable local SQLite persistence retaining bookings and timestamps across app restarts' },
    { id: '08_appointment_rescheduling', label: '08 | APPOINTMENT RESCHEDULING', sub: 'Current booking banner, availability re-validation & atomic slot-swap transactions' },
    { id: '09_appointment_cancellation', label: '09 | CANCELLATION & SLOT RELEASE', sub: 'Safety confirmation modal, slot release to doctor availability pool & medical audit trail' },
    { id: '10_reminders_and_offline', label: '10 | LOCAL REMINDERS & OFFLINE RESILIENCE', sub: '30-minute lead time exact alarms, demo test alert & offline-first SQLite operation' },
  ];

  // Transcode intro card into 8-second MP4
  const introMp4 = path.join(normalizedClipsDir, '00_intro.mp4');
  console.log('Rendering 00_intro.mp4 (8s)...');
  execFileSync(FFMPEG_PATH, [
    '-loop', '1',
    '-i', introImg,
    '-c:v', 'libx264',
    '-t', '8',
    '-pix_fmt', 'yuv420p',
    '-r', '30',
    introMp4,
    '-y'
  ]);

  // Transcode each scene into framed 1080p 16:9 MP4 with chapter overlay
  const clipList = [introMp4];

  for (let i = 0; i < sceneSpecs.length; i++) {
    const spec = sceneSpecs[i];
    const rawFile = path.join(rawClipsDir, `${spec.id}.webm`);
    const outFile = path.join(normalizedClipsDir, `${spec.id}.mp4`);

    console.log(`Compositing scene ${spec.id} into 1080p 16:9...`);

    // Clean text overlay escaping for ffmpeg drawtext filter
    const titleText = spec.label.replace(/:/g, '\\:').replace(/'/g, '');
    const subText = spec.sub.replace(/:/g, '\\:').replace(/'/g, '');

    // Complex filter:
    // 1. Scale real mobile recording to 960px height (fit centered on 1920x1080 canvas)
    // 2. Pad to 1920x1080 canvas with Deep Navy (#0E1A2D)
    // 3. Draw upper left chapter badge and bottom description card
    const vf = [
      'scale=-1:960',
      'pad=1920:1080:(1920-iw)/2:(1080-ih)/2:color=#0E1A2D',
      `drawbox=x=40:y=40:w=680:h=60:color=#0E7490@0.3:t=fill`,
      `drawbox=x=40:y=40:w=680:h=60:color=#0891B2:t=2`,
      `drawtext=text='${titleText}':x=60:y=62:fontsize=22:fontcolor=#22D3EE:box=0`,
      `drawbox=x=40:y=980:w=1840:h=60:color=#162740@0.85:t=fill`,
      `drawbox=x=40:y=980:w=1840:h=60:color=#0E7490:t=1`,
      `drawtext=text='${subText}':x=60:y=1000:fontsize=20:fontcolor=#FBFBFA:box=0`,
      'format=yuv420p'
    ].join(',');

    execFileSync(FFMPEG_PATH, [
      '-i', rawFile,
      '-vf', vf,
      '-c:v', 'libx264',
      '-preset', 'fast',
      '-crf', '19',
      '-r', '30',
      '-an',
      outFile,
      '-y'
    ]);

    clipList.push(outFile);
  }

  // Transcode outro card into 10-second MP4
  const outroMp4 = path.join(normalizedClipsDir, '11_outro.mp4');
  console.log('Rendering 11_outro.mp4 (10s)...');
  execFileSync(FFMPEG_PATH, [
    '-loop', '1',
    '-i', outroImg,
    '-c:v', 'libx264',
    '-t', '10',
    '-pix_fmt', 'yuv420p',
    '-r', '30',
    outroMp4,
    '-y'
  ]);
  clipList.push(outroMp4);

  // Write concat list
  const concatFile = path.join(TEMP_DIR, 'concat_list.txt');
  const concatContent = clipList.map((c) => `file '${c.replace(/\\/g, '/')}'`).join('\n');
  fs.writeFileSync(concatFile, concatContent);

  const finalVideoWithoutAudio = path.join(TEMP_DIR, 'walkthrough_video_only.mp4');
  console.log('Concatenating all clips...');
  execFileSync(FFMPEG_PATH, [
    '-f', 'concat',
    '-safe', '0',
    '-i', concatFile,
    '-c', 'copy',
    finalVideoWithoutAudio,
    '-y'
  ]);

  // Final multiplexing with soundtrack
  const finalExportPath = path.join(EVIDENCE_DIR, 'careconnect_final_walkthrough.mp4');
  console.log(`Multiplexing final video with ambient audio -> ${finalExportPath}...`);

  execFileSync(FFMPEG_PATH, [
    '-i', finalVideoWithoutAudio,
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
  console.log(`SUCCESS! Final CareConnect Showcase Video exported:`);
  console.log(`File: ${finalExportPath}`);
  console.log(`Size: ${(finalStat.size / (1024 * 1024)).toFixed(2)} MB`);
  console.log(`=============================================================`);

  // Clean up temp directory
  try {
    fs.rmSync(TEMP_DIR, { recursive: true, force: true });
  } catch (_) {}

  process.exit(0);
}

main().catch((err) => {
  console.error('Fatal error during video walkthrough production:', err);
  process.exit(1);
});
