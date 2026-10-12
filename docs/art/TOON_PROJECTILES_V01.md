# Bee Alien · Proyectiles e impactos toon

Set reutilizable de dos proyectiles, dos impactos pequeños y dos explosiones. Bee usa amarillo miel/crema; alien usa cian, carcasa grafito y violetas secundarios. Cel shading y contorno fino en los cuerpos y efectos sólidos, sin bloom necesario en Compatibility. Las partículas pequeñas de estela son planas, con desaparición suave.

## Escenas

| Archivo | Comportamiento |
| --- | --- |
| `scenes/projectiles/toon/bee_bolt.tscn` | Disparo miel, estela cálida, equipo Bee, daño/velocidad/duración heredados: 10 / 14 / 1,4 s |
| `scenes/projectiles/toon/alien_bolt.tscn` | Disparo cian, acentos violetas y estela cian, equipo alien: 8 / 6 / 2,5 s |
| `scenes/vfx/toon/bee_impact.tscn` | Impacto cálido pequeño, 0,24 s |
| `scenes/vfx/toon/alien_impact.tscn` | Impacto cian/violeta pequeño, 0,28 s |
| `scenes/vfx/toon/bee_explosion.tscn` | Explosión cálida, 0,65 s |
| `scenes/vfx/toon/alien_explosion.tscn` | Explosión cian/violeta, 0,65 s |

Los cuerpos reutilizan los modelos originales de **864 triángulos** cada uno: `assets/models/shared/projectiles/bee_bolt.glb` y `alien_bolt.glb`, con fuentes conservadas en `art_source/blender/projectiles_toon_v01/`. No se duplican ni reexportan. Las explosiones son geometría procedural nativa de Godot; su fuente editable sigue siendo `scripts/art/toon_burst_visual.gd`.

Se deriva de `BeeEnergyProjectile` y `AlienEnemyProjectile`, conservando el contrato `launch(direction, attacker)`, daño por `DamageHitbox3D`, equipos, duración y plano XY. El morro del GLB, originalmente hacia -X, gira para apuntar en la dirección de vuelo, incluido disparo oblicuo. Los impactos se disparan al confirmar daño; no son un sistema de colisión nuevo. El flash tiene un pequeño desplazamiento visual hacia la cámara para leerlo sobre el blanco; esto no desplaza el hitbox. La regla de cuerpo neutral sigue dependiendo del hurtbox existente; el feedback de ese caso permanece pequeño y sin sonido de impacto tecnológico.

La estela Bee no emite; la alien emite a 0,35. El material toon de energía/impactos se limita a 0,65, manteniendo el cian coloreado sin exigir bloom. Los efectos de explosión son visuales: no aplican daño de área. No cambian la paleta del entorno.

## Archivos de esta tarea

- Dos escenas de proyectil y cuatro escenas VFX descritas arriba.
- `scripts/vfx/toon_bee_projectile.gd`, `toon_alien_projectile.gd`: adaptadores de las clases existentes.
- `scripts/vfx/toon_shot_style.gd`: geometría compartida y paleta de estelas, creación de impactos.
- `scripts/art/projectile_combat_toon_lab.gd`, `scenes/art_labs/projectiles_game_toon_v01.tscn`: prueba aislada con blancos, daño real y comparación visual.
- `tests/bee_prototype/validate_toon_projectiles_v01.gd`: daño, filtrado, limpieza, orientación, paleta y geometría.
- `tools/art/capture_projectiles_game_toon.gd`, `docs/art/projectiles_game_toon_v01/`: capturas de comparación e impactos ampliados.
- Modificado `scripts/art/art_delivery_hub_v01.gd`: acceso a la prueba.

No se modifica el jugador, los enemigos activos, los scripts de proyectiles originales ni la escena del Nivel 01. Para integrar estos assets, asignar las escenas nuevas en las propiedades de proyectil de los actores correspondientes; `BeePlayer.projectile_scene` acepta el nuevo disparo derivado. Los controladores que precargan una ruta fija necesitarán una sustitución explícita en una tarea de integración.

## Cómo probar

Ejecutar `scenes/art_labs/projectiles_game_toon_v01.tscn` con **F6**, o seleccionar **Disparos toon · impacto real** en la colección de arte.

La primera fila muestra Bee disparando a un blanco alien; la segunda, alien hacia un blanco cálido; abajo se comparan las explosiones. La prueba usa velocidad 8 y duración 3 s sólo para ver los trayectos. El daño real se aplica a blancos con `HealthComponent` y hurtboxes normales.

**Espacio** repite, **P** pausa/reanuda, **H** oculta la interfaz y **Esc** vuelve al índice. Para ver los GLB grandes y sus vistas lateral/3/4, usar la galería existente `scenes/art_labs/projectiles_toon_v01.tscn`.

Las escenas de impacto/explosión se instancian bajo un `Node3D` y se colocan con `global_position`. `play()` reinicia; `seek(segundos)` sirve para inspección; `finished` avisa al terminar. Por defecto se eliminan automáticamente; `free_when_finished = false` sirve para previews reutilizables.

## Verificación y problemas

**0 fallos** en la prueba de ambos equipos: impactos físicos con daño correcto y una sola señal, aliados sin daño, expiración/limpieza del proyectil, plano XY, orientación del morro, recuentos GLB de 864, estelas según equipo y emisión/finalización de los cuatro VFX. Revisión de capturas reales en Godot 4.7.2 Compatibility.

Advertencia conocida de caché de shaders `user://` en esta sesión restringida; no impidió la prueba ni las capturas. Se conserva la detección de contacto existente mediante áreas, sin introducir una solución de barrido para velocidades muy altas. No se midió un benchmark de disparos masivos. Estos assets todavía no reemplazan los disparos del nivel jugable.
