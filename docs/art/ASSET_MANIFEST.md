# Manifiesto de assets 3D — Bee Alien 3D

Generado el 2026-10-12 (Lote 11, etapa A1) leyendo `assets/models/`, `art_source/blender/`, `scenes/art_labs/` y `docs/art/`. Solo lectura: no se movió nada. Estructura destino y pedido de assets nuevos: `docs/art/ASSET_REQUEST_TEMPLATE.md`, `docs/art/ASSET_MOVE_PLAN.md`.

**Cómo leerlo.**
- *Nivel*: L01 y L02 están confirmados por uso real. Los marcados *(prop.)* son una propuesta de reparto por nombre (L03 bosque, L04 cielo, L05 invasión, L06 atmósfera, L07 espacio). `compartido` = Bee, ítems, proyectiles.
- *Tris*: `manifest.json` de cada tanda; `—` si la tanda no trae manifest (assets previos al flujo Codex).
- *¿Juego?*: referencia estática `res://` desde escenas/scripts que no sean laboratorio (`scenes/art_labs`, `scripts/art`) ni tests, incluyendo la ruta indirecta por la escena envoltorio de `art_labs` (que es lo que instancia el juego). No detecta cargas por nombre construido en runtime.
- *Estado*: `en juego` = se instancia en un nivel o escena jugable; `texturizado` = GLB con materiales y escena de laboratorio, sin uso en el juego. No hay bocetos ni modelos sin material en disco: todo `.blend` tiene GLB y escena de laboratorio (excepto `hipster_poc`, sin fuente).

