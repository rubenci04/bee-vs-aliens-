# Informe Lote 12

## Etapa 1 — Auditoría y mudanza por nivel

- **Auditoría:** `docs/art/AUDITORIA_ASSETS.md` (112 GLB medidos: triángulos, implante, material blanco, uso, `_lite`, presupuesto, nivel). Hallazgos: 1 pieza blanca (`hipster_poc`, humano gigante apagado), 0 materiales rotos, 26 GLB sobre presupuesto (4 tienen `_lite`: hormiga, mariquita, mosquito, oruga), 0 modelos sin implante separado.
- **Mudanza** (8 lotes: N1, N2, N3, N4, N7, shared, `_unassigned`, estilo; tras cada uno reimportación y 35 tests dirigidos — todos `tests/art/` más los del nivel, del imán de fauna y los de ítems/proyectiles — en verde, ningún lote revertido): 82 GLB heredados + `bee_mid_poly`/`wasp_mid_poly` (de `assets/style/models/`), con sus `.import` y `.blend`; 60 con `git mv` (historial conservado) y 27 con `mv` porque nunca se habían commiteado. Se reescribieron las rutas en 150+ archivos (escenas, `.tres`, scripts, tests, tools, manifiestos, docs de arte). Resultado: Nivel 1 = 45 GLB (29 del elenco/decorado heredados y los nuevos de Codex), Nivel 2 = 27, Nivel 3 = 11, Nivel 4 = 8, Nivel 7 = 3, shared = 14, `_unassigned` = 4 (gaviota, pulpo y mantarraya en `coastal/`; humano gigante en `human/`).
- **Rana:** código (`garden_toad_encounter.gd`, `lake_toad_boss.gd`) a `scripts/levels/level_02_lake/` (con sus `.uid`), escena a `scenes/levels/level_02_lake/lake_toad_miniboss_visual.tscn`, modelo `amphibian_mount_study` a `level_02_lake/bosses`. Se mantuvo el nombre de carpeta `level_02_lake` (el pedido dice `level_02_lagoon`; Codex ya entregó ahí, ver Discrepancias del checklist).
- **Duplicados:** `swarm_lite_v01/*` pasaron a `*_lite` (hormiga, mariquita, mosquito, oruga) para convivir con las versiones completas.
- **Documentos:** `ASSET_MANIFEST.md` regenerado (112 filas, 50 en uso), `ASSET_CHECKLIST_BY_LEVEL.md` con estados reales y 9 discrepancias, README con inventario en cada carpeta de nivel, `shared/` y `_unassigned/` (en `assets/models/` y `art_source/blender/`), `ASSET_MOVE_PLAN.md` marcado como ejecutado.
- **Commit:** incluye el arte de Codex que estaba sin versionar (GLB, `.blend`, laboratorios, scripts/tests/tools de arte, `concept_art`) porque las rutas movidas lo referencian. Quedan fuera `addons/` y `demo/` (terceros, sin tocar).
- `.git/index.lock` huérfano (0 bytes, sin proceso git): lo borré al aparecer; la primera pasada de `git mv` falló por eso y se repitió completa.

### Pendientes de mover

| Qué | Motivo |
|---|---|
| `assets/models/<tanda>/manifest.json` (24) | Los leen `tests/art/*.gd` y `tools/art/capture_requested_props_details.gd` por la ruta de la tanda (incluso construida con `"res://assets/models/"+batch+...`). Sus campos `source`/`glb` ya apuntan a las rutas nuevas. |
| `tools/art/create_*.py` (generadores de Blender) | Sus constantes `OUT`/`SRC` apuntan a la carpeta de la tanda vieja; reubicar requiere una tabla por tanda (varias tandas se repartieron entre niveles). Solo importa si se vuelven a ejecutar. |
| `scenes/art_labs/**`, `scripts/art/**`, `tests/art/**` | Laboratorios y validaciones: referencian por ruta y ya están actualizados; no son arte de nivel. |
| `bee_aftermath_turtle.gd`, `bee_level_01_scale_event.gd` (invoca la rana) | Código del Nivel 1; se apaga en la etapa 2 con la constante. |
| Carpetas vacías `assets/models/<tanda>/` y `art_source/blender/<tanda>/` | Contienen solo el `manifest.json` o un `.gdignore`; no se borran. |

### Qué falta (Nivel 1)

- Moscas común/verde/nube, gusanos A/B, hongos de jardín y tarántula: solo arte; faltan escena jugable, IA/HP/hitbox y, en la tarántula, hitbox del implante y liberación.
- Tarántula: el modelo lleva exoesqueleto alien (placas, núcleo cian, nodos); el contrato pide solo implante.
- Sin `_lite` y sobre presupuesto: escarabajo ciervo (9.952), caracol (7.748), hongo cañón (11.822). Hormiga y mariquita tienen `_lite` pero el juego sigue cargando la completa.
- Araña colgante: el GLB (`controlled_hanging_spider`) no está conectado al nodo procedural.
- Tortuga de jardín: solo pieza procedural de la secuela; falta modelo/escena de tanque.
- Robot caminante: falta modo mini-jefe con escoltas.
- Hongos destructibles que sueltan polen: no existe la lógica.

