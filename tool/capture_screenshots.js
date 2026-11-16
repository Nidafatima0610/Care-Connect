const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const PORT = 8085;
const WEB_DIR = path.join(__dirname, '..', 'build', 'web');
const EVIDENCE_DIR = path.join(__dirname, '..', 'evidence', 'day_1');
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

// 1. Static file server
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

// 2. Main capture workflow
async function main() {
  if (!fs.existsSync(EVIDENCE_DIR)) {
    fs.mkdirSync(EVIDENCE_DIR, { recursive: true });
  }

  const server = await startServer();

  const userDataDir = path.join(process.env.TEMP || 'C:\\Temp', 'cc_chrome_user_data_' + Date.now());
  const chromeArgs = [
    '--headless=new',
    '--remote-debugging-port=9222',
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

  console.log('Spawning Chrome...');
  const chromeProc = spawn(CHROME_PATH, chromeArgs, { stdio: 'ignore' });

  // Wait for remote debugging to be ready and get a page target
  let pageWsUrl = null;
  for (let i = 0; i < 30; i++) {
    await sleep(500);
    try {
      const res = await fetch('http://127.0.0.1:9222/json/list');
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

  // Connect via WebSocket to the Page target
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

  // Helper to click coordinates
  async function clickAt(x, y) {
    await sendCommand('Input.dispatchMouseEvent', {
      type: 'mousePressed',
      x,
      y,
      button: 'left',
      clickCount: 1,
    });
    await sleep(80);
    await sendCommand('Input.dispatchMouseEvent', {
      type: 'mouseReleased',
      x,
      y,
      button: 'left',
      clickCount: 1,
    });
  }

  // Set device emulation: iPhone 15 Pro Max
  // width: 430, height: 932, scale: 2.0 -> genuine 860x1864 crisp pixels
  await sendCommand('Page.enable');
  await sendCommand('DOM.enable');
  await sendCommand('Runtime.enable');
  await sendCommand('Emulation.setDeviceMetricsOverride', {
    width: 430,
    height: 932,
    deviceScaleFactor: 2.0,
    mobile: true,
  });

  console.log('--- Navigating to Home Screen ---');
  await sendCommand('Page.navigate', { url: `http://127.0.0.1:${PORT}/#/` });

  // Wait for Flutter Web engine initialization and image loading
  console.log('Waiting for Flutter app rendering...');
  await sleep(6500);

  // Capture 01: Home Screen
  console.log('Capturing 01_home_screen.png...');
  const shot1 = await sendCommand('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(
    path.join(EVIDENCE_DIR, '01_home_screen.png'),
    Buffer.from(shot1.data, 'base64')
  );
  console.log('Saved 01_home_screen.png');

  // Interaction: Search for "Elena"
  console.log('--- Interacting with Search Bar ---');
  // Click search field (around X: 215, Y: 290)
  await clickAt(215, 290);
  await sleep(400);

  // Type "Elena"
  await sendCommand('Input.insertText', { text: 'Elena' });
  await sleep(2500); // allow Riverpod reactive filtering to settle

  console.log('Capturing 02_doctor_search_filtering.png...');
  const shot2 = await sendCommand('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(
    path.join(EVIDENCE_DIR, '02_doctor_search_filtering.png'),
    Buffer.from(shot2.data, 'base64')
  );
  console.log('Saved 02_doctor_search_filtering.png');

  // Navigate to Doctor Detail Screen
  console.log('--- Navigating to Doctor Detail Screen ---');
  await sendCommand('Page.navigate', {
    url: `http://127.0.0.1:${PORT}/#/doctor/doc_alistair_vance`,
  });
  await sleep(4500); // allow detail page and portrait to load

  console.log('Capturing 03_doctor_detail_screen.png...');
  const shot3 = await sendCommand('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(
    path.join(EVIDENCE_DIR, '03_doctor_detail_screen.png'),
    Buffer.from(shot3.data, 'base64')
  );
  console.log('Saved 03_doctor_detail_screen.png');

  // Click "Book Appointment" sticky button
  // Bottom bar is at Y: 890, Book Appointment button is at X: 290
  console.log('--- Clicking Book Appointment button ---');
  await clickAt(290, 895);
  await sleep(1500); // allow modal bottom sheet animation to settle

  console.log('Capturing 04_booking_roadmap_modal.png...');
  const shot4 = await sendCommand('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(
    path.join(EVIDENCE_DIR, '04_booking_roadmap_modal.png'),
    Buffer.from(shot4.data, 'base64')
  );
  console.log('Saved 04_booking_roadmap_modal.png');

  // Clean up
  console.log('All screenshots captured successfully.');
  ws.close();
  chromeProc.kill();
  server.close();

  try {
    fs.rmSync(userDataDir, { recursive: true, force: true });
  } catch (_) {}

  process.exit(0);
}

main().catch((err) => {
  console.error('Error during capture:', err);
  process.exit(1);
});
