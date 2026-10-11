# INFORME NOCHE 01 — trabajo autónomo

Punto de partida: `pacing-aim-01` (e003a75, Lote 7). Cada etapa tiene su rama, encadenada sobre la anterior, y se cierra con la suite completa verde, commit y push.

## Lista de tareas
- [x] ETAPA 1 — Liberación y correcciones (`liberation-01`)
- [x] ETAPA 2 — Limpieza y assets de Codex (`assets-cleanup-02`)
- [x] ETAPA 3 — Pulido y legibilidad (`polish-03`)
- [x] ETAPA 4 — Prototipo Nivel 02 «Laguna» (`level02-lake-proto`)
- [x] ETAPA 5 — Preparar demo (`demo-prep-01`) — con pendiente: build (faltan plantillas de exportación)

## Decisiones tomadas sin poder preguntar (interpretación más razonable)
- **Assets de Codex sin trackear:** "no tocar" lo interpreto como no modificarlos ni borrarlos. Cuando una etapa necesita usarlos (Etapa 2), commiteo **tal cual** los archivos que el juego referencia, como en el respaldo del Lote 6, para que la rama sea jugable desde origin.
- **Sonido de liberación:** reutilizo el tintineo del polen ya aprobado (`audio/sfx/real/pollen.wav`, Kenney CC0), más agudo (×1,45), con el cue nuevo `liberate`. La explosión de tecnología es el `tech_death` de siempre. No agregué archivos de audio (así no hay licencias nuevas que revisar).
- **Luciérnaga:** no es enemigo (es decoración); "liberarla" no aplica. Las de primer plano ya son animales libres (sin implante).
- **Tortuga:** era un adorno del momento posterior al humano gigante. Ahora tiene un implante en el lomo: si le disparás, se libera y cuenta en LIBERADOS (es un bonus: si no le disparás, se va igual y cuenta como no liberada).
- **LIBERADOS n/N:** N = animales controlados que aparecieron en la partida (incluida la tortuga); n = los que liberaste. Se guarda en el checkpoint.
- **Organismo morado:** lo reemplacé en los eventos normales por otras familias (X=80 mariquita, X=214 libélula ondulante, X=254 mariquita blindada (gate duro: un blindado de suelo lo trababa), zona 2 polilla) y aparece en el jefe cada 2 invocaciones de las fases 2 y 3, solo.

## ETAPA 1 — Liberación y correcciones (`liberation-01`) — HECHA
- **Liberación** (`scripts/levels/bee_liberation.gd`, helper común): al llegar a 0 el implante, este tira chispas y una mini explosión cian y se oculta; el cuerpo pasa a colores cálidos (sin brillo alien); salen destellos dorados, un "LIBERADO" flotante (1,3 s) y un tintineo suave. El animal deja de atacar, no tiene hitbox activa y se aleja relajado `LEAVE_SECONDS` 3 s (volando arriba-izquierda o caminando). Sale de las amenazas al instante (el progreso de eventos no cambia) y cuenta en **"SECTOR DESPEJADO · LIBERADOS n/N"**. Lo usan: avispa, mosquito, mariquita, libélula (procedural y ondulante), polilla, hormiga, escarabajo, caracol, araña y tortuga.
- **Tecnología que explota** (igual que antes): sonda, ojo, speeder, torreta, walker, semillero, UFO y drones. **Hongo cañón:** explota solo el cañón (el dispositivo) y el hongo queda quieto, sin daño y con colores cálidos hasta que el scroll lo deja atrás. Caza alien: Etapa 2.
- **Organismo morado:** fuera de los eventos normales; el UFO lo invoca solo cada `ORGANIC_EVERY` 2 invocaciones (fases 2 y 3, en lugar de drones/sondas). Explota.
- **Escalas** (`scripts/levels/bee_fauna_sizes.gd`, `SIZE` relativo a Bee = 1,0; `BEE_LENGTH` 1,18 m medido): mosquito 0,7 · luciérnaga 0,6 · mariquita 0,9 · hormiga 1,1 (antes 2,2) · escarabajo 1,5 (antes 2,4) · caracol 1,3 (antes 1,9) · araña 1,4 · polilla 1,4 · libélula 2,0. Cada animal calcula su escala desde su propio largo medido; las hitboxes salen del tamaño final.
- **Mosquito suave:** dirección con aceleración gradual (`MOSQUITO_ACCEL` 6 m/s²) y oscilación senoidal lenta (`MOSQUITO_DRIFT`); frena suave al telegrafiar y la embestida sigue siendo solo con telegrafía. Medido: máx. 1,8 m/s y 6 m/s² mientras flota.
- **Luciérnagas:** las de primer plano (modelo real, 0,6× Bee) derivan por el mundo hacia −X y miran hacia ahí. Las del fondo ahora son **puntos de luz difusos** (partículas GPU sin gravedad), no cuerpos.
- **Tortuga** (`bee_aftermath_turtle.gd`): caparazón con 16 placas hexagonales, cabeza con ojo, cuatro patas, cola, toon/contorno/rim y colores de jardín. 2 iteraciones (`noche_turtle_a*` → `noche_turtle_b*`): en la primera las placas de arriba quedaban hundidas en la cúpula. Bandera `TURTLE_ENABLED`.
- **Sonidos:** cue `liberate` = el tintineo aprobado del polen (Kenney Interface CC0) más agudo; la explosión es el `tech_death` de siempre.
- **Ajuste por la liberación:** el gate duro de X=254 tenía al organismo; lo reemplacé por la mariquita, porque un blindado de suelo (caracol) dejaba el gate sin poder cerrarse.
- **Tests:** nuevo `validate_bee_liberation_v01` (no muere, no daña, se aleja, cuenta; tecnología explota; hongo; escalas medidas; mosquito suave; luciérnagas de fondo; tortuga). Ajustados: audio (alias), araña (`defeated` llega al terminar de trepar), rebuild/vertical slice/challenge (el organismo ya no está en los eventos), orientación (las luciérnagas reaparecen a la derecha), textos "SECTOR DESPEJADO · …".
- **Suite:** 72/72 PASS. Duración con el bot: UFO a los 387 s (6,5 min).
- **Capturas:** `noche_turtle_{a,b}{,_zoom,_freed}.png`, `noche_liberation_{ant,mosquito,mushroom}.png`.
- **Solo medido por tests (falta playtest):** sensación de la liberación, el tamaño nuevo de los animales y si el mosquito suave sigue siendo amenazante.

