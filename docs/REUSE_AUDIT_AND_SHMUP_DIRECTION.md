# Reuse audit y dirección SHMUP

## Dirección acordada

Bee Alien 3D debe avanzar como **shooter arcade aéreo de desplazamiento lateral**: Bee vuela en X/Y, esquiva y dispara, enfrenta oleadas breves y llega a un cierre claro. Las amenazas se organizan en fauna terrestre, humanos y tecnología extraterrestre. La detección humana sigue siendo un POC secundario; no define el bucle principal. Esta auditoría sólo propone reutilización: no autoriza importar ni copiar recursos todavía.

## Tucumán Rush 3D: qué reutilizar

| Recurso comprobado | Estado | Decisión |
|---|---|---|
| Ciruja, Hipster, Agente y Grandote: `.blend` + `.glb` en `art_source/blender/characters/` y `assets/models/characters/` | Cuatro humanos low-poly, 18 huesos, seis clips comunes (Idle, Run, Throw, Jump, Fall, Melee) | **Adaptar** como siluetas humanas; probar escala y cámara lateral de Bee antes de importar. Agente y Hipster son los candidatos inmediatos; Grandote sirve como amenaza pesada; Ciruja sólo si su identidad encaja. No se verificó un civil/NPC adicional. |
| `rig_animation_poc.blend`, `rig_test_normal.glb`, `rig_test_heavy.glb` | Contrato común de 18 huesos, seis clips | **Referencia** para integrar los humanos; no sustituir el rig ni las animaciones de Bee. |
| `orange_projectile.gd`, `bottle_projectile.gd`, `bullet_projectile.gd`, `drone_bomb_projectile.gd` y escenas homónimas | Proyectil lanzado, botella y bala mayormente horizontales, bomba descendente | **Adaptar conceptos**, sobre todo lanzamiento, equipo y daño. La botella y la bala requieren puntería X/Y para un juego aéreo. Mantener el sistema de proyectiles ya existente en Bee. |
| `basic_enemy.gd`, `hipster_enemy.gd`, `agente_enemy.gd`, `grandote_enemy.gd`, `drone_enemy.gd` | IA melee, ranged, heavy y aérea con windup/bomba | **Adaptar patrones** de telegraph, reposicionamiento y enfriamiento; no copiar controladores atados al suelo/banda Z. |
| `attack_definition_3d.gd`, `enemy_definition_3d.gd`, `encounter_director.gd` | Datos de ataque/enemigo y activación por umbral X | **Adaptar** sólo los campos y la lógica que necesiten oleadas aéreas. Rangos Z, persecución de piso y progresión de Ruta 38 no se trasladan literalmente. |
| `health_component.gd`, hitbox/hurtbox y HitFlash | Bee ya dispone de equivalentes | **No copiar**: conservar los componentes del proyecto Bee y evitar dos contratos de daño. |
| Props de Route 38 (`low_wall`, `distant_house`, `famailla_sign` y composición de slices) | Escenografía vial | **Referencia visual / adaptación puntual** para planos de fondo; no importar slices completos. No se localizaron modelos dedicados de vehículos reutilizables. |

Los GLB humanos verificados son aproximadamente: Ciruja 2346 tris/11 materiales, Hipster 2480/8, Agente 2108/8 y Grandote 3292/7. Son cifras documentadas en sus POC, no una nueva medición geométrica.

## Biblioteca externa: naves y licencia

El inventario `D:\proyectos\V_Asset_Library\asset_inventory.csv` contiene **16 candidatos nominales de nave/dron aéreo**: ocho `craft_*` de Kenney Space Kit, un `Enemy_EyeDrone` de Quaternius y siete extras tipo UFO/ship. **Nueve** tienen licencia local CC0 verificada (los ocho Kenney y EyeDrone). Los siete extras carecen de licencia local comprobable: **LICENSE REVIEW; no usar en producción**. Las licencias locales de Kenney Space Kit y Quaternius Sci-Fi Essentials/Modular SciFi indican CC0 1.0; uso comercial permitido, atribución no obligatoria. El inventario no equivale a validación visual, escala, importación Godot ni encaje artístico.

