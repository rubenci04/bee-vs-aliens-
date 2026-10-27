# Tanda E2 — Moscas en grupo, escarabajo con cañón aéreo, Robot antiaéreo, intro con guía de controles, música

Rama `lote-16-titulo-intro`. Sin commit. No se tocó el aguijón estético ni el Polen de la E1.

## 1. Grupos de moscas
- `FlyCloud` pasa a **6 moscas** (`ENEMY_HEALTH.COMMON_HP`) y **9** desde X ≥ 240 (`FINAL_GROUP_SIZE`); máximo 2 grupos. `VISIBLE_LIMIT` 5 → 9 (sigue un solo MultiMesh opaco, sin sombras y un único callback por grupo).
- **14 HP por mosca** (`FLY_HP`). El grupo sigue contando una baja por mosca.
- Primera descarga **0,85 s** después de activarse (`FIRST_VOLLEY_SECONDS`), luego cada **2,2 s**; picada de 2 moscas cada **3,0 s**, aviso de 0,5 s intacto.
- Archivos: `bee_fly_cloud_settings.gd`, `bee_fly_cloud.gd`, `bee_enemy_health_settings.gd`, `bee_encounter_settings.gd`.

## 2. Escarabajo: bola de cañón aérea
- Nuevos `scripts/levels/beetle_cannon.gd` (componente que se añade al escarabajo en el controlador) y `beetle_cannonball.gd`.
- Cada 3,0 s **mientras camina** (estado IDLE): pide un cupo de `BeeCommonSlots`, pulso `COMMON_CUE` de 0,5 s y dispara desde el implante dorsal una bola hacia el punto (x de Bee, y ∈ [2,2; 4,8]). Si su embestida arranca durante el aviso, gana la embestida y se cancela la bola.
- Explota en el aire a los **0,75–0,95 s**: esfera visible de **1,5 m**, daño **8**, y **4 fragmentos** (daño 3, alcance **1,8 m**). La bola está en el grupo `alien_projectiles`, así que el Polen/escudo y la Nova la limpian antes de que explote.
- Se cambió `asset_fauna.gd`: **no**. Prefiero el componente aparte para no tocar la máquina de estados de 1 465 líneas; el pedido nombraba `asset_fauna.gd`, pero el efecto es el mismo.

## 3. Robot caminante
- `HOP_APEX` 1,5 → **3,5**, `JUMP_APEX` 3,4 → **4,4**, `BURST_SPEED` 6,5 → **10,0**. Cañón, ráfaga y láser ya apuntaban sin límite de ángulo (`_aim_direction` / láser desde el vector a Bee), no hizo falta cambiarlos.
- Si Bee pasa **más de 2,0 s por encima de Y = 3,2**, el siguiente ataque pasa a ser `hop` → `burst` → `jump` (rotando). Nunca dos seguidos: entre medias avanza el patrón normal, para que no desaparezcan cañón, morteros, láser y pisotón. `high_seconds` y `air_priority_picks` quedan expuestos para tests.
- Aviso de balance: Y = 3,2 es una altura de vuelo normal (rango ≈ 0,7–7,2), así que en la práctica el Robot responderá a casi cualquier Bee que vuele a media altura.

## 4. Intro de 4 s con «CÓMO JUGAR»
- Solo al empezar desde el principio: `BeeGameSettings.level_intro_pending` se activa en `BeeSceneFade.change` hacia el Nivel 1 (título/intro/resultados) y en el reinicio completo; un respawn de checkpoint la cancela (`resume_after_checkpoint`). F6 directo sobre la escena **no** muestra intro.
- Durante 4,0 s el controlador no avanza reloj ni scroll ni spawns; Bee se mueve y dispara libremente. Tarjeta `scripts/ui/bee_howto_card.gd`, texto según el último dispositivo (teclado o mando); se descarta con cualquier tecla/botón/clic a partir de 1,5 s, lo que además termina la intro.
- **Diferencias con lo pedido**: (a) no hay animación de «entrada» de Bee, aparece ya en pantalla; (b) puse los controles **reales**, no los del enunciado: Bomba = `C` (teclado) / `X` (mando), Disparo mando = `A / RT` (en el mando `X` es la bomba), y no existe «Espacio / Clic der.».

## 5. Música
- El valor por defecto ya era **25 %** música / **100 %** efectos (`MUSIC_DEFAULT_VOLUME`, Lote 15) y las barras de pausa nacen de esos valores; no hubo nada que cambiar en el código. Ojo: `user://audio_settings.cfg` **persiste** lo último que se deja en las barras (en esta máquina quedó `music=0.05`), y eso gana sobre el defecto; además `validate_bee_lote14_music_v01` escribe ese archivo. No lo toqué. Borrar el archivo devuelve el 25 %.

## Pruebas (headless)
| Prueba | Resultado |
|---|---|
| `validate_bee_tanda_e2` (nuevo: moscas 6/9, 14 HP, 0,85 s; bola explosiva; Robot; intro; música) | OK |
| `validate_bee_t6c_cloud`, `validate_bee_tanda_c_beetle`, `validate_bee_tanda_d_robot` (actualizados) | OK |
| `validate_bee_tanda_c_wasp`, `tanda_b`, `lote14_music_v01`, `lote14_controls_v01`, `tanda_e1_post_robot_to_tarantula` | OK |
| `validate_bee_walker_miniboss_v01` (bots expertos, `dev/lote15/walker.sh expert`) | OK: 110,5 / 85,6 / 80,9 / 70,5 s |
| `validate_bee_checkpoint_qol_v01` | Falla por escenario nulo en su carga (mismo defecto de fixture de los tests de jefes de la E1); no lo toqué |

Cambios en tests existentes: t6c (6/9, 14 HP, cadencias), beetle (permite bola/fragmentos, sigue prohibiendo piedras), robot D (constantes), walker (Bee a Y = 3,0 en el fixture de estructura para ejercitar el patrón base).

## Pendiente
- Playtest humano: ¿6 moscas de 14 HP duran demasiado? ¿el Robot se siente injusto con Bee alta? ¿la bola del escarabajo se ve y se esquiva?
- No corrí la suite completa. Los avisos `_register_pickup ... Cannot convert argument` aparecen al terminar `tanda_d_robot` (pickups liberados con una llamada diferida pendiente); no investigué si son anteriores a esta tanda.
