# INFORME LOTE 9 — Sensación de juego y balance (autónomo)

Rama base: `dev-04` (unifica `polish-03` = master + `level02-lake-proto` + `demo-prep-01`). Cada etapa tiene su rama hija,
encadenada: `dev-04` → `balance-04a` → `balance-04b` → `balance-04c`. Cada una se cerró con la suite completa verde,
commit y push.

## Decisiones tomadas sin poder preguntar (interpretación más razonable)
- **PASO 0 · archivos sin trackear:** `level02-lake-proto` commiteaba 15 archivos de Codex que en el disco estaban sin trackear
  (modelos/wrappers de la laguna, helecho, sapo). Eran **idénticos byte a byte** (hash) a los del commit; los aparté a un
  respaldo fuera del repo para que el merge pudiera escribirlos y verifiqué el hash después. No se perdió nada.
- **PASO 0 · conflicto:** solo en `docs/INFORME_NOCHE_01.md`; tomé la versión de `demo-prep-01` (es la más completa).
- **PASO 0 · caché de clases:** la primera corrida falló en la laguna porque la caché de clases globales no conocía las
  clases nuevas. Se arregló con `--import` (no es un cambio de código).
- **`scripts/game/bee_game_settings.gd` no estaba commiteado en ninguna rama** aunque el juego lo usa (dificultad, NOCHE 01):
  un clon desde GitHub no compilaba. Es código del juego (no de Codex): lo commiteé en `balance-04a`.
- **"11 animales":** los 10 de `ANIMAL_FAMILIES` (avispa, libélula, araña, mosquito, mariquita, libélula ondulante, polilla,
  hormiga, escarabajo, caracol) + el hongo cañón (tiene implante). **La luciérnaga no es enemigo** (es decoración, ver
  NOCHE 01), así que no tiene tiempo de liberación.
- **"Puntería normal" (referencia medible):** 3 toques/s de Base (10 HP). Sobre un animal los toques van cuerpo, implante (2×),
  cuerpo, fallo = 30 DPS efectivos. Sobre tecnología todos pegan a 1× = 30 DPS. La libélula controlada viene de frente y su
  esfera de implante cubre cabeza y tórax: sus toques van implante, implante, implante, fallo.
- **Auto-aim:** ahora apunta al **cuerpo** de los animales (1×); el 2× es un tiro deliberado con el mouse. Excepción: la
  libélula (por lo de arriba, su auto-aim sigue en el implante, como pedía su test).
- **La bomba** es daño de área: siempre 1× (nunca el 2× del implante) y una sola vez por animal aunque toque cuerpo e implante.
- **Unidades totales:** cuento todas las del recorrido, popcorn y oleadas de zona incluidas (antes 137; sin popcorn 104).
  Los minions del jefe quedan fuera (son parte de la pelea).
- **Enemigos simultáneos:** popcorn incluido. Tope 4 en el recorrido y 5 en las zonas.
- **Duración:** con 69 unidades el bot llegaba al jefe a los 295 s. Para volver al objetivo bajé el scroll de crucero
  1,5 → 1,25 m/s, cada zona dura al menos 22 s y el respiro tras una zona 6 → 7 s.

## ETAPA A — Liberar y dañar (`balance-04a`)
### 1. Todo impacto daña al implante
- `DamageHurtbox3D` (`scripts/components/hurtbox_3d.gd`) tiene `damage_multiplier` y un **punto débil opcional**: si la línea de
  vuelo del disparo pasa a menos de `weak_point_radius` del implante (plano X/Y), es un impacto directo (2×).
- **Fauna de Codex** (`asset_fauna.gd`): el área del cuerpo cubre todo el modelo (antes era un escudo neutro solo debajo del
  implante) y alimenta la misma salud del implante a 1×; el área del implante es 2×. La esfera del implante quedó acotada a
  `IMPLANT_RADIUS_MAX` 0,62 m (el cargador de la polilla la hacía de 1,4 m y tapaba todo el animal).
- **Libélula controlada:** el abdomen daña al implante a 1×, el implante 2×. **Avispa y araña:** un área, con el implante
  como punto débil (`WEAK_POINT_RADIUS` 0,32 m).
