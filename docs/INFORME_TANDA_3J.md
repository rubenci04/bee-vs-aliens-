# T3j — Enemigos comunes sin avisos de línea

Rama `lote-16-titulo-intro`. Cambios de presentación exclusivamente. Se conservan daños, shapes/radios de impacto, velocidades, trayectorias, bloqueos de dirección, patrones, cadencias y tiempos de aviso/ataque. No se agregan assets.

## Auditoría y alcance

Clasificación completa de las 38 filas históricas en la actualización T3j de `AVISOS_ATAQUE_INVENTARIO.md`. Se contrastaron los emisores reales, incluidos los legados.

| Grupo | Avisos eliminados de pantalla | Señal vigente |
|---|---|---|
| Ant | Franja de embestida, línea fina naranja a ras del suelo y aro de carga del implante | Se agacha visualmente y pulsa magenta; nada en el suelo |
| FlyCommon / Mosquito | Carrera, mira de escupitajo | Anticipación y pulso del cuerpo |
| FlyGreen | Mira de ácido | Pulso verde del ácido |
| FlyCloud | Banda de barrido | Pulso cian del grupo completo |
| Ladybird | Barrido / aro de carga | Pulso carmesí |
| StagBeetle | Corredor de carga / aro de carga | Pulso azul; se conserva la pose de pinzas |
| WormB | Franja de embestida / mira de barro | Pulso amarillo |
| Snail | Mira de escupitajo | Pulso cian |
| WormA | Mira celeste vertical/diagonal del láser, disco y domo de vidrio/elipse naranja de erupción; disco de salto | Pulso en la cabeza/cuerpo cuando está expuesto y un único aro cian en el impacto de suelo, alfa 0,35 |
| Spider | Columna y aro suspendido de caída / aro de carga del implante | Pulso blanco del cuerpo; hilo natural conservado |
| MushroomCannon | Mira de esporas | Pulso magenta |
| WaveDragonfly | Corredor ondulado / aro de carga | Pulso cian del cuerpo |
| Moth | Aro suspendido de preparación de bomba | Anticipación del propio cuerpo |
| AlienFighter, SeedCarrier, Nymph | Miras compartidas de AssetFauna | Pulso del propio modelo |
| Perch / Strider | Columna de salto / franja de embestida | Anticipación del modelo; Perca conserva solo el aro de superficie de impacto |
| Turtle (reservada) | Línea de rodar / aro de escupitajo dirigido a Bee | Retracción/pose original y pulso verde de bilis |
| Speeder | Línea de carrera / carril clásico | Pulso del modelo |
| EyeDrone / Probe | Líneas del sector y bolas externas de carga | Pulso del modelo; rayo activo intacto |
| PopcornDrone (Swarm) | Línea cian de 14 m del kamikaze, ausente del inventario histórico | Pulso del dron; dirección, velocidad y duración originales |
| GroundTurretEnemy común | Bola externa de carga | Pulso y solo aro del impacto de mortero, radio PUDDLE_RADIUS, alfa 0,35 |
| GroundWalkerEnemy común legado | Bola externa de carga | Pulso del modelo; no confundir con WalkerMiniboss |
| ControlledDragonfly | Ya no tenía líneas | Conserva aviso de alas/implante, escala visual de alas acotada a 1,12 y pulso del cuerpo |
| Arañitas auxiliares TarantulaDropSpider | Columna naranja previa | Modelo visible y pulso antes de caer; seda activa aparece al empezar el descenso |

Otros avisos ya locales en el modelo, como el núcleo del organismo legado, se conservan. No se cambia el elenco ni se activan especies reservadas.

**Conservados:** todos los avisos del Robot caminante minijefe (cañón, morteros, salto, onda, sector láser) y de la Tarántula (diagonales, techo, carga/banda, onda, red, péndulo, cortina y hilos); jefes UFO/N7 y sapos especiales; regadera y otros eventos ambientales. Quedan fuera de los comunes o del alcance. Sus scripts no cambian. También quedan intactos el Aguijón de Bee, F4, proyectiles y ataques activos: láser de gusano/EyeDrone, seda, red y ondas que hacen daño.

## Implementación y constantes

`scripts/vfx/bee_common_attack_cue.gd` concentra `SECONDS=0,5`, `MAX_SCALE=1,12`, `ENERGY=2,2` y `RING_ALPHA=0,35`. Reutiliza los colores reales de `BeeShotStyles`/`BeeFacetShotStyles` y los parámetros emisivos de materiales existentes; restaura los materiales y escalas al terminar, sin añadir una segunda pasada de dibujo. Las copias se cachean en la propia malla y no modifican materiales compartidos de otros enemigos.