Verificación: reimportación (0 errores) y suite completa **91/91 PASS** (la primera pasada dio 48/91: la caché de clases no conocía los scripts movidos de la rana; tras reimportar quedó todo en verde). Logs `dev/lote12_1b_*`.

## Etapa 2 — El Nivel 1 solo con su elenco

- **Interruptor:** `LEVEL01_ROSTER_ONLY := true` (`bee_level_01_controller.gd`) + `static var roster_only` (los tests del flujo antiguo lo ponen en `false` antes de cargar el nivel, como `giant_human_enabled`). `EVENTS_ROSTER` es la tabla nueva; `EVENTS_LEGACY` conserva intacta la anterior (72 eventos, UFO, rana, aliens). Código sin borrar: UFO (Nivel 7), rana (Nivel 2), sonda/ojo/speeder/torreta/organismo/popcorn/caza/semillero, mosquito/libélula/polilla, luciérnagas (`FIREFLIES_ENABLED`).
- **Tabla nueva:** 48 eventos, **133 unidades**, 14 familias del contrato (mosca común 40, avispa 18, mosca verde 20, hormiga 11, mariquita 10, nube 9, gusano A 6, gusano B 5, escarabajo 5, araña 4, caracol 2, tortuga, hongo cañón, robot caminante). Más **13 hongos de jardín** fijos. Tres zonas de combate de **5 oleadas** cada una (X=112 macizo, 220 huerta, 255 sombra).
- **Especies nuevas jugables** (`AssetFauna` data-driven + 2 clases): mosca común (`dash`: vuelo errático, embestida con aviso 0,5 s), mosca verde (nuevo modo `zigzag`: zigzag y gotas lentas apuntadas), nube de moscas (`whole_body`: un solo hurtbox, 24 HP: la bomba de 32 la limpia), gusano A (nuevo modo `burrow`: bajo tierra no se ve ni se apunta, marca en el suelo 1,0 s, erupción, 2,6 s vulnerable, vuelve a enterrarse), gusano B (`lunge` a ras), tortuga (`BeeGardenTurtle`, tanque ×2 con 220 HP y golpe de caparazón con anillo de aviso 0,9 s) y hongos de jardín (`BeeGardenMushroom`: destructibles no sólidos que sueltan 1 polen, restaurados por el checkpoint; solo el hongo cañón dispara).
- **Arco:** césped (X 0–68) → macizo (68–179, regadera en X=128) → **valle de respiro** (sin eventos de X=179 a 205, checkpoint 1 en X=190, dos frascos de miel y una bomba en X=192–200) → huerta (205–250, tortuga como puerta dura en X=232) → sombra (252–287) → checkpoint 2 (X=281) → **robot caminante con escoltas** (avispas y moscas) en X=294, que cierra el nivel. Sin UFO: tras el robot el sector se completa con una carrera corta (`ROSTER_RUN_OUT_SCROLL`).
- **Ajustes de balance** (constantes): `ROUTE_DAMAGE_SCALE` 0,22 → 0,8 (hay menos enemigos con disparo), `ARENA_MIN_SECONDS` 22 → 28, ataques más frecuentes en las especies nuevas (`LEVEL_TUNING`), daños y recuperaciones de las moscas/gusanos, hongo y suministro previo al robot en X=285–287.
- **Medición del bot** (Normal, Base, sin Modo Miel ni pausa de impacto; `validate_bee_pacing_v01`):

| Métrica | Resultado |
| --- | --- |
| Llegada al robot caminante (último encuentro) | 344,7 s (5,7 min); nivel completo a 375,9 s (6,3 min) |
| Mayor hueco sin amenaza fuera del valle | 4,8 s |
| Valle de respiro | 17,9 s (objetivo ~20 s; el test exige 12–22 s) |
| Vida perdida antes del robot | 52 (objetivo 45–70) |
| Máx. simultáneas ruta / zonas medidas | 5 / 4 (topes 7 / 10; el bot mata rápido las unidades débiles) |
| Zonas | 3 × 36 s |

