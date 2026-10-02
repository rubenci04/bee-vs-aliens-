# Audio Asset Inventory

Ruta descubierta: `D:\proyectos\V_Asset_Library\01_Extracted\audio`. Biblioteca sólo leída; originales intactos. La evidencia son los LICENSE/README/PDF locales, no la palabra free del nombre.

| Pack | Audios / formato | Autor/fuente | Evidencia | Licencia/restricciones | Estado |
|---|---|---|---|---|---|
| (free)FX_Laser_Sound_Pack | 11 / .wav | Autor no indicado | License.txt + README.txt | Licencia propia: uso comercial/modificación; no redistribuir originales/asset packs; crédito opcional | APPROVED; no seleccionado |
| kenney_impact-sounds | 130 / .ogg | Kenney / www.kenney.nl | License.txt | CC0; comercial y modificación; atribución opcional | APPROVED; seleccionado |
| kenney_interface-sounds | 100 / .ogg | Kenney / www.kenney.nl | License.txt | CC0; comercial y modificación; atribución opcional | APPROVED; seleccionado |
| kenney_sci-fi-sounds | 73 / .ogg | Kenney / www.kenney.nl | License.txt | CC0; comercial y modificación; atribución opcional | APPROVED; seleccionado |
| Sci-Fi Weapon SFX by Lentikula | 15 / .wav | Lentikula | Readme.txt | CC0; comercial y modificación; atribución opcional | APPROVED; no seleccionado |
| Sonniss.com-GDC2026-GameAudioBundle | 347 / .wav | Autores por subcarpeta; distribuido por Sonniss / https://sonniss.com | Readme.txt + License - GDC Game Audio.pdf | Royalty-free: comercial/modificación sin atribución; no venta como sounds sueltos, no reclamar autoría; prohíbe entrenamiento/desarrollo de IA | APPROVED para juego; no seleccionado |

Total: **676 audios**, seis packs. 0 APPROVED WITH ATTRIBUTION, 0 PENDING, 0 REJECTED por licencia. Tres packs aprobados no usados por curación; no significa licencia rechazada.

**36 candidatos / 36 archivos únicos revisados por decodificación y metadata**, no por escucha humana fiable: duración, onset/tail, peak y RMS. Nombres/clasificación del pack guiaron la shortlist (1–4 por cue). Datos completos: `dev/audio_asset_review/candidates.json`. No se decodificaron/importaron los 676 sonidos indiscriminadamente.

## Candidatos y selección

