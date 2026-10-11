# INFORME LOTE 7 — RITMO, NIVEL MÁS LARGO, APUNTADO LIBRE Y ORIENTACIÓN

Rama `pacing-aim-01` (desde `assets-integration-01`). No toqué archivos ajenos sin trackear (`addons/`, `demo/`, `tools/art/`, ni los tests/escenas nuevos de arte que aparecieron en `tests/art/` durante el lote).

## Duración medida (bot de tests, `tests/levels/validate_bee_pacing_v01.gd`)
Bot: Bee invulnerable en el ancla del jugador, sigue la altura de la amenaza más cercana, **apunta libremente** a la amenaza más cercana en pantalla y dispara 3 veces por segundo con el arma Base (un jugador razonable, no perfecto). Mide segundos de juego.

| | Antes (Lote 6, 2 m/s, sin zonas) | Ahora |
|---|---|---|
| Hasta el UFO | 322 s (5,4 min) | **~381 s (6,3 min)** |
| Nivel completo | 412 s (6,9 min) | ~419 s (7,0 min) |
| Checkpoints | X=190 a los 113 s | X=190 a los ~196 s · X=281 a los ~305 s |
| Contenido nuevo (zonas de combate) | — | 3 × 36 s = **~108 s** |
| Respiro más largo sin amenazas | 3 s | ~18 s (los respiros nuevos) |

Diagnóstico previo (importante): con 2 m/s el nivel ya estaba **limitado por el contenido**, no por el scroll. Los eventos se encolaban detrás del tope de amenazas y la cámara llegaba al final (X=360) mucho antes que los últimos encuentros (el último evento salía a los 284 s, con la cámara ya parada). Con 1,5 m/s el paisaje y los encuentros vuelven a coincidir.

Por qué no 120 s exactos: con el scroll a 1,5 m/s la sola travesía de 340 m ya cuesta ~227 s más ~65 s de paradas (humano y gates), así que las zonas quedaron en 36 s c/u para no pasar mucho de ~6 min. Se ajusta con `ARENA_MAX_SECONDS` (36) y `ARENA_WAVE_MAX` (9).

## 1) Ritmo (`scripts/levels/bee_level_01_controller.gd`, constantes al inicio)
- `LEVEL_SCROLL := 1.5` (antes 2.0 fijo en 4 lugares). La escena sigue en 2.0 para los POC; el director lo fija al iniciar. `POST_BOSS_SCROLL := 2.0` (rodada final tras el jefe, sin cambio). `HOLD_SCROLL` sigue en 1.0.
- Coherencia: **no moví ninguna distancia**. Gates 254/296/340, humano 140, checkpoint 190, jefe 340.5, pilones, flor contaminada y luces del día siguen igual (todo está anclado en X y la luz se mezcla por distancia, así que solo tarda más en atardecer).
- **Tiempo en cámara** por familia, `CAMERA_TIME` (segundos mínimos en juego antes de que el director la retire): Avispa 12, Sonda 13, Ojo 13, Speeder 10, Organismo 13, Walker 16, Torreta 14, Libélula 14, Araña 12, Mosquito 10, Mariquita 15, Libélula ondulante 12, Polilla 13, Hormiga 12, Escarabajo 14, Caracol 15, Hongo 13, Semillero 22. Para que no se vayan antes por su cuenta, en el Level 01 subí sus contadores: Avispa `max_passes` 3→99, Libélula `max_passes` 3→99, Araña `attacks` 2→99 y fauna Codex `max_cycles`→99. Siguen atacando (con sus patrones y telegrafías de siempre) hasta su tiempo. El popcorn sigue cruzando (es su patrón). Los terrestres que quedan atrás del borde izquierdo se retiran como antes.
- Telegrafías: sin cambios (mínimo 0,4 s; ver tests de los lotes 4 y 6).

## 2) Nivel más largo
- **Zonas de combate** (clave `arena` en un evento existente, así no se mueve la estructura de 56 eventos): el scroll baja a `ARENA_SCROLL` 0,3 m/s y se juegan 3 oleadas una tras otra (la siguiente entra cuando el campo está limpio `ARENA_WAVE_GAP` 1,2 s, o a los `ARENA_WAVE_MAX` 9 s). Tope `ARENA_MAX_SECONDS` 36 s. Al terminar, el cartel dice "ZONA DESPEJADA" y hay un **respiro** de `BREATHER_SECONDS` 6 s sin encuentros nuevos (el paisaje corre).
  | Zona | Dónde | Oleadas (familias existentes en combinaciones nuevas) |
  |---|---|---|
  | CLARO DEL JARDÍN | X=112 (acto 2) | mosquito+avispa+mosquito · hormiga+araña+ojo · popcorn arco+libélula ondulante+sonda |
  | HUELLAS DEL GIGANTE | X=172 (acto 3) | escarabajo+2 mosquitos · organismo+popcorn en picada · caracol+polilla+avispa |
  | DEFENSA ALIEN | X=233 (acto 4) | walker+polilla · hongo cañón+libélula ondulante+sonda · mariquita+hormiga+ojo |
