# BEE LEVEL 01 — TRANSFORMATION PASS 01

Rama `level01-transformation-01` (desde master `04f11fa`). Fuente de verdad: `docs/BEE_LEVEL01_ARCADE_DIRECTOR_BLUEPRINT_01.md` (con estado de implementación añadido al final). Referencia de **sensación** (no de contenido): The Flying Hamster — pantalla siempre viva, escalas distintas, formaciones, set pieces cortos, respiros con contenido. Sin bullet hell.

Commits:
1. `docs: add level 01 arcade director blueprint` — Blueprint + analizador + UIDs de dos scripts dev.
2. `feat: direct level 01 arcade pacing` — Fase A.
3. `feat: animate miniature garden respites` — Fase B.
4. `feat: introduce controlled fauna liberation` — Fase C.
5. `feat: stage alien escalation in level 01` — Fase D.
6. `style: strengthen bee alien visual identity` — Fase E + esta documentación.

Higiene previa: 9 archivos (`.import`, `default_bus_layout.tres`) marcados como modificados sin diferencia de contenido (solo LF/CRLF tras reimportar): `update-index --refresh` no bastaba; `git add` sobre esos 9 confirmó `diff --cached` vacío y limpió el estado sin cambiar contenido ni borrar nada.

## Métricas del director (BEFORE → AFTER)

Bot que no esquiva, puntería perfecta, vida enorme, 60 fps fijos; dispara cada 0,45 s (eficiente), 0,6 s (razonable) u 0,8 s (moderado). `dev/director_blueprint/gap_analysis.gd` + `dev/arcade_pressure_review/sim_level.gd`.

| Métrica | Eficiente | Razonable | Moderado |
|---|---|---|---|
| Llegada al UFO | 205,7 → **208,2 s** | 210,9 → **217,0 s** | 223,4 → **228,6 s** |
| Duración total estimada (UFO ≈45–60 s + respiro 2,6 s + approach 3,2 s + cierre ≈4 s) | ≈4:25 | **≈4:40** | ≈5:00 |
| Enemigos / eventos | 64/24 → **71/31** | igual | igual |
| Decision gaps estrictos ≥2 s | 1 (5 s) → **0** | 1 (5 s) → **0** | 1 (5 s) → **0** |
| Tramos silenciosos ≥3 s | 8 → 6 | 7 → 6 | 6 → 6 |
| …de ellos "aburridos" (solo polen o nada) | 5 s → **0 s** | 5 s → **0 s** | 5 s → **0 s** |
| Tramo silencioso no deseado más largo | 5 s (apertura) → **0 s** | 5 s → **0 s** | 5 s → **0 s** |
| Tiempo sin amenaza visible | 23 % → 18 % | 20 % → 16 % | 15 % → 14 % |
| Presencia de fuego a distancia | 33 % → 37 % | 44 % → 46 % | 57 % → 55 % |
| Proyectiles hostiles: promedio / pico | 0,68 / 8 → **0,84 / 10** | 0,76 / 8 → **0,95 / 9** | 0,95 / 9 → **1,05 / 9** |
| Amenazas máx. (enemigos / con disparos) | 3 / 10 → 3 / 12 | 3 / 10 → 3 / 12 | 3 / 11 → 3 / 12 |

Los 6 tramos silenciosos que quedan son **todos diseñados** y tienen contenido: apertura con la lata (0–3 s), tensión antes de la alerta del humano (66–69 s, se conserva como respiro verdadero), secuela del humano (80–87 s), jardín contaminado al atardecer (145–150 s), recompensa de Bomb tras el Walker (177–184 s) y el último silencio antes del UFO.

## Fase A — Arcade Director

