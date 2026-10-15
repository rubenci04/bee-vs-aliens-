# T6c — FlyCloud: rendimiento y picadas

Rama `lote-16-titulo-intro`. Auditoría inicial previa a modificar FlyCloud. `project.godot` tiene un cambio local anterior que se conserva y no se incluye.

## Hallazgos antes del cambio

El GLB existente de nube tiene **8 moscas**, **213 nodos**, **120 mallas**, 4.896 triángulos y tres materiales fuente opacos. Cada `Fly_00`…`Fly_07` contiene una jerarquía de 26 nodos (15 mallas y articulaciones). No hay una IA ni un script por mosca visual: el `AssetFauna` administra la nube como bloque y `fly_trio_visual.gd` reproduce un AnimationPlayer común. El modelo completo usa un solo HealthComponent y una caja de daño para toda la nube; las moscas visibles no son blancos independientes.

Una nube instanciada inicialmente cuenta **224 nodos, 6 scripts adjuntos, 2 callbacks de scripts activos, 2 Area3D, 120 mallas con sombras, 0 luces y 1 AnimationPlayer**. Las dos áreas son hurtbox de la nube y hitbox del ataque grupal: no existen 16 áreas individuales. Por mosca: 26 nodos del rig, 15 mallas con sombra, cero scripts propios, cero áreas y cero luces; los costes de gestión/colisión se comparten por ocho.

Los tres materiales GLB son opacos; el estilo toon agrega pasadas de contorno y se mantienen sombras por cada pieza. La fábrica también puede añadir `HostileGlow` (núcleo/halo, con un material transparente y tween), por lo que se medirá tras esa preparación. El problema no es una supuesta IA repetida por cada mosca, sino principalmente la cantidad de piezas dibujadas/animadas y sus pasadas. El renderer y el juego real, no solo este conteo, determinarán la mejora.

## Banco reproducible antes de optimizar

`tools/fly_cloud_benchmark.gd` abre N1 real en el sector de nubes, fija cámara/director y protege Bee; el fondo, iluminación y render permanecen activos. Usa Compatibility, 1154×648, VSync/tope apagados, 3 s de calentamiento y tres muestras de 5 s. Guarda resultados/captura en `dev/t6c_benchmark_<variante>.json` y `dev/t6c_<variante>.png`.

El banco legado instancia ocho rigs originales y oculta cuatro moscas del último: **60 visibles y 64 animadas**. Conserva el coste residual de cuatro rigs ocultos; no se presenta como medición de exactamente sesenta rigs independientes. Esta limitación se declara para no atribuir todo ahorro a scripts. Los modelos y fuentes `.blend` no se modifican.

Primera muestra exploratoria, antes de preparar el glow de fábrica: Intel Arc B580, fondo vacío 196,77 FPS; 60 moscas visibles **68,48 / 69,33 / 68,60 FPS**. Después se añadió el glow real y se tomó el censo tras calentamiento: 227 nodos, 122 mallas (120 del rig + núcleo/halo), 120 con sombra, un material transparente, cero luces, seis scripts y dos callbacks activos por nube. Las cifras locales no reproducen exactamente los 33–51 FPS de la partida del dueño.

## FPS antes/después con GPU real

Godot **4.7.2 Compatibility/OpenGL 3.3**, Intel **Arc B580**, driver **32.0.101.9150**, resolución **1154×648**, misma escena/fondo/cámara, VSync y tope desactivados. No se ejecutaron otros bancos Godot simultáneos durante las muestras. Cada fila tiene tres ventanas de 5 s tras calentamiento. El FPS mínimo se calcula por ventanas completas de un segundo; no significa que cada frame individual tenga ese mínimo.

