# Auditoría de assets (Lote 12, etapa 1)

Fecha: 2026-10-12. Contrastada contra `LEVEL_01_ROSTER.md` (manda) y `ASSET_CHECKLIST_BY_LEVEL.md`. Datos medidos leyendo cada GLB (triángulos = suma de las mallas instanciadas por los nodos; implante = nodos cuyo nombre contiene implant/device/AlienControl; «casi blanco» = material sin textura con luminancia > 0,8) y buscando referencias estáticas `res://` desde escenas, scripts y tests. «En uso» = lo referencia el juego (no un laboratorio) directamente o a través de su escena de laboratorio.

Presupuesto (de `ASSET_REQUEST_TEMPLATE.md`): enemigo común ~5.000 triángulos; jefe/montura ≤ 12.000. Para entorno/props se usó ≤ 12.000 como tope de aviso.

## Resumen

| Destino | GLB | En uso |
|---|---|---|
| Nivel 1 (jardín) | 45 | 23 |
| Nivel 2 (laguna; carpeta `level_02_lake`) | 27 | 9 |
| Nivel 3 (bosque) | 11 | 6 |
| Nivel 4 (cielo) | 8 | 0 |
| Nivel 5 / 6 | 0 | — |
| Nivel 7 (espacio) | 3 | 0 |
| shared (bee 2, alien_tech 6, pickups 4, projectiles 2) | 14 | 11 |
| `_unassigned` (costa 3, humano 1) | 4 | 1 |
| **Total** | **112** | |

- **Piezas blancas:** una sola, `hipster_poc` (1 material casi blanco, camisa/zapatillas del humano gigante; hoy apagado). Ninguna pieza blanca en los GLB de nivel.
- **Material roto:** ninguno (todos tienen materiales y una imagen/paleta).
- **Sobre presupuesto:** 26 GLB (columna «Problemas»). Con versión `_lite`: hormiga, mariquita, mosquito, oruga. **Sin `_lite`** (y sobre ~5.000): escarabajo ciervo, caracol, hongo cañón (Nivel 1); libélula, perca, garza (Nivel 2); polilla bomba, luciérnaga, ratón, búho, insecto palo (Nivel 3); águila x2, paloma (Nivel 4); patinador orbital (Nivel 7); gaviota, pulpo, mantarraya (`_unassigned`); semillero alien (`shared/alien_tech`). Jefes sobre 12.000: el estudio de montura anfibia (22.136). `canonical_implant_kit` (28.288) es una hoja de referencia, no un modelo de juego.
- **Sin implante separado:** ninguno (todo `controlled_*` trae al menos un nodo de dispositivo; el `_liberado` de los modelos nuevos lo omite).

## Contraste con el contrato del Nivel 1

| Unidad del contrato | Modelo en `level_01_garden` | Tris | Estado | Falta |
|---|---|---|---|---|
| Mariquita | `controlled_flying_ladybird` (+ `_lite`) | 9.384 / 4.954 | En juego (asset_fauna) | usar el `_lite` en el juego |
| Mosca común | `lvl01_enemy_fly_common_v01` (+ liberada) | 4.104 | Solo laboratorio | escena jugable, IA, HP |
| Mosca verde | `lvl01_enemy_fly_green_v01` (+ liberada) | 4.104 | Solo laboratorio | escena jugable, IA, gota apuntada |
| Nube de moscas | `lvl01_enemy_fly_swarm_v01` (+ liberada) | 4.896 | Solo laboratorio | unidad de grupo jugable, bomba que la limpia |
| Avispa | `wasp_mid_poly` (en juego) y `wasp_enemy_visual` (original) | 4.294 / 1.014 | En juego | — |
| Hormiga | `controlled_ant` (+ `_lite`) | 13.456 / 4.980 | En juego | `_lite` en juego; piedritas en arco |
| Caracol | `controlled_woodland_snail` | 7.748 | En juego | **sin `_lite`** |
| Gusano A / B | `lvl01_enemy_worm_rose/compost_v01` (+ liberados) | 4.532 / 3.636 | Solo laboratorio | emerger con marca, escena/IA |
| Escarabajo ciervo | `controlled_stag_beetle` | 9.952 | En juego | **sin `_lite`**; embestida con aviso 0,8 s |
| Hongos de jardín | `lvl01_environment_mushroom_{button,spotted,umbrella}_v01` | 584–1.184 | Solo laboratorio | destructible que suelta polen |
| Hongo cañón | `controlled_mushroom_cannon` | 11.822 | En juego | **sin `_lite`** |
| Araña colgante | nodo `controlled_spider.tscn` (procedural) y `controlled_hanging_spider.glb` | 4.930 | En juego (nodo); GLB sin conectar | conectar el GLB al nodo (hilo + abanico) |
| Tortuga de jardín | solo código (`bee_aftermath_turtle.gd`, caparazón hexagonal procedural) | — | Solo como escena de «secuela» | modelo GLB jugable como tanque, HP alto |
| Robot caminante | `ground_walker_enemy.tscn` (procedural, Quaternius/Kenney) | — | En juego | pasarlo a mini-jefe con escoltas |
| Tarántula (jefe) | `lvl01_boss_giant_spider_v01` (+ liberada), implante en la versión controlada (22 nodos) | 11.652 / 8.584 | Solo laboratorio | escena de jefe, IA, hitbox del implante, liberación |

