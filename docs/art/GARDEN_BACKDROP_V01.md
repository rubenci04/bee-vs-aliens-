# Bee Alien · Objetos de jardín 01

Cuatro modelos originales para reforzar el jardín del Nivel 01, con escala humana respecto de Bee, siluetas simples, paleta natural sin emisión y los shaders toon existentes. Fuentes Blender conservadas y GLB exportados. Sin biblioteca externa.

| Modelo | Triángulos | Uso |
| --- | ---: | --- |
| `garden_hose` | 3.424 | Manguera enrollada de suelo, extremo suelto y boquilla de latón |
| `garden_watering_can` | 2.624 | Regadera verde salvia, recipiente hueco, dos asas y rociador |
| `garden_fence_module` | 2.404 | Valla modular de madera con siete listones y dos postes |
| `garden_distant_house` | 2.116 | Casa de poco espesor para fondo lejano, tejado apagado y ventanas sin emisión |

Cada modelo tiene una malla agrupada y varias superficies de material. Los contornos añaden pases de dibujo; los recuentos de triángulos no son un benchmark de rendimiento. La casa es una pieza de fondo vista de frente, no un edificio para explorar. La manguera se muestra inclinada en el estudio para distinguir las vueltas; en la composición descansa casi horizontal.

## Archivos nuevos

- Fuentes: `art_source/blender/garden_backdrop_v01/*.blend` y `.gdignore`.
- Exportaciones: `assets/models/garden_backdrop_v01/*.glb`, sus importaciones y `manifest.json`.
- Wrappers toon: `scenes/art_labs/garden_backdrop_v01/*.tscn`.
- Galería: `scenes/art_labs/garden_backdrop_v01.tscn` y `scripts/art/garden_backdrop_lab.gd`.
- Generador: `tools/art/create_garden_backdrop_v01.py`.
- Validación: `tests/art/validate_garden_backdrop_v01.gd`.
- Capturas reales: `docs/art/garden_backdrop_v01/`, estudio, composición y vistas individuales lateral/3/4.

Se actualizan el índice `scripts/art/art_delivery_hub_v01.gd`, la comprobación de sus enlaces `tests/art/validate_mothership_and_title_v01.gd` y `tools/art/capture_catalog.gd` para capturar también la composición del jardín. La composición reutiliza flores locales y la referencia de Bee existente.

## Cómo probar

Abrir `scenes/art_labs/garden_backdrop_v01.tscn` en Godot y pulsar **F6**. También se puede acceder desde **Colección de arte** en la pantalla de título.

- **1–4**: inspeccionar una pieza.
- **V**: lateral / 3/4.
- **G**: ver la composición de jardín a escala humana.
- **E**: regresar al estudio de las cuatro piezas.
- **H**: ocultar interfaz para una vista limpia.
- **Esc**: volver al índice.

Para usar las piezas, instanciar los wrappers `.tscn`, que aplican el cel shading. Aún no están colocadas en el nivel jugable ni tienen colisiones o un controlador de parallax; se entregan como assets de presentación.

## Verificación y problemas

Generador Blender: sólidos cerrados, normales recalculadas, sin caras degeneradas y presupuesto inferior a 5.000 triángulos por objeto. Validator Godot: recuentos reales del GLB coinciden con el manifiesto, fuentes presentes, toon/contorno activos y emisión natural ausente: **0 fallos**. Revisión visual en Compatibility de estudio, composición y regadera 3/4. Se corrigió la altura del suelo del estudio para que no ocultara la valla y se oscureció el interior de la regadera para leer su cavidad.

Godot mantiene la advertencia conocida de caché `user://` y preferencias del editor en esta sesión restringida; no impidió importar o capturar. No se modificó el Nivel 01 jugable ni otros proyectos.
