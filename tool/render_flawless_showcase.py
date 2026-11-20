import os
import subprocess
import shutil

ffmpeg = r'C:\Users\umair\AppData\Local\Microsoft\WinGet\Links\ffmpeg.exe'

work_dir = r'C:\Users\umair\AppData\Local\Temp\cc_flawless_showcase'
os.makedirs(work_dir, exist_ok=True)

source_work_dir = r'C:\Users\umair\AppData\Local\Temp\cc_showcase_1795162862478'
bg_dir = os.path.join(source_work_dir, 'backgrounds')
soundtrack_wav = os.path.join(source_work_dir, 'soundtrack.wav')
voice_mp4 = r'C:\Users\umair\.gemini\antigravity\brain\1ae6a110-f689-4500-826f-ec7e60194096\.user_uploaded\media_1795165153262_6102797b.mp4'
if not os.path.exists(voice_mp4):
    voice_mp4 = r'C:\Users\umair\.gemini\antigravity\brain\1ae6a110-f689-4500-826f-ec7e60194096\.user_uploaded\media_1795163866286_3a6e97e5.mp4'

dest_day5 = r'D:\Internship daily projects\care_connect\evidence\day_5\CareConnect_Weekly_Final_Showcase.mp4'
dest_final_dir = r'D:\Internship daily projects\care_connect\evidence\final_submission'
os.makedirs(dest_final_dir, exist_ok=True)
dest_final = os.path.join(dest_final_dir, 'CareConnect_Weekly_Final_Showcase.mp4')

print('=== 1. VERIFYING SOURCES ===')
print('Voice audio:', voice_mp4, os.path.exists(voice_mp4))
print('Soundtrack:', soundtrack_wav, os.path.exists(soundtrack_wav))
print('Backgrounds dir:', bg_dir, os.path.exists(bg_dir))

# 8 segments mapping directly to the 51.95s voice narration
# Every phone screen uses a genuine, verified, complete application capture
segments = [
    {
        'id': '00_intro',
        'type': 'image',
        'file': os.path.join(bg_dir, '00_intro.png'),
        'duration': 3.5,
    },
    {
        'id': '02_doctor_discovery',
        'type': 'composite',
        'bg': os.path.join(bg_dir, '02_doctor_discovery_bg.png'),
        'shot': r'evidence\day_1\01_home_screen.png',
        'duration': 10.0,
    },
    {
        'id': '04_search_and_filters',
        'type': 'composite',
        'bg': os.path.join(bg_dir, '04_search_and_filters_bg.png'),
        'shot': r'evidence\day_2\01_doctor_search_results.png',
        'duration': 8.0,
    },
    {
        'id': '03_doctor_details',
        'type': 'composite',
        'bg': os.path.join(bg_dir, '03_doctor_details_bg.png'),
        'shot': r'evidence\day_5\02_doctor_details.png',
        'duration': 10.0,
    },
    {
        'id': '06_appointment_booking',
        'type': 'composite',
        'bg': os.path.join(bg_dir, '06_appointment_booking_bg.png'),
        'shot': r'evidence\day_5\04_appointment_booking.png',
        'duration': 12.0,
    },
    {
        'id': '07_booking_confirmation',
        'type': 'composite',
        'bg': os.path.join(bg_dir, '07_booking_confirmation_bg.png'),
        'shot': r'evidence\day_5\05_booking_confirmation.png',
        'duration': 7.0,
    },
    {
        'id': '08_appointment_history',
        'type': 'composite',
        'bg': os.path.join(bg_dir, '08_appointment_history_bg.png'),
        'shot': r'evidence\day_5\06_appointment_history.png',
        'duration': 5.0,
    },
    {
        'id': '11_outro',
        'type': 'image',
        'file': os.path.join(bg_dir, '11_outro.png'),
        'duration': 3.5,
    }
]

rendered_clips = []

