#!/bin/bash
cd /d/proyectos/bee_alien_3d
G="/c/Users/rea_0/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
timeout 900 "$G" --headless --fixed-fps 60 --path . --script res://tests/legacy_rojos/validate_bee_pacing_v01.gd -- report 2>&1 | grep "PACING\|SCRIPT ERROR" | grep -v "events(index\|acts\|checkpoints\|scroll stopped\|frog\|camera-time" | cut -c1-230
