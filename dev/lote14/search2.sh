#!/bin/bash
# LOTE 14: runs the pacing test itself (assert mode) for each ROSTER_FIRE_SLOWDOWN value given and prints PASS or the failing check.
cd /d/proyectos/bee_alien_3d
G="/c/Users/rea_0/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
C=scripts/levels/bee_level_01_controller.gd
for v in "$@"; do
  sed -i "s/^const ROSTER_FIRE_SLOWDOWN := [0-9.]*/const ROSTER_FIRE_SLOWDOWN := $v/" $C
  out=$(timeout 900 "$G" --headless --fixed-fps 60 --path . --script res://tests/levels/validate_bee_pacing_v01.gd 2>&1)
  if echo "$out" | grep -q "SCRIPT ERROR"; then echo "slow=$v FAIL: $(echo "$out" | grep '^ERROR' | grep -v material | head -1)"; else echo "slow=$v PASS $(echo "$out" | grep 'HP before' | sed -E 's/PACING HP before the robot gate: //')"; fi
done
