# T2 — Menú, transiciones y resultados

Rama `lote-16-titulo-intro`. Fecha: 15/10/2026. Cambios de presentación y navegación; sin modificar combate, vidas, daños, drops ni puntuación calculada.

## Menú y desarrollo

- `bee_title_screen.gd::debug_menu_enabled()` usa la misma comprobación que los comparadores: editor/debug de desarrollo, excluyendo standalone exportado. Ya no puede aparecer Laguna en una exportación mediante `--debug-art`. No se borró la escena del prototipo.
- La búsqueda en scripts y escenas no encontró un contador FPS propio de gameplay. Se agregó al final de la línea **DEV** existente, con actualización real por frame; esa línea solo se construye en desarrollo. No hay contador ni botón Laguna en builds exportadas, incluidas exportaciones debug. Un contador superpuesto por el propio editor o un driver externo queda fuera del contenido del proyecto.
- Logo con alto de 180 px; subtítulo en 30 % de altura, con ajuste de línea; panel del menú desde 40 %. A 1154×648 hay espacio entre logo, subtítulo y botones. Se conservan proporción del arte, música, foco, controles y el scroll de Opciones: las opciones que no entran se alcanzan con rueda/foco del mando.

## Transiciones e intro

`project.godot` fija `rendering/environment/defaults/default_clear_color` en **negro**. `bee_scene_fade.gd` coloca una capa negra en la raíz, independiente de la escena que se está descargando: **0,22 s de salida**, cambio de escena bajo negro y **0,22 s de entrada**. Se usa entre título, intro, nivel y navegación desde resultados; también al abrir directamente título/intro/nivel. El negro permanece durante la carga síncrona, en vez de mostrar un cuadro gris. No es un cargador asíncrono ni se promete eliminar todo tiempo de carga.

La intro conserva las cinco imágenes y los textos de `assets/ui/intro/intro_texts.json`, así como el salto intencional después de 0,6 s. Cada imagen ahora dura:

`max(duration_seconds del JSON, demora de tipeo + caracteres / 38 + 2,0 s de lectura completa)`.

El zoom usa esa duración efectiva. El reloj del texto queda detenido durante el fundido entre imágenes y se reinicia con la imagen nueva. Así las frases largas no se cortan automáticamente antes de terminar; el jugador todavía puede saltarlas. No se cambió el JSON ni el sonido/música de la intro. La salida al nivel queda protegida frente a llamadas repetidas del final de intro.

## Resultados independientes

Nueva escena `scenes/game/bee_results_screen.tscn`, script `scripts/game/bee_results_screen.gd`. Sustituye los dos carteles superpuestos y elimina el retorno automático al título. La escena muestra:

- **NIVEL 1 COMPLETADO**;
- rango S/A/B/C;
- liberados / total;
- puntaje final y mejor combo;
- botones para repetir o volver al menú.

El fondo es la ilustración del título atenuada, sobre una base opaca; la acción no se ve detrás del texto. Se ocultan Bee de gameplay y sus capas de HUD, incluidas las etiquetas viejas. El nivel conserva la protección terminal de Bee y sigue retirando proyectiles enemigos tardíos. La pantalla recibe una copia de las estadísticas reales al terminar; no cambia su cálculo.

**R y Enter** repiten el nivel directamente, sin reproducir otra vez la intro. **Esc / B** vuelve al menú sin abrir la pausa. Se puede usar mouse o foco de botones; A acepta el botón elegido. Desde el menú, Jugar vuelve a mostrar la intro como antes. Se evita que CheckpointQoL intercepte la navegación como pausa después de ganar.

Todos los rangos están en **`scripts/game/bee_flow_settings.gd::RANKS`**, en orden de mayor a menor. Se exigen **ambas condiciones**, con umbrales inclusivos:

| Rango | Porcentaje mínimo liberado | Puntaje mínimo |
|---|---:|---:|
| S | 85 % | 100.000 |
| A | 65 % | 60.000 |
| B | 40 % | 25.000 |
| C | Resto | 0 |

Si el total de animales es cero, se evita división por cero y no se concede porcentaje alto. El ejemplo del pedido, **326/454, 135.040 puntos, combo ×185**, resulta en **A**. El mismo archivo centraliza tiempos de fundido/lectura y posiciones nuevas del título; son ajustes de presentación fáciles de cambiar.

## Verificación

Capturas reales de Godot Compatibility en **`docs/menu_y_resultados.png`** (2308×1296): menú sin control de Laguna, Opciones abierto, segunda imagen de intro con texto completo y resultados con el ejemplo solicitado. Herramienta reproducible: `tools/menu_y_resultados.gd`, ejecutar Godot con `--path . --script res://tools/menu_y_resultados.gd`. En esta herramienta, ejecutada con el binario de editor, se oculta únicamente el botón de desarrollo para mostrar la composición que verá una exportación; las pruebas verifican por separado su condición de visibilidad. Capturas revisadas; sin errores de script/render en el registro final.

Siete pruebas dirigidas aprobadas, sin suite completa: `validate_bee_t2_flow`, `validate_bee_lote16_title_intro_v01`, `validate_bee_lote14_screen_v01`, `validate_bee_lote17_checkpoint_v01`, `validate_bee_live_readability`, `validate_bee_lote17_terminal_ui_v01`, `validate_bee_terminal_states_v01`.

La nueva cubre separación geométrica de subtítulo/logo/panel, limpieza negra, tiempo de lectura de las cinco frases, estadísticas reales/rangos y bordes, HUD/Bee ocultos, Enter/A hacia nivel sin intro, Esc/B hacia menú y gate de desarrollo/exportación. La prueba terminal histórica sigue comprobando invulnerabilidad, limpieza de balas tardías, ausencia de nuevos enemigos, R como reinicio completo y polen que no revive a Bee.

Se actualizaron solo expectativas afectadas de pruebas anteriores: esperar el fundido antes de comprobar destino; resultados independientes en lugar de dos carteles; y guardar explícitamente la escena en vez de suponer que el último hijo raíz es el nivel, porque la transición ahora vive al lado de él. Se repitieron las pruebas afectadas. Los tests headless conservan algunos avisos conocidos de recursos al cerrar; no hubo errores de script en las ejecuciones finales.

## Qué probar

Abrir el título a la resolución habitual; revisar que el subtítulo no toque logo/botones, entrar a Opciones y navegar hasta Ver introducción con teclado/mando. Probar Jugar, cambios entre las cinco imágenes, salto y entrada al nivel: debe haber negro/fundido, sin gris. Ganar el nivel y revisar datos/rango; R y Enter deben repetir, Esc/B debe volver al menú y A debe aceptar el botón enfocado. Confirmar en una exportación que no aparezcan Laguna, comparadores ni FPS. Pendiente: validación humana de ritmo de lectura, mando real y resoluciones/aspectos distintos al banco.
