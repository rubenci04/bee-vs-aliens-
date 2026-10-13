#!/bin/bash
# LOTE 15: robot mini-boss bot fights in report mode (extra args go to the test: first, expert, trace).
cd /d/proyectos/bee_alien_3d
G="/c/Users/rea_0/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
timeout 900 "$G" --headless --fixed-fps 60 --path . --script res://tests/levels/validate_bee_walker_miniboss_v01.gd -- report "$@" 2>&1 | grep -E "MEASURE|WALKER|WOULD|SCRIPT ERROR|_OK"
