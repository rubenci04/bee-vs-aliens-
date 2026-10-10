# INFORME UFO BOSS 01 — "NODO ALIEN" (lote 4)

> **Actualización (fixes visuales 01):** HP 400 → 500, F9 deja Base + 2 bombas y se subió la dificultad: ver `docs/INFORME_FIXES_VISUALES_01.md` (valores nuevos). Las tablas de abajo muestran los valores de la primera pasada.

Rama `ufo-boss-01` (desde HEAD de `camera-fp-spike`). `master` se adelantó por fast-forward a ese mismo commit (9db6f11) antes de crear la rama.

## Punto de partida (importante)
El repo ya tenía un jefe OVNI funcional ("ALIEN SCOUT", `scripts/levels/ufo_boss_01.gd`, doc `docs/BEE_UFO_BOSS_01.md`, 1300 HP, 3 fases, drones en fase 2, flujo de nivel y SECTOR DESPEJADO). **No lo rehice**: lo adapté a este pedido. Lo que ya existía y se conservó: construcción por código en estilo C sin assets externos, aviso/oscurecimiento "última calma", descenso con sting, drones (2 Eye Drone en fase 2, 1 Probe en fase 3), muerte con explosión y SECTOR DESPEJADO recién al terminar, invulnerabilidad tras ganar, reinicio con R. El doc viejo describe los valores anteriores (HP 1300, 0,8 de escala): vale este informe.

## Qué cambió
- **Nombre y HP:** barra "NODO ALIEN"; HP 1300 → **400**. Se actualizaron las asserts de 1300 en 8 suites.
- **Tamaño:** escala visual 0,8 → **1,6** (aro de ~2,7 m de radio = ~5,4 m de ancho, ~2x el anterior). Hurtbox y contacto escalados igual. Encuadre: el nivel usa el preset **E** (ancho visible ~12,6 m), no el D; 6 m exactos taparían la zona de vuelo de Bee, así que quedó en ~5,4 m, anclado más a la derecha (ANCHOR_DX 3,0) y con menos oscilación vertical para que no se corte arriba. Capturas: ver abajo.
- **Rayo tractor (fase 3):** cada 3.er ataque de la fase 3. Marca naranja pulsante en el suelo + columna tenue en la X de Bee **bloqueada** al empezar; 1,0 s después cae una columna cian (0,8 s). Daño 15, **un solo golpe por exposición**. Se cancela al morir/congelarse. Decisión: la columna cae en la X de Bee (no bajo el platillo) porque el platillo vive en la derecha y nunca amenazaría a Bee; moverse 1,5 m lo esquiva.
- **Aviso:** "SEÑAL DESCONOCIDA" durante la última calma y el descenso (antes "¡PRIMER CONTACTO!"). El oscurecimiento existente ahora deja el combate ~12 % más oscuro (sol x0,88, ambiente x0,9) en vez de volver al 100 %.
- **Suministros:** el polen PollenM pasó de X=347 (inalcanzable) a X=338,4 (antes del jefe). Pickup de bomba (B) aparece en la arena durante la última calma **solo si Bee tiene <2 cargas** (así morir y reintentar no regala bombas). No agregué un Powerup fijo a la escena: habría roto el conteo (5) de 4 suites.
- **Respawn en el jefe:** al empezar la pelea se toma un checkpoint propio (`activate_boss_checkpoint`): HP mínimo 60 (mismo criterio que el checkpoint de X=190), munición/bombas/polen y objetos recogidos. Si Bee muere, R reaparece ahí (reproduce la última calma + descenso con el jefe a HP completo), no en X=190.
- **Debug F9:** salta al inicio de la pelea (recarga el nivel con 100 HP, Spread 20, 2 bombas). Muestra "DEBUG · SALTO AL JEFE (F9) · NO ES EL JUEGO NORMAL" arriba; el cartel sobrevive a un respawn dentro del jefe y desaparece con Shift+R.
- **Explosión:** VFX principal y pesado ~1,5x, más sacudida de cámara.

## Valores de balance (todo en `scripts/levels/ufo_boss_01.gd` salvo indicación)
| Parámetro | Valor |
|---|---|
| HP (`max_hp`) | 400 (Base 10 = 40 tiros; ~14 s con 33 dps) |
| Fases | 66 % / 33 % (`PHASE_2_RATIO`, `PHASE_3_RATIO`) |
| Daño proyectil / contacto | 8 / 12 (`SHOT_DAMAGE`, `CONTACT_DAMAGE`) |
| Rayo | daño 15, aviso 1,0 s, activo 0,8 s, ancho 1,5 m (`BEAM_*`) |
| Ráfaga dirigida | 3 tiros, 0,14 s entre sí, 6,2 m/s; abanico 5 tiros a 17°, 4,8 m/s |
| Ciclo por fase (`PHASE_TUNING`) | amplitud / período / pausa / aviso dirigido / aviso abanico: F1 0,9/5,4/1,45/0,6/0,7; F2 1,1/4,6/1,3/0,55/0,7; F3 1,3/3,4/1,0/0,5/0,6 |
| Drones | F2: 2 Eye Drone; F3: 1 Probe; recarga 11 s / 13 s |
| Aparición | descenso 3,2 s, invulnerable; última calma 2,6 s |
| Respawn | HP mínimo 60 % (en `bee_checkpoint_qol.gd`) |

## Cómo probarlo
1. Abrir el proyecto en la rama `ufo-boss-01`, F5.
2. **F9** en cualquier momento: salta a la pelea (cartel DEBUG). Esperá ~6 s: "SEÑAL DESCONOCIDA", el cielo se oscurece, aparece una B (bomba) y baja el OVNI.
3. Fase 1 (>66 %): ráfagas de 3. Fase 2: aparecen 2 drones. Fase 3 (<33 %): mirá la marca naranja en el suelo, tenés 1 s para salir de la columna; luego cae el rayo.
4. Matarlo: explosión grande → "SECTOR DESPEJADO · R — JUGAR DE NUEVO". Bee no recibe daño después.
5. Morir en el jefe y apretar R: volvés al inicio de la pelea con ≥60 HP.
6. Ajustar: tocar las constantes de la tabla.

## Capturas (renderizadas)
`dev/visual_target/ufo_boss_phase1.png`, `_phase2`, `_phase3`, `_beam_mark` (aviso), `_beam` (rayo activo), `_explosion`.

## Tests
Nuevo: `tests/levels/validate_bee_ufo_boss_nodo_v02.gd` (aviso y suministros, nombre/HP/ancho, Spread y Bomba dañan, drones en F2, aviso del rayo de 1 s, esquivar = sin daño, un golpe de 15, SECTOR DESPEJADO tras la explosión, sin daño posterior, respawn con HP ≥ 60 sin conservar daño al jefe, F9 + cartel DEBUG). Ajustados: `validate_bee_ufo_boss_01` (retry ahora vuelve al jefe; jefe en fase 3 empieza con rayo), y las suites que fijaban 1300 HP. Suite completa: ver resultado al final.

## Decisiones sin preguntar / pendientes
- Ancho 5,4 m en vez de 6 (ver arriba). Sonido grave de descenso: se mantuvo el sting existente (Sonniss/Epic, ya registrado) más el hover de Kenney; no agregué audio nuevo.
- El rayo no sale del platillo sino que cae desde arriba en la X de Bee (marcado en el suelo); si preferís que el platillo se mueva sobre Bee, hay que ampliar su rango lateral.
- No hay remoto: no hice push.