| Caso | FPS de las tres muestras | FPS medio | Mínimo por ventana de 1 s | Peor P99 de frame (ms) |
|---|---|---:|---:|---:|
| Antes, 60 visibles / rigs legados, con glow, medición inicial | 61,87 / 63,78 / 62,73 | 62,80 | No registrado en esa pasada | No registrado |
| Antes, repetición final de control en orden inverso | 64,25 / 65,14 / 64,43 | **64,61** | 62,46 | 19,273 |
| Después, estrés de **60 instancias** con picadas, límite elevado solo en laboratorio | 160,93 / 173,13 / 173,77 | **169,28** | **155,70** | 9,388 |
| Después, una nube de juego, **24 visibles + 36 reserva** | 188,22 / 187,21 / 187,85 | **187,76** | **184,64** | 6,866 |
| Después, fábrica real, **9 nubes / hasta 216 visibles** | 107,45 / 104,96 / 107,00 | **106,47** | **97,81** | 13,384 |

Comparación de estrés igualando sesenta instancias visuales: **64,61 → 169,28 FPS, unas 2,62×** en la repetición controlada. El banco supera 75 FPS medios y no tuvo ventanas de un segundo por debajo de 75 en los modos optimizados medidos. El P99 de nueve nubes tiene poco margen (13,384 ms ≈74,7 FPS en ese percentil de la peor muestra): no se promete que cada frame de una partida completa mantenga 75. Para certificar el caso concreto del dueño falta repetir con su resolución/configuración y disparos, demás enemigos y efectos reales; el director y Bee estaban detenidos en este banco y las nubes seguían activas.

El coste de dibujo reportado por el motor pasó de unas **4.628–4.694 llamadas** en el caso legado a **1.081** con una nube instanciada de 60 o 24; el fondo vacío rondaba 1.080. Nueve nubes de fábrica reportaron 1.105. No se redujeron geometría del jardín, resolución, calidad global ni sombras del escenario para lograrlo.

Datos: `dev/t6c_before_snapshot.json` conserva la medición tomada antes de cambiar la nube; `dev/t6c_benchmark_legacy.json`, `_optimized.json`, `_game.json` y `_encounter.json` registran las pasadas finales, con sus logs y PNG correspondientes. Son artefactos locales no versionados.

## Implementación localizada

La escena `scenes/levels/asset_fauna/fly_cloud.tscn` ahora usa `bee_fly_cloud.gd`, compatible con la fábrica/director `AssetFauna`. Un único callback de física administra formación, selección de atacantes, avisos, picadas, retorno, colisiones y retirada. Los miembros tienen descriptores pasivos de objetivo/salud/áreas, sin callbacks de movimiento ni AnimationPlayer por mosca.

`bee_fly_cloud_mesh.gd` combina en memoria la geometría de `Fly_00` del GLB existente, conservando UV, paleta y escala/orientación original. Se comparte una malla cacheada entre nubes y se dibuja con un MultiMesh por nube. El shader opaco anima las alas con los datos del administrador; no escribe ALPHA, no crea contornos adicionales ni luces y el MultiMesh tiene sombras desactivadas. Los modelos y `.blend` originales permanecen intactos. La geometría se centra sobre el blanco físico de cada mosca, y la anticipación escala solo el visual.

La población Normal es **60**, con **24 visibles como máximo y 36 en reserva**. La reserva es un contador: cero nodos, scripts, áreas o visuales propios. Cada hueco visible usa seis nodos (objetivo, salud, dos áreas y dos shapes), cuatro scripts pasivos y ninguna lógica de movimiento propia. Una nube normal tiene 148 nodos, 48 áreas asignadas y un único script de movimiento activo; solo las hurtboxes legibles/cercanas y las hitboxes de los atacantes están habilitadas. Las áreas de ataque tienen el shape desactivado fuera de la picada. Lejos de Bee y fuera de pantalla también se bloquea salud y se excluye el blanco de puntería. EASY conserva el escalado existente de la fábrica, aplicado a la población.

