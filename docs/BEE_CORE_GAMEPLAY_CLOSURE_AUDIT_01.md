# BEE CORE GAMEPLAY CLOSURE AUDIT 01

## 1. Executive status

**READY FOR ART PASS: CONDITIONAL. Core aproximado: 93%.** El kit jugable necesario ya existe; faltan cierres pequeños de estado y de entrada al proyecto, no nuevas mecánicas. Esta cifra es juicio técnico del vertical slice, no progreso del juego completo ni resultado matemático de los tests.

Auditoría del proyecto local con Godot 4.7.2: código, escenas, Input Map, tests, documentos, métricas previas y Git. Cero modificaciones a gameplay, balance, arte o arquitectura. Se añadió sólo este documento y evidencia DEV en `dev/core_closure_audit_01/`. No se inspeccionó ni modificó Tucumán/2D ni la biblioteca externa.

Tres pendientes antes de declarar cerrado el core: **victoria terminal segura**, **polen rechazado durante derrota** y **arranque canónico en Level 01**. No requiere boss, scoring, dash, combo, menú ni Level 02.

## 2. Existing systems

| Área | Estado real | Estimación |
| --- | --- | --- |
| Player | CharacterBody3D, vuelo X/Y, facing, bounds, HP y visual de alas | 95% |
| Combat | Base, Spread, sting, Bomb, auto-aim, daño/HitFlash | 93% |
| Enemies | Siete familias con funciones diferentes y activación común | 95% |
| Level structure | 360 m, 24 eventos, 38 enemigos, humano, obstáculos, gates y final | 94% |
| QoL | Checkpoint, respawn protegido, Esc, Shift+R, hints | 92% |
| Presentation functional | HUD, VFX y SFX integrados; estética aún provisional | 95% |
| Overall core | Loop completo; excepciones terminales pendientes | **93%** |

Sistemas compartidos a conservar: HealthComponent, DamageHitbox3D/Hurtbox3D, HitFlash3D, BeeShmupStage/Camera, BeeAudio, BeeCombatVFX y wrappers visuales. No existe scoring jugable: `best_score` del auto-aim sólo ordena targets.

## 3. Player

`scripts/bee_prototype/bee_player.gd`: velocidades 7 m/s X y 6 m/s Y, aceleración 32, desaceleración 40. Input vector normalizado, sin gravedad, Z=0, facing por input horizontal. No dash/dodge/roll/sprint; esquivar consiste en volar. Esto alcanza para el SHMUP actual.

La ventana de vuelo avanza con cámara: X local ±5,2 m, Y=0,7–7,2. Move-and-slide colisiona con mundo sólido; clamp posterior y arrastre del borde trasero escriben posición directamente. No hay crush damage. Riesgo a comprobar en playtest: permanecer contra una roca mientras pasa el borde trasero; no se demostró bloqueo en los recorridos existentes.

Animación funcional: alas procedurales 16 Hz, facing y squash de sting/derrota; no hacen falta rig/AnimationTree ni animación esquelética de vuelo para cerrar mecánica. El Player reúne movimiento/armas/aim; separar más componentes ahora no resuelve los dos bugs encontrados.

Estado inconsistente confirmado: `PollenPickup.collect()` sólo comprueba grupo y recogida previa. Health permite restaurar desde cero, pero Bee conserva `is_defeated=true`. Diagnóstico: **polen aceptado, HP=20, Bee derrotada y contador incrementado**. Es curación parcial del estado muerto, no un respawn válido. Debe impedirse en el consumidor del pickup; no eliminar la capacidad genérica de restaurar Health.

## 4. Combat

Loop existente: mover → target contextual → X/Z → esquivar ataques telegrafiados → recoger curación/munición → decidir C → avanzar. No falta una herramienta obligatoria.

