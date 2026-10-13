#!/bin/bash
# LOTE 14: runs the pacing bot in report mode (prints the PACING lines; never fails on the targets).
cd /d/proyectos/bee_alien_3d
G="/c/Users/rea_0/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
timeout 900 "$G" --headless --fixed-fps 60 --path . --script res://tests/levels/validate_bee_pacing_v01.gd -- report "$@" 2>&1 | grep "PACING\|SCRIPT ERROR\|ERROR" | grep -v "events(index\|acts\|checkpoints\|scroll stopped\|frog\|camera-time\|material\|worst lags" | cut -c1-520
