# Jardín — dos lombrices y tres hongos, v01

Fecha: 2026-10-12. Rama conservada: `lote-11`. Diseños originales nuevos del Nivel 01; se conservan todos los modelos anteriores, incluido el hongo cañón existente.

## Ficha del pedido

**Lombriz rosada:** larga y fina, 16 segmentos móviles, extremos afinados y clitelo natural cálido. **Lombriz de compost:** más corta y gruesa, 12 segmentos móviles, curvatura lateral suave y clitelo ocre. Sin patas, ojos inventados, gore ni mutación. Para continuar la tanda de enemigos, ambas incluyen un pequeño implante dorsal externo, separado y desmontable, además de GLB liberados con el cuerpo completo.

**Hongo botón pequeño:** sombrero marrón redondeado y tallo corto crema. **Hongo de copa mediano:** sombrero ancho de perfil más plano, ocre cálido, con tallo más largo. **Hongo rojizo grande:** copa abovedada con seis manchas claras, tallo crema alto y base ensanchada. Son elementos naturales del entorno, sin armas, implantes, emisión ni física; no se convierten automáticamente en enemigos. Las formas se modelaron por perfiles distintos, no solo cambiando la escala de un único hongo.

Paleta natural tierra/rosa/ocre/crema/rojo apagado. Cian y violeta exclusivos del implante de las lombrices. Sombreado cel y contorno fino mediante el estilo Godot del proyecto; fuentes Blender y GLB con PBR portable.

## Presupuesto y escala

Bee ≈ 1 unidad. Medidas de la pose exportada X/Y/Z Godot. +Y arriba, orientación frontal de lombrices -X y origen de referencia en el suelo; las lombrices mantienen una separación pequeña sobre la base.

| Modelo | Tris | Materiales | Tamaño X/Y/Z (m) |
|---|---:|---:|---|
| Lombriz rosada | 4532 | 4 | 3.01 / 0.37 / 0.367 |
| Lombriz rosada liberada | 4256 | 1 | 3.01 / 0.253 / 0.367 |
| Lombriz de compost | 3636 | 4 | 2.162 / 0.528 / 0.65 |
| Lombriz de compost liberada | 3360 | 1 | 2.162 / 0.418 / 0.65 |
| Hongo botón pequeño | 584 | 1 | 0.7 / 0.703 / 0.7 |
| Hongo de copa mediano | 584 | 1 | 1.24 / 1.013 / 1.24 |
| Hongo rojizo grande | 1184 | 1 | 1.82 / 1.737 / 1.82 |

Presupuesto: lombrices ≤5.000 tris, hongos ≤2.000. Cada hongo usa un solo material con paleta plana embebida. Las cinco fuentes empacan su PNG de 8×2 píxeles; no requieren bibliotecas ni descargas externas.

## Movimiento y anclas

Lombrices: `idle` (2,0 s), `crawl` (2,0 s) y `recoil` (1,4 s). Segmentos `Segment_00…15` o `00…11`; onda lateral, contracción leve al reptar y reacción elevando la parte delantera. Las piezas se animan por nodos independientes superpuestos, no por un esqueleto de deformación. El reptado no traslada la raíz por el nivel; el futuro controlador hará ese desplazamiento. Anclas `GroundAnchor`, `HeadAnchor`, `BodyAnchor`, `ImplantAnchor`.

Hongos: `idle` (2,0 s, cambio de escala vertical muy leve) y `sway` (2,4 s, balanceo suave opcional). Se pueden dejar estáticos con `preview_motion=false`. Anclas `GroundAnchor`, `BaseAnchor` y `CapAnchor`. Los tres tienen origen de colocación sobre el suelo y siguen siendo objetos naturales no emisivos.

## Archivos y cómo revisar

- Fuentes de lombrices: `art_source/blender/levels/level_01_garden/enemies/lvl01_enemy_worm_{rose,compost}_v01.blend`.
- Fuentes de hongos: `art_source/blender/levels/level_01_garden/environment/lvl01_environment_mushroom_{button,umbrella,spotted}_v01.blend`.
- GLB en las mismas rutas relativas dentro de `assets/models/levels/level_01_garden/`; lombrices con variantes `_liberado.glb`. Total: **cinco fuentes y siete GLB**.
- Manifiesto conjunto: `assets/models/levels/level_01_garden/garden_floor_v01_manifest.json`; cinco manifiestos individuales junto a los modelos.
- Constructor: `tools/art/create_garden_floor_v01.py` con argumento `-- worm_rose`, `-- worm_compost`, `-- mushroom_button`, `-- mushroom_umbrella` o `-- mushroom_spotted` tras el script Blender. Solo genera las rutas nuevas de esta tanda.
- Wrapper: `scripts/art/garden_floor_visual.gd`; contorno de actor para lombrices y de prop para hongos. Script de controles: `scripts/art/garden_floor_lab.gd`.
- Laboratorio: abrir `scenes/art_labs/garden_floor_v01.tscn`, ejecutar **F6**. De izquierda a derecha: dos lombrices, hongo pequeño, mediano y grande. **1** reposo, **2** reptar/balancear, **3** reacción, **L** retirar/colocar implantes de las lombrices.
- Prefabs instanciables: `scenes/art_labs/garden_floor_v01/<variante>.tscn`; lombrices también con sufijo `_liberated.tscn`.
- Renders de los GLB reales en Godot Compatibility: `concept_art/levels/level_01/garden_floor_v01/overview.png`, `movement_preview.gif`, imágenes hero y hojas `lvl01_<variante>_concept_v01{,_liberado}.png`. Fondo neutro sin suelo, entorno, texto ni UI. El GIF acomoda los cinco assets en dos filas para verlos mejor; el laboratorio conserva la comparación horizontal de tamaños.

## Verificación

Blender verificó mallas cerradas, ausencia de caras degeneradas, triángulos exportados y materiales. Validación dirigida `tests/art/validate_garden_floor_v01.gd`: **PASS**. Comprueba budgets, segmentos, reptado/balanceo, tamaño pequeño<mediano<grande, seis manchas naturales, anclas, toon/contorno, liberación, falta de tecnología/emisión en hongos y ausencia de colisiones. Las capturas permitieron ajustar las manchas al perfil del sombrero y encuadrar completos los modelos.

Suite completa ejecutada una sola vez: **91/91 PASS**, 186,3 s, sin errores de script. Logs: `dev/garden_floor_full_suite_result.log` y `dev/garden_floor_full_suite.log`.

Logs: `dev/garden_floor_<variante>.log`, `dev/garden_floor_import.log`, `dev/garden_floor_validation.log`, `dev/garden_floor_capture.log`, `dev/garden_floor_motion.log`. Los avisos de caché de miniaturas Blender fuera del proyecto no impidieron guardar las fuentes ni exportar los GLB.

No se modificaron scripts de gameplay, oleadas ni modelos anteriores. Pendiente: integrar lombrices como enemigos (IA/HP/daño/colisiones) y colocar los hongos en el jardín. No se hizo commit/push.
