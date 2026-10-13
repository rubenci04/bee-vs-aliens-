#!/bin/bash
# LOTE 14: fine search of ROSTER_FIRE_SLOWDOWN on the nominal bot seed; prints the values where every pacing target holds.
cd /d/proyectos/bee_alien_3d
C=scripts/levels/bee_level_01_controller.gd
for v in "$@"; do
  sed -i "s/^const ROSTER_FIRE_SLOWDOWN := [0-9.]*/const ROSTER_FIRE_SLOWDOWN := $v/" $C
  out=$(bash dev/lote14/pacing.sh)
  dens=$(echo "$out" | sed -nE 's/.*density visible>=3: ([0-9]+) % · flyer\+ground: ([0-9]+) % · bullets: ([0-9]+) %.*/\1 \2 \3/p')
  hp=$(echo "$out" | sed -nE 's/.*min=([0-9]+) avg=([0-9.]+) damage_taken=([0-9]+) healed=([0-9]+).*/\1 \2 \3 \4/p')
  rev=$(echo "$out" | sed -nE 's/.*revives \(report mode only\)=([0-9]+)/\1/p')
  lag=$(echo "$out" | sed -nE 's/.*event_lag max=([0-9.]+) m.*/\1/p')
  tar=$(echo "$out" | sed -nE 's/.*tarantula_entry=([0-9.]+)s.*/\1/p')
  ok=$(echo "$dens $hp $rev $lag $tar" | awk '{ if ($1>=81 && $2>=72 && $3>=71 && $4>=32 && $4<=52 && $5>=58 && $5<=77 && $6>=100 && $8==0 && $9<=16 && $10>=335 && $10<=415) print "PASS"; else print "-" }')
  echo "slow=$v dens=[$dens] hp=[$hp] revives=$rev lag=$lag tarantula=$tar $ok"
done