| Herramienta | Función / decisión actual | Observación |
| --- | --- | --- |
| Base | 10 HP, ilimitado, velocidad 14, vida 1,4 s | Siempre disponible; alcance nominal 19,6 m. X es por pulsación, no autofire ni cooldown propio. Comodidad/cadencia requieren playtest. |
| Sting | 15 HP, alcance 0,85, activo 0,12 s, cooldown 0,52 s | Alternativa sin ammo y más daño por impacto; exige proximidad al enemigo. No otorga protección/parry. Motivo mecánico existe; utilidad práctica pendiente. |
| Spread | 3×6 HP, ±14°, 24 pulsaciones | Cobertura o hasta 18 HP si conectan varios; impacto central aislado hace menos que Base. No es buff garantizado, ni arma seleccionable libremente. |
| Bomb | 32 HP, radio 3 m, una descarga, hasta tres cargas | Recurso escaso para grupo/cajas cercanas. No limpia balas ni protege a Bee: no describirla como panic shield. |

Auto-aim: rango 12 m, cono frontal total 80°, orden por distancia+ángulo; apunta al Hurtbox y fija dirección inicial, sin homing. Reduce trabajo de apuntar, pero deja posicionamiento, facing y dodge. No mide frustum ni oclusión: `visible/is_visible_in_tree` no significa visible en pantalla. Puede elegir fuera del encuadre o a través de props. Es riesgo de lectura/decisión, no razón para rehacer aim sin playtest.

Daño: una descarga por hurtbox y activación de Hitbox; Bomb deduplica por Health. Teams `bee/alien` evitan daño propio/friendly fire entre enemigos. Humano usa `human_hazard` separado. No existe daño genérico por rozar cada cuerpo enemigo: contacto ofensivo de Wasp, Speeder y Organic sólo en sus fases activas.

No hay i-frames tras daño normal: varios ataques distintos pueden sumar HP en un frame. HitFlash es presentación, no invulnerabilidad. Sólo respawn protege 1,25 s. Esta política no es bug por sí sola; validar justicia de impactos combinados antes de decidir i-frames. Un hit rechazado por protección queda deduplicado en esa ventana, evitando daño retroactivo del mismo ataque continuo.

Proyectiles se desplazan sin barrido y consultan hurtboxes (mask 2), no cuerpos del mundo: roca/log no frenan disparos; cajas sí tienen hurtbox. Riesgo de túnel a FPS bajos o doble contacto simultáneo antes de liberación diferida; no observado en validación normal. No cambiar colisiones globales en esta auditoría.

## 5. Enemies

| Familia | Rol | Daño / presión |
| --- | --- | --- |
| Wasp | Chase aéreo + melee | 10 HP; startup 0,30 s, activo 0,12, recovery 0,60 |
| Probe | Ranged que mantiene distancia | Bala 8 HP; startup 0,45, cooldown 1,25 |
| EyeDrone | Aéreo ligero, persecución + tiro | Bala 6 HP; reutiliza base ranged con chase propio |
| Speeder | Pasada horizontal/dash | Contacto 13 HP; anticipación 0,70 s; reentrada si sobrevive |
| Turret | Ranged fijo terrestre | Bala 9 HP; startup 0,65, cooldown 1,60 |
| Organic Alien | Stalk + lunge/bite | 13 HP; startup 0,65, lunge 0,38, recovery 0,75 |
| Walker | Heavy terrestre móvil/ranged | Bala 9 HP; aim, startup 0,65, Shoot, recovery y reposition |

Level aplica HP locales 36/32/24/30/40/47/60 respectivamente (Speeder 30, Turret 40). Todos ofrecen activate(target), defeated, is_active/is_defeated y Health/Hurtbox; Eye hereda Probe. Las diferencias de estados no requieren unificar una máquina universal.

Cubren melee, presión aérea, rango, pasada rápida, suelo fijo, orgánico y heavy móvil. **No falta una octava familia imprescindible.** Boss: **LEVEL 01 FINAL CONTENT LATER**; el último hard gate ya valida presión combinada y cierre. Su ausencia no impide Art Pass ni cierre de las herramientas base.

## 6. Hazards

