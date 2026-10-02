# Level 01 — Flora & Garden Variety Pass 01

Feedback: demasiada repetición de la misma flor azul; recuperar las flores multicolor antiguas y evaluar progresivamente la nueva biblioteca.

## Resultado visual

| Métrica | Antes | Después |
| --- | ---: | ---: |
| Tipos/modelos de flor | 1: purpleA | 6 |
| Instancias de la flor azul/violeta dominante | 139 | 47 |
| Total flores | 139 | 134 |
| Colocaciones decorativas | 350 | 350 |
| Paleta | azul/violeta | azul/violeta, amarillo, rojo y rosado |

Distribución real: purpleA 47, purpleB 20, redA 15, yellowA 13, yellowB 32, rose recuperada 7. Cinco slots se reemplazan por Fern_1 en contacto alien. Se conserva ~34% de la flor dominante original (~35% del total floral actual). Plantas previas: CommonTree_1, Fern_1 y rocas/props; se mantienen. Los seis modelos aportan siluetas de copa, flor abierta y pétalos redondeados, sin recolor aleatorio ni nuevas texturas.

## Recuperación, fuentes y licencias

Flor antigua comprobada: flower()/rose de `scripts/bee_prototype/bee_garden_poc.gd`, primitivas originales del juego. Se aisló en `scenes/decoration/recovered_garden_rose.tscn`, sin scripts por instancia, colliders ni cambios a POC original. Conserva cinco pétalos rosados y centro ocre. POCs de vuelo/combate también conservan proxies; documentación Garden registra paleta rosada/ocre/violeta anterior.

Cuatro archivos promovidos desde Kenney Nature Kit ya existente: flower_purpleB, redA, yellowA y yellowB, todos GLB autocontenidos. License.txt local CC0 explícito, autor Kenney. Copia selectiva a approved/nature/kenney/kenney_nature-kit/Models/GLTF format y al mismo subdirectorio de 02_Selected_For_Game. Sin reemplazar fuentes. Rutas completas/hash y licencia: `assets/external/ASSET_PROVENANCE.md`.

La nueva carpeta `D:\proyectos\V_Asset_Library\01_Extracted\flores` tiene 15 GLB y cero documentos de licencia. Los nombres "_cc0" no bastan; asset/extras no acreditan licencias. **Ninguno se promovió/importó al proyecto**. Macetas, cactus y posibles tallos quedan reservados; no se usaron combinaciones. No Blender. Inventario por archivo, packs y otras variantes verificables: `docs/FLORA_ASSET_INVENTORY.md`.

## Composición

- Inicio 0–45 m: yellowA/B con azul/violeta.
- Tronco 45–95 m: purpleA/B, helechos y algo de amarillo.
- Transición/zona humana 95–165 m: redA y rosas recuperadas, con violetas; botella existente, sin macetas nuevas.
- Contacto alien 165–285 m: más vegetación baja en cinco slots, rojo/amarillo/violeta moderados.
- Final 285–360 m: flores abiertas y acentos rojos/amarillos entre vegetación irregular existente. Sin nuevos shaders ni oscurecimiento artificial.

Los pockets existentes de cinco flores conservan separaciones irregulares. Variación uniforme 0,75–1,25 alrededor de escala base por modelo; yaw de Kenney intacto, rosas casi laterales para mantener pétalos legibles. Se mantiene la regla de bounds completos detrás de Z=−3 y los foreground bajos. Ninguna flora tiene colisión. Tronco, cajas, polen y gap humano quedan delante de la decoración.

## Capturas y validación

`dev/level_01_flora_review/`: 01_start, 02_multicolor_cluster, 03_log_area, 04_human_area, 05_alien_area, 06_final, 07_recovered_old_flower y 08_promoted_kenney_variants (PNG). La última muestra assets recién promovidos de la biblioteca Kenney antigua; no assets de la carpeta nueva sin licencia. Helper review_flora.gd registra counts y dimensiones nativas, sin construir una arquitectura de vegetación.

Capturas del test integrado se redirigen a runtime/ mediante BEE_LEVEL_REVIEW_DIR para conservar las imágenes Density Pass 02. Sin cambios a la lógica de validación; sólo destino opcional de artefactos.

Resultados finales: test integrado Level 01 headless aprobado dentro de la suite, render aprobado, cargas jugables directas headless/render código 0. Suite completa **17/17**, cero regresiones y sin SCRIPT ERROR/recursos faltantes. Colisión humana: 473 frames seguros headless / 466 render; contacto de piernas/torso conserva 20 HP una vez. Longitud 360 m, scroll 2 m/s, 24 eventos, 38 enemigos, HP, humano, Bee, ataques, 17 polen, 8 cajas y 8 rocas sin cambios.

Misma muestra local de 5 s con Walker + Probe + Turret, Intel Arc B580, OpenGL Compatibility, velocidad normal y sin otros tests activos: **99,998 FPS medios**, mínimo observado Engine FPS 89, peor frame 10,993 ms, 1136 nodos. Baseline 99,96 FPS medios: no caída significativa en esta muestra. Pico integrado: 1147 nodos headless / 1143 render, frente a 1091 del pass anterior; incremento por la geometría de siete rosas recuperadas y variantes de mesh. La muestra de 180 ciclos físicos con render sigue ~60 ciclos/s; no equivale a FPS. Intervalo ~3,6 s del log integrado incluye la espera deliberada de esa muestra/capturas, no spike de gameplay. No es un benchmark completo de todo el nivel/otros equipos.

Logs: review.log, level_render.log, suite.log, direct_headless.log, direct_render.log y performance.log en dev/level_01_flora_review. Las ocho capturas se abrieron y revisaron; runtime/ contiene combate/progreso con flora actual, preservando capturas previas.

**BEE LEVEL 01 FLORA & GARDEN VARIETY PASS 01 APTO**.

## Pendientes

Adjuntar evidencia de autor/licencia a cada descarga nueva antes de promover. Revisar costo y escala de maceta/tulipanes pesados sólo cuando estén autorizados por su procedencia. La flor Kenney azul/violeta sigue deliberadamente presente; la rosa recuperada conserva aspecto proxy. Playtest humano para confirmar variedad y legibilidad; no Weapons/Powerups ni Level 02.

## Git / archivos de esta tarea

**Flora Pass 01:** modificados bee_level_01_scenery.gd, documentación Level 01, ASSET_PROVENANCE.md y destino opcional de capturas en validate_bee_level_01_vertical_slice.gd. Creados recovered_garden_rose.tscn, FLORA_ASSET_INVENTORY.md, este documento, review_flora.gd, capturas y logs de review.

**Assets nuevos:** cuatro GLB Kenney + archivos .import en approved; cuatro copias idénticas en 02_Selected_For_Game. Ningún archivo de la carpeta nueva flores se copió. License.txt ya existente intacto.

**Cambios anteriores:** las siete modificaciones tracked previas (project.godot, escenas garden/mission/player, scripts garden/mission, test mission) y los numerosos assets/POCs/docs/Level 01 untracked permanecen. Los archivos Level 01 ya estaban untracked, por lo que git status no distingue sus ediciones internas. Estado completo al cierre en dev/level_01_flora_review/git_status.log. Sin commit/push/reset/clean/stash.
