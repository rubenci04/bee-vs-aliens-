#!/bin/bash
# LOTE 14: runs the pacing bot (report + trace) and prints the damage it took by enemy family, plus the headline metrics.
cd /d/proyectos/bee_alien_3d
G="/c/Users/rea_0/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
timeout 900 "$G" --headless --fixed-fps 60 --path . --script res://tests/levels/validate_bee_pacing_v01.gd -- report trace 2>&1 | grep "BOT_HIT\|PACING density visible\|PACING event_lag\|PACING HP\|PACING revives\|PACING boss_entry\|PACING robot" > /tmp/hits.txt
grep BOT_HIT /tmp/hits.txt | sed -E 's/BOT_HIT ([A-Za-z]+)_?[^ ]* -([0-9]+) .*/\1 \2/' | awk '{c[$1]+=$2; n[$1]++} END{for(k in c) print k, "total", c[k], "hits", n[k]}' | sort -k3 -n -r
grep -v BOT_HIT /tmp/hits.txt