## ETAPA 2 — Limpieza y assets de Codex (`assets-cleanup-02`)
- **Humano gigante apagado:** `GIANT_HUMAN_ENABLED := false` (controlador). El nodo queda congelado y oculto, su evento se saltea sin detener el scroll y el momento posterior solo trae la tortuga (sin polvo de pisadas). No se borró código, escena ni tests: los tests que lo cubren lo vuelven a encender con `BeeLevel01Controller.giant_human_enabled = true`.
- **Fuera:** la botella roja del comienzo (oculta, el nodo se conserva porque otros tests lo buscan por nombre), la **caja de cerillos** y el **paquete rojo/crema** (dos tipos de destructible: ahora son la **lata de atún** y la **cáscara de banana** de Codex, con la misma jugabilidad y la colisión ajustada al modelo más bajo) y el envoltorio rojo/crema del picnic (X=171).
- **Assets de Codex agregados** (miniatura, todos detrás del plano de juego, sin colisión, mismo toon/contorno/rim por sus wrappers): botella verde (X=41), lata de atún, cáscara de banana, manguera, valla (5 módulos, X=148–184), casa de fondo lejano, piñas (`pine_cone`: "piña" = piña de pino), pinos altos y piñoneros (tramo final), tronco hueco con campanillas, más arbustos con margaritas y brotes de árbol.
- **Toon de Codex en el Level 01** (los POC no cambian): disparo de Bee (`projectiles/toon/bee_bolt`), disparos alien (`alien_bolt`, también la fauna de Codex), pickups (polen, Spread, bomba; mismos nombres para el checkpoint) y explosiones (`BeeCombatVFX.toon_bursts`: las muertes de tecnología usan la explosión toon cian de Codex; la onda de la bomba de Bee y de las minas conserva el anillo original porque muestra el radio real de daño; impactos y fogonazos sin cambio; el disparo de Bee es una subclase propia del toon de Codex que mantiene las reglas de impacto del juego). **Curación:** el tarro de miel de Codex aparece antes del UFO si Bee tiene menos del 70 % de HP (`BOSS_HEAL_BELOW`).
- **Caza alien** (`alien_needle_interceptor`): enemigo del atardecer (X=289, con un speeder; tecnología, explota). Patrulla arriba a la derecha, avisa con una línea 0,6 s y dispara un abanico de 3. HP 60. No integré el UFO con ruedas ni el águila.
- **Título** (`scenes/game/bee_title_screen.tscn`, escena principal): reutiliza la pantalla de Codex **sin modificarla** (hereda su script). Jugar Nivel 01 · Dificultad · Salir; "Colección de arte" solo en modo debug (ejecutando desde el editor o con `--debug-art`). Al completar el nivel vuelve al título (Enter o 8 s); R sigue reiniciando. Si el nivel se abre directo (F6 o tests), no vuelve solo.
- **Dificultad** (`scripts/game/bee_game_settings.gd`): FÁCIL = Bee recibe ×0,6 de daño, enemigos y UFO con ×0,75 de HP; NORMAL = igual que hoy.
- **Opcional no hecho:** el chorro de regadera en el hueco del humano (sin humano, el hueco ya no es necesario; queda pendiente si se quiere como peligro propio).
- **Archivos de Codex commiteados tal cual** (los que el juego referencia; calculado con `dev/asset_catalog/deps_closure.gd`): modelos y wrappers de las piezas de arriba, ítems/proyectiles/explosiones toon, pantalla de título, logo y shaders. Ninguno modificado.
- **Tests:** nuevo `validate_bee_assets_cleanup_v02` (humano apagado, props, toon, caza alien, título, FÁCIL). Ajustados: los tests que cubren al humano lo vuelven a encender; la botella roja ya no se exige visible; los destructibles de Codex tienen su propia verificación (mismo HP y hurtbox, colisión más baja); los pickups toon de Codex dejan su destello como hijo de `Powerups` y su feedback es la explosión toon cálida.
- **Suite:** 73/73 PASS.
- **Capturas:** `noche2_x{36,96,124,176,300}.png`, `noche2_{bottle,toon_shots,fighter}.png`, `noche_title.png`.
- **Falta playtest:** que la dificultad FÁCIL se sienta bien, si la casa/valla de fondo distraen (la Etapa 3 trabaja la legibilidad) y el flujo título → nivel → título en un build.