- **Tests:** nuevo `validate_bee_level01_roster_v01` (familias permitidas/prohibidas, momentos que salieron, arco, valle con suministros, hongos, nube, gusano A con marca de 1 s, gusano B, tortuga, código conservado). `validate_bee_garden_toad_v01` ahora usa el escenario del Nivel 2 y maneja la rana directamente (sin tabla, scroll ni director del Nivel 1). 20 tests del flujo antiguo pasaron a `roster_only = false` + `EVENTS_LEGACY`; `validate_bee_level_01_vertical_slice` y `validate_bee_pacing_v01` se reescribieron para el elenco (valle como excepción de ≤5 s, entrada al último encuentro 330–420 s, daño 45–70).
- **Para jugar:** Nivel 01 en Normal: mirar moscas en V, la nube, el gusano que marca el suelo, el valle de respiro con frascos y bomba tras el checkpoint, la tortuga y su anillo, hongos que se rompen en polen y el robot con escoltas al final.

Verificación: reimportación y suite completa **92/92 PASS** (logs `dev/lote12_2_*`; primera pasada tras el cambio: 70/91, los fallos eran tests atados a la tabla anterior).

## Etapa 3 — Robot caminante como mini-jefe y tarántula como jefe final

### 3.1 Robot caminante (mini-jefe, checkpoint 2)

- **Archivos:** `scripts/levels/walker_miniboss.gd` (`WalkerMiniboss`, hereda de `GroundWalkerEnemy`: mismo modelo, animaciones y escena base), `scenes/levels/walker_miniboss.tscn` (escena heredada), `scripts/levels/bee_ground_shockwave.gd` (onda de suelo compartida con la tarántula).
- **Puerta X=294** (`"miniboss": true`): primera oleada con el robot (avispa + 2 moscas comunes) y segunda oleada (`escort_wave`: avispa, mosca verde, mosca común) cuando baja al 60 % de vida o a los 14 s. **6 escoltas** en total.
- **Cañón dorsal:** carga + línea de aviso de **0,5 s**; la línea se fija al final del aviso y dispara una ráfaga de 3. El cañón tiene **vida propia (70)**; al romperlo explota, se oculta la malla `Cylinder` y pierde ese disparo (sigue pisoteando más seguido).
- **Pisotón:** banda de aviso en el suelo (0,6 s), luego una onda que corre a ambos bordes a ras de suelo (1,25 m de alto): se esquiva volando por encima. No es un proyectil: **la pirueta no la destruye** (solo da su invulnerabilidad de 0,35 s).
- **Ojo amarillo:** punto débil ×2 dentro del cuerpo (un disparo cuya línea pasa a 0,42 m del ojo). El auto-apuntado apunta al cuerpo a la altura del ojo; el cañón es un tiro deliberado con el mouse.
- **Vida 640** (Normal) con tope de daño sostenido (3,9 %/s de la vida, reserva 30) para que Spread no lo derrita. Barra propia "ROBOT CAMINANTE". **Explota al caer** (cadena de explosiones + estallido final); no cuenta como liberado.

### 3.2 Tarántula (jefe final, atardecer)

- **Archivos:** `scripts/levels/tarantula_boss_01.gd` (`TarantulaBoss01`), `scenes/levels/tarantula_boss_01.tscn`, `scripts/levels/tarantula_drop_spider.gd` (arañas colgantes). Misma estructura que el jefe UFO del Lote 10: barra con marcas de fase, registro `hazards` con el aviso de cada ataque, tope de daño por segundo (`limit_hull_damage`), bomba = 8 % de su vida, miel entre fases, checkpoint de jefe.
- **Entrada:** tras el robot, respiro de 2,6 s (miel si Bee está bajo 70 %, bomba si tiene menos de 2) y la tarántula entra caminando por la derecha (X≈296, atardecer completo).
- **Fase 1 (100–75 %):** abanico de telaraña desde la boca (aviso 0,6 s), pisotón con onda (0,65 s), arañas pequeñas que bajan por un hilo en la columna de Bee (el hilo es el aviso, 0,7 s; un par de disparos las liberan).
- **Fase 2 (75–50 %):** hilos que bajan (aviso 0,75 s) y barren la pantalla hasta 3,0 m de altura (por debajo hay pasillo); invoca moscas (2 llamadas de 2 moscas, se retiran solas a los 10 s); **patas blindadas** (los disparos en las patas se absorben); tras cada ataque grande el **implante del abdomen queda expuesto 1,8 s (×2)**: se abre la tapa dorsal y el núcleo late.
- **Fase 3 (50–20 %):** **embestida** a lo ancho con banda roja de **0,8 s** mientras retrocede (carga previa), cruza al otro lado y se da vuelta; **miel** al entrar (mitad de la pelea).
- **Fase 4 (<20 %, furia):** **cortina de telaraña** con dos huecos seguros (aviso 0,6 s) y **embestidas encadenadas** (dos, cada una con 0,8 s).
- **Reglas:** nunca encadena un ataque que cierra carril (pisotón, embestida, cortina) mientras los hilos barren (abajo vs. arriba sería imposible); la telaraña es disparo común (la pirueta la destruye), **el pisotón y la embestida no**. Vida 1200 (Normal), tope 1,3 %/s (Fácil 1,15 %/s), reserva 18; el implante expuesto paga la mitad del tope. RNG con semilla: cada pelea se juega igual (mediciones reproducibles).
- **Liberación:** al romper el implante queda **LIBERADA**: se ocultan el dispositivo y los brazaletes, colores cálidos, texto "LIBERADO", se calma y se retira caminando; luego 10 m de carrera y **"SECTOR DESPEJADO · LIBERADOS n/N"** (la tarántula cuenta como animal). Puntaje de jefe en el combo.
- **Modelo:** el implante existe como pieza separada en el GLB (`implant_core`); **no se inventó ninguna malla**. Las placas alien que el contrato no quiere (flancos, guarda del tórax, sensor) se ocultan en tiempo de ejecución; detalle en `docs/art/AUDITORIA_ASSETS.md` («Tarántula: piezas»).

