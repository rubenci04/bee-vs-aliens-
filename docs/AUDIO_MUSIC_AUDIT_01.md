# AUDIO MUSIC AUDIT 01

Auditoría de solo lectura de `D:\proyectos\V_Asset_Library\01_Extracted\audio`. No se copió ni importó nada al juego. Duraciones medidas leyendo las cabeceras de los archivos (WAV) o decodificando (OGG). Estado de licencias según `docs/ASSET_LIBRARY_AUDIT_01.md`.

## Resumen
- 6 packs, 676 archivos: Kenney Sci-Fi / Impact / Interface (CC0), Lentikula Sci-Fi Weapon (CC0), FX Laser (comercial, no redistribuir los originales) y Sonniss GDC 2026 Part 9 (royalty-free, sin atribución; no revender los sonidos tal cual, **prohibido entrenar IA con ellos**).
- **No hay música utilizable** (ninguna pista con melodía, ritmo o estructura). Lo más cercano son tres *loops ambientales sintéticos* de Epic Stock Media (≈60 s) y un drone de tensión de Alexander Kopeikin (64 s), que sirven como cama sonora, no como tema. Las cajas de música de Sonic Bat son notas sueltas de 2–3 s. Si se quiere música real hay que conseguirla fuera de esta biblioteca.
- Sonniss es una **muestra** (3 archivos por pack de media): hay buenos candidatos para ambiente, pero casi todos son WAV 96 kHz/24 bit de 50–200 s, así que habría que recortar/convertir (OGG) antes de integrarlos para no inflar el proyecto.
- La mejor ambientación de jardín existente es una sola pista de Sonniss (prados, insectos, viento), que habría que recortar y loopear.