## ETAPA 3 — Pulido y legibilidad (`polish-03`)
- **Corredor central limpio** (`scripts/levels/bee_level_01_readability.gd`): todo prop decorativo que suba a la franja de vuelo (y 1,6–6,4 m) más cerca que z = −5 del plano de juego se corre hacia atrás, con la misma X y el mismo tamaño (39 props de Codex y del jardín doméstico). El pasto alto procedural tampoco queda en esa franja (`CORRIDOR_CLEAR_Z` en `bee_level_01_visual_target.gd`: las hojas que salían más cerca se espejan hacia atrás; la secuencia aleatoria aprobada no cambia). La basura baja del suelo se queda donde estaba. El brote de árbol de X=104 (llenaba el centro) quedó más chico y más lejos; también la valla y la casa de fondo.
- **Contraste:** los contornos de Bee y de los enemigos (ancho de actor) toman solo el 15 % del tono de la luz (`ACTOR_OUTLINE_TINT`), así quedan casi negros en el día, el dorado y el atardecer violeta. Los props mantienen el contorno teñido. El cian de los implantes de la fauna de Codex sube a `IMPLANT_GLOW` 1,1 (estaba en 0,65).
- **Cian solo para tecnología alien:** test con auditoría automática de colores. La baliza del checkpoint era cian y ahora es color miel (`BEACON_COLOR`). Todo el cian restante está en enemigos, implantes, pilones/relés, el dispositivo contaminado o crecimientos alien. El violeta queda como secundario (antenas, puntas).
- **Rendimiento** (1152×648, Arc B580, mismo banco que los lotes 5–6; el cuadro está topado a 10 ms por el monitor):

| X | CPU render antes | CPU render después | draw calls antes → después |
|---|---|---|---|
| 10 | 1,31 ms | 1,38 ms | 376 → 394 |
| 100 | 1,51 | 1,32 | 358 → 340 |
| 176 | 2,20 | 2,03 | 787 → 849 |
| 250 | 2,30 | 1,82 | 801 → 821 |
| 300 | 2,32 | 1,95 | 857 → 855 |
| 355 | 2,22 | 1,82 | 775 → 789 |
| **promedio** | **1,98** | **1,72** | — |

GPU sin cambios (~2,0 ms, ruido ±0,4).
- **Capturas:** antes `noche3before_x{10,100,176,250,300,355}.png`, después `noche3after_x…`, más `noche3_{x100,x176,x300,sunset_actor}.png`.
- **Falta playtest:** si el corredor quedó demasiado vacío o si falta "jungla" en algunos tramos (es fácil de ajustar con `CORRIDOR_Z`).
- **Tests:** nuevo `validate_bee_readability_v03` (corredor, contornos al atardecer, brillo de implantes, auditoría de cian). **Suite:** 74/74 PASS.

