# Bee Audio Basic V01

Feedback sonoro funcional para el gameplay existente. Sin música, mezcla final ni cambios de balance.

## Fuentes y procedencia

La búsqueda previa en el proyecto y `D:\proyectos\V_Asset_Library` no encontró WAV/OGG/MP3/FLAC; tampoco dentro de los 26 ZIP revisados. No se descargó ni importó audio externo.

Los 16 WAV son placeholders originales sintetizados mediante `tools/generate_bee_sfx_v01.gd`: mono PCM16, 22050 Hz, tonos/noise con envolventes cortas y semilla reproducible. No contienen muestras de terceros. No se les asignó una licencia externa ni una declaración CC0. Ver `audio/sfx/PROVENANCE.md`.

## Buses y reproducción

`default_bus_layout.tres`: Master 0 dB, SFX -3 dB, Music -8 dB (vacío). Master incluye HardLimiter con techo -1 dB para proteger las superposiciones. Esto no reemplaza una escucha/mezcla final.

`BeeAudio` crea voces bajo un contenedor de la escena, sin singleton persistente. Máximo 16 voces; una entrada de prioridad mayor reemplaza una voz menor. Armas, daño y derrota del Player son no espaciales. Impactos, melee, enemigos, cajas, pickups y humano usan AudioStreamPlayer3D: unit_size 12 m, max_distance 26 m (humano 32 m), panning_strength 0.35. Sonidos lejanos no cubren todo el nivel.

| Cue / evento | Duración | dB relativos a SFX | Espacial |
|---|---:|---:|---|
| Base: energía corta | 0.085 s | -20 | No |
| Spread: una voz por ráfaga, más grave/ancha | 0.105 s | -18 | No |
| TECH HIT: chispa aguda | 0.12 s | -20 | Sí |
| ORGANIC HIT: impacto seco | 0.11 s | -21 | Sí |
| Melee: sólo cuando conecta | 0.14 s | -16 | Sí |
| Bomb: activación aguda + expansión grave, un cue compuesto | 0.58 s | -8 | No |
| Bee damage / defeat | 0.19 / 0.42 s | -11 / -9 | No |
| Tech / organic death | 0.28 / 0.21 s | -15 / -16 | Sí |
| Crate break | 0.25 s | -16 | Sí |
| Pickup Spread / Bomb | 0.19 / 0.26 s | -21 / -19 | Sí |
| Pollen | 0.10 s | -26 | Sí |
| Human warning / step | 0.48 / 0.26 s | -14 / -16 | Sí |

Base/Spread varían pitch ±2.5%. Walker reutiliza tech death a pitch 0.82 y +2 dB. Bomb y daño/derrota tienen prioridad sobre disparos y pickups. Los valores son iniciales; la percepción depende también del espectro y la atenuación.

## Integración y limpieza

- Eventos aceptados existentes, sin lógica nueva de armas ni cambios de cadencia, HP, daño, colisiones, VFX o encuentros.
- Impacto del proyectil es la capa principal de enemy hit; HitFlash no duplica audio. Melee fallido permanece silencioso. Derrota sustituye el cue de daño en el golpe letal.
- Muertes y recogidas respetan sus guardas existentes. Caja sólo suena al romperse. Pickups rechazados no suenan.
- HumanAudio observa TELEGRAPH y CROSSING: warning al comenzar, thump al entrar y otro 3 segundos después si continúa cruzando. No pretende sincronizar cada paso de la animación.
- Todos los clips son finitos, sin loops. `finished` libera la voz y un timer real respalda el cleanup. Al salir del árbol se detiene y libera el stream. R elimina el contenedor completo junto con la escena. Las conexiones a nodos liberados no mantienen sonidos ni pasos pendientes. Headless crea/verifica voces y su lifetime sin iniciar el mixer Dummy; render Windows valida reproducción real. Esto evita playbacks pendientes en cierres inmediatos de tests headless.

## Pruebas

Test específico: `res://tests/bee_prototype/validate_bee_audio_basic_v01.gd`, headless y render. Comprueba streams/buses, triggers, impactos y daño, melee acertado/fallido, muertes sin duplicado, Walker más grave, pickups/polen, warning/dos thumps, límite/prioridad de voces y R real. No evalúa estética.

Regresiones: Weapons, VFX, Level 01 y suite Bee completa. El test de Level 01 conserva su alcance anterior. Logs en `dev/audio_basic_review/`; el test con render registra una muestra de 240 frames con Spread, enemigos y Bomb.

Test específico headless/render y cargas jugables directas headless/OpenGL: código 0, sin recursos faltantes ni errores. Última muestra render local: 98.78 FPS, peor frame 36.341 ms, un frame >33.3 ms, pico 1274 nodos (primera muestra: 98.77 FPS / 42.586 ms). La muestra VFX anterior registró 99.11 FPS / 37.845 ms; no se observa una caída sostenida, pero existe un pico aislado. No es una comparación controlada ni un benchmark exhaustivo.

Cierre del baseline procedural: **20/20** regresiones aprobadas, incluido Weapons, Combat VFX y Level 01 integrado. Sin SCRIPT ERROR, missing streams ni recursos pendientes en la suite final. **BEE AUDIO BASIC V01 APTO**. Los WAV procedurales quedan conservados para comparación/fallback en V02.

Ejecución manual: abrir `scenes/levels/bee_level_01_vertical_slice.tscn` con Godot 4.7.2 y F6. WASD/flechas vuelo, X disparo, Z melee, C Bomb, R tras derrota. Escuchar Base/Spread, impactos, cajas, pickups y humano; verificar que R corte los sonidos anteriores.

## Límites V01

Todos los sonidos son temporales sintetizados, no foley ni assets finales. Music está vacío; sin ambiente, voces, occlusion o reverb. La validación automatizada demuestra reproducción/eventos/cleanup, no preferencia auditiva ni escucha humana. Falta una sesión breve de escucha con auriculares/parlantes para ajustar comodidad del fuego repetido y balance subjetivo.
