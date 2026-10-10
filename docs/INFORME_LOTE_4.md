# INFORME LOTE 4 — COMBAT VARIETY 01

Rama `combat-variety-01` (desde `ufo-boss-01`). Paso 0: `master` adelantada por fast-forward a `ufo-boss-01` (fd90bed) y empujada a `origin`.

## Cómo está armado
- Cada patrón nuevo es un **modo opcional** del enemigo (`sting_fan_count`, `laser_every`, `ram_mode`, `mortar_mode`, `low_burst`, `split_orb`), apagado por defecto; **solo el Level 01 lo activa** (`LEVEL_TUNING` en `bee_level_01_controller.gd`). Los POC viejos siguen igual.
- Se reutilizan los proyectiles existentes (`AlienEnemyProjectile`, `BeeEnemyPatterns.fan_directions/spawn_shot`), la regla de no disparar fuera de pantalla (`BeeShmupFairness.can_fire`) y el token de "un patrón pesado a la vez" (`BeeAttackTokens`). Nuevo: `bee_attack_visuals.gd` (líneas, anillos, discos y áreas de daño por código, sin assets), `alien_mortar_shell.gd`, `alien_orb_splitter.gd`, `ufo_boss_mine.gd`.
- Parámetros en constantes al inicio de cada script.

## Parte A — enemigo → patrón nuevo → telegrafía
| Enemigo | Patrón nuevo | Telegrafía (antes de dañar) | Constantes |
|---|---|---|---|
| Avispa | 1 abanico corto de 3 tiros (13° entre sí) desde el implante; todas las avispas desde X=40 | carga cian del implante **0,45 s** | `wasp_enemy.gd`: `STING_FAN_STEP`, `sting_windup`, `sting_damage` 6 |
| Dron Ojo | Láser fino que **barre en vertical** ±20° a través de la altura de Bee (1 golpe, 10) | línea roja de inicio + línea tenue de fin, **0,70 s** | `eye_drone_enemy.gd`: `LASER_CHARGE`, `LASER_SWEEP` 0,75, `LASER_HALF_ARC`, `LASER_LENGTH` 9, `LASER_DAMAGE` |
| Speeder | Embestida recta hacia Bee (puede ser diagonal), luego **se retira** sin dañar a la derecha | parpadeo blanco + línea naranja que apunta a Bee y se **fija 0,25 s antes**, **0,75 s** | `speeder_enemy.gd`: `RAM_TELEGRAPH`, `RAM_LOCK`, `RAM_SPEED` 11, `RAM_DISTANCE`, `RETREAT_SPEED` |
| Torreta | Mortero en arco alto; al caer deja un **charco cian** breve (1,4 s, bajo) | anillo en el suelo bajo Bee desde el inicio de la carga: **~1,55 s** antes del impacto | `ground_turret_enemy.gd`: `MORTAR_FLIGHT`, `MORTAR_APEX`, `MORTAR_DAMAGE` 9, `PUDDLE_*` |
| Walker | Ráfaga **horizontal** de 3 tiros desde el cañón de la nuca (~2,6 m) y camina hacia Bee (mantiene 3 m); el barrido violeta sigue alternando | carga cian del cañón **0,60 s** | `ground_walker_enemy.gd`: `LOW_BURST_*` |
| Sonda | Orbe lento grande que a los 4 m **se divide en 2** (±24°) | carga habitual (0,45 s) + el orbe **se hincha y titila 0,45 s** antes de dividirse | `alien_probe_ranged.gd`: `ORB_*` |

Notas: el Dron Ojo usa ráfagas dirigidas hasta X=96 y el láser desde ahí (como antes los abanicos). Los drones que invoca el jefe **no** usan láser (solo ráfagas) para no apilar con minas y rayo.

## Parte B — Jefe UFO v2 (NODO ALIEN)
- **Lados:** vive en un lado de la pantalla (`side`). 1.er intento entra por la **derecha**, el reintento (respawn) por la **izquierda**, y así alterna. En cada cambio de fase **cruza al otro lado** (arco alto de 1,5 s, sin atacar y con el casco sin dañar). En fase 3 cambia de lado cada **6,5 s** (solo entre patrones).
- **Movimiento:** banda lateral más amplia (|x| 1,2…≈3,5 m del centro, ocho más ancho) y vertical ±1,3/1,4/1,5 m por fase. Durante la pelea **Bee puede usar todo el ancho** (antes solo los 2/3 izquierdos).
- **Minas:** flotan quietas con un anillo amarillo que se achica hasta el radio de explosión (dibujado todo el tiempo) y explotan en área: daño **12**, radio **1,5 m**. Fase 2: 2 minas, mecha **2,0 s**; fase 3: 3 minas, mecha **1,5 s**. Una cae donde estaba Bee y las demás a 2,4 m a los lados.
- **Drones:** entran rotando por **arriba, borde izquierdo y borde derecho** (antes salían todos del platillo).
- **Fases:** F1 ráfagas apuntadas · F2 minas + ráfagas + drones · F3 rayo tractor (marca 1 s) → minas rápidas → ráfaga de 4, más cambios de lado.
- **Barra:** "NODO ALIEN" con marcas al 66 % y 33 % y "FASE n / 3" debajo.
- **Se mantiene:** HP 500, F9 = arma Base + 2 bombas, respawn al inicio de la pelea con HP ≥ 60.

