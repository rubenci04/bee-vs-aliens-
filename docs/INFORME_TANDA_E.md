# Tanda E — atasco post-robot, ritmo de zonas y escarabajo con granadas

Rama `tanda-e-ritmo-escarabajos` (creada desde `lote-16-titulo-intro`, 0cc44b6; el trabajo sin commitear de las Tandas E1/E2 viaja con ella, con acuerdo del usuario).

## 1. Atasco tras matar al robot

**Causa real** (reproducida con `dev/tanda_e/repro_post_robot.gd`, registro por segundo): el gate del robot (`_hard_gate`) solo se libera cuando `active_units` y `_pending` están vacíos, y `_advance_tarantula` solo corre con todas las colas vacías. Si tras la muerte del robot queda **cualquier escolta viva** (avispa o mosca; desde la Tanda B nada las retira ni las expira), o un pedido pendiente que no se lanza, el gate queda cerrado, `scroll_speed = 0`, la calma de 5,5 s nunca empieza y la tarántula no entra (40 s de registro: `gate=true`, `breather=-1`, cámara fija en 294). Con todo muerto la tarántula entraba a los 6 s: no había error de script, ni problema de `begin()`, ni de la cámara. Los potenciadores quedaban "trabados" a la vista porque la cámara no avanzaba, y `BombRecharge` (X=302) caía en el borde izquierdo de la pantalla final (cámara 309,4).

**Arreglo** (`bee_level_01_controller.gd`):
- `_on_robot_defeated`: los pedidos pendientes del gate se descartan y las escoltas caen con el robot (como los minions del UFO; se liberan, también las que estaban teletransportándose: se les quita la protección).
- Red de seguridad: si a los `POST_ROBOT_FORCE_SEC` = 8 s de la muerte la calma no empezó, se libera lo que sostenga el gate (se limpian unidades, se baja el gate) y se fuerza la secuencia con una calma corta (`POST_ROBOT_FORCED_CALM_SEC` = 3,5 s): 8 + 3,5 < 12 s.
- Provisiones: Spread, Bomba y cura aparecen **donde termina el avance** (relativas a `_post_robot_target_x`, `POST_ROBOT_PICKUP_OFFSETS` = (-3; 0,5; 4)), en pantalla cuando la cámara se detiene. `BombRecharge` pasa de X=302 a `BOMB_RECHARGE_X` = 306 (solo en roster).

**Test de regresión** `tests/levels/validate_bee_tanda_e_post_robot.gd`: escoltas vivas, solo escoltas, todo muerto, Bee herida y pedidos en cola: la tarántula entra a los 5,6 s de juego en todos; con una escolta imposible de matar (red de seguridad) a los 11,5 s. Además comprueba los medallones a la vista.

## 2. Ritmo (bot limpiador: cada enemigo muere 6 s después de aparecer; `dev/tanda_e/measure_pacing.gd`)

| | Antes | Después |
|---|---|---|
| Nube (E33): oleadas internas / grupos de moscas | 7 / 16 | 2 / 5 |
| Escarabajos (E56): oleadas internas / unidades de la zona | 7 / 22 | 3 / 10 |
| Arañas: oleadas internas / unidades de la zona | 7 / 20 | 4 / 11 |
| Tramo X=227–259: eventos / unidades | 12 / 28 | 7 / 16 |
| Unidades lanzadas hasta el robot (bot) | 467 | 358 |
| Segundos de zona (nube / escarabajos / arañas) | 58 / 36 / 40 | 18 / 21 / 24 |
| **Segundos hasta que sale el robot** | **523,7** | **423,2 (−19 %)** |

Notas honestas: el bot limpiador es más rápido que una persona, así que los segundos por zona (18-24 s) quedan por debajo del objetivo de 45-60 s; la bajada relativa de cada zona es de 55-70 %. El bot experto de `validate_bee_pacing_v01.gd` ya no completa el nivel en este árbol (muere a los ~390 s sin mi cambio de tabla; es de la Lote 14, anterior a las zonas bloqueantes de la Tanda B), así que no pude usarlo para esta tabla.
- Se dejó el evento X=227 (se quitan 5 de los 12, no 6): sin él quedaba un tramo vacío de 21 m tras la zona de escarabajos. El debut del gusano de compost (X=235–241,7) se conserva.
- Refuerzos: solo si quedan menos de 2 enemigos y pasaron `EXTRA_ARRIVAL_SECONDS` = 30 s (`REINFORCE_BELOW` = 2, se reintenta cada `REINFORCE_RECHECK_SECONDS` = 4 s).

