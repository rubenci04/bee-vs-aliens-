# BEE ALIEN — ARCADE CONTENT & SPECTACLE REBUILD 02

Rama: `level01-arcade-rebuild-02` (hija de `level01-transformation-01`). Nace del playtest humano de la Transformation
Pass 01: *"el nivel todavía se siente vacío, poco desafiante y demasiado estático"*. Sin merge, sin push.

## Diagnóstico (antes de tocar nada)

Nuevo analizador estricto `dev/arcade_rebuild_v02_review/pressure_analysis.gd` ("ACTIVE PRESSURE OR MEANINGFUL EVENT":
amenaza en pantalla, proyectil en pantalla, telegraph/hazard, cápsula de power-up, dispositivo disparable o set piece en
movimiento; **no** cuentan piedras estáticas, cajas, landmarks ni polen). Hallazgos sobre la versión del playtest:

1. **Los enemigos morían antes de existir.** El disparo de Bee recorre 19.6 m (14 m/s × 1.4 s) y el auto-aim alcanza
   12 m: con Bee a la izquierda, el jugador mataba unidades ~3 m **fuera** del borde derecho.
2. **Casi todos los tiradores atacaban una sola vez** (26/26 con el bot eficiente).
3. **Proyectiles visibles en promedio 0.5–0.6** (pico 6–7): muy lejos del "fuego frecuente".
4. **Unidades medianas que se estacionaban fuera de pantalla** (la Probe disparaba desde 9 m y la regla de fairness
   suprimía la ráfaga entera: 2.4 disparos perdidos por Probe).
5. **Concurrencia**: tope 2 hasta X=150, unidades de cada evento llegando 3–5 s separadas → "enemigo → kill → nada".

## Qué cambió

(ver secciones por fase más abajo; números finales en "Métricas")

### Presión sostenida (fase 2)
- **EVENTS V3**: 42 eventos, 92 unidades (antes 31 / 71). Oleadas compactas (las unidades de un evento llegan juntas,
  0.2–1.6 s), cinco actos intactos, mismos gates duros (254, 296, 340), humano en 140, checkpoint en 190.
- **Popcorn** (`PopcornDrone`, `scenes/levels/popcorn_drone.tscn`): mini-drones alien procedurales (paleta alien, Style C),
  10 HP (= un disparo Base), trayectorias `sine | arc_top | arc_bottom | dive` (entradas por arriba, abajo y en picada),
  algunos "shooters" disparan **una** bala lenta tras un destello del ojo. Fuera del tope de amenazas (presupuesto propio: 6).
- **Tope de amenazas 2 → 3 (X≥24) → 4 (X≥96)** (`threat_cap()`).
- **Techo de disparos vivos 10** (sólo unidades del director de Level 01; el OVNI y los POCs no cambian): con la volea
  más grande (abanico de 5) el pico nunca pasa de 14.
- **Combate acotado a la pantalla** (Level 01): el disparo de Bee desaparece al salir de pantalla y el auto-aim no fija
  enemigos que todavía no entraron.
- **`stay_on_screen`** (Level 01): Probe / EyeDrone / Walker nunca apuntan desde fuera de pantalla; vuelven a entrar primero.
- **Cadencia** (windups, daño y velocidad de bala sin tocar): ráfagas Probe/Eye/Walker 3 → 4; descansos más cortos
  (Probe 0.8→0.55 / 2.0→1.6, Eye 2.0→1.5, Turret 1.55→1.3, Walker 0.9→0.7); HP medianos +15–20 %
  (Probe 38, Eye 28, Turret 46, Walker 72); OrganicAlien sigue en 47.
- **Satisfacción**: capa de destello en toda muerte, "pop" corto para el popcorn, onda doble para muertes pesadas y
  **micro-shake** (≤ 9 cm, 0.2 s) sólo para Bomb, muertes pesadas y aterrizajes de la rana.

### Entradas cinematográficas 2.5D (fase 3)
`CinematicDepthEntry` (reutilizable): la unidad aparece pequeña en el fondo (z = −22), crece y entra al plano en 2 s;
las formaciones arrancan juntas y **se abren** al llegar. Mientras está en profundidad: sin IA (no dispara), todas sus
Area3D apagadas (sin colisión ni daño en ningún sentido) y fuera del auto-aim. Se activa al llegar a z = 0.
Usada en 5 entradas: Probe X=56, **V de 3 EyeDrones X=68**, OrganicAlien X=80 (presentación), **rombo Probe + 2 Eye X=228**,
**V Eye + 2 Probe X=324**.