- **5 actos internos** (`ACT_STARTS`, nunca se muestran): 1 AWAKENING 0–68 m, 2 CONTROLLED GARDEN 68–140, 3 HUMAN TERRITORY 140–198, 4 ALIEN ESCALATION 198–340, 5 FIRST CONTACT (respiro + UFO). `current_act` en el controlador.
- **EVENTS V2** (datos simples): umbrales cada **4–16 m** (antes 14 m fijos; 9 espaciados distintos, nunca más de 3 iguales seguidos), microeventos *popcorn* (Speeder solo, diagonal de Wasp), **10 formaciones** con altura/X por unidad (`pair`, `escort`, `staggered`, `horizontal`, `vertical`, `top_bottom`, `diagonal`, `rock_turret`, `wave`, `v`), 4 **momentos del director** sin enemigos (señal `director_moment`) + `last_silence`. Gates duros y humano en el mismo sitio (X=140, 254, 296, 340).
- **Lenguaje de proyectiles:** el abanico del EyeDrone solo desde **X=96** (antes: ráfagas apuntadas); a mitad, combinaciones; tarde, composiciones.
- **Presencia:** popcorn (Speeder, Eye), medio 4–8 s (Probe en hold/advance, Turret), persistente hasta ~10–15 s (Wasp de 3 pasadas, libélula, Walker escoltado). Sin HP extra.
- **Dificultad:** 64 → 69 enemigos en la Fase A (presupuesto 60–72); 71 con las dos libélulas.
- **Bomb:** recarga de X=318 → **X=302**, justo después del gate del Walker (pico → recompensa → recuperación).
- Test: `validate_bee_level01_arcade_director_v01` (orden, actos, cadencia, formaciones, gating del fan, momentos, nivel completo con techo de amenazas y de proyectiles, checkpoint).

## Fase B — Mundo en miniatura

| Evento | Qué es | Coste |
|---|---|---|
| **La lata del despertar** (X≈6) | lata de refresco aplastada de 4,3 × 2,7 m (código, Style C) detrás del plano de vuelo; se balancea y suelta polvo al empezar | CHEAP |
| **Secuela del humano** (X≈146) | polvo asentándose en varios puntos + escarabajo no hostil cruzando el suelo 9 s | CHEAP |
| **Recompensa de Bomb** (X≈302) | la cápsula late 3 veces y un anillo la marca | CHEAP |
| **Impacto contra sólidos** | las paredes del tronco hueco detienen los disparos con chispa y sonido aprobados; la roca estructural ya lo hacía. La botella gigante **no**: no tiene collider (Bee la atraviesa), así que tampoco frena disparos | CHEAP |
| **Vegetación** | los ~14 helechos de primer plano se mecen cuando Bee pasa baja cerca (tween, sin física ni shader) | CHEAP |

## Fase C — Fauna controlada: la libélula

- **Visual:** criatura propia en código, Style C (toon, rim, contorno, alas translúcidas con el shader de alas): abdomen largo, cuatro alas, ojos grandes, ~2,5 m de envergadura (mayor que Bee). Vista en tres cuartos desde arriba para que las alas se lean con la cámara lateral.
- **Controlada:** tono violeta-gris apagado, aleteo rígido y rápido, hover mecánico.
- **Implante** en el tórax (carcasa oscura, núcleo cian pulsante, antenas violeta): **único objetivo dañable**, hurtbox generosa de 0,5 m, el auto-aim apunta a él. **60 HP** = 1,5 s de fuego Base perfecto a 3,3 Hz (más para un jugador real).
- **Cuerpo:** el abdomen absorbe disparos con un destello neutro; no hay "HP del animal" (la salud del cuerpo nunca cambia).
- **Ataque:** ENTER → HOVER → TELEGRAPH (alas se abren, implante brilla) → **pasada amplia bloqueada** (sin homing) → RECOVERY → REPOSITION; 3 pasadas, contacto solo durante la pasada (13), luego sale aún controlada. Sin proyectiles.
- **Liberación:** cancela el ataque al instante, el dispositivo se suelta y cae, el brillo se apaga, vuelven los colores naturales (verde/azul), aleteo libre, un giro y vuelo de salida; descarga alien + campanilla positiva (cues aprobados). Sin explosión ni cadáver. La libélula liberada deja de contar como amenaza en ese instante.
- **Pista:** `DESTRUÍ EL IMPLANTE` solo la primera vez (3,5 s).
- **Apariciones:** X=124 **sola** (sustituye la Wasp aislada, antes del humano) y X=262 con una Probe en el jardín contaminado. Tras el checkpoint no reaparece la primera (sin farmeo); reinicio total la restaura.
- Test: `validate_bee_controlled_fauna_v01`.

## Fase D — Escalada alien