## Candidatos por uso
Duración en segundos. Paths relativos a `...\01_Extracted\audio\`. Pack "Sonniss" = `Sonniss.com-GDC2026-GameAudioBundle\`.

### 1. Ambiente de jardín en loop (viento, insectos, pájaros lejanos)
| Archivo | Pack | Licencia | Uso sugerido | Dur. |
|---|---|---|---|---|
| `Just Sound Effects - Highlands of Norway\AMBSwmp_Meadow Pipits calling many Insects humming Wind blowing through Grass_JSE_HoN_Stereo.wav` | Sonniss | Royalty-free (restricciones Sonniss) | **Primera opción**: pajaritos lejanos + muchos insectos + viento en pasto. Recortar un tramo estable y loopear | 86.5 |
| `344 Audio - East Coast America Vol. 1\AMBSubn_Ambience, Forest Crickets, Birds, Connecticut 02_...wav` | Sonniss | idem | Grillos y pájaros; tono más de bosque/atardecer. Ideal para el tramo de atardecer (x 250–360) | 52.3 |
| `Epic Stock Media - Synthesized Nature Loops and Sounds\WINDInt_Loop Weather Wind Whipping Constricted Flow Turbulent 01_ESM_SNLS.wav` | Sonniss | idem | Capa de viento ya preparada como loop (suave bajo la ambiente) | 7.5 |
| `Epic Stock Media - Synthesized Nature Loops and Sounds\AMBTrop_Loop Ambience Jungle Night Humid Birds Bug Chirps 01_ESM_SNLS.wav` | Sonniss | idem | Loop de insectos/pájaros listo, pero es selva nocturna: solo para atardecer/final | 41.6 |
| `Epic Stock Media - Public Spaces - Storms Lakes Parks and Rural Nature Exteriors\AMBPark_...Strong Wind On Trees Foliage Traffic Wash 03_ESM_CPS.wav` | Sonniss | idem | Descartado para jardín: lleva tráfico de fondo | — |

### 2. Música (si hay)
**No hay música.** Cama sonora opcional (no son temas):
| Archivo | Pack | Licencia | Uso sugerido | Dur. |
|---|---|---|---|---|
| `Epic Stock Media - Strange Game Ambient Loops 3\DSGNSynth_Dark Loop Mystic Forest Tonal Steady Synth_ESM_SGA3.wav` | Sonniss | Royalty-free | Pad tonal estable para tensión suave en el jardín | 59.7 |
| `Epic Stock Media - Strange Game Ambient Loops 3\DSGNSynth_Scifi Loop Ship Reactor Synth Layer Layered Saw Buzz_ESM_SGA3.wav` | Sonniss | idem | Bajo continuo sci-fi para zonas de invasión/defensas alien | 60.0 |
| `Epic Stock Media - Strange Game Ambient Loops 3\MAGShim_Shimmer Loop Small Bell Metal Taps_ESM_SGA3.wav` | Sonniss | idem | Capa de campanitas, solo adorno | 44.5 |
| `Alexander Kopeikin - Emotion and Magic\magic, drone, tension, spellbound, evanescence-002.wav` | Sonniss | idem | Drone de tensión para el aviso del humano gigante / jefe | 64.0 |

### 3. Aleteo de abeja
No hay un zumbido de abeja ni de insecto volando limpio. Opciones (todas requieren pitch/filtrado y probar):
| Archivo | Pack | Licencia | Uso sugerido | Dur. |
|---|---|---|---|---|
| `Sonik Sound Library - Toy Quadcopter\AERORadio_Quadcopter, Toy, Flying Sustained Close to Mic_KSL_KS013.wav` | Sonniss | Royalty-free | **Mejor opción**: zumbido sostenido de hélices pequeñas; loop de aleteo/vuelo con volumen según velocidad | 22.3 |
| `SoundBits - Vox Bestiae - Source Elements\CREAInsc_Insectoid Creature Tremble Attack Long 1_SNDBTS_VB-SE.wav` | Sonniss | idem | Vibración insectoide para avispa (ataque/telegraph) | 2.5 |
| `kenney_sci-fi-sounds\Audio\computerNoise_000..003.ogg` | Kenney Sci-Fi | CC0 | Zumbido eléctrico filtrado como capa mecánica del implante | 5.0 |
| `kenney_sci-fi-sounds\Audio\engineCircular_000..004.ogg` | Kenney Sci-Fi | CC0 | Alternativa CC0 de zumbido continuo (pitch alto) | 5.0 |

### 4. Pasos del humano gigante
Ya existe `human_step` en el juego: `footstep_grass_000` de Kenney, recortado y con el pitch bajado a 0.7 (ver `audio/sfx/PROVENANCE.md`). Las opciones siguientes sirven para mejorarlo (variaciones, más peso).

| Archivo | Pack | Licencia | Uso sugerido | Dur. |
|---|---|---|---|---|
| `kenney_impact-sounds\Audio\footstep_grass_000..004.ogg` | Kenney Impact | CC0 | **Base recomendada**: 5 variaciones; bajar pitch 3–4 octavas y reforzar graves (suena a paso enorme sobre pasto) | 0.59–0.78 |
| `kenney_impact-sounds\Audio\impactSoft_heavy_000..004.ogg` | Kenney Impact | CC0 | Capa de peso (golpe sordo) sincronizada con cada pisada | 0.50 |
| `kenney_impact-sounds\Audio\impactPlate_heavy_000..004.ogg` | Kenney Impact | CC0 | Capa metálica/zapato si se quiere más contundencia | 0.56 |
| `Cinematic Sound Design - Colossal Impacts\Impact Cut Sweep.wav` | Sonniss | Royalty-free | Pisada colosal "de película" para la primera aparición | 2.8 |

### 5. Aparición de OVNI (sting o drone grave)
| Archivo | Pack | Licencia | Uso sugerido | Dur. |
|---|---|---|---|---|
| `Epic Stock Media - Halloween Game - Haunted House and Horror Audio Scare Kit\UIAlert_Alert Designed Transition Swell Creature Strange Alien Layered 01_ESM_HALG.wav` | Sonniss | Royalty-free | **Sting**: swell alienígena extraño para la entrada del OVNI | 6.1 |
| `kenney_sci-fi-sounds\Audio\spaceEngineLow_000..004.ogg` | Kenney Sci-Fi | CC0 | **Drone grave** en loop mientras el OVNI está en pantalla (fade in/out) | 5.0 |
| `kenney_sci-fi-sounds\Audio\spaceEngineLarge_000..004.ogg` | Kenney Sci-Fi | CC0 | Variante más grande/pesada para el mini-UFO/jefe | 5.0 |
| `kenney_sci-fi-sounds\Audio\forceField_000..004.ogg` | Kenney Sci-Fi | CC0 | Pulso/escudo al activarse | 0.95 |
| `Cinematic Sound Design - Sci-Fi Drones\Roomtone Space Ship Interior Muted.wav` | Sonniss | Royalty-free | Drone grave más sutil (cama bajo el sting) | 72.7 |
| `Epic Stock Media - Strange Game Ambient Loops 3\DSGNSynth_Scifi Loop Ship Reactor...wav` | Sonniss | idem | Loop de reactor de nave; ya figura en Música | 60.0 |

### 6. Explosión de jefe
| Archivo | Pack | Licencia | Uso sugerido | Dur. |
|---|---|---|---|---|
| `kenney_sci-fi-sounds\Audio\lowFrequency_explosion_000.ogg` / `_001.ogg` | Kenney Sci-Fi | CC0 | **Cuerpo grave** de la explosión (2.0 s y 1.0 s) | 2.0 / 1.0 |
| `kenney_sci-fi-sounds\Audio\explosionCrunch_000..004.ogg` | Kenney Sci-Fi | CC0 | Capa de crujido/escombros; la `_004` es la más larga | 0.78–1.98 |
| `Epic Stock Media - Anime Game\EXPLDsgn_Explosion Small Blast Enemy Death Crunchy Boom Cartoon Noisy Crash Impact Delay 03_ESM_AG.wav` | Sonniss | Royalty-free | Capa cartoon con cola para el tono humorístico | 1.5 |
| `Federico Soler - Effective Trailer Booms Vol. 2\EffectiveTrailer_Booms_Vol2_011/075/214.wav` | Sonniss | Royalty-free | Boom épico con cola larga (15–17 s) para el golpe final del jefe; recortar | 15.5–17.3 |
| `Ivo Vicic - Fireworks FX\13 Fireworks_powerful explosions_multiples in a row_near.wav` | Sonniss | Royalty-free | Explosiones encadenadas (jefe que se desarma) | 24.2 |

## Recomendación
1. **Alcanza con Kenney (CC0)** para pasos del humano, drone y explosión de jefe: ya están aprobados, son CC0 sin restricciones de redistribución (verificar si el archivo concreto ya está copiado en `audio/sfx`; si no, registrar su procedencia al copiarlo).
2. De Sonniss conviene traer solo **dos pistas**: el ambiente de prado/insectos (Highlands of Norway) y el sting alien (Halloween Game), recortadas y convertidas a OGG. Registrar origen, hash y restricciones en `audio/sfx/PROVENANCE.md` y `docs/THIRD_PARTY_AUDIO_CREDITS.md` al integrarlas.
3. Aleteo: probar primero el quadcopter de juguete con filtro; si no convence, el zumbido tendría que generarse/grabarse (no hay uno limpio en la biblioteca).
4. Música: decidir si hace falta una pista real; los loops de Epic Stock Media solo dan atmósfera.
5. No se usó audio de FX Laser, Lentikula ni Sonniss en gameplay hasta ahora; Lentikula (armas láser CC0) y FX Laser no aportan a esta lista.