### Showcase (fase 4)
- **Walker ×5**: presentación limpia (X=105, solo), set piece A (X=180, Walker abajo + enjambre en picada que obliga a
  moverse + Wasp), escolta (X=238), gates tardíos (296, 340). Mientras vive un Walker "hold" el scroll baja a 1 m/s
  para que acompañe a Bee en vez de quedar atrás. Con `stay_on_screen` camina 1.8 m hacia adentro del borde antes de
  detenerse a apuntar (el cuerpo entero se lee en pantalla) y nunca se queda quieto fuera de ella.
- **OrganicAlien ×3**: presentación desde profundidad (X=80, solo), set piece B "fuego cruzado" (X=214, con Probe y Eye
  que dan fuego dirigido), gate tardío (X=254). Más presencia por movimiento (alterna altura de acecho tras cada mordida).
- **"La rana"** (evento grande de escala, X=188): rana de jardín (Quaternius, CC0) 5× el largo de Bee que salta por el
  fondo, se detiene, lanza la lengua al cielo y se va; cada aterrizaje = polvo + golpe + micro-shake. Sin colisión.

### Power moment pre-boss (fase 5)
Cápsula **S+** (`Powerups/PrebossPower`, X=334, ~12–18 s antes del OVNI): más grande, con halo, pulso, aviso
"¡PREPARATE! · SPREAD+" y carga sonora. Base → Spread sobrecargado (48 ráfagas); con Spread → recarga + extiende
(nunca baja la munición; tope 64). Bomb/polen sin cambios.

### Mundo vivo (fase 6)
Polen en el aire, hojas que caen (algunas cruzan **delante** del plano de vuelo), nubes de mosquitos sobre flores y
mariposas en el fondo. Sin colisión, sin sombras, nada procesa lejos de la cámara.

## Métricas

Analizador estricto (`pressure_analysis.gd`, bot que sigue la altura del enemigo más cercano y dispara cada `fire` s,
nunca esquiva). BEFORE medido sobre `ff72a9a` exportado con `git archive` (sin tocar el repo) con el **mismo** analizador.
Bots: eficiente (0.30 s), rápido (0.45 s), razonable (0.60 s).

| Métrica | BEFORE 0.30 / 0.45 / 0.60 | AFTER 0.30 / 0.45 / 0.60 |
|---|---|---|
| Unidades / eventos | 71 / 31 | **92 / 42** (63 amenazas + 29 popcorn) |
| Walker / OrganicAlien | 2 / 1 | **5 / 3** |
| Segundos activos (presión o evento real) | 83 / 85 / 92 % | **89 / 93 / 95 %** |
| Segundos con proyectil hostil en pantalla | 24 / 30 / 39 % | **40 / 54 / 54 %** |
| Proyectiles visibles promedio | 0.31 / 0.48 / 0.57 | **0.53 / 0.94 / 1.23** |
| Pico de proyectiles | 6 / 6 / 7 | **9 / 9 / 9** (techo ≤ 14) |
| Huecos ≥ 3 s sin nada (fuera de respiros) | 4 / 4 / 2 (13 / 12 / 6 s) | **1 / 0 / 0** (3 / 0 / 0 s) |
| Tiradores con ≥ 2 ciclos de ataque | 1 / 3 / 8 | **1 / 15 / 26** |
| Probe: vida / balas | 1.8–3.8 s / 1.8–3.6 | 2.5–8.9 s / 2.8–7.0 |
| EyeDrone que nunca dispararon | 9 / 9 / 4 de 14 | 12 / 2 / 0 de 17 |
| Walker: balas / suprimidas fuera de pantalla | 0–3 / **3.0** | 2.8–7.6 / 0–1.0 |
| Llegada al OVNI | 202 / 208 / 217 s | 202 / 214 / 241 s |

Lectura honesta:
- El "fuego normal 4–7 balas visibles" del brief **no** se alcanza en promedio global (el promedio incluye respiros,
  humano y pausas): 0.9–1.2 con jugador rápido/razonable, 2.0–2.2 en los bloques densos, picos 9–11. Subirlo más exige
  más tiradores simultáneos o balas más lentas; lo dejo al playtest antes de seguir empujando (riesgo de bullet hell).
- Un jugador muy eficiente (0.30 s, puntería perfecta) sigue matando casi todo en el primer ciclo: es la recompensa
  pedida ("un jugador competente puede impedirlo").
- El nivel dura más con el jugador razonable (+24 s) por los Walkers "hold" y las oleadas más largas.

