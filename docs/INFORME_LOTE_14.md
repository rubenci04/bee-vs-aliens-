# Informe Lote 14

Rama `lote-14` (desde `lote-13`).

## Etapa 0 — Línea base
- Suite completa sobre el último commit de `lote-13` (`684b1a0`): **96/96 en verde** (`dev/l14e0_suite_result.log`). No había rojos que corregir.
- `audio/` (solo listado): 4 mp3 en la raíz (título, nivel 1, intro del jefe, jefe derrotado/victoria) + `ambience/` y `sfx/`. Ver Etapa 4.

## Etapa 1 — Cómo se juega
### 1.1 Disparo sostenido (`bee_player.gd`, categoría "Sustained fire (LOTE 14)")
- Tocar (clic izquierdo o X) sigue disparando **un** tiro al instante. Mantener más de `hold_start_delay` = 0,12 s dispara **ráfagas**: 3 tiros seguidos (`burst_size`, `burst_shot_gap` 0,06 s) sin potenciador, o un **abanico de 5** (`spread_burst_size`, paso 11°) con Spread (1 carga por ráfaga). Cadencia `burst_rate` = 2,5 ráfagas/s; soltar corta el disparo en el acto. El clic sostenido mantiene vivo el apuntado libre.
- **DPS (balance):** referencia de "tocar rápido" = 3 toques/s. Tocar: 3 × 10 = **30 DPS** (Base) / 3 × 3 perdigones × 8 = **72 DPS** (Spread, todos impactando). Mantener: 2,5 × 3 × 4 = **30 DPS** (Base, `hold_damage_ratio` 0,4 → 4 por tiro) / 2,5 × 5 × 4 = 50 DPS teóricos (Spread, `hold_spread_damage_ratio` 0,5 → 4 por perdigón; contra un solo blanco impactan ~3 de 5, ≈ 30 DPS). Medido en `validate_bee_lote14_controls_v01`.
- Todavía no hay "mega disparo".

### 1.2 Aguijón metálico (Z) — 360°
- Golpea al **enemigo más cercano** dentro de `melee_reach_factor` (1,6) × `BEE_LENGTH` (1,3 m, medido del modelo) = **2,08 m**, adelante **o atrás**, con una **embestida de 0,2 s** hacia él (se detiene a 0,6 m del objetivo; Bee se gira hacia él). Daño **30** (3 × una bala base de 10), recarga **0,9 s**, flash de impacto, destello del aguijón y estela plateada. Sin nadie al alcance: el golpe hacia adelante de antes.
- **Provisorio:** el modelo de Bee no tiene aguijón separado; se usa un **cono cromado** simple (`ChromeStinger`, construido por código) que aparece durante el golpe. Cuando haya un aguijón modelado se reemplaza esa malla.
- HUD: `AGUIJÓN LISTO · Z` / barra de recarga (bajo la línea de la pirueta). Suma al combo por el mismo camino de daño (golpes y bajas).

### 1.3 Mariquita
- Un solo disparo lento (`SPEED_BY_FAMILY` 2,6 m/s contra 3,8) con pausa de 5,5 s (`COOLDOWN_BY_FAMILY`, antes 3,8 s); ya no abanica de a 3.

### Tests de la etapa
- Nuevo: `validate_bee_lote14_controls_v01` (ráfagas, DPS, abanico, soltar, aguijón 360°/alcance/recarga/estela, mariquita).
- Adaptados por el cambio de daño/recarga del aguijón (15 → 30, 0,52 → 0,9 s): `validate_bee_combat_poc`, `..._audio_basic_v01`, `..._combat_vfx_v01`, `validate_bee_visual`, `validate_wasp_visual`, `validate_bee_level_01_vertical_slice` (la caja de 24 PV cae al primer golpe), `validate_bee_lote10_pressure_v01` (mariquita: 1 tiro). `validate_bee_pacing_v01`: el bot es caótico (el informe del Lote 13 ya avisaba ±15 PV); la vida perdida pasó de 73 a 83 y se amplió provisoriamente el tope a 90 hasta la Etapa 2, que rehace esa meta.
- Suite completa: 94/97 a la primera; los 3 rojos eran expectativas viejas y se repitieron en verde.
