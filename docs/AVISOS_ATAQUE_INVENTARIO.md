# Tanda 3f — Inventario y galería de avisos

Rama `lote-16-titulo-intro`. **No se aplicó ninguna propuesta al juego.** Solo se agregaron herramientas de revisión, una prueba, este inventario y los dos PNG. No se modificaron scripts/escenas del juego, assets de arte, daños, colisiones ni tiempos de ataque.

Referencia: `ADENDA_GAMEPLAY_2.md` H-15/H-25/H-29/H-32. La adenda describe un video previo: se contrastó contra el código actual, incluyendo variantes fuera del roster. El archivo local de la adenda queda fuera del commit.

## Inventario de franjas, barras, líneas y columnas de aviso

Medidas en metros. Las dimensiones variables dependen de Bee, posición del emisor, cámara o destino bloqueado; la galería muestra un ejemplo representativo, no una medida universal. Duración = tiempo de aviso hasta iniciar el ataque, no duración del ataque activo.

`BeeAttackVisuals.line()` engrosa los avisos naranjas a un mínimo de 0,07 m, añade borde claro de 0,045 m por lado y eleva su alfa a al menos 0,72. Por tanto, 0,04/0,05/0,06 en la tabla son anchos solicitados: el resultado naranja suele medir 0,07 más bordes. Una mira que se bloquea cambia al naranja `LOCK_COLOR`. Estos ajustes actuales de Tanda 3 se conservan.