## 3. Escarabajo con granadas

Disparan apenas entran en pantalla: **primer disparo a 0,73 s** de materializarse (límite 1,5 s). Recarga lenta, **4-5 s de lanzamiento a lanzamiento**; el cronómetro corre también durante la embestida (la embestida queda como tercera acción: su primera espera `FIRST_RAM_AFTER` = 2,5 s para que la primera granada salga antes). Aviso de 0,5 s (pulso del enemigo), un cupo de `BeeCommonSlots` mientras se compromete (máx. 2 atacantes), vida 51 sin cambios. Dos armas que se **alternan**:
- **Temblor** (`BeetleGrenade`, `quake`): granada en arco (1,1 s, cúspide 3,2 m) que cae en el suelo a la X de Bee; explota con **dos ondas grandes** de `BeeGroundShockwave` (una hacia cada lado, 2,2 m de alto x 1,5 m de ancho, 6,5 m/s, **8 de daño**), marrón/naranja quemado con corona oscura. Se responde volando por encima.
- **Abanico** (`fan`): granada en el aire cerca de Bee; al explotar suelta **3 disparos** (`BeetleShard`, 4 de daño, 6 m/s) hacia Bee en abanico fino de ±9°. Naranja quemado con núcleo oscuro.
Sonidos: solo claves ya aprobadas (`organic_charge` al lanzar, `wasp_overload` al explotar). Todo está en `alien_projectiles` (la Nova y el escudo de polen lo limpian).
`BeeGroundShockwave.launch` ganó parámetros opcionales de color y ancho (valores por defecto = onda de plasma del robot, sin cambios). `beetle_cannonball.gd` (Tanda E2) ya no se usa en el juego pero se conserva con su test.

Test `tests/levels/validate_bee_tanda_e_beetle.gd`: primer disparo, recarga, alternancia, onda (2 ondas, 8 de daño, tamaño, colores), 3 disparos (ángulos, daño, colores), aviso 0,5 s, tope de 2 atacantes y daño real a una Bee en el suelo. `validate_bee_tanda_c_beetle.gd` ya no espera la bala de cañón.

## 4. Constantes nuevas
`BeeGameSettings`: `POST_ROBOT_FORCE_SEC`, `POST_ROBOT_FORCED_CALM_SEC`, `POST_ROBOT_PICKUP_OFFSETS` (ahora relativas). `BeeEncounterSettings`: `REINFORCE_BELOW`, `REINFORCE_RECHECK_SECONDS`. `BeeLevel01Controller`: `BOMB_RECHARGE_X`. `BeetleCannon`: `FIRST_DELAY`, `FIRST_RAM_AFTER`, `RECHARGE_MIN/MAX`, `WARNING`, `RETRY`, `FAN_*`. `BeetleGrenade`: `WAVE_*`, `FAN_*`, `FLIGHT_TIME`, `APEX`.

## 5. Cómo probar
1. F5, Jugar, y con **F9** (salto de debug al jefe) o jugando hasta X=294: matar al robot **dejando escoltas vivas**. Esperado: las escoltas explotan con él, la cámara avanza ~una pantalla, aparecen Spread, Bomba y cura a la vista y a los pocos segundos entra la tarántula (nunca más de ~12 s).
2. Zona de escarabajos (X≈214): al entrar en pantalla, a ~1 s tira una granada con aviso; alterna onda grande (volar por encima) y abanico de 3 disparos; cada 4-5 s.
3. Zona de nube (X=138), escarabajos y arañas: ahora 2, 3 y 4 oleadas internas.

## 6. Suite
Ver el final de este documento.

## Suite completa (156 `validate_*`, 4 en paralelo, headless)
Primera pasada: 106 PASS / 50 con fallo. Lo que arreglé (tests, sin tocar jefes ni HUD): 27 tests usaban `root.get_child(último)` como escena actual y la cubierta `SceneFade` (Tanda E2) ahora se agrega después; cambié esa línea para ignorarla (corrigió unos 25 fallos); `validate_bee_pacing_v01` igual; los tests de cantidades (zonas 2-7 oleadas, ≥160 unidades, ≥74 eventos), medallones post-robot, escoltas liberadas con el robot, `BombRecharge`, `validate_bee_tanda_c_beetle`, `..._e2`. Tests nuevos: `validate_bee_tanda_e_post_robot` y `validate_bee_tanda_e_beetle` (PASS). Pasan tras los cambios: tanda_b, tanda_c_beetle, tanda_d_rewards, tanda_e1, t6c_cloud, second_checkpoint, tanda_e_post_robot, tanda_e_beetle.

