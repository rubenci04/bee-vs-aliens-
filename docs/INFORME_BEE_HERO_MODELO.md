# Bee héroe v02 — informe de modelo e integración

Fecha: 2026-10-13. Rama de tarea: `lote-15b-bee-modelo`, creada desde `lote-14` después del resguardo **0b65701**. Inventario, modelos completos/lite y cuatro vueltas de revisión terminados. Entrega de arte lista, sin sustituir el Bee jugable.

## Etapa 0 — preparación

Se revisaron AGENTS.md, CLAUDE.md, la plantilla y el checklist. El estado inicial tenía cambios del Lote 15, plugins/addons, demo y herramientas pendientes. Se conservaron en un commit de resguardo en la rama original, sin modificar su contenido ni ejecutar reset/clean/stash/amend. Las eliminaciones de tres UID de herramientas del Lote 13 ya figuraban en el estado inicial y se registraron tal como estaban.

Los cachés locales `dev/godot_user_lote10/` y `tools/art/__pycache__/` se mantienen en disco y se excluyeron del resguardo mediante `.gitignore`. No se cambiaron scripts de gameplay durante esta tarea; el commit de resguardo contiene los cambios que ya existían.

Blender disponible y probado: `C:/Program Files/Blender Foundation/Blender 5.2/blender.exe`, versión **5.2.1 LTS**. Apertura de fuentes en modo background, sin guardarlas; hashes antes/después intactos.

## Referencias requeridas — inventario inicial y resolución

Al iniciar la etapa 1, `concept_art/shared/bee_hero/` no existía en el checkout. No se encontró una hoja de modelo de cuatro vistas ni una hoja de detalles del nuevo Bee en `concept_art/`, `art_reference/` o `docs/art/`.

Se inspeccionaron estas imágenes candidatas en Descargas, sin copiarlas al proyecto ni tratarlas como sustituto de la hoja faltante:

- `C:/Users/rea_0/Downloads/bee model.jpg`: recorte del héroe con cara decidida, taladro trasero, propulsores y cañón de antena.
- `C:/Users/rea_0/Downloads/Abeja heroica escapa del control alienígena.png`: composición del jardín, héroe y enemigos, sin cuatro vistas.

También se revisó el catálogo de imágenes de Descargas para localizar una posible hoja: no apareció una hoja de cuatro vistas del Bee. El usuario entregó luego la carpeta requerida. Antes de modelar se abrieron **todas sus imágenes**: `bee model.jpg` y `Lámina de abeja mecánica blindada.png` (cuatro vistas). No hay una hoja adicional de detalles en la carpeta. La imagen recortada y las cuatro vistas gobiernan el diseño; las imágenes de Descargas no sustituyeron la hoja.

## Etapa 1 — modelo actual usado en juego

| Elemento | Ruta / dato |
|---|---|
| GLB actual (v01, nombre histórico) | `assets/models/shared/bee/bee_mid_poly.glb` |
| Fuente correspondiente | `dev/style_test/blend/bee_style_b.blend` |
| Generador correspondiente | `dev/style_test/tools/create_bee_style_b.py`, usa `style_b_common.py` |
| Fuente anterior, **no** la mid-poly actual | `art_source/blender/shared/bee/bee_alien_visual.blend`, 1.144 tris |
| Generador anterior | `tools/bee_prototype/create_bee_visual.py` |
| Escena jugable | `scenes/bee_prototype/bee_player.tscn` |
| Presentación | `scripts/bee_prototype/bee_visual.gd` |
| Laboratorio v01 | `scenes/bee_prototype/visuals/bee_player_visual_lab.tscn` |
| GLB/fuente mid-poly | **4.540 triángulos, 35 mallas, seis materiales** |

La fuente mid-poly existe, aunque el manifiesto anterior muestra `—` como fuente. Se encontró en la carpeta de pruebas de estilo; no se movió ni reexportó. Su generador aún escribe en la ruta histórica `assets/style/models/`; **no ejecutarlo para esta tarea**, porque regeneraría v01 en otra ruta. Otros assets recientes se producen con builders en `tools/art/`, fuentes en `art_source/blender/levels/…`, exportaciones GLB, paletas embebidas y wrappers de laboratorio. Los nuevos v02 deberán guardarse únicamente en las rutas solicitadas `art_source/blender/shared/bee_hero/` y `assets/models/shared/bee_hero/`.