| Fila PNG | Aviso / emisor | Archivo | Tamaño y particularidades | Aviso actual | Uso |
|---:|---|---|---|---:|---|
| 1 | Hormiga · embestida | `scripts/levels/asset_fauna.gd` | Ant; franja a Y+0,5; 3,2 m × 0,14 m | 0.50 s | N1 |
| 2 | Gusano B · embestida | `scripts/levels/asset_fauna.gd` | WormB; 3,6 m × 0,14 m | 0.60 s | N1 |
| 3 | Escarabajo · carga | `scripts/levels/asset_fauna.gd` | StagBeetle; 6,5 m/s × 1,3 s = 8,45 m; ancho 0,5 | 0.80 s | N1 |
| 4 | Mosca · carrera | `scripts/levels/asset_fauna.gd` | FlyCommon; 6 m × 0,12 m; variante no escupitajo | 0.50 s | N1 |
| 5 | Nube · barrido | `scripts/levels/asset_fauna.gd` | FlyCloud; largo hasta Bee +3 m | 0.60 s | N1 |
| 6 | Mariquita · barrido | `scripts/levels/asset_fauna.gd` | Ladybird; largo hasta Bee +3 m | 0.80 s | N1 |
| 7 | Puntería de fauna | `scripts/levels/asset_fauna.gd` | Emisor→Bee, largo variable; AIM_LINE_WIDTH; duración por especie | 0.60 s | N1/variantes |
| 8 | Gusano A · mira del láser | `scripts/levels/worm_behavior.gd` | WormA; cabeza→Bee variable; rayo activo alcanza 11 m | 0.60 s | N1 |
| 9 | Araña · columna de caída | `scripts/levels/controlled_spider.gd` | Spider; ancho 0,5, alto desde cuerpo hasta lock_y; aro R0,55 | 0.85 s | N1 |
| 10 | Robot · mira del cañón | `scripts/levels/walker_miniboss.gd` | Walker; 12 m × 0,08; carga de cañón | 0.50 s | N1 |
| 11 | Robot · morteros | `scripts/levels/walker_miniboss.gd` | Top de encuadre→suelo; línea naranja; disco R0,7; MORTAR_FALL aparte | 0.85 s | N1 |
| 12 | Robot · salto | `scripts/levels/walker_miniboss.gd` | Columna 2,8 m de alto × 2,2 de ancho; sombra R1,3 | 0.75 s | N1 |
| 13 | Robot · onda de pisotón | `scripts/levels/bee_ground_shockwave.gd` | Walker; ancho de cámara +2 m; alto 1,25 | 0.60 s | N1 |
| 14 | Robot · sector de láser | `scripts/levels/walker_miniboss.gd` | Dos bordes de 16 m × 0,05; HOSTILE_CYAN | 0.85 s | N1 |
| 15 | Tarántula · salto diagonal | `scripts/levels/tarantula_boss_01.gd` | Trayectoria entre despegue/aterrizaje; ancho BODY_SIZE.y×0,8=1,44 | 0.80 s | N1 |
| 16 | Tarántula · salto al techo | `scripts/levels/tarantula_boss_01.gd` | Misma diagonal + barra oscura de 3,6×0,3 en destino de techo | 0.80 s | N1 |
| 17 | Tarántula · carga de suelo | `scripts/levels/tarantula_boss_01.gd` | Todo ancho visible +2 m; altura -0,1→2,5 = 2,6 m | 0.80 s | N1 |
| 18 | Tarántula · pisotón | `scripts/levels/bee_ground_shockwave.gd` | Todo ancho visible +2 m; alto 1,3 | 0.65 s | N1 |
| 19 | Tarántula · mira de red | `scripts/levels/tarantula_boss_01.gd` | Boca→punto bloqueado; TarantulaWebNet.WARNING | 0.50 s | N1 |
| 20 | Tarántula · péndulo | `scripts/levels/tarantula_boss_01.gd` | Columna entre techo y punto inferior variable | 0.60 s | N1 |
| 21 | Arañitas del jefe · caída | `scripts/levels/tarantula_drop_spider.gd` | top→hang_y; naranja antes, seda blanca durante descenso | 0.70 s | N1 |
| 22 | Tarántula · hilos barridos | `scripts/levels/tarantula_boss_01.gd` | Techo→THREAD_BOTTOM=3; varias columnas; patrón fuera de secuencia | 0.75 s | legado |
| 23 | Tarántula · cortina | `scripts/levels/tarantula_boss_01.gd` | Ya punteada: segmentos verticales 0,36×0,1 cada 0,55; huecos 1,7 | 0.60 s | N1 |
| 24 | Regadera · guía y franja | `scripts/levels/bee_level_01_watering_event.gd` | Guía 0,99×8,5; franja 1,6×0,14; disco R1,21 | 1.00 s | N1 |
| 25 | Avispa · sobrecarga | `scripts/bee_prototype/wasp_enemy.gd` | Largo distancia a Bee +3 m; ancho/profundidad 0,07 | 0.85 s | N1 |
| 26 | Mosquito · carrera | `scripts/levels/asset_fauna.gd` | 7 m × 0,12; especie fuera del roster N1 actual | 0.50 s | legado |
| 27 | Libélula · corredor ondulado | `scripts/levels/asset_fauna.gd` | WaveDragonfly; 17 m × 2×wave_amp=2,2 | 0.65 s | legado |
| 28 | Tortuga · rodar | `scripts/levels/bee_garden_turtle.gd` | Emisor→borde de cámara variable; ancho 0,5; no activa en roster | 0.90 s | reservada |
| 29 | Speeder · carrera | `scripts/bee_prototype/speeder_enemy.gd` | 13 m × 0,07; solo ram_mode | 0.75 s | legado |
| 30 | Speeder · carril clásico | `scripts/bee_prototype/speeder_enemy.gd` | 30 m × 0,05 × 0,05; lane_telegraph sin ram_mode | 0.70 s | legado |
| 31 | EyeDrone · sector | `scripts/bee_prototype/eye_drone_enemy.gd` | Dos bordes ±20°: ancho 0,05 / 0,025; laser_every | 0.70 s | legado |
| 32 | UFO · columna | `scripts/levels/ufo_boss_01.gd` | 1,5×7,5; disco R0,93; fases: aviso 1 /0,85 /0,7 /0,65 s | 1.00 s | reservado N7 |
| 33 | UFO · barrido de bandas | `scripts/levels/ufo_assault.gd` | Tres bandas variables en todo ancho; dos huecos libres; NOTICE | 0.80 s | reservado N7 |
| 34 | UFO · embestida | `scripts/levels/ufo_assault.gd` | Posición→ancla opuesta variable; ancho 1,5 | 0.80 s | reservado N7 |
| 35 | Perca · salto | `scripts/levels/asset_fauna.gd` | Superficie de agua→ápice 2,2..4,6; aro de agua | 0.70 s | Laguna |
| 36 | Patinador · embestida | `scripts/levels/asset_fauna.gd` | Strider; 3,6×0,14 sobre agua | 0.50 s | Laguna |
| 37 | Sapo · lengua | `scripts/levels/level_02_lake/lake_toad_boss.gd` | Lengua: aviso 7,5×0,12 | 0.70 s | Laguna |
| 38 | Sapo de paso · lengua | `scripts/levels/level_02_lake/garden_toad_encounter.gd` | 60% del ancho de cámara; ancho 0,12 | 0.60 s | Laguna |

