# Asset Library License Audit 01

Auditoría de solo lectura de `D:\proyectos\V_Asset_Library\01_Extracted` (2026-10-02). No se copió, movió, borró ni importó nada. Reglas: sección 65 de `docs/INFORME_MAESTRO.md` (aceptar CC0, dominio público, CC BY, royalty free comercial compatible; rechazar CC BY-NC, licencia desconocida, restricciones incompatibles). El nombre de un archivo o carpeta **no** cuenta como licencia.

## Cómo se clasificó la evidencia

| Tipo | Qué es | Peso |
| --- | --- | --- |
| **LOCAL** | `License.txt` / `Readme.txt` / EULA dentro del pack | Evidencia firme |
| **WEB** | Página de origen consultada hoy (2026-10-02) en `https://poly.pizza/m/<ID>`; el `<ID>` figura en el nombre de la carpeta. Misma vía que ya usa `assets/external/ASSET_PROVENANCE.md` para Alien y Robot | Evidencia válida, **no archivada localmente**. Antes de integrar hay que guardar URL y captura en `ASSET_PROVENANCE.md` |
| **DECLARADA** | Dicha en `INFORME_MAESTRO.md` (§68–71) sin archivo ni URL que la respalde | No cuenta; el pack queda DUDOSO |
| **PISTA** | Nombre de archivo, metadatos o generador | No cuenta |

Falsos positivos descartados: `flores/gal-b-water-lily-4370.glb` contiene el texto "Creative Commons Attribution-ShareAlike 3.0", pero es la licencia del **perfil de color ICC** incrustado (Elle Stone), no del modelo. `flores/plaggy_cc0-plant-pot-573.glb` contiene nodos `Sketchfab_model` y `cc0_plant_pot`: delata el origen, no la licencia.

Estilo de referencia: Visual Target aprobado (low poly facetado, colores planos, paleta cálida; cian solo para tecnología alien). Cuando no hay render propio, la valoración se marca **(estimado)**: sale de triángulos, materiales y de la revisión previa `docs/EXTRAS_SCIFI_VISUAL_REVIEW_01.md`, no de verlo en pantalla.

## Resumen

49 packs/ítems agrupados (8 Kenney 3D, 5 Quaternius, 18 modelos de `extras`, 6 grupos de `flores`, 6 de `nuevos`, 6 de audio). Los dos ZIP de Easy Animated Enemy Pack y la copia de Mini Forest dentro de `extras` son duplicados y cuentan una vez.

| Estado | Packs |
| --- | ---: |
| APROBADO | 23 |
| CON ATRIBUCIÓN | 13 |
| DUDOSO | 13 |
| RECHAZADO | 0 |

No se encontró ninguna licencia NC, de uso personal ni editorial. Los 13 DUDOSOS lo son por falta total de evidencia, no por una licencia mala.

## Tabla de packs

