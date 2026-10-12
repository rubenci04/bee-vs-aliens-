#!/bin/bash
# usage: run_suite.sh <label> [test-name-substring...]  -> dev/<label>_suite_result.log
cd /d/proyectos/bee_alien_3d
G="/c/Users/rea_0/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
L=$1; shift
OUT=dev/${L}_suite_result.log; : > $OUT
pass=0; fail=0
for t in $(ls tests/*/validate_*.gd); do
  if [ $# -gt 0 ]; then m=0; for s in "$@"; do [[ $t == *$s* ]] && m=1; done; [ $m = 0 ] && continue; fi
  n=$(basename $t .gd); fps="--fixed-fps 60"
  [[ $n == validate_toon_items_v01 || $n == validate_wasp_visual ]] && fps=""
  timeout 900 "$G" --headless $fps --path . --script res://$t > dev/${L}_log_$n.log 2>&1; rc=$?
  se=$(grep -c "SCRIPT ERROR" dev/${L}_log_$n.log)
  if [ $rc -eq 0 ] && [ $se -eq 0 ]; then pass=$((pass+1)); echo "PASS $n" >> $OUT; else fail=$((fail+1)); echo "FAIL $n rc=$rc script_errors=$se" >> $OUT; fi
done
echo "TOTAL pass=$pass fail=$fail" >> $OUT
