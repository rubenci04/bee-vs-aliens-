# Suites núcleo (desde la Tanda R)

Antes de cada commit hay que correr el núcleo y que todo dé PASS. Un `SCRIPT ERROR` cuenta como fallo aunque el código de salida sea 0.

## Comando

```bash
bash dev/tanda_r/run_nucleo.sh
```

Corre 4 suites a la vez y deja los logs en `dev/tanda_r/ultima_corrida/` (`_result.txt` tiene una línea por suite). Si Godot no está en la ruta de siempre:
`GODOT=/ruta/al/Godot_v4.7.2-stable_win64_console.exe bash dev/tanda_r/run_nucleo.sh`. Tarda unos 50 minutos en esta PC.

## Qué entra

Todo `tests/*/validate_*.gd`, **menos**:

- `tests/legacy_rojos/`: 18 suites con expectativas de un diseño viejo (ver su `README.md`).
- 5 recorridos largos que no terminan a tiempo y se corren a mano cuando se toca su jefe o el director:
  `validate_bee_boss_fight_v04`, `validate_bee_level01_arcade_director_v01`, `validate_bee_level01_transformation_v01`,
  `validate_bee_tarantula_boss_v01`, `validate_bee_walker_miniboss_v01`.

## Mientras trabajás

Corré solo las suites que toca tu cambio (`godot --headless --path . --script res://tests/levels/validate_<nombre>.gd`) y el núcleo completo una vez al final.
