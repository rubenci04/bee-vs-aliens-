# Bee Audio Asset Integration V02

V01 se cerró primero: 20/20, audio headless/render y cargas directas headless/OpenGL código 0. No se rehizo el sistema ni se borraron sus sonidos.

## Biblioteca y selección

Ruta descubierta: `D:\proyectos\V_Asset_Library\01_Extracted\audio`. Seis packs, 676 audios: 373 WAV y 303 OGG. Revisados 36 candidatos (1–4 por cue) por decodificación, duración, onset/tail, peak y RMS. No hubo escucha subjetiva fiable ni descarga. Ver `AUDIO_ASSET_INVENTORY.md` para packs, evidencia y descartes.

Kenney Impact/Interface/Sci-Fi y Lentikula: CC0. FX Laser: licencia propia comercial/modificación, sin redistribuir originales. Sonniss: royalty-free comercial/modificación, sin atribución, con restricciones de redistribución/autoría y entrenamiento de IA. Los seis están aprobados para uso en juego; ninguno requiere atribución obligatoria. Sólo se usaron los tres packs Kenney; las licencias locales quedan copiadas en `audio/sfx/licenses` y hay crédito de cortesía.

Se incorporaron **14 WAV derivados de 15 OGG CC0**, no packs completos. Mono PCM16 a 44100 Hz, peak máximo 0.40, colas acortadas y fades 2/35 ms; Godot usa su compresión QOA normal al importar. Bomb une únicamente dos capas en un WAV. Los originales de la biblioteca permanecen intactos. Script reproducible: `tools/integrate_audio_v02.gd -- weapons|state|world`; cada grupo se importó y validó por separado.

| Cue | Selección principal | Duración V02 | dB relativos a SFX |
|---|---|---:|---:|
| Base | Sci-Fi / laserSmall_000 | 0.20 s | -20 |
| Spread | Sci-Fi / laserLarge_000 | 0.34 s | -18 |
| Tech impact | Sci-Fi / impactMetal_000 | 0.28 s | -20 |
| Organic impact | Impact / impactSoft_medium_000 | 0.118 s | -21 |
| Melee | Impact / impactPunch_medium_000 | 0.30 s | -16 |
| Bomb | Sci-Fi / forceField_000 + lowFrequency_explosion_000 | 0.70 s | -8 |
| Bee damage | Impact / impactPunch_medium_001 | 0.29 s | -11 |
| Bee defeat | Interface / minimize_001 | 0.258 s | -9 |
| Tech death | Sci-Fi / explosionCrunch_000 | 0.55 s | -15 |
| Organic death | Placeholder V01 conservado | 0.21 s | -16 |
| Crate | Impact / impactPlank_medium_000 | 0.30 s | -16 |
| Spread pickup | Interface / confirmation_001 | 0.290 s | -24 |
| Bomb pickup | Interface / maximize_001 | 0.258 s | -22 |
| Pollen | Interface / pluck_002 | 0.13 s | -29 |
| Human warning | Placeholder V01 conservado | 0.48 s | -14 |
| Human crossing | Impact / footstep_grass_000, pitch baked 0.70 | 0.30 s | -16 |

Base/Spread comparten familia tecnológica y varían pitch ±2.5%. Spread sigue siendo una voz por ráfaga. Bomb tiene activación/expansión en un único cue; no crea un sistema de layering. Walker conserva la misma muerte tecnológica con pitch 0.82 y +2 dB. HitFlash no añade sonido. Los pickups reales bajaron 3 dB para mantenerlos por debajo de ataques/daño. Estos niveles son iniciales, no una mezcla final.

## Arquitectura y fallback

Se conserva BeeAudio, Master/SFX/Music, la protección de clipping y el límite de 16 voces con prioridad. Music sigue vacío. Armas/estado de Bee no espaciales; impactos/melee/enemigos/cajas/pickups/humano espaciales, alcance 26 m (humano 32 m), unit_size 12 m, paneo 0.35. Sin cambios de gameplay, balance, cadencia, HP, encuentros, VFX, humano o flora.