**Contrato de vida nuevo:** la entrada FlyCloud de `COMMON_HP` pasa de 66 a 60 y representa población, no vida de un cuerpo compartido. Cada miembro tiene **1 HP**, así que Base, un perdigón lateral de 1, Aguijón o bomba lo liberan con un solo impacto. La salud del administrador baja una unidad por miembro; no tiene un hurtbox gigante. No se duplica la población en otra tabla. Este contrato reemplaza para FlyCloud el TTK agregado de T6b: limpiar sesenta miembros puede requerir sesenta tiros Base (~5 s nominales), no los 22 impactos anteriores sobre una caja única. Las otras once familias y los jefes conservan sus vidas y armas.

Tras un impacto, la mosca abandona la formación y encoge durante 0,25 s, sin transparencia; luego entra una de reserva reutilizando el hueco. Una misma bomba/hitbox no puede volver a dañar el HealthComponent reciclado durante su misma activación. Las bombas limpian las moscas visibles alcanzadas, no la reserva oculta. La puntuación, polen, audio de liberación y contador del director se entregan **una sola vez al completar la nube**, evitando multiplicar por sesenta las recompensas/efectos. Los impactos conservan el feedback de proyectil habitual.

## Picadas y legibilidad

Cada 3,2 s disponibles se seleccionan alternativamente **2 y 3 miembros** en pantalla (hasta los que sobrevivan). Cada uno se separa de la formación y avisa durante **0,5 s**, con desfase de 0,08 s entre miembros, escala visual 1,0–1,12 y pulso cian en su material opaco. **No hay líneas, franjas, sectores ni otra geometría de aviso.** La dirección se fija al terminar el aviso; no persigue a Bee durante la picada.

La picada viaja a 8,5 m/s durante hasta 1,1 s y hace **3 HP de daño base**, como una bala enemiga chica, con los factores de dificultad/presión existentes. Un contacto aplica daño una sola vez y cambia al retorno; si falla, también retorna al agotar el vuelo, a 8 m/s. Los miembros supervivientes vuelven a formación y pueden participar en otra tanda. La pirueta evita el contacto por su invulnerabilidad; la mosca no se transforma en un proyectil rompible.

Se conserva el token global de patrones pesados: varias nubes no lanzan simultáneamente docenas de picadas. Una nube sin candidatos visibles no reserva ese token. El aviso nunca empieza desde fuera del encuadre, aunque la colisión cercana esté habilitada en el borde. Al liberar/retirar la nube se desactivan colisiones y objetivos; se libera el token y no quedan reservas atacando.

## Pruebas dirigidas

**14/14 aprobadas**: `validate_bee_t6c_cloud`, `validate_bee_t6a_health`, `validate_bee_lote15_hits_v01`, `validate_bee_t3j`, `validate_bee_t4f`, `validate_bee_tanda4c_weapons`, `validate_bee_weapons_powerups_v01`, `validate_bee_t4b`, `validate_bee_lote14_controls_v01`, `validate_bee_lote14_screen_v01`, `validate_bee_t1b_hud`, `validate_bee_galeria_avisos`, `validate_bee_galeria_propuestas` y `validate_bee_garden_identity_v04`. Resultados locales: `dev/t6c_related_results.json` y `dev/t6c_related_*.log`.

El test T6c comprueba fábrica Normal (60/24/36), ausencia de scripts de movimiento por mosca, MultiMesh opaco sin sombras/luces/AnimationPlayer, impacto Base y perdigón lateral de un daño, reposición desde reserva, bomba sin dañar reserva ni repetir en el mismo hueco, culling de colisión, dos/tres avisos individuales sin líneas, ventana de 0,5 s/escala pequeña, contacto de 3 HP, retorno, pausa y liberación final única. Un banco de disparo continuo con proyectiles físicos limpió los 60 miembros móviles y su reserva en **5,53 s** simulados, con Bee protegida y apuntado dirigido; no es un tiempo de jugador humano.

Se actualizaron únicamente los contratos reemplazados de FlyCloud en T6a, impactos Lote 15 y T3j. El banco T6a de nueve cajas compartidas/TTK agregado y el tween de toda la nube dejan paso al banco individual T6c; las once familias restantes conservan sus verificaciones de daño y vida. No se quitan pruebas de otros enemigos para ocultar fallos.

