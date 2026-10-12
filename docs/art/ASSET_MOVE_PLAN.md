# Plan de movimiento de assets (EJECUTADO en el Lote 12)

> Estado: la mudanza se ejecutó el 2026-10-12 con `git mv` (o `mv` para lo que nunca se había commiteado), reescribiendo todas las rutas. El reparto real difiere de la tabla de abajo en varios puntos y está en `AUDITORIA_ASSETS.md` y `ASSET_MANIFEST.md`; lo que quedó sin mover (manifiestos y generadores) está en «Pendientes de mover» de `docs/INFORME_LOTE_12.md`. El texto original se conserva como referencia histórica.

## Plan original (Lote 11)

Propuesta del Lote 11 para llevar lo existente a la estructura nueva (`levels/level_0N_*`, `shared/`, `rail_mode/`). No se movió ningún archivo. Reparto por nivel: `ASSET_MANIFEST.md`.

## Destino propuesto por tanda

| Tanda actual (`assets/models/` + `art_source/blender/`) | Destino | Archivos con `res://` a actualizar* |
|---|---|---|
| `pickups_toon_v01` | `shared/pickups/` | 6 (4 envoltorios `scenes/items/toon`, `bee_alien_bomb.gd`, lab) + 1 test |
| `projectiles_toon_v01` | `shared/projectiles/` | 3 |
| `bee_prototype` (bee_alien, avispa, sonda) | `shared/bee/` (Bee) · `levels/level_01_garden/enemies/` (avispa, sonda) | 2 |
| `future_biomes_v09/canonical_implant_kit`, `v09/amphibian_mount_study` | `shared/alien_tech/` · `levels/level_02_lake/bosses/` | 6 (tanda) |
| `garden_backdrop_v01`, `ground_litter_v01/v02`, `forest_floor_v01` (tronco, campanilla), `future_biomes_v06`, `future_biomes_v04/giant_bottle_cap`, `future_biomes_v07` (sol/luna/estrellas) | `levels/level_01_garden/{props,environment}/` | 4–7 por tanda + 1 test |
| `swarm_lite_v01` (duplicados de V01/V03/V09) | `levels/level_01_garden/enemies/` tras decidir cuál versión queda | 6 + 1 test |
| `future_biomes_v01` (lago), `lake_fauna_v01`, `future_biomes_v08` | `levels/level_02_lake/{enemies,environment}/` | 7 + 5 + 4 |
| `pine_woods_v01`, `future_biomes_v02`–`v04` (resto), `v10`, `v11` | `levels/level_03_forest/…` | 3–5 por tanda |
| `residential_sky_v01`, `eagle_sky_v01`, `future_biomes_v05` (gaviota/boya) | `levels/level_04_sky/…` | 2–5 por tanda |
| `alien_ships_v02`, `mothership_v01` | `levels/level_05_invasion/{enemies,bosses}/` | 3 · 2 |
| `future_biomes_v03/manta`, `v05/octopus` | `levels/level_06_atmosphere/enemies/` (propuesto) | — |
| `future_biomes_v01/{warm_asteroid,orbital_skimmer}` | `levels/level_07_space/…` | — |
| `human_reuse/hipster_poc.glb` | `levels/level_01_garden/props/` | 3 + 1 test |

*Conteo de archivos `.gd/.tscn/.tres/.json` (fuera de `dev/` y `docs/`) que contienen la ruta `assets/models/<tanda>/`.

## Qué referencias habría que actualizar

1. **Escenas de laboratorio y envoltorios** (`scenes/art_labs/**/*.tscn`): cada una apunta a su GLB por `ext_resource path="res://assets/models/<tanda>/<archivo>.glb"` y lleva `uid`. Mover el GLB junto con su `.import` conserva el `uid` en Godot 4, pero conviene hacerlo con el editor (o reimportar) para que reescriba rutas.
2. **Scripts de juego** con `preload`/`load` a envoltorios `art_labs` o a GLB: `bee_level_01_asset_dressing.gd`, `bee_level_02_lake_scenery.gd`, `asset_fauna.gd`, `destructible_obstacle_3d.gd`, `garden_props.gd`, `bee_alien_bomb.gd`, `bee_fauna_sizes.gd`.
3. **Escenas jugables**: `scenes/items/toon/*`, `scenes/projectiles/toon/*`, `scenes/levels/giant_human_hazard.tscn`, `scenes/bee_prototype/bee_shmup_world_scale_human_poc.tscn`, `scenes/bee_prototype/visuals/*`.
4. **`manifest.json` de cada tanda** (campos `glb` y `source`) y `ASSET_MANIFEST.md`.
5. **Scripts de laboratorio** (`scripts/art/*.gd`, `art_delivery_hub_v01.gd`, `asset_catalog_lab.gd`) que listan carpetas por nombre de tanda.
6. **Tests** que cargan rutas: 5 suites (`garden_backdrop`, `human_reuse`, `lake_fauna`, `pickups_toon`, `swarm_lite`).
7. **Fuentes `.blend`**: los `.blend` guardan rutas de exportación relativas o absolutas; los scripts de `tools/art/` que regeneran GLB (y el campo `source` de los manifests) deberían recibir la ruta nueva.
8. **Documentación**: `docs/art/*_V0N.md`, `ASSET_PROVENANCE.md`, informes.

## Orden recomendado

1. Moverlo todo en Godot (editor: arrastrar en FileSystem) para reescribir `uid`/rutas, una tanda por vez, con la suite verde entre tandas.
2. Primero tandas de un solo uso (aliens L05, cielo L04), luego las del Nivel 01 en juego (riesgo mayor).
3. Resolver duplicados antes: `swarm_lite_v01` vs `v01/v03/v09`.
4. No borrar nada: las carpetas `future_biomes_vNN` quedan con un README apuntando al destino.
5. Una pasada completa de tests al final; revisar `dev/` (capturas y logs) como documentos históricos, sin actualizar.

Riesgos: rutas construidas por concatenación en runtime (no detectables por búsqueda estática), `uid` duplicados si se copia en lugar de mover, y reimportación larga.
