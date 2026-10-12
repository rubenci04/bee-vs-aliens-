#!/bin/bash
cd /d/proyectos/bee_alien_3d
G="/c/Users/rea_0/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
: > dev/lote12/lotes_status.log
for l in "$@"; do
  echo "== $l move" >> dev/lote12/lotes_status.log
  dev/lote12/move_assets.sh dev/lote12/map_$l.txt >> dev/lote12/lotes_status.log 2>&1
  timeout 400 "$G" --headless --path . --import > dev/lote12/import_$l.log 2>&1
  dev/run_suite.sh lote12_$l tests/art/ level_01_vertical_slice garden_identity asset_fauna level02_lake toon_items toon_projectiles combat_vfx
  if grep -q "^FAIL" dev/lote12_${l}_suite_result.log; then
    echo "== $l FAILED -> reverting" >> dev/lote12/lotes_status.log
    grep "^FAIL" dev/lote12_${l}_suite_result.log >> dev/lote12/lotes_status.log
    dev/lote12/move_assets.sh dev/lote12/map_$l.txt --reverse >> dev/lote12/lotes_status.log 2>&1
    timeout 400 "$G" --headless --path . --import > dev/lote12/import_${l}_rev.log 2>&1
  else
    echo "== $l OK" >> dev/lote12/lotes_status.log
  fi
done
echo DONE >> dev/lote12/lotes_status.log