Los **16 WAV procedurales permanecen disponibles**. `BeeAudio.use_real_assets = false` vuelve al baseline; `true` selecciona los 14 replacements. Si falta un replacement, se usa su placeholder. Organic death y Human warning mantienen V01: los candidatos no justificaron reemplazarlos sin escucha humana. Provenance por cue, fuentes originales, modificaciones y SHA256: `audio/sfx/PROVENANCE.md`.

Voces ligadas a la escena; clips finitos sin loops, stop al salir, cleanup por finished/timer. R recarga y elimina audio anterior. Headless verifica los recursos/eventos sin mixer Dummy; render comprueba reproducción.

## Revisión manual A/B

Abrir `dev/audio_review/audio_review.tscn` y F6. Flechas o botones cambian cue. A reproduce procedural; B/Space reproduce seleccionado. Los botones muestran cue y referencia; Base ×10 permite revisar repetición. Una escucha A/B corta es necesaria para decidir comodidad, fuerza de Bomb, timbre de criatura, ruptura de caja y peso de pasos. Es DEV, sin menú ni cambios a gameplay.

Level 01: abrir `scenes/levels/bee_level_01_vertical_slice.tscn` y F6; WASD/flechas vuelo, X Base/Spread, Z melee, C Bomb, R tras derrota. Comparar el resultado en acción antes de declarar audio artístico final.

## Validación y límites

Test de integración V02: `tests/bee_prototype/validate_bee_audio_assets_v02.gd`, mappings reales/placeholder, licencias conservadas, límites/loops/formato fuente, review A/B, Base repetido y cleanup. El test Audio Basic valida los triggers reales en Level 01 y R. Weapons, Combat VFX y Level 01 conservan sus validaciones anteriores. Logs finales en `dev/audio_asset_review`.

Tests específicos headless/render aprobados. El test con render en Level 01 confirmó todos los eventos, R y cleanup: código 0. Cargas jugables directas headless y OpenGL: código 0, sin SCRIPT ERROR, missing streams ni warnings. Muestra comparable de 240 frames: **98.86 FPS**, peor frame **36.103 ms**, un frame >33.3 ms, pico 1275 nodos. Baseline V01 final: 98.78 FPS / 36.341 ms / 1274 nodos. No se observa caída sostenida significativa; persiste un pico aislado. No es benchmark exhaustivo ni escucha humana.

Cierre final: **21/21** regresiones aprobadas (baseline V01 20/20 + test de assets V02), incluyendo Weapons, Combat VFX, humano y Level 01 integrado. Código 0 en todos los tests, sin errores ni warnings en logs finales. Originales de los 15 sources verificados por SHA256 después de la integración. **BEE AUDIO ASSET INTEGRATION V02 APTO** como integración funcional; calidad subjetiva/mezcla final pendientes de escucha humana.

El resultado funcional no certifica que todos los reemplazos gusten más al oído: la selección se basó en metadata y waveform, con timbres/familias elegidos para gameplay. Sin música, ambiente, master final, occlusion ni sincronía exacta de pasos. Pendiente: playtest humano de la review A/B y del nivel; especialmente cajas, Organic death y Human warning.

## Git: alcance de esta continuación

- **Audio V01 closure:** `audio/sfx` procedural, `default_bus_layout.tres`, `scripts/audio`, generador V01, test Audio Basic, documentación V01 y logs de baseline. Hooks de audio en BeePlayer, BeeEnergyProjectile, BeeAlienBomb, BeePowerupPickup, pollen, EnemyFeedback y DestructibleObstacle; HumanAudio en la escena local del humano y variante heavy en Walker. Correcciones de montaje bajo Window y cierre headless, sin cambios de mecánicas.
- **Real Audio Asset Integration V02:** 14 WAV en `audio/sfx/real`, tres licencias, mapping/fallback y ajuste de pickups en BeeAudio; inspect/integrate/document tools; review A/B; test assets V02; inventory, provenance, créditos y este documento; logs V02. BeeAudio es un archivo compartido entre ambos alcances.
- **Previous Changes:** cambios previos de Weapons/VFX/Level/escenas/arte/imports/documentación conservados. El status Git global ya incluía archivos modificados y numerosos untracked; no se atribuye todo ese diff a audio. Status completo: `dev/audio_asset_review/git_status_final.txt`. Sin commit, push, reset, clean ni stash.
