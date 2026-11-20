import os
import subprocess
import re

ffmpeg = r'C:\Users\umair\AppData\Local\Microsoft\WinGet\Links\ffmpeg.exe'

# 1. Check audio files in user uploads
uploads_dir = r'C:\Users\umair\.gemini\antigravity\brain\1ae6a110-f689-4500-826f-ec7e60194096\.user_uploaded'
print('=== AUDIO FILES IN UPLOADS ===')
if os.path.exists(uploads_dir):
    for f in os.listdir(uploads_dir):
        p = os.path.join(uploads_dir, f)
        print(f, os.path.getsize(p), 'bytes')
        res = subprocess.run([ffmpeg, '-i', p], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        for line in res.stderr.splitlines():
            if 'Duration:' in line or 'Audio:' in line or 'Stream' in line:
                print('  ', line.strip())

# 2. Check images used in generate_careconnect_report_v2.py
print('\n=== CHECKING SCRIPT IMAGES IN REPORT V2 ===')
with open('tool/generate_careconnect_report_v2.py', 'r', encoding='utf-8') as f:
    code = f.read()

img_paths = re.findall(r'[\'\"](evidence/[^\'\"]+\.png)[\'\"]', code)
print('Images referenced in report v2 script:', len(img_paths))
for img in sorted(set(img_paths)):
    full_path = os.path.abspath(img)
    exists = os.path.exists(full_path)
    size = os.path.getsize(full_path) if exists else 0
    print(f'{img} (exists={exists}, size={size} bytes)')
