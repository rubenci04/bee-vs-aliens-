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
