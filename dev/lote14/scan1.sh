#!/bin/bash
# LOTE 14: scans ROSTER_FIRE_SLOWDOWN (args) on the nominal bot seed only.
cd /d/proyectos/bee_alien_3d
C=scripts/levels/bee_level_01_controller.gd
for v in "$@"; do
  sed -i "s/^const ROSTER_FIRE_SLOWDOWN := [0-9.]*/const ROSTER_FIRE_SLOWDOWN := $v/" $C
  r=$(bash dev/lote14/pacing.sh | grep "HP before\|revives\|density visible\|event_lag" | sed -E 's/PACING //' | tr '\n' ' ' | sed -E 's/\(frames [0-9]+\) longest_quiet=[0-9.]+s//; s/HP before the robot gate: //; s/\(pollen bars.*\)//; s/\(events launched after their X\)//')
  echo "slow=$v :: $r"
done