El implante separado está en las nuevas moscas, gusanos y tarántula (versión controlada con dispositivo, `_liberado` sin él). Los modelos antiguos separan el dispositivo en un nodo (`AlienControlDevice`) que se oculta al liberar.

## Enemigos que viven en código o escena (sin GLB propio)

| Unidad | Archivos | Nivel | Nota |
|---|---|---|---|
| Avispa | `wasp_enemy.tscn/.gd` | 1 | visual `wasp_mid_poly.glb` |
| Araña colgante | `controlled_spider.tscn/.gd` | 1 | |
| Robot caminante | `ground_walker_enemy.tscn/.gd` | 1 (único tecnológico) | |
| Tortuga | `bee_aftermath_turtle.gd` | 1 | |
| Popcorn alien | `popcorn_drone.tscn/.gd` | shared/alien_tech | relleno de formaciones del Lote 11; no figura en el contrato |
| Sonda, dron ojo, speeder, torreta, organismo morado | `alien_probe_*`, `eye_drone_enemy`, `speeder_enemy`, `ground_turret_enemy`, `organic_alien_enemy` | shared/alien_tech (el organismo, Nivel 7) | apagar en el Nivel 1 (etapa 2) |
| Caza alien, semillero | `asset_fauna.gd` (`fighter`, `seed_carrier`) | shared/alien_tech | |
| Libélula controlada, mosquito, perca… | `controlled_dragonfly.gd`, `asset_fauna.gd` | 2 | |
| Polilla, polilla bomba | `asset_fauna.gd` | 3 | |
| UFO / NODO ALIEN | `ufo_boss_01.*`, `ufo_assault.gd`, `ufo_shield_node.gd` | 7 | se conserva |
| Rana del Lote 10 | `garden_toad_encounter.gd`, `lake_toad_boss.gd` (ahora `scripts/levels/level_02_lake/`), escena `scenes/levels/level_02_lake/lake_toad_miniboss_visual.tscn`, modelo `amphibian_mount_study.glb` | 2 | `bee_level_01_scale_event.gd` la invoca desde el Nivel 1 hasta la etapa 2 |

## Usos cruzados (el Nivel 1 usa assets de otros niveles)

- Pinos y piñas (`tall_pine`, `umbrella_pine`, `pine_cone`) → Nivel 3; los usa `bee_level_01_asset_dressing.gd` (y `tall_pine` también la laguna). Decorado de fondo del jardín: se decide en la etapa 2.
- Luciérnaga (Nivel 3) en `bee_level_01_asset_dressing.gd` (ya apagada por `FIREFLIES_ENABLED`).
- `asset_fauna.gd` instancia mosquito, libélula (Nivel 2), polilla bomba, polilla estacionaria (Nivel 3), caza y semillero (`shared/alien_tech`): salen del Nivel 1 en la etapa 2.
- Helecho, campanilla y tronco hueco están en `level_01_garden` y también los usa la laguna.

## Tabla completa