- **Segundo checkpoint** en X=281 (`second_checkpoint_x` en `bee_checkpoint_qol.gd`): después de la tercera zona y de la flor contaminada (266), antes del gate de 296. Misma regla que el primero (HP mínimo 60 %, guarda el estado); baliza "CHECKPOINT 2". El respawn ahí no repite nada anterior.

## 3) Apuntado libre (`scripts/bee_prototype/bee_player.gd`)
- Mover el mouse apunta (rayo de la cámara contra el plano de vuelo z=0; el punto se recalcula cada cuadro, así la mira queda quieta en pantalla aunque el nivel avance). **Clic izquierdo dispara** y X sigue disparando. Sin movimiento del mouse durante `AIM_HOLD_SECONDS` 2,5 s vuelve el **auto-aim** de siempre. Mientras apunta, Bee mira hacia la mira y el disparo sale de ese lado. `set_aim_point()` sirve para el bot y para un futuro gamepad.
- **Mira** (`scripts/levels/bee_level_01_crosshair.gd`): anillo amarillo cálido con contorno oscuro grueso, 4 marcas y punto cian como el HUD. Solo se ve mientras se apunta; oculta el cursor del sistema y lo devuelve en pausa, derrota o al salir. El marcador de auto-aim se oculta mientras se apunta.
- Hint de controles: "X / CLIC DISPARO · MOUSE APUNTA · Z AGUIJÓN · C BOMBA · ESC PAUSA".

## 4) Orientación (`scripts/levels/asset_fauna.gd`, `bee_level_01_asset_dressing.gd`)
- Todos los modelos de Codex miran hacia −X en yaw 0. Antes **las luciérnagas miraban al revés de su deriva** (yaw invertido) y la fauna nueva miraba siempre a Bee, aunque se moviera para el otro lado (p. ej. la libélula volviendo a la derecha o el mosquito errático).
- Ahora cada animal **mira hacia donde se desplaza**: velocidad relativa a la pantalla para los voladores (lo que ve el jugador) y velocidad sobre el suelo para los terrestres, suavizada `FACE_SMOOTHING` 0,18 s (el mosquito no titila). Bajo `FACE_MIN_SPEED` 0,5 m/s (quieto, telegrafiando, hongo estático) mira su ataque o a Bee. Al liberarse mira hacia donde se va.
- Auditadas las 9 familias: mosquito, mariquita, libélula ondulante, polilla, hormiga, escarabajo, caracol, semillero y hongo (estático).

## Tests
Nuevos: `validate_bee_pacing_v01` (duración con el bot, 2 checkpoints, 3 zonas ≥ 90 s de contenido, scroll 1,5, respiros ≤ 25 s y que ninguna unidad aérea se retire antes de su tiempo en cámara), `validate_bee_free_aim_v01` (8 direcciones, mouse, clic, mira, regreso al auto-aim, hint), `validate_bee_fauna_facing_v01` (orientación medida con posiciones reales en 8 familias + luciérnagas), `validate_bee_second_checkpoint_v01` (guardado, curación, respawn en X=281).
Ajustados (por los valores nuevos, no por cambios de comportamiento ocultos): scroll 2.0 → `LEVEL_SCROLL` (vertical slice, rebuild v02); unidades planificadas incluyen las de las zonas (rebuild v02, director); los tests que verifican el **patrón** de 3 pasadas (avispa), 3 pasadas (libélula) y 2 golpes (araña) fijan ese contador en la unidad de prueba (el patrón existe igual; el nivel ahora los deja hasta su tiempo en cámara); el test de checkpoint usa X=275 para morir antes del segundo checkpoint; el test de rocas reactiva el primer checkpoint después de saltar a X=307.

## Capturas (`dev/visual_target/`)
`lote7_zone{1,2,3}_open.png`, `lote7_zone{1,2,3}_wave2.png` (zonas de combate), `lote7_checkpoint2.png`, `lote7_fireflies.png` (luciérnagas mirando hacia su deriva), `lote7_crosshair.png` (mira apuntando atrás y arriba). Script: `dev/visual_target/capture_lote7.gd`.

## Dudoso / pendiente
- **Sin playtest humano.** La duración real depende de cómo juegue cada uno: un jugador que mata más rápido (Spread, bombas) termina antes; las zonas tienen tope de tiempo, así que uno más lento no se eterniza.
- Las zonas siempre llegaron al tope de 36 s con el bot (la 3.ª oleada entra a los ~18 s y queda viva). Si se sienten largas: `ARENA_MAX_SECONDS`.
- Mira y cursor: el cursor del sistema se oculta solo mientras se apunta; si molesta en ventana, es una línea en `bee_level_01_crosshair.gd`.

**Resultado de la suite final:** 71/71 PASS (headless, `SCRIPT ERROR` contado como fallo; incluye las suites de `tests/art/`, también las ajenas sin trackear). Durante el lote, un test ajeno nuevo (`validate_alien_ships_v02`) falló una vez por un error de parseo propio; en la corrida final ya pasaba (lo corrigió su autor, no esta rama).
