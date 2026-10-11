# CATÁLOGO DE ASSETS 01 (Lote 6)

Todos los `.blend` de `art_source/blender/` (43: 3 de `bee_prototype/` y 40 de `future_biomes_v01…v10`) renderizados de costado
(cámara ortográfica, fondo neutro, Blender 5.2 headless, `dev/asset_catalog/render_blend.py`).
- Hoja de contactos: `dev/asset_catalog/contact_sheet.png` (se regenera con `dev/asset_catalog/contact_sheet.gd`, sin `--headless`).
- Renders individuales y datos (triángulos, medidas): `dev/asset_catalog/renders/<nombre>.png|.json`.
- Triángulos = mallas visibles del `.blend` evaluadas (modificadores aplicados). **Referencia de peso:** los visuales de enemigos
  actuales del juego (avispa, sonda, abeja) tienen ~1 000 tris; los assets de Codex tienen 2 000–28 000. Por eso "retoque" = funciona
  pero conviene decimar antes de poblar más niveles (en este lote no se tocó ningún modelo).
- Estado: **listo** (encaja tal cual) · **retoque** (usable, mejorable: peso o detalle) · **descartar** (referencia/estudio, no es
  contenido para el nivel; no se borra nada) · **en uso** (ya estaba en el juego).
- "Escala relativa" = multiplicador del modelo respecto de su tamaño en Blender (1 u ≈ el tamaño de Bee, ~1,1 u de largo).
- `.glb` / `.tscn`: todos tienen `.glb` en `assets/models/` y escena envoltorio en `scenes/art_labs/` (la envoltura aplica toon + contorno).