**La suite NO está en verde** (por eso no hice commit, según la regla del proyecto). Siguen fallando 43 suites; por el mensaje de error ninguna toca el código que cambié, pero **no las comparé contra un estado base limpio** (el árbol ya traía trabajo sin commitear de E1/E2, así que no hay base limpia): 
- validate_alien_probe_visual
- validate_bee_arcade_combat_patterns_v02
- validate_bee_arcade_pressure_world_interaction_v01
- validate_bee_arcade_rebuild_v02
- validate_bee_asset_fauna_v01
- validate_bee_audio_basic_v01
- validate_bee_balance_liberation_v04
- validate_bee_boss_fight_v04
- validate_bee_checkpoint_qol_v01
- validate_bee_combat_poc
- validate_bee_combat_vfx_v01
- validate_bee_controlled_fauna_v01
- validate_bee_fauna_facing_v01
- validate_bee_flight_poc
- validate_bee_free_aim_v01
- validate_bee_garden_toad_v01
- validate_bee_items_shots_v04
- validate_bee_level01_arcade_director_v01
- validate_bee_level01_challenge_balance_v01
- validate_bee_level01_roster_v01
- validate_bee_level01_transformation_v01
- validate_bee_level_01_vertical_slice
- validate_bee_liberation_v01
- validate_bee_lote11_juice_v01
- validate_bee_lote13_combat_v01
- validate_bee_lote14_music_v01
- validate_bee_lote15_gameplay_v01
- validate_bee_mission_01
- validate_bee_pacing_v01
- validate_bee_readability_v03
- validate_bee_shmup_air_ground_poc
- validate_bee_shmup_ground_threat_poc
- validate_bee_shmup_organic_alien_poc
- validate_bee_t3k
- validate_bee_tanda_c_ant
- validate_bee_tarantula_boss_v01
- validate_bee_threat_camera_boss_v03
- validate_bee_ufo_boss_01
- validate_bee_ufo_boss_nodo_v02
- validate_bee_visual_polish_v02
- validate_bee_walker_miniboss_v01
- validate_toon_projectiles_v01

Causas típicas vistas: expectativas viejas (volumen del bus de música, valores del aguijón, auto-aim, brillos, `PollenM` que ya no existe), harnesses de nivel completo que esperan el UFO o que no limpian las zonas bloqueantes, y los bots de jefes (`tarantula_boss_v01`: el bot experto no libera a la tarántula, daño 796 contra 55-80; `walker_miniboss_v01`: pasa todas las comprobaciones hasta la matriz de duración pero no termina dentro del tiempo del test). No toqué vida/daño de jefes.

### Segunda ronda (arreglo de suites viejas)
Se actualizaron expectativas viejas en ~25 tests (daño del disparo Base 10→3, tamaño de ventana headless para el apuntado asistido, aguijón que necesita la física de Bee, aviso de 0,5 s, pantalla de resultados, avispa persistente, `PollenM`, volumen guardado de música) y se agregó el flag de test `BeeLevel01Controller.instant_arrival` (los enemigos aparecen activos sin teletransporte). Pasaron de 43 a 25 las suites que fallan. Siguen fallando (cada una arrastra una cadena de números de balance/diseño ya superados, p. ej. Spread 8 de daño, vuelta automática a Base, duración del UFO, `Ant` que embiste, objetos de Tanda D):
- validate_bee_arcade_combat_patterns_v02
- validate_bee_arcade_pressure_world_interaction_v01
- validate_bee_arcade_rebuild_v02
- validate_bee_balance_liberation_v04
- validate_bee_boss_fight_v04
- validate_bee_checkpoint_qol_v01
- validate_bee_controlled_fauna_v01
- validate_bee_fauna_facing_v01
- validate_bee_garden_toad_v01
- validate_bee_level01_arcade_director_v01
- validate_bee_level01_challenge_balance_v01
- validate_bee_level01_roster_v01
- validate_bee_level01_transformation_v01
- validate_bee_level_01_vertical_slice
- validate_bee_liberation_v01
- validate_bee_lote11_juice_v01
- validate_bee_lote13_combat_v01
- validate_bee_lote15_gameplay_v01
- validate_bee_mission_01
- validate_bee_pacing_v01
- validate_bee_t3k
- validate_bee_tanda_c_ant
- validate_bee_tarantula_boss_v01
- validate_bee_walker_miniboss_v01
- validate_toon_projectiles_v01