### Medidas y transformación exactas

Medición leyendo los vértices reales del GLB y aplicando la jerarquía de transformaciones, no una aproximación a partir de cajas locales rotadas:

- Godot **+Y arriba, frente −Z**, laterales ±X. Blender: +Z arriba, frente +Y.
- Raíz `BeeModel`: posición `(0,0,0)`, escala `(1,1,1)`, rotación identidad. Origen en el centro del tórax (`Thorax`), **no en el suelo**.
- Todos los nodos del GLB tienen escala 1. Algunas partes (patas, antenas, cejas, aguijón) conservan rotaciones locales de construcción; las alas tienen rotación inicial identidad.
- Caja Godot mínima: `(-0,550000; -0,252490; -0,409831)`.
- Caja Godot máxima: `(+0,550000; +0,301797; +0,566391)`.
- GLB bruto **largo × alto × ancho = 0,976222 × 0,554287 × 1,100000 m**.
- El código aplica `VISUAL_SCALE = 1.2`: visual mostrado **1,171467 × 0,665144 × 1,320000 m** (largo × alto × ancho). Esto explica el largo indicado como ~1,18 m.

**Decisión adoptada para v02:** para conservar la escala visual actual 1,2 y obtener ~1,4 m en pantalla, la geometría v02 tendría que medir ~1,166667 m de largo bruto. Un GLB bruto de 1,4 m se mostraría como 1,68 m con el código actual. Se eligió geometría bruta de 1,166667 m, con escala/rotación aplicadas y origen conservado, para obtener 1,4 m con el mismo multiplicador 1,2. No se ajustó el código ni la escala del jugador.

### Nombres que deben conservarse cuando tengan equivalente

- Raíz: `BeeModel`; cuerpo: `Thorax`, `Abdomen`, `Head`.
- Cara: `Eye_L`, `Eye_R`, `Brow_L`, `Brow_R`, `Mandible_L`, `Mandible_R`.
- Antenas: `AntennaBase_L`, `AntennaBase_R`, `AntennaTip_L`, `AntennaTip_R`.
- Alas independientes: **`Wing_L`, `Wing_R`**, pivotes Godot `(-0,11; 0,13; 0,035)` y `(+0,11; 0,13; 0,035)`.
- Patas: `Leg_L_0_Upper/Lower`, `Leg_L_1_Upper/Lower`, `Leg_L_2_Upper/Lower`, equivalentes `_R_…` (seis patas, dos piezas por pata).
- Aguijón existente: `Stinger`. Contrario al comentario provisional del código, **el GLB sí contiene esta pieza separada**; actualmente no se usa como golpe cromado.
- Tecnología v01: `ImplantHousing`, `Sensor_L`, `Sensor_R`, `Conduit_L`, `Conduit_R`, `BrokenCable`, `LiftedBrokenPlate`. No son nombres imprescindibles para el nuevo diseño; se conservará v01 intacto y v02 no tendrá el cian/azul del diseño anterior.

Materiales v01: `Gold`, `Dark`, `Cyan`, `AlienMetal`, `Eye`, `Wing`. v02 requiere su nueva paleta; no reutilizar el material `Cyan`.

### Animaciones actuales

**El GLB y la fuente mid-poly no contienen clips ni acciones.** No hay AnimationPlayer en el modelo importado. Por tanto no existe una lista de nombres/duraciones GLB que replicar.

El aleteo es procedural en `bee_visual.gd`: `wing_frequency=16.0 Hz`, `wing_amplitude=0.55 rad`, rotación local **Z** con signo opuesto por ala. Periodo 0,0625 s. Se detiene al derrotar al actor. Un loop GLB nuevo puede representar ese aleteo, pero una integración futura tendrá que elegir AnimationPlayer o el driver procedural, evitando que ambos escriban las alas simultáneamente.

Otros movimientos de juego son tweens de `VisualRoot`, no clips exportados: pirueta de 0,35 s, deformación del golpe de aguijón, aplastamiento al derrotar. No se cambian en esta tarea.

## Cómo el juego usa el visual

