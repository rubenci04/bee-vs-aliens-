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

## Etapa 2 — Que todo ataque y que no haya huecos

### 2.1 Todo enemigo ataca enseguida
- Regla medida (`validate_bee_lote13_combat_v01`): cada familia, sola en pantalla, muestra su **primer aviso a ≤ ~1 s de entrar** (`FIRST_ATTACK_MAX_DELAY` = 1,0 s + 0,15 de tolerancia) y ningún aviso dura menos de 0,4 s. Se midió: mosca común 0,43 s · mosca verde 0,38 · nube 0,38 · avispa 0,55 · mariquita 0,27 · hormiga 0,15 · caracol 0,27 · gusano A 0,27 · gusano B 0,60 · escarabajo 0,33 · araña 0,25 · hongo cañón 0,27 (el robot: ≈0,9 s; la tarántula conserva su entrada de jefe de 3 s).
- Cómo: `first_idle_time` (0,25 s, `FIRST_ATTACK_REST`) y "llegó" al entrar en pantalla (`ARRIVAL_INSET`) en `AssetFauna`; la araña baja y avisa en ~0,75 s (`ROSTER_TUNING`); el robot camina menos (`ENTRY_INSET`, `FIRST_REST`).
- **Mosca común:** embiste y **escupe** (pellets, cada segundo ataque). **Mosca verde:** **ráfaga de 3 gotas de ácido**. **Nube de moscas:** **persigue a Bee en bloque** (`chase`).
- **Avisos que se fijan:** los ataques apuntados muestran una línea fina que sigue a Bee y se **fija (naranja) 0,3 s antes del primer tiro**; toda la ráfaga/abanico/arco va por la línea fijada, así que salir de ella tras el aviso esquiva limpio.

### 2.2 Variedad de disparos y colores (`BeeShotStyles`)
Núcleo siempre cian; borde, forma y estela propios; todos contrastan con el dorado de Bee. Probado: núcleo cian, borde no cian, distancia al dorado, parejas distintas.

| Familia | Disparo | Patrón |
|---|---|---|
| Avispa | aguijón violeta alargado | abanico de 3 + picada |
| Mosca verde | gota verde lima de ácido | ráfaga de 3 por la línea fijada |
| Mosca común | pellet negro (núcleo cian) | embestida / 2 pellets |
| Araña | telaraña blanca (nudo de hilos, sin anillo: la mira es un anillo) | abanico de 3 + columna vertical |
| Hormiga | piedrita naranja oscura que gira | **en arco** (cae donde estaba Bee) + embestida |
| Caracol | burbuja de baba translúcida que ondula | **en arco** lento |
| Hongo cañón | espora magenta con púas | abanico de 3 |
| Mariquita | semilla roja con punto negro | abanico de 3 + barrido |
| Escarabajo | piedra gris-marrón | **en arco** + embestida |
| Gusano B | glóbulo de barro (se usa en la etapa 3) | — |

Los arcos son proyectiles con gravedad (`AlienEnemyProjectile.gravity`, `BeeEnemyPatterns.spawn_lob`): aterrizan en el punto fijado dentro de 0,1 m (test) y desaparecen al tocar el suelo.

### 2.3 Densidad, sin valle de respiro
- **Se eliminó el valle** del checkpoint 1: esa franja (X 180–218) es la **entrada de los gusanos** con mucha acción. Los suministros (racimos y bomba) quedan, en medio de la acción.
- Tabla nueva **generada** por `dev/lote13/_gen_events.gd` (semilla fija; `regen.sh` la vuelve a pegar en el controlador): un golpe cada ~2,1 m con 1–3 bichos mezclando voladores y terrestres, tres zonas de **6 oleadas** (28–36 s), 114 eventos y ~240 unidades (antes 48 y 133). Zonas más ágiles (`ROSTER_ARENA_*`: oleada nueva cada 4 s). Sin tortuga (ver Etapa 3).
- Ajustes para que la densidad no sea castigo injusto: daño de ruta en **chip** (`ROUTE_DAMAGE_SCALE` 0,15 → 1–2 de vida por impacto), tiros más lentos (esquivables y más tiempo en pantalla), HP de los bichos de relleno ×1,15–1,4 (`ROSTER_HP_SCALE`) para que permanezcan en pantalla, cooldowns propios (mariquita 3,8 s), daños de mosca común/verde/nube bajados, regadera 8 → 5.
- **Bot de ritmo** (`validate_bee_pacing_v01`), más "jugador razonable": esquiva también arcos (predicción con gravedad), **lee los avisos** (líneas fijadas y anillos de lobs) y usa la **pirueta** cuando un tiro o un cuerpo va a tocarla (la pirueta es del Lote 11). Mide la densidad fuera de los jefes.

| Métrica (bot, Normal, Base, sin jefes) | Meta | Resultado |
|---|---|---|
| ≥ 3 enemigos visibles | ≥ 80 % del tiempo | **83 %** |
| 1 volador + 1 terrestre a la vez | ≥ 70 % | **82 %** |
| Balas enemigas en pantalla | ≥ 70 % | **79 %** |
| Mayor tiempo sin amenaza | ≤ 4 s | **1,2 s** |
| Vida perdida antes del robot | 50–75 | **61** |
| Duración hasta la tarántula | 5,5–7 min | **366 s (6,1 min)** |
| Máx. simultáneos ruta / zonas | 7 / 10 | 6 / 8 |
| Retraso máx. de un evento respecto de su X | ≤ 18 m | 15,7 m (media 4,2 m) |

El robot entra a los 326 s (5,4 min). El retraso de eventos viene de los topes de simultáneos (se vuelve a medir y se acota en el test).

### Tests de la etapa
- Nuevo: `validate_bee_lote13_combat_v01` (tiempos del primer aviso, avisos ≥ 0,4 s, estilos, arcos y disparo propio de cada familia en vivo).
- Actualizados: `validate_bee_pacing_v01` (densidad, quietud ≤ 4 s, daño 50–75, tarántula 5,5–7 min, retraso, bot lee avisos y rueda), `validate_bee_level01_roster_v01` (sin valle, sin tortuga, 6 oleadas), `validate_bee_level_01_vertical_slice` (conteos de la tabla densa).

Verificación de la etapa: reimportación y suite completa **96 validaciones** (`dev/l13e2_*`): 94 en verde y 2 con expectativas viejas (caracol "lento" ahora es un arco de lanzamiento ≤ 7 m/s; regadera 4–12 de daño) que se corrigieron y repitieron en verde sin tocar código. Sin `SCRIPT ERROR` ajenos a esas dos.
