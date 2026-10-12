# Laguna — nube de mosquitos, tortuga pintada y salamandra acuática, v01

Fecha: 2026-10-12. Rama conservada: `lote-11`. Tanda para `level_02_lake`, categoría enemigo/fauna controlada liberable. Se entregan modelos y animaciones para integración posterior; no se modifica el nivel jugable ni sus oleadas.

## Diseño y procedencia

**Nube de mosquitos:** seis miembros con vuelo independiente, dos alas articuladas por animal, patas largas, probóscide y abdomen segmentado. Se importaron las mallas internas de la fuente original `art_source/blender/levels/level_02_lake/enemies/controlled_mosquito.blend`; corresponde al diseño que también tiene versión ligera en `swarm_lite_v01`. Se redujeron solo copias nuevas para esta nube, se reunieron las piezas estáticas en un cuerpo natural y un implante y se conservaron las alas separadas. Las seis instancias comparten datos de malla. La fuente original se verificó por SHA-256 antes y después del proceso, sin guardarla ni modificarla.

Referencia original SHA-256: `48d024563dc910fd320c8a37d1f782948446abfcee27014c8e720d84e65b30cc`.

**Tortuga pintada:** caparazón oscuro abovedado, plastrón cálido, marcas rojizas en borde y mejillas, patas con dedos, cabeza, mandíbula y cola móviles. Diseño original, verde/ocre/rojo natural no emisivo; mochila externa grafito con núcleo cian y nodo violeta sobre el caparazón, totalmente separada del animal.

**Salamandra acuática:** diseño de tritón acuático estilizado, cuerpo pardo/ocre con manchas cálidas, cuatro patas con dedos y cola con aleta y tres articulaciones. Cabeza y mandíbula móviles. Sin mutación ni branquias alienígenas; implante dorsal externo y retirable. Diseño nuevo original del proyecto.

Los tres usan la paleta de naturaleza cálida, formas suaves, dos/tres bandas toon y contorno fino del proyecto. Cian/violeta y emisión pertenecen exclusivamente a los implantes. No hay gore ni cuerpo reemplazado por tecnología.

## Presupuesto y escala

Bee ≈ 1 unidad. Medidas de la pose exportada X/Y/Z Godot, +Y arriba y frente -X; la raíz es referencia de colocación y la nube está en vuelo sobre ella.

| Asset | Tris controlado/liberado | Materiales | Tamaño X/Y/Z (m) |
|---|---|---|---|
| Tortuga pintada | 4908 / 4580 | 4 / 1 | 2.706 / 1.118 / 2.12 |
| Salamandra acuática | 4112 / 3784 | 4 / 1 | 3.955 / 0.773 / 1.3 |
| Nube de seis mosquitos | 4680 / 3696 | 4 / 1 | 2.873 / 2.142 / 1.16 |

Tope de **5.000 triángulos por enemigo**, incluida toda la nube. En ella se cuentan seis instancias: **4.680 triángulos dibujados**, a partir de solo **780 triángulos únicos almacenados**. Variante liberada: 3.696 dibujados/616 únicos. La nube conserva nodos animados y no usa MultiMesh; comparte las mallas, pero cada nodo aún tiene sus llamadas de dibujo.

Máximo cuatro materiales por GLB. Paleta natural de 8×2 píxeles empacada en `.blend` y embebida en GLB. La copia del mosquito conserva sus colores cálidos equivalentes del original al reunir los cinco materiales naturales en una paleta.

## Movimiento y anclas

Cuatro clips exportados por modelo: `idle` (2,0 s), `swim` (1,6 s), `attack` (1,4 s) y `liberate` (1,6 s). En los mosquitos, `swim` es el clip de vuelo mantenido con ese nombre para el laboratorio compartido. La nube cambia de separación/profundidad y mueve alas con fases diferentes.

