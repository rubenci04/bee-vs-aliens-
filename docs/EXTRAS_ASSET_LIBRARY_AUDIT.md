# Auditoría local de `extras` para Bee Alien 3D

**Alcance:** lectura recursiva de `D:\proyectos\V_Asset_Library\01_Extracted\extras`. Ningún asset se copió, convirtió o integró. El inventario fila por archivo, con rutas absolutas y metadatos, está en `docs/EXTRAS_ASSET_LIBRARY_INVENTORY.csv`.

## Resumen ejecutivo

| Métrica | Resultado |
| --- | ---: |
| Fuentes de primer nivel | 19: 17 carpetas y 2 GLB sueltos |
| Archivos totales | 159 |
| Archivos de modelos | 84: 24 GLB, 27 FBX, 33 OBJ; ningún GLTF o BLEND |
| Conceptos/modelos distintos | 40; 22 del pack Kenney repetidos en tres formatos |
| CC0 confirmado por evidencia local | 66 archivos / 22 conceptos (Kenney Mini Forest) |
| Otra licencia compatible confirmada | 0 |
| LICENSE REVIEW (archivo presente, alcance ambiguo) | 0 |
| Sin licencia local encontrada | 18 archivos / 18 conceptos |
| Candidatos posibles para Bee | 70 archivos / 32 conceptos; sólo 19 conceptos ambientales Kenney tienen CC0 local |
| No prioritarios / indeterminados | 6 / 2 conceptos |

Otros archivos: 29 PNG, 33 MTL, 8 copias `.bak`, 3 URL, 1 HTML y 1 TXT. Los nombres `by ...` sirven como pista de atribución, **no** como licencia. Esta carpeta no contiene una solución sci-fi licenciada localmente para bombardero, carrier, radar, nodo de control o nave nodriza.

## Inventario por pack

