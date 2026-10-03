# BEE UFO BOSS 01 — FIRST CONTACT

Rama `ufo-boss-01`. Primer jefe real y clímax de Level 01. Test: `tests/levels/validate_bee_ufo_boss_01.gd`. Capturas: `dev/ufo_boss_01_review/`.

## Propósito narrativo
Hasta el final del nivel Bee vio tecnología, drones, criaturas y torretas, pero ninguna nave. El OVNI llega desde el fondo con su brillo cian, entra al plano de juego y convierte el cierre en "esto era una invasión". El HUD muestra `¡PRIMER CONTACTO!` durante la llegada y luego la barra `ALIEN SCOUT`.

## Modelo y estilo
- Construido en código (`scripts/levels/ufo_boss_01.gd`, `_build_visual`): sin assets externos de OVNI.
- Platillo compacto: núcleo alien inferior (violeta), casco ancho mid-poly con sombreado suave (`GardenProps.loft(..., smooth)`), anillo exterior (toro), cúpula cian, 4 emisores cian bajo el ala y 4 aletas pequeñas.
- 6 colores, Style C vía `BeeToonStyle.apply` (toon 3 bandas, rim, contorno). El cian emisivo pasa el umbral de glow. Silueta distinta de Probe (cápsula), EyeDrone (esfera) y Speeder (nave alargada).

## Escala
`VisualRoot` a 0,8: ~2,7 m de ancho × ~1,3 m de alto en pantalla. Un Probe ocupa ~1,1 × 0,7 m, así que el área visible es ~3,3× la de un enemigo aéreo, por debajo de una nave nodriza. En la arena se ubica a +3,3 m del centro de cámara (derecha) y deja la mitad izquierda para Bee.
- Hurtbox: caja 2,5 × 0,85 × 1,4 (un poco menor que el casco visible).
- Contacto: caja 2,0 × 0,55 × 1,0, 12 de daño, se rearma cada 1,5 s.

## HP y cálculo de DPS
Medido con `dev/ufo_boss_01_review/measure_dps.gd`: jefe real moviéndose y atacando, Bee a ~6 m siguiendo su altura con su velocidad real y pulsando X a 3,3 Hz.

| Fuente | Medido |
|---|---|
| Base (10 por disparo) | 33 dps (auto-aim: 99/99 aciertos contra un blanco grande) |
| Spread (3 × 6) | 6 por ráfaga a ~6 m: los laterales de ±14° pasan por arriba y abajo del casco; de cerca rinde más |
| Bomb | 32 si Bee está a ≤ ~3 m (radio y daño sin cambios) |

Jugador razonable: dispara ~70 % del tiempo (el resto esquiva o se reposiciona) con ~90 % de acierto → ≈ 21 dps; más ~1,5 bombas (≈ 48). **HP = 1300** → ≈ 60 s para ese jugador; ≈ 39 s como mínimo pulsando sin parar. Las dos transiciones suman ~1,8 s.

## Estados (máquina simple, sin framework)
`APPROACH → PHASE_1 → PHASE_2 → PHASE_3 → DEATH` (+ `TRANSITION` breve entre fases, `DONE` al terminar).
- **APPROACH (3,2 s):** nace a z = −38 m, arriba a la derecha, y llega al plano con ease-out, girando y con glow alto. Invulnerable (`damage_blocked`, hurtbox no monitorable, fuera del grupo de auto-aim), no dispara. Suena el sting y entra el loop de hover.
- **PHASE_1 (100–66 %):** bob vertical lento (±0,9 m, período 6 s). Ráfagas aimed de 3 disparos cada 1,45 s.
- **PHASE_2 (66–33 %):** ±1,0 m, 5 s. Alterna aimed y abanico.
- **PHASE_3 (<33 %):** ±1,1 m, 3,6 s (más rápido). Alterna aimed y abanico+aimed combinados; cooldown 1,0 s.
- **TRANSITION (0,9 s):** sin ataque, pulso del núcleo y del glow, sonido grave.
- Las amplitudes mantienen todo el platillo dentro del encuadre de la cámara D.

## Ataques y telegraphs
- **Aimed:** telegraph de 0,5–0,6 s (los emisores cian crecen y brillan) + `ufo_charge` agudo. Luego 3 disparos a 0,14 s, desde el emisor más cercano a Bee. Cada uno apunta a donde está Bee **en ese instante** y sigue en línea recta (sin homing), a 6,2 m/s.
- **Abanico:** telegraph de 0,6–0,7 s (el núcleo violeta crece) + `ufo_charge` grave. 5 disparos a 17° entre sí (68° en total) centrados en Bee, a 4,8 m/s. A ~6 m los huecos miden ~1,7 m, contra un contacto efectivo de ~0,68 m (proyectil 0,28 + Bee 0,40).
- Probe invocado: **no implementado** (añadía spam y riesgos de fairness sin aportar a V01).