La fila «Puntería de fauna» es el mismo dibujador compartido por FlyGreen, Snail, MushroomCannon, AlienFighter, SeedCarrier, Nymph y variantes de escupitajo de FlyCommon/WormB. Sus tiempos en `AssetFauna.KINDS`: FlyCommon/FlyGreen 0,5; Snail/Nymph/WormB/Fighter 0,6; Mushroom 0,7; SeedCarrier 0,8 s (mínimo general 0,4). La longitud siempre es boca→Bee y el bloqueo ocurre 0,3 s antes de disparar; puede ocultarse si Bee ya esquivó. Ladybird y FlyCloud tienen filas separadas de barrido, 0,8 y 0,6 s respectivamente. Hormiga además recibe tiros de `BeeImplantShooter`: su carga se anuncia en el propio implante, no agrega otra franja.

El robot no tiene una columna blanca de aviso independiente: las líneas naranjas reciben el borde claro compartido, y los morteros/saltos añaden discos de destino. La columna de araña combina rectángulo cian y aro; su hilo blanco natural persiste durante el movimiento. La cortina de la tarántula ya usa segmentos cortos separados, no una barra continua.

## Líneas relacionadas que no son avisos previos

| Elemento | Archivo | Tamaño / duración | Clasificación |
|---|---|---|---|
| Agua que cae | `scripts/levels/bee_level_01_watering_event.gd` | Cilindro alto 8,5 m, ancho 1,1 m; activo 0,5 s tras aviso de 1 s; daño 5 | Ataque activo, no sustituido por las propuestas |
| Rayo del ojo del robot | `scripts/levels/walker_miniboss.gd` | Largo 16 m, ancho 0,2 m; barrido de 0,7 s (`LASER_SWEEP`) | Ataque activo después de los bordes de sector |
| Rayo de WormA | `scripts/levels/worm_behavior.gd` | Largo 11 m; visual `LASER_WIDTH×1,4` = 0,196 m; activo 0,2 s (`LASER_ACTIVE`) | Ataque activo, separado de la mira previa de 0,6 s |
| Hilo de araña / jefe | `controlled_spider.gd`, `tarantula_boss_01.gd`, `tarantula_drop_spider.gd` | Seda de diámetro 0,05 m en araña; largos según techo/cuerpo; continúa durante caída/péndulo | Seda/ataque visible, no solo aviso |
| Red de tarántula | `scripts/levels/tarantula_web_net.gd` | Bola de hilos, rayos locales de 0,04 m; vida del proyectil | Ataque activo, no una franja de aviso |
| Aguijón / «rayo naranja» del video | `scripts/bee_prototype/bee_player.gd`, `bee_visual.gd`; H-15/H-32 de la adenda | En el código actual `start_melee()` hace embestida de 0,2 s; muestra cono cromado y estela de 0,25 s. No se encontró un dibujador de rayo largo Bee→blanco en ese recorrido | Solo inventariado; sin opciones A/B. La atribución del video era una inferencia y no confirma el efecto actual |
| Cono F4 / línea al objetivo de Bee | `scripts/levels/bee_level_01_crosshair.gd` | Dos rayos proyectados de 12 m y línea al blanco mientras F4 está encendido | Debug de puntería, no aviso enemigo; intacto |

Otros avisos que ya cumplen la idea de marca local: discos/anillos de erupción y salto del gusano, aro de bomba de polilla, puntos de minas y bolas de carga de implantes. `BeeShotWarning` agrega anticipación por especie de 0,35 s y flechas de borde para enemigos fuera de cámara; no son barras largas y no se cambiaron. La tarántula avisa su escupitajo con brillo de boca de 0,45 s. Esos tiempos menores de 0,5 s se registran como existentes, sin corregirlos en esta tarea.

## Opciones de la galería

Cada fila tiene tres columnas sobre el mismo fondo/cámara:

- **Actual:** geometría construida desde las medidas y colores del código; se usa el mismo helper de avisos cuando el juego lo usa, con sus bordes actuales. Se reconstruye una pose fija representativa: no se ejecuta el ataque ni se captura su IA en combate. El emisor gris es un símbolo esquemático, no el modelo del enemigo.
- **A:** aro cian pequeño en el impacto previsto con sector translúcido que se va llenando. Sin una franja de trayectoria. Para ataques distribuidos hay varias marcas puntuales; para caídas hay marca de suelo y otra a altura de contacto.
- **B:** marca magenta en el impacto más anticipación esquemática del emisor: ilumina el cuerpo, aumenta ligeramente su escala y añade un aro y señal corta de dirección. No se implementó esta animación en ningún enemigo real.

En ambas opciones se ensaya **0,75 s** de anticipación visual, configurable en el catálogo: dentro de 0,5–1 s. Es un tiempo de la maqueta, no un cambio al ataque. Solo para rayos aparece una trayectoria de puntos muy finos durante los últimos **0,25 s**, nunca una franja larga sostenida. Los PNG fijan la animación al 70 % (restan 0,225 s); abrir F6 permite ver el llenado y el pulso.

**Límites para decidir:** una marca de destino no alcanza por sí sola para explicar todos los peligros. Onda de suelo, carga del jefe, cortina y caída de agua afectan un corredor o varias alturas; por eso se ensayan varias marcas. Aun así, claridad del área y anticipación justa necesitan playtest antes de aplicar algo. Las dos opciones no alteran la trayectoria real ni ofrecen zonas seguras nuevas. Las marcas no garantizan que el resto del recorrido sea seguro.

La galería usa el fondo del Nivel 01 y sus perfiles reales de luz (`LightProgression`, progreso 80/310). «Noche» corresponde al anochecer violeta que hoy existe en el juego. Los tres paneles de cada fila usan igual escala de cámara; la cámara se amplía para filas de longitud extrema (carril de 30 m). Solo los avisos y el emisor esquemático cambian entre columnas. Ningún PNG se utiliza como asset del juego.

## Abrir, exportar y validar

- Abrir `tools/galeria_avisos.tscn` y ejecutar F6. Flechas izquierda/derecha: aviso; 1: día; 2: noche; E: regenerar ambas galerías.
- Exportación reproducible: `Godot --path . --resolution 1500x400 res://tools/galeria_avisos.tscn -- --export-gallery` (con GPU, no headless).
- Resultados: `docs/galeria_avisos_dia.png`, `docs/galeria_avisos_noche.png`; 1500×15200 px, 38 filas. Ampliar al 100 % y desplazarse verticalmente para leerlos.
- `validate_bee_galeria_avisos`: prueba headless dirigida aprobada; recorre los 38 originales/A/B, comprueba ausencia de áreas de daño y colisiones en las muestras, aislamiento de cámaras, llenado/anticipación, puntos tardíos exclusivos de rayos y cambio día/noche. Sin suite completa. Revisión adicional de PNG con GPU. Godot conserva avisos de recursos al cerrar la escena del nivel; no hubo errores de script ni aserciones.
- Archivos agregados: catálogo, herramienta y escena bajo `tools/`; prueba bajo `tests/levels/`; este inventario y los dos PNG bajo `docs/`. `dev/` y archivos ajenos no se incluyen en el commit.

Pendiente: elegir A/B por fila mirando ambas luces, y validar los peligros que ocupan una zona entera antes de una futura implementación. **El juego sigue exactamente con sus avisos anteriores.**


## Actualización T3j — clasificación y decisión aplicada

La tabla histórica de arriba conserva las medidas/tiempos de T3f. La presentación vigente es T3j para enemigos comunes y T3h para jefes/ambiente. No confundir avisos con ataques activos.