| Familia | Candidatos con licencia comprobada | Uso propuesto |
|---|---|---|
| AIR LIGHT | `Enemy_EyeDrone`, `craft_speederA/B/C/D`, `craft_racer` | Oleadas rápidas y reconocimiento. EyeDrone es el candidato alien más directo; los craft Kenney requieren revisión de silueta/paleta. |
| AIR HEAVY | `craft_cargoA/B`, `craft_miner` | Naves más grandes o lentas, sólo tras prueba de escala y lectura. No hay gunship validada. |
| GROUND | `rover`, `turret_single`, `turret_double` (Kenney) | Amenazas terrestres de apoyo, separadas de las oleadas aéreas. |
| SUPPORT | `satelliteDish` y variantes (Kenney), `Prop_SatelliteDish` (Quaternius) | Antenas/objetivos o decorado; no son enemigos aéreos por sí solos. |
| BOSS | Sin nave nodriza dedicada con licencia y apariencia validadas | `craft_cargoB` podría ser proxy temporal, pero no declararlo boss final. Los UFO de `extras` siguen en LICENSE REVIEW. |

Las tres criaturas alienígenas de Quaternius Modular SciFi (`Alien_Cyclop`, `Alien_Oculichrysalis`, `Alien_Scolitex`) son candidatos terrestres futuros, no naves. Los módulos `rocket_*` de Kenney son piezas, no vehículos completos.

## Shortlist para acelerar un POC (14 recursos; ningún traslado en esta tarea)

1. Agente GLB + fuente Blender — amenaza humana de disparo.
2. Hipster GLB + fuente Blender — humano que lanza objetos.
3. Grandote GLB + fuente Blender — amenaza humana pesada ocasional.
4. AlienProbeRanged actual de Bee — base alienígena ya jugable.
5. `Enemy_EyeDrone` — AIR LIGHT externo CC0.
6. `craft_speederA` — AIR LIGHT externo CC0, pendiente de prueba visual.
7. `craft_racer` — AIR LIGHT rápido externo CC0, pendiente de prueba visual.
8. `craft_cargoA` — AIR HEAVY proxy externo CC0, pendiente de escala.
9. `turret_single` — GROUND externo CC0.
10. `rover` — GROUND externo CC0.
11. `orange_projectile.gd` — patrón de lanzamiento humano; adaptar a Bee.
12. `bullet_projectile.gd` — patrón de disparo humano; adaptar dirección X/Y.
13. `drone_enemy.gd` — referencia de posicionamiento aéreo y bomba; no copiar IA.
14. `encounter_director.gd` — referencia para activación y fin de oleada; rediseñar para scroll.

## Mapa de reutilización y familias

**Conservar en Bee:** BeePlayer, Wasp, AlienProbe, Health/HitFlash, proyectiles, daño, derrota/restart y encuentros ya funcionales. **Adaptar desde Tucumán:** humanos y su rig como arte, patrones de bala/objeto lanzado, estados ranged/heavy/aerial, definiciones y dirección de encounters. **No conviene trasladar:** banda Z 2.5D, cámara de Ruta 38, slices completos, duplicados de componentes de salud/daño, ni extras sin licencia local.

Familias propuestas: **fauna** (Wasp y variantes), **humanos** (observador/detector secundario, tirador Agente, lanzador Hipster, pesado Grandote), **alien AIR LIGHT** (Probe/EyeDrone/speeder), **alien AIR HEAVY** (cargo/miner tras evaluación), **alien GROUND/SUPPORT** (torreta/rover/antena) y **BOSS** aún sin asset aprobado. Un modelo compartido no implica compartir IA ni balance.

## Bucle mínimo y decisión siguiente

Bucle: volar y disparar → leer telegraph → esquivar o destruir una oleada corta → recoger curación/recurso si corresponde → avanzar con scroll → siguiente familia → cierre de tramo. La primera validación debe ser **una sola oleada AIR LIGHT en escena aislada usando el AlienProbe existente y el director/encuentro actual de Bee**; sólo después evaluar importación de `Enemy_EyeDrone`. Así se comprueba ritmo de SHMUP sin convertir Human Detection en eje ni introducir una biblioteca completa de golpe.

Limitaciones: esta auditoría es de archivos, inventario y licencias locales; no se abrieron los modelos de la biblioteca en Godot ni se verificaron sus pivotes, escala, polígonos, materiales o legibilidad en movimiento. La ausencia de vehículos/NPC adicionales se refiere a los recursos dedicados encontrados en Tucumán Rush, no a posibles primitivas dentro de escenas.