Rutas relativas a `D:\proyectos\V_Asset_Library\01_Extracted\`. Estilo: ENCAJA / AJUSTES (= encaja con ajustes) / NO ENCAJA.

### Kenney (modelos 3D)

| Pack | Contenido | Licencia | Evidencia | Estado | Estilo | Uso sugerido |
| --- | --- | --- | --- | --- | --- | --- |
| kenney_nature-kit | 329 modelos: flores, pasto, plantas, hongos, troncos, rocas, tocones, macetas | CC0 1.0 | LOCAL `kenney\kenney_nature-kit\License.txt` | APROBADO | ENCAJA | **Vegetación gigante** y suelo. Ya en uso (flower_purpleA/B, redA, yellowA/B, log_large) |
| kenney_mini-forest_1.0 (copia idéntica en `extras\`) | 22 modelos: árboles, rocas, `plant`, `patch-dirt`, `patch-grass`, valla, escalera, puente | CC0 1.0 | LOCAL `kenney\kenney_mini-forest_1.0\License.txt` (+ `Overview.html` en `extras`) | APROBADO | ENCAJA | Rocas y parches de tierra; valla/escalera/puente como objetos humanos o de escala |
| kenney_food-kit | 200 modelos de cocina y comida: latas, botellas, tazas, ollas, sartenes, tablas, cubiertos, barril | CC0 1.0 | LOCAL `kenney\kenney_food-kit\License.txt` | APROBADO | ENCAJA | **Objetos humanos** (latas, botellas, ollas, tazas). Ya en uso: `soda-bottle` |
| kenney_blaster-kit_2.1 | 40 modelos: blasters de juguete, dardos de espuma, granadas, cajas, blancos | CC0 1.0 | LOCAL `kenney\kenney_blaster-kit_2.1\License.txt` | APROBADO | ENCAJA | Objetos humanos de juguete (cajas, granadas, blancos) |
| kenney_space-kit | 153 modelos: naves `craft_*`, `turret_*`, antena, cohete, meteoritos, rover, hangares, un alien | CC0 1.0 | LOCAL `kenney\kenney_space-kit\License.txt` | APROBADO | AJUSTES (paleta naranja/blanco → gris/cian) | **Naves y torretas alien**. Ya en uso: `craft_speederA`, `turret_single` |
| kenney_modular-space-kit_1.0 | 40 piezas: pasillos, salas, puertas, cables | CC0 1.0 | LOCAL `kenney\kenney_modular-space-kit_1.0\License.txt` | APROBADO | AJUSTES | Interiores de nave; no sirve para el jardín. Niveles futuros |
| kenney_space-station-kit | 97 piezas de estación | CC0 1.0 | LOCAL `kenney\kenney_space-station-kit\License.txt` | APROBADO | AJUSTES | Niveles de atmósfera/espacio |
| kenney_prototype-kit | 145 piezas grises: columnas, botones, animales de bloque | CC0 1.0 | LOCAL `kenney\kenney_prototype-kit\License.txt` | APROBADO | AJUSTES (son blockout gris) | Solo prototipado; sin uso en arte final |

### Quaternius (packs)

| Pack | Contenido | Licencia | Evidencia | Estado | Estilo | Uso sugerido |
| --- | --- | --- | --- | --- | --- | --- |
| Easy Animated Enemy Pack (2 ZIP idénticos) | 6 criaturas animadas: araña, rata, avispa, serpiente, rana + 1 | CC0 1.0 | LOCAL `quaternius\Easy Animated Enemy Pack...144515Z-1-001\...\License.txt` (el otro ZIP igual) | APROBADO | ENCAJA (visto en `Preview.png`: low poly, colores planos) | **Fauna del jardín como amenaza** (araña, rana, serpiente). La avispa duplica la actual |
| Stylized Nature MegaKit [Standard] | 68 modelos: flores, pasto alto, arbustos, helechos, árboles | CC0 1.0 | LOCAL `quaternius\Stylized Nature MegaKit[Standard]\License_Standard.txt` | APROBADO | AJUSTES (texturas pintadas y hojas con alfa; cambiar a materiales planos) | Pasto/flores gigantes. Ya en uso: CommonTree_1, Fern_1 |
| Modular SciFi MegaKit [Standard] | 191 piezas modulares | CC0 1.0 | LOCAL `quaternius\Modular SciFi MegaKit[Standard]\...\License_Standard.txt` | APROBADO | NO ENCAJA (PBR oscuro con texturas, ver `Preview_1.png`) | Ninguno por ahora |
| Sci-Fi Essentials Kit [Standard] | 37 modelos: drones, robots, armas, planetas, consolas | CC0 1.0 | LOCAL `quaternius\Sci-Fi Essentials Kit[Standard]\License_Standard.txt` | APROBADO | NO ENCAJA (PBR realista, ver `Preview_1.jpg`) | Los drones araña solo como referencia de silueta |
| Blends-20260929T144335Z-1-001 | 150 `.blend` de naturaleza: árboles por estación, rocas, pasto, maíz, trigo | Sin evidencia | Ninguna: sin licencia ni readme. Solo 6 de los 150 nombres coinciden con el kit Standard gratuito (68 modelos) | **DUDOSO** | AJUSTES (estimado; mismo estilo pintado que Stylized Nature) | Nada hasta aclarar el origen. Necesitan Blender para exportar |

### `extras` (modelos sueltos; evidencia WEB poly.pizza, 2026-10-02)

Crédito CC BY 3.0: título, autor, enlace a la página, enlace a la licencia (`https://creativecommons.org/licenses/by/3.0/`) e indicar si se modificó.

