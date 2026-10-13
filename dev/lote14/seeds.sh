#!/bin/bash
# LOTE 14: runs the pacing test (assert mode) with several bot seeds and prints PASS / the failing check for each.
cd /d/proyectos/bee_alien_3d
G="/c/Users/rea_0/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
for s in "$@"; do
  out=$(timeout 900 "$G" --headless --fixed-fps 60 --path . --script res://tests/levels/validate_bee_pacing_v01.gd -- seed=$s 2>&1)
  if echo "$out" | grep -q "SCRIPT ERROR"; then echo "seed=$s FAIL: $(echo "$out" | grep '^ERROR' | grep -v material | head -1)"; else echo "seed=$s PASS $(echo "$out" | grep 'HP before' | sed -E 's/PACING HP before the robot gate: //')"; fi
done
