# INFORME NOCHE 01 — trabajo autónomo

Punto de partida: `pacing-aim-01` (e003a75, Lote 7). Cada etapa tiene su rama, encadenada sobre la anterior, y se cierra con la suite completa verde, commit y push.

## Lista de tareas
- [x] ETAPA 1 — Liberación y correcciones (`liberation-01`)
- [x] ETAPA 2 — Limpieza y assets de Codex (`assets-cleanup-02`)
- [ ] ETAPA 3 — Pulido y legibilidad (`polish-03`)
- [ ] ETAPA 4 — Prototipo Nivel 02 «Laguna» (`level02-lake-proto`)
- [ ] ETAPA 5 — Preparar demo (`demo-prep-01`)

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
