const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const PORT = 8092;
const WEB_DIR = path.join(__dirname, '..', 'build', 'web');
const EVIDENCE_DIR = path.join(__dirname, '..', 'evidence', 'day_5');
const CHROME_PATH = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';

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
      console.log(`Server running at http://127.0.0.1:${PORT}`);
      resolve(server);
    });
  });
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function main() {
  if (!fs.existsSync(EVIDENCE_DIR)) {
    fs.mkdirSync(EVIDENCE_DIR, { recursive: true });
  }

  const server = await startServer();

  const userDataDir = path.join(
    process.env.TEMP || 'C:\\Temp',
    'cc_chrome_user_data_d5_' + Date.now()
  );
  const chromeArgs = [
    '--headless=new',
    '--remote-debugging-port=9227',
    '--user-data-dir=' + userDataDir,
    '--no-first-run',
    '--no-default-browser-check',
    '--disable-background-networking',
    '--disable-extensions',
    '--disable-sync',
    '--window-size=412,915',
    '--hide-scrollbars',
    'about:blank',
  ];

  console.log('Spawning Chrome for Day 5 captures...');
  const chromeProc = spawn(CHROME_PATH, chromeArgs, { stdio: 'ignore' });

  let pageWsUrl = null;
  for (let i = 0; i < 30; i++) {
    await sleep(500);
    try {
      const res = await fetch('http://127.0.0.1:9227/json/list');
      if (res.ok) {
        const list = await res.json();
        const page = list.find((t) => t.type === 'page');
        if (page && page.webSocketDebuggerUrl) {
          pageWsUrl = page.webSocketDebuggerUrl;
          console.log('Connected to Chrome Page target at', pageWsUrl);
          break;
        }
      }
    } catch (_) {}
  }

  if (!pageWsUrl) {
    console.error('Failed to connect to Chrome page debugging target.');
    chromeProc.kill();
    server.close();
    process.exit(1);
  }

  const ws = new WebSocket(pageWsUrl);
  await new Promise((res) => (ws.onopen = res));

  let msgId = 1;
  const pendingRequests = new Map();

  ws.onmessage = (evt) => {
    const msg = JSON.parse(evt.data);
    if (msg.id && pendingRequests.has(msg.id)) {
      const { resolve, reject } = pendingRequests.get(msg.id);
      pendingRequests.delete(msg.id);
      if (msg.error) reject(msg.error);
      else resolve(msg.result);
    }
  };

  function sendCommand(method, params = {}) {
    const id = msgId++;
    return new Promise((resolve, reject) => {
      pendingRequests.set(id, { resolve, reject });
      ws.send(JSON.stringify({ id, method, params }));
    });
  }

  await sendCommand('Page.enable');
  await sendCommand('DOM.enable');
  await sendCommand('Runtime.enable');

  async function setViewport(width, height) {
    await sendCommand('Emulation.setDeviceMetricsOverride', {
      width,
      height,
      deviceScaleFactor: 2.0,
      mobile: true,
    });
  }

  async function captureScreen(fileName, fullPathWithQuery, waitMs = 7000) {
    console.log(`--- Capturing ${fileName} (route: ${fullPathWithQuery}) ---`);
    const queryPart = fullPathWithQuery.includes('?') ? fullPathWithQuery.split('?')[1] : '';
    const hashPart = fullPathWithQuery.split('?')[0];

    let url;
    if (queryPart) {
      url = `http://127.0.0.1:${PORT}/?v=${Date.now()}&${queryPart}#${hashPart}`;
    } else {
      url = `http://127.0.0.1:${PORT}/?v=${Date.now()}#${hashPart}`;
    }

    console.log(`Navigating to: ${url}`);
    await sendCommand('Page.navigate', { url });
    await sleep(waitMs);
    const shot = await sendCommand('Page.captureScreenshot', { format: 'png' });
    const targetPath = path.join(EVIDENCE_DIR, fileName);
    fs.writeFileSync(targetPath, Buffer.from(shot.data, 'base64'));
    console.log(`Saved ${fileName} (${fs.statSync(targetPath).size} bytes)`);
  }

  // --- STANDARD SCREEN SIZE (412 x 915) ---
  await setViewport(412, 915);

  // 1. Home / Doctor Discovery
  await captureScreen('01_home_doctor_discovery.png', '/', 7500);

  // 2. Doctor Details
  await captureScreen('02_doctor_details.png', '/doctor/doc_alistair_vance', 7500);

  // 3. Search and Specialty Filters
  await captureScreen('03_search_specialty_filters.png', '/?q=Cardio', 7500);

  // 4. Appointment Booking
  await captureScreen('04_appointment_booking.png', '/doctor/doc_alistair_vance/book', 7500);

  // 5. Booking Confirmation
  await captureScreen('05_booking_confirmation.png', '/booking/confirmation?id=APT-849201&doctor=Dr.+Alistair+Vance&date=2026-11-24&slot=10:00+AM&fee=140.0', 7500);

  // 6. Appointment History
  await captureScreen('06_appointment_history.png', '/appointments', 7500);

  // 7. Cancellation or Rescheduling
  await captureScreen('07_cancellation_and_rescheduling.png', '/appointments/APT-849201/reschedule', 7500);

  // 8. Patient Profile
  await captureScreen('08_patient_profile.png', '/profile', 7500);

  // --- RESPONSIVE SMALL PHONE SIZE (360 x 800) ---
  await setViewport(360, 800);

  // 9. Responsive Small: Home
  await captureScreen('09_responsive_small_360x800_home.png', '/', 7500);

  // 10. Responsive Small: Booking
  await captureScreen('10_responsive_small_360x800_booking.png', '/doctor/doc_alistair_vance/book', 7500);

  // 11. Responsive Small: Appointment History
  await captureScreen('11_responsive_small_360x800_history.png', '/appointments', 7500);

  // 12. Responsive Small: Rescheduling
  await captureScreen('12_responsive_small_360x800_reschedule.png', '/appointments/APT-849201/reschedule', 7500);

  console.log('All Day 5 screenshots captured successfully.');
  ws.close();
  chromeProc.kill();
  server.close();

  try {
    fs.rmSync(userDataDir, { recursive: true, force: true });
  } catch (_) {}

  process.exit(0);
}

main().catch((err) => {
  console.error('Error during Day 5 capture:', err);
  process.exit(1);
});