La ruta base de cada entrada es `D:\proyectos\V_Asset_Library\01_Extracted\extras\`; el CSV conserva la ruta completa de los 84 modelos. `SIN LICENCIA` significa que no se encontró evidencia local, no una conclusión sobre los derechos externos.

| Pack / archivo | Modelos y lectura técnica | Uso hipotético | Estado local |
| --- | --- | --- | --- |
| `kenney_mini-forest_1.0` | 22 modelos × FBX/GLB/OBJ; GLB ~58–847 tri/modelo; `character-archer` trae 32 clips | jardín, rocas, estructuras de fondo | **CC0 CONFIRMADO** |
| `Alien by Quaternius - sUTLXji0aL.glb` | 2 meshes, 4 materiales, ~2.616 tri, rig, 9 clips (incluye Idle/Walk/Bite/Death) | criatura alien melee | SIN LICENCIA |
| `Tree Blob by Quaternius - 0X3fUj0uUF.glb` | 1 mesh, 1 material, ~1.892 tri | criatura vegetal, si la inspección visual lo avala | SIN LICENCIA |
| `1 by Eric Finn - 05X3xYCrpya` | OBJ `model`, ~3.924 tri, 66 objetos, 14 materiales | indeterminado por nombre; revisión visual pendiente | SIN LICENCIA |
| `Alien by jeremy - 3SD07SGSMNy` | OBJ `Alien_01`, ~1.644 tri, 8 materiales, sin rig OBJ | criatura alien provisional | SIN LICENCIA |
| `Alien Jetpack Go! by Damon Pidhajecky - 7VJiMcRcn6d` | OBJ `model`, ~8.070 tri, 17 objetos, 15 materiales | tropa aérea; alto coste visual/técnico | SIN LICENCIA |
| `Bee by apelab - f0lW38lzjd4` | OBJ `model`, ~2.854 tri | duplica rol de BeePlayer | SIN LICENCIA |
| `Flying saucer by Poly by Google - b0N_HeT_Ttb` | OBJ `1352 Flying Saucer`, ~3.600 tri, PNG hermano sin vínculo MTL | nave/fondo; escala OBJ arbitraria | SIN LICENCIA |
| `Flying saucer by Poly by Google - fojR5i3h_nh` | OBJ `flying sacuer`, ~918 tri, 4 materiales | UFO ligero; variante funcional por probar | SIN LICENCIA |
| `Mars Rover by Anna M - 2qciL4mkmTz` | OBJ `model`, ~22.596 tri, 22 objetos, 8 materiales | rover terrestre pesado; integración costosa | SIN LICENCIA |
| `Owz by sirkitree - 5vbeGRwzuQl` | OBJ `model`, ~7.720 tri; identidad indeterminada | revisión visual pendiente | SIN LICENCIA |
| `ricks ufo by eeee - q6vNUoHZXr` | FBX `source/RAM`, ~25.948 tri, 32 materiales, sin rig/clips | posible set piece; complejidad alta | SIN LICENCIA |
| `Robot Enemy Legs Gun by Quaternius - lFZfDh2hzP` | FBX `Enemy_2Legs_Gun`, ~4.722 tri, 2 meshes, 9 materiales, rig y 7 clips (incluye Run/Shoot) | walker armado, rol ausente | SIN LICENCIA |
| `spaceship Goodnews by Justin Scifres - aeLvaKN3cYh` | OBJ `model`, ~5.798 tri, 11 materiales | nave de ataque provisional | SIN LICENCIA |
| `Ufo by hat_my_guy - NgURFR5T9m` | FBX `ufo`, ~1.004 tri, 2 materiales | UFO ligero | SIN LICENCIA |
| `UFO by marcusnikira - 4nCAC4jP0a` | FBX `UFO`, ~1.358 tri, 4 materiales | variante de nave mediana | SIN LICENCIA |
| `UFO TIME by Martin Calviello - 89hlsI17Ulw` | OBJ `model`, ~32.524 tri, **303 objetos**, 21 materiales | posible set piece/boss proxy; coste muy alto | SIN LICENCIA |
| `Wasp by Poly by Google - e-maR6CzcKc` | OBJ `wasp`, ~1.684 tri, `waspTxt.png` enlazado en MTL | duplica Wasp actual | SIN LICENCIA |
| `Wasp by Quaternius - 3aQgc75sUR` | FBX `Wasp`, ~3.736 tri, rig y Flying/Attack/Death | duplica Wasp actual | SIN LICENCIA |

Mini Forest contiene `bridge`, `building-platform`, `building-roof`, `building-structure`, `character-archer`, `fence`, `flag`, `ladder`, `patch-dirt`, `patch-grass`, `plant`, `platform`, `rocks-high`, `rocks-low`, `rocks-ramp`, `stones`, `target`, `tent`, `tree-high`, `tree`, `weapon-arrow` y `weapon-bow`. La vista previa local confirma formas simples y paleta plana; su tema es bosque/fantasía, no tecnología alien. `character-archer` y las dos armas no aportan un rol necesario frente al humano ya reutilizado y el combate Bee actual.

## Inventario por categoría y encaje

Conteos por **concepto** (las tres exportaciones Kenney cuentan una vez): AIR LIGHT 2; AIR MEDIUM 4; BOSS/MINI-BOSS candidato 2; GROUND HEAVY 2; ORGANIC ALIEN 3; SUPPORT/STRUCTURE 3; ENVIRONMENT/PROP 16; NOT USEFUL 6; UNKNOWN 2. No se encontró un modelo claramente clasificable como AIR HEAVY, GROUND LIGHT dedicado, radar, generador o mina. Rocas/puentes pueden servir de hazard ambiental, pero no constituyen un sistema de hazard nuevo.

La compatibilidad visual de Kenney es **media/alta para jardín arcade**, comprobada en `Preview.png`; no implica encaje sci-fi. La de los 18 modelos sin licencia local queda **DESCONOCIDA** hasta una revisión visual selectiva. Nombres, polígonos y materiales no prueban una silueta. Las cifras de triángulos OBJ se estiman triangulando caras; las GLB proceden de índices de primitivas; cinco FBX no Kenney se inspeccionaron en Blender 5.2 **sin guardar**. Los AABB del CSV son locales/importados y no garantizan escala final: los dos GLB Quaternius sueltos, por ejemplo, usan nodo padre a escala 100. Los 22 FBX y 22 OBJ Kenney remiten a la métrica de su GLB hermano, no a una medición independiente de cada formato.

## Licencias y dependencias

`kenney_mini-forest_1.0/License.txt` declara **Creative Commons Zero (CC0 1.0)** y uso personal, educativo y comercial; atribución alentada, no requerida. `Overview.html` repite CC0. Es la única evidencia local de licencia detectada en todo `extras`. Ni carpetas etiquetadas `Quaternius` ni `Poly by Google` permiten inferir licencia. Los 18 modelos restantes quedan **NO UTILIZAR TODAVÍA** hasta obtener evidencia verificable de su licencia. No hay archivos de licencia local que justifiquen la categoría intermedia `LICENSE REVIEW`.

La mayoría de OBJ manuales tiene MTL de color sin mapas; `Wasp by Poly` enlaza `waspTxt.png`, y un Flying Saucer trae PNG hermano sin referencia `map_` en su MTL. Kenney tiene `colormap.png` en tres carpetas de formato y GLB autocontenidos a verificar en una importación futura. El CSV registra estas dependencias por archivo. Ningún modelo ni textura se importó a Bee.

## Duplicados y variantes

No hay hashes SHA-256 idénticos entre los **84 archivos de modelos**. Hay **22 tríos** FBX/GLB/OBJ del mismo concepto Kenney; no son archivos byte a byte idénticos. Entre archivos auxiliares sí hay cuatro grupos de hash repetido: tres copias de `colormap.png`, MTL Kenney compartidos, y MTL/BAK idénticos entre algunos packs manuales. No borrar nada. Dos `Flying saucer`, cuatro UFO adicionales y dos `Wasp` son **familias visuales**, no duplicados confirmados. Probar un representante funcional antes de considerar variantes evita implementar múltiples naves equivalentes.

## Shortlist: 25 conceptos agrupados, no ranking de belleza

**Disponibles por licencia local; uso principalmente ambiental (12):** `tree-high`, `tree`, `plant`, `rocks-high`, `rocks-low`, `rocks-ramp`, `stones`, `bridge`, `building-platform`, `building-structure`, `building-roof`, `tent`. Los tres `rocks-*` forman una familia; las tres piezas `building-*` otra. Prioridad **ENVIRONMENT ONLY** para contraste de escala natural, no para reemplazar tecnología alien.

**Potenciales, pero bloqueados por ausencia de licencia local (13):** `Alien by Quaternius` y `Alien_01` como familia de criatura; `Tree Blob` como criatura vegetal por comprobar; `Alien Jetpack Go!` como tropa aérea; `Enemy_2Legs_Gun` como walker; `Mars Rover` como rover; `spaceship Goodnews`, ambos `Flying saucer`, `Ufo by hat_my_guy` y `UFO by marcusnikira` como familia de naves (seleccionar **uno** sólo tras comparación); `ricks ufo` y `UFO TIME` como set pieces/boss proxies provisionales. **Ninguno está autorizado para integración por esta auditoría.** `UFO TIME`, `ricks ufo` y `Mars Rover` son además técnicamente pesados. Su apariencia no fue validada con render; “prometedor” describe el rol sugerido, no calidad visual confirmada.

## Familias, progresión y vacíos frente al Bee actual

| Etapa orientativa | Familia y aporte nuevo | Límite actual |
| --- | --- | --- |
| EARLY GAME / ENVIRONMENT ONLY | Kenney árboles, plantas, rocas y puente: escala/lectura del mundo | CC0; no sustituye flores/botella ya aprobadas |
| EARLY-MID | Alien simple o UFO ligero: primera criatura alien o nave variante | sin licencia; no duplicar Probe/EyeDrone |
| MID GAME | Jetpack alien / spaceship: tropa aérea o gunship sólo si el comportamiento difiere del ranged actual | sin licencia; silueta sin revisar |
| MID-LATE | Walker armado / Mars Rover: amenaza terrestre móvil, hoy ausente | sin licencia; Rover ~22,6k tri |
| BOSS / SET PIECE | `ricks ufo` / `UFO TIME`: proxy de gran nave, no boss definitivo | sin licencia; ~26k/33k tri y muchos materiales/objetos |

Necesidades A–M: **rover** y **walker** tienen candidatos identificables; **criatura alien** y **tropa jetpack** también. **Heavy aerial**, **bombardero**, **carrier**, **control node**, **radar**, **hive-control device** y **mothership** no tienen un candidato inequívoco en metadatos locales. Los UFO podrían servir de mini-boss o nave de fondo **sólo condicionalmente** tras licencia e inspección visual. Ningún modelo de `extras` debería replicar Bee, Wasp, Probe, EyeDrone, Speeder o GroundTurret por mera variedad cosmética.

## Qué podría evitar modelado original y qué sigue bloqueado

Mini Forest puede cubrir vegetación, rocas y estructuras naturales sin Blender. Si se aclaran derechos y se confirma silueta, `Enemy_2Legs_Gun` podría ahorrar el primer walker riggeado; `Mars Rover` el rover; `Alien by Quaternius` una criatura animada; una sola nave de la familia UFO un proxy de set piece. Por ahora **todos los UFO, aliens, rover, walker y naves manuales están bloqueados por licencia local ausente**. `1 by Eric Finn` y `Owz` permanecen sin clasificar visualmente; Bee y ambos Wasp externos no son prioridad por rol duplicado.
