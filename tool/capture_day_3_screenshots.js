const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const PORT = 8088;
const WEB_DIR = path.join(__dirname, '..', 'build', 'web');
const EVIDENCE_DIR = path.join(__dirname, '..', 'evidence', 'day_3');
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
    'cc_chrome_user_data_d3_' + Date.now()
  );
  const chromeArgs = [
    '--headless=new',
    '--remote-debugging-port=9225',
    '--user-data-dir=' + userDataDir,
    '--no-first-run',
    '--no-default-browser-check',
    '--disable-background-networking',
    '--disable-extensions',
    '--disable-sync',
    '--window-size=430,932',
    '--hide-scrollbars',
    'about:blank',
  ];

  console.log('Spawning Chrome for Day 3 captures...');
  const chromeProc = spawn(CHROME_PATH, chromeArgs, { stdio: 'ignore' });

  let pageWsUrl = null;
  for (let i = 0; i < 30; i++) {
    await sleep(500);
    try {
      const res = await fetch('http://127.0.0.1:9225/json/list');
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

  // Setup mobile viewport emulation: 430x932 @ 2.0x DPR -> genuine 860x1864 PNGs
  await sendCommand('Page.enable');
  await sendCommand('DOM.enable');
  await sendCommand('Runtime.enable');
  await sendCommand('Emulation.setDeviceMetricsOverride', {
    width: 430,
    height: 932,
    deviceScaleFactor: 2.0,
    mobile: true,
  });

  // Helper function to capture a screen with full page reload isolation
  async function captureScreen(fileName, fullPathWithQuery, waitMs = 7000) {
    console.log(`--- Capturing ${fileName} (route: ${fullPathWithQuery}) ---`);
    const separator = fullPathWithQuery.includes('?') ? '&' : '?';
    const queryPart = fullPathWithQuery.split('?')[1] || '';
    const hashPart = fullPathWithQuery.split('?')[0];
    
    // In Flutter Web with hash router: http://127.0.0.1:PORT/?query#/route
    // We pass query parameters in the URL search string so Uri.base picks them up cleanly
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

  // ==========================================
  // 1. Capture 01: Booking Screen
  // ==========================================
  await captureScreen(
    '01_booking_screen.png',
    '/doctor/doc_alistair_vance/book',
    7500
  );

  // ==========================================
  // 2. Capture 02: Date Selection
  // ==========================================
  await captureScreen(
    '02_date_selection.png',
    '/doctor/doc_alistair_vance/book?select_date=tomorrow',
    7500
  );

  // ==========================================
  // 3. Capture 03: Available Time Slots (Scrolled to center time slot grid)
  // ==========================================
  console.log('--- Capturing 03_available_time_slots.png ---');
  await sendCommand('Page.navigate', {
    url: `http://127.0.0.1:${PORT}/?v=${Date.now()}&select_date=tomorrow#/doctor/doc_alistair_vance/book`,
  });
  await sleep(6500);
  await sendCommand('Input.dispatchMouseEvent', {
    type: 'mouseWheel',
    x: 215,
    y: 400,
    deltaX: 0,
    deltaY: 180,
  });
  await sleep(1500);
  const shot03 = await sendCommand('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(
    path.join(EVIDENCE_DIR, '03_available_time_slots.png'),
    Buffer.from(shot03.data, 'base64')
  );
  console.log('Saved 03_available_time_slots.png');

  // ==========================================
  // 4. Capture 04: Selected Appointment Slot
  // ==========================================
  console.log('--- Capturing 04_selected_appointment_slot.png ---');
  await sendCommand('Page.navigate', {
    url: `http://127.0.0.1:${PORT}/?v=${Date.now()}&select_date=tomorrow&select_slot=10:00 AM#/doctor/doc_alistair_vance/book`,
  });
  await sleep(6500);
  // Scroll down so Consultation Modality and Booking Review card are clearly visible
  await sendCommand('Input.dispatchMouseEvent', {
    type: 'mouseWheel',
    x: 215,
    y: 400,
    deltaX: 0,
    deltaY: 780,
  });
  await sleep(1500);
  const shot04 = await sendCommand('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(
    path.join(EVIDENCE_DIR, '04_selected_appointment_slot.png'),
    Buffer.from(shot04.data, 'base64')
  );
  console.log('Saved 04_selected_appointment_slot.png');

  // ==========================================
  // 5. Capture 05: Booking Confirmation Receipt
  // ==========================================
  await captureScreen(
    '05_booking_confirmation.png',
    '/booking/confirmation?id=APT-849201',
    8000
  );

  // ==========================================
  // 6. Capture 06: Appointment History
  // ==========================================
  await captureScreen(
    '06_appointment_history.png',
    '/appointments',
    7500
  );

  // ==========================================
  // 7. Capture 07: Booking Validation Error
  // ==========================================
  await captureScreen(
    '07_booking_validation_error.png',
    '/doctor/doc_alistair_vance/book?error=validation',
    7500
  );

  // ==========================================
  // 8. Capture 08: Booking Conflict Alert
  // ==========================================
  await captureScreen(
    '08_booking_conflict.png',
    '/doctor/doc_alistair_vance/book?error=conflict',
    7500
  );

  // ==========================================
  // Complete & Clean Up
  // ==========================================
  console.log('All 8 Day 3 screenshots captured successfully.');
  ws.close();
  chromeProc.kill();
  server.close();

  try {
    fs.rmSync(userDataDir, { recursive: true, force: true });
  } catch (_) {}

  process.exit(0);
}

main().catch((err) => {
  console.error('Error during Day 3 capture:', err);
  process.exit(1);
});