**Giant Human:** ambiental, no enemigo que deba matarse. Telegraph 1 s, Run reutilizado, warning/steps, daño 20 HP una vez por crossing al mismo hurtbox. Wrapper Level recorta piernas animadas fuera del corredor central de 2,4 m; torso empieza Y=3,2. Shape duplicada por pierna, sin alterar GLB ni recursos compartidos. Tests recorren el hueco durante todo cruce y verifican piernas/torso. Evento X=140 espera a que salgan amenazas previas; scroll detenido durante cruce, después reanuda. Checkpoint X=190 impide repetirlo en respawn. **Mecánicamente suficiente**, con tolerancia deliberada; arte y claridad espacial pertenecen al Art Pass.

**Hollow log:** shell de cuatro colliders, collider heredado macizo desactivado. Test comprueba entrar/atravesar/salir. Mesh puede ocultar a Bee brevemente: problema de lectura visual para Art Pass, no evidencia de túnel físicamente cerrado. Si ocultación impide esquivar en playtest, sube a corrección de gameplay; no reconstruir ahora.

**Obstáculos/cajas:** ocho rocas, ocho cajas de 24 HP, botella y tronco. Cajas reciben X/Z/Bomb, al morir ocultan visual y quitan collider/monitorability. Sin drops; destruir despeja ruta y ya tiene propósito. Drop es NICE TO HAVE. Reload total las reconstruye; checkpoint conserva cajas previas destruidas y restaura posteriores. Daño parcial previo no se serializa, sólo destrucción; suficiente para un tramo archivado sin backtracking.

## 7. Weapons/powerups

V01 suficiente: Base → Spread al recoger, consume una unidad por pulsación y vuelve a Base al agotarse; refill al máximo 24. Bomb inicia con una, máximo tres; a máximo el pickup permanece. HUD/hints reflejan ambos.

Spread X=22/222; Bomb X=166/318. Checkpoint conserva estado real, sin munición gratis; futuras recogidas se deshacen al reintentar, sin acumulación. No hacen falta inventario, selección de diez armas ni upgrades permanentes.

Polen: 17 unidades, **cura 20 HP con cap 100 y suma contador opcional**; se consume también con HP lleno. No es score ni condición de progresión/final. Healing+incentivo de ruta alcanza; aclarar visualmente que 17/17 no es objetivo obligatorio es mejora menor. El bug de recogida derrotada sí requiere cierre.

## 8. Level 01

360 m / 2 m/s = 180 s de viaje base. Humano y gates agregan tiempo: 3–5 min es objetivo, **no duración humana demostrada**. Inicio directo en Bee (-2,4,0), hint breve y primer enemigo X=12 (~6 s). No necesita intro/cinemática ni countdown para funcionar.

24 eventos/38 enemigos: 20 soft, humano y tres hard gates en 254/296/340. Entradas separadas 0,8 s, cap dos hasta X=300 y tres después. Soft presionan 6 s y se retiran a 10 m/s: se puede sobrevivir sin matar todo; no explotarlo como obligación de agregar score. Hard gates esperan amenazas previas y requieren bajas. Enemigos posteriores se regeneran desde checkpoint sin duplicados; humano anterior consumido.

Final actual: al despejar oleadas y alcanzar distancia de cierre se detiene scroll, se congela IA y muestra `SECTOR DESPEJADO`. **No existe estado terminal seguro:** Bee puede moverse/disparar; freeze no elimina balas; derrota sigue reemplazando el mensaje. Diagnóstico aislado entrando por la rama existente de completion: bala real reduce HP 100→92 tras victoria; daño letal deja `sector_complete=true` y `is_defeated=true`, texto PLAYER DOWN. No fue una partida humana; la suite sí recorre el nivel completo, pero permite derrota posterior expresamente.

Cerrar con victoria estable, limpieza/neutralización de daño pendiente y una opción de reintento comunicada. Shift+R ya existe: no hace falta menú, stats ni transición de campaña. No balancear ni añadir boss para solucionar esto.

Dificultad: no selector, números locales y cap acotado. No se verificó supervivencia humana sin fixtures ni necesidad real de cambiar HP. Riesgos: sumar daño sin i-frames, pulsaciones de X, retiros soft que disminuyen necesidad de melee/Bomb, limitación de Spread contra target aislado. Difficulty settings y balance final van después; ningún exploit de acumulación de Bomb/polen en checkpoint se observó.