## Test de balance (nuevo `tests/levels/validate_bee_combat_variety_v01.gd`)
Verifica cada patrón por familia (y su telegrafía medida) y en el jefe: cada fuente de daño registrada (`hazards`) tuvo **≥ 0,4 s** de aviso; existen ráfaga, mina y rayo; minas de F3 más rápidas; cambios de lado; drones desde ≥2 puntos; el único daño sin aviso (contacto con el casco) **≤ 24** en una pelea guionada de ~32 s con Bee volando a 7 m/s; reintento desde la izquierda con HP completo; minas desactivadas al morir.
Medido: telegrafías avispa 0,47 s, láser 0,70 s, speeder 0,75 s, mortero ~1,55 s, walker 0,60 s, orbe 0,45 s. Jefe: 19 peligros, contacto sin aviso 12, 4 cambios de lado. Un bot que **no esquiva** recibió ~248 de daño en ~32 s (≈7,7 dps): orientativo.

## Dudoso de balance (constantes fáciles de tocar)
- **Minas F3** (`MINE_FUSE[PHASE_3]` 1,5 s, `MINE_COUNT` 3) y su anillo (`RING_START` 1,6 en `ufo_boss_mine.gd`): pueden saturar la pantalla junto con el rayo; si molesta, 2 minas o mecha 1,8 s.
- **Cambio de lado F3** (`SIDE_SWITCH_P3` 6,5 s): si se siente caótico, 8–9 s.
- **Láser del Ojo** (`LASER_HALF_ARC` 20°, `LASER_SWEEP` 0,75 s): es el patrón nuevo más exigente; si cuesta leerlo, 0,9 s de barrido.
- **Embestida del Speeder** (`RAM_SPEED` 11): rápida a propósito; el aviso dura 0,75 s.
- **Torreta** cooldown 1,1 → 1,3 s para compensar el charco.

## Tests ajustados
- `validate_bee_threat_camera_boss_v03`: la avispa "estándar" ahora se prueba antes de X=40; el aguijón dispara 3 en abanico.
- `validate_bee_ufo_boss_01`: fase 2 = cruce + minas; fase 3 = rayo + minas + ráfagas + cambios de lado (antes abanicos).
- `validate_bee_arcade_combat_patterns_v02`, `validate_bee_arcade_pressure_world_interaction_v01`, `validate_bee_level01_arcade_director_v01`, `validate_bee_shmup_fairness_v01`: verifican que el Level 01 aplica los modos nuevos y, donde comprobaban la mecánica vieja (ráfagas de la Sonda, abanicos del Ojo, abanico de la Torreta, ráfaga apuntada del Walker), fuerzan esos valores en la unidad de prueba: esa mecánica sigue existiendo (POCs, drones del jefe). El tiempo de "primer acecho" de la avispa ahora incluye el aguijón.

**Bug corregido de paso:** el aguijón de la avispa pisaba el temporizador del acecho (el acecho quedaba en ~1 s). Ya existía con las avispas que picaban antes; ahora se guarda y se restaura (`_stalk_resume` en `wasp_enemy.gd`).

## Capturas (`dev/visual_target/lote4_*.png`)
avispa (carga / abanico), ojo (carga / láser), speeder (destello / embestida), torreta (marca / proyectil / charco), walker (carga / ráfaga), sonda (orbe hinchado / división), jefe (fase 1 derecha, cruce fase 2, minas fase 3, reintento por la izquierda).

## Otros
- En el checkout hay trabajo **ajeno a este lote, sin trackear** (`tests/art/`, `scenes/art_labs/`, `scenes/ui/`, `scripts/art/`, `docs/art/`, `assets/models/future_biomes_*`, `art_source/blender/future_biomes_*`, `assets/style/future_lake_water.gdshader`). No lo toqué ni lo commiteé.
- Sin playtest humano: los números salen de tests y capturas.

**Resultado de la suite final:** 47/47 PASS (las 42 del proyecto + 5 suites ajenas sin trackear en `tests/art/`), headless, `SCRIPT ERROR` contado como fallo.
