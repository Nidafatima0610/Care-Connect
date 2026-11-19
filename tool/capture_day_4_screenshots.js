const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const PORT = 8089;
const WEB_DIR = path.join(__dirname, '..', 'build', 'web');
const EVIDENCE_DIR = path.join(__dirname, '..', 'evidence', 'day_4');
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
    'cc_chrome_user_data_d4_' + Date.now()
  );
  const chromeArgs = [
    '--headless=new',
    '--remote-debugging-port=9226',
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

  console.log('Spawning Chrome for Day 4 captures...');
  const chromeProc = spawn(CHROME_PATH, chromeArgs, { stdio: 'ignore' });

  let pageWsUrl = null;
  for (let i = 0; i < 30; i++) {
    await sleep(500);
    try {
      const res = await fetch('http://127.0.0.1:9226/json/list');
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

  // ==========================================
  // 1. Capture 01: Persistent Appointment History
  // ==========================================
  await captureScreen(
    '01_persistent_appointment_history.png',
    '/appointments',
    7500
  );

  // ==========================================
  // 2. Capture 02: Appointment After Restart (Simulated app restart with persisted state)
  // ==========================================
  await captureScreen(
    '02_appointment_after_restart.png',
    '/appointments?restart=true',
    7500
  );

  // ==========================================
  // 3. Capture 03: Cancellation Confirmation Dialog
  // ==========================================
  await captureScreen(
    '03_cancellation_confirmation.png',
    '/appointments?show_cancel=true',
    7500
  );

  // ==========================================
  // 4. Capture 04: Cancelled Appointment State
  // ==========================================
  await captureScreen(
    '04_cancelled_appointment.png',
    '/appointments?tab=past&cancelled=true',
    7500
  );

  // ==========================================
  // 5. Capture 05: Rescheduling Screen
  // ==========================================
  await captureScreen(
    '05_rescheduling_screen.png',
    '/appointments/APT-849201/reschedule',
    7500
  );

  // ==========================================
  // 6. Capture 06: Rescheduled Appointment Review State
  // ==========================================
  console.log('--- Capturing 06_rescheduled_appointment.png ---');
  await sendCommand('Page.navigate', {
    url: `http://127.0.0.1:${PORT}/?v=${Date.now()}&reschedule_slot=02:30 PM#/appointments/APT-849201/reschedule`,
  });
  await sleep(6500);
  // Scroll down so Rescheduling Summary review card and CTA are visible
  await sendCommand('Input.dispatchMouseEvent', {
    type: 'mouseWheel',
    x: 215,
    y: 400,
    deltaX: 0,
    deltaY: 450,
  });
  await sleep(1500);
  const shot06 = await sendCommand('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(
    path.join(EVIDENCE_DIR, '06_rescheduled_appointment.png'),
    Buffer.from(shot06.data, 'base64')
  );
  console.log('Saved 06_rescheduled_appointment.png');

  // ==========================================
  // 7. Capture 07: Reminder Configuration Bottom Sheet
  // ==========================================
  await captureScreen(
    '07_reminder_configuration.png',
    '/appointments?show_reminders=true',
    7500
  );

  // ==========================================
  // 8. Capture 08: Notification Demo SnackBar
  // ==========================================
  await captureScreen(
    '08_notification_demo.png',
    '/appointments?show_demo=true',
    7500
  );

  // ==========================================
  // 9. Capture 09: Offline Storage State Banner
  // ==========================================
  await captureScreen(
    '09_offline_state.png',
    '/appointments?offline=true',
    7500
  );

  // ==========================================
  // Complete & Clean Up
  // ==========================================
  console.log('All 9 Day 4 screenshots captured successfully.');
  ws.close();
  chromeProc.kill();
  server.close();

  try {
    fs.rmSync(userDataDir, { recursive: true, force: true });
  } catch (_) {}

  process.exit(0);
}

main().catch((err) => {
  console.error('Error during Day 4 capture:', err);
  process.exit(1);
});