Columnas: nivel / carpeta / archivo / unidad del contrato / ¿en uso? / triángulos / `_lite` / implante (nodos) / problemas.

| Nivel | Carpeta | GLB | Elenco N1 | En uso | Tris | `_lite` | Implante | Problemas |
|---|---|---|---|---|---|---|---|---|
| Nivel 1 | bosses | `assets/models/levels/level_01_garden/bosses/lvl01_boss_giant_spider_v01.glb` | Tarántula (jefe) | no (solo laboratorio) | 11652 | no | sí (22) | — |
| Nivel 1 | bosses | `assets/models/levels/level_01_garden/bosses/lvl01_boss_giant_spider_v01_liberado.glb` | Tarántula (liberada) | no (solo laboratorio) | 8584 | no | sí (1) | — |
| Nivel 1 | enemies | `assets/models/levels/level_01_garden/enemies/controlled_ant.glb` | Hormiga | sí: asset_fauna.gd | 13456 | tiene | sí (2) | sobre presupuesto: enemigo 13456 > 5.000 (tiene _lite);  |
| Nivel 1 | enemies | `assets/models/levels/level_01_garden/enemies/controlled_ant_lite.glb` | Hormiga | no (solo laboratorio) | 4980 | es lite | sí (2) | — |
| Nivel 1 | enemies | `assets/models/levels/level_01_garden/enemies/controlled_flying_ladybird.glb` | Mariquita | sí: asset_fauna.gd | 9384 | tiene | sí (1) | sobre presupuesto: enemigo 9384 > 5.000 (tiene _lite);  |
| Nivel 1 | enemies | `assets/models/levels/level_01_garden/enemies/controlled_flying_ladybird_lite.glb` | Mariquita | no (solo laboratorio) | 4954 | es lite | sí (2) | — |
| Nivel 1 | enemies | `assets/models/levels/level_01_garden/enemies/controlled_hanging_spider.glb` | Araña colgante | no (solo laboratorio) | 4930 | no | sí (2) | — |
| Nivel 1 | enemies | `assets/models/levels/level_01_garden/enemies/controlled_mushroom_cannon.glb` | Hongo cañón | sí: asset_fauna.gd | 11822 | no | sí (2) | sobre presupuesto: enemigo 11822 > 5.000 (sin _lite);  |
| Nivel 1 | enemies | `assets/models/levels/level_01_garden/enemies/controlled_stag_beetle.glb` | Escarabajo ciervo | sí: asset_fauna.gd | 9952 | no | sí (1) | sobre presupuesto: enemigo 9952 > 5.000 (sin _lite);  |
| Nivel 1 | enemies | `assets/models/levels/level_01_garden/enemies/controlled_woodland_snail.glb` | Caracol | sí: asset_fauna.gd | 7748 | no | sí (1) | sobre presupuesto: enemigo 7748 > 5.000 (sin _lite);  |
| Nivel 1 | enemies | `assets/models/levels/level_01_garden/enemies/lvl01_enemy_fly_common_v01.glb` | Mosca común | no (solo laboratorio) | 4104 | no | sí (5) | — |
| Nivel 1 | enemies | `assets/models/levels/level_01_garden/enemies/lvl01_enemy_fly_common_v01_liberado.glb` | Mosca común (liberada) | no (solo laboratorio) | 3776 | no | sí (1) | — |
| Nivel 1 | enemies | `assets/models/levels/level_01_garden/enemies/lvl01_enemy_fly_green_v01.glb` | Mosca verde | no (solo laboratorio) | 4104 | no | sí (5) | — |
| Nivel 1 | enemies | `assets/models/levels/level_01_garden/enemies/lvl01_enemy_fly_green_v01_liberado.glb` | Mosca verde (liberada) | no (solo laboratorio) | 3776 | no | sí (1) | — |
| Nivel 1 | enemies | `assets/models/levels/level_01_garden/enemies/lvl01_enemy_fly_swarm_v01.glb` | Nube de moscas | no (solo laboratorio) | 4896 | no | sí (25) | — |
| Nivel 1 | enemies | `assets/models/levels/level_01_garden/enemies/lvl01_enemy_fly_swarm_v01_liberado.glb` | Nube de moscas (liberada) | no (solo laboratorio) | 4320 | no | sí (8) | — |
| Nivel 1 | enemies | `assets/models/levels/level_01_garden/enemies/lvl01_enemy_worm_compost_v01.glb` | Gusano B | no (solo laboratorio) | 3636 | no | sí (5) | — |
| Nivel 1 | enemies | `assets/models/levels/level_01_garden/enemies/lvl01_enemy_worm_compost_v01_liberado.glb` | Gusano B (liberado) | no (solo laboratorio) | 3360 | no | sí (1) | — |
| Nivel 1 | enemies | `assets/models/levels/level_01_garden/enemies/lvl01_enemy_worm_rose_v01.glb` | Gusano A | no (solo laboratorio) | 4532 | no | sí (5) | — |
| Nivel 1 | enemies | `assets/models/levels/level_01_garden/enemies/lvl01_enemy_worm_rose_v01_liberado.glb` | Gusano A (liberado) | no (solo laboratorio) | 4256 | no | sí (1) | — |
| Nivel 1 | enemies | `assets/models/levels/level_01_garden/enemies/wasp_enemy_visual.glb` | Avispa | no (solo laboratorio) | 1014 | no | no | — |
| Nivel 1 | enemies | `assets/models/levels/level_01_garden/enemies/wasp_mid_poly.glb` | Avispa | sí: bee_prototype/visuals/wasp_enemy_visual.tscn | 4294 | no | no | — |
| Nivel 1 | environment | `assets/models/levels/level_01_garden/environment/flowering_shrub.glb` | — | sí: bee_level_01_asset_dressing.gd | 11784 | no | no | — |
| Nivel 1 | environment | `assets/models/levels/level_01_garden/environment/forest_fern.glb` | — | sí: bee_level_02_lake_scenery.gd | 2940 | no | no | — |
| Nivel 1 | environment | `assets/models/levels/level_01_garden/environment/garden_bellflower.glb` | — | sí: bee_level_01_asset_dressing.gd, bee_level_02_lake_scenery.gd | 2824 | no | no | — |
| Nivel 1 | environment | `assets/models/levels/level_01_garden/environment/garden_distant_house.glb` | — | sí: bee_level_01_asset_dressing.gd | 2116 | no | no | — |
| Nivel 1 | environment | `assets/models/levels/level_01_garden/environment/garden_fence_module.glb` | — | sí: bee_level_01_asset_dressing.gd | 2404 | no | no | — |
| Nivel 1 | environment | `assets/models/levels/level_01_garden/environment/garden_sapling.glb` | — | sí: bee_level_01_asset_dressing.gd | 7904 | no | no | — |
| Nivel 1 | environment | `assets/models/levels/level_01_garden/environment/hollow_fallen_log.glb` | — | sí: bee_level_01_asset_dressing.gd, bee_level_02_lake_scenery.gd | 1972 | no | no | — |
| Nivel 1 | environment | `assets/models/levels/level_01_garden/environment/lvl01_environment_mushroom_button_v01.glb` | Hongo de jardín | no (solo laboratorio) | 584 | no | no | — |
| Nivel 1 | environment | `assets/models/levels/level_01_garden/environment/lvl01_environment_mushroom_spotted_v01.glb` | Hongo de jardín | no (solo laboratorio) | 1184 | no | no | — |
| Nivel 1 | environment | `assets/models/levels/level_01_garden/environment/lvl01_environment_mushroom_umbrella_v01.glb` | Hongo de jardín | no (solo laboratorio) | 584 | no | no | — |
| Nivel 1 | environment | `assets/models/levels/level_01_garden/environment/sky_crescent_moon.glb` | — | sí: bee_level_01_asset_dressing.gd | 3692 | no | no | — |
| Nivel 1 | environment | `assets/models/levels/level_01_garden/environment/sky_star_cluster.glb` | — | sí: bee_level_01_asset_dressing.gd | 2640 | no | no | — |
| Nivel 1 | environment | `assets/models/levels/level_01_garden/environment/sky_sun.glb` | — | sí: bee_level_01_asset_dressing.gd | 2208 | no | no | — |
| Nivel 1 | props | `assets/models/levels/level_01_garden/props/banana_peel.glb` | — | sí: bee_level_01_asset_dressing.gd, destructible_obstacle_3d.gd | 908 | no | no | — |
| Nivel 1 | props | `assets/models/levels/level_01_garden/props/empty_drink_can.glb` | — | sí: bee_level_01_asset_dressing.gd | 4572 | no | no | — |
| Nivel 1 | props | `assets/models/levels/level_01_garden/props/garden_hose.glb` | — | sí: bee_level_01_asset_dressing.gd | 3424 | no | no | — |
| Nivel 1 | props | `assets/models/levels/level_01_garden/props/garden_watering_can.glb` | — | no (solo laboratorio) | 2624 | no | no | — |
| Nivel 1 | props | `assets/models/levels/level_01_garden/props/giant_bottle_cap.glb` | — | sí: bee_level_01_asset_dressing.gd | 5984 | no | no | — |
| Nivel 1 | props | `assets/models/levels/level_01_garden/props/glass_bottle.glb` | — | sí: bee_level_01_asset_dressing.gd | 1640 | no | no | — |
| Nivel 1 | props | `assets/models/levels/level_01_garden/props/matchbox.glb` | — | no (solo laboratorio) | 2820 | no | no | — |
| Nivel 1 | props | `assets/models/levels/level_01_garden/props/open_candy_wrapper.glb` | — | no (solo laboratorio) | 116 | no | no | — |
| Nivel 1 | props | `assets/models/levels/level_01_garden/props/open_tuna_tin.glb` | — | sí: bee_level_01_asset_dressing.gd, destructible_obstacle_3d.gd | 1584 | no | no | — |
| Nivel 1 | props | `assets/models/levels/level_01_garden/props/wrapped_candy.glb` | — | sí: bee_level_01_asset_dressing.gd | 2024 | no | no | — |
| Nivel 2 | bosses | `assets/models/levels/level_02_lake/bosses/amphibian_mount_study.glb` | — | sí: levels/level_02_lake/lake_toad_miniboss_visual.tscn | 22136 | no | sí (2) | sobre presupuesto: jefe 22136 > 12.000;  |
| Nivel 2 | bosses | `assets/models/levels/level_02_lake/bosses/lvl02_boss_rococo_toad_v01.glb` | — | no (solo laboratorio) | 11992 | no | sí (28) | — |
| Nivel 2 | bosses | `assets/models/levels/level_02_lake/bosses/lvl02_boss_rococo_toad_v01_liberado.glb` | — | no (solo laboratorio) | 7900 | no | sí (1) | — |
| Nivel 2 | enemies | `assets/models/levels/level_02_lake/enemies/controlled_dragonfly.glb` | — | sí: asset_fauna.gd | 16580 | no | sí (2) | sobre presupuesto: enemigo 16580 > 5.000 (sin _lite);  |
| Nivel 2 | enemies | `assets/models/levels/level_02_lake/enemies/controlled_dragonfly_nymph.glb` | — | sí: asset_fauna.gd | 4842 | no | sí (2) | — |
| Nivel 2 | enemies | `assets/models/levels/level_02_lake/enemies/controlled_mosquito.glb` | — | sí: asset_fauna.gd | 7840 | tiene | sí (1) | sobre presupuesto: enemigo 7840 > 5.000 (tiene _lite);  |
| Nivel 2 | enemies | `assets/models/levels/level_02_lake/enemies/controlled_mosquito_lite.glb` | — | no (solo laboratorio) | 4954 | es lite | sí (2) | — |
| Nivel 2 | enemies | `assets/models/levels/level_02_lake/enemies/controlled_perch.glb` | — | sí: asset_fauna.gd | 8236 | no | sí (1) | sobre presupuesto: enemigo 8236 > 5.000 (sin _lite);  |
| Nivel 2 | enemies | `assets/models/levels/level_02_lake/enemies/controlled_water_strider.glb` | — | sí: asset_fauna.gd | 4872 | no | sí (2) | — |
| Nivel 2 | enemies | `assets/models/levels/level_02_lake/enemies/lvl02_enemy_giant_heron_v01.glb` | — | no (solo laboratorio) | 5964 | no | sí (9) | sobre presupuesto: enemigo 5964 > 5.000 (sin _lite);  |
| Nivel 2 | enemies | `assets/models/levels/level_02_lake/enemies/lvl02_enemy_giant_heron_v01_liberado.glb` | — | no (solo laboratorio) | 5212 | no | sí (1) | sobre presupuesto: enemigo 5212 > 5.000 (sin _lite);  |
| Nivel 2 | enemies | `assets/models/levels/level_02_lake/enemies/lvl02_enemy_mosquito_cloud_v01.glb` | — | no (solo laboratorio) | 4680 | no | sí (13) | — |
| Nivel 2 | enemies | `assets/models/levels/level_02_lake/enemies/lvl02_enemy_mosquito_cloud_v01_liberado.glb` | — | no (solo laboratorio) | 3696 | no | sí (6) | — |
| Nivel 2 | enemies | `assets/models/levels/level_02_lake/enemies/lvl02_enemy_salamander_v01.glb` | — | no (solo laboratorio) | 4112 | no | sí (5) | — |
| Nivel 2 | enemies | `assets/models/levels/level_02_lake/enemies/lvl02_enemy_salamander_v01_liberado.glb` | — | no (solo laboratorio) | 3784 | no | sí (1) | — |
| Nivel 2 | enemies | `assets/models/levels/level_02_lake/enemies/lvl02_enemy_turtle_v01.glb` | — | no (solo laboratorio) | 4908 | no | sí (5) | — |
| Nivel 2 | enemies | `assets/models/levels/level_02_lake/enemies/lvl02_enemy_turtle_v01_liberado.glb` | — | no (solo laboratorio) | 4580 | no | sí (1) | — |
| Nivel 2 | environment | `assets/models/levels/level_02_lake/environment/cattails_cluster.glb` | — | sí: bee_level_02_lake_scenery.gd | 4272 | no | no | — |
| Nivel 2 | environment | `assets/models/levels/level_02_lake/environment/lotus_lily_pad.glb` | — | sí: bee_level_02_lake_scenery.gd | 7632 | no | no | — |
| Nivel 2 | environment | `assets/models/levels/level_02_lake/environment/lvl02_environment_floating_branch_lite_v01.glb` | — | no (solo laboratorio) | 708 | es lite | no | — |
| Nivel 2 | environment | `assets/models/levels/level_02_lake/environment/lvl02_environment_flowering_lily_pads_lite_v01.glb` | — | no (solo laboratorio) | 1540 | es lite | no | — |
| Nivel 2 | environment | `assets/models/levels/level_02_lake/environment/lvl02_environment_totoras_cluster_lite_v01.glb` | — | no (solo laboratorio) | 1720 | es lite | no | — |
| Nivel 2 | environment | `assets/models/levels/level_02_lake/environment/shore_rock.glb` | — | no (solo laboratorio) | 5472 | no | no | — |
| Nivel 2 | environment | `assets/models/levels/level_02_lake/environment/shore_wave_module.glb` | — | no (solo laboratorio) | 7900 | no | no | — |
| Nivel 2 | environment | `assets/models/levels/level_02_lake/environment/submerged_root_module.glb` | — | sí: bee_level_02_lake_scenery.gd | 1532 | no | no | — |
| Nivel 2 | props | `assets/models/levels/level_02_lake/props/coastal_buoy.glb` | — | no (solo laboratorio) | 4592 | no | no | — |
| Nivel 2 | props | `assets/models/levels/level_02_lake/props/coastal_rowboat.glb` | — | no (solo laboratorio) | 5412 | no | no | — |
| Nivel 3 | enemies | `assets/models/levels/level_03_forest/enemies/controlled_bomb_moth.glb` | — | sí: asset_fauna.gd | 23592 | no | sí (2) | sobre presupuesto: enemigo 23592 > 5.000 (sin _lite);  |
| Nivel 3 | enemies | `assets/models/levels/level_03_forest/enemies/controlled_caterpillar.glb` | — | no (solo laboratorio) | 20344 | tiene | sí (2) | sobre presupuesto: enemigo 20344 > 5.000 (tiene _lite);  |
| Nivel 3 | enemies | `assets/models/levels/level_03_forest/enemies/controlled_caterpillar_lite.glb` | — | no (solo laboratorio) | 4968 | es lite | sí (2) | — |
| Nivel 3 | enemies | `assets/models/levels/level_03_forest/enemies/controlled_firefly.glb` | — | sí: bee_level_01_asset_dressing.gd | 8864 | no | sí (1) | sobre presupuesto: enemigo 8864 > 5.000 (sin _lite);  |
| Nivel 3 | enemies | `assets/models/levels/level_03_forest/enemies/controlled_mouse.glb` | — | no (solo laboratorio) | 10748 | no | sí (1) | sobre presupuesto: enemigo 10748 > 5.000 (sin _lite);  |
| Nivel 3 | enemies | `assets/models/levels/level_03_forest/enemies/controlled_owl.glb` | — | no (solo laboratorio) | 13540 | no | sí (1) | sobre presupuesto: enemigo 13540 > 5.000 (sin _lite);  |
| Nivel 3 | enemies | `assets/models/levels/level_03_forest/enemies/controlled_stick_insect.glb` | — | no (solo laboratorio) | 7416 | no | sí (1) | sobre presupuesto: enemigo 7416 > 5.000 (sin _lite);  |
| Nivel 3 | enemies | `assets/models/levels/level_03_forest/enemies/moth_stationary_bomb.glb` | — | sí: asset_fauna.gd | 2528 | no | sí (2) | — |
| Nivel 3 | environment | `assets/models/levels/level_03_forest/environment/tall_pine.glb` | — | sí: bee_level_01_asset_dressing.gd, bee_level_02_lake_scenery.gd | 1564 | no | no | — |
| Nivel 3 | environment | `assets/models/levels/level_03_forest/environment/umbrella_pine.glb` | — | sí: bee_level_01_asset_dressing.gd | 3176 | no | no | — |
| Nivel 3 | props | `assets/models/levels/level_03_forest/props/pine_cone.glb` | — | sí: bee_level_01_asset_dressing.gd | 4992 | no | no | — |
| Nivel 4 | enemies | `assets/models/levels/level_04_sky/enemies/controlled_eagle.glb` | — | no (solo laboratorio) | 6914 | no | sí (2) | sobre presupuesto: enemigo 6914 > 5.000 (sin _lite);  |
| Nivel 4 | enemies | `assets/models/levels/level_04_sky/enemies/controlled_eagle_flight.glb` | — | no (solo laboratorio) | 6914 | no | sí (2) | sobre presupuesto: enemigo 6914 > 5.000 (sin _lite);  |
| Nivel 4 | enemies | `assets/models/levels/level_04_sky/enemies/controlled_pigeon.glb` | — | no (solo laboratorio) | 11008 | no | sí (1) | sobre presupuesto: enemigo 11008 > 5.000 (sin _lite);  |
| Nivel 4 | environment | `assets/models/levels/level_04_sky/environment/residential_cottage.glb` | — | no (solo laboratorio) | 2988 | no | no | — |
| Nivel 4 | environment | `assets/models/levels/level_04_sky/environment/residential_two_storey.glb` | — | no (solo laboratorio) | 3364 | no | no | — |
| Nivel 4 | environment | `assets/models/levels/level_04_sky/environment/sky_cloud.glb` | — | no (solo laboratorio) | 5888 | no | no | — |
| Nivel 4 | environment | `assets/models/levels/level_04_sky/environment/warm_star_set.glb` | — | no (solo laboratorio) | 1800 | no | no | — |
| Nivel 4 | props | `assets/models/levels/level_04_sky/props/warm_street_lamp.glb` | — | no (solo laboratorio) | 1288 | no | no | — |
| Nivel 7 | bosses | `assets/models/levels/level_07_space/bosses/alien_mothership.glb` | — | no (solo laboratorio) | 6764 | no | sí (2) | — |
| Nivel 7 | enemies | `assets/models/levels/level_07_space/enemies/orbital_skimmer.glb` | — | no (solo laboratorio) | 5548 | no | no | sobre presupuesto: enemigo 5548 > 5.000 (sin _lite);  |
| Nivel 7 | environment | `assets/models/levels/level_07_space/environment/warm_asteroid.glb` | — | no (solo laboratorio) | 3752 | no | no | — |
| _unassigned | coastal | `assets/models/_unassigned/coastal/controlled_gull.glb` | — | no (solo laboratorio) | 11348 | no | sí (1) | sobre presupuesto: enemigo 11348 > 5.000;  |
| _unassigned | coastal | `assets/models/_unassigned/coastal/controlled_manta_ray.glb` | — | no (solo laboratorio) | 7280 | no | sí (1) | sobre presupuesto: enemigo 7280 > 5.000;  |
| _unassigned | coastal | `assets/models/_unassigned/coastal/controlled_octopus.glb` | — | no (solo laboratorio) | 20144 | no | sí (1) | sobre presupuesto: enemigo 20144 > 5.000;  |
| _unassigned | human | `assets/models/_unassigned/human/hipster_poc.glb` | — | sí: bee_prototype/bee_shmup_world_scale_human_poc.tscn, levels/giant_human_hazard.tscn | 2480 | no | no | material casi blanco (1);  |
| shared/alien_tech | alien_tech | `assets/models/shared/alien_tech/alien_armoured_bomber.glb` | — | no (solo laboratorio) | 4974 | no | sí (2) | — |
| shared/alien_tech | alien_tech | `assets/models/shared/alien_tech/alien_needle_interceptor.glb` | — | sí: asset_fauna.gd | 4982 | no | sí (2) | — |
| shared/alien_tech | alien_tech | `assets/models/shared/alien_tech/alien_probe_visual.glb` | — | sí: bee_prototype/visuals/alien_probe_visual.tscn | 920 | no | no | — |
| shared/alien_tech | alien_tech | `assets/models/shared/alien_tech/alien_seed_carrier.glb` | — | sí: asset_fauna.gd | 9108 | no | no | sobre presupuesto: enemigo 9108 > 5.000;  |
| shared/alien_tech | alien_tech | `assets/models/shared/alien_tech/alien_signal_relay.glb` | — | sí: bee_level_01_asset_dressing.gd | 4520 | no | no | — |
| shared/alien_tech | alien_tech | `assets/models/shared/alien_tech/canonical_implant_kit.glb` | — | no (solo laboratorio) | 28288 | no | sí (9) | sobre presupuesto: kit 28288 (referencia, no es un modelo de juego);  |
| shared/bee | bee | `assets/models/shared/bee/bee_alien_visual.glb` | — | no (solo laboratorio) | 1144 | no | sí (1) | — |
| shared/bee | bee | `assets/models/shared/bee/bee_mid_poly.glb` | — | sí: bee_prototype/bee_player.tscn | 4540 | no | sí (1) | — |
| shared/pickups | pickups | `assets/models/shared/pickups/pickup_bomb.glb` | — | sí: items/toon/bomb.tscn, bee_prototype/bee_alien_bomb.gd | 2068 | no | no | — |
| shared/pickups | pickups | `assets/models/shared/pickups/pickup_healing.glb` | — | sí: items/toon/healing.tscn | 1656 | no | no | — |
| shared/pickups | pickups | `assets/models/shared/pickups/pickup_pollen.glb` | — | sí: items/toon/pollen.tscn | 2096 | no | no | — |
| shared/pickups | pickups | `assets/models/shared/pickups/pickup_spread.glb` | — | sí: items/toon/spread.tscn | 1564 | no | no | — |
| shared/projectiles | projectiles | `assets/models/shared/projectiles/alien_bolt.glb` | — | sí: projectiles/toon/alien_bolt.tscn | 864 | no | sí (2) | — |
| shared/projectiles | projectiles | `assets/models/shared/projectiles/bee_bolt.glb` | — | sí: projectiles/toon/bee_bolt.tscn | 864 | no | no | — |

## Qué cambió de lugar en esta etapa

Ver `docs/INFORME_LOTE_12.md` (sección Etapa 1): 82 GLB heredados + 2 modelos de `assets/style/models` (Bee y avispa mid poly), sus `.blend`, la rana (escena y código) y los manifiestos (no se movieron, ver «Pendientes de mover»).