| Filas históricas | Emisor / aviso | Clase | Decisión T3j |
|---|---|---|---|
| 1 | Hormiga: franja y línea fina naranja de embestida a ras del suelo | Común | Sin marca; agacha el cuerpo y pulso magenta |
| 2 | Gusano B: franja de embestida | Común | Sin marca; pulso amarillo |
| 3 | Escarabajo: corredor de carga | Común | Sin marca; pulso azul |
| 4 | Mosca: carrera | Común | Sin marca; pulso cian |
| 5 | Nube de moscas: barrido | Común | Sin marca; pulso cian del grupo |
| 6 | Mariquita: barrido | Común | Sin marca; pulso carmesí |
| 7 | Miras FlyGreen, Snail, MushroomCannon, AlienFighter, SeedCarrier, Nymph y variantes FlyCommon/WormB | Comunes | Sin líneas ni sus marcas hijas; pulso según disparo |
| 8 | Gusano A: línea celeste vertical/diagonal de mira | Común | Mira invisible; láser activo intacto |
| 9 | Araña colgante: columna y aro suspendido de caída | Común | Sin marca; pulso blanco del cuerpo; seda natural intacta |
| 10–14 | Robot: cañón, morteros, salto, pisotón y sector láser | Minijefe | Se mantienen exactamente como T3h |
| 15–20 | Tarántula: diagonales/techo, carga/banda, pisotón, red, péndulo | Jefe | Se mantienen exactamente como T3h |
| 21 | Arañitas de caída invocadas por Tarántula | Comunes auxiliares | Sin columna previa; modelo visible durante el aviso y pulso blanco; seda activa reaparece al caer |
| 22–23 | Tarántula: hilos barridos y cortina | Jefe | Se mantienen |
| 24 | Regadera: guía/franja | Ambiente, no enemigo común | Se mantiene; fuera del alcance |
| 25 | Avispa: sobrecarga | Común | Sin línea; anticipación violeta del cuerpo |
| 26 | Mosquito: carrera | Común legado | Sin línea; anticipación del cuerpo |
| 27 | Libélula ondulada: corredor | Común legado | Sin banda; anticipación del cuerpo |
| 28 | Tortuga: rodar | Común reservada | Sin línea de suelo; conserva retracción y añade pulso del cuerpo |
| 29–30 | Speeder: carrera y carril clásico | Común legado | Sin líneas; pulso del modelo |
| 31 | EyeDrone: sector de láser | Común legado | Sin bordes previos; rayo activo intacto |
| 32–34 | UFO: columna, bandas y embestida | Jefe reservado N7 | Se mantienen |
| 35 | Perca: salto | Común de Laguna | Sin columna; conserva solo aro local de superficie |
| 36 | Patinador: embestida | Común de Laguna | Sin franja; anticipación del cuerpo |
| 37 | Sapo de Laguna: lengua | Jefe | Se mantiene |
| 38 | Sapo de paso: lengua | Encuentro especial derivado de BeeLakeToadBoss | Se mantiene; no es fauna común del roster |

Adicionales fuera de las filas de líneas: gusano A de erupción pierde disco y domo de vidrio con elipse naranja; queda un único aro cian sin relleno, alfa 0,35, radio leído de su esfera de daño sin modificarla. El salto del mismo gusano conserva solo ese aro en destino. El aro de carga de BeeImplantShooter desaparece para todos los comunes. El aro suspendido de la bomba de polilla desaparece. Las poses y brillos existentes de fauna sin líneas (por ejemplo ControlledDragonfly) se conservan.

Aguijón de Bee, cono F4, proyectiles, láser activo de WormA/EyeDrone, domos de ondas que ya dañan y redes/seda activas no son avisos previos: **intactos**.


La revisión de “cualquier otro común” además encontró `PopcornDrone._show_kamikaze_line()` (Swarm): línea cian de 14 m, `KAMIKAZE_WARNING=0,5 s`, no estaba en las 38 filas. También se oculta y pasa a pulso del dron, sin cambiar su carrera. La torreta común `GroundTurretEnemy` conserva solo el aro de destino del mortero, con radio `PUDDLE_RADIUS` y alfa 0,35; su bola de carga externa se sustituye por el pulso del cuerpo. El caminante **común legado** `GroundWalkerEnemy` recibe pulso en vez de la bola de carga; no es `WalkerMiniboss`, cuyos avisos permanecen intactos. La libélula `ControlledDragonfly` ya no tenía líneas: conserva las alas/implante anticipados, con escala de alas limitada a 1,12 y pulso del cuerpo, dejando sus hurtboxes fuera del nodo escalado. Otras señales locales que ya pertenecen al propio enemigo (por ejemplo el núcleo del organismo) se conservan.
