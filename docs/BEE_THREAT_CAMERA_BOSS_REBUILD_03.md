# BEE ALIEN — THREAT, CAMERA & BOSS REBUILD 03

Rama: `level01-threat-camera-boss-03` (hija de `level01-arcade-rebuild-02`). Nace del playtest humano posterior al
Rebuild 02: *todavía no es suficientemente desafiante ni divertido*. Principio: el problema no era "faltan enemigos",
sino que **muchos enemigos no llegaban a ser un problema** (ver → disparar → destruir, sin esquivar). Sin merge, sin push.

Herramientas de medición (dev, no cambian el juego):
- `dev/threat_camera_boss_v03_review/threat_analysis.gd`: por familia (vida visible, TTK, ataques iniciados, muertos antes
  del 1.º / 2.º ataque), **sólo combate activo** (balas visibles, ocupación de ataque, amenazas) y duración del boss con
  la S+ tomada. `ghost=1`: las balas atraviesan a Bee (modela a un jugador que esquiva; sin esto el bot "absorbe" balas).
- `camera_compare.gd` (D vs E), `review_capture.gd` (capturas), `bench_scenes.gd -- preset=D|E` (rendimiento).

## A. Cámara E — "Arcade wide"

| | Cámara D (antes) | Cámara E (ahora) |
|---|---|---|
| distancia / altura / pitch / FOV | 8.5 / 2.0 / +5° / 40° | **10.0 / 2.45 / +5° / 40°** |
| ancho visible en el plano de vuelo | 10.7–11.4 m | **12.6–13.4 m (+18 %)** |
| alto visible | 6.2 m (−0.28..5.96) | **7.3 m (−0.23..7.11) (+18 %)** |
| área | — | **+39 %** |
| techo de vuelo de Bee / techo de entidades | 5.56 / 5.46 | **6.71 / 6.61** |

- **Ancla de Bee**: arranca al **32 %** del ancho desde la izquierda; su ventana de vuelo termina al **66 %**, así que el
  tercio derecho queda siempre libre para leer lo que entra. A la izquierda conserva ~1.6 m de margen para retroceder.
- Bee se sigue leyendo bien (≈15 % más chica en pantalla); escala del jardín intacta (los props se colocan según la cámara).
- Todo lo que depende de la cámara ya derivaba del encuadre: borde de spawn, fairness de disparo, auto-aim, limpieza de
  disparos, entradas en profundidad, rana. Preset D sigue disponible (`BeeLevel01Framing.use_preset(&"D")`).
- Comparativas: `cam_D_*.png` / `cam_E_*.png` (combate, Walker, 3 amenazas, Organic, boss).

## B. Roles de amenaza

DPS Base razonable ≈ 27–33 (3 toques/s × 10 HP, auto-aim). TTK objetivo → HP:

| Rol | TTK objetivo | Familia | HP antes → ahora |
|---|---|---|---|
| POPCORN | 0.1–0.8 s | Swarm | 10 |
| LIGHT | 1–2 s | Wasp / EyeDrone / Speeder | 36→**44** / 28→**40** / 30 |
| MEDIUM | 2.5–4.5 s | Probe / Turret / OrganicAlien | 38→**80** / 46→**70** / 47→**100** |
| HEAVY | 4–7 s | Walker | 72→**120** |
| SHOWCASE | 5–8 s | Walker con "hold" | →**150** |

- **Wasp**: implante alien visible en el tórax (de ahí vienen sting y overload, no del insecto).
  - *Implant sting* (desde X=40 en la 2.ª Wasp de un grupo; desde X=150 en todas): el implante carga en cian 0.45 s y
    dispara 2 dardos ligeros dirigidos.
  - *OVERLOAD* (desde X=150 en la 1.ª Wasp de un grupo; desde X=240 en todas): a ≤35 % HP el implante se pone
    rojo/naranja con halo, chispas y un quejido creciente; 0.85 s de aviso, la línea se fija 0.3 s antes (línea naranja
    visible) apuntando a donde va Bee; embestida recta (sin homing) que pasa el punto y explota al final de la línea
    (radio 1.5 m, 18 de daño sólo dentro del radio). Si la destruís durante el aviso, explota inofensiva.
- **OrganicAlien**: segundo lenguaje: HOVER → RANGED (el núcleo brilla verde 0.6 s, abanico de 3 bio-orbes verdes,
  distintos del magenta tech) → REPOSITION → STALK → LUNGE → RECOVERY → RANGED… nunca ambos a la vez.
- **Walker**: además de su ráfaga, cada 2.º ataque es un **BARRIDO** de 5 disparos de arriba hacia abajo cruzando la
  línea de Bee (carga violeta 0.85 s, distinta de la cian). Entra completo antes de apuntar (Rebuild 02).
- **Probe**: se posiciona más rápido (3.0 m/s, alcance 8.5 m) → telegraph ~1 s después de estar entero en pantalla.
- **Speeder**: rol FAST CROSSING THREAT con línea de carril naranja durante el aviso; 5 en el nivel (X 76, 152, 289).
- **No unfair stacks** (`BeeAttackTokens`): un solo patrón pesado a la vez (overload, barrido, abanico del ojo,
  embestida); el resto usa su ataque básico o espera un instante.
- Tope de amenazas 2 (X<96) / 3 (X<240) / 4 (último tercio). Cadencias de reposo algo más cortas (avisos, daño y
  velocidad de bala sin cambios).

## C. Presión de combate (sólo segmentos activos)