## ETAPA 4 — Prototipo Nivel 02 «Laguna» (`level02-lake-proto`, NO va a master)
- **Escena** `scenes/levels/bee_level_02_lake.tscn` (hereda la base del shmup). Reutiliza la cámara del Level 01 (encuadre E), los controles, el apuntado libre y la mira, el HUD de armas, los disparos toon, la liberación y la dificultad. Tiene director propio (`bee_level_02_controller.gd`) y decoración propia (`bee_level_02_lake_scenery.gd`).
- **Agua estilizada**: un plano con el shader de lago de Codex; el plano de juego queda sobre la superficie. Decoración (detrás del plano de juego): nenúfares (algunos con ranas Quaternius descansando), totoras, tronco hueco, raíces sumergidas, campanillas, helechos, pinos y orillas lejanas.
- **Enemigos nuevos** (animales: se liberan):
  - **zapatero de agua**: se desliza por la superficie y embiste (aviso 0,5 s);
  - **ninfa de libélula**: escupe un orbe lento (0,6 s);
  - **perca**: nada bajo el agua (sin hurtbox ni auto-aim mientras está sumergida), avisa con un anillo sobre el agua y una columna tenue en la X de Bee (0,7 s) y salta en arco a través de ese punto.
  - Además reaparecen la libélula ondulante y los mosquitos.
- **Mini-jefe sapo** (`lake_toad_boss.gd`, visual de Codex): **lengua** con línea de aviso de 0,7 s y **salto** con anillo en el punto de aterrizaje (0,9 s). Al caer lanza una **onda baja** por el agua hacia ambos lados (se esquiva volando alto). Implante en el lomo, 220 HP. Se **libera** (se va saltando) y eso completa el nivel: "LAGUNA DESPEJADA · LIBERADOS n/N".
- **Duración medida con el bot:** sapo a los 75 s, nivel completo en **~90 s** (9/15 liberados).
- **Acceso:** botón "Laguna (prototipo · debug)" en el título, solo en modo debug. El flujo del Level 01 no cambia.
- **Capturas:** `noche4_{start,strider,perch,toad_tongue,complete}.png`.
- **Pendiente:** no hay ranas enemigas (Codex no entregó una rana jugable; las ranas de Quaternius son decoración). Faltan sonidos propios del agua (salpicón, croar), checkpoint y transición desde el Level 01. El sapo no tiene animación esquelética (se mueve por transformaciones). Todo esto necesita playtest.
- **Tests:** nuevo `validate_bee_level02_lake_proto` (escena, 3 enemigos nuevos con telegrafía medida, sapo, recorrido con bot, acceso solo debug). **Suite:** 75/75 PASS (incluye todo el Level 01 sin cambios).

## ETAPA 5 — Preparar demo (`demo-prep-01`, desde `polish-03`)
- **master** quedó adelantada por fast-forward a `2798f08` (fin de `polish-03`) y pusheada. **No incluye** la laguna. No hice checkout de master porque Codex tiene cambios sin commitear en `docs/art/` que se perderían; la actualicé con `git fetch . polish-03:master`, que solo acepta fast-forward.
- **Export de Windows:** el preset "Windows Desktop" está en `export_presets.cfg` (x86_64, PCK embebido, sin firma, `builds/windows/BeeAlien.exe`, excluye dev/docs/tests/tools/demo/art_source). Lo commiteé con `-f` porque `.gitignore` lo ignoraba; no tiene secretos. `builds/` agregado a `.gitignore`.
- **Build: PENDIENTE.** Faltan las plantillas de exportación de Godot 4.7.2 en esta PC y no las instalé a ciegas. Cómo instalarlas y exportar: `docs/GUIA_EXPORT_DEMO.md`.
- **itch.io:** `docs/CHECKLIST_DEMO_ITCH.md` (nombre, descripción corta, controles, capturas necesarias, licencias a revisar).

