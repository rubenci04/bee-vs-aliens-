# Bee Alien · Interceptor y bombardero alien

POC pequeño de dos naves originales, con siluetas diferenciadas de perfil y orientación inicial hacia **-X** en Godot. Carcasas grafito, lentes y motores cian, nodos secundarios violetas. Cel shading y contorno fino usando el estilo compartido del juego; emisión limitada a 0,65 para Compatibility.

| Nave | Triángulos | Diseño y referencias de integración |
| --- | ---: | --- |
| Interceptor aguja | 4.982 | Cuerpo alargado, aletas barridas, dos motores a distinta altura y cañón ventral. Marcadores `Muzzle`, `EngineLeft`, `EngineRight`, `CoreTarget`. |
| Bombardero acorazado | 4.974 | Casco ancho, blindaje lateral, motores dobles y dos cargas inferiores. Marcadores `BombDropLeft`, `BombDropRight`, `EngineLeft`, `EngineRight`, `CoreTarget`. |

Cada GLB tiene **una malla con cinco superficies de material**. Las piezas se agrupan para reducir objetos; los marcadores permanecen como nodos vacíos. Las mallas son cerradas, sin caras degeneradas, verificadas durante la generación. Son modelos estáticos sin rig ni clips de animación. No usan la liberación de animales: la tecnología constituye toda la nave.

## Archivos creados y modificados

- Fuentes: `art_source/blender/shared/alien_tech/alien_needle_interceptor.blend`, `alien_armoured_bomber.blend` y `.gdignore`.
- Exportaciones: `assets/models/shared/alien_tech/alien_needle_interceptor.glb`, `alien_armoured_bomber.glb` y `manifest.json`.
- Escenas reutilizables: `scenes/art_labs/alien_ships_v02/alien_needle_interceptor.tscn`, `alien_armoured_bomber.tscn`. Aplican `future_asset_visual.gd`, el shader y el contorno existentes.
- Galería: `scenes/art_labs/alien_ships_v02.tscn`, reutilizando el catálogo existente.
- Generación: `tools/art/create_alien_ships_v02.py`, usando helpers originales locales V09. No importa bibliotecas externas ni reexporta las naves anteriores.
- Validación: `tests/art/validate_alien_ships_v02.gd`.
- Capturas reales: `docs/art/alien_ships_v02/`, estudio conjunto y vistas lateral/3/4 de cada nave, con fondo neutro y sin UI en las fichas limpias.
- Modificado `scripts/art/art_delivery_hub_v01.gd`: acceso **Interceptor y bombardero alien**.

## Cómo probar y reutilizar

Abrir `scenes/art_labs/alien_ships_v02.tscn` y ejecutar **F6**, o elegir **Interceptor y bombardero alien** en la colección. **1/2** inspeccionan cada nave, **V** alterna lateral/3/4, **H** oculta la interfaz, **E** vuelve al estudio conjunto y **Esc** vuelve a la colección.

Instanciar la escena de la nave bajo el actor `Node3D` del juego. El plano del juego es XY, +Y arriba; `face_right(true)` invierte la dirección. Los marcadores sirven como puntos de referencia: para generar un proyectil o una bomba, usar su `global_position`. La escena no dispara ni suelta cargas por sí sola.

## Verificación y límites

Importación y revisión visual en Godot 4.7.2, renderer Compatibility. **0 fallos** en la prueba: presupuesto real importado, una malla por nave, estilo toon/contorno, dos superficies de energía, límite de emisión, marcadores, orientación y fichas limpias. También pasó la navegación de la colección. Resultados en `dev/alien_ships_v02_test.log`, `dev/alien_ships_v02_gl_test.log` y `dev/alien_ships_v02_hub.log`.

Assets visuales preparados para integración: todavía sin IA, colisiones, daño ni animación de motores. Las cargas del bombardero forman parte de la malla estática; un sistema de lanzamiento necesitará instanciar bombas independientes. No se modifican los enemigos ni la escena jugable actual y no se ha medido rendimiento con muchas naves.

La sesión restringida presenta avisos de guardado de ajustes/caché `user://` de Godot y de miniatura externa de Blender. Las fuentes y GLB del proyecto se guardan correctamente; esos avisos no impiden la captura.

La prueba headless registró dos avisos de material nulo del renderer dummy al cambiar de ficha. Se verificó el mismo test con OpenGL Compatibility: 0 fallos y sin esos avisos; las capturas también finalizaron correctamente.