Bots: eficiente 0.30 s / medio 0.40 s / moderado 0.50 s entre disparos, puntería perfecta, con `ghost=1`.

| Métrica | ANTES (cámara E, roles viejos) 0.30 / 0.50 | AHORA 0.30 / 0.40 / 0.50 |
|---|---|---|
| balas visibles en combate (prom.) | 1.80 / 2.18 * | **2.88 / 3.27 / 3.41** |
| pico | 10 / 10 | 14 / 10 / 12 |
| ocupación de ataque | 44 % / 48 % | **55 % / 57 % / 58 %** |
| Probe: ataques / muertos antes del 2.º | 1.1 / 15 de 17 — 1.8 / 7 | **2.6 / 2 — 3.2 / 1 — 3.6 / 0** |
| EyeDrone: ataques | 1.0 / 1.1 | 1.1 / 1.3 / 1.4 (LIGHT) |
| Wasp: ataques / nunca atacó | 0.1 / 10 de 11 — 0.5 / 5 | **1.3 / 4 — 1.3 / 4 — 1.9 / 0** |
| OrganicAlien: ataques | 0.3 / 1.3 | **2.3 / 3.7 / 4.3** |
| Walker: ataques / TTK en combate | 1.2 / 2.5 s — 2.8 / 8.4 s | **2.6 / 7.7 s — 3.4 / 9.5 s — 3.6 / 9.9 s** |
| Turret: ataques | 1.5 / 2.7 | **2.3 / 4.0 / 4.3** |

\* el ANTES se midió sin `ghost` (el bot absorbía balas); el AHORA con `ghost=1` equivale a un jugador que esquiva.
Los MEDIUM/HEAVY ya no mueren sistemáticamente sin cumplir su función. El TTK "en combate" del Walker supera los 4–7 s
porque el jugador reparte fuego entre varias amenazas (solo: 120 HP ≈ 3.6–4.4 s).

## D. Boss Challenge V2

- **Movimiento**: figura en ocho sobre la parte derecha (amplitud X 0.7 / 1.1 / 1.4 m por fase) + acercarse/alejarse
  desde la fase 2; altura con más recorrido (1.0 / 1.3 / 1.5 m) aprovechando el alto de la cámara E. Siempre dentro de la
  franja [cámara + 1.4, borde − 2.2]: nunca persigue a Bee, la izquierda es siempre ruta de escape. Medido: deriva
  0.94 m en fase 1, 2.61 m en fase 2.
- **Secuaces**: fase 2 → 2 EyeDrones que salen del platillo (sin colisión ni disparo hasta llegar); se repone cuando no
  queda ninguno (cada ≥ 11 s). Fase 3 → 1 Probe sólo si la pantalla está limpia (≤ 4 balas). Máximo 2 vivos. Mientras
  invoca (~1 s) el OVNI **no ataca** (el núcleo pulsa). Los secuaces mueren con la nave.
- **HP**: sin cambios (1300). Duración con S+: **62 s** (eficiente) / **80 s** (medio) / **103 s** (moderado);
  antes 48 s / 78 s. La pelea es más larga por decisiones (boss vs secuaz), no por esponja.
- **Muerte**: misma secuencia + micro-shake en chispas y explosión final y una onda pesada extra.

## E. Presentación

- **"Papeles dorados"** = las hojas del Rebuild 02 (quads ocres que se veían como papel). Ahora son **hojas reales**:
  óvalo en punta plegado por la nervadura, con pecíolo, colores mate (verde apagado, ocre, marrón), sin especular,
  caída irregular (dirección, deriva lateral y giro variables). 6 hojas. Ver `leaf_zoom.png` / `13_dry_leaves.png`.
- **La rana**: ahora salta **detrás** de la botella lejana (z −10.5; se verifica contra la caja real de la botella),
  entra desde fuera del borde visible a su profundidad (antes "aparecía" en pantalla) y cada salto tiene anticipación
  (agacharse → salto con estiramiento → aterrizaje con compresión).
- Polen, mosquitos y mariposas se mantienen.

## Rendimiento (1152×648, misma máquina, `bench_scenes.gd`)

| Escenario | D sostenido / CPU render | E sostenido / CPU render | primer pico E |
|---|---|---|---|
| jardín | 10.00 ms / 1.31 | 10.00 ms / 1.81 | 37 ms |
| 4 amenazas (Walker, Eye, Wasp overload, Probe) | 10.08 / 1.92 | 10.08 / 2.04 | 117 ms (1.ª aparición) |
| rana | 10.05 / 1.54 | 10.05 / 1.81 | 69 ms |
| boss fase 2 + secuaces | 10.00 / 2.09 | 10.00 / 2.36 | 11 ms |

~100 FPS sostenido (vsync) en todo; la cámara E cuesta +0.1–0.5 ms de CPU de render. Los picos son compilación de
shaders la primera vez que aparece cada combinación.

## Tests
- Nuevo `tests/levels/validate_bee_threat_camera_boss_v03.gd` (camera, wasp, organic, walker, roles, boss,
  presentation; `-- only=...`).
- Actualizados: framing (contrato E + ganancia medida contra D), fairness, vertical slice (tronco hueco en el nuevo
  encuadre, HP de showcase), patterns v02 / pressure-world / challenge (HP por rol, 44 eventos, tope 96/240),
  rebuild v02 (umbrales, rana más larga).

## Playtest manual (lo que los tests no miden)
Ver el informe final de la sesión.
