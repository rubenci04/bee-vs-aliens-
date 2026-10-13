"""Measure original MP3s without modifying assets; pass the ffmpeg executable."""
from pathlib import Path
import subprocess, sys, re, json
root = Path(__file__).resolve().parents[2]
results = {}
for path in sorted((root / 'audio').glob('*.mp3')):
    result = subprocess.run([sys.argv[1], '-hide_banner', '-i', str(path), '-af', 'volumedetect', '-f', 'null', '-'], capture_output=True)
    output = result.stderr.decode('utf-8', errors='replace')
    mean = float(re.search(r'mean_volume: ([-\d.]+)', output)[1])
    peak = float(re.search(r'max_volume: ([-\d.]+)', output)[1])
    results[path.name] = {'mean_db': mean, 'peak_db': peak, 'gain_db': round(-18.0 - mean, 1)}
print(json.dumps(results, ensure_ascii=True, indent=2))
(root / 'dev/lote15_music_measurement.json').write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding='utf-8')
