#!/bin/bash
# Regenerates the GRADUAL EVENTS_ROSTER table and splices it into the level controller (LOTE 13 dev tool).
cd /d/proyectos/bee_alien_3d
G="/c/Users/rea_0/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
"$G" --headless --path . --script res://dev/lote14/_gen_events.gd 2>&1 | grep -i "wrote\|error"
c=scripts/levels/bee_level_01_controller.gd
a=$(grep -n "^const EVENTS_ROSTER = \[" $c | cut -d: -f1)
b=$(grep -n "^## LOTE 12 · ETAPA 2: Level 1 plays only its roster" $c | cut -d: -f1)
{ head -$a $c; cat dev/lote14/events_roster.txt; printf ']\n\n'; tail -n +$b $c; } > /tmp/controller_new.gd && cp /tmp/controller_new.gd $c
"$G" --headless --path . --import 2>&1 | grep -i "parse error" | head -3