## 9. UI/QoL

HP, arma/ammo, Bomb, polen, fase del tramo, indicador de target, hints de pickups, checkpoint, pausa y derrota presentes. Información esencial disponible; UI provisional sin juzgar belleza. Falta mensaje final claro de reintento, ligado al cierre terminal, no HUD nuevo.

R antes del checkpoint recarga inicio; después respawn (190,5.4,0). Cura al activar sólo hasta mínimo 60%; snapshot de HP/Spread/Bomb/polen/pickups/cajas y tiempo. Hand-off único en memoria del SceneTree, sin autoload/save; reload limpia audio/VFX/shots y target. Protección con blink 1,25 s no bloquea controles; siguiente umbral a 8 m. Esc pausa y congela timer de protección, Esc reanuda. Shift+R full reset también pausado. R de derrota pausada requiere reanudar primero; utilidad full reset sigue disponible.

Polen/pickups anteriores quedan archivados incluso no recogidos; contador restaura snapshot, por lo que 17/17 no siempre puede alcanzarse tras reintento. No es exploit ni bloquea final. Hints enseñados se preservan. No faltan vidas, continue ni checkpoint múltiple para este slice.

## 10. Audio/VFX

Audio V02: 16 cues, 14 reales y dos placeholders, fallback procedural, SFX/Master/Music vacío, máximo 16 voces con prioridades y cleanup ligado a escena. Triggers de tiro/impacto/daño/derrota/pickup/crate/humano y cue de checkpoint integrados. Headless valida estructura/eventos, no escucha; render previo validó reproducción. Mezcla, timbre final y música **Art/Audio Polish**, no blocker funcional.

VFX: muzzle, trail, impacto, sting, Bomb, death/crate y pickups; recursos compartidos, cleanup temporal, HitFlash sin modificar daño. Tests validan disparadores/radio/lifetime y recursos, no belleza. Sin necesidad de otra capa VFX previa al arte.

## 11. Inputs

| Control | Acción |
| --- | --- |
| WASD / flechas | Vuelo X/Y |
| X | Base/Spread, una pulsación |
| Z | Sting/melee |
| C | Bomb |
| R | Reintentar tras derrota |
| Esc | Pausa/reanuda Level 01 |
| Shift+R | Reinicio completo Level 01 |

Shift+R puede satisfacer también R por comparación sin modifiers, pero el componente procesa full restart primero y retorna: prioridad lógica correcta. Falta test de eventos físicos/modificadores; pruebas QoL usan acciones sintéticas. Nombres heredados `throw_orange/debug_attack` son deuda de nomenclatura, no controles incorrectos. No necesita Space/jump, mouse aim ni Tab/lock-on en este kit Bee.

Gamepad: **BEFORE RELEASE** recomendado para distribución arcade; no MUST HAVE BEFORE ART en slice PC de teclado. Settings volumen/fullscreen/resolución/rebind: preparación de release/accesibilidad, no core inmediato. Save/campaign: **NO NECESARIO** para Level 01 con checkpoint de sesión.

## 12. Technical debt

| Prioridad | Hallazgo / acción propuesta |
| --- | --- |
| P1 | Estados terminales incoherentes: victoria dañable y curación derrotada. Corregir pequeño, con regresión explícita. |
| P1 operativa | `project.godot` main_scene todavía `bee_garden_poc.tscn`; F5 no prueba Level 01. Establecer entrada canónica, conservando POCs con F6. No cambiado aquí. |
| P1 conservación | Git sólo tiene baseline inicial `01dbd87`; 14 tracked modificados y 872 archivos untracked al iniciar (muchos DEV). Level 01/audio/VFX y demás mejoras no están protegidos por commit. |
| P2 | Level hereda escena/core POC y overrides específicos; checkpoint depende de nombres, `elapsed_seconds` y `_waiting_for_human` privados del controller. Mantener contrato local documentado; generalizar sólo al necesitar segundo nivel. |
| P2 | Controllers POC duplican políticas de waves; no son todos runtime de Level 01. Evitar editar todos por simetría. |
| P2 | Timeline, HP, 2 m/s de reanudación, índice/humano X140 y spawn Y5,4 hardcodeados: aceptables para un nivel, sensibles a cambios futuros. |
| P2 | Core no barra colisión de proyectiles ni frustum de aim; tests no cubren FPS bajos/contacto múltiple ni arrastre contra todas las rocas. Investigar si playtest falla, sin refactor preventivo. |
| P3 | DEV/capturas/logs, imports CSV/translation y docs históricas aumentan ruido; preparar política de distribución/archivo después. Git avisa LF→CRLF en los 14 archivos modificados: advertencia de conversión, no error de runtime; acordar política de endings al preparar baseline. |

