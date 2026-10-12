# Nivel 02 — rama flotante, totoras y nenúfares ligeros

Entrega del 2026-10-12, creada en Blender 5.2.1. Tres variantes nuevas, siguiendo la ficha adjunta y el inventario. Se conservan los juncos, nenúfares y raíces que ya estaban en el juego.

## Ficha de diseño

- Nivel: `level_02_lake`; categoría: entorno repetible, decoración sin colisión ni daño.
- **Rama flotante:** madera cálida bifurcada, silueta irregular y cortes claros, sin detalle áspero. Flotación y balanceo suaves.
- **Totoras:** cinco tallos de alturas distintas, espigas marrones y hojas verdes curvadas; grupo compacto para la orilla. Balanceo suave por viento.
- **Nenúfares:** dos hojas carnosas con una muesca real, nervaduras simples y flor rosada con centro amarillo. Flotación suave.
- Escala respecto de Bee (1,18 m): rama ~2,61 largos, totoras ~2,79 largos de alto, grupo de nenúfares ~2,31 largos de ancho.
- Paleta: madera ocre/marrón, verdes naturales y flor rosada/amarilla. Sin cian, tecnología alien ni emisión.
- Presupuesto: máximo 2.000 triángulos por prop; se entregan directamente las versiones `_lite`, sin una copia pesada innecesaria.
- Anclas: `PlacementAnchor` y `WaterlineAnchor` para flotantes; `PlacementAnchor` y `GroundAnchor` para totoras. Origen centrado en la base, +Y arriba, transformaciones de malla aplicadas.
- Animación: clip `idle` de 2 s embebido en cada GLB. Pivotes `FloatPivot` / `WindPivot`; no armature. Amplitud y duración configurables en constantes del constructor.
- Referencia: biblia toon C y flora del lago del inventario. Geometría propia nueva, sin importar biblioteca externa ni modificar modelos anteriores.

## Medidas y presupuesto reales

| Asset | Triángulos | Materiales | Largo × alto × profundidad |
|---|---:|---:|---|
| `lvl02_environment_floating_branch_lite_v01` | 708 | 3 | 3,079 × 0,460 × 1,008 m |
| `lvl02_environment_totoras_cluster_lite_v01` | 1.720 | 4 | 2,118 × 3,293 × 0,430 m |
| `lvl02_environment_flowering_lily_pads_lite_v01` | 1.540 | 4 | 2,722 × 0,485 × 1,673 m |

Materiales planos PBR, sin texturas. Contorno y bandas toon se aplican con los shaders existentes de Godot; no se hornean en la malla. Todos los componentes están separados y nombrados (ramas, hojas, tallos, espigas, pétalos).

## Archivos y uso

- Fuentes `.blend`: `art_source/blender/levels/level_02_lake/environment/`, con los nombres de la tabla. Incluyen cámara y luz de estudio.
- GLB: `assets/models/levels/level_02_lake/environment/`, mismos nombres. Estadísticas: `lake_botanical_v01_manifest.json`.
- Constructor: `tools/art/create_lake_botanical_v01.py`.
- Laboratorio: abrir `scenes/art_labs/lake_botanical_v01.tscn` y ejecutar **F6**. Los tres modelos reproducen su reposo en loop.
- Envoltorios instanciables: `scenes/art_labs/lake_botanical_v01/floating_branch.tscn`, `totoras_cluster.tscn` y `flowering_lily_pads.tscn`.
- Hoja de cuatro vistas por asset: `concept_art/levels/level_02/lake_botanical_v01/lvl02_environment_<nombre>_concept_v01.png`. Fondo gris liso, sin suelo, texto ni sombras. Vistas derivadas del mismo GLB real, usando Compatibility y luz cálida del proyecto. `overview.png` muestra la tanda.

Para ubicar un flotante, alinear su `WaterlineAnchor` con la superficie del agua (0,130 m para la rama, 0,005 m para nenúfares, relativos a la base). Las totoras se colocan con la base sobre el suelo. Son assets listos para instanciar; este pedido no cambia la escena jugable del lago ni añade colisiones.

## Verificación

Blender verificó mallas cerradas sin caras degeneradas, triángulos exportados y máximo de cuatro materiales. Godot verificó escala/origen, sombreado toon y contorno, ausencia de emisión/colisiones, clip animado, cinco espigas y dos hojas independientes. Renders laterales, frontales, traseros, superiores y generales revisados.

Validación dirigida de los tres assets: **PASS**, sin errores de script. Suite completa ejecutada una sola vez: **78/86 PASS, ocho fallos**. El resultado corresponde al estado actual de `lote-11`, que también contiene cambios de gameplay (regadera como nuevo momento, progresión/daño/HUD y efectos). Los nuevos modelos no están referenciados por scripts o escenas jugables y su wrapper no altera esos sistemas. Se preservó ese trabajo; este pedido y la ficha excluyen editar código del juego.

Pruebas que fallaron:

- `validate_bee_audio_basic_v01`: audio/daño de impacto `tech_hit`.
- `validate_bee_combat_vfx_v01`: expectativa de daño de impacto.
- `validate_bee_arcade_rebuild_v02`: lista de momentos incluye el nuevo `watering_can`.
- `validate_bee_boss_fight_v04`: el bot no completó el estado `SECTOR DESPEJADO`.
- `validate_bee_checkpoint_qol_v01`: snapshot/curación/inventario.
- `validate_bee_level01_arcade_director_v01`: lista de momentos incluye `watering_can`.
- `validate_bee_level01_challenge_balance_v01`: contacto `RightFoot`, daño esperado 20.
- `validate_bee_level01_transformation_v01`: lista de momentos incluye `watering_can`.

Resultados completos: `dev/lake_botanical_full_suite_result.log` y `dev/lake_botanical_full_suite.log`. La entrega de geometría está completa; la suite general del juego no está verde. No se corrigieron esos sistemas dentro de esta tarea de arte. Logs: `dev/lake_botanical_validation.log`, `dev/lake_botanical_render.log`, `dev/lake_botanical_build.log`. No se hizo commit/push. Aviso no bloqueante: Blender no pudo guardar miniaturas de caché en el perfil de Windows; las fuentes y GLB se guardaron y validaron correctamente.
