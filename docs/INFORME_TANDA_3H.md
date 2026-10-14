# T3h — Avisos locales, bandas transparentes y bordes punteados

Rama `lote-16-titulo-intro`. El cambio es de presentación. Se conservan daños, shapes/volúmenes de impacto, velocidades, trayectorias, patrones y tiempos de aviso/ataque existentes. No se modificó el Aguijón ni se añadieron assets de arte.

## Qué dibujaba cada efecto

| Excepción | Emisor y archivo | Aspecto aplicado |
|---|---|---|
| a: franjas de suelo | Ant/WormB y carreras de fauna en `asset_fauna.gd`; ondas de pisotón en `bee_ground_shockwave.gd` | Corredores necesarios: relleno 0,25 y borde punteado, 0,60 solo los últimos 0,30 s. Miras simples: marca local en el destino, sin trayectoria opaca. |
| b: diagonal y banda roja de tarántula | `_begin_jump()` y `_begin_charge()` en `tarantula_boss_01.gd` | Bandas transparentes punteadas, mismo recorrido/alto; alfa 0,25 → 0,60 solo al final. La banda de carga se desplaza únicamente en Z a −0,4, detrás del cuerpo; no mueve la hitbox. |
| c: láser del Robot | `_begin_laser()` en `walker_miniboss.gd`: dos límites del sector antes de barrer | Avisos con puntos de alfa 0,25 (máximo 0,35), sin trazo sólido. Rayo celeste activo con centro brillante y caída de brillo/alpha hacia bordes. Conserva 16 m, shape 16×0,3×1,2, aviso 0,85 s y barrido 0,7 s. |
| d: tres líneas verticales y elipses | **Morteros**, `_mark_mortars()` en `walker_miniboss.gd`: tres X alrededor de Bee | Marca/anillo de suelo R0,7 conservado; columna suave con degradado de anchura y altura, sin contorno sólido. Aviso 0,85 s intacto; caída/impacto originales. |
| e: bloque bajo rojo durante Robot | **Salto/aterrizaje**, `_begin_jump()` en `walker_miniboss.gd` | Volumen visual original 2,2×2,8 m con relleno transparente y borde punteado, alfa 0,25/0,60 en fase final; sombra R1,3 y aviso 0,75 s intactos. No es un error de cubos ni otro enemigo. |
| f: domos y elipses | Gusano A, `_begin_mark()` en `worm_behavior.gd`; se identifican por separado las ondas activas en `bee_ground_shockwave.gd` | Domo visual de aviso con alfa ≤0,25 y borde punteado; elipse/aro de suelo ≤0,40. **Son señales de ataque, no escudos.** Las ondas activas quedan intactas; ver precisión abajo. |

Precisión sobre f: en el código anterior, el aviso de erupción del gusano era disco+aro, sin malla semiesférica; se le agrega una cubierta visual translúcida en ese mismo destino/radio, liberada con las demás señales. Los domos ya existentes de `BeeGroundShockwave` son **ondas que ya hacen daño**, no preavisos: se conserva su aspecto y su daño. No se oculta el peligro activo ni se convierte en escudo. La maqueta comparativa f incluye la interpretación visual del domo blanco del pedido; las escenas reales muestran el aviso efectivo de WormA.

## Cobertura del inventario de 38 variantes

`BeeAttackVisuals` centraliza el cambio: líneas de avisos naranjas, marcas de impacto y anillos. Se conserva la geometría de referencia que usan bots y se cambia su material; los marcadores agregados son mallas sin colisión. Carreras/cargas y bandas de suelo conservan una región suave porque no sería justo mostrar un solo punto para un ataque que daña a lo largo de un corredor.

Las excepciones que no pasaban por el helper naranja reciben el material explícitamente: cañón/láser/morteros/salto de Robot; red y destino de techo de tarántula; columna de Spider; guía de regadera; mira láser de WormA; sobrecarga de Wasp; carril clásico de Speeder; sector de EyeDrone; bandas/carga/columna de UFO reservado; lengua del sapo de Laguna. Las variantes compartidas de AssetFauna (mosca, mariquita, hormiga, escarabajo, gusanos, tortuga/perca/patinador y demás miras del inventario) heredan el tratamiento del helper. Se evita cambiar los rayos/proyectiles activos ajenos; seda que pasa a activa restaura su material original con `restore_active_line()`.

Se aplicó A como base, sin la nueva animación B del enemigo. Se mantienen sus anticipaciones existentes. La línea/malla del Aguijón queda intacta para T4b. La regadera activa y los otros rayos activos ajenos al láser del Robot conservan su aspecto original.

Valores visuales configurables en `scripts/vfx/bee_warning_style.gd`: `BASE_ALPHA=0,25`, `FINAL_ALPHA=0,60`, `FINAL_SECONDS=0,30`. El shader usa puntos de UV en una sola malla, sin crear decenas de nodos para cada guion. Columnas limitadas a 0,28; puntos de rayo a 0,35; domos a 0,25; elipses 0,35 y bordes 0,40. La animación final es un tween de material: no modifica la cuenta regresiva del ataque. Avisos cortos existentes fuera de 0,5–1 s (por ejemplo escupitajo de tarántula 0,45 s o anticipación por especie de 0,35 s) no se rebalancean en esta tarea.

