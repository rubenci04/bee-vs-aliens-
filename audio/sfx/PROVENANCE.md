# Bee SFX — procedencia

## PROCEDURAL PLACEHOLDERS

16 WAV mono PCM16 / 22.050 Hz, generados localmente mediante `tools/generate_bee_sfx_v01.gd` con tonos, ruido determinista y envolventes suaves. Son assets procedurales originales del proyecto, sin grabaciones/muestras externas y sin obligaciones de licencia de terceros. No se declara ninguna licencia externa ni se hace pasar este material por audio final.

Antes de generarlos se buscaron WAV/OGG/MP3/FLAC en Bee Alien 3D y V_Asset_Library, y en los directorios centrales de 26 ZIP de la biblioteca: cero archivos de audio. Los nombres laser encontrados correspondían a geometría/previews, no sonidos. No hubo descargas, promoción desde biblioteca, música o voces.

Placeholder funcional V01. Regeneración: Godot headless con `--script res://tools/generate_bee_sfx_v01.gd`, después importar desde el editor. El generador sobrescribe únicamente estos 16 WAV dentro del proyecto. Duraciones 0,085–0,58 s; sin loops; amplitud PCM limitada a ±0,4.

## REAL ASSETS V02

14 WAV seleccionados, derivados de 15 OGG originales CC0 de Kenney. Los 16 placeholders originales permanecen intactos. Copias de licencias: `licenses/Kenney_SciFi.txt`, `licenses/Kenney_Impact.txt`, `licenses/Kenney_Interface.txt`.