| Cue | Candidatos (rutas relativas a la biblioteca) | Principal / decisión |
|---|---|---|
| base | `Sci-Fi Weapon SFX by Lentikula/Laser Pistol 1.wav` (1.589s)<br>`Sci-Fi Weapon SFX by Lentikula/Laser Pistol 2.wav` (1.406s)<br>`kenney_sci-fi-sounds/Audio/laserSmall_000.ogg` (0.239s)<br>`kenney_sci-fi-sounds/Audio/laserSmall_001.ogg` (0.247s) | kenney_sci-fi-sounds/Audio/laserSmall_000.ogg |
| spread | `Sci-Fi Weapon SFX by Lentikula/Laser Rifle 1.wav` (2.549s)<br>`Sci-Fi Weapon SFX by Lentikula/Laser Rifle 2.wav` (2.344s)<br>`kenney_sci-fi-sounds/Audio/laserLarge_000.ogg` (0.677s) | kenney_sci-fi-sounds/Audio/laserLarge_000.ogg |
| tech_hit | `kenney_sci-fi-sounds/Audio/impactMetal_000.ogg` (0.635s)<br>`kenney_impact-sounds/Audio/impactTin_medium_000.ogg` (0.159s) | kenney_sci-fi-sounds/Audio/impactMetal_000.ogg |
| organic_hit | `kenney_impact-sounds/Audio/impactSoft_medium_000.ogg` (0.118s)<br>`kenney_impact-sounds/Audio/impactSoft_medium_001.ogg` (0.183s) | kenney_impact-sounds/Audio/impactSoft_medium_000.ogg |
| melee | `kenney_impact-sounds/Audio/impactPunch_medium_000.ogg` (0.430s)<br>`kenney_impact-sounds/Audio/impactPunch_heavy_000.ogg` (0.649s) | kenney_impact-sounds/Audio/impactPunch_medium_000.ogg |
| bomb | `kenney_sci-fi-sounds/Audio/forceField_000.ogg` (0.954s)<br>`kenney_sci-fi-sounds/Audio/lowFrequency_explosion_000.ogg` (2.000s)<br>`kenney_sci-fi-sounds/Audio/explosionCrunch_000.ogg` (0.777s) | kenney_sci-fi-sounds/Audio/forceField_000.ogg + lowFrequency_explosion_000.ogg (máximo dos capas) |
| bee_damage | `kenney_impact-sounds/Audio/impactPunch_medium_001.ogg` (0.405s)<br>`kenney_impact-sounds/Audio/impactSoft_heavy_001.ogg` (0.572s) | kenney_impact-sounds/Audio/impactPunch_medium_001.ogg |
| bee_defeat | `kenney_interface-sounds/Audio/minimize_001.ogg` (0.258s)<br>`kenney_interface-sounds/Audio/minimize_002.ogg` (0.258s) | kenney_interface-sounds/Audio/minimize_001.ogg |
| tech_death | `kenney_sci-fi-sounds/Audio/explosionCrunch_001.ogg` (1.357s)<br>`kenney_sci-fi-sounds/Audio/explosionCrunch_002.ogg` (1.256s) | kenney_sci-fi-sounds/Audio/explosionCrunch_000.ogg; reutiliza el candidato corto revisado en Bomb |
| organic_death | `kenney_sci-fi-sounds/Audio/slime_000.ogg` (0.500s)<br>`kenney_sci-fi-sounds/Audio/slime_001.ogg` (4.710s) | Placeholder procedural conservado |
| crate | `kenney_impact-sounds/Audio/impactWood_heavy_000.ogg` (0.313s)<br>`kenney_impact-sounds/Audio/impactPlank_medium_000.ogg` (0.779s) | kenney_impact-sounds/Audio/impactPlank_medium_000.ogg |
| spread_pickup | `kenney_interface-sounds/Audio/confirmation_001.ogg` (0.290s)<br>`kenney_interface-sounds/Audio/confirmation_002.ogg` (0.539s) | kenney_interface-sounds/Audio/confirmation_001.ogg |
| bomb_pickup | `kenney_interface-sounds/Audio/maximize_001.ogg` (0.258s)<br>`kenney_interface-sounds/Audio/maximize_002.ogg` (0.258s) | kenney_interface-sounds/Audio/maximize_001.ogg |
| pollen | `kenney_interface-sounds/Audio/pluck_001.ogg` (0.102s)<br>`kenney_interface-sounds/Audio/pluck_002.ogg` (0.164s) | kenney_interface-sounds/Audio/pluck_002.ogg |
| human_warning | `kenney_sci-fi-sounds/Audio/lowFrequency_explosion_001.ogg` (1.000s)<br>`kenney_sci-fi-sounds/Audio/forceField_001.ogg` (0.953s) | Placeholder procedural conservado |
| human_step | `kenney_impact-sounds/Audio/footstep_grass_000.ogg` (0.777s)<br>`kenney_impact-sounds/Audio/footstep_concrete_000.ogg` (0.106s) | kenney_impact-sounds/Audio/footstep_grass_000.ogg |

## Descartes y reservas

Lentikula: rifles de 2.34–2.55s y pistolas de 1.4–1.6s incluyendo cola/silencio; preferida la familia Kenney corta y coherente. FX Laser y Sonniss: legalmente utilizables, pero sin promoción porque la shortlist cubre los eventos con packs pequeños; Sonniss tiene recordings extensos, voces/gore/ambientes que no se ajustan a esta pasada. No se copiaron estos packs ni se usaron para entrenar/desarrollar IA.

Organic death: slime_001 dura 4.71s y slime_000 no asegura mejora estética sin escucha; se conserva el chirp procedural sin gore. Human warning: forceField/explosion no comunica inequívocamente aviso de humano; se conserva el pulse V01. Para crate se eligió el impacto de tabla más breve; aún requiere escucha para confirmar que se percibe como ruptura y no sólo golpe.

No se afirma que una duración/forma de onda demuestre calidad artística. La elección sonora final necesita playtest humano A/B.
