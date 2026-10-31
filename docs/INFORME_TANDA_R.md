# Tanda R — terreno limpio

- Base: `tanda-q-validar-g` (`1cbb3fd`). Rama: `tanda-r-terreno-limpio`. Plan: doc «Bee vs Alien — Plan 2: Bee protagonista».
- Sin commit, a propósito: las 6 PNG modificadas de `assets/ui/intro/` y `assets/ui/title/` (son de Rubén; decide él). Los `.uid` sueltos sí entraron.
- A, bug real (desde la Tanda O): un disparo cuyo tirador ya murió pasaba un objeto liberado a `take_boss_burst_damage(source: Node)`; salía `SCRIPT ERROR` y **el golpe se perdía**. Ahora `hurtbox_3d.gd` pasa `null` si el atacante ya no existe. Test: `validate_bee_tanda_r` (Bee 100 → 88, sin errores).
- B, tests rotos por N y O: `t7b_combo` (Frenesí una vez a x15), `tanda_d_tarantula` (la llamada de avispas espera si quedan vivas: 14,7–18 s), `lote15_gameplay` (el disparo Base es 3). En verde.
- La corrida completa destapó 11 suites más que rompieron las tandas F–Q sin que nadie lo viera. 10 eran expectativas viejas (G: 6 arañas, menos vida, bomba de miel con 5 m sin objetivo; I: hormiga sale del hormiguero, enemigo detrás de cámara se descarta en la ruta; K: 7 pickups y PrebossPower en X=282; P: teclado 3 s seguidos para cambiar la leyenda).
- Una era un fallo real de la Tanda G: una flor nueva en X=263 tocaba el hormiguero de X=265. Se movió a X=259,5 (`bee_level_01_garden_mushrooms.gd`).
- C, 25 suites viejas: 2 arregladas (`lote15_gameplay`, `tanda_c_ant`); 18 movidas a `tests/legacy_rojos/` con su causa en el README (mover, no borrar); 5 recorridos largos quedan en su lugar, fuera del núcleo.
- `docs/SUITES_NUCLEO.md` + `dev/tanda_r/run_nucleo.sh`: el núcleo que hay que correr antes de cada commit.
- D: `CLAUDE.md` y `AGENTS.md` al día y gemelos (remoto, ramas, controles reales de mando y teclado, tests, reglas). El texto viejo está en `docs/CLAUDE_HISTORICO.md`.
- Cambios de juego: solo el arreglo A y la flor movida. Ninguna vida ni daño cambió.
- Ojo: `tests/legacy_rojos/` incluye la prueba general del nivel, la de checkpoints y la del elenco. Conviene reescribirlas en una tanda propia; hoy no cubren nada.
- Cómo probar: abrí Godot 4.7.2, F5, Jugar. Dejate pegar por un disparo de una mosca que acabás de liberar: la vida tiene que bajar. Cerca de X=263 (zona de arañas) la flor ya no toca el hormiguero.