Autor: Kenney. Fuente de distribución: biblioteca local del usuario; fuente indicada por los packs: www.kenney.nl. Licencia: CC0 (http://creativecommons.org/publicdomain/zero/1.0/), atribución no obligatoria. Créditos de cortesía: `docs/THIRD_PARTY_AUDIO_CREDITS.md`.

Las rutas Source siguientes son relativas a `D:\proyectos\V_Asset_Library\01_Extracted\audio`. El script `tools/integrate_audio_v02.gd` modifica únicamente las copias elegidas; nunca los originales.

### base
- Original: `kenney_sci-fi-sounds/Audio/laserSmall_000.ogg`
- SHA256 original: `72b589eadd41781257ac859e4f4d030222e623390e4a1a83f6d05329a6e026f1`
- Bee: `res://audio/sfx/real/base.wav` (0.200s)
- SHA256 Bee: `cede369e388af8f64bbaec152c8167987b5488037430c6bf47bc4e2cf820b88b`
- Cambios: OGG decoded to mono PCM16 WAV; shortened; normalized to peak 0.40; 2ms/35ms fades; pitch baked 1.0.

### bee_damage
- Original: `kenney_impact-sounds/Audio/impactPunch_medium_001.ogg`
- SHA256 original: `e71d23abcc3f10d9d6bc9615b2a431fff70b12333a5fcdd9964457564ace4349`
- Bee: `res://audio/sfx/real/bee_damage.wav` (0.290s)
- SHA256 Bee: `aed9cd2ab365eb61ce9215ca2091230efcfc66637cf22652bd673868f84c085a`
- Cambios: OGG decoded to mono PCM16 WAV; shortened; normalized to peak 0.40; 2ms/35ms fades; pitch baked 1.0.

### bee_defeat
- Original: `kenney_interface-sounds/Audio/minimize_001.ogg`
- SHA256 original: `8481912bc7fa5828924a00ef15b6cd613b994956e0817bd3122065c9b2896d2d`
- Bee: `res://audio/sfx/real/bee_defeat.wav` (0.258s)
- SHA256 Bee: `8fd01e0b81457f753235e797e12b1bc6799a91b837d27e200310bb2e05bbb153`
- Cambios: OGG decoded to mono PCM16 WAV; shortened; normalized to peak 0.40; 2ms/35ms fades; pitch baked 1.0.

### bomb
- Original: `kenney_sci-fi-sounds/Audio/forceField_000.ogg`
- SHA256 original: `c2916f2a062c8ddd1aca2826d134fe90847037db31342726ffb0f9097afe339c`
- Bee: `res://audio/sfx/real/bomb.wav` (0.700s)
- SHA256 Bee: `d8c42f62a95b4dde6b68339c9f80755c14c2926bae42f2c28e85a557bdd305a4`
- Cambios: OGG decoded to mono PCM16 WAV; shortened; normalized to peak 0.40; 2ms/35ms fades; two layers, low pulse delayed 25ms; pitch baked 1.0.
- Segunda capa CC0: `kenney_sci-fi-sounds/Audio/lowFrequency_explosion_000.ogg`
- SHA256 segunda capa: `3cb48d86dab63140cfb9aaeea4d4a6846abaca5831d157d8adbec0490da26343`

### bomb_pickup
- Original: `kenney_interface-sounds/Audio/maximize_001.ogg`
- SHA256 original: `fd3e75e1de2f2fda90aceeacaeb0427ac8bddd3b07a6ce2a8f9ba923df3771f9`
- Bee: `res://audio/sfx/real/bomb_pickup.wav` (0.258s)
- SHA256 Bee: `32783a6bac699b1479616ea510568ec8fcc52792a45fd21e6ec5ac9673822585`
- Cambios: OGG decoded to mono PCM16 WAV; shortened; normalized to peak 0.40; 2ms/35ms fades; pitch baked 1.0.

### crate
- Original: `kenney_impact-sounds/Audio/impactPlank_medium_000.ogg`
- SHA256 original: `8403cd7a043f0391574c88c55dd205743725b5363d2407f6de145f201690b68f`
- Bee: `res://audio/sfx/real/crate.wav` (0.300s)
- SHA256 Bee: `7a563b58f52a3b26c6941a0b3aeed63cf7d4392a4c9fbc5539ff6cc385dc26a4`
- Cambios: OGG decoded to mono PCM16 WAV; shortened; normalized to peak 0.40; 2ms/35ms fades; pitch baked 1.0.

### human_step
- Original: `kenney_impact-sounds/Audio/footstep_grass_000.ogg`
- SHA256 original: `9d49497777405d78d7cf7f2888e28277f3a23192300cfd1d79d54876b20f479f`
- Bee: `res://audio/sfx/real/human_step.wav` (0.300s)
- SHA256 Bee: `77854b42e7b59b5db8d861d62e1047aa5dd41cdbbea1e1ce22bfd67bc25ed484`
- Cambios: OGG decoded to mono PCM16 WAV; shortened; normalized to peak 0.40; 2ms/35ms fades; pitch baked 0.7.

### melee
- Original: `kenney_impact-sounds/Audio/impactPunch_medium_000.ogg`
- SHA256 original: `486988aa2d6440ffc4c62a0e8ccf3c23673ba84424bd4723378d451b7255eb5c`
- Bee: `res://audio/sfx/real/melee.wav` (0.300s)
- SHA256 Bee: `ef73209eae45abc66bc1aefd0e1ca20b75e54f58ea51d4438f2804f254c6179b`
- Cambios: OGG decoded to mono PCM16 WAV; shortened; normalized to peak 0.40; 2ms/35ms fades; pitch baked 1.0.

### organic_hit
- Original: `kenney_impact-sounds/Audio/impactSoft_medium_000.ogg`
- SHA256 original: `7d3ba0bb5e60a11b5d3e558c141303dcf494256675fbf753c0d252d2cf0481e3`
- Bee: `res://audio/sfx/real/organic_hit.wav` (0.118s)
- SHA256 Bee: `29fa9ecc75f384e6770e9e6fe46177328fcd60c28f220ea37d2c4ae1b33277d1`
- Cambios: OGG decoded to mono PCM16 WAV; shortened; normalized to peak 0.40; 2ms/35ms fades; pitch baked 1.0.

### pollen
- Original: `kenney_interface-sounds/Audio/pluck_002.ogg`
- SHA256 original: `c977fe249ff42d1c93a552b33abc13a8399df3879fa510475426e5c4bbac1da9`
- Bee: `res://audio/sfx/real/pollen.wav` (0.130s)
- SHA256 Bee: `15743c3c0240ad5fd51bcd3f7bbea35bfc024609602b77d2dae623bba9d74b25`
- Cambios: OGG decoded to mono PCM16 WAV; shortened; normalized to peak 0.40; 2ms/35ms fades; pitch baked 1.0.

### spread
- Original: `kenney_sci-fi-sounds/Audio/laserLarge_000.ogg`
- SHA256 original: `a56d95794cd732d6c2d66ce488c14cf557fe526c282897c9a77675c2bd9b77e6`
- Bee: `res://audio/sfx/real/spread.wav` (0.340s)
- SHA256 Bee: `09622dfb4568b20b4027fc02863eebfc46862df95a0f188eb37b3b2af912b7f4`
- Cambios: OGG decoded to mono PCM16 WAV; shortened; normalized to peak 0.40; 2ms/35ms fades; pitch baked 1.0.

### spread_pickup
- Original: `kenney_interface-sounds/Audio/confirmation_001.ogg`
- SHA256 original: `063564703b6094d70718a3e787a55cc9141611e4ecd6b6637f8828f79b4a8c3a`
- Bee: `res://audio/sfx/real/spread_pickup.wav` (0.290s)
- SHA256 Bee: `5997e5e4dfb73794803768ce151404998ba7607ee3dc91bd1a93a68a9f3827da`
- Cambios: OGG decoded to mono PCM16 WAV; shortened; normalized to peak 0.40; 2ms/35ms fades; pitch baked 1.0.

### tech_death
- Original: `kenney_sci-fi-sounds/Audio/explosionCrunch_000.ogg`
- SHA256 original: `4b597d658d0ae101f0a030fbeea5fc3a4292ab85f017470a8254a8e7959cbd69`
- Bee: `res://audio/sfx/real/tech_death.wav` (0.550s)
- SHA256 Bee: `13bcfa8107cd2db1212aa6e3ce03251f1f2a83bfd2c054044609ca5ac9acca86`
- Cambios: OGG decoded to mono PCM16 WAV; shortened; normalized to peak 0.40; 2ms/35ms fades; pitch baked 1.0.

### tech_hit
- Original: `kenney_sci-fi-sounds/Audio/impactMetal_000.ogg`
- SHA256 original: `956c6612a256aa1a67a2327fffe2454f6b1d82e4c1c2be28fd66916335d5b1d6`
- Bee: `res://audio/sfx/real/tech_hit.wav` (0.280s)
- SHA256 Bee: `442752dce1c37089a94c70a327382c6c17eb4f5fa69da706c9400dd93026699f`
- Cambios: OGG decoded to mono PCM16 WAV; shortened; normalized to peak 0.40; 2ms/35ms fades; pitch baked 1.0.

## POLISH-02 AUDIO (generado con `tools/integrate_audio_polish02.gd`)

Los originales de la biblioteca no se tocan. Rutas Source relativas a `D:\proyectos\V_Asset_Library\01_Extracted\audio`.

### garden_loop (ambiente de jardín, bus Ambience)
- Original: `Sonniss.com-GDC2026-GameAudioBundle/Just Sound Effects - Highlands of Norway/AMBSwmp_Meadow Pipits calling many Insects humming Wind blowing through Grass_JSE_HoN_Stereo.wav`
- Autor/pack: Just Sound Effects, "Highlands of Norway", dentro de Sonniss.com GDC 2026 Game Audio Bundle (Part 9).
- Licencia: Sonniss GDC Royalty-Free (`License - GDC Game Audio.pdf`): uso comercial en el juego, sin atribución. Restricciones: no revender ni redistribuir los sonidos tal cual y **prohibido entrenar IA con ellos**.
- SHA256 original: `b47ac8ae869b52760bfd41e195e37a319c822ad04a734aec0c869bc4a5eee280`
- Bee: `res://audio/ambience/garden_loop.wav` (21.5 s, loop)
- SHA256 Bee: `a3c762f65a1d0691bfda78be9b0a41d4652449a13127b2bd69a5240b55de183e`
- Cambios: ventana más estable de 24 s desde 5.0 s, crossfade de loop 2.5 s, remuestreo, pico 0.30, PCM16 estéreo.

### wing_buzz (zumbido de aleteo de Bee, bus SFX)
- Original: `Sonniss.com-GDC2026-GameAudioBundle/Sonik Sound Library - Toy Quadcopter/AERORadio_Quadcopter, Toy, Flying Sustained Close to Mic_KSL_KS013.wav`
- Autor/pack: Sonik Sound Library, "Toy Quadcopter", dentro de Sonniss.com GDC 2026 Game Audio Bundle. Licencia: igual que arriba (Sonniss GDC Royalty-Free, sin IA).
- SHA256 original: `ae90f7d2cf44d9cd4c8badb21a138109fbbf36b89ac008aa6681332553c8a077`
- Bee: `res://audio/sfx/real/wing_buzz.wav` (3.6 s, loop)
- SHA256 Bee: `78a207811feca597e03b8fc210d09c1c58d06523bf34740b6120b18c9d8362b8`
- Cambios: mono, ventana estable de 4 s desde 13.0 s, 2 pasa-bajos de un polo a 900 Hz, pasa-altos 110 Hz, crossfade de loop 0.4 s, pico 0.50, PCM16 mono.

### human_step_b / human_step_c (variaciones de pasos del humano gigante)
- Autor: Kenney (Impact Sounds 1.0). Licencia: CC0.
- human_step_b: original `kenney_impact-sounds/Audio/footstep_grass_001.ogg`, SHA256 original `fb28781bd22b2eefdc14077f1adf5c94d7fe9c3a130194633b55f3e0d39d9f04`, Bee `res://audio/sfx/real/human_step_b.wav`, SHA256 Bee `7904f3da67d7ca2c22d17e00ebfb035aa1f74900d95094d061dcb2d3a3d7b864`.
- human_step_c: original `kenney_impact-sounds/Audio/footstep_grass_002.ogg`, SHA256 original `73a520139f5be716a403bfe9c80e0e94d1e61d8e9de04a354b336392164b53dc`, Bee `res://audio/sfx/real/human_step_c.wav`, SHA256 Bee `146953230e43661c02802c8060d3306b9ff19cdea957c88cf35c673c083d5c98`.
- Cambios (ambos): OGG decoded to mono PCM16 WAV; shortened; normalized to peak 0.40; 2ms/35ms fades; pitch baked 0.70.

### Niveles (referencia: pico de un disparo base = 0.40 -20 dB cue -3 dB bus SFX = -31 dBFS)
- Ambiente: pico 0.30, jugador -24 dB, bus Ambience -6 dB: pico ~ -40 dBFS (RMS ~ -54 dBFS).
- Zumbido: pico 0.50, jugador -36 dB, bus SFX -3 dB: pico ~ -45 dBFS.
- Pasos del humano: cue -21 dB (antes -16): ~ -32 dBFS, al nivel de un disparo y por debajo de bomba (-8 dB) y explosiones (-15 dB).

## UFO BOSS 01 (generado con `tools/integrate_audio_ufo01.gd`)

Rutas Source relativas a `D:\proyectos\V_Asset_Library\01_Extracted\audio`. Originales sin tocar.

### ufo_sting (entrada del OVNI)
- Original: `Sonniss.com-GDC2026-GameAudioBundle/Epic Stock Media - Halloween Game - Haunted House and Horror Audio Scare Kit/UIAlert_Alert Designed Transition Swell Creature Strange Alien Layered 01_ESM_HALG.wav`
- Autor/pack: Epic Stock Media, "Halloween Game", en Sonniss.com GDC 2026 Game Audio Bundle (Part 9). Licencia: Sonniss GDC Royalty-Free, sin atribución obligatoria; no revender ni redistribuir los sonidos tal cual; **prohibido entrenar IA con ellos**.
- SHA256 original: `56f3499d2097f22856aa5c2007217de6f6adae4db5135544277b84b9e323cad6`
- Bee: `res://audio/sfx/real/ufo_sting.wav` (3,4 s). SHA256 Bee: `9a112eebe1d8d1baa3a1fa0d322a61ae59467410c1ec20a0aea18d8c7fb83dca`
- Cambios: mono PCM16, primeros 3,4 s, fade-in 4 ms, fade-out 0,8 s, pico 0,45.

### ufo_charge (telegraph de ataque)
- Original: `kenney_sci-fi-sounds/Audio/forceField_002.ogg`. Autor: Kenney (Sci-Fi Sounds 1.0). Licencia: CC0.
- SHA256 original: `051b0eafc479695af4ca3607d41fd4be41bae7c21f4f9508d004722b09f1bd63`
- Bee: `res://audio/sfx/real/ufo_charge.wav` (0,45 s). SHA256 Bee: `de81f3e143acc251756941ff63ba34af13ab731e935fd2aac6cd6a9004c5990c`
- Cambios: mono PCM16, primeros 0,45 s, fade-in 4 ms, fade-out 0,12 s, pico 0,40. Pitch 1,2 (aimed) / 0,85 (abanico) / 0,6 (transición) en tiempo de ejecución.

### ufo_hover (loop del platillo)
- Original: `kenney_sci-fi-sounds/Audio/spaceEngineLow_000.ogg`. Autor: Kenney. Licencia: CC0.
- SHA256 original: `d7deee8d7217ce63aab802ad7365a59cacfd243392dc1bd03b0a9d454aa494df`
- Bee: `res://audio/sfx/real/ufo_hover.wav` (4,5 s, loop). SHA256 Bee: `4e82c91591f799e1bff5511b97130a84b4773174c2c3f41e278305ecbe98986c`
- Cambios: mono PCM16, crossfade de loop 0,5 s, pico 0,35. Se reproduce con AudioStreamPlayer3D a −22 dB en el bus SFX.

### ufo_death (explosión final)
- Originales: `kenney_sci-fi-sounds/Audio/lowFrequency_explosion_000.ogg` y `kenney_sci-fi-sounds/Audio/explosionCrunch_004.ogg`. Autor: Kenney. Licencia: CC0.
- SHA256 originales: `3cb48d86dab63140cfb9aaeea4d4a6846abaca5831d157d8adbec0490da26343` / `9c3a1c73cadf0de5d5a578b31a264f20b1ac7cb6ec9bbd34a203f58402ea5390`
- Bee: `res://audio/sfx/real/ufo_death.wav` (2,2 s). SHA256 Bee: `4c6b209832a49968e41276175f1a916149bb635db52c82289816f6678b6109eb`
- Cambios: dos capas mezcladas a mono (crunch con 30 ms de retardo), 2,2 s, fade-out 0,4 s, pico 0,45.

## GARDEN IDENTITY & AUDIO PASS 04 (2026-10-04)

Herramienta: `tools/integrate_audio_garden04.gd` (idempotente: dos ejecuciones dan los mismos SHA-256). Fuentes en
`D:\proyectos\V_Asset_Library\01_Extracted\audio\` (abreviado `SON\` = `Sonniss.com-GDC2026-GameAudioBundle\`).
Licencias: Sonniss GDC 2026 royalty-free (sin atribución obligatoria; prohibido revender/redistribuir tal cual y
entrenar IA con los sonidos) y Kenney CC0. Selección: análisis de señal + espectrogramas
(`dev/audio_audition/analysis/`), **pendiente de confirmación auditiva del usuario** en
`dev/audio_audition/audio_audition.tscn` (F6, tecla A = A/B con lo anterior). Ningún original modificado.
Cues: mono PCM16 a la tasa de mezcla, pico 0,40, ≤ 0,72 s (contrato V02); muertes 0,60 s para que toda voz temporal termine en 1 s aun con pitch 0,82 de enemigo pesado y la variación. Los placeholders V01 siguen intactos.

| Bee | Fuente (SHA-256 fuente) | Cambios | SHA-256 Bee |
|---|---|---|---|
| `real/tech_death.wav` (reemplaza Kenney explosionCrunch) | `SON\Epic Stock Media - Anime Game\EXPLDsgn_Explosion Small Blast Enemy Death Crunchy Boom Cartoon Noisy Crash Impact Delay 03_ESM_AG.wav` (`0fdfac62d1c0b80a9db28e41c878562ab67825202cb863e8a0a600c35c333dc4`) | desde el onset, 0,60 s, fade-out 180 ms | `65b6b0b270ce6208a03eddc9c526de0de4ff102b7670b10672d5a5d6efdd93d4` |
| `real/organic_death.wav` (nuevo; antes placeholder procedural) | `SON\Epic Stock Media - Tower Defense Game\WOODImpt_Hit Blood Spill Splat Wood Impact Light Hit Squelch Small Thump 03_ESM_TDG.wav` (`022152183544436b2e7ae8c82ae3cb1cff6dff5e9c0153e1096a1b638e90e518`) + `SON\Cinematic Sound Design - Cartoon & Animation Vol 2\Cartoon Bubbles Short.wav` (`13bfc9f9b66dbe1208810fca8963fc154058063657079559980ce05c986c41fc`) | splat + burbujas a +70 ms ×0,55, 0,60 s, fade-out 150 ms | `b22ac3c63ad8fb85a7c1bed6c61aa9220f9be8d7d7f9b4c5cfe06892e557a097` |
| `real/wasp_overload.wav` (nuevo; antes ufo_charge ×1,7) | `SON\SoundBits - Vox Bestiae - Source Elements\CREAInsc_Insectoid Creature Tremble Attack Long 1_SNDBTS_VB-SE.wav` (`2be627183c6652ae6ae47528cae580fb0311c03f544951e3060af5e588419e9c`) | desde el onset, 0,72 s, fade-out 160 ms | `d5d65a36ff3b7debbe99941510af8839a4221e912f3abc505606f107efacd094` |
| `real/organic_charge.wav` (nuevo) | `SON\Epic Stock Media - Anime Game\DSGNMisc_Misc Monster Tentacle Modulated Creature Shadow Abstract Swept Wobble Lfo 02_ESM_AG.wav` (`d10c51599a12fbf9bcd9e73bc44bddd040029265fd33a514ff145396d7aebc2c`) | desde el onset, 0,72 s, fade-out 140 ms | `ca3bd5c42b8bf610ee026541fa01fa3a8c065209f839098fb13ae6b290f0d575` |
| `real/walker_charge.wav` (nuevo) | `SON\Epic Stock Media - Tower Defense Game\ROBTMvmt_Tower Deploy Hitech Robot Motor Dark Thump Servo Whine 04_ESM_TDG.wav` (`c9f2c8b24ce6ae6fb7b519b2bbcdb2503816ca5cdd6c8f81ee3fc27149600d48`) | desde el onset, 0,72 s, fade-out 120 ms | `f88ed7c463728225098d8fda65661a675eca7a04d73a0d2e05a129ffba796c69` |
| `real/human_step.wav`, `_b`, `_c` (reemplazan) | Kenney `footstep_grass_000/001/002.ogg` (misma receta V02: onset, pitch 0,7) + `SON\Cinematic Sound Design - Colossal Impacts\Impact Cut Sweep.wav` (`e6b918055aa5ed53917ad217ed9077b0bfff5b0c7bcf97d07ba48be492b61b21`) | el crujido conserva su pico 0,40; golpe grave desde 15 ms antes de su pico, pico 0,32, +30 ms; 0,60 s, fade-out 200 ms | `3c58e9a903001f49ca39ea4e42017c60312a5a06f7357ebf68a79766673c9fa1` / `f64f45d53e1a87c7448b96b139f486161fb336dc3efa8d26136244e41e8db288` / `b9089bafd727823ba4bd354d4cfdfdb13b35b697aca32ef94f72b9f50c602d6e` |
| `real/spider_telegraph.wav` (nuevo) | `SON\InMotionAudio - Arc\ELECArc_ArcDesign15_InMotionAudio_Arc.wav` (`87c709fed078cfea7447e1e13b50715c59d7d78f2589d7bba9382ed3fafbef69`) | desde el onset, 0,62 s, fade-out 140 ms | `afbf79561d22a356a6b3c5ebb03e57103ff31e86c80430c7022aafe5bed03d59` |
| `real/spider_drop.wav` (nuevo) | `SON\Cinematic Sound Design - Ultra Transitions & Impacts\Woosh Sweep Slide Infographics Basic.wav` (`c4e52e70037d52909874ad89d07720c72a24923a54bacb8892f742f2f5660fb5`) | desde el onset, 0,72 s, fade-out 60 ms | `e06411ffd74b331cfc620f5299510e40e1108d2e7b75b0a22458bbf0e87978fa` |
| `real/spider_retract.wav` (nuevo) | `SON\Epic Stock Media - HD Lock And Mechanism Sound Design Kit\MECHMisc_Tool Tape Measure Pull Retract Spring Slide Spin Long 07_ESM_HDLM.wav` (`98ca9a8955b69cbe6844614bb0de2973014f9845314d17aa5f02a8f44cdfbfff`) | tramo de retracción desde 1,95 s, 0,60 s, fade-out 120 ms | `ce656205035d5452f5c2e8168bac889b01eaa72fff4a9178370d717412b2e544` |
| `real/ufo_approach.wav` (nuevo, one-shot largo) | `SON\344 Audio - Air Designed\AEROJet_Unidentified Encounter_344 Audio_Air Designed.wav` (`45021960e53ba666e0e2c563480f469a3af05f69661a0b71d93276277b9166b2`) | tramo 2,0–7,0 s, fade-in 1,0 s, fade-out 0,7 s, pico 0,50 | `ca923751c06bba4c7494974f6afd225d10f4842191fa704bc98696f35ccac118` |
| `ambience/dusk_loop.wav` (nuevo, loop) | `SON\344 Audio - East Coast America Vol. 1\AMBSubn_Ambience, Forest Crickets, Birds, Connecticut 02_344 Audio_East Coast America.wav` (`d227b21d2df0f329acd490ad1c4ecaddfef4e19f295880a40116a60112da147f`) | ventana más estable de 22 s desde 2 s, crossfade de loop 2,5 s, pico 0,30 | `b7747a72943c16a2935da052c02b2d8270b4251458bc8f51ad3d656885974ccc` |

Mezcla (cue → dB): telegraphs hostiles `wasp_overload` −15, `walker_charge`/`organic_charge`/`spider_telegraph` −16
(prioridad 4) > muertes `tech_death`/`organic_death` −17 (antes −15/−16) > golpes −20/−21 > ambiente (−24, dusk −27).
El peligro del jugador (`bee_damage` −11, `bomb` −8) sigue arriba. Variación por reproducción en muertes, golpes,
cajas y araña (pitch ±3–6 %, volumen ±0,5–1,5 dB).
