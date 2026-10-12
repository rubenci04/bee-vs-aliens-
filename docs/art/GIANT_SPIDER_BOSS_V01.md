# Araña gigante con exoesqueleto alien — Nivel 01

Entrega original del 2026-10-12, creada y exportada en Blender 5.2.1. Se tomó la ficha adjunta como referencia de entrega; el pedido fue diseñar el modelo para el juego. No se reemplazó el UFO ni se agregó comportamiento de combate.

## Ficha del pedido

- Nombre: `lvl01_boss_giant_spider_v01`; nivel `level_01_garden`; categoría jefe.
- Función propuesta: araña terrestre controlada, liberable al destruir el dispositivo externo. Esta entrega prepara la geometría y sus anclas; HP, patrones y colisiones se definirán al integrarla.
- Escala: 6,44 m de largo, 3,07 m de alto, 4,32 m de profundidad, incluidas patas y armadura. Equivale a ~5,46 largos de Bee (1,18 m). Base en Y=0; +Y arriba, -X adelante, como la fauna existente.
- Lectura: abdomen grande, frente con ocho ojos ámbar y quelíceros, ocho patas articuladas y bridas grafito claramente externas. Anatomía natural marrón/ocre intacta; placas sobre el abdomen y tórax, núcleo cian dorsal y cuatro nodos violetas sin emisión.
- Presupuesto: ≤12.000 triángulos, cumpliendo también el máximo de jefe de 25.000 de la ficha adjunta.
- Variantes: controlada y liberada sin tecnología; ambas usan la misma fuente `.blend`.
- Anclas: `ImplantAnchor`, `BodyAnchor`, `MuzzleAnchor`, `SilkAnchor`, `GroundAnchor`.
- Animación: pivotes rígidos editables, no armature ni skinning. `idle` de 2 s, `walk` de 1,2 s, `attack` de 1,4 s. Reposo/caminar tienen poses coincidentes al inicio/final y se reproducen en loop en el laboratorio; ataque es de una pasada.
- Referencia: biblia de estilo C, implantes externos del proyecto y araña colgante del inventario. Es geometría nueva; no se reconstruyó ni sustituyó ningún modelo existente.
- Origen/licencia: creación propia del proyecto con primitivas y mallas generadas en Blender, sin biblioteca externa.

## Archivos

| Entrega | Ruta | Triángulos | Materiales |
|---|---|---:|---:|
| Fuente editable | `art_source/blender/levels/level_01_garden/bosses/lvl01_boss_giant_spider_v01.blend` | 11.652 | 4 |
| GLB controlada | `assets/models/levels/level_01_garden/bosses/lvl01_boss_giant_spider_v01.glb` | 11.652 | 4 |
| GLB liberada | `assets/models/levels/level_01_garden/bosses/lvl01_boss_giant_spider_v01_liberado.glb` | 8.584 | 1 |

La liberada conserva 6,44 × 2,65 × 4,32 m. Colores naturales mediante una paleta PNG de **8 × 2 píxeles**, embebida en ambos GLB y empacada en la fuente Blender. Son colores planos, sin detalle fotográfico. Esta paleta permite cuerpo, manchas y ojos con un solo material natural, manteniendo cuatro materiales totales y la importación directa con color. Materiales grafito, cian y violeta para tecnología; solo `implant_core` tiene emisión. El contorno se aplica en el shader del juego, no está horneado en la geometría.

Fuente con cámara de estudio, luces y tracks NLA editables. Constructor reproducible: `tools/art/create_giant_spider_boss_v01.py`. Estadísticas exportadas: `assets/models/levels/level_01_garden/bosses/lvl01_boss_giant_spider_v01_manifest.json`.

## Cómo visualizar

Abrir `scenes/art_labs/giant_spider_boss_v01.tscn` y ejecutar F6. Izquierda: controlada; derecha: liberada. Teclas **1** reposo, **2** caminar, **3** ataque; **L** oculta o vuelve a mostrar toda la armadura de la controlada, incluidas las ocho bridas de patas.

En Blender abrir la fuente y usar F12 para la vista de estudio. El material fuente es PBR exportable; la presentación cel shading definitiva usa los shaders existentes de Godot. En NLA, activar solo el track que se quiera editar; reposo está activo al abrir.

Hoja de cuatro vistas del mismo modelo, fondo gris liso, sin suelo/sombras/textos: `concept_art/levels/level_01/giant_spider/lvl01_boss_giant_spider_concept_v01.png` y `_liberado.png`. Render lateral con luz cálida y toon del proyecto: `side.png`; vista general: `hero.png`. Generadas desde el GLB real en Godot Compatibility, no desde una ilustración independiente.

## Verificación

Blender comprobó mallas cerradas, sin caras degeneradas, presupuesto y tres clips en ambos GLB. `validate_giant_spider_boss_v01.gd` comprueba ocho pivotes, triángulos reales importados, base, escala, anclas, contorno/toon, emisión solo del núcleo, movimiento del caminar y desaparición completa de tecnología al liberar. Revisión visual de vistas lateral, frontal, trasera y superior completada.

**Suite completa: 84/84 PASS**, una sola pasada, sin errores de script. La validación dirigida del asset se repitió después de cerrar la paleta embebida y también pasó. Logs: `dev/giant_spider_full_suite_result.log`, `dev/giant_spider_validation.log`, `dev/giant_spider_render.log`. Modelo listo como asset; la integración de IA, daño y reemplazo del jefe queda fuera de este pedido de diseño. No se hizo commit/push.

Aviso no bloqueante: Blender no pudo escribir la miniatura de caché del perfil de Windows por permisos; el `.blend` se guardó correctamente. La revisión visual se hizo con los renders reales de Godot.