Referencias locales actuales cargan, recursos licenciados y fuentes conservadas. Ownership: enemigos/projectiles/audio/VFX son hijos del nivel y reload los elimina; caches de streams/mallas no persisten nodos. Shapes humanas duplicadas por pierna. No se encontró necesidad de reemplazar sistemas compartidos.

Clasificación de estructura: **PRODUCTION candidate** Level 01, siete enemigos, Player/visuals, componentes, audio/VFX, pickups/hazards y assets aprobados (aunque carpeta diga `bee_prototype`); **KEEP** tests/docs/provenance/tools/fuentes .blend; **DEV ONLY** Visual Labs, review, fixtures, capturas/logs y runners; **ARCHIVE LATER** POCs superados y duplicaciones, después de verificar referencias heredadas. No borrar/mover nada ahora.

Git recomendado: revisar diff y untracked, preparar baseline funcional coherente con Level 01, dependencias, licencias, UID, tests y docs; evidencias DEV voluminosas en commit separado/archivo según política acordada. Verificar checkout limpio y suite; después Art Pass en commits pequeños. No ignorar indiscriminadamente assets necesarios. **Sólo recomendación: no commit/push/reset/stash/clean ejecutado.** Riesgo real de pérdida y comparación defectuosa si se continúa sin baseline; no es feature faltante.

## 13. Tests

22 validadores: vuelo/auto-aim, combate/derrota, visuales Bee/Wasp/Probe, Garden/Mission, humano, core SHMUP, aire/suelo/variedad, log, Organic/Walker, Weapons, Audio V01/V02, VFX, Level 01 y checkpoint. Cubren umbrales reales, enemigos, daños, teams, gates, humano, pickups, inventario, respawn, seguridad, limpieza, pausa y final.

Huecos prioritarios: (1) victory no cambia a derrota ni recibe daño pendiente; (2) polen rechaza Player muerto sin modificar HP/contador; (3) lanzamiento canónico y R vs Shift+R mediante eventos de tecla reales. Añadir pocas aserciones al corregir, no cincuenta tests. Después: overlap/swept collision a FPS bajo y protección congelada en pausa si hay problemas observados.

Suite verde no prueba dificultad/diversión ni estas garantías ausentes: varios tests matan actores vía Health y aceleran tiempo; el test Level además fuerza derrota después de completion. Diagnóstico DEV `probe_terminal_states.gd` reproduce problemas, **no es validator agregado a la suite**, ni reemplaza un recorrido real. Logs: `dev/core_closure_audit_01/terminal_states.log`.

Validación de esta auditoría: carga directa headless/render código 0; suite completa **22/22** aprobada, incluyendo Level 01 y checkpoint, sin regresiones ni errores/advertencias del motor. Runtime del proyecto sin cambios. Los dos problemas auditados son huecos del contrato/cobertura actual, no nuevas regresiones causadas por esta tarea.

## 14. Performance

Métricas locales existentes: VFX ~99,11 FPS en estrés, peor frame 37,845 ms (un pico); Audio V02 98,86 FPS, peor 36,103 ms, ~1275 nodos; checkpoint quieto 100,00/99,99 FPS sin/con proceso, peor 10,625/10,340 ms, 1057 nodos. Intel Arc B580 / Compatibility en pruebas previas. Son muestras breves, no benchmark general; no confundir headless/FPS acelerado con rendimiento de gameplay.

