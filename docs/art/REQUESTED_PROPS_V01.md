# Bee Alien · Pinos, residuos y barrio

Entrega de los objetos solicitados, organizada en cuatro POCs pequeños. Doce modelos originales: piña, dos pinos, botella, cerillos, envoltorio, cáscara de banana, lata de atún, grupo de estrellas, poste de luz y dos casas. Se conservan todos los modelos anteriores.

| Galería / carpeta | Asset | Triángulos |
| --- | --- | ---: |
| `pine_woods_v01` | `pine_cone` · piña con cuarenta escamas | 4.992 |
| | `tall_pine` · pino alto por niveles | 1.564 |
| | `umbrella_pine` · pino mediterráneo de copa ancha | 3.176 |
| `ground_litter_v01` | `glass_bottle` · botella verde abierta | 1.640 |
| | `matchbox` · caja parcialmente abierta con cerillos | 2.820 |
| | `open_candy_wrapper` · papel de caramelo abierto | 116 |
| `ground_litter_v02` | `banana_peel` · tres tiras de cáscara amarilla | 908 |
| | `open_tuna_tin` · lata vacía y tapa levantada con anilla | 1.584 |
| `residential_sky_v01` | `warm_star_set` · cinco estrellas crema | 1.800 |
| | `warm_street_lamp` · poste curvo con lámpara ámbar | 1.288 |
| | `residential_cottage` · casa baja con porche | 2.988 |
| | `residential_two_storey` · casa de dos pisos | 3.364 |

Cada modelo tiene una malla agrupada y varios materiales; esto no equivale a un único draw call. El generador verifica sólidos cerrados y caras no degeneradas. Los props son estáticos y originales, sin bibliotecas externas, marcas, texto ni texturas dependientes. El papel tiene grosor y pliegues geométricos; la botella tiene pared interior, fondo real y boca abierta; la lata tiene interior visible.

## Estilo

Cel shading de tres bandas, contorno fino y rim suave. Vegetación verde natural, madera ocre/marrón, residuos crema/coral/amarillo y casas con pintura cálida y ventanas apagadas. Ningún elemento usa energía cian/violeta.

La botella usa un shader de vidrio toon translúcido, opacidad base 0,38 y borde oscuro dentro del mismo pase. Un inverted hull opaco taparía el interior de la botella; por eso el vidrio no usa ese segundo pase de contorno. La fuente Blender conserva alfa 0,58; el wrapper lo reduce para leer mejor las capas superpuestas en Compatibility. Se evita refracción y brillo fotográfico.

El único material con emisión de este lote es el bulbo del poste: ámbar, energía 0,22. Las estrellas y ventanas no emiten. `WarmLightAnchor` sirve para colocar una luz cálida de Godot; el modelo por sí solo no ilumina el entorno. `BottleMouth` referencia la boca de la botella.

## Archivos creados y modificados

Para cada carpeta indicada en la tabla:

- `art_source/blender/<carpeta>/<asset>.blend`: doce fuentes editables; `.gdignore` conserva las fuentes fuera del importador.
- `assets/models/<carpeta>/<asset>.glb`, `manifest.json`: doce exportaciones y cuatro presupuestos/rutas.
- `scenes/art_labs/<carpeta>/<asset>.tscn`: doce wrappers toon reutilizables.
- `scenes/art_labs/<carpeta>.tscn`: cuatro galerías.
- `docs/art/<carpeta>/`: estudio conjunto y fichas lateral/3/4, con fondo neutro y sin UI en las capturas limpias.

Archivos compartidos nuevos:

- `tools/art/create_requested_props_v01.py`: generador con selección explícita de una tanda mediante argumento.
- `scripts/art/requested_prop_visual.gd`: vidrio translúcido y control de energía del bulbo, heredando el estilo de props existente.
- `assets/style/toon_prop_glass.gdshader`: vidrio de tres bandas con borde oscuro y rim suave.
- `scripts/art/requested_props_lab.gd`: catálogo que centra y encuadra cada objeto desde sus límites geométricos reales.
- `tests/art/validate_requested_props_v01.gd`: integración de los doce assets.
- `tools/art/capture_requested_props_details.gd`, `docs/art/requested_props_v01/`: vista conjunta de los doce objetos, inspección de transparencia y colección a 720 px de alto.

Modificado `scripts/art/art_delivery_hub_v01.gd`: cuatro accesos nuevos, lista desplazable y seguimiento del foco para navegar por teclado. No se cambian los scripts de juego ni el Nivel 01.

## Cómo probar

Ejecutar con **F6** `scenes/art_labs/art_delivery_hub_v01.tscn` y elegir alguno de los cuatro grupos nuevos. También se puede ejecutar directamente cualquiera de sus galerías.

**1–4** seleccionan piezas, **V** cambia lateral/3/4, **H** oculta la interfaz, **E** vuelve al estudio conjunto y **Esc** a la colección. Los modelos se centran y encuadran automáticamente; sus tamaños de catálogo sirven para inspección y no fijan la escala del nivel.

Instanciar los wrappers `.tscn` en el nivel para conservar el estilo. Ajustar escala y profundidad Z por instancia: árboles, postes y casas representan elementos humanos enormes frente a Bee. Casas y estrellas se diseñan para fondo/parallax; los otros props pueden colocarse en suelo.

## Verificación y límites

**0 fallos / 12 assets** en Godot 4.7.2 Compatibility: fuentes presentes, recuentos GLB contra manifiesto, máximo 5.000 triángulos, una malla agrupada, toon/contorno, vidrio con transparencia, bulbo cálido y energía limitada, ausencia de otras emisiones, marcadores, catálogos completos y encuadre individual sin recortes verticales. La prueba de navegación de la colección también pasó con 0 fallos. Capturas reales revisadas visualmente. Logs en `dev/requested_props_v01_test.log`, `dev/requested_props_v01_hub.log` y `dev/<carpeta>_capture.log`.

Assets visuales sin colisiones, físicas, viento, parallax automático ni interacción con tapa/cerillos. Las piezas se agrupan en una malla; para animar partes se pueden separar desde la fuente Blender. La transparencia puede requerir revisar el orden de superposición al combinar muchos objetos translúcidos. No hay benchmark de grandes cantidades.

Persisten los avisos de caché de shaders/ajustes del editor de Godot y miniaturas externas de Blender por el entorno restringido. Las fuentes, exportaciones, pruebas y capturas se guardaron correctamente.