| Modelo (carpeta) | Contenido | Licencia (WEB) | Estado | Estilo | Uso sugerido |
| --- | --- | --- | --- | --- | --- |
| Alien by Quaternius (`sUTLXji0aL`) | Criatura animada (9 clips), 2.6k tri | CC0 (también en `ASSET_PROVENANCE.md`) | APROBADO | AJUSTES (revisado en Lab: legible, escala/orientación por resolver) | **Enemigo alien** melee; ya aprobado |
| Robot Enemy Legs Gun by Quaternius (`lFZfDh2hzP`) | Walker armado (7 clips), 4.7k tri | CC0 (ídem) | APROBADO | AJUSTES (blanco/amarillo/rojo vs paleta alien; pivot elevado) | **Enemigo alien** terrestre; ya aprobado |
| Tree Blob by Quaternius (`0X3fUj0uUF`) | Criatura vegetal, 1.9k tri | CC0 | APROBADO | ENCAJA (estimado) | Enemigo orgánico/vegetal |
| Wasp by Quaternius (`3aQgc75sUR`) | Avispa animada, 3.7k tri | CC0 | APROBADO | ENCAJA (estimado) | Duplica la Wasp actual |
| Ufo by hat_my_guy (`NgURFR5T9m`) | UFO, 1.0k tri | CC0 | APROBADO | AJUSTES: la revisión visual lo vio como disco negro plano con silueta débil | Descartado como enemigo en la revisión previa |
| Flying saucer by Poly by Google (`fojR5i3h_nh`) | Platillo ligero, 918 tri, 4 materiales | CC BY 3.0, Poly by Google | CON ATRIBUCIÓN | AJUSTES (revisado: cúpula, borde y patas se leen; platillo clásico) | **Primer OVNI** (proxy de formación) |
| Flying saucer by Poly by Google (`b0N_HeT_Ttb`) | Platillo, 3.6k tri | CC BY 3.0, Poly by Google | CON ATRIBUCIÓN | AJUSTES (estimado; no revisado) | Variante de OVNI |
| UFO by marcusnikira (`4nCAC4jP0a`) | UFO, 1.4k tri, 4 materiales | CC BY 3.0, marcusnikira | CON ATRIBUCIÓN | AJUSTES (estimado) | Segundo OVNI candidato |
| spaceship Goodnews by Justin Scifres (`aeLvaKN3cYh`) | Nave, 5.8k tri, 11 materiales | CC BY 3.0, Justin Scifres | CON ATRIBUCIÓN | AJUSTES (revisado: aspecto juguete) | Proxy de gunship |
| Alien by jeremy (`3SD07SGSMNy`) | Alien OBJ, 1.6k tri, sin rig | CC BY 3.0, jeremy | CON ATRIBUCIÓN | ENCAJA (estimado) | Criatura alien estática |
| Alien Jetpack Go! by Damon Pidhajecky (`7VJiMcRcn6d`) | Tropa jetpack, 8k tri, 15 materiales | "Creative Commons Attribution" (la página no indica versión) | CON ATRIBUCIÓN | AJUSTES (estimado; detalle alto) | Tropa aérea; confirmar versión de licencia |
| Bee by apelab (`f0lW38lzjd4`) | Abeja OBJ, 2.9k tri | CC BY 3.0, apelab | CON ATRIBUCIÓN | ENCAJA (estimado) | Sin uso: duplica BeePlayer |
| Wasp by Poly by Google (`e-maR6CzcKc`) | Avispa con textura, 1.7k tri | CC BY 3.0, Poly by Google | CON ATRIBUCIÓN | AJUSTES (estimado) | Sin uso: duplica Wasp |
| Mars Rover by Anna M (`2qciL4mkmTz`) | Rover, 22.6k tri | CC BY 3.0, Anna M | CON ATRIBUCIÓN | NO ENCAJA (revisado: vehículo naranja industrial, muy pesado) | Ninguno |
| Owz by sirkitree (`5vbeGRwzuQl`) | Modelo 7.7k tri, identidad sin aclarar | CC BY 3.0, sirkitree | CON ATRIBUCIÓN | NO EVALUADO | Revisar visualmente |
| "1" by Eric Finn (`05X3xYCrpya`) | 66 objetos, 3.9k tri, sin aclarar | CC BY 3.0, Eric Finn | CON ATRIBUCIÓN | NO EVALUADO | Revisar visualmente |
| UFO TIME by Martin Calviello (`89hlsI17Ulw`) | UFO, 32.5k tri, 303 objetos | CC BY 3.0, Martin Calviello | CON ATRIBUCIÓN | NO ENCAJA (estimado: demasiado detalle) | Proxy de set piece; costoso |
| ricks ufo by eeee (`q6vNUoHZXr`) | UFO, 25.9k tri, 32 materiales | CC BY 3.0, eeee | CON ATRIBUCIÓN | NO ENCAJA (estimado) | Proxy de set piece; costoso |