| Nivel | Categoría | Nombre | .blend | .glb | ¿Juego? (dónde) | Tris | Estado |
|---|---|---|---|---|---|---|---|
| compartido | enemigo | bee_alien_visual | art_source/blender/bee_prototype/bee_alien_visual.blend | assets/models/bee_prototype/bee_alien_visual.glb | no (solo laboratorio) | — | texturizado |
| compartido | ítem | pickup_bomb | art_source/blender/pickups_toon_v01/pickup_bomb.blend | assets/models/pickups_toon_v01/pickup_bomb.glb | sí — items/toon/bomb.tscn, bee_prototype/bee_alien_bomb.gd | 2068 | en juego |
| compartido | ítem | pickup_healing | art_source/blender/pickups_toon_v01/pickup_healing.blend | assets/models/pickups_toon_v01/pickup_healing.glb | sí — items/toon/healing.tscn | 1656 | en juego |
| compartido | ítem | pickup_pollen | art_source/blender/pickups_toon_v01/pickup_pollen.blend | assets/models/pickups_toon_v01/pickup_pollen.glb | sí — items/toon/pollen.tscn | 2096 | en juego |
| compartido | ítem | pickup_spread | art_source/blender/pickups_toon_v01/pickup_spread.blend | assets/models/pickups_toon_v01/pickup_spread.glb | sí — items/toon/spread.tscn | 1564 | en juego |
| compartido | fx | alien_bolt | art_source/blender/projectiles_toon_v01/alien_bolt.blend | assets/models/projectiles_toon_v01/alien_bolt.glb | sí — projectiles/toon/alien_bolt.tscn | 864 | en juego |
| compartido | fx | bee_bolt | art_source/blender/projectiles_toon_v01/bee_bolt.blend | assets/models/projectiles_toon_v01/bee_bolt.glb | sí — projectiles/toon/bee_bolt.tscn | 864 | en juego |
| L01 jardín | enemigo | alien_probe_visual | art_source/blender/bee_prototype/alien_probe_visual.blend | assets/models/bee_prototype/alien_probe_visual.glb | sí — bee_prototype/visuals/alien_probe_visual.tscn, bee_prototype/visuals/alien_probe_visual_lab.tscn | — | en juego |
| L01 jardín | enemigo | wasp_enemy_visual | art_source/blender/bee_prototype/wasp_enemy_visual.blend | assets/models/bee_prototype/wasp_enemy_visual.glb | sí — bee_prototype/visuals/wasp_enemy_visual.tscn | — | en juego |
| L01 jardín | enemigo | controlled_mosquito | art_source/blender/future_biomes_v01/controlled_mosquito.blend | assets/models/future_biomes_v01/controlled_mosquito.glb | sí — asset_fauna.gd | 4954 | en juego |
| L01 jardín | enemigo | controlled_firefly | art_source/blender/future_biomes_v03/controlled_firefly.blend | assets/models/future_biomes_v03/controlled_firefly.glb | sí — bee_level_01_asset_dressing.gd | 8864 | en juego |
| L01 jardín | enemigo | controlled_flying_ladybird | art_source/blender/future_biomes_v03/controlled_flying_ladybird.blend | assets/models/future_biomes_v03/controlled_flying_ladybird.glb | sí — asset_fauna.gd | 4954 | en juego |
| L01 jardín | entorno | giant_bottle_cap | art_source/blender/future_biomes_v04/giant_bottle_cap.blend | assets/models/future_biomes_v04/giant_bottle_cap.glb | sí — bee_level_01_asset_dressing.gd | 5984 | en juego |
| L01 jardín | entorno | empty_drink_can | art_source/blender/future_biomes_v06/empty_drink_can.blend | assets/models/future_biomes_v06/empty_drink_can.glb | sí — bee_level_01_asset_dressing.gd | 4572 | en juego |
| L01 jardín | entorno | wrapped_candy | art_source/blender/future_biomes_v06/wrapped_candy.blend | assets/models/future_biomes_v06/wrapped_candy.glb | sí — bee_level_01_asset_dressing.gd | 2024 | en juego |
| L01 jardín | entorno | sky_crescent_moon | art_source/blender/future_biomes_v07/sky_crescent_moon.blend | assets/models/future_biomes_v07/sky_crescent_moon.glb | sí — bee_level_01_asset_dressing.gd | 3692 | en juego |
| L01 jardín | entorno | sky_star_cluster | art_source/blender/future_biomes_v07/sky_star_cluster.blend | assets/models/future_biomes_v07/sky_star_cluster.glb | sí — bee_level_01_asset_dressing.gd | 2640 | en juego |
| L01 jardín | entorno | sky_sun | art_source/blender/future_biomes_v07/sky_sun.blend | assets/models/future_biomes_v07/sky_sun.glb | sí — bee_level_01_asset_dressing.gd | 2208 | en juego |
| L01 jardín | enemigo | controlled_ant | art_source/blender/future_biomes_v09/controlled_ant.blend | assets/models/future_biomes_v09/controlled_ant.glb | sí — asset_fauna.gd | 4980 | en juego |
| L01 jardín | enemigo | controlled_caterpillar | art_source/blender/future_biomes_v09/controlled_caterpillar.blend | assets/models/future_biomes_v09/controlled_caterpillar.glb | no (solo laboratorio) | 4968 | texturizado |
| L01 jardín | entorno | garden_distant_house | art_source/blender/garden_backdrop_v01/garden_distant_house.blend | assets/models/garden_backdrop_v01/garden_distant_house.glb | sí — bee_level_01_asset_dressing.gd | 2116 | en juego |
| L01 jardín | entorno | garden_fence_module | art_source/blender/garden_backdrop_v01/garden_fence_module.blend | assets/models/garden_backdrop_v01/garden_fence_module.glb | sí — bee_level_01_asset_dressing.gd | 2404 | en juego |
| L01 jardín | entorno | garden_hose | art_source/blender/garden_backdrop_v01/garden_hose.blend | assets/models/garden_backdrop_v01/garden_hose.glb | sí — bee_level_01_asset_dressing.gd | 3424 | en juego |
| L01 jardín | entorno | garden_watering_can | art_source/blender/garden_backdrop_v01/garden_watering_can.blend | assets/models/garden_backdrop_v01/garden_watering_can.glb | no (solo laboratorio) | 2624 | texturizado |
| L01 jardín | entorno | glass_bottle | art_source/blender/ground_litter_v01/glass_bottle.blend | assets/models/ground_litter_v01/glass_bottle.glb | sí — bee_level_01_asset_dressing.gd | 1640 | en juego |
| L01 jardín | entorno | matchbox | art_source/blender/ground_litter_v01/matchbox.blend | assets/models/ground_litter_v01/matchbox.glb | no (solo laboratorio) | 2820 | texturizado |
| L01 jardín | entorno | open_candy_wrapper | art_source/blender/ground_litter_v01/open_candy_wrapper.blend | assets/models/ground_litter_v01/open_candy_wrapper.glb | no (solo laboratorio) | 116 | texturizado |
| L01 jardín | entorno | banana_peel | art_source/blender/ground_litter_v02/banana_peel.blend | assets/models/ground_litter_v02/banana_peel.glb | sí — bee_level_01_asset_dressing.gd, destructible_obstacle_3d.gd | 908 | en juego |
| L01 jardín | entorno | open_tuna_tin | art_source/blender/ground_litter_v02/open_tuna_tin.blend | assets/models/ground_litter_v02/open_tuna_tin.glb | sí — bee_level_01_asset_dressing.gd, destructible_obstacle_3d.gd | 1584 | en juego |
| L01 jardín | entorno | hipster_poc | � | assets/models/human_reuse/hipster_poc.glb | sí — bee_prototype/bee_shmup_world_scale_human_poc.tscn, levels/giant_human_hazard.tscn | — | en juego |
| L01 jardín | enemigo | controlled_ant | art_source/blender/swarm_lite_v01/controlled_ant.blend | assets/models/swarm_lite_v01/controlled_ant.glb | no (solo laboratorio) | 4980 | texturizado |
| L01 jardín | enemigo | controlled_caterpillar | art_source/blender/swarm_lite_v01/controlled_caterpillar.blend | assets/models/swarm_lite_v01/controlled_caterpillar.glb | no (solo laboratorio) | 4968 | texturizado |
| L01 jardín | enemigo | controlled_flying_ladybird | art_source/blender/swarm_lite_v01/controlled_flying_ladybird.blend | assets/models/swarm_lite_v01/controlled_flying_ladybird.glb | no (solo laboratorio) | 4954 | texturizado |
| L01 jardín | enemigo | controlled_mosquito | art_source/blender/swarm_lite_v01/controlled_mosquito.blend | assets/models/swarm_lite_v01/controlled_mosquito.glb | no (solo laboratorio) | 4954 | texturizado |
| L02 lago | entorno | cattails_cluster | art_source/blender/future_biomes_v01/cattails_cluster.blend | assets/models/future_biomes_v01/cattails_cluster.glb | sí — bee_level_02_lake_scenery.gd | 4272 | en juego |
| L02 lago | enemigo | controlled_perch | art_source/blender/future_biomes_v01/controlled_perch.blend | assets/models/future_biomes_v01/controlled_perch.glb | sí — asset_fauna.gd | 8236 | en juego |
| L02 lago | entorno | lotus_lily_pad | art_source/blender/future_biomes_v01/lotus_lily_pad.blend | assets/models/future_biomes_v01/lotus_lily_pad.glb | sí — bee_level_02_lake_scenery.gd | 7632 | en juego |
| L02 lago | entorno | coastal_buoy | art_source/blender/future_biomes_v05/coastal_buoy.blend | assets/models/future_biomes_v05/coastal_buoy.glb | no (solo laboratorio) | 4592 | texturizado |
| L02 lago | entorno | coastal_rowboat | art_source/blender/future_biomes_v08/coastal_rowboat.blend | assets/models/future_biomes_v08/coastal_rowboat.glb | no (solo laboratorio) | 5412 | texturizado |
| L02 lago | entorno | shore_rock | art_source/blender/future_biomes_v08/shore_rock.blend | assets/models/future_biomes_v08/shore_rock.glb | no (solo laboratorio) | 5472 | texturizado |
| L02 lago | entorno | shore_wave_module | art_source/blender/future_biomes_v08/shore_wave_module.blend | assets/models/future_biomes_v08/shore_wave_module.glb | no (solo laboratorio) | 7900 | texturizado |
| L02 lago | enemigo | controlled_mushroom_cannon | art_source/blender/future_biomes_v10/controlled_mushroom_cannon.blend | assets/models/future_biomes_v10/controlled_mushroom_cannon.glb | sí — asset_fauna.gd | 11822 | en juego |
| L02 lago | enemigo | controlled_dragonfly_nymph | art_source/blender/lake_fauna_v01/controlled_dragonfly_nymph.blend | assets/models/lake_fauna_v01/controlled_dragonfly_nymph.glb | sí — asset_fauna.gd | 4842 | en juego |
| L02 lago | enemigo | controlled_water_strider | art_source/blender/lake_fauna_v01/controlled_water_strider.blend | assets/models/lake_fauna_v01/controlled_water_strider.glb | sí — asset_fauna.gd | 4872 | en juego |
| L02 lago | entorno | submerged_root_module | art_source/blender/lake_fauna_v01/submerged_root_module.blend | assets/models/lake_fauna_v01/submerged_root_module.glb | sí — bee_level_02_lake_scenery.gd | 1532 | en juego |
| L03 bosque (prop.) | entorno | forest_fern | art_source/blender/forest_floor_v01/forest_fern.blend | assets/models/forest_floor_v01/forest_fern.glb | sí — bee_level_02_lake_scenery.gd | 2940 | en juego |
| L03 bosque (prop.) | entorno | garden_bellflower | art_source/blender/forest_floor_v01/garden_bellflower.blend | assets/models/forest_floor_v01/garden_bellflower.glb | sí — bee_level_01_asset_dressing.gd, bee_level_02_lake_scenery.gd | 2824 | en juego |
| L03 bosque (prop.) | entorno | hollow_fallen_log | art_source/blender/forest_floor_v01/hollow_fallen_log.blend | assets/models/forest_floor_v01/hollow_fallen_log.glb | sí — bee_level_01_asset_dressing.gd, bee_level_02_lake_scenery.gd | 1972 | en juego |
| L03 bosque (prop.) | enemigo | controlled_stag_beetle | art_source/blender/future_biomes_v02/controlled_stag_beetle.blend | assets/models/future_biomes_v02/controlled_stag_beetle.glb | sí — asset_fauna.gd | 9952 | en juego |
| L03 bosque (prop.) | enemigo | controlled_woodland_snail | art_source/blender/future_biomes_v02/controlled_woodland_snail.blend | assets/models/future_biomes_v02/controlled_woodland_snail.glb | sí — asset_fauna.gd | 7748 | en juego |
| L03 bosque (prop.) | enemigo | controlled_owl | art_source/blender/future_biomes_v03/controlled_owl.blend | assets/models/future_biomes_v03/controlled_owl.glb | no (solo laboratorio) | 13540 | texturizado |
| L03 bosque (prop.) | enemigo | controlled_mouse | art_source/blender/future_biomes_v04/controlled_mouse.blend | assets/models/future_biomes_v04/controlled_mouse.glb | no (solo laboratorio) | 10748 | texturizado |
| L03 bosque (prop.) | enemigo | controlled_stick_insect | art_source/blender/future_biomes_v04/controlled_stick_insect.blend | assets/models/future_biomes_v04/controlled_stick_insect.glb | no (solo laboratorio) | 7416 | texturizado |
| L03 bosque (prop.) | entorno | flowering_shrub | art_source/blender/future_biomes_v06/flowering_shrub.blend | assets/models/future_biomes_v06/flowering_shrub.glb | sí — bee_level_01_asset_dressing.gd | 11784 | en juego |
| L03 bosque (prop.) | entorno | garden_sapling | art_source/blender/future_biomes_v06/garden_sapling.blend | assets/models/future_biomes_v06/garden_sapling.glb | sí — bee_level_01_asset_dressing.gd | 7904 | en juego |
| L03 bosque (prop.) | enemigo | controlled_hanging_spider | art_source/blender/future_biomes_v11/controlled_hanging_spider.blend | assets/models/future_biomes_v11/controlled_hanging_spider.glb | no (solo laboratorio) | 4930 | texturizado |
| L03 bosque (prop.) | entorno | pine_cone | art_source/blender/pine_woods_v01/pine_cone.blend | assets/models/pine_woods_v01/pine_cone.glb | sí — bee_level_01_asset_dressing.gd | 4992 | en juego |
| L03 bosque (prop.) | entorno | tall_pine | art_source/blender/pine_woods_v01/tall_pine.blend | assets/models/pine_woods_v01/tall_pine.glb | sí — bee_level_01_asset_dressing.gd, bee_level_02_lake_scenery.gd | 1564 | en juego |
| L03 bosque (prop.) | entorno | umbrella_pine | art_source/blender/pine_woods_v01/umbrella_pine.blend | assets/models/pine_woods_v01/umbrella_pine.glb | sí — bee_level_01_asset_dressing.gd | 3176 | en juego |
| L04 cielo (prop.) | enemigo | controlled_eagle_flight | art_source/blender/eagle_sky_v01/controlled_eagle_flight.blend | assets/models/eagle_sky_v01/controlled_eagle_flight.glb | no (solo laboratorio) | 6914 | texturizado |
| L04 cielo (prop.) | enemigo | controlled_pigeon | art_source/blender/future_biomes_v04/controlled_pigeon.blend | assets/models/future_biomes_v04/controlled_pigeon.glb | no (solo laboratorio) | 11008 | texturizado |
| L04 cielo (prop.) | enemigo | controlled_gull | art_source/blender/future_biomes_v05/controlled_gull.blend | assets/models/future_biomes_v05/controlled_gull.glb | no (solo laboratorio) | 11348 | texturizado |
| L04 cielo (prop.) | entorno | sky_cloud | art_source/blender/future_biomes_v07/sky_cloud.blend | assets/models/future_biomes_v07/sky_cloud.glb | no (solo laboratorio) | 5888 | texturizado |
| L04 cielo (prop.) | enemigo | controlled_bomb_moth | art_source/blender/future_biomes_v10/controlled_bomb_moth.blend | assets/models/future_biomes_v10/controlled_bomb_moth.glb | sí — asset_fauna.gd | 23592 | en juego |
| L04 cielo (prop.) | enemigo | controlled_dragonfly | art_source/blender/future_biomes_v10/controlled_dragonfly.blend | assets/models/future_biomes_v10/controlled_dragonfly.glb | sí — asset_fauna.gd | 16580 | en juego |
| L04 cielo (prop.) | enemigo | moth_stationary_bomb | art_source/blender/future_biomes_v10/moth_stationary_bomb.blend | assets/models/future_biomes_v10/moth_stationary_bomb.glb | sí — asset_fauna.gd | 2528 | en juego |
| L04 cielo (prop.) | enemigo | controlled_eagle | art_source/blender/future_biomes_v11/controlled_eagle.blend | assets/models/future_biomes_v11/controlled_eagle.glb | no (solo laboratorio) | 6914 | texturizado |
| L04 cielo (prop.) | entorno | residential_cottage | art_source/blender/residential_sky_v01/residential_cottage.blend | assets/models/residential_sky_v01/residential_cottage.glb | no (solo laboratorio) | 2988 | texturizado |
| L04 cielo (prop.) | entorno | residential_two_storey | art_source/blender/residential_sky_v01/residential_two_storey.blend | assets/models/residential_sky_v01/residential_two_storey.glb | no (solo laboratorio) | 3364 | texturizado |
| L04 cielo (prop.) | entorno | warm_star_set | art_source/blender/residential_sky_v01/warm_star_set.blend | assets/models/residential_sky_v01/warm_star_set.glb | no (solo laboratorio) | 1800 | texturizado |
| L04 cielo (prop.) | entorno | warm_street_lamp | art_source/blender/residential_sky_v01/warm_street_lamp.blend | assets/models/residential_sky_v01/warm_street_lamp.glb | no (solo laboratorio) | 1288 | texturizado |
| L05 invasión (prop.) | enemigo | alien_armoured_bomber | art_source/blender/alien_ships_v02/alien_armoured_bomber.blend | assets/models/alien_ships_v02/alien_armoured_bomber.glb | no (solo laboratorio) | 4974 | texturizado |
| L05 invasión (prop.) | enemigo | alien_needle_interceptor | art_source/blender/alien_ships_v02/alien_needle_interceptor.blend | assets/models/alien_ships_v02/alien_needle_interceptor.glb | sí — asset_fauna.gd | 4982 | en juego |
| L05 invasión (prop.) | enemigo | alien_seed_carrier | art_source/blender/future_biomes_v02/alien_seed_carrier.blend | assets/models/future_biomes_v02/alien_seed_carrier.glb | sí — asset_fauna.gd | 9108 | en juego |
| L05 invasión (prop.) | enemigo | alien_signal_relay | art_source/blender/future_biomes_v02/alien_signal_relay.blend | assets/models/future_biomes_v02/alien_signal_relay.glb | sí — bee_level_01_asset_dressing.gd | 4520 | en juego |
| L05 invasión (prop.) | enemigo | amphibian_mount_study | art_source/blender/future_biomes_v09/amphibian_mount_study.blend | assets/models/future_biomes_v09/amphibian_mount_study.glb | no (solo laboratorio) | 22136 | texturizado |
| L05 invasión (prop.) | enemigo | canonical_implant_kit | art_source/blender/future_biomes_v09/canonical_implant_kit.blend | assets/models/future_biomes_v09/canonical_implant_kit.glb | no (solo laboratorio) | 28288 | texturizado |
| L05 invasión (prop.) | jefe | alien_mothership | art_source/blender/mothership_v01/alien_mothership.blend | assets/models/mothership_v01/alien_mothership.glb | no (solo laboratorio) | 6764 | texturizado |
| L06 atmósfera (prop.) | enemigo | controlled_manta_ray | art_source/blender/future_biomes_v03/controlled_manta_ray.blend | assets/models/future_biomes_v03/controlled_manta_ray.glb | no (solo laboratorio) | 7280 | texturizado |
| L06 atmósfera (prop.) | enemigo | controlled_octopus | art_source/blender/future_biomes_v05/controlled_octopus.blend | assets/models/future_biomes_v05/controlled_octopus.glb | no (solo laboratorio) | 20144 | texturizado |
| L07 espacio (prop.) | enemigo | orbital_skimmer | art_source/blender/future_biomes_v01/orbital_skimmer.blend | assets/models/future_biomes_v01/orbital_skimmer.glb | no (solo laboratorio) | 5548 | texturizado |
| L07 espacio (prop.) | entorno | warm_asteroid | art_source/blender/future_biomes_v01/warm_asteroid.blend | assets/models/future_biomes_v01/warm_asteroid.glb | no (solo laboratorio) | 3752 | texturizado |

