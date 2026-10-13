"""Run each project validation once, retaining errors even when Godot exits 0."""
from pathlib import Path
import os, subprocess, time

ROOT = Path(__file__).resolve().parents[2]
GODOT = Path(r'C:\Users\rea_0\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe')
TIMEOUT_SECONDS = 180
REAL_TIME_TESTS = {'validate_toon_items_v01', 'validate_wasp_visual'}
env = dict(os.environ, APPDATA=str(ROOT/'dev/godot_user_lote10'))
tests = sorted((ROOT/'tests').rglob('validate_*.gd'))
results = []
started = time.monotonic()
with (ROOT/'dev/bee_hero_v02_full_suite.log').open('w', encoding='utf-8') as log:
    for test in tests:
        rel = test.relative_to(ROOT).as_posix()
        command = [str(GODOT), '--headless', '--path', str(ROOT)]
        if test.stem not in REAL_TIME_TESTS:
            command += ['--fixed-fps', '60']
        command += ['--script', 'res://'+rel]
        try:
            run = subprocess.run(command, cwd=ROOT, env=env, capture_output=True,
                                 timeout=TIMEOUT_SECONDS, creationflags=subprocess.CREATE_NO_WINDOW)
            output = (run.stdout+run.stderr).decode('utf-8', errors='replace')
            passed = run.returncode == 0 and 'SCRIPT ERROR' not in output
        except subprocess.TimeoutExpired as error:
            output = ((error.stdout or b'')+(error.stderr or b'')).decode('utf-8', errors='replace')
            output += '\nTIMEOUT\n'
            passed = False
        log.write('\n===== '+rel+' =====\n'+output)
        log.flush()
        results.append(('PASS' if passed else 'FAIL')+' '+rel)
failed = [r for r in results if r.startswith('FAIL')]
summary = f'{len(tests)-len(failed)}/{len(tests)} PASS; failures={len(failed)}; elapsed={time.monotonic()-started:.1f}s'
(ROOT/'dev/bee_hero_v02_full_suite_result.log').write_text(summary+'\n'+'\n'.join(results)+'\n', encoding='utf-8')
print(summary, flush=True)
for failure in failed:
    print(failure, flush=True)
raise SystemExit(1 if failed else 0)