`BeeShotWarning.volley()` coloca el pulso en los últimos 0,5 s de la preparación existente. No alarga ni adelanta el ataque. Se conserva el sonido de aviso aprobado. Las marcas de trayectoria quedan sin capas de render, incluidas sus marcas hijas: se retienen los handles geométricos para no alterar los bloqueos de apuntado, referencias de bots o la activación de ataques. No se dibujan.

La hormiga conserva la rotación original del rig que contiene hurtboxes; solo el modelo visual recibe la contrarrotación de agacharse. Los impactos puntuales del gusano leen el radio de la esfera existente y dibujan un aro horizontal sin relleno; no alteran esa esfera. El gusano enterrado no se hace visible antes de erupcionar: en ese caso el aviso es únicamente el pequeño aro de impacto.

Liberar/cancelar un ataque interrumpe el pulso antes de devolver al animal sus colores naturales. Las arañitas auxiliares usan una bandera de inicio del descenso para que mostrar el modelo durante el aviso no impida activar su daño: mismos 0,7 s de preparación, 0,25 s de caída, daño 5 y radio 0,42 que antes.

## Verificación visual

`docs/avisos_enemigos_comunes_antes_despues.png`: 32 filas, cuatro columnas **antes día / ahora día / antes noche / ahora noche**, 2308×10368 px. Incluye todas las familias comunes del roster N1, variantes de gusano, nube, comunes legados y reservados que tienen avisos en estos dibujadores. Abrir al 100 % y desplazarse verticalmente para leer nombres y observar el momento de anticipación.

Modelos y métodos de ataque reales, fondo del nivel y perfiles reales de iluminación a progreso 80/310. Poses preparadas/congeladas para revisar, no una grabación de una partida. La columna antes usa los scripts de HEAD previo a T3j; se conservaron y restauraron íntegramente las copias de trabajo después de capturar. Las capturas intermedias/logs quedan en `dev/`, fuera del commit. Herramienta reproducible: `tools/avisos_comunes.gd`, ejecución con GPU mediante `--script`; combina las capturas anteriores de `dev/t3j_before_*.png` con las actuales.

Se revisaron en detalle hormiga, nube y erupción del gusano en ambas luces: la hormiga destaca por su pulso magenta y agachado; la nube por el pulso cian conjunto, sin banda. El pequeño aro del gusano mantiene visible el impacto mientras el animal permanece enterrado. La lectura durante movimiento y disparos simultáneos requiere playtest humano.

## FPS

Intel Arc B580, Compatibility, 1154×648, VSync/tope apagados. Misma escena con **20 moscas comunes** detenidas en su aviso; todos los hijos con IA también detenidos. Un segundo de calentamiento y tres muestras de 3 s por versión. Es coste de render de un enjambre de comparación, no FPS de una partida completa.

| Versión | FPS medio | Muestras |
|---|---:|---|
| Antes | 134.7 | 134.9, 129.9, 139.4 |
| Ahora | 136.9 | 135.7, 137.8, 137.3 |

Diferencia media: **+2.2 FPS**. No se observa caída en esta medición final.

Una implementación exploratoria con overlay en todos los cuerpos costaba unos 37 FPS y se descartó. La versión final utiliza emisión de los materiales existentes, sin esa pasada extra. Datos crudos en `dev/t3j_fps_before.json` y `dev/t3j_fps_after.json`, sin commitear. La variación entre muestras impide interpretar pequeñas diferencias como una mejora garantizada.

## Pruebas / pendientes

Pasaron seis pruebas dirigidas: `validate_bee_t3j`, `validate_bee_asset_fauna_v01`, `validate_bee_combat_variety_v01`, `validate_bee_controlled_spider_v01`, `validate_bee_t3h`, `validate_bee_liberation_v01`. No se ejecutó la suite completa. La nueva prueba comprueba ausencia de marcas comunes, radio/daño y hurtboxes intactos, pulso/restauración/cancelación, aro de gusano, conservación del láser activo/avisos de Robot y activación correcta de las arañitas auxiliares. Render/capturas finales sin errores de script o shader.

Pendiente humano: comprobar en Godot, de día y noche, hormigas agachándose sin franja, nube pulsando sin banda, mosca verde/avispa/caracol/hongo anticipando antes de disparar, gusano con un único aro de suelo y sin domo, araña con seda activa y sin columna previa. Confirmar que los avisos de Robot/Tarántula y el Aguijón se ven igual. Si el pulso es demasiado fuerte o tenue, ajustar `ENERGY`; para tamaño, `MAX_SCALE`; `SECONDS` cambia solo la ventana visual, nunca el reloj del ataque.
