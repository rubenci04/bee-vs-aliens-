# Tanda H — música por escena

Rama `tanda-h-musica`, desde `tanda-g-mejoras-juego` (`cbb912e`). Las músicas anteriores se conservan en `audio/`.

| Pista nueva | Momento |
| --- | --- |
| `musica titulos.mp3` | Apertura y menú de título |
| `musica storyboard.mp3` | Las cinco ilustraciones de la introducción |
| `musica gameplay accion!.mp3` | Inicio y acción del nivel 1 |
| `entra minijefe.mp3` | Entrada y pelea con el robot; continúa hasta la tarántula |
| `entra jefe tarantula.mp3` | Entrada y pelea con la tarántula |
| `victoria! jefe vencido y nivel pasado.mp3` | Tarántula vencida y salida hacia resultados; una sola vez |

Los nombres permiten un mapeo directo, sin ambigüedad. Los cinco temas de escena tienen `loop=true` en sus `.import`; victoria tiene `loop=false`. `MusicManager` conserva los fades, la pausa y el volumen guardado. Las dos pistas de jefe se cruzan al empezar la pelea final; la victoria no se dispara al derrotar al robot.

Para probar: reimportar (`godot --headless --path . --import`) y correr `validate_bee_tanda_h_music_mapping.gd`, `validate_bee_lote14_music_v01.gd`, `validate_bee_audio_basic_v01.gd`, `validate_bee_audio_assets_v02.gd` y `validate_bee_polish_audio_v01.gd` con `--headless --path . --script res://tests/...`. Los cinco pasaron en Godot 4.7.2. Godot emitió avisos del entorno sobre `user://logs` y recursos al salir en algunos tests; no hubo `SCRIPT ERROR` en las corridas finales.

Los cambios de gameplay de Tanda G que ya estaban sin commit en el árbol de trabajo no forman parte del commit de esta tanda.
