# Rococó — sapo gigante con armadura alien, v01

Fecha: 2026-10-12. Rama de trabajo: `lote-11` (se conservó la rama real con los archivos de arte).

## Ficha del pedido

- Nombre: Rococó, sapo gigante; propuesta de primer jefe del Nivel 02, lago, por continuidad con la tanda anterior. No sustituye al sapo mini-jefe existente.
- Categoría: jefe / fauna controlada liberable.
- Función prevista: salto, plasma desde dos cañones y lengüetazo de largo alcance. Esta entrega incluye modelo y presentación de ataques; IA, HP, colisiones, selección de objetivo y daño quedan para una tarea de integración.
- Escala: Bee ≈ 1 unidad; controlado 3,953 × 2,910 × 3,800 m (X/Y/Z Godot), origen en el suelo, +Y arriba, frente -X. Se puede escalar el nodo completo al integrar.
- Lectura: cuerpo ancho, cuatro patas, muslos traseros fuertes, ojos elevados y dos bocas de cañón; piel natural conservada bajo piezas separadas.
- Paleta: oliva, ocre, vientre cálido, ojos ámbar y lengua coral. Grafito, cian y nodos violeta exclusivos de tecnología externa. Sin gore ni mutación.
- Presupuesto: ≤12.000 triángulos. Controlado **11.992**, cuatro materiales. Liberado **7.900**, un material. Paleta natural de 8×2 píxeles empacada en `.blend` y embebida en ambos GLB.
- Rig: pivotes rígidos editables en cuerpo, cabeza, mandíbula, garganta, cuatro extremidades, lengua y dos cañones. No usa esqueleto deformable/retargeting humano.
- Anclas: `GroundAnchor`, `BodyAnchor`, `ImplantAnchor`, `Muzzle_L`, `Muzzle_R`, `TongueAnchor`, `TongueTipAnchor`. Los muzzle están dentro del respectivo cañón y heredan su retroceso.
- Origen: diseño original construido en Blender, sin importaciones externas. Los modelos anteriores permanecen intactos.

## Animaciones reales exportadas

| Clip | Duración | Movimiento |
|---|---:|---|
| `idle` | 2,0 s | respiración, garganta y balanceo de cabeza |
| `hop` | 1,6 s | impulso de extremidades y elevación del cuerpo; sin desplazamiento horizontal |
| `plasma_fire` | 1,8 s | preparación de 0,6 s y dos pulsos de retroceso en ambos cañones |
| `tongue_attack` | 2,4 s | apertura de boca de 0,6 s, extensión de lengua de más de 6 m, sostén y retracción |

Reposo y salto se reproducen en loop; ataques una vez. El desplazamiento por el nivel, la dirección/objetivo de la lengua y la telemetría de combate corresponden al controlador futuro. El GLB liberado conserva los clips naturales; el clip de plasma solo conserva la reacción corporal, sin armas.

## Archivos y prueba visual

- Blender: `art_source/blender/levels/level_02_lake/bosses/lvl02_boss_rococo_toad_v01.blend`, cámara/luz de estudio y pistas NLA editables.
- Modelos: `assets/models/levels/level_02_lake/bosses/lvl02_boss_rococo_toad_v01.glb` y `lvl02_boss_rococo_toad_v01_liberado.glb`.
- Estadísticas: `lvl02_boss_rococo_toad_v01_manifest.json`, misma carpeta.
- Constructor reproducible: `tools/art/create_rococo_toad_boss_v01.py`.
- Escenas instanciables: `scenes/art_labs/rococo_toad_boss_v01/controlled.tscn` y `liberated.tscn`.
- Laboratorio: `scenes/art_labs/rococo_toad_boss_v01.tscn`, ejecutar **F6**. **1** respirar, **2** saltar, **3** doble plasma, **4** lengua, **L** retirar/colocar tecnología. El ejemplar del fondo muestra la variante liberada.
- Presentación: `scripts/art/rococo_toad_visual.gd` aplica cel shading y contorno del proyecto; PBR portable en Blender/GLB. `rococo_toad_lab.gd` muestra orbes cian efímeros, sin colisiones ni daño, con velocidad/vida/tiempos en constantes.
- Renders Godot Compatibility: `concept_art/levels/level_02/rococo_toad/hero.png`, `plasma_fire.png`, `tongue_attack.png` y hojas `lvl02_boss_rococo_toad_concept_v01{,_liberado}.png`. Cuatro vistas del mismo GLB sobre gris neutro, sin entorno, suelo, texto ni UI.

## Verificación

Blender comprobó geometría cerrada, ausencia de caras degeneradas, presupuesto y cuatro materiales como máximo. Prueba dirigida `tests/art/validate_rococo_toad_boss_v01.gd`: **PASS**, sin errores de script. Comprueba contorno/toon, emisión solo tecnológica, anclas, cuatro extremidades, salto, retroceso, extensión/retracción de lengua, liberación completa y dos plasmas de laboratorio con caducidad. Renders revisados.

Suite completa ejecutada **una sola vez: 87/87 PASS**, en 214,4 s, sin errores de script. Logs: `dev/rococo_full_suite_result.log` y `dev/rococo_full_suite.log`. Incluye la nueva validación del asset. Los fallos registrados en la tanda botánica anterior ya no aparecen en el estado actual del proyecto; no se editaron esos sistemas durante esta tarea.

Otros registros: `dev/rococo_build.log`, `dev/rococo_import.log`, `dev/rococo_capture.log`, `dev/rococo_validation.log`.

No se hizo commit/push ni se modificaron scripts de gameplay. Las fuentes PBR y los GLB requieren el wrapper del proyecto para el cel shading final.