La prueba inicial detectó que un miembro repuesto fuera de pantalla debía mantener la salud bloqueada hasta activar su colisión: corregido. También se evitó usar readback de transform/color de MultiMesh con el renderer dummy, que retorna valores ficticios; headless comprueba los datos que recibe el shader y la geometría se verificó además con capturas GPU. Se corrigieron escala y centro del mesh combinado tras revisión visual. Las pruebas finales no emiten aserciones ni SCRIPT ERROR; algunos cierres headless conservan avisos de recursos, ya observados en tandas previas.

## Validación completa y alcance

Una única pasada completa: **88/132 aprobadas, 44 fallidas**, frente a 87/131 y 44 fallidas en T6b. La validación nueva T6c aprueba; **ningún fallo nuevo ni ningún caso histórico reparado**. Los 44 nombres son exactamente los registrados en [INFORME_TANDA_6B.md](INFORME_TANDA_6B.md): expectativas antiguas de combate/HitFlash/VFX, fixtures con escena nula y pruebas históricas de jefes, entre otros. Se mantienen sin arreglos ajenos a la nube.

Ejecución headless con hasta tres procesos aislados, `APPDATA` propio por test, `--fixed-fps 60` salvo las dos excepciones históricas de toon items/avispa. **27 procesos se cerraron tras emitir SCRIPT ERROR y seguir abiertos**, contados como fallidos; **cero timeouts**. No se repitió la suite completa. Resumen/outputs locales: `dev/t6c_full_results.json` y `dev/t6c_full_*.log`. No se presenta el repositorio como verde.

Se comprobó además la retirada de una nube cuyo proceso había sido congelado por el director/herramienta antes de liberarla: la animación opaca se reactiva para terminar y no deja nodos peligrosos o una reserva eterna. La prueba dirigida ampliada y la pasada completa final aprueban ese caso.

Los cambios de producción se limitan a la escena FlyCloud, su administrador/configuración/mesh compartido, el valor especial de población en la tabla de salud y tres conexiones de la fábrica (población, sin halo, sin hit-flash agregado). No cambian `asset_fauna.gd`, jugador, daño/perfiles de armas, lógica de Aguijón, jefes, calendario de oleadas, modelos ni `.blend`. El cambio local previo de `project.godot`, UIDs/importaciones automáticas y documentos ajenos quedan fuera del commit.

## Cómo probar

En Godot 4.7.2 abrir `D:\proyectos\bee_alien_3d`, escena `scenes/levels/bee_level_01_vertical_slice.tscn`, F6. Llegar a la presentación de nubes (sector de x≈138): cada nube muestra como máximo 24 moscas, cada una cae con un impacto y otra entra desde reserva. Observar dos/tres moscas que se separan, pulsan/crecen levemente y luego se lanzan; esquivar con movimiento vertical o pirueta. Deben volver a formación si sobreviven, sin líneas/franjas. Una bomba limpia las visibles alcanzadas; no elimina mágicamente la reserva.

Para reproducir los FPS sin jugar hasta ese sector, ejecutar desde el proyecto con el Godot console funcional:

```powershell
& 'C:\Users\rea_0\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --path . --resolution 1154x648 --script res://tools/fly_cloud_benchmark.gd -- --variant=optimized
```

Variantes: `legacy` = representación anterior; `optimized` = estrés de 60 instancias; `game` = 24 visibles/36 reserva; `encounter` = nueve nubes de fábrica. Ejecutarlas **de una en una**, sin `--headless` ni `--fixed-fps`, para que los resultados sean de render real. El límite elevado del estrés está restringido al laboratorio de desarrollo y no se habilita en una exportación standalone. El programa guarda JSON/captura en `dev/` y termina solo. La prueba funcional puede correrse con `--headless --fixed-fps 60 --script res://tests/levels/validate_bee_t6c_cloud.gd`.