- Se conserva la telegrafía, la liberación (el animal nunca muere) y la explosión de la tecnología.

### 2. Tiempos de liberación (medidos con disparos simulados, NORMAL)
| Familia | HP antes → ahora | Disparos | Tiempo | Objetivo |
|---|---|---|---|---|
| Mosquito | 36 → 36 | 3 | 0,67 s | ~0,7 s |
| Avispa | 44 → 36 | 3 | 0,67 s | ~0,7 s |
| Mariquita | 130 → 70 | 6 | 1,67 s | 1,5-2,0 s |
| Hormiga | 44 → 64 | 6 | 1,67 s | 1,5-2,0 s |
| Polilla | 60 → 70 | 6 | 1,67 s | 1,5-2,0 s |
| Libélula controlada | 60 → 110 | 7 | 2,00 s | 1,5-2,0 s |
| Libélula ondulante | 56 → 64 | 6 | 1,67 s | 1,5-2,0 s |
| Hongo cañón | 60 → 70 | 6 | 1,67 s | 1,5-2,0 s |
| Araña | 90 → 80 | 7 | 2,00 s | ~2,0 s |
| Escarabajo | 110 → 120 | 11 | 3,33 s | 3-4 s |
| Caracol | 100 → 120 | 11 | 3,33 s | 3-4 s |
| Semillero alien | 240 → 220 | 22 | 7,00 s | 6-8 s |
| Speeder | 30 → 40 | 4 | 1,00 s | (tec.) ~1 s |
| Dron ojo | 40 → 50 | 5 | 1,33 s | (tec.) ~1,3 s |
| Sonda / Torreta / Caza alien | 80 / 70 / 60 → 70 | 7 | 2,00 s | (tec.) ~2 s |
| Walker | 120 → 100 (showcase 150 → 130) | 10 | 3,00 s | (tec.) ~3 s |

Los objetivos de la tecnología no venían en el pedido: los elegí por rol (ligera ~1 s, media ~2 s, pesada ~3 s).
Test: `tests/levels/validate_bee_balance_liberation_v04.gd` (regla 1×/2×, auto-aim al cuerpo, bomba 1×, tiempos).

### 3. Mariposas y polilla
- **Polilla:** sus 4 alas (nodos `FlightWing_*` del GLB) estaban modeladas planas y la cámara lateral las veía de canto. Ahora
  aletean sobre el eje del cuerpo (6,5 aleteos/s, 0,25-1,35 rad), el cuerpo sube en cada aleteo y se balancea (`FLAP`).
- **Mariposas decorativas:** aleteo 0,2-1,75 rad (antes 0,85-1,65, casi invisible de lado), ondulación vertical, giro suave
  hacia donde vuelan (antes saltaba entre 0 y 180°) y alabeo (`BUTTERFLY_*`).

### 4. Menos enemigos, mejor elegidos
- **69 unidades** (antes 137 con popcorn / 104 sin popcorn). Las 19 familias siguen apareciendo, menos veces. Popcorn 33 → 18.
- **Zonas de combate: 2 oleadas** (antes 3). Siguen los momentos, el gate de X=254 (y los de 296 y 340), los checkpoints
  (X=190 / 281) y la iluminación del día.
- **Simultáneos** (popcorn incluido): tope `MAX_ON_SCREEN` 4 en el recorrido y `MAX_ON_SCREEN_ARENA` 5 en las zonas.
- **Medido con el bot** (`validate_bee_pacing_v01`): jefe a los **347 s (5,8 min)**, nivel completo a 386 s; zonas de 22-23 s;
  respiro más largo 17 s; máximo simultáneo medido 4 en el recorrido y 5 en las zonas.
- Tests heredados actualizados (presupuesto 55-70 con zonas, 38 eventos, HP nuevos, espaciado máx. 20 m, profundidad 2
  entradas): `arcade_rebuild_v02`, `arcade_director_v01`, `pressure_world_interaction_v01`, `vertical_slice`,
  `challenge_balance_v01`, `combat_patterns_v02`, `threat_camera_boss_v03`, `asset_fauna_v01`, `controlled_fauna_v01`, `pacing_v01`.
