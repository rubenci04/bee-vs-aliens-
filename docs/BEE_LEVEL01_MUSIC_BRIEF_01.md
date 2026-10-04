# BEE — LEVEL 01 MUSIC BRIEF 01

Fecha: 2026-10-04 · Rama: `level01-garden-identity-04`. **Solo especificación.** No hay música en la biblioteca local
(confirmado en `docs/BEE_ASSET_LIBRARY_DEEP_AUDIT_02.md` §9) y esta tarea no descarga ni fabrica música. El bus `Music`
ya existe (-8 dB) y está vacío. Este brief sirve para encargar, comprar o elegir pistas sin inventar un título.

## 1. Qué tiene que hacer la música en Level 01
- Dar ritmo arcade a 3–5 minutos de vuelo continuo (360 m a 2 m/s, más combate y jefe).
- Acompañar la **progresión visual ya aprobada**: jardín natural → jardín doméstico → territorio humano → color fuerte
  y contaminación alien (después del checkpoint, X≈190) → silencio → OVNI.
- No tapar jamás los telegraphs: avisos de avispa, carga violeta del Walker, columna de la araña, OVNI.

## 2. Estructura y BPM
| Tramo | X (m) | Rol | BPM | Intensidad |
|---|---|---|---:|---|
| A. Jardín | 0–140 | tema principal, curioso y luminoso | 118–126 | 2/5 → 3/5 |
| B. Territorio humano | 140–198 | mismo tema, más percusión y bajo | mismo BPM (sin cortes) | 3/5 |
| C. Escalada alien | 198–340 | capa alien encima del tema; armonía más tensa | mismo BPM | 4/5 |
| D. Último silencio | ~340 (2,6 s) | **la música se retira** (stinger de salida o fade de 1,5 s) | — | 0 |
| E. Jefe OVNI | 340+ | pista de jefe o variación densa del tema | 132–140 | 5/5 |
| F. Sector despejado | fin | stinger de victoria (3–6 s) | — | — |

Un único BPM para A–C permite **stems** (capas que entran y salen) en vez de cambiar de pista: es lo que mejor sigue la
progresión por actos sin cortes.

## 3. Mood
- Aventura **colorida y con humor**, no infantil: una abeja diminuta contra una invasión enorme.
- Nostalgia **arcade de fines de los 90 / principios de los 2000** (shmups y plataformas 3D de esa época): melodía
  pegadiza, frases de 8 compases, energía constante.
- La amenaza alien suena **real** dentro del tono, pero sin terror.

## 4. Instrumentación
**Capa naturaleza (siempre):** marimba / kalimba / pizzicato, guitarra acústica percusiva, percusión orgánica
(shakers, woodblocks, cajón), bajo cálido.
**Capa arcade (desde A):** batería con groove (no rock pesado), arpegios cortos de sintetizador "retro-limpio"
(no chiptune puro), un lead melódico brillante.
**Capa alien (desde C):** pads con detune, bajos sintéticos con LFO lento, pequeños "blips" cian, sweeps; armonías
modales (lidio / frigio) por encima del tema, no reemplazándolo.
**Jefe (E):** percusión más densa, ostinato de bajo, el tema principal en modo menor o con reharmonización,
brass sintético corto para los cambios de fase.

## 5. Requisitos de loop y técnicos
- Formato: OGG Vorbis (q6+) o WAV 44,1/48 kHz estéreo. Normalizado a ~-14 LUFS integrado, pico ≤ -1 dBTP.
- **Loop limpio** sin clic: o bien intro + loop separados, o un archivo con punto de loop documentado (en compases).
- Duración del loop principal: 1:30–3:00. Pista de jefe: 1:00–2:00 en loop.
- Stems (si se encargan): naturaleza / arcade / alien / percusión, todos de la misma duración y alineados.
- Mezcla pensada para quedar **debajo** de los SFX: poco contenido entre 2–4 kHz en los momentos densos (es donde
  viven los telegraphs) y graves controlados (las explosiones y pisadas gigantes viven ahí).
- Stingers: transición a jefe (2–4 s), victoria (3–6 s), derrota (2–3 s).

## 6. Licencia (obligatoria)
CC0 o royalty-free comercial **explícita para videojuegos**, con texto de licencia descargable que se archiva en el
repo. Nada CC BY-NC, nada "solo uso personal", nada con Content ID que pueda reclamar videos del juego. Registrar en
`docs/THIRD_PARTY_AUDIO_CREDITS.md`.

## 7. Integración prevista (cuando exista la música; no implementado)
- Un `AudioStreamPlayer` en el bus `Music` por capa/stem, volumen gobernado por el acto del director
  (`BeeLevel01Controller.current_act`) y por `director_moment` (`last_silence` → fade out; jefe → pista E).
- Ducking suave (-3 dB) de la música mientras suena un telegraph pesado (overload, barrido, araña, OVNI).
- El ambiente (`GardenAmbience` + `DuskAmbience`) sigue debajo de la música.

## 8. Cómo evaluar candidatos (criterios humanos)
1. ¿Se tararea después de una partida?
2. ¿Sigue sonando bien en la tercera repetición del loop?
3. Con SFX reales (no en solo): ¿se siguen oyendo el aviso de la avispa y la columna de la araña?
4. ¿Suena a "abeja contra aliens en un jardín" y no a "fantasía medieval" ni a "terror"?
