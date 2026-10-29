# Tanda L — música sin huecos

Los MP3 traen silencio grabado. Se midió cada archivo decodificado por Godot 4.7.2 con umbral de −45 dBFS (`AudioStreamPlayback.mix_audio`); `ffmpeg` no estaba instalado. Los valores están en `MusicManager.SILENCE_TRIMS` y no se modificó ningún MP3.

| Archivo (`audio/`) | Inicio (s) | Final (s) |
| --- | ---: | ---: |
| `Introducción al Jefe Final 1era opcion.mp3` | 0,063 | 2,537 |
| `Jefe Derrotado y Pantalla de Victoria.mp3` | 0,077 | 2,276 |
| `Menú Principal y Pantalla de Títulos.mp3` | 0,138 | 2,512 |
| `Nivel 1 El Jardín Acción Fuerte 1era opcion.mp3` | 0,780 | 2,640 |
| `entra jefe tarantula.mp3` | 0,082 | 2,748 |
| `entra minijefe.mp3` | 0,075 | 2,590 |
| `musica gameplay accion!.mp3` | 0,086 | 2,731 |
| `musica storyboard.mp3` | 0,041 | 1,853 |
| `musica titulos.mp3` | 0,041 | 2,610 |
| `victoria! jefe vencido y nivel pasado.mp3` | 0,133 | 2,216 |

Cada pista que repite inicia la vuelta siguiente 1,5 s antes del final audible, en el segundo reproductor y desde su `start_trim`. La mezcla es de potencia constante. El nivel deja un corte intencional de ~1,5 s al entrar el robot y la tarántula. La pausa detiene ambos reproductores y sus transiciones; el volumen guardado y los fades de muerte/victoria se mantienen. Victoria se reproduce una sola vez.

**Constantes:** `SILENCE_TRIMS`, `LOOP_CROSSFADE_SECONDS` y `BeeMusic.BOSS_BREAK_SECONDS`.

**Cómo probar:** ejecutar `tests/levels/validate_bee_tanda_l_music_gap.gd` con Godot 4.7.2; adelanta la pista hasta el final audible, mide el hueco (<0,3 s), pausa en medio del cruce y verifica que victoria no repita. También pasaron `validate_bee_lote14_music_v01.gd`, `validate_bee_tanda_h_music_mapping.gd`, `validate_bee_audio_basic_v01.gd`, `validate_bee_audio_assets_v02.gd` y `validate_bee_polish_audio_v01.gd` en modo headless. La medición lógica del test dio 0,00 s de hueco; conviene escucharlo en el juego para confirmar el resultado perceptivo del dispositivo de audio.