La tortuga anima cuatro patas, cabeza, mandíbula y cola. La salamandra agrega `TailBase`, `TailMid` y `TailTip` con ondulación de natación. Son animaciones rígidas de piezas jerárquicas, no un esqueleto de deformación. El clip de ataque representa avance de cabeza/apertura de boca en vertebrados y avance local de los mosquitos, sin daño. El desplazamiento por el lago y la selección de objetivo corresponden al futuro controlador.

Anclas: vertebrados `ImplantAnchor`, `MuzzleAnchor` en la cabeza, `BodyAnchor`, `GroundAnchor`; nube `ImplantAnchor_00…05`, `MuzzleAnchor_00…05`, cuerpo y raíz. El clip `liberate` no elimina tecnología por sí mismo: usar `release_control()` del wrapper o el GLB liberado.

## Entrega y prueba

- Fuentes: `art_source/blender/levels/level_02_lake/enemies/lvl02_enemy_{turtle,salamander,mosquito_cloud}_v01.blend`, cámara/luz de estudio y pistas NLA editables.
- Exportados: `assets/models/levels/level_02_lake/enemies/` con mismos nombres y variantes `_liberado.glb`.
- Manifiesto conjunto: `lake_creatures_v01_manifest.json`, más tres manifiestos individuales. Incluye referencia/hash del mosquito original.
- Constructor reproducible: `tools/art/create_lake_creatures_v01.py` con argumento `-- turtle`, `-- salamander` o `-- mosquito_cloud` tras el script Blender. Solo guarda las rutas nuevas de esta tanda.
- Wrapper: `scripts/art/lake_creatures_visual.gd`; PBR portable en Blender/GLB, toon y contorno final mediante Godot.
- Laboratorio: abrir `scenes/art_labs/lake_creatures_v01.tscn` y ejecutar **F6**. Tortuga izquierda, salamandra centro, nube derecha. **1** reposo, **2** natación/vuelo, **3** ataque, **4** movimiento de liberación, **L** retirar/colocar implantes.
- Prefabs: `scenes/art_labs/lake_creatures_v01/{turtle,salamander,mosquito_cloud}.tscn` y sufijo `_liberated.tscn`. La nube puede instanciarse varias veces en el nivel.
- Capturas: `concept_art/levels/level_02/lake_creatures_v01/overview.png`, `movement_preview.gif`, vistas individuales y hojas `lvl02_enemy_<variante>_concept_v01{,_liberado}.png`. Vistas del mismo GLB real en Godot Compatibility, gris neutro sin suelo, entorno, texto ni UI.

## Verificación

Blender verificó mallas cerradas sin caras degeneradas, presupuesto, materiales y fuente de mosquito sin modificar. Prueba dirigida `tests/art/validate_lake_creatures_v01.gd`: **PASS**. Comprueba presupuesto contando instancias, seis mosquitos/doce alas, anatomía importada con escala/posición conservada, movimiento independiente, cuatro patas en vertebrados, tres articulaciones de cola, clips, anclas, toon/contorno, emisión solo tecnológica, liberación y ausencia de físicas. Renders y GIF revisados; la revisión detectó y corrigió la reconstrucción de transformaciones de las piezas importadas antes de la entrega.

Suite completa ejecutada una sola vez: **90/90 PASS**, 205,4 s, sin errores de script. Registros: `dev/lake_creatures_full_suite_result.log` y `dev/lake_creatures_full_suite.log`.

Logs: `dev/lake_{turtle,salamander,mosquito_cloud}_build.log`, `dev/lake_creatures_import.log`, `dev/lake_creatures_validation.log`, `dev/lake_creatures_capture.log`, `dev/lake_creatures_motion.log`. Aviso no bloqueante de caché de miniaturas Blender fuera del proyecto; fuentes y GLB guardados y validados.

Pendiente de integración jugable: IA, HP, colisiones, daño, desplazamiento y oleadas. No se reemplazaron assets existentes ni se hizo commit/push.
