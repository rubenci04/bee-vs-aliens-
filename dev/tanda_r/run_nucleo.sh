#!/bin/bash
# Tanda R: corre las suites núcleo (todo tests/*/validate_*.gd menos tests/legacy_rojos/ y los recorridos largos), 4 en paralelo.
# Uso: bash dev/tanda_r/run_nucleo.sh [carpeta_de_salida]   (por defecto dev/tanda_r/ultima_corrida, ignorada por git si así se quiere)
# Resultado por suite: PASS / FAIL(código) / SCRIPT_ERROR(n). Un SCRIPT ERROR cuenta como fallo aunque el código sea 0.
cd "$(dirname "$0")/../.."
OUT="${1:-dev/tanda_r/ultima_corrida}"; mkdir -p "$OUT"
G="${GODOT:-/c/Users/rea_0/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe}"
LONG="validate_bee_boss_fight_v04 validate_bee_level01_arcade_director_v01 validate_bee_level01_transformation_v01 validate_bee_tarantula_boss_v01 validate_bee_walker_miniboss_v01"
one() {
  t="$1"; n=$(basename "$t" .gd)
  timeout 600 "$G" --headless --path . --script "res://$t" > "$OUT/$n.log" 2>&1; rc=$?
  se=$(grep -c "SCRIPT ERROR" "$OUT/$n.log")
  if [ $rc -ne 0 ]; then echo "FAIL($rc) $n"; elif [ "$se" -gt 0 ]; then echo "SCRIPT_ERROR($se) $n"; else echo "PASS $n"; fi
}
export -f one; export OUT G
for t in tests/*/validate_*.gd; do
  case "$t" in tests/legacy_rojos/*) continue;; esac
  n=$(basename "$t" .gd); case " $LONG " in *" $n "*) continue;; esac
  echo "$t"
done | xargs -P 4 -I{} bash -c 'one {}' | sort > "$OUT/_result.txt"
echo "PASS: $(grep -c '^PASS' "$OUT/_result.txt") / $(wc -l < "$OUT/_result.txt")"
grep -v '^PASS' "$OUT/_result.txt"