### `flores` (15 GLB sueltos, sin ningún archivo de texto)

Evidencia en todas: ninguna. Los nombres `quaternius_cc0-...` y `plaggy_cc0-...` **no** cuentan como licencia (regla del proyecto). Hay un patrón `autor-nombre-número` sin identificar el sitio.

| Grupo | Archivos | Estado | Estilo | Uso sugerido |
| --- | --- | --- | --- | --- |
| quaternius_cc0-* (flores, cactus, sakura) | 9 GLB, 5–90 KB | DUDOSO | ENCAJA (estimado, por tamaño y materiales simples) | Flores sueltas |
| eiacreations-tulip-5441 | 1 GLB, 8.2 MB | DUDOSO | NO ENCAJA (estimado: textura pesada) | Ninguno |
| mohamed_hassan-sunflower / tulip | 2 GLB, 6–7 MB | DUDOSO | NO ENCAJA (estimado) | Ninguno |
| tilixia-summer-tulip-4376 | 1 GLB, 1.5 MB | DUDOSO | AJUSTES (estimado) | Tulipán focal |
| plaggy_cc0-plant-pot-573 | 1 GLB, 14 MB, 3 texturas; nodos `Sketchfab_model` | DUDOSO | NO ENCAJA (estimado: realista, pesado) | **Maceta** (objeto humano) si se aclara |
| gal-b-water-lily-4370 | 1 GLB, 456 KB | DUDOSO | AJUSTES (estimado) | Solo zona acuática |

### `nuevos` (8 archivos sueltos, sin texto)

| Pack | Contenido | Licencia declarada (no probada) | Estado | Estilo | Uso sugerido |
| --- | --- | --- | --- | --- | --- |
| Low Poly UFO Scene By EdwinRC (`.fbx` + `.3ds`) | Escena de OVNIs | INFORME §68: "Sketchfab, CC BY" | **DUDOSO** (DECLARADA, sin URL) | ENCAJA (estimado, por el nombre y 837 KB) | **Primer OVNI** si se confirma |
| UFO.blend + UFO_Wavefront.obj | Mismo OVNI: el `.obj` dice en su cabecera `exported from 'UFO.blend'`. Nodos `BottomGun`, `Body`, `Glass` | INFORME §69/70: "Game Ready" y/o "Battleship", royalty free | **DUDOSO** (DECLARADA; no se sabe cuál de los dos es) | NO EVALUADO | **Mini boss** si se confirma |
| Space_Rocket.blend | Cohete con 2 albedos | INFORME §71: royalty free | **DUDOSO** (DECLARADA) | NO EVALUADO | Decoración de nivel futuro |
| Stylized_Foliage_Coniferous_Kit.blend (209 MB) | Coníferas | `BEE_LEVEL_01_VERTICAL_SLICE_V01.md`: posible CGTrader "Mini Stylized Foliage Kit", Royalty Free; ningún archivo local lo ata | **DUDOSO** | AJUSTES (estimado) | Nada: no son plantas de jardín |
| Male_Avatar_Character_Free.blend (255 MB) | Personaje humano | Ninguna ("Free" en el nombre no es licencia) | **DUDOSO** | NO ENCAJA (estimado) | Ninguno |
| Frozen+Penguin+Valley.blend1 | Escena de nieve | Ninguna | **DUDOSO** | NO EVALUADO | Ninguno |

### Audio