## Notas de la lectura

- Totales: 82 GLB propios (81 `.blend`); 48 referenciados por el juego y 34 solo en laboratorio.
- `bee_alien_visual`: el cuerpo de Bee es procedural; el GLB solo sirve de referencia de escala (`bee_fauna_sizes.gd`), por eso figura como laboratorio.
- `matchbox`, `open_candy_wrapper`: reemplazados en el Nivel 01 por la lata de atún y la cáscara de banana (Lote 8/9). Siguen como reserva.
- Las cuatro piezas de `swarm_lite_v01` duplican nombres de V01/V03/V09 (`controlled_ant`, `controlled_caterpillar`, `controlled_flying_ladybird`, `controlled_mosquito`); el juego usa las versiones de `assets/`, `assets_v03/` y `assets_v09/` (`asset_fauna.gd`).
- `alien_ships_v02/alien_needle_interceptor` es el único alien de V02 en juego (`fighter`). El bombardero blindado, `mothership_v01` y `eagle_sky_v01` están listos pero sin integrar.
- `controlled_spider` del Nivel 01 es un nodo propio (`scenes/levels/controlled_spider.tscn`); el GLB `controlled_hanging_spider` (V11) no está conectado.

## Fuera de `assets/models/`

| Categoría | Contenido | Uso |
|---|---|---|
| fx | `scenes/vfx/*.tscn`, `scenes/vfx/toon/{alien_explosion,alien_impact,bee_explosion,bee_impact}.tscn` | en juego |
| ui | `scenes/ui/future_health_bar.tscn`; HUD de armas `scenes/bee_prototype/bee_weapons_hud.tscn`; título construido por script (`scripts/game/bee_title_screen.gd`) | en juego |
| ítem | `scenes/items/toon/{bomb,healing,pollen,spread}.tscn` (envoltorios de `pickups_toon_v01`) | en juego |
| proyectil | `scenes/projectiles/toon/{alien_bolt,bee_bolt}.tscn` | en juego |
| externo aprobado | `assets/external/approved/` (Kenney, Quaternius, Tiny Treats, KayKit; ver `assets/external/ASSET_PROVENANCE.md`); 14 GLB/GLTF directos + paquetes | parcial: speeder, torreta, ojo, rana, araña, vegetación |
| entorno | `assets/models/human_reuse/hipster_poc.glb` (humano gigante, Nivel 01 y POC de escala; sin `.blend`) | en juego |