### Rendimiento (con render, 1152×648, misma máquina; `bench_scenes.gd`)
| Escenario | Sostenido | Primer pico (compilación) | Peor frame sostenido | Render CPU |
|---|---|---|---|---|
| jardín (con mundo vivo) | 10.00 ms | 38.6 ms | 10.3 ms | 1.59 ms (antes 1.02) |
| formación desde profundidad | 10.07 ms | 11.6 ms | 32.0 ms | 1.18 ms |
| Walker + enjambre + Wasp | 10.03 ms | **75.0 ms** (primer popcorn) | 33.1 ms | 1.38 ms |
| la rana | 10.05 ms | 34.7 ms | 36.3 ms | 1.47 ms |
| tramo final denso (4 amenazas + 3 popcorn) | 10.03 ms | 10.3 ms | 30.4 ms | 1.64 ms |
| último silencio / OVNI fase 3 | 10.01 / 10.00 ms | 11.4 ms | 14.8 / 12.0 ms | 1.38 ms |

Sostenido ≈ 100 FPS (vsync) en todos los escenarios, igual que el pase anterior (10.00–10.08 ms). El pico de 75 ms es
la primera aparición del popcorn (compilación de shaders en GL Compatibility), una sola vez por sesión.

## Assets
Ver `docs/BEE_LOCAL_ASSET_OPPORTUNITY_AUDIT_01.md`. Único asset nuevo: Quaternius Frog (CC0, hash registrado).

## Godot AI (`addons/godot_ai/`)
Inspeccionado: es un puente MCP para un **editor Godot abierto** (requiere habilitar el plugin en Project Settings y
`uv` para el servidor Python). Este pase trabaja headless/por scripts, así que **no se usó**; no se habilitó (no se tocó
`project.godot`), no es dependencia runtime y no se commiteó.

## Fuera de alcance / pendiente
- Humano gigante: sin candidato local mejor (ver auditoría) → sin cambios.
- Segunda fauna controlada: DEFER (no hay polilla/pájaro con licencia local).

## Tests
- Nuevo `tests/levels/validate_bee_arcade_rebuild_v02.gd`: presupuesto y estructura (Walker ×5 con presentación limpia y
  encuentros tardíos, Organic ×3, popcorn con tiradores, entradas en profundidad, caps), popcorn (un disparo, tirador
  dispara una vez, escape liberado, fuera del cap), seguridad de la entrada en profundidad (sin IA, sin disparo, sin
  colisión ni daño, sin auto-aim; entrega a enemigo normal al llegar), power moment (Base→Spread, recarga+extensión,
  nunca downgrade), set pieces (hold del Walker, la rana sin colisión), checkpoint (no repite set pieces previos; la S+
  sigue adelante) y corrida completa (caps, techo, ninguna bala desde profundidad, momentos en orden, OVNI 1300 HP,
  Level Complete). `-- only=static|popcorn|depth|power|setpieces|checkpoint|run`.
- Actualizados al diseño nuevo (los valores del pase anterior estaban fijados en los tests): vertical slice, director,
  challenge balance, patterns v02, pressure/world, transformation, fairness (+ chequeo explícito del techo de disparos y
  del combate acotado a pantalla) y checkpoint QoL (5 cápsulas).

## Capturas de review
`dev/arcade_rebuild_v02_review/` (PNG ignorados por git; regenerar con `review_capture.gd -- shots=all`):
01 opening · 02 early combat · 03 depth formation approaching · 04 depth formation gameplay · 05 Walker showcase ·
06 Organic presentation · 07 Organic combined · 08 human · 09 dragonfly · 10 dense mid encounter · 11 second Walker
set piece · 12 living garden · 13 large scale event (rana) · 14 late-game pressure · 15 guaranteed Spread pickup ·
16 final silence · 17 UFO reveal. Hojas de assets en `asset_audit/`.

## Playtest manual (lo que los tests no miden)
1. ¿Sigue sintiéndose vacío? Prestar atención a X≈50–90, 120–140, 160–195, 220–245 y 255–300.
2. ¿Es más desafiante sin ser injusto? ¿Se esquivan las ráfagas de 4 y los abanicos con 4 amenazas en pantalla?
3. Entradas desde profundidad (X≈56, 68, 80, 228, 324): ¿se leen como "vienen desde el fondo"? ¿se entiende que no se
   les puede disparar hasta que llegan?
4. Walker (X≈105 y 180): ¿se queda en pantalla el tiempo suficiente? ¿el scroll lento se siente bien o pesado?
5. OrganicAlien (X≈80, 214, 254): ¿tiene más presencia?
6. Popcorn: ¿satisface reventarlos? ¿los disparos únicos se distinguen bien?
7. La rana (X≈188): ¿transmite "Bee es diminuta"? ¿distrae del combate?
8. S+ antes del OVNI (X≈334): ¿se ve especial, se agarra sin problema y "prepara" para el boss?
9. Mundo vivo: ¿se nota el polen/hojas/mariposas sin ensuciar la lectura?
10. Disparos de Bee que desaparecen en el borde derecho: ¿se percibe como natural?
