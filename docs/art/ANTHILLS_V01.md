# Hormigueros del jardín — v01

Fecha: 2026-10-12. Rama conservada: `lote-12`, con cambios de gameplay en curso preservados. Categoría: entorno natural del Nivel 01. Dos diseños originales nuevos, sin importar bibliotecas ni reemplazar assets existentes.

## Diseños

- **Cráter bajo:** montículo ancho de tierra marrón cálida, abertura circular superior y cavidad que desciende 0,385 m desde `EntranceAnchor` hasta la primera superficie interior. Perfil suave irregular, piedras pequeñas y dos briznas de hierba para la escala.
- **Túnel lateral:** montículo más alto y compacto, tierra ocre, entrada visible hacia -X y túnel ciego redondeado. Desde el ancla de entrada hay 1,110 m de profundidad hasta la pared interior. El túnel se modeló mediante resta booleana sobre una malla nueva; el dorso y la base siguen cerrados.

La abertura superior es una concavidad real con pared y fondo; la lateral está cortada dentro de la malla. No son círculos oscuros pegados sobre una superficie plana. Los interiores llevan un tono tierra oscuro no emisivo. Sin tecnología alien ni neón; un único material natural con paleta de 8×2 píxeles embebida y empacada en las fuentes.

## Presupuesto y escala

Bee ≈ 1 unidad. X/Y/Z Godot, +Y arriba, base en el suelo; frente del acceso lateral -X.

| Modelo | Tris | Materiales | Tamaño X/Y/Z (m) |
|---|---:|---:|---|
| Hormiguero bajo con cráter | 1336 | 1 | 2.41 / 0.62 / 2.402 |
| Hormiguero alto con túnel lateral | 1636 | 1 | 1.827 / 1.59 / 1.841 |

Ambos por debajo de 2.000 triángulos. Props estáticos, sin AnimationPlayer, IA, HP, física ni generación automática de hormigas. Se pueden colocar o instanciar como entorno. Para una futura aparición de hormigas se incluyen `EntranceAnchor`, `TunnelAnchor`, `BodyAnchor`, `BaseAnchor` y `GroundAnchor`; el comportamiento corresponderá al controlador de nivel.

## Entrega y revisión

- Fuentes: `art_source/blender/levels/level_01_garden/environment/lvl01_environment_anthill_{crater,side_tunnel}_v01.blend`, cámara/luz de estudio y paleta empacada.
- GLB: mismos nombres en `assets/models/levels/level_01_garden/environment/`.
- Manifiesto conjunto: `anthills_v01_manifest.json`, más un manifiesto por modelo, junto a los GLB.
- Constructor: `tools/art/create_anthills_v01.py` con `-- crater` o `-- side_tunnel` tras el script Blender. Geometría en `tools/art/anthills_geometry_v01.py`, fragmento leído por el constructor.
- Wrapper: `scripts/art/anthills_visual.gd` aplica cel shading y contorno de prop; Blender/GLB conservan PBR portable.
- Laboratorio: abrir `scenes/art_labs/anthills_v01.tscn` y ejecutar **F6**. Comparación de los dos montículos; sin controles especiales ni animaciones.
- Escenas instanciables: `scenes/art_labs/anthills_v01/crater.tscn` y `side_tunnel.tscn`.
- Renders reales Godot Compatibility: `concept_art/levels/level_01/anthills_v01/overview.png`, imágenes hero y hojas `lvl01_environment_anthill_<tipo>_concept_v01.png`. Cuatro vistas de cada GLB real, fondo gris neutro sin entorno, suelo, texto ni UI.

## Verificación

Blender comprobó todas las mallas cerradas y sin caras degeneradas, presupuesto y material. Prueba dirigida `tests/art/validate_anthills_v01.gd`: **PASS**. Verifica conteos, tamaño/perfiles, anclas, base, toon/contorno, paleta, ausencia de emisión/colisiones/animaciones y la profundidad de las entradas mediante intersección de un rayo con los triángulos reales del montículo. Detectaría una abertura sustituida por un disco pintado sin cavidad. Capturas revisadas.

Suite completa ejecutada una sola vez: **92/94 PASS**, 226,4 s. La nueva prueba de hormigueros pasó. Dos validaciones del gameplay actual de `lote-12` fallaron:

- `tests/levels/validate_bee_level_01_vertical_slice.gd`: espera 133 unidades; midió 132 (huecos 13 m y valle 26 m, dentro de sus límites).
- `tests/levels/validate_bee_tarantula_boss_v01.gd`: bot Normal/Base, combate 95,3 s, daño 120 frente al objetivo de 50–70.

Los hormigueros no están referenciados por las escenas/scripts jugables; sus wrappers solo aplican materiales. Se preservaron los cambios de gameplay que ya estaban en curso al comenzar la tarea. No se ajustaron conteos ni daño dentro de este pedido de arte. Resultados: `dev/anthills_full_suite_result.log` y `dev/anthills_full_suite.log`.

Logs: `dev/anthill_crater.log`, `dev/anthill_side_tunnel.log`, `dev/anthills_import.log`, `dev/anthills_capture.log`, `dev/anthills_validation.log`. Los avisos de caché de miniaturas Blender fuera del proyecto no impidieron guardar fuentes y exportaciones.

Pendiente: colocar estos nuevos props en la escena jugable del Nivel 01. No se modificaron los cambios de gameplay existentes ni se hizo commit/push.
