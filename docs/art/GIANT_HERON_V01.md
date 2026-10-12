# Garza gigante — enemigo secundario del lago, v01

Fecha: 2026-10-12. Rama conservada: `lote-11`.

## Ficha del asset

- Nivel/categoría: Nivel 02 lago, enemigo secundario grande; nuevo diseño original, sin sustituir aves existentes.
- Función prevista: amenaza por aletazos de viento y picotazos; movimientos y efectos demostrados en laboratorio. IA, HP, daño, hitboxes, trayectoria de viento y aparición en oleadas quedan pendientes de integración jugable.
- Silueta: garza reconocible, cuello articulado en S, pico largo, cejas inclinadas, ojos ámbar, patas altas, alas anchas y plumas oscuras. La actitud amenazante se comunica con postura y mirada, sin mutación ni gore.
- Escala: Bee ≈ 1 unidad. 4,437 × 4,855 × 5,352 m (X/Y/Z Godot) en pose neutral; origen sobre el suelo, +Y arriba, frente -X. El tamaño se puede ajustar desde el nodo raíz al integrar.
- Paleta: gris natural, crema cálido, patas/pico ocre y ojos ámbar. Implantes externos grafito con núcleo cian y dos nodos violeta. Las ráfagas de viento son crema claro no emisivo; no son plasma alien.
- Presupuesto: **5.964 triángulos / cuatro materiales** controlada; **5.212 / un material** liberada. Tope de esta variante grande: 6.000 triángulos. Paleta natural de 8×2 píxeles empacada en Blender y GLB; no texturas externas necesarias en el archivo exportado.
- Tecnología: placa dorsal, dos brazales de ala y collar externo del cuello. Todos separados y retirables, preservando el ave completa.
- Rig: **21 nodos rígidos articulados** editables: cuerpo, tres tramos de cuello, cabeza, mandíbula, cola; hombro/codo/muñeca en cada ala; cadera/rodilla/tobillo/dedos en cada pata. No es un rig de deformación con huesos; cada pieza sigue su articulación jerárquica, exportada como animación glTF.
- Anclas: `WindAnchor_L`, `WindAnchor_R` siguiendo muñecas; `BeakTipAnchor` siguiendo cabeza; `BodyAnchor`, `ImplantAnchor`, `GroundAnchor`.
- Origen/licencia: modelado procedural original del proyecto en Blender, sin assets externos.

## Clips exportados

| Clip | Duración | Movimiento |
|---|---:|---|
| `idle` | 2,0 s | respiración y ajustes sutiles de cuello, alas, patas y cola |
| `walk` | 1,6 s | articulación alternada de patas, dedos y balanceo corporal |
| `fly` | 1,2 s | aleteo por hombros, codos y muñecas, patas recogidas y cola |
| `wind_attack` | 2,0 s | preparación de 0,6 s y golpe amplio de alas; ráfagas visuales en laboratorio |
| `peck_attack` | 1,6 s | preparación, extensión de cuello, avance del cuerpo, apertura del pico y recuperación |

Reposo, caminar y vuelo se reproducen en loop; ataques una vez. La caminata y el vuelo animan las piezas sin desplazar al enemigo por el nivel: ese desplazamiento pertenece al futuro controlador. El laboratorio emite viento a los 0,75 s; velocidad, vida y momento de salida son constantes configurables, sin colisiones ni daño.

## Entrega y prueba

- Fuente editable: `art_source/blender/levels/level_02_lake/enemies/lvl02_enemy_giant_heron_v01.blend` (pistas NLA, cámara y luces de estudio).
- Exportados: `assets/models/levels/level_02_lake/enemies/lvl02_enemy_giant_heron_v01.glb` y `lvl02_enemy_giant_heron_v01_liberado.glb`; manifiesto JSON al lado.
- Constructor: `tools/art/create_giant_heron_v01.py`.
- Wrapper: `scripts/art/giant_heron_visual.gd`, cel shading/contorno del proyecto. Fuente/GLB con materiales PBR portables; el toon final corresponde al wrapper Godot.
- Laboratorio: abrir `scenes/art_labs/giant_heron_v01.tscn`, ejecutar **F6**. **1** reposo, **2** caminar, **3** vuelo, **4** aletazo de viento, **5** picotazo, **L** retirar/colocar implantes. El ave del fondo muestra la versión liberada.
- Subescenas instanciables: `scenes/art_labs/giant_heron_v01/controlled.tscn` y `liberated.tscn`.
- Capturas: `concept_art/levels/level_02/giant_heron/hero.png`, `wind_attack.png`, `peck_attack.png`, hojas `lvl02_enemy_giant_heron_concept_v01{,_liberado}.png` y `movement_preview.gif`.
- Hojas de cuatro vistas generadas del mismo GLB real, con gris neutro, sin UI, texto, entorno ni suelo. GIF renderizado de los clips reales del GLB, sin interpolación inventada.

## Verificación

Blender comprobó todas las mallas cerradas, sin caras degeneradas, presupuesto y materiales. Godot Compatibility renderizó el modelo y los ataques; se corrigió la orientación de normales del pico durante la revisión.

Prueba dirigida `tests/art/validate_giant_heron_v01.gd`: **PASS**, 21/21 articulaciones con movimiento comprobado entre los clips; cinco animaciones, alcance del picotazo, anclas, toon/contorno, emisión solo tecnológica, liberación completa, ausencia de colisiones y caducidad de ráfagas. Logs: `dev/heron_build.log`, `dev/heron_import.log`, `dev/heron_validation.log`, `dev/heron_capture.log`, `dev/heron_motion.log`.

Suite completa ejecutada una sola vez: **88/88 PASS**, 204,6 s, sin errores de script. Registros: `dev/heron_full_suite_result.log` y `dev/heron_full_suite.log`.

No se tocaron scripts de gameplay, modelos existentes, ramas ni historial Git. No se hizo commit/push.