## Proyectiles
- `scenes/levels/ufo_boss_projectile.tscn` reutiliza `AlienEnemyProjectile`. Visual violeta con núcleo blanco y estela corta orientada, que contrasta con el cian de Bee y el jardín.
- Núcleo visible 0,20; collider **0,14**. Daño 8, vida 3 s. Se dibuja sobre los VFX (`render_priority` 49–51).
- Grupo propio `ufo_boss_projectiles` (además de `alien_projectiles`). Cada disparo pasa por `BeeShmupFairness.can_fire`.
- **Pico medido: 11 proyectiles simultáneos** en Fase 3, incluidos los que ya salieron por la izquierda.

## Bomb
Daña al jefe con su radio de 3 m y 32 de daño, sin cambios. No cancela proyectiles (decisión A del Fairness Pass) y no agrega invulnerabilidad.

## Muerte (2,3 s)
1. Al llegar a 0: deja de atacar, contacto y hurtbox apagados, sale del auto-aim, oculta la barra y **borra todos sus proyectiles vivos** (evita una muerte injusta después de ganar; no es bullet cancel de la bomba).
2. Flash, 4 chispas con impacto (0,3 s entre cada una) mientras cae, se inclina y se apaga el glow.
3. Explosión principal (`bomb` VFX r 2,6) + `ufo_death`.
4. `defeated` → el controlador completa la oleada → 4 m de scroll → `SECTOR DESPEJADO`.

## Integración en Level 01
`BeeLevel01Controller`: último encuentro despejado → respiro de 1,6 s con scroll 0 (arena lock, sin encuentros nuevos) → `_start_boss()` → `_on_boss_defeated` → `wave_completed`. Antes de la muerte nunca se muestra el final. Bee mantiene sus límites de vuelo normales; la cámara D no cambia. `freeze_enemies()` congela también al jefe si Bee muere.

## Restart y checkpoint
El jefe, su barra, el loop de hover y sus proyectiles son hijos de la escena del nivel. R (checkpoint X=190) y Shift+R recargan la escena: el jefe se reconstruye con HP completo y fase 1. El test verifica que no sobreviven nodos, barras, loops, voces `ufo_*` ni proyectiles, y que no hay jefes duplicados.

## Audio (aprobado, ver `audio/sfx/PROVENANCE.md`)
`ufo_sting` (Sonniss / Epic Stock Media, swell alien), `ufo_charge` (Kenney forceField_002), `ufo_hover` (Kenney spaceEngineLow_000, loop), `ufo_death` (Kenney lowFrequency_explosion_000 + explosionCrunch_004). Generados con `tools/integrate_audio_ufo01.gd`. Reutiliza `tech_hit` y `tech_death`.
- `ufo_charge` es un cue normal de `BeeAudio` (corto, pico ≤ 0,41). El sting (3,4 s), la explosión (2,2 s) y el hover (loop) superan el contrato de cues cortos de `validate_bee_audio_assets_v02`, así que el jefe los reproduce con sus propios reproductores: el hover como hijo del jefe y el sting y la explosión bajo el nodo `Enemies`, para que la explosión no se corte al liberar el jefe. Todos se liberan solos o con la recarga de escena.

## Rendimiento (render, 1152×648, Intel Arc B580; `dev/ufo_boss_01_review/bench_boss.gd`)
| | Frame medio | FPS | Peor frame | CPU render | Nodos |
|---|---|---|---|---|---|
| Arena sin jefe | 10,0 ms | 100 (tope del monitor) | 11,0 ms | 1,63 ms | 1419 |
| Jefe Fase 3 (20 s) | 10,0 ms | 100 | 16,2 ms | 1,94 ms | 1511 |

Sin pooling ni MultiMesh: los datos no lo justifican.

## Tests
`validate_bee_ufo_boss_01` (headless y render): respiro y arena lock, approach (z lejano, invulnerable, sin disparos, 2–4 s), entrada al plano, Fase 1 aimed (dirección al momento del disparo, sin homing), collider < núcleo, daño de Bomb, transiciones al 66/33 %, abanico de 5 con huecos atravesables, Fase 3 combinada, pico de proyectiles 5–15, HitFlash, muerte (ataques apagados, proyectiles borrados, final solo después), `SECTOR DESPEJADO`, reintento desde checkpoint, restart total y limpieza.

Ajustados lo mínimo para el nuevo final: `validate_bee_level_01_vertical_slice`, `validate_bee_terminal_states_v01` y `validate_bee_checkpoint_qol_v01` (matan al jefe cuando está activo).

## Limitaciones (requieren playtest humano)
- El HP sale de un modelo de jugador razonable; la duración real depende de cómo se juegue.
- La dificultad de los patrones no fue jugada por una persona.
- Spread rinde poco a distancia contra este jefe.
- La captura del OVNI lejano es un destello pequeño entre la niebla del atardecer.
- No hay música ni cámara de jefe.
- Probe invocado reservado para una versión futura.