- **Suite:** 76/76 PASS.

## ETAPA B — Disparos, ítems y legibilidad (`balance-04b`)
### 1. Disparos
- `scripts/vfx/bee_shot_palette.gd` (`BeeShotPalette`): **Bee** dispara una **bola de plasma redonda**: núcleo blanco
  (`BEE_SHOT_CORE`), halo dorado (`BEE_SHOT_COLOR` #ffb829) y estela corta de 0,12 s. La flecha toon de Codex queda oculta
  (no se modificó). **Enemigos**: orbe frío, núcleo cian pálido, halo cian (`ENEMY_SHOT_COLOR` #2eebff) y borde violeta
  (`ENEMY_SHOT_RIM`), estela cian corta; los del OVNI son 1,3× más grandes (`BOSS_SHOT_SIZE`). Separación de tono entre los
  dos bandos: 146°.
- Se aplica a **todo** proyectil enemigo del Level 01 y de la laguna (sonda, ojo, torreta, walker, avispa, popcorn, organismo,
  fauna de Codex, OVNI) al entrar al árbol (`node_added` conectado al nivel): no se tocó ninguna escena reutilizable ni los POC.
  Colisión, daño y velocidad sin cambios.
### 2. Cian = hostil
- `IMPLANT_GLOW` de la fauna de Codex 1,1 → 1,6 (se leía poco al atardecer).
- `scripts/vfx/bee_hostile_glow.gd` (`BeeHostileGlow`): al aparecer, si una unidad no tiene un brillo cian legible
  (`MIN_GLOW` 0,9) se le agrega un núcleo cian pulsante donde está su hurtbox. Lo necesitaron el **dron ojo, la torreta, el
  speeder, el walker, el semillero y el caza alien** (sus modelos texturizados no tenían cian propio).
- **La mira** se vuelve cian, crece, late y enmarca al hostil con corchetes cuando apunta a menos de 1,1 m de un enemigo
  (`BeeLevel01Crosshair.HOSTILE`, `HOVER_RADIUS`). El marcador de auto-aim ya era cian.
### 3. Ítems
- **La bomba da 3 bombas** (`bomb_pickup_charges` 3) hasta el tope `max_bomb_charges` **5** (antes +1 hasta 3). Con el tope
  lleno el ítem queda en el suelo.
- `scripts/vfx/bee_item_beacon.gd` (`BeeItemBeacon`): todo ítem del nivel (polen, Spread, bomba, curación, también los que
  aparecen después) lleva halo pulsante saturado, anillo de color con **contorno blanco** y una **columna de luz** suave.
  Colores lejos del ocre y del cian: **polen lima** #c7ff38, **Spread azul** #4d75ff, **bomba roja** #ff294d,
  **curación verde** #4dff6b.
### 4. Suministro antes del jefe
- `PREBOSS_SUPPLY` (`bee_level_01_vertical_slice.gd`): una bomba (+3) en X=337 y un tarro de miel en X=338,8, justo antes del
  gate de X=340. Se sigue sumando la ayuda dinámica que ya había durante el "último silencio".
### 5. Tests
- Nuevo `tests/levels/validate_bee_items_shots_v04.gd`: plasma de Bee (núcleo, halo, estela corta, flecha oculta), orbe enemigo
  y del OVNI, separación de colores, brillo cian de las 19 familias al atardecer, mira, +3 bombas y tope 5 (y el ítem queda),
  balizas en todos los ítems con halo que late, **contraste de color contra el suelo** (distancia RGB ≥ 0,45 y ≥ 30° de tono
  contra los 3 ocres del suelo) y entre ítems (≥ 45°), suministro previo al jefe.
- Medido: brillo cian al atardecer por familia = avispa 1,80 · sonda 1,91 · libélula 2,21 · araña 0,94 · fauna de Codex
  1,17-1,76 · el resto con el núcleo agregado 1,40 (mínimo exigido 0,9). Contraste contra el suelo: polen 0,60 / 43° ·
  Spread 0,81 / 162° · bomba 0,50 / 39° · curación 0,66 / 97°.
- Ajustados: `combat_vfx_v01` (estela corta), `weapons_powerups_v01` (+3 / tope 5), `checkpoint_qol_v01` (+3),
  `vertical_slice` (recolección con tope), `visual_polish_v02` (balizas y plasma son brillos sin toon a propósito).
- **Suite:** 77/77 PASS.

## ETAPA C — Jefe final (`balance-04c`)
### 1-2. Más vida y cuatro fases (`scripts/levels/ufo_boss_01.gd`)
| | Antes | Ahora |
|---|---|---|
| Vida | 500 | **1200** (`max_hp`; Fácil ×0,75 = 900) |
| Fases | 3 (66 / 33 %) | **4** (70 / 40 / 15 %, `PHASE_*_RATIO`); nunca se saltea una fase |
| Bomba | 32 (6 %) | **8 % de su vida** (`BOMB_FRACTION`, 96 HP) |
| Daño por golpe | disparo 8 · mina 12 · rayo 15 · casco 12 | disparo **2** · mina **5** · rayo **8** · casco **10** |

- **Fase 1 (100-70 %):** ráfagas apuntadas más rápidas (4 disparos cada 0,11 s a 7,8 m/s; antes 3 cada 0,14 s a 6,8 m/s)
  y un abanico apuntado cada tercer ataque.
- **Fase 2 (70-40 %): escudo cian.** Burbuja que absorbe los tiros (puff neutro) alimentada por **3 nodos** (2 al rearmarse)
  que barren el arco del platillo que mira a Bee, unidos por un cable cian. Mientras tanto alterna minas y ráfagas. Al romper
  todos los nodos el escudo cae **5 s** (`SHIELD_WINDOW`) y recibe **×2** (`WINDOW_DAMAGE_SCALE`; el rótulo dice
  "¡ESCUDO ABAJO!"); después parpadea 1,2 s (`SHIELD_REFORM`, aviso) y se rearma. Nodos: 16 HP (`SHIELD_NODE_HP`).
  Si Bee está dentro de la burbuja sus tiros salen igual. Los drones de la fase 2 desaparecieron (los minions quedan en la 3).
- **Fase 3 (40-15 %):** rayo tractor cada dos ataques (antes cada tres), minas más rápidas (mecha 1,25 s), cambio de lado cada
  4,5 s (antes 6,5). El rayo nunca cierra un carril mientras quedan minas colgando (eso queda para la furia). Sonda / organismo
  como minion (uno a la vez).
- **Fase 4 (< 15 %): FURIA.** Núcleo rojo, combo rayo + minas a la vez, abanicos y ráfagas de 5, cambio de lado cada 3,5 s.
- **Telegrafía:** todo ataque que daña avisa ≥ 0,42 s (ráfaga 0,42-0,5 s; abanico 0,45-0,6 s; minas 0,45 s de vuelo + mecha;
  rayo 0,85 s en fase 3 y 0,7 s en furia). El único daño sin aviso es tocar el casco.
### 3. Bombas
- `BeeAlienBomb` pregunta a la entidad (`bomb_damage_for`): el OVNI recibe el 8 % de su vida por bomba (96 de 1200).
### 4. Cinemática de muerte
- 8 explosiones encadenadas (0,22 s) mientras cae con una luz cian que crece, doble explosión principal más grande, destello
  blanco de pantalla, 1,3 s de resplandor (`DEATH_*`, total 3,4 s; antes ~2,3 s). Luego un cartel grande al centro:
  **"SECTOR DESPEJADO · LIBERADOS n/N"** (`bee_level_01_vertical_slice.gd`, `clear_banner`).
### 5. Tests
- Nuevo `tests/levels/validate_bee_boss_fight_v04.gd`: **bot** que pelea solo con Base, ~60 % de puntería (de cada 5 toques,
  3 al objetivo — nodo si hay escudo, minion si hay, si no el platillo — y 2 desviados) y que **esquiva a medias**: reacciona a
  todos los avisos pero la mitad de las veces tarde (a mitad del aviso), y de las balas que vienen hacia él solo intenta
  esquivar la mitad; nunca se queda quieto. Mide duración, daño recibido, daño sin aviso, telegrafía mínima, las 4 fases, la
  ventana del escudo y la bomba. Juega **3 peleas en Normal** (la media es la medida; tolerancia ±5) y una en Fácil.
  Corre a `time_scale` 2: a 4 con la máquina cargada se apilaban pasos de física y los hitbox (que se activan con
  `set_deferred`) se desfasaban, inflando el daño ~40 %.
- Actualizados: `ufo_boss_01` (fase 1 con abanicos, escudo y ventana, fase 4 con combo, bomba 8 %, muerte 3,4 s),
  `ufo_boss_nodo_v02` (escudo en vez de drones, telegrafía del rayo por fase), `threat_camera_boss_v03` (escudo en la fase 2,
  minions en la 3), `combat_variety_v01` (romper nodos antes de avanzar), y la vida 1200 en `arcade_rebuild_v02`,
  `transformation_v01`, `challenge_balance_v01`, `pressure_world_interaction_v01`, `combat_patterns_v02`. El bot de
  `pacing_v01` ahora apunta a los nodos con el escudo arriba y se ubica del lado libre durante el jefe.
- Accesor nuevo `UfoBossMine.spot()` (la mina vive en el origen; su posición real era privada).
- Medido con el bot (3 corridas completas de la suite, en paralelo con otras pruebas):

| Corrida | Normal: duración media (3 peleas) | Normal: daño medio | Peleas individuales | Fácil |
|---|---|---|---|---|
| 1 | 77,0 s | 52,3 | 78 s/44 · 77 s/51 · 75 s/62 | 53 s / 24 |
| 2 | 73,3 s | 42,3 | 75 s/47 · 74 s/34 · 70 s/46 | 52 s / 12 |
| 3 (sola, a time_scale 4, antes de fijarlo en 2) | 77,8 s | 52,3 | 78 s/51 · 77 s/44 · 78 s/62 | 58 s / 25 |

  Objetivo: 70-90 s y 40-60 de daño en Normal; Fácil bastante menos (12-25). Fases por tiempo (corrida 2): fase 1 ~21 s,
  fase 2 ~16 s (2 escudos, 2 ventanas), fase 3 ~20 s, furia ~11 s. Telegrafía mínima 0,42 s. Daño sin aviso: 0 en Normal
  (el bot no toca el casco); en Fácil 6 = un roce del casco al empezar. La bomba sacó exactamente el 8,0 %.
- **Suite:** 78/78 PASS (cuenta todos los `validate_*.gd` del disco, incluidos 2 tests toon sin trackear de Codex en `tests/bee_prototype/`).

## Valores configurables (resumen)
| Qué | Dónde | Valor |
|---|---|---|
| Multiplicadores de daño | `bee_liberation.gd` `IMPLANT_MULTIPLIER`, `BODY_MULTIPLIER`, `WEAK_POINT_RADIUS` | 2× · 1× · 0,32 m |
| Implante / punto débil de la fauna de Codex | `asset_fauna.gd` `IMPLANT_RADIUS_MAX`, `WEAK_RADIUS_RANGE`, `IMPLANT_GLOW` | 0,62 m · 0,22-0,32 m · 1,6 |
| HP del nivel (tiempos de liberación) | `bee_level_01_controller.gd` `LEVEL_HP`, `SHOWCASE_HP` | ver Etapa A · 130 |
| Aleteo de la polilla | `asset_fauna.gd` `FLAP` | 6,5 Hz · 0,25-1,35 rad |
| Vuelo de las mariposas | `bee_level_01_living_garden.gd` `BUTTERFLY_*` | 2,6 Hz · 0,2-1,75 rad |
| Simultáneos | `bee_level_01_controller.gd` `MAX_ON_SCREEN`, `MAX_ON_SCREEN_ARENA` | 4 · 5 |
| Ritmo | `LEVEL_SCROLL`, `ARENA_MIN_SECONDS`, `BREATHER_SECONDS` | 1,25 m/s · 22 s · 7 s |
| Colores de disparo | `bee_shot_palette.gd` `BEE_SHOT_COLOR`, `ENEMY_SHOT_COLOR`, `ENEMY_SHOT_RIM`, `*_RADII` | oro · cian · violeta |
| Brillo hostil mínimo | `bee_hostile_glow.gd` `MIN_GLOW` | 0,9 |
| Mira | `bee_level_01_crosshair.gd` `HOSTILE`, `HOVER_RADIUS` | cian · 1,1 m |
| Bombas | `bee_player.gd` `bomb_pickup_charges`, `max_bomb_charges` | 3 · 5 |
| Colores de ítems | `bee_item_beacon.gd` `COLORS`, `PULSE_HZ`, `COLUMN_*` | lima · azul · rojo · verde |
| Suministro antes del jefe | `bee_level_01_vertical_slice.gd` `PREBOSS_SUPPLY` | bomba X=337 · miel X=338,8 |
| Jefe | `ufo_boss_01.gd` `max_hp`, `PHASE_*_RATIO`, `BOMB_FRACTION`, `SHIELD_*`, `WINDOW_DAMAGE_SCALE`, `*_DAMAGE`, `DEATH_*` | 1200 · 70/40/15 % · 8 % · ver Etapa C |
| Nodos del escudo | `ufo_shield_node.gd` `ORBIT_SPEED`, `ARC_SWEEP`, `HIT_RADIUS` | 0,8 · 0,35 rad · 0,6 m |

## Capturas (`dev/visual_target/`)
Script: `dev/visual_target/capture_lote9.gd` (necesita ventana; argumento `before` / `after`).
- Antes: `lote9_before_{shots_day,shots_dusk,items_ground,items_dusk,implants_dusk,moth,boss}.png`.
- Después: lo mismo con `lote9_after_*` más `boss_shield`, `boss_shield_down`, `boss_fury`, `boss_death`, `sector_clear`.
- Las "antes" se tomaron con la Etapa A ya aplicada (no cambia disparos, ítems ni jefe).

## Qué quedó solo medido por tests y qué necesita playtest humano
- **Medido por tests / bot:** regla 1×/2× y bomba 1×, tiempos de liberación con disparos simulados, auto-aim al cuerpo,
  unidades (69) y familias, zonas de 2 oleadas, simultáneos (4 / 5 medidos), duración del nivel (jefe a 347 s = 5,8 min),
  aleteo (rangos de ángulo y balanceo), disparos (formas y colores), brillo cian al atardecer de las 19 familias, mira,
  +3 bombas y tope 5, balizas y contraste de color contra el suelo, suministro antes del jefe, las 4 fases, escudo y ventana,
  telegrafía ≥ 0,4 s, daño sin aviso, bomba 8 %, duración y daño de la pelea con el bot, cinemática y cartel final.
- **Necesita playtest humano:**
  - si el nivel con 69 enemigos y scroll 1,25 m/s se siente vacío o lento (el bot ve 198 s sin amenazas de 347; el respiro más
    largo es 16 s);
  - si el 2× al implante se nota como recompensa (tiro con mouse) y si el auto-aim al cuerpo convence;
  - el aleteo de la polilla y las mariposas en movimiento (las capturas son estáticas);
  - si la bola de plasma de Bee y el orbe enemigo se distinguen en plena pelea, y si los anillos/columnas de los ítems
    ensucian la escena;
  - **el jefe**: el bot "esquiva a medias" es un modelo; un humano puede esquivar mejor o peor (las peleas individuales del bot
    van de 34 a 62 de daño). Revisar si el daño por bala (2) se siente demasiado bajo y si la fase del escudo se entiende sin
    leer el rótulo;
  - la dificultad FÁCIL con el jefe nuevo.

## Ramas de este lote
`dev-04` (merges) → `balance-04a` → `balance-04b` → `balance-04c` (cadena lineal). `master` quedó adelantada por fast-forward
hasta `balance-04c` y pusheada (ver el chat del lote para el hash final).