| Pack | Licencia | Evidencia | Estado | Notas |
| --- | --- | --- | --- | --- |
| kenney_sci-fi-sounds, impact-sounds, interface-sounds | CC0 1.0 | LOCAL `audio\kenney_*\License.txt` | APROBADO | Ya en uso (`docs/THIRD_PARTY_AUDIO_CREDITS.md`) |
| Sci-Fi Weapon SFX by Lentikula | CC0 | LOCAL `audio\Sci-Fi Weapon SFX by Lentikula\Readme.txt` ("released under a CC0 license") | APROBADO | Sin uso aún |
| (free)FX_Laser_Sound_Pack | Comercial permitido | LOCAL `...\License.txt` y `README.txt` | APROBADO con restricción | **No redistribuir ni revender los originales** |
| Sonniss GDC 2026 Game Audio Bundle | Royalty-free | LOCAL `audio\Sonniss.com-GDC2026-GameAudioBundle\License - GDC Game Audio.pdf` y `Readme.txt` | APROBADO con restricciones | Sin atribución. Prohibido vender los sonidos tal cual y **prohibido entrenar IA con ellos** |

## Candidatos para la vertical slice

**Primer OVNI / mini boss**
- Hoy, con licencia verificada: Flying saucer `fojR5i3h_nh` (CC BY, 918 tri, ya revisado) y UFO marcusnikira (CC BY, sin revisar). Ninguno es un boss.
- Para mini boss no hay ningún candidato liviano con licencia verificada. UFO TIME y ricks ufo (CC BY) pesan entre 26k y 33k triángulos.
- Los candidatos que el informe prefiere (Low Poly UFO Scene, "Game Ready", "Battleship") están en `nuevos` y siguen DUDOSOS.

**Enemigos alien:** Alien by Quaternius y Robot Enemy Legs Gun (CC0, aprobados); Tree Blob (CC0); Kenney Space Kit `craft_*` y `turret_*` recoloreados (CC0). Alien by jeremy y Jetpack (CC BY).

**Vegetación gigante:** Kenney Nature Kit (flores, pasto, hongos, tocones, troncos) y Mini Forest (CC0); Stylized Nature MegaKit con materiales planos (CC0).

**Objetos humanos:** Kenney Food Kit (latas, botellas, tazas, ollas, sartenes, tablas, cubiertos, barril) y Blaster Kit (cajas, granadas, blancos) (CC0). Maceta: solo `plaggy_cc0-plant-pot` y está DUDOSO; alternativa CC0 ya aprobada: `pot_large`/`pot_small` del Nature Kit.

## Qué necesito para resolver los DUDOSOS

1. **Quaternius Blends (150 .blend):** ¿de qué página o carpeta de Google Drive los bajaste? ¿Es un pack pago o de Patreon?
2. **`flores` (15 GLB):** ¿de qué sitio? El patrón `autor-nombre-número` sugiere un sitio concreto. Con la URL de cada modelo se resuelve.
3. **Low Poly UFO Scene By EdwinRC:** la URL de Sketchfab, para confirmar autor y versión de CC BY.
4. **UFO.blend / UFO_Wavefront.obj:** la URL de CGTrader. ¿Es "UFO Game Ready" o "UFO Battleship"?
5. **Space_Rocket.blend:** URL de origen.
6. **Stylized_Foliage_Coniferous_Kit.blend:** confirmar que es el listing de CGTrader mencionado en `BEE_LEVEL_01_VERTICAL_SLICE_V01.md`.
7. **Male_Avatar_Character_Free.blend y Frozen+Penguin+Valley.blend1:** URL, o decirme que se descartan.

## Observaciones sobre los docs actuales

- `CLAUDE.md` e `INFORME_MAESTRO.md` §68–71 dan por buenas las licencias de Low Poly UFO, UFO Game Ready y Battleship. En la biblioteca no hay evidencia de ninguna.
- `ASSET_INVENTORY.md` de la biblioteca marca los 12 packs de `extras` como "LICENCIA A REVISAR". La verificación web de hoy los resuelve, pero la evidencia WEB no está archivada: conviene registrar URL y fecha por modelo en `assets/external/ASSET_PROVENANCE.md` antes de importar cualquiera.
- La consulta web se hizo con una herramienta que resume la página. Antes de integrar un modelo CC BY, abrir su página a mano y copiar título, autor y versión exactos para el crédito.