- Jerarquía: `BeePlayer (CharacterBody3D) / VisualRoot (Node3D) / BeeVisual (GLB + bee_visual.gd)`.
- `bee_visual.gd` encuentra `Wing_L/R` por nombre y aplica toon, contorno, rim cálido y escala 1,2. La dirección derecha gira `VisualRoot` alrededor de Y a **−PI/2**; izquierda a **+PI/2**. Mantener frente −Z del GLB.
- **Disparo:** `bee_player.gd::_spawn_projectile` usa `muzzle_offset=Vector3(0.48,0,0)` desde el jugador. Con apuntado libre, desplaza 0,48 m en la dirección de apuntado. No lee ningún empty `muzzle`; el ancla nueva deberá conectarse en una integración posterior.
- **Flash de daño:** `HitFlash3D` busca todas las `MeshInstance3D` bajo `../VisualRoot` y aplica `material_overlay`, luego lo restaura. Las piezas separadas del nuevo GLB quedarán dentro de esa jerarquía; mantenerlas como MeshInstance3D visibles.
- **Aguijón de combate actual:** `_build_stinger` crea `ChromeStinger` fuera de `VisualRoot`, hijo del jugador, un cono procedural de 0,8 m con trail, visible solo en golpe. `_show_stinger` lo orienta en el plano X/Y hacia el objetivo. No lee `Stinger` ni `stinger_tip` del GLB. Una futura integración tendrá que evitar duplicar el cono procedural con el taladro nuevo.
- Colisión actual: esfera física de radio 0,28, hurtbox de radio 0,20 y caja de melee `(0.75,0.5,0.5)`. No se alteran por cambiar el modelo; tamaño visual v02 no implica redimensionarlas ahora.
- `BeePlayer.BEE_LENGTH=1.3` se usa para el alcance de melee; es una constante de gameplay, no la medición bruta del GLB. No modificarla dentro de este pedido.

## Contrato de v02

Preservar nombres equivalentes, raíz/origen/orientación y aplicar escala/rotación de geometría antes de exportar. Nuevas piezas/anclas exactas: `stinger_drill`, `stinger_tip`, `thruster_L`, `thruster_R`, `nozzle_L`, `nozzle_R`, `antenna_R_blaster`, `muzzle`, `helmet_socket`, `plates`. Las toberas apuntarán hacia atrás (+Z Godot) y el cañón hacia adelante (−Z Godot). El taladro trasero deberá conservar su propio eje de giro. No modelar casco ni fuego de propulsores.

El pedido enumera siete usos de material pero fija máximo seis. Solución prevista: **amarillo**, **oscuro compartido** (franjas/patas/antenas/cara), **acero gris**, **acero oscuro**, **alas translúcidas neutras**, **oro emisivo exclusivo de la boca del cañón**. Ningún cian ni azul brillante. Materiales planos, textura opcional ≤1024 px; sin pelaje geométrico costoso.

Presupuestos: completo 16.000–18.000 tris con tope 20.000; `_lite` ≤6.000, ambos contados luego de aplicar modificadores y triangular. Se completaron cuatro vueltas de lateral/frente/espalda/arriba/3/4 con iluminación del juego, comparativas con la hoja y siluetas negras a 96 px.

## Integridad y validación de etapa 1

GLB v01 SHA-256: `2ef72672d95d8b1bef063982321c504db676c2e3e8f49842eae9a0c37fdc7264`.
Fuente mid-poly SHA-256: `6f76078782a320c1272751d171f264b2f6de7884d3f9f18161ad029493d6ba87`.
Fuente anterior SHA-256: `d5b5304a620198b029326177f89a0ff19a3a7acf8b600a7e736f93184c24bb2e`.

Validación dirigida `tests/bee_prototype/validate_bee_visual.gd`: **PASS**, `BEE_VISUAL_OK wings facing collider health melee hitflash defeat`. Lectura de fuente/GLB y hashes intactos. Logs `dev/bee_v01_source_inventory.log`, `dev/bee_midpoly_source_inventory.log` y `dev/bee_hero_inventory_validation.log`; medición reproducible en `dev/bee_v01_inventory.json`. La suite completa se reserva para la entrega del modelo y no se ejecutó todavía en esta tarea.

## Etapa 2 — geometría inicial y validación

