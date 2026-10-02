# Level 01 — Density & Collision Pass 02

## Feedback humano literal

- todavía muy vacío;
- necesita muchos más enemigos;
- entorno vacío;
- pasar entre piernas no debe dañar;
- quiere más obstáculos/interacción.

La percepción de «3× más actividad» se traduce en 38 enemigos, no en 51 bajas obligatorias. No se agregaron familias, armas, assets externos, metros ni velocidad.

## Antes / después

| Métrica | Pass 01 | Pass 02 |
| --- | ---: | ---: |
| Longitud / scroll | 360 m / 2 m/s | igual |
| Eventos | 14 | 24 |
| Enemigos | 17 | 38 |
| Máximo simultáneo | 2 | 2 hasta 300 m; 3 al final |
| Eventos por 100 m | 3,89 | 6,67 |
| Gap máximo entre umbrales | 32 m / 16 s | 16 m / 8 s |
| Gap medio entre umbrales | 23,23 m / 11,62 s | 14,26 m / 7,13 s |
| Escenografía colocada | 206 | 350 |
| Polen | 17 | 17 |
| Cajas rompibles | 8 | 8 |
| Rocas sólidas | 8 | 8 |
| Obstáculos físicos | 18: 8 cajas + 8 rocas + tronco + botella | igual |
| Hueco central de hitboxes del humano | 1,75 m | mínimo 2,4 m |

Los gaps son viajes teóricos a velocidad normal, no duración real de combate. Hay navegación/polen entre umbrales; el último evento está en 340 m, seguido de roca/caja/polen en 343–347 m antes del final a 360 m.

## Cambios jugables y visuales

20 soft encounters mantienen scroll y permiten escapar. Los tres hard gates son Organic + Wasp (254 m), Walker + EyeDrone (296 m) y Walker + Probe + Turret (340 m). El evento especial humano está en 140 m sin combate simultáneo. Entradas de grupo separadas por 0,8 s, demoradas si el cupo está ocupado. Los soft ejercen presión durante 6 s y se retiran a la izquierda a 10 m/s, sin nuevos ataques durante retirada; al salir se libera su subtree. Las muertes conservan feedback un segundo antes de liberar nodos. Los proyectiles existentes conservan su TTL. HP y ataques reutilizables no cambian.

El último tramo contiene Walker + EyeDrone, Wasp + Speeder, Probe + EyeDrone + Wasp y el hard gate final de tres. Se mantienen rutas bajas de polen, túnel del tronco, botella y cajas/rocas que se pueden rodear por arriba.

16 pockets irregulares añaden 80 flores, 48 helechos y 16 árboles: 144 colocaciones adicionales, siempre detrás del plano de vuelo. Se conservan los pequeños foreground existentes. Variación de Z, tamaño y giro; sin nuevas texturas ni imports.

La revisión render detectó oclusión de Walker por hojas anchas: ahora los bounds completos del foliage de fondo quedan detrás de Z=−3, no sólo su centro. Los helechos foreground conservan ancho, pero su altura se reduce al 20% para permanecer debajo de la ruta baja de Bee. No se altera la colisión del escenario.

## Causa y corrección del humano

Las cajas antiguas permanecían en X=±1,55 mientras Run desplazaba los pies: por ejemplo X≈−1,84/+2,60 en la pose 0,2 s. VisualRoot gira 90° y escala 6×, pero las hitboxes son hermanas sin esa transformación. El volumen fijo podía ocupar espacio visualmente vacío. El test anterior sólo comprobaba unos frames en el hueco y luego sacaba Bee de él; no cubría todo el cruce.

La instancia local ahora obtiene posiciones animadas de foot/calf, construye envolventes conservadoras de piernas y recorta su borde interior fuera de X local ±1,2. El centro permanece seguro incluso cuando la zancada cambia; no se altera Run, GLB ni el hazard de los POCs anteriores. En poses que no tienen pierna fuera de esa franja se omite sólo esa envolvente. La profundidad de 3 m conserva contacto lateral con ambas piernas. Torso: 4,45×4×1,55 m, centro Y=5,2, borde inferior Y=3,2 (antes 2,8). El gap de 2,4 m deja ~1,84 m para el centro de la hurtbox de Bee (radio 0,28). La hitbox común conserva 20 HP y un único impacto por cruce.

Test: Bee sigue el centro del humano durante todo CROSSING, con Areas físicas activas y movimiento/clamp de vuelo suspendido sólo en esa comprobación aislada. Contactos de ambas piernas y torso se prueban por separado en una pose real de Run; 20 HP una vez, sin daño por frame. El recorrido integrado valida además bounds, navegación y progreso. Esto no sustituye probar manualmente la entrada/salida del hueco con controles.

## Validación y límites

Validación final: test integrado headless aprobado dentro de la suite (471 frames de gap seguro) y render OpenGL aprobado (467 frames); 38 spawns, máximo 3, cuatro escapes soft, final y R correctos. Carga jugable directa headless/render: código 0. Bee suite completa: **17/17**, cero regresiones, sin SCRIPT ERROR ni recursos faltantes.

Rendimiento local, Intel Arc B580 / Compatibility: muestra de 5 s a velocidad normal con Walker + Probe + Turret: media 99,96 FPS, mínimo Engine FPS 90, peor frame 13,58 ms, 1080 nodos. Pico de nodos del recorrido integrado: 1091. El muestreo de 180 ciclos físicos con render dio ~60 ciclos/s y peor intervalo 20,94 ms. No confundir esos ciclos con FPS de render. El intervalo ~3,6 s del log integrado incluye la espera deliberada de esa muestra y las capturas PNG: no es un spike de gameplay. Estas muestras no son un benchmark exhaustivo ni certifican otros equipos.

Capturas en `dev/level_01_review/`: `density02_01_garden`, `02_light_group`, `03_three_threats`, `04_boxes_rocks`, `human_safe_gap_debug`, `06_vegetation`, `07_organic`, `08_walker`, `09_final_section` (PNG); además crate before/broken. Volúmenes rojos sólo en el test; no quedan en gameplay. Logs headless/render/direct/suite/performance y `density02_git_status.log` en el mismo directorio. Se conservan imágenes anteriores.

Archivos de la pasada: controller y scenery del Level 01, wrapper y escena local del humano, test integrado, documento del Level 01 y este feedback; dos helpers de diagnóstico/medición en el directorio de review, capturas y logs. Git conserva las siete modificaciones tracked previas y los archivos untracked existentes; los archivos del Level 01 siguen untracked. No commit/push/reset/clean/stash. Git advierte conversión LF/CRLF en archivos tracked ya modificados; no es error del motor.

**BEE LEVEL 01 DENSITY & COLLISION PASS 02 APTO**. Siguiente paso: playtest humano focalizado en actividad, entrada/salida del hueco y lectura del tramo final; no iniciar Weapons/Powerups.

No hay checkpoint: R tras derrota recarga todo. El túnel aún puede ocultar parcialmente a Bee. El ajuste de colisión es deliberadamente generoso, no anatomía exacta. El ritmo y dificultad de 38 unidades requieren otro playtest humano. Los tests de progresión observan activaciones normales, dejan escapar unidades soft y resuelven otras por Health para cubrir todas las familias; no simulan una partida ganada mediante X/Z.