- **Progresión:** antes del checkpoint domina la naturaleza; después, 9 pilones alien (carcasa oscura, anillo cian, punta violeta) detrás del plano, más grandes hacia el atardecer. Sin campo de neón.
- **Jardín contaminado** (X≈262): flor grande con placas oscuras, zarcillos y nodos que laten; pétalos drenados a malva. Un **dispositivo de control** (30 HP) en el plano de vuelo puede dispararse: el brillo muere, la flor recupera su rosa, polen. Sin drop.
- **El último silencio:** respiro previo al jefe 1,6 → **2,6 s**; la luz y el ambiente bajan, sube un zumbido (el loop aprobado del UFO) y una sombra enorme barre el jardín; la luz vuelve con el reveal. **UFO Boss sin cambios.**
- **Giant Human + Wasp:** **no implementado**. El corredor seguro está en la banda media (2,4–4,2 m); una pasada de Wasp allí empujaría a Bee hacia zapatos o torso. Fairness por encima del momento espectacular: el humano sigue solo.
- **Momentos firma presentes:** 1 lata del despertar · 2 tronco (formación escalonada en X=50) · 3 primera libélula · 4 Giant Human · 5 roca estructural + Turret (X=207) · 6 jardín contaminado · 7 último silencio / sombra del UFO · 8 reveal del UFO.
- Test E2E: `validate_bee_level01_transformation_v01`.

## Fase E — Identidad Style C

| | Antes | Después |
|---|---|---|
| Contorno Bee | 0,0025 (~1,3 px @1080p) | **0,0030** (+20 %) |
| Contorno actores (Wasp, Probe, Eye, Turret, Walker, Speeder, Organic, libélula, UFO, dispositivo alien) | 0,0025 | **0,0029** (+16 %) |
| Contorno props (rocas, cajas, lata, escarabajo, flor, pilones) | 0,0025 | **0,0023** (−8 %, más sutil) |
| Giant Human | sin contorno | sin contorno (conservador por escala) |

Evaluado en pantalla con recorte ampliado (`style_compare_zoom.png`): trazo un poco más dibujado en lo que el jugador lee, sin efecto pegatina.
- **Coherencia:** mismas bandas toon, rim y respuesta de material para todo (un único shader); sin cambios de saturación o valor por modelo.
- **Lenguaje alien unificado** con el UFO (`BeeAlienPalette`): cian `#26F2FF`, violeta `#9E38F2`, carcasa oscura del panel del UFO, emisión nunca por encima de los emisores del UFO (2,0). Lo comparten implante, dispositivo, pilones y flor contaminada.
- **Bee al atardecer:** legible (amarillo sobre violeta, ver `11_sunset_combat.png`); sin rim ni emisión extra.
- Cámara D, GL Compatibility, sin DOF ni posproceso nuevo.

## Rendimiento (render 1152×648, Intel Arc B580; `bench_scenes.gd`, `bench_density.gd`)

| Escenario | Pico de primera aparición | Sostenido | FPS | Peor sostenido |
|---|---|---|---|---|
| Jardín tranquilo | 11 ms | 10,00 ms | 100 | 11 ms |
| Combate denso al atardecer | 38 ms | 10,07 ms | 99 | 31 ms |
| Libélula | 10 ms | 10,00 ms | 100 | 12 ms |
| Giant Human | 34 ms | 10,03 ms | 100 | 28 ms |
| Jardín contaminado | 37 ms | 10,02 ms | 100 | 21 ms |
| Último silencio | 11 ms | 10,00 ms | 100 | 13 ms |
| UFO fase 3 | 10 ms | 10,00 ms | 100 | 11 ms |
| Tramo denso 290 m → jefe | — | **10,05 ms** (antes 10,08) | 99 | 127 ms (primera aparición de una familia) |

Sin regresión sostenida (FPS limitado por el monitor). Los picos son compilación de shaders/pipelines la primera vez que aparece algo en un proceso nuevo.

## Tests

Nuevos: `validate_bee_level01_arcade_director_v01`, `validate_bee_controlled_fauna_v01`, `validate_bee_level01_transformation_v01` (estructura: director, formaciones, fauna, liberación, destructibles, checkpoint, humano, contaminación, UFO, completado, ningún disparo hostil nacido fuera de pantalla). Actualizados solo por la nueva tabla: vertical slice, checkpoint (índice tras X=190 calculado), Challenge, Arcade Pressure, Combat Patterns (totales y entrada de HP del implante). Suite completa: **36**.

## Limitaciones y diferido

- Todo el ritmo se mide con bots; la diversión la decide el playtest.
- **Diferido:** segunda/tercera fauna distinta (polilla, escarabajo controlado…), gota de agua, Wasp en el cruce del humano (descartado por fairness), contorno para el humano, reacción de vegetación por shader, feedback en la botella gigante (no es sólida).
- El hover de la libélula mira a la cámara en tres cuartos: sus alas se ven verticales mientras se mantiene controlada (la silueta "vista desde arriba" girada). Se ven abiertas durante el giro de liberación.
- No se hizo: música, UI, Level 2, nuevas armas, score, gamepad, Forward+.