Fuentes en `art_source/blender/shared/bee_hero/`, GLB en `assets/models/shared/bee_hero/`, nombres `shared_hero_bee_v02` y `shared_hero_bee_v02_lite`. Construcción reproducible: `tools/art/create_bee_hero_v02.py`. Las mallas tienen modificadores aplicados, escalas unitarias, rotaciones de construcción aplicadas y caras trianguladas; Blender verifica cierre y ausencia de caras degeneradas.

Primera versión: completo **17.576 triángulos**, lite **4.838**, seis materiales. Largo visual con escala heredada: 1,400000 / 1,400380 m. Sin texturas ni pelaje de geometría costoso. v01 no tiene clips que copiar; se agregaron `wingbeat` y `drill_spin`, ambos de 0,5 s. Aleteo a 16 Hz sobre las dos bisagras legacy, con dos membranas por bisagra (cuatro alas de la hoja). El taladro rota alrededor de su origen dedicado y arrastra las bandas/remaches/`stinger_tip`.

Validación dirigida `tests/art/validate_bee_hero_v02.gd`: **PASS**, nombres/piezas, seis materiales, dirección de muzzle/toberas, presupuestos y escala visible, clips/movimiento, fuente v01 intacta, ausencia de colisiones. No se instancia el nuevo modelo desde BeePlayer.

## Etapa 3 — revisión visual y entrega final

Renders reales de Godot Compatibility, no imágenes generadas: `docs/art/renders/bee_hero/round_01/` a `round_04/`, ambos modelos, lateral/frente/espalda/arriba/3/4. Dirección de luz (-40,-25,0), color (1,0.9,0.72), energía 1,25 y ambiente cálido/0,7 de la escena del jardín, sobre fondo neutral. Se aplica el shader toon y el contorno existentes en el laboratorio; el GLB conserva materiales portables. Alas cálidas translúcidas sin sheen emisivo en el preview. Solo la boca del cañón usa emisión dorada; sin cian, azul brillante, casco ni fuego modelado.

| Vuelta | Observación visual | Corrección y resultado |
|---|---|---|
| 1 | Alas de canto en lateral, ojos salientes, núcleo oscuro ocultando bandas metálicas, boca del blaster pequeña | Registrado antes de corregir; renders y comparativa conservados |
| 2 | Perfil y cara más cercanos a la hoja | Giro de membranas aplicado, ojos ajustados a la superficie de la cabeza, cejas curvas, núcleo del taladro reducido, cinco bandas más cortas, punta metálica y boca del blaster mayor. 17.612 / 4.846 tris |
| 3 | Propulsor poco separado del tórax en silueta negra | Se elevó el conjunto del propulsor con sus aletas y anclas, sin alterar conteo ni caja general. Se ve el escalón del pod bajo las alas |
| 4 | La comparativa de la versión lite mostraba franjas dentadas por reducción a través de los materiales | Se conservó la malla del abdomen sin reducción; franjas continuas y limpias. Lite final: 5.604 tris. Cinco vistas completas revisadas en ambos modelos |

### Medidas y presupuestos finales

Conteo de índices triangulados exportados, con todos los modificadores aplicados. La geometría de cada fuente está triangulada, cerrada y sin caras degeneradas. No se estima desde el archivo ni desde caras sin triangular. Seis materiales y ninguna textura en ambas versiones.

| Modelo | Triángulos reales | Largo × alto × ancho GLB (m) | Visual con escala heredada 1,2 (m) |
|---|---:|---|---|
| `shared_hero_bee_v02` | **17.612** | 1,166667 × 0,969787 × 0,640114 | **1,400000 × 1,163745 × 0,768136** |
| `shared_hero_bee_v02_lite` | **5.604** | 1,166766 × 0,971858 × 0,639685 | **1,400119 × 1,166230 × 0,767623** |

Medidas de pose de reposo, incluyendo alas, patas, antenas, taladro y cañón. La caja cambia durante el aleteo. Raíz/origen/orientación heredados; escala 1 y rotación 0 de las mallas aplicadas, comprobadas además en Godot. La diferencia de 0,000119 m de largo visible lite es residual de la simplificación.

### Silueta a 96 píxeles y fidelidad