### 3.3 Medición con el bot

Bot de las peleas (igual criterio que el del UFO): 3 toques/s, 60 % apuntados, reacciona a cada aviso pero uno de cada dos tarde (con la mitad del aviso ya gastada), ve la mitad de los disparos que le vienen; con Spread la munición es infinita (peor caso de daño). Daño = HP perdido acumulado (la miel no se resta). Tests: `validate_bee_tarantula_boss_v01`, `validate_bee_walker_miniboss_v01`.

**Tarántula** (desde fase 1 hasta la liberación):

| Dificultad / arma | Duración | Daño recibido | Notas |
| --- | --- | --- | --- |
| Normal / Base | 86,2 s | 69 | 4 fases, 17 ventanas del implante, aviso mínimo 0,60 s, 0 daño sin aviso |
| Normal / Spread | 84,4 s | 66 | el tope de DPS iguala a Base |
| Fácil / Base | 90,8 s | 48 | |
| Fácil / Spread | 91,3 s | 44 | |

El daño lo hacen la telaraña (≈2/3) y las moscas (≈1/3): el bot esquiva pisotón, hilos, embestida y cortina aun reaccionando tarde. Normal/Base queda justo en el borde (69 de 50–70).

**Robot caminante** (activación → caída; daño de toda la puerta, escoltas incluidas):

| Dificultad / arma | Duración | Daño recibido |
| --- | --- | --- |
| Normal / Base | 36,8 s | 45 |
| Normal / Spread | 29,7 s | 5 |
| Fácil / Base | 31,5 s | 19 |
| Fácil / Spread | 27,4 s | 3 |

**Recorrido completo** (`validate_bee_pacing_v01`, bot invulnerable desde el robot): llegada al robot 344,7 s (5,7 min), robot 32,4 s, **entrada de la tarántula 379,7 s (6,3 min)**, nivel completo 489,0 s (8,2 min). Vida perdida antes del robot: 61 (objetivo 45–70; antes 52: el bot de ritmo ahora apunta al mismo punto que el auto-apuntado del juego). Hueco máximo fuera del valle 4,8 s; valle 17,9 s; máximos simultáneos ruta/zonas 6/4.

### Tests

- Nuevos: `validate_bee_tarantula_boss_v01` (estructura, implante ×2, patas blindadas, bomba 8 %, pirueta vs. telaraña/onda/embestida, liberación y cartel, 4 peleas) y `validate_bee_walker_miniboss_v01` (dos oleadas, cañón 0,5 s y rotura, ojo ×2, onda no destruible, explosión, 4 peleas en 25–40 s).
- Actualizados: `validate_bee_level_01_vertical_slice` (135 unidades con la segunda oleada, vida del mini-jefe, el nivel termina con la tarántula liberada) y `validate_bee_pacing_v01` (mide robot y tarántula, apunta como el auto-apuntado).
- Verificación: reimportación y suite completa **95/95 PASS**, sin `SCRIPT ERROR` (logs `dev/lote12_3b_*`). Primera pasada: 94/95 (Spread derretía al robot en 21 s: se agregó su tope de DPS; y el auto-apuntado del robot miraba a la altura del cañón, corregido con `auto_aim_point`). Siguen los avisos conocidos del renderer headless (`Parameter "material" is null`), presentes desde antes.

### Pendiente / qué falta

- Arte: clips de pisotón/embestida/calma para la tarántula y pisotón del robot; quitar del `.blend` las placas alien que hoy se ocultan en ejecución; malla de cañón roto.
- La araña del recorrido sigue con su nodo procedural (el GLB colgante solo se usa en las arañas del jefe).
- Balance sujeto al playtest humano: el bot esquiva los ataques grandes y el daño viene casi todo de la telaraña y las moscas.
- Música de jefe: no hay (fuera de alcance).
