# Informe Lote 13

## Etapa 0 — Guardar lo pendiente

- Etapa 3 del Lote 12 (robot mini-jefe y tarántula): suite completa 95/95 y commit `a8c73d2` en `lote-12` (pusheado).
- Hormigueros de Codex (`anthills_v01`) y el cambio de `ASSET_MANIFEST.md`: commit aparte `868a418`, tal cual.
- Rama `lote-13` creada desde ahí.

## Etapa 1 — Todo es jardín + polen

### 1.1 Jardín puro, también al atardecer
- Los pinos y las piñas salen del Nivel 01. No se borraron: viven en `assets/models/levels/level_03_forest/` y en `FOREST_PIECES` de `bee_level_01_asset_dressing.gd` (apagado con `BUILD_FOREST_PIECES = false`; el flujo antiguo `roster_only = false` los conserva).
- Las vainas negras con antenas violetas eran los relés de señal (`BeeLevel01AlienEscalation`); junto con la flor contaminada y la maceta alien ya no se construyen con el elenco del Nivel 1 (constante `GARDEN_ONLY`). El código sigue ahí para el flujo antiguo.
- Se mantiene el ciclo de luz día → atardecer (sol, luna y estrellas del cielo no cambian).

### 1.2 Fondo lleno de piezas de jardín
- Valla a lo largo de todo el nivel (módulo cada 7,2 m, `FENCE_*`), 5 casas lejanas (`HOUSE_X`), y en la segunda mitad (donde estaban los pinos): arbustos, campanillas, arbolitos (saplings), latas, caramelos, mangueras y 4 regaderas.
- No había piezas nuevas de Rubén en `art_source/blender/levels/level_01_garden/environment/` más allá de los hormigueros (ya commiteados).
- **Piezas de fondo que faltan** (pedido para Codex/Rubén): banco o mesa de jardín, carretilla, bebedero de pájaros, tendedero, gnomo de jardín, macetas en hilera (hoy hay macetas sueltas del decorado doméstico), porche o fachada de casa más cercana (hoy la casa es una silueta lejana repetida), árboles frutales más altos que los saplings, y una segunda variante de valla (con portón) y de casa.

### 1.3 Hormigueros
- `scripts/levels/bee_level_01_anthills.gd` coloca 8 hormigueros (cráter y túnel lateral, escala 1,8) cerca de cada grupo de hormigas.
- Los eventos de hormigas llevan `"anthill": true` (5 eventos de ruta y 4 oleadas de zona): la hormiga nace en el ancla de entrada del montículo, crece 0,7 s con una nube de tierra (sin ser blanco ni amenaza), salta al suelo en 0,4 s y recién entonces actúa. Sin montículo en pantalla entra por el borde derecho como antes. Constantes: `EMERGE_SECONDS`, `HOP_SECONDS`, `HILL_SCALE`, `PLACEMENTS`.

### 1.4 Polen, no miel
- Todo lo visible dice POLEN: el HUD muestra `POLEN [####------] 4/10 · +15% VIDA`; los tarros de miel pasaron a **racimos de polen** (`scenes/items/toon/pollen_cluster.tscn`, 5 de polen, balizas verdes más grandes).
- El polen **no cura al instante** (`POLLEN_INSTANT_HEAL = 0`): llena la barra; cada `POLLEN_PER_HEAL = 10` se recupera `POLLEN_HEAL_FRACTION = 0.15` de la vida máxima, con destello dorado, texto flotante "+15% VIDA", ráfaga de polen y sonido.
- Más polen: hongos y **campanillas destructibles** (15 nuevas) sueltan 2 de polen (`BeeGardenMushroom.POLLEN_DROPS`), 8 racimos sueltos en el recorrido (`POLLEN_CLUSTERS` del escenario), los racimos reemplazan a los tarros de rocas/suministros, y cada animal liberado sigue dando 1.
- **FRENESÍ** (disparo doble 6 s) ya no depende del polen: se activa al llegar a combo x`FRENZY_COMBO = 8`; HUD `FRENESÍ: COMBO x8 (n/8)` / `FRENESÍ · DISPARO DOBLE n s`. (Internamente se conservan los nombres `honey_*` de `BeePlayer`.)
- Tests adaptados: `validate_bee_lote11_juice_v01` (barra, cura 15 %, frenesí, racimos con imán), `validate_bee_terminal_states_v01`, `validate_bee_items_shots_v04`, `validate_bee_checkpoint_qol_v01` (interruptor `pollen_heal_enabled` para fixtures), `validate_bee_garden_identity_v04` y `validate_bee_level01_roster_v01` (hormigueros y campanillas).