Renders negros, con alas opacas solo para esta prueba: completo **116 × 96 px**, 4.176 píxeles negros; lite **115 × 96 px**, 4.109. Cada silueta tiene un único componente conectado. Inspección visual: se reconoce la abeja, el taladro trasero y el cañón elevado; el propulsor genera un escalón compacto bajo las alas. Los dos propulsores se superponen en vista lateral pura, como corresponde a su ubicación simétrica: no se distinguen por separado en esa vista. La conectividad mide continuidad, no sustituye esta revisión visual.

Desvíos deliberados de la hoja: venación de las alas simplificada; menos remaches pequeños y sin pelaje geométrico; ojos algo más redondeados, boca y pies simplificados; propulsores ligeramente más altos para la lectura lateral. Lite conserva la misma jerarquía, franjas y silueta, con facetas más visibles en tubos y membranas. No es una copia de cada detalle de la ilustración; la cara, cuatro alas, seis patas, placas separadas, dos pods y taladro de cinco bandas mantienen su identidad.

Anclas nuevas incluidas: `stinger_tip`, `nozzle_L/R`, `muzzle`, `helmet_socket`. `stinger_drill` tiene eje propio; `thruster_L/R`, `antenna_R_blaster` y `plates` son conjuntos separados. Nombres equivalentes de v01 conservados. Clips `wingbeat` y `drill_spin`, ambos loops de **0,5 s**, con aleteo de 16 Hz; el segundo añade giro del taladro. No había clips v01 que replicar.

### Archivos y cómo mirar la entrega

- Fuentes editables: `art_source/blender/shared/bee_hero/shared_hero_bee_v02.blend` y `shared_hero_bee_v02_lite.blend`.
- Exportaciones: `assets/models/shared/bee_hero/shared_hero_bee_v02.glb` y `shared_hero_bee_v02_lite.glb`; mediciones reproducibles en `bee_hero_v02_manifest.json`.
- Comparativa final: `docs/art/renders/bee_hero/round_04/full_comparison.png` y `lite_comparison.png`; hojas `full_five_views.png` / `lite_five_views.png`, PNG individuales y siluetas a 96 px. Las vueltas anteriores se conservan como evidencia.
- Abrir `scenes/art_labs/bee_hero_v02.tscn` en Godot y ejecutar **F6**: completo y lite juntos; **1** aleteo, **2** giro del taladro con aleteo, **Espacio** pausa. Revisar cara decidida, franjas limpias, cinco bandas del taladro, cañón derecho y dos toberas.
- Builder independiente `tools/art/create_bee_hero_v02.py`; herramientas de captura/compaginación en `dev/bee_hero_modelo/`. Solo regeneran v02; no invocan builders históricos.

### Validación y límite de integración

Prueba dirigida final `tests/art/validate_bee_hero_v02.gd`: **PASS**, 17.612 / 5.604 tris; materiales/paleta/emisión, alas translúcidas, escala/rotación aplicada, raíz identidad, nombres/anclas/direcciones, clips y movimiento, laboratorio, ausencia de colisiones y hash GLB v01. Las tres fuentes/GLB históricos conservan sus hashes de etapa 1. `git diff 0b65701 -- scripts scenes/bee_prototype project.godot` vacío: no se cambió código del juego.

Suite completa ejecutada **una sola vez al final**: **101/101 PASS, 0 fallos**, 371,5 s. Godot 4.7.2 headless, FPS fijo 60 excepto las validaciones históricas `validate_toon_items_v01` y `validate_wasp_visual`, que usan reloj real; timeout de 180 s por script. Ningún `SCRIPT ERROR` ni timeout. El renderer dummy y algunas pruebas emiten avisos de materiales/recursos al salir, registrados en los logs; no fallaron las aserciones ni los códigos de salida. Logs locales `dev/bee_hero_v02_full_suite.log` y `dev/bee_hero_v02_full_suite_result.log`; comando reproducible `python dev/bee_hero_modelo/run_full_suite.py`.

El juego sigue usando v01. La integración futura debe conectar `muzzle`, elegir un único driver de alas y resolver el aguijón procedural para no duplicarlo con el taladro. No se ajustaron colisiones ni mecánicas en esta entrega de arte.

Commits por etapa: resguardo **0b65701**, inventario **2a7a6d8**, modelado inicial **2f6d9d5**; revisión y entrega final en un cuarto commit, seguido de push de `lote-15b-bee-modelo`.
