# Bee Alien · Suelo de jardín y bosque

Tres props originales para completar la vegetación y los obstáculos naturales del catálogo. Usan verdes naturales, marrones cálidos, coral y crema, sin emisión. Cel shading, contorno fino y formas suaves con el estilo compartido del proyecto. No se importaron bibliotecas externas.

| Pieza | Triángulos | Uso visual |
| --- | ---: | --- |
| Tronco caído hueco | 1.972 | Pared de madera cerrada alrededor de un hueco continuo, cortes claros, rama corta y musgo amplio. Referencia vacía `HollowEntrance` en la boca. |
| Helecho | 2.940 | Cinco frondas curvas y cuarenta hojuelas con volumen; vegetación baja para jardín y bosque. |
| Campanilla | 2.824 | Dos corolas abiertas coral, interiores crema, estambres con polen dorado y hojas lanceoladas. |

Una malla por prop, con 4/3/5 superficies de material respectivamente. Cada sólido se comprueba en Blender: aristas manifold y caras sin degeneración. Fuentes sin rig ni animación de viento. La escala final se ajusta por instancia; la galería compara una Bee diminuta con plantas y madera grandes.

## Archivos de esta tarea

- `art_source/blender/forest_floor_v01/`: `hollow_fallen_log.blend`, `forest_fern.blend`, `garden_bellflower.blend` y `.gdignore`.
- `assets/models/forest_floor_v01/`: los tres GLB y `manifest.json`, con recuentos y rutas de fuente.
- `scenes/art_labs/forest_floor_v01/`: tres escenas reutilizables con el script toon existente.
- `scenes/art_labs/forest_floor_v01.tscn`, `scripts/art/forest_floor_lab.gd`: estudio y composición de jardín.
- `tools/art/create_forest_floor_v01.py`: generador editable basado en helpers originales V09.
- `tests/art/validate_forest_floor_v01.gd`: verificación en Godot.
- `docs/art/forest_floor_v01/`: estudio, jardín y vistas lateral/3/4 por pieza. Capturadas con `tools/art/capture_catalog.gd`.
- Modificado `scripts/art/art_delivery_hub_v01.gd`: acceso al lote y altura de botones a 64 px para acomodar la fila adicional.
- Actualizado `docs/art/ENVIRONMENT_ROADMAP.md` con este lote disponible.

## Cómo probar

Abrir `scenes/art_labs/forest_floor_v01.tscn` y ejecutar **F6**, o seleccionar **Tronco, helecho y campanilla** en la colección.

**G** muestra la composición de jardín; **1/2/3** inspeccionan las piezas; **V** alterna lateral y 3/4; **H** oculta la interfaz; **E** vuelve al estudio conjunto; **Esc** vuelve a la colección. Las vistas individuales contienen solamente el prop y un fondo neutro.

Para integrar, instanciar los wrappers `.tscn` bajo el nivel y ajustar escala y profundidad Z. Los GLB usan XY como plano lateral y +Y arriba. El tronco incluye una leve orientación en profundidad para mostrar la boca desde la cámara lateral. `HollowEntrance.global_position` puede servir de referencia al colocar contenido junto a la abertura.

## Verificación y problemas

**0 fallos** en Godot 4.7.2 Compatibility: tres importaciones, presupuestos reales, una malla por pieza, shader toon y contorno, ausencia de emisión y control alien, marcador del tronco, composición con Bee y fichas limpias. La navegación de la colección también pasó con 0 fallos. Logs: `dev/forest_floor_v01_test.log`, `dev/forest_floor_v01_hub.log`, `dev/forest_floor_v01_capture.log`. Capturas revisadas visualmente.

Son assets visuales: todavía sin colisiones ni viento, y no se colocaron automáticamente en el nivel jugable. Si el tronco se usa como paso jugable, su colisión debe respetar el hueco; una envolvente convexa única lo cerraría. La composición usa formas de fondo de revisión, no un nuevo set de terreno exportado. No se midió rendimiento con muchas instancias.

Avisos del entorno restringido: caché de shaders/ajustes del editor de Godot y miniaturas externas de Blender. Los `.blend`, GLB, pruebas y capturas se guardaron correctamente.
