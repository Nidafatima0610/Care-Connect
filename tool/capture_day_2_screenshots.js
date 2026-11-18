const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const PORT = 8087;
const WEB_DIR = path.join(__dirname, '..', 'build', 'web');
const EVIDENCE_DIR = path.join(__dirname, '..', 'evidence', 'day_2');
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

  const userDataDir = path.join(process.env.TEMP || 'C:\\Temp', 'cc_chrome_user_data_d2_' + Date.now());
  const chromeArgs = [
    '--headless=new',
    '--remote-debugging-port=9224',
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

  console.log('Spawning Chrome for Day 2 captures...');
  const chromeProc = spawn(CHROME_PATH, chromeArgs, { stdio: 'ignore' });

  let pageWsUrl = null;
  for (let i = 0; i < 30; i++) {
    await sleep(500);
    try {
      const res = await fetch('http://127.0.0.1:9224/json/list');
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
  async function captureScreen(fileName, hashPath, waitMs = 6500) {
    console.log(`--- Capturing ${fileName} (route: ${hashPath}) ---`);
    const uniqueUrl = `http://127.0.0.1:${PORT}/index.html?v=${Date.now()}_${Math.floor(Math.random()*1000)}#${hashPath}`;
    await sendCommand('Page.navigate', { url: uniqueUrl });
    await sleep(waitMs);
    const shot = await sendCommand('Page.captureScreenshot', { format: 'png' });
    const targetPath = path.join(EVIDENCE_DIR, fileName);
    fs.writeFileSync(targetPath, Buffer.from(shot.data, 'base64'));
    console.log(`Saved ${fileName} (${fs.statSync(targetPath).size} bytes)`);
  }

  // ==========================================
  // 1. Capture 01: Doctor Search Results
  // ==========================================
  await captureScreen('01_doctor_search_results.png', '/?q=Elena', 7000);

  // ==========================================
  // 2. Capture 02: Specialty Filter Results
  // ==========================================
  await captureScreen('02_specialty_filter_results.png', '/?specialty=cardiology', 7000);

  // ==========================================
  // 3. Capture 03: Patient Profile Screen
  // ==========================================
  await captureScreen('03_patient_profile_screen.png', '/profile', 7000);

  // ==========================================
  // 4. Capture 04: Edit Patient Profile Screen
  // ==========================================
  await captureScreen('04_edit_patient_profile.png', '/profile/edit', 7000);

  // ==========================================
  // 5. Capture 05: Doctor Loading State (Skeleton Cards)
  // ==========================================
  await captureScreen('05_doctor_loading_state.png', '/?state=loading', 7000);

  // ==========================================
  // 6. Capture 06: Doctor Error State (Error View + Retry)
  // ==========================================
  await captureScreen('06_doctor_error_state.png', '/?state=error', 7000);

  // ==========================================
  // 7. Capture 07: Doctor Empty State (No Specialists Found)
  // ==========================================
  await captureScreen('07_doctor_empty_state.png', '/?q=NonExistentSpecialistXYZ', 7000);

  // ==========================================
  // Complete & Clean Up
  // ==========================================
  console.log('All 7 Day 2 screenshots captured successfully.');
  ws.close();
  chromeProc.kill();
  server.close();

  try {
    fs.rmSync(userDataDir, { recursive: true, force: true });
  } catch (_) {}

  process.exit(0);
}

main().catch((err) => {
  console.error('Error during Day 2 capture:', err);
  process.exit(1);
});
