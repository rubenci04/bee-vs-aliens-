# Bee Alien · Águila para el nivel del cielo

Variante del águila V11, con cuerpo natural marrón/ocre, cabeza crema, pico ganchudo, garras y plumas de vuelo reconocibles. Dispositivo externo grafito con lentes cian y nodos violetas; retirarlo conserva toda la anatomía. Cel shading de bandas, contorno fino y emisión limitada a 0,65 para Compatibility.

**6.914 triángulos, cuatro objetos de malla:** cuerpo, ala cercana, ala lejana y controlador. Cada ala tiene un pivote independiente. Animación por objetos, sin esqueleto ni clips horneados en el GLB. Las cuatro mallas son cerradas y se verifican al exportar. El águila original V11 se conserva.

## Archivos de esta tarea

- `art_source/blender/levels/level_04_sky/enemies/controlled_eagle_flight.blend`: fuente editable y pivotes de alas.
- `assets/models/levels/level_04_sky/enemies/controlled_eagle_flight.glb` y `manifest.json`: modelo exportado y presupuesto.
- `scenes/art_labs/assets_eagle_sky_v01/controlled_eagle_flight.tscn`: visual reutilizable con estilo toon, aleteo, planeo y pose de picado.
- `scripts/art/eagle_sky_visual.gd`: animación de alas y control removible heredado.
- `scenes/art_labs/eagle_sky_v01.tscn`, `scripts/art/eagle_sky_lab.gd`: galería y composición de cielo con Bee pequeña, nubes existentes y capas de paisaje mates.
- `tools/art/create_eagle_sky_v01.py`: reconstruye solamente el águila, usando el bloque original de construcción de `create_future_biomes_v11.py` y los helpers V09. No ejecuta ni reexporta ese lote.
- `tests/art/validate_eagle_sky_v01.gd`, `tools/art/capture_eagle_sky_v01.gd`: validación y capturas.
- `docs/art/eagle_sky_v01/`: vistas lateral, 3/4, liberada, estudio, cielo y picado.
- Modificado `scripts/art/art_delivery_hub_v01.gd`: acceso al águila y botones de 76 px para acomodar la fila adicional.

## Cómo probar

Abrir `scenes/art_labs/eagle_sky_v01.tscn` en Godot y ejecutar **F6**. También está en la colección: **Águila · vuelo y picado**.

**G** muestra el cielo y reinicia el vuelo, alternando aleteo y planeo. **D** inicia un ciclo visual de aviso de 0,65 s, picado de 1 s y recuperación de 1,35 s. **P** pausa/reanuda, **L** pone/quita el implante, **E** vuelve al estudio, **1** inspecciona el águila, **V** cambia lateral/3/4, **H** oculta interfaz y **Esc** vuelve a la colección. Las fichas individuales tienen fondo neutro, pose congelada y ninguna escenografía.

Para reutilizar el visual, instanciar su escena bajo un `Node3D`. `set_flight_pose(0/1/2)` selecciona aleteo/planeo/picado; `animate_wings` habilita animación automática, `seek(segundos)` permite sincronizarla o inspeccionar un momento. `release_control()` oculta el dispositivo, `controlled = true` lo restaura y `face_right(bool)` invierte el sentido horizontal. El movimiento del actor debe controlarlo el juego; la trayectoria de esta galería es solamente una demostración.

## Verificación y límites

**0 fallos**: importación, 6.914 triángulos y cuatro mallas, alas con geometría móvil independiente, aleteo opuesto, planeo, pose de picado, cambio de dirección, toon/contorno, emisión exclusiva del controlador, liberación/restauración, trayectoria XY y vistas limpias. Capturas reales revisadas en Godot 4.7.2 Compatibility.

POC visual listo para integrar: todavía sin IA, daño, hitboxes ni comportamiento de mini-jefe. No sustituye enemigos del nivel actual. Las alas son piezas rígidas articuladas; un futuro rig puede añadir plegado fino de plumas y patas. No hay benchmark de muchas águilas simultáneas.

Esta sesión restringida avisa que no puede guardar ajustes del editor ni crear caché de shaders `user://`; la importación, las pruebas y las capturas finalizaron correctamente.
