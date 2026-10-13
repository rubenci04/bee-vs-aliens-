#!/bin/bash
# LOTE 15: tarantula bot fights in report mode (extra args go to the test: first, expert, trace).
cd /d/proyectos/bee_alien_3d
G="/c/Users/rea_0/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
timeout 1500 "$G" --headless --fixed-fps 60 --path . --script res://tests/levels/validate_bee_tarantula_boss_v01.gd -- report "$@" 2>&1 | grep -E "MEASURE|TARANTULA|WOULD|SCRIPT ERROR|_OK" | grep -v "timeline"