## Valores configurables (resumen)
| Qué | Dónde | Valor |
|---|---|---|
| Tamaños de animales (× Bee) | `bee_fauna_sizes.gd` `SIZE` / `BEE_LENGTH` | ver Etapa 1 · 1,18 m |
| Salida relajada del liberado | `asset_fauna.gd` `LEAVE_SECONDS`, `LEAVE_GROUND_SPEED`, `LEAVE_AIR_SPEED` | 3 s · 1,8 · 2,4 m/s |
| Mosquito suave | `asset_fauna.gd` `MOSQUITO_SPEED`, `MOSQUITO_ACCEL`, `MOSQUITO_DRIFT(_RATE)` | 3,6 m/s · 6 m/s² |
| Brillo de implantes | `asset_fauna.gd` `IMPLANT_GLOW` | 1,1 |
| Texto / tintineo de liberación | `bee_liberation.gd` `TEXT_*`, `CHIME_PITCH`, `WARM_AMOUNT` | 1,3 s · ×1,45 · 0,28 |
| Organismo como minion | `ufo_boss_01.gd` `ORGANIC_EVERY` | 2 |
| Humano gigante | `bee_level_01_controller.gd` `GIANT_HUMAN_ENABLED` | false |
| Tortuga | `bee_level_01_moments.gd` `TURTLE_ENABLED`, `TURTLE_SCALE` | true · 1,0 |
| Curación antes del UFO | `bee_level_01_controller.gd` `BOSS_HEAL_BELOW` | 70 % HP |
| Dificultad FÁCIL | `bee_game_settings.gd` `EASY_DAMAGE_TAKEN`, `EASY_ENEMY_HP` | ×0,6 · ×0,75 |
| Vuelta al título | `bee_game_settings.gd` `RETURN_TO_TITLE_SECONDS` | 8 s |
| Corredor limpio | `bee_level_01_readability.gd` `CORRIDOR_*`; `bee_level_01_visual_target.gd` `CORRIDOR_CLEAR_Z` | z −5 · y 1,6–6,4 |
| Contorno de actores | `bee_toon_style.gd` `ACTOR_OUTLINE_TINT` | 0,15 |
| Baliza de checkpoint | `bee_checkpoint_qol.gd` `BEACON_COLOR` | miel |
| Sapo de la laguna | `lake_toad_boss.gd` (`TONGUE_*`, `JUMP_*`, `WAVE_*`, `IMPLANT_HP`) | 0,7 s · 0,9 s · 220 HP |
| Perca | `asset_fauna.gd` `LEAP_DEPTH`, `LEAP_SPAN`, KINDS "perch" | −1,4 · 1,8 m |

## Ramas de la noche
`liberation-01` (cd8008f) → `assets-cleanup-02` (e4cf71e) → `polish-03` (2798f08 = **master**) → `demo-prep-01` (esta). Aparte: `level02-lake-proto` (5dcc8a7, desde `polish-03`, no mergeada).

## Qué quedó solo medido por tests y qué necesita playtest humano
- **Medido por tests/bot:** telegrafías (≥ 0,4 s), escalas, orientación, liberación (no muere, no daña, se aleja, cuenta), tecnología que explota, duración del Level 01 (UFO a ~6,5 min con el bot) y de la laguna (~90 s), corredor despejado, auditoría de cian, FÁCIL/NORMAL, menú del título, rendimiento del render.
- **Necesita playtest:** la sensación de liberar (texto, tintineo, la retirada), el tamaño nuevo de los animales (sobre todo hormiga y escarabajo, ahora más chicos), si el mosquito suave sigue siendo una amenaza, la tortuga nueva, el nivel sin humano gigante, si el corredor limpio deja el jardín demasiado vacío, la dificultad FÁCIL, el flujo título → nivel → título y todo el prototipo de la laguna (ritmo, salto de la perca, sapo).

## Pendientes
- Build de Windows (instalar plantillas, ver guía).
- Chorro de regadera (opcional de la Etapa 2): no hecho; sin humano, el hueco que debía cubrir ya no existe.
- Laguna: ranas enemigas (falta un modelo jugable), sonidos de agua, animación esquelética del sapo, checkpoint.

## Incidente (resuelto)
Al crear `demo-prep-01` desde `polish-03`, git quitó del disco 15 archivos de Codex que yo había commiteado (tal cual) en `level02-lake-proto`: modelos y wrappers de `lake_fauna_v01`, `forest_fern` y el visual del sapo. No estaban en `polish-03`. Por eso, en la primera corrida de la suite de esta etapa, tres tests de arte de Codex fallaron por timeout. Los restauré en el disco desde el commit `5dcc8a7` con `git show` (sin tocar el índice) y verifiqué que son idénticos byte a byte (hash). No se perdió nada, pero conviene saberlo: esos archivos ahora están commiteados solo en la rama de la laguna; en las demás siguen sin trackear, como antes.

**Suite final de `demo-prep-01`:** 74/74 PASS (corrida limpia, después de restaurar los archivos de Codex).
