const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { chromium } = require('C:/Users/umair/Desktop/dreamweb_studio/node_modules/playwright-core');

const CHROME_PATH = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const FFMPEG_PATH = 'C:\\Users\\umair\\AppData\\Local\\Microsoft\\WinGet\\Links\\ffmpeg.exe';
const EVIDENCE_DIR = path.join(__dirname, '..', 'evidence', 'day_5');

// Locate existing temp directory with the 10 recorded scenes
const tempBase = process.env.TEMP || 'C:\\Temp';
const dirs = fs.readdirSync(tempBase).filter(d => d.startsWith('cc_walkthrough_')).sort().reverse();
if (dirs.length === 0) throw new Error('No cc_walkthrough temp directory found');
const WORK_DIR = path.join(tempBase, dirs[0]);
console.log(`Using existing recorded work directory: ${WORK_DIR}`);

const rawClipsDir = path.join(WORK_DIR, 'raw_clips');
const normalizedClipsDir = path.join(WORK_DIR, 'normalized_clips');
if (!fs.existsSync(normalizedClipsDir)) fs.mkdirSync(normalizedClipsDir, { recursive: true });

const overlaysDir = path.join(WORK_DIR, 'overlays');
if (!fs.existsSync(overlaysDir)) fs.mkdirSync(overlaysDir, { recursive: true });

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

async function generateOverlays() {
  console.log('Generating pixel-perfect 1080p transparent overlay PNGs via Playwright...');
  const browser = await chromium.launch({ executablePath: CHROME_PATH, headless: true });
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });

  for (const sc of sceneSpecs) {
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body {
            margin: 0;
            width: 1920px;
            height: 1080px;
            background: transparent;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            overflow: hidden;
            position: relative;
          }
          .header-pill {
            position: absolute;
            top: 40px;
            left: 45px;
            display: inline-flex;
            align-items: center;
            padding: 12px 28px;
            background: rgba(14, 116, 144, 0.4);
            border: 1.5px solid #0891B2;
            border-radius: 999px;
            color: #22D3EE;
            font-size: 20px;
            font-weight: 700;
            letter-spacing: 1.5px;
            backdrop-filter: blur(10px);
            box-shadow: 0 4px 16px rgba(0,0,0,0.3);
          }
          .footer-card {
            position: absolute;
            bottom: 35px;
            left: 45px;
            right: 45px;
            padding: 16px 28px;
            background: rgba(14, 26, 45, 0.92);
            border: 1px solid rgba(14, 116, 144, 0.5);
            border-radius: 14px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            backdrop-filter: blur(12px);
            box-shadow: 0 8px 24px rgba(0,0,0,0.4);
          }
          .sub-text {
            color: #FBFBFA;
            font-size: 20px;
            font-weight: 500;
            letter-spacing: 0.3px;
          }
          .brand-tag {
            color: #10B981;
            font-size: 16px;
            font-weight: 600;
            letter-spacing: 1px;
            text-transform: uppercase;
            padding: 4px 12px;
            background: rgba(16, 185, 129, 0.15);
            border: 1px solid rgba(16, 185, 129, 0.3);
            border-radius: 6px;
          }
        </style>
      </head>
      <body>
        <div class="header-pill">${sc.label}</div>
        <div class="footer-card">
          <div class="sub-text">${sc.sub}</div>
          <div class="brand-tag">CareConnect Core Feature</div>
        </div>
      </body>
      </html>
    `;
    await page.setContent(html);
    const outPng = path.join(overlaysDir, `${sc.id}_overlay.png`);
    await page.screenshot({ path: outPng, omitBackground: true });
    console.log(`Generated overlay: ${sc.id}_overlay.png`);
  }

  await browser.close();
}

async function main() {
  await generateOverlays();

  const introImg = path.join(WORK_DIR, 'intro_card.png');
  const outroImg = path.join(WORK_DIR, 'outro_card.png');
  const audioPath = path.join(WORK_DIR, 'soundtrack.wav');

  if (!fs.existsSync(introImg) || !fs.existsSync(outroImg)) {
    throw new Error('Intro or Outro card missing');
  }

  // 1. Render Intro MP4 (8s)
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

  const clipList = [introMp4];

  // 2. Transcode each scene clip using overlay filter (NO fontconfig)
  for (const sc of sceneSpecs) {
    const rawFile = path.join(rawClipsDir, `${sc.id}.webm`);
    const overlayFile = path.join(overlaysDir, `${sc.id}_overlay.png`);
    const outFile = path.join(normalizedClipsDir, `${sc.id}.mp4`);

    console.log(`Compositing scene ${sc.id} into 1080p 16:9 MP4...`);

    // Scale mobile webm to height 960 (keeping aspect ratio 430:932 -> width ~442)
    // Pad to 1920:1080 with Deep Navy background #0E1A2D
    // Overlay the transparent branding PNG on top
    const filterComplex = [
      '[0:v]scale=-1:960,pad=1920:1080:(1920-iw)/2:(1080-ih)/2:color=#0E1A2D[base]',
      '[base][1:v]overlay=0:0[v]'
    ].join(';');

    execFileSync(FFMPEG_PATH, [
      '-i', rawFile,
      '-i', overlayFile,
      '-filter_complex', filterComplex,
      '-map', '[v]',
      '-c:v', 'libx264',
      '-preset', 'fast',
      '-crf', '19',
      '-r', '30',
      '-an',
      outFile,
      '-y'
    ]);

    clipList.push(outFile);
    console.log(`Scene ${sc.id} ready: ${outFile} (${fs.statSync(outFile).size} bytes)`);
  }

  // 3. Render Outro MP4 (10s)
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

  // 4. Concat all clips
  const concatFile = path.join(WORK_DIR, 'concat_list.txt');
  const concatContent = clipList.map((c) => `file '${c.replace(/\\/g, '/')}'`).join('\n');
  fs.writeFileSync(concatFile, concatContent);

  const finalVideoWithoutAudio = path.join(WORK_DIR, 'walkthrough_video_only.mp4');
  console.log('Concatenating all clips...');
  execFileSync(FFMPEG_PATH, [
    '-f', 'concat',
    '-safe', '0',
    '-i', concatFile,
    '-c', 'copy',
    finalVideoWithoutAudio,
    '-y'
  ]);

  // 5. Final multiplexing with audio
  const finalExportPath = path.join(EVIDENCE_DIR, 'careconnect_final_walkthrough.mp4');
  console.log(`Multiplexing final video with ambient soundtrack -> ${finalExportPath}...`);

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

  process.exit(0);
}

main().catch((err) => {
  console.error('Error during video assembly:', err);
  process.exit(1);
});