print('\n=== 2. RENDERING INDIVIDUAL SCENE CLIPS ===')
for idx, seg in enumerate(segments):
    out_clip = os.path.join(work_dir, f'{idx:02d}_{seg["id"]}.mp4')
    if seg['type'] == 'image':
        print(f'Rendering {seg["id"]} ({seg["duration"]}s)...')
        cmd = [
            ffmpeg,
            '-loop', '1',
            '-i', seg['file'],
            '-c:v', 'libx264',
            '-t', str(seg['duration']),
            '-pix_fmt', 'yuv420p',
            '-r', '30',
            out_clip,
            '-y'
        ]
    else:
        print(f'Compositing {seg["id"]} with genuine screenshot ({seg["duration"]}s)...')
        filter_complex = '[1:v]scale=440:950[app];[0:v][app]overlay=70:55[v]'
        cmd = [
            ffmpeg,
            '-loop', '1',
            '-i', seg['bg'],
            '-loop', '1',
            '-i', seg['shot'],
            '-filter_complex', filter_complex,
            '-map', '[v]',
            '-c:v', 'libx264',
            '-preset', 'fast',
            '-crf', '18',
            '-t', str(seg['duration']),
            '-pix_fmt', 'yuv420p',
            '-r', '30',
            '-an',
            out_clip,
            '-y'
        ]
    subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
    rendered_clips.append(out_clip)
    print(f'  Created {out_clip} ({os.path.getsize(out_clip)} bytes)')

# 3. Concatenate video clips
print('\n=== 3. CONCATENATING VIDEO CLIPS ===')
concat_txt = os.path.join(work_dir, 'concat.txt')
with open(concat_txt, 'w', encoding='utf-8') as f:
    for c in rendered_clips:
        f.write(f"file '{c.replace(chr(92), '/')}'\n")

video_only = os.path.join(work_dir, 'video_only.mp4')
subprocess.run([ffmpeg, '-f', 'concat', '-safe', '0', '-i', concat_txt, '-c', 'copy', video_only, '-y'], check=True)
print('Video only assembled:', video_only, f'({os.path.getsize(video_only)} bytes)')

# 4. Mix Audio:
# User voice delayed by 3.5s (3500ms), amplified 2.2x so it peaks clearly at ~ -1.4dB
# Background music at volume 0.07 (-23dB) so it sits very softly underneath
print('\n=== 4. MIXING USER VOICE WITH SOFT BACKGROUND MUSIC ===')
filter_audio = (
    '[1:a]adelay=3500|3500,volume=2.2[voice];'
    '[2:a]volume=0.07[bgm];'
    '[voice][bgm]amix=inputs=2:duration=longest:dropout_transition=2[aout]'
)

cmd_final = [
    ffmpeg,
    '-i', video_only,
    '-i', voice_mp4,
    '-i', soundtrack_wav,
    '-filter_complex', filter_audio,
    '-map', '0:v',
    '-map', '[aout]',
    '-c:v', 'copy',
    '-c:a', 'aac',
    '-b:a', '192k',
    '-shortest',
    dest_day5,
    '-y'
]
subprocess.run(cmd_final, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
print('Exported to day_5:', dest_day5, f'({os.path.getsize(dest_day5)} bytes)')

# Copy to final_submission
shutil.copy2(dest_day5, dest_final)
print('Copied to final_submission:', dest_final, f'({os.path.getsize(dest_final)} bytes)')

print('\n=== 5. VERIFYING FINAL VIDEO ===')
probe = subprocess.run([ffmpeg, '-i', dest_final], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
for line in probe.stderr.splitlines():
    if any(k in line for k in ['Duration:', 'Stream #0:0', 'Stream #0:1']):
        print(' ', line.strip())

# Volume analysis
res_vol = subprocess.run([ffmpeg, '-i', dest_final, '-af', 'volumedetect', '-f', 'null', '-'], stderr=subprocess.PIPE, text=True)
for line in res_vol.stderr.splitlines():
    if 'mean_volume' in line or 'max_volume' in line:
        print(' ', line.strip())
