import os
import subprocess
import shutil

ffmpeg = r'C:\Users\umair\AppData\Local\Microsoft\WinGet\Links\ffmpeg.exe'

work_dir = r'C:\Users\umair\AppData\Local\Temp\cc_showcase_1795162862478'
video_no_audio = os.path.join(work_dir, 'showcase_no_audio.mp4')
soundtrack_wav = os.path.join(work_dir, 'soundtrack.wav')
voice_mp4 = r'C:\Users\umair\.gemini\antigravity\brain\1ae6a110-f689-4500-826f-ec7e60194096\.user_uploaded\media_1795163866286_3a6e97e5.mp4'

dest_day5 = r'D:\Internship daily projects\care_connect\evidence\day_5\CareConnect_Weekly_Final_Showcase.mp4'
dest_final_dir = r'D:\Internship daily projects\care_connect\evidence\final_submission'
os.makedirs(dest_final_dir, exist_ok=True)
dest_final = os.path.join(dest_final_dir, 'CareConnect_Weekly_Final_Showcase.mp4')

print('=== 1. PREPARING AUDIO STREAMS ===')
print('Video source:', video_no_audio, os.path.exists(video_no_audio))
print('Soundtrack source:', soundtrack_wav, os.path.exists(soundtrack_wav))
print('User voice source:', voice_mp4, os.path.exists(voice_mp4))

# Filter complex:
# 1. Take voice from voice_mp4 (stream 0:a / 1:a), delay 6s (6000ms), boost volume 2.2x to make it prominent
# 2. Take background music from soundtrack_wav, set volume to 0.10 (-20dB) so it remains soft underneath
# 3. Mix both streams together using amix
# 4. Map video and mixed audio into final mp4, copying video stream without re-encoding
filter_complex = (
    '[1:a]adelay=6000|6000,volume=2.2[voice];'
    '[2:a]volume=0.10[bgm];'
    '[voice][bgm]amix=inputs=2:duration=longest:dropout_transition=2[aout]'
)

cmd = [
    ffmpeg,
    '-i', video_no_audio,
    '-i', voice_mp4,
    '-i', soundtrack_wav,
    '-filter_complex', filter_complex,
    '-map', '0:v',
    '-map', '[aout]',
    '-c:v', 'copy',
    '-c:a', 'aac',
    '-b:a', '192k',
    '-shortest',
    dest_day5,
    '-y'
]

print('\n=== 2. RUNNING FFMPEG MIX ===')
res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
if res.returncode != 0:
    print('FFmpeg Error:', res.stderr[-1000:])
    raise RuntimeError('FFmpeg failed to mix video and audio')

print('Successfully exported to day_5:', dest_day5)
size_day5 = os.path.getsize(dest_day5)
print(f'Size: {size_day5 / (1024*1024):.2f} MB ({size_day5} bytes)')

# Copy to final_submission
shutil.copy2(dest_day5, dest_final)
print('Successfully copied to final_submission:', dest_final)
size_final = os.path.getsize(dest_final)
print(f'Size: {size_final / (1024*1024):.2f} MB ({size_final} bytes)')

print('\n=== 3. VERIFYING STREAMS & DURATION ===')
probe = subprocess.run([ffmpeg, '-i', dest_final], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
for line in probe.stderr.splitlines():
    if any(k in line for k in ['Duration:', 'Stream #0:0', 'Stream #0:1']):
        print(' ', line.strip())