| Nombre | Tipo | Bioma | Estado | Tris aprox. | Escala relativa sugerida | .glb | .tscn | Nota |
|---|---|---|---|---|---|---|---|---|
| `alien_probe_visual` | enemigo alien (volador) | Jardín / invasión | en uso | 920 | 1.0 (ya en Level 01) | sí | sí | Sonda actual del juego. |
| `alien_seed_carrier` | enemigo alien (volador, minijefe) | Jardín / invasión | listo (9,1k tris, algo pesado) | 9108 | 1.15 (≈2,8 m) | sí | sí | **Integrado** como SEMILLERO ALIEN. |
| `alien_signal_relay` | prop alien | Invasión | listo | 4520 | 2.1 (≈2 m) | sí | sí | **Integrado**: reemplaza columna/anillo de los pilones. |
| `amphibian_mount_study` | estudio (sapo + implante) | Lago | descartar por ahora (22k tris, solo estudio) | 22136 | — | sí | sí | Hoja de estudio de montura; sin rig ni pelea. Reservado para el nivel del lago. |
| `bee_alien_visual` | jugador | — | en uso | 1144 | 1.2 (ya en juego) | sí | no | Bee actual. |
| `canonical_implant_kit` | kit de referencia (4 implantes) | — | descartar (referencia, 28k tris) | 28288 | — | sí | sí | Solo documentación visual del implante canónico; el implante in-game ya viene dentro de cada `controlled_*`. |
| `cattails_cluster` | vegetación | Lago / pantano | listo | 4272 | 3–4 | sí | sí | Para el nivel del lago. |
| `coastal_buoy` | prop humano | Costa | listo | 4592 | 2–3 | sí | sí | Para la costa. |
| `coastal_rowboat` | prop humano | Costa / lago | listo | 5412 | 1.5–2 | sí | sí | Barca grande; fondo. |
| `controlled_ant` | enemigo suelo | Jardín | retoque (13k tris; funciona, conviene decimar) | 13456 | 1.1 (≈2,6 m) | sí | sí | **Integrado** (HORMIGA). |
| `controlled_bomb_moth` | enemigo volador | Jardín / atardecer | retoque (23k tris) | 23592 | 0.85 | sí | sí | **Integrado** (POLILLA). Lo más pesado integrado. |
| `controlled_caterpillar` | enemigo suelo (blindado) | Jardín | retoque (20k tris) | 20344 | 1.0 | sí | sí | Candidata a próxima tanda de suelo; no integrada por peso y solapamiento con escarabajo. |
| `controlled_dragonfly` | enemigo volador | Lago / jardín | retoque (16k tris) | 16580 | 0.8 | sí | sí | **Integrado** (LIBÉLULA ONDULANTE). Convive con la libélula procedural de la fauna controlada. |
| `controlled_firefly` | fauna decorativa | Jardín nocturno | listo (8,9k tris) | 8864 | 0.9 | sí | sí | **Integrado** como decoración (liberada, sin implante) al atardecer. |
| `controlled_flying_ladybird` | enemigo volador (resistente) | Jardín | listo (9,4k tris) | 9384 | 1.15 | sí | sí | **Integrado** (MARIQUITA BLINDADA). |
| `controlled_gull` | enemigo volador | Costa | retoque (11k tris) | 11348 | 1.5 | sí | sí | Costa; no encaja en el jardín. |
| `controlled_manta_ray` | enemigo volador/acuático | Lago / costa | listo (7k tris) | 7280 | 2 | sí | sí | Costa; no encaja en el jardín. |
| `controlled_mosquito` | enemigo volador (rápido) | Lago / jardín | listo (7,8k tris) | 7840 | 1.0 (≈1,7 m) | sí | sí | **Integrado** (MOSQUITO ERRÁTICO). |
| `controlled_mouse` | enemigo suelo | Residencial / jardín | retoque (10,7k tris) | 10748 | 1.5 | sí | sí | Candidato futuro (zona humana). |
| `controlled_mushroom_cannon` | enemigo suelo estático | Jardín | retoque (11,8k tris) | 11822 | 1.0 | sí | sí | **Integrado** (HONGO CAÑÓN). |
| `controlled_octopus` | enemigo acuático | Costa | retoque (20k tris) | 20144 | 2 | sí | sí | Costa. |
| `controlled_owl` | enemigo volador | Bosque / aire | retoque (13,5k tris) | 13540 | 2 | sí | sí | Futuro; demasiado grande para el jardín. |
| `controlled_perch` | fauna acuática | Lago | listo (8k tris) | 8236 | 1.5 | sí | sí | Lago. |
| `controlled_pigeon` | enemigo volador | Residencial | retoque (11k tris) | 11008 | 2 | sí | sí | Futuro (zona humana). |
| `controlled_stag_beetle` | enemigo suelo blindado | Jardín | listo (10k tris) | 9952 | 1.0 (≈2,8 m) | sí | sí | **Integrado** (ESCARABAJO CIERVO). |
| `controlled_stick_insect` | enemigo suelo | Jardín / bosque | listo (7,4k tris) | 7416 | 1.2 | sí | sí | Candidato: silueta muy fina, baja lectura a escala del jardín; no integrado. |
| `controlled_woodland_snail` | enemigo suelo (lento, blindado) | Jardín | listo (7,7k tris) | 7748 | 1.0 (≈2,2 m) | sí | sí | **Integrado** (CARACOL). |
| `empty_drink_can` | prop humano | Jardín | listo (4,6k tris) | 4572 | 4.5 (≈6 m) | sí | sí | **Integrado** como decoración (lata). |
| `flowering_shrub` | vegetación | Jardín | retoque (11,8k tris) | 11784 | 3.2–3.5 | sí | sí | **Integrado** como decoración (4 arbustos). |
| `garden_sapling` | vegetación | Jardín | listo (7,9k tris) | 7904 | 3.0–3.3 | sí | sí | **Integrado** como decoración (brote de árbol, 3). |
| `giant_bottle_cap` | prop humano | Jardín | listo (6k tris) | 5984 | 2.0–2.2 | sí | sí | **Integrado** como decoración (tapa de botella, 2). |
| `lotus_lily_pad` | vegetación | Lago | listo (7,6k tris) | 7632 | 3 | sí | sí | Lago. |
| `moth_stationary_bomb` | proyectil / mina | Jardín | listo (2,5k tris) | 2528 | 1.5 (≈0,6 m) | sí | sí | **Integrado** como cuerpo de las bombas de la polilla. |
| `orbital_skimmer` | vehículo alien | Espacio / atmósfera | listo (5,5k tris) | 5548 | 1.5 | sí | sí | Para los niveles finales. |
| `shore_rock` | decoración | Costa | listo | 5472 | 2 | sí | sí | Costa. |
| `shore_wave_module` | decoración | Costa | listo (7,9k tris) | 7900 | 3 | sí | sí | Costa. |
| `sky_cloud` | cielo | Cielo | listo | 5888 | — | sí | sí | Candidato para el cielo de otros niveles. |
| `sky_crescent_moon` | cielo | Cielo nocturno | listo (3,7k tris) | 3692 | 20% de la altura de pantalla | sí | sí | **Integrado** (cielo final, sin niebla, sin sombreado). |
| `sky_star_cluster` | cielo | Cielo nocturno | listo (2,6k tris) | 2640 | 14–20% de la altura de pantalla | sí | sí | **Integrado** (2 grupos, cielo final). |
| `sky_sun` | cielo | Cielo | listo | 2208 | — | sí | sí | Sin uso en Level 01 (el sol es una luz). |
| `warm_asteroid` | espacio | Espacio | listo (3,8k tris) | 3752 | 3 | sí | sí | Para el nivel espacial. |
| `wasp_enemy_visual` | enemigo volador | Jardín | en uso | 1014 | 1.0 | sí | sí | Avispa actual. |
| `wrapped_candy` | prop humano | Jardín | listo (2k tris) | 2024 | 1.5–1.7 | sí | sí | **Integrado** como decoración (caramelo, 2). |

## Resumen
- **Integrados al Level 01 en el Lote 6 (19 assets):** mosquito, mariquita voladora, libélula (ondulante), polilla + su bomba (moth_stationary_bomb), hormiga, escarabajo ciervo, caracol,
  hongo cañón, alien_signal_relay, alien_seed_carrier, luna creciente, estrellas, luciérnaga, tapa de botella, lata, caramelo, arbusto con flores, brote de árbol. Ver `docs/INFORME_LOTE_6.md`.
- **Reservados** para otros biomas: lago (nenúfar, totoras, perca, sapo, boya, barca), costa (gaviota, pulpo, ola, roca), cielo/espacio (nube, sol, asteroide, skimmer, mantarraya).
- **Para decimar antes de reutilizar:** polilla (23k), oruga (20k), pulpo (20k), libélula (16k), búho (13,5k), hormiga (13k).
- **Sin carpeta nueva más allá de `future_biomes_v10`** al momento de este catálogo.
