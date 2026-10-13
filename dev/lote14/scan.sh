#!/bin/bash
# LOTE 14: scans ROSTER_FIRE_SLOWDOWN (arg list) over several bot seeds and prints min/avg HP, damage and revives per run.
cd /d/proyectos/bee_alien_3d
C=scripts/levels/bee_level_01_controller.gd
for v in "$@"; do
  sed -i "s/^const ROSTER_FIRE_SLOWDOWN := [0-9.]*/const ROSTER_FIRE_SLOWDOWN := $v/" $C
  for s in 1414 1 2 3; do
    r=$(bash dev/lote14/pacing.sh seed=$s | grep "HP before\|revives\|density visible" | sed -E 's/PACING //' | tr '\n' ' ' | sed -E 's/\(frames [0-9]+\) longest_quiet=[0-9.]+s//; s/HP before the robot gate: //; s/\(pollen bars.*\)//')
    echo "slow=$v seed=$s :: $r"
  done
done