**No bloquea Art Pass en hardware probado.** Hay que volver a medir con nuevos assets/luces y en hardware objetivo inferior; los picos merecen observación, no optimización especulativa ahora. No se midió de nuevo por ser auditoría y existir métricas recientes comparables.

## 15. Missing systems

Ausentes confirmados: scoring persistente de partida, combo/multiplier, boss, gamepad, settings, save/campaña, menú/continue/transition. Su ausencia no equivale a core incompleto del slice. Sí faltan dos garantías de estado terminal y entrada canónica del nivel. No pedir infraestructura abstracta ni nuevos sistemas para resolverlas.

## 16. Must Have

1. **Cierre terminal Level 01**: victoria estable, neutralizar daño residual y comunicar reintento ya disponible. Sin Level Complete screen compleja ni stats.
2. **Rechazo de polen durante derrota**: HP=0/derrota deben ser coherentes; pickup no se consume ni suma contador.
3. **Arranque canónico**: F5/ejecución estándar deben abrir Level 01, no Garden POC. Confirmar Input Map/prioridad full restart en esa ruta.

Una pasada humana de Level 01 tras estos cierres es condición de aceptación del feel, no sistema que implementar. No exigir completar sin daño ni cambiar balance antes de observar problemas.

## 17. Nice to Have

Score simple para replay, drops selectivos en cajas, autofire si pulsaciones cansan, aclarar polen opcional, frustum de aim si afecta lectura, más pulido de hints/fin. Dash/dodge sólo si demuestra necesidad jugable futura; no obligatorio. Ninguno bloquea Art Pass. Evitar convertir esta lista en backlog automático.

## 18. Future

Boss como contenido final de Level 01 más adelante; Level 02/campaña/transition sólo al ampliar alcance. Gamepad y settings antes de release. Save si hay campaña que lo justifique. Balance final y accesibilidad después de playtest/art legible.

**NO NECESARIO ahora:** combo obligatorio, roll/sprint, diez armas, skill tree, vidas/continue, save para este nivel, cinemática inicial, máquina de estados Player compleja o arquitectura universal de encounters.

## 19. Art Pass blockers

**CONDITIONAL, tres blockers concretos:** victoria terminal, polen derrotado y launch canónico. Los dos primeros tienen evidencia; tercero está en config. Ninguno exige rediseño. Git baseline es higiene operativa recomendada antes del arte, no cuarto sistema jugable. No bloquean: estética provisional, boss ausente, scoring ausente, falta de gamepad, mezcla final o música.

Art Pass debe conservar coordenadas X/Y/Z, VisualRoot/facing frontal -Z, Hurtbox/Health, puntos de tiro, telegraphs, separación presentación/daño y tamaños de colisión. Mejorar lectura del log/foreground, targets y armas es trabajo visual valioso, sin alterar kit a la vez.

## 20. Roadmap

1. **Core Closure Micro Fix 01**: únicamente victoria segura, guard de polen derrotado y main_scene Level 01; tests cortos que protejan esos contratos. Mantener balance/diseño.
2. **Closure acceptance**: suite 22+ lo estrictamente necesario, carga estándar/directa, playtest humano hasta final con reintento/checkpoint. Revisar y preparar baseline Git con autorización separada.
3. **Art Direction Pass**: un tramo representativo con gameplay congelado, probar legibilidad y medir performance; extender sólo cuando sea visualmente aprobado. Sin Level 02 ni nuevas mecánicas durante esa fase.

## 21. Recommendation

La respuesta a “¿qué mecánicas imprescindibles faltan si mañana hacemos arte?” es: **ninguna nueva**. Hace falta cerrar estados ya existentes y asegurar que se ejecuta el nivel correcto. Próxima tarea exacta: **BEE CORE CLOSURE MICRO FIX 01**, limitada a los tres puntos anteriores y regresión. No implementada en esta auditoría. Después aceptar el feel con playtest humano y pasar a arte; no seguir indefinidamente acumulando POCs.

**BEE CORE GAMEPLAY CLOSURE AUDIT 01 COMPLETO.** Auditoría completa; esto no declara el core 100% cerrado ni los bugs corregidos.