## Capturas y contraste

- `docs/galeria_avisos_dia.png` y `_noche.png`: seis filas a–f, columnas **antes / ahora inicial / ahora últimos 0,3 s**, 1500×2400 px. Los paneles son comparaciones de geometría del código con emisor esquemático. La captura f distingue el aviso del gusano de una onda activa.
- `docs/avisos_en_escena_dia.png` y `_noche.png`: tres capturas del Nivel 1 (Tarántula banda de carga, Robot aviso+rayo celeste, hormiga y aviso de WormA), 1154×1944 px. Se instancian los enemigos reales y se llaman sus métodos reales de preparación; poses congeladas para revisar. No son una partida completa.
- Se revisaron copias de diagnóstico en escala de grises sobre los fondos reales de día y anochecer. Los puntos claros, elipses y cambios de transparencia permiten leer los límites sin depender solamente del color; la fase inicial es deliberadamente tenue. Validación del jugador en movimiento sigue pendiente, en especial banda de carga sobre vegetación densa y puntos del láser a distancia.

Herramientas: `tools/galeria_avisos_aplicados.tscn` (F6 o `-- --export-gallery`) y `tools/avisos_en_escena.gd` (script con GPU; `-- --capture-only` regenera imágenes sin benchmark). `tools/galeria_avisos.tscn` se conserva como navegador completo del inventario. Las galerías PNG antiguas de 38 filas fueron reemplazadas por las seis excepciones solicitadas; el catálogo de 38 no se borró.

## FPS

Intel Arc B580, Compatibility, 1154×648, sin VSync/tope, misma escena del Nivel 1 con poses congeladas, dos pasadas con orden inverso; 1 s de calentamiento y muestras de 3 s. Se cambia solo el estilo de los avisos, no el resto de presentación. Son mediciones de render, no duración/FPS de una partida con IA.

| Escena | Antes FPS medio | Ahora FPS medio | Diferencia |
|---|---:|---:|---:|
| Tarántula / banda | 128,3 | 136,0 | +7,7 |
| Robot / avisos y rayo | 151,3 | 152,0 | +0,7 |
| Hormiga / gusano | 139,3 | 145,5 | +6,2 |

Ninguna escena completa cae más de 3 FPS en esta corrida final; los aumentos no garantizan una mejora, dada la variación de reloj/carga entre muestras. Una corrida exploratoria anterior mostró −6,1 FPS en Robot, con alta variación entre muestras; por eso se midieron separadamente las capas de ese ataque:

| Robot, diagnóstico aislado | Media FPS |
|---|---:|
| Aspecto anterior | 145,5 |
| Avisos y rayo nuevos | 148,0 |
| Solo rayo con degradado | 149,6 |
| Solo pareja de avisos punteados | 150,0 |

En una muestra exploratoria, **la pareja de avisos punteados del sector costó unos 3,8 FPS**; en la medición final, con el patrón calculado sobre el plano local de la malla (sin depender del atlas UV del BoxMesh), no se reprodujo esa caída. Es la capa que conviene vigilar si aparecen bajones: superficies transparentes con shader de puntos. No hay evidencia estable para atribuir una caída mayor a 3 FPS a un aviso concreto en la versión final. Datos crudos finales en `dev/t3h_fps.json` y `dev/t3h_robot_fps.json`, sin commitearlos.

## Pruebas y problemas previos

Pasaron cinco pruebas dirigidas: `validate_bee_t3h`, `validate_bee_galeria_avisos`, `validate_bee_tanda3_legibilidad`, `validate_bee_combat_variety_v01`, `validate_bee_asset_fauna_v01`. La prueba nueva comprueba alfa inicial/final y su momento, geometría/posición intactas, vuelta a material de seda activa, tiempos/daño/shape reales del láser, tres carriles de mortero y daño/velocidad/shape de la onda. Capturas y benchmark con GPU sin errores de shader/script finales. No se corrió la suite completa.

**No quedaron verdes las dos pruebas largas de balance de jefes:**

- `validate_bee_walker_miniboss_v01`: exige 30–45 s, obtuvo 93,439 s.
- `validate_bee_tarantula_boss_v01`: exige 80–110 s, obtuvo 188,600 s; daño del bot 157 frente a rango 55–80.

Se repitieron con `BeeWarningStyle.enabled=false` (avisos anteriores) y dieron **exactamente los mismos tiempos y daño**. Es un fallo previo respecto a sus expectativas de balance, coherente con el cambio de daño por toque en T4c. No se alteraron ataques, daños ni tests de balance para disimularlo. Los logs de referencia quedan en `dev/t3h_robot_baseline.log` / `dev/t3h_spider_baseline.log`; el baseline de Robot también emite advertencias de material nulo en headless. Queda pendiente revisar esos tests/balance en una tanda autorizada para ello.

## Qué probar en Godot

Revisar de día y noche: lectura de bandas de suelo; diagonal y carga de Tarántula sin tapar su cuerpo; aviso punteado y bordes del rayo celeste del Robot; tres morteros con sus destinos; salto con bloque transparente; domo de gusano como aviso y ondas como daño activo. Confirmar que esquivar se siente igual y que el aumento de alfa ocurre solo justo antes de atacar. Aguijón continúa igual. Vigilar FPS especialmente durante el aviso de sector del Robot.
