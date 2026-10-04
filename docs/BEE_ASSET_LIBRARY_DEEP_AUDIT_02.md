# BEE — ASSET LIBRARY DEEP AUDIT 02

Fecha: 2026-10-04. Rama: `level01-threat-camera-boss-03`. Tarea de auditoría: **no se importó, copió, movió ni borró nada**
en la biblioteca ni en el runtime del juego. No se descargó nada. Ningún archivo `.import` nuevo.

Documentos hermanos: `docs/BEE_ASSET_SHORTLIST_ACTIONABLE_01.md` (qué usar, rutas exactas, compras/descargas) y
`docs/BEE_PROJECT_VIABILITY_REVIEW_01.md` (viabilidad, red flags, próximos 3 movimientos).
Auditorías previas que este documento amplía: `ASSET_LIBRARY_AUDIT_01.md` (licencias, 2026-10-02) y
`BEE_LOCAL_ASSET_OPPORTUNITY_AUDIT_01.md` (Rebuild 02).

---

## 0. Método (qué se hizo de verdad)

| Paso | Herramienta (todas en `dev/asset_audit_02/`, solo dev) | Resultado |
|---|---|---|
| Inventario de **todos** los archivos (17.193) | `find` → `data/library_files.tsv`, `data/pack_inventory.tsv` | 89 packs/ítems, 8,9 GB |
| Apertura **real** de cada modelo (2.215 únicos: un formato por modelo, glb > gltf > fbx > obj) | `probe_models.gd` (GLTFDocument / FBXDocument en runtime + lector OBJ propio `obj_loader.gd`) | `data/model_probe.tsv`: triángulos, vértices, materiales, texturas, huesos, **clips con duración**, tamaño en metros. 2.214/2.215 abren (falla 1 decal glTF del Modular SciFi) |
| Lectura de **280 `.blend` sin Blender** | `blend_probe.gd` (recorre bloques del archivo; soporta zstd "seekable" de Blender 3+) | `data/blend_probe.tsv` (objetos, mallas, armaduras, **acciones**) + 280 miniaturas embebidas en `blend_thumbs/` |
| Formato y **duración** de los 714 audios | `probe_audio.gd` (cabecera RIFF de WAV; Vorbis + `get_length()` en OGG) | `data/audio_probe.tsv` |
| **Inspección visual** | `contact_sheet.gd` (SubViewport, pose de animación real, Style C opcional) | `sheets/*_toon.png` (con Style C) y `*_raw.png` (materiales originales): humans, fauna, alien_safe, alien_doubtful, props, nature, water, doubtful_misc |
| Revisión del Giant Human | `human_compare.gd` (todos a 12,66 m, pose run/walk, abeja a escala real, línea del borde superior de la cámara E) | `sheets/human_compare_giant.png` + medición de entrepierna |
| Estructura de rigs | `tree_dump.gd` | nombres de huesos, compatibilidad de librerías de animación |

Los datos y las imágenes están en subcarpetas con `.gdignore`: el editor no las importa (no generan `.import` ni
`.translation`, que fue el ruido que dejó la auditoría de extras en `docs/`). Los PNG de `dev/` además están en `.gitignore`.

**Límites honestos**
- El audio se clasificó por metadatos, nombre, librería de origen y duración medida. **No se escuchó**: el "uso
  recomendado" es una hipótesis que el usuario debe confirmar con los oídos.
- Las licencias "WEB" de `extras` (poly.pizza) **no se re-verificaron hoy**; se toma lo registrado el 2026-10-02 en
  `ASSET_LIBRARY_AUDIT_01.md`.
- Las miniaturas de `.blend` son de 128 px (lo que Blender guarda). Sirven como evidencia de contenido, no de calidad.

---

## 1. Hallazgo principal: la biblioteca cambió hoy

`01_Extracted/nuevos/` recibió **15 packs nuevos entre las 00:52 y las 00:57 de hoy** (2026-10-04) que **ninguna
auditoría previa registró**. Algunos son lo más útil de toda la biblioteca:

| Pack nuevo | Licencia local | Por qué importa |
|---|---|---|
| **Tiny Treats – House Plants 1.0** (Isa Lousberg) | **CC0** (`License.txt`) | macetas, regaderas, pala, platos, monstera/pothos/sansevieria/yuca/suculentas: **mundo en miniatura humano-doméstico**, estilo suave que encaja con Style C |
| **KayKit – Forest Nature Pack 1.0** (Kay Lousberg) | **CC0** | árboles, arbustos, pasto, 43 rocas; suave, degradado, cerrado: **mejor encaje Style C de la biblioteca** |
| **KayKit – Adventurers 2.0** | **CC0** | 6 personajes chibi + rig con 26 clips; **no** sirven de humano gigante (ver §8) |
| **Ultimate Platformer Pack** (Quaternius) | **CC0** | Bee/Crab/Enemy/Skull animados, sierra, bola de pinchos, tuberías, nubes, cofre; personaje = conejo azul, no humano |
| Free Wild Animal 3D Models (craftpix) | solo una URL (`craftpix.net/file-licenses`) | **único pájaro** de la biblioteca (búho) + 9 mamíferos. Con esqueleto, **0 clips** |
| LowPoly Pixel RPG (Devil's Workshop) | solo una URL de itch.io | props pixel-art; estilo incompatible |
| modular_terrain_collection | **ninguna** | totoras (cattail), agua, flores: útil para lago **si** se aclara licencia |
| 9 robots vóxel (Arachnodroid, Mecha01…) | **ninguna** | estilo vóxel incompatible con Style C |
| male_casual, LowPoly Environment Pack, LowPolyTreePack.blend | **ninguna** | — |

---

## 2. Inventario total por carpeta

Rutas relativas a `D:\proyectos\V_Asset_Library\`. Tabla completa (89 filas) en `dev/asset_audit_02/data/pack_inventory.tsv`.

| Carpeta / pack | Archivos | MB | Formatos útiles | Contenido real (verificado) | Licencia |
|---|---:|---:|---|---|---|
| `01_Extracted/audio/Sonniss…GDC2026` | 350 | 7.653 | 347 WAV 48–192 kHz / 24–32 bit | 214,6 min de SFX de 63 librerías: ambientes, foley, UI, impactos, sci-fi, criaturas | Royalty-free local (PDF + Readme). Sin atribución. **No revender/redistribuir tal cual. Prohibido entrenar IA** |
| `audio/kenney_sci-fi / impact / interface` | 77 / 133 / 103 | 7,6 | OGG | láseres, motores 5 s, explosiones, impactos por material, pasos, UI | CC0 local |
| `audio/Sci-Fi Weapon SFX by Lentikula` | 16 | 17,7 | WAV 48k/24 | 5 beams (4–13 s), 5 pistolas (1,2–1,6 s), 5 rifles (1,9–2,6 s) | CC0 local (Readme) |
| `audio/(free)FX_Laser_Sound_Pack` | 13 | 0,9 | WAV 44,1k/32f | 4 shots, 4 energy impulses, 1 double, 1 UI (0,19–0,32 s) | Comercial OK; no redistribuir originales |
| `kenney/kenney_nature-kit` | 3.618 | 28 | 329 modelos (glb/fbx/obj/dae) | flores, pasto, rocas, troncos, **lirios de agua, río, canoa**, macetas, vallas | CC0 |
| `kenney/kenney_food-kit` | 1.009 | 13 | 200 modelos | latas, botellas, envoltorios, fruta, platos rotos, telgopor, caja de pizza | CC0 |
| `kenney/kenney_space-kit` | 1.694 | 18 | 153 modelos | naves `craft_*`, torretas, antenas, cristales, hangares, alien | CC0 |
| `kenney/kenney_space-station-kit`, `modular-space-kit` | 497 / 214 | 25 | 97 / 40 | interiores de estación | CC0 |
| `kenney/kenney_blaster-kit_2.1` | 211 | 4,3 | 40 | pistolas de juguete, dardos, cajas (3 clips open/close), blancos | CC0 |
| `kenney/kenney_prototype-kit` | 740 | 9,9 | 145 | blockout gris, figurines, perro/caballo/bisonte de bloques | CC0 |
| `kenney/kenney_mini-forest_1.0` (+ copia idéntica en `extras/`) | 120 | 3,1 | 22 | árboles, rocas, arquero chibi (32 clips) | CC0 |
| `quaternius/Easy Animated Enemy Pack` (2 copias idénticas) | 26 ×2 | 11,8 ×2 | 6 FBX + 6 blend | **rana, rata, serpiente ×2, araña, avispa animadas** | CC0 |
| `quaternius/Stylized Nature MegaKit` | 454 | 116 | 68 glTF | flores, pasto, hongos, trébol, pétalos, piedras, árboles (texturas con alfa) | CC0 |
| `quaternius/Sci-Fi Essentials Kit` | 292 | 174 | 37 glTF | EyeDrone (en uso), QuadShell, Trilobite, antena, mina, props | CC0 |
| `quaternius/Modular SciFi MegaKit` | 1.165 | 62 | 191 glTF | módulos de base + **3 aliens orgánicos** (Cyclop, Oculichrysalis, Scolitex) | CC0 |
| `quaternius/Blends-…` | 150 | 80 | 150 blend v2.79 | árboles por estación, rocas, cactus, **Lilypad**, maíz, trigo; sin rig | **sin licencia local** |
| `nuevos/Tiny_Treats_House_Plants` | 688 | 33 | 113 modelos | ver §1 | CC0 |
| `nuevos/KayKit_Forest_Nature_Pack` | 641 | 11 | 105 modelos | ver §1 | CC0 |
| `nuevos/KayKit_Adventurers_2.0` | 250 | 22 | 39 modelos | 6 personajes + 2 rigs de animación + 31 armas/props | CC0 |
| `nuevos/Ultimate Platformer Pack` | 549 | 85 | 110 modelos + 112 blend | ver §1 | CC0 |
| `nuevos/Free Wild Animal 3D Models` | 23 | 2,5 | 20 FBX (unity/unreal) | oso, jabalí, ciervo ×2, zorro, erizo, **búho**, conejo, ardilla, lobo | URL externa |
| `nuevos/LowPoly_Pixel_RPG…` (+ `.unitypackage` 52 MB) | 3.537 | 92 | 100 FBX + 3.381 PNG | props/personajes pixel-art | URL externa |
| `nuevos/modular_terrain_collection` | 306 | 5 | 305 OBJ | playa, cueva, acantilado, colinas, **agua, totoras**, flores | ninguna |
| `nuevos/` 9 robots vóxel | 45 | 92 | OBJ + VOX + GIF | mechas vóxel | ninguna |
| `nuevos/` sueltos | 9 | 520 | blend/fbx/obj/3ds | UFO.blend, UFO_Wavefront.obj, Low Poly UFO Scene, Space_Rocket, Male_Avatar (244 MB), Stylized Foliage (209 MB), Frozen Penguin, LowPolyTreePack, male_casual | ninguna |
| `extras/` | 18 ítems | 13 | glb/fbx/obj | UFOs, naves, Owz (insecto), Alien, Walker, Tree Blob, abejas/avispas | WEB poly.pizza (ver 01) |
| `flores/` | 15 | 37 | glb | tulipanes, girasol, nenúfar, maceta, cactus | ninguna |
| `02_Selected_For_Game/` | 27 | 16 | — | copia curada de lo ya promovido (food, nature, space, Alien, Walker, EyeDrone, Nature MegaKit) | ídem origen |
| `00_Zips/` | — | — | — | solo carpetas vacías por proveedor | — |

Totales por formato: PNG 6.618 · FBX 2.425 · OBJ 2.036 · GLB 1.083 · glTF 658 · WAV 373 (7,6 GB) · OGG 303 · BLEND 279 ·
DAE/STL 482 c/u · VOX 9 · GIF 13 · 1 `.unitypackage`.

---

## 3. Inventario por categoría

Conteo de modelos únicos verificados (un formato por modelo). "Seguro" = licencia local clara.

| Categoría | Seguro | Dudoso / externo | Lo destacable |
|---|---:|---:|---|
| **3D MODELS (total)** | ~1.800 | ~420 | 2.215 modelos únicos abiertos |
| **CHARACTERS / HUMANS** | 9 (6 KayKit, arquero Kenney, 2 astronautas Kenney, figurines) | male_casual, Male_Avatar, 8 Devil's | **ningún humano adulto seguro**; los seguros son chibi o bloques |
| **ANIMALS** | rana, rata, serpiente ×2 (Quaternius) + perro/caballo/bisonte de bloques | 10 Free Wild (incl. búho) | fauna terrestre animada sí; **aves: 0 seguras** |
| **INSECTS** | araña, avispa (Quaternius), Bee y avispa del UPP (cartoon) | Owz (insecto alado, CC BY), Bee apelab, Wasp Poly (CC BY) | **no hay** polilla, mariposa, escarabajo, libélula, mosca, mosquito ni hormiga |
| **BIRDS** | 0 | búho Free Wild (pose de vuelo, alas abiertas, 18 huesos, **0 clips**) | carencia real |
| **ALIEN / SCI-FI** | 3 aliens Modular SciFi, QuadShell, Trilobite, EyeDrone, mina, antena, 153 Kenney space, Alien + Walker (en uso), Tree Blob | 8 UFOs/naves de extras, UFO.blend, UFO_Wavefront, UFO Scene EdwinRC, 9 robots vóxel | sin **OVNI jefe** seguro de calidad (el boss actual es procedural) |
| **ENVIRONMENT** | KayKit Forest 105, Kenney nature 329, mini-forest 22, space/station 290 | modular_terrain 305, LowPoly Env 31, 150 blends | abundante |
| **GARDEN / NATURE** | Quaternius Nature 68, KayKit Forest, Kenney nature, Tiny Treats plantas | `flores/` 15, blends | abundante; **hojas sueltas gigantes**: Tiny Treats monstera/sansevieria/yuca |
| **HUMAN-SCALE PROPS** | Kenney food 200, Tiny Treats (regaderas, pala, macetas, platos), blaster kit, UPP (tuberías, sierra) | Devil's (tijera, valija, caja) | muy bueno para basura/jardín; **falta**: manguera, botella PET, colilla, tapita, juguetes de jardín |
| **VEHICLES** | Kenney space craft, rover, monorriel; canoa Kenney | Mars Rover, Goodnews (CC BY) | sin autos/bicis humanos (no hacen falta) |
| **VFX** | **0 assets de VFX** (sin texturas de partículas/flipbooks) | — | los VFX del juego son procedurales; está bien así |
| **AUDIO** | 714 archivos (676 biblioteca + 38 proyecto) | — | ver §9 |
| **MUSIC** | **0 pistas** | — | solo 4 cajitas de música de 2,6 s y 2 "braams" de 14–16 s. **Carencia real** |
| **UI** | Kenney interface (sonidos); Sonniss UI | — | **0 assets gráficos de UI** (íconos, fuentes, marcos) |
| **MISC** | prototype kit, UPP números/corazones/estrellas/monedas | Devil's 2D sprites, `.unitypackage` | UPP `Heart`, `Star`, `Coin` sirven como pickups |

---

## 4. Licencias (política estricta)

### VERIFIED SAFE (texto de licencia local claro y compatible)
- **CC0**: Kenney (8 packs 3D + 3 de audio), Quaternius Easy Animated Enemy Pack, Stylized Nature MegaKit, Sci-Fi
  Essentials, Modular SciFi MegaKit, **Ultimate Platformer Pack**, **KayKit Adventurers 2.0**, **KayKit Forest Nature
  1.0**, **Tiny Treats House Plants 1.0**, Lentikula.
- **Royalty-free con restricciones** (usables en el juego, no redistribuir sueltos): Sonniss GDC 2026 (además **prohibido
  entrenar IA**), FX Laser Sound Pack.
- Verificados por web y registrados en `ASSET_PROVENANCE.md`: Alien (Quaternius `sUTLXji0aL`) y Robot Enemy Legs Gun
  (`lFZfDh2hzP`), CC0.

### POSSIBLY USABLE — VERIFY EXTERNALLY
| Asset | Evidencia local | Qué falta |
|---|---|---|
| Free Wild Animal 3D Models (búho + 9) | `License.txt` = solo la URL `https://craftpix.net/file-licenses/` | leer y archivar el texto de licencia craftpix vigente para "freebies"; confirmar uso comercial en juego |
| LowPoly Pixel RPG (Devil's Workshop) | `ReadMe.txt` remite a itch.io | página de itch con licencia |
| `extras/` CC BY 3.0 (saucers fojR/b0N, UFO marcusnikira, Goodnews, Owz, "1", Alien jeremy, Jetpack, Bee apelab, Wasp Poly, Mars Rover, UFO TIME, ricks ufo) | verificación web del 2026-10-02, no archivada | captura/URL por modelo en `ASSET_PROVENANCE.md` + crédito exacto |
| `extras/` CC0 web (Tree Blob, Wasp Quaternius, Ufo hat_my_guy) | web 2026-10-02 | archivar URL |
| Quaternius `Blends-…` (150) | ninguna; nombres coinciden con el "Ultimate Nature Pack" de Quaternius | URL de origen; Quaternius publica CC0 pero el nombre del autor no es licencia |
| modular_terrain_collection | ninguna | origen y licencia |

### DO NOT USE (licencia o procedencia insuficiente)
`Male_Avatar_Character_Free.blend` · `male_casual/` · 9 robots vóxel · `LowPoly Environment Pack` · `LowPolyTreePack.blend` ·
`UFO.blend` + `UFO_Wavefront.obj` · `Low Poly UFO Scene By EdwinRC` · `Space_Rocket.blend` ·
`Stylized_Foliage_Coniferous_Kit.blend` · `Frozen+Penguin+Valley.blend1` · todo `flores/` (el "cc0" del nombre no es licencia).
Ninguno tiene una licencia NC conocida: están aquí por **falta de evidencia**, no por licencia mala.

---

## 5. Modelos — inspección visual por grupo

Contact sheets: `dev/asset_audit_02/sheets/`. Datos exactos por modelo: `data/model_probe.tsv`.

### 5.1 Humanos (`humans_toon.png`, `human_compare_giant.png`)
| Candidato | Licencia | Tris | Rig / clips | Visual |
|---|---|---:|---|---|
| **Hipster actual** (`assets/models/human_reuse/hipster_poc.glb`) | propio | 2.480 | 18 huesos, 6 clips (Idle, Run, Jump, Fall, Melee, Throw; sin Walk) | adulto, piernas largas, **muy cúbico** (cajas, bota-bloque) |
| KayKit Rogue/Ranger/Barbarian/Knight/Mage/Rogue_Hooded | CC0 | 5.800–8.900 | 23 huesos; 0 clips propios, 26 en los rigs (`Running_A/B`, `Walking_A/B/C`…) | **excelente factura**, suave, pero **chibi**: cabeza ≈ 40 % de la altura |
| UPP "Character" | CC0 | 2.908 | 29 huesos, 18 clips | **es un conejo azul con pijama**, no un humano |
| Kenney archer / astronauts / figurines | CC0 | 150–574 | 32 / 0 / 27 clips | bloques de juguete; peor que el actual |
| male_casual | **ninguna** | 952 | 25 huesos, **0 clips**, FBX Z-up (viene acostado) | adulto creíble, textura atlas |
| Male_Avatar_Character_Free.blend (244 MB, zstd) | **ninguna** | — | 1 armadura, **1 acción** (`Avatar_Male_ArmatureAction`), 33 imágenes | avatar realista en T-pose (miniatura): fuera de estilo y sin walk/run |
| Devil's char01–04 / player1–4 | URL | 56–232 | 0 | bloques con textura pixel; no humanos legibles |

### 5.2 Fauna e insectos (`fauna_toon.png`)
- **Quaternius Easy Animated Enemy Pack**: rana 4,9k, rata 4,0k, serpiente 1,6k, araña 2,7k, avispa 3,7k. Colores
  planos, sin texturas, siluetas claras. **El mejor grupo de fauna de la biblioteca.**
- **UPP Bee / Crab / Enemy / Skull**: 1,8–3,6k, 10 clips (4 la abeja). Muy cartoon (ojos enormes, dientes): tono
  infantil; la abeja choca con la protagonista. El cangrejo es la excepción útil (agua).
- **Free Wild** (craftpix, verificar): estilo facetado coherente, paleta por textura. El **búho viene en pose de vuelo**
  con alas abiertas y 18 huesos: se puede aletear rotando huesos por código. Ningún clip.
- **Owz** (extras, CC BY web): resultó ser un **insecto alado tipo avispa/abeja gigante** con alas translúcidas, 7,7k tris,
  sin rig. Antes figuraba "identidad sin aclarar".
- Alien (Quaternius, en uso) y Tree Blob (criatura-árbol, 1,9k, sin clips).

### 5.3 Alien / sci-fi (`alien_safe_toon.png`, `alien_doubtful_toon.png`)
- **Modular SciFi aliens**: Cyclop (2,1k, masa azul con ojo), Oculichrysalis (6,4k, crisálida naranja con ojos),
  Scolitex (11k, criatura-flor con patas y caparazón). Solo clip `Alien_Idle`. Orgánicos, raros, legibles: buen
  "organismo alien" de escenario o mini-amenaza estática. Texturas en ruta rota (ver §7).
- **QuadShell** (cuadrúpedo con cañón, 7,5k, Walk/Run/Attack/Charge/Hit/TurnOff) y **Trilobite** (bípedo blindado, 8,3k,
  Walk/Run/Attack/AttackAuto/Hanging/TurnOff): PBR oscuro, buenas animaciones.
- Kenney space `craft_*` (264–384 tris, blanco/amarillo de juguete), `turret_double`, `satelliteDish_large`,
  `machine_wireless`, `rock_crystalsLargeA`, `hangar_roundGlass`: recoloreables a gris/cian.
- UPP `Hazard_Saw`, `SpikyBall`, `Cannon`: hazards mecánicos de lectura inmediata.
- Dudosos: saucer **fojR** (918 tris, clásico con patas) y **b0N** (3,6k) son los mejores OVNIs livianos (CC BY web);
  UFO.blend (platillo verde con cúpula y 6 acciones de cañones) es el más atractivo de todos pero **sin licencia**;
  UFO_Wavefront 33,8k y UFO Scene 40,7k demasiado pesados; robots vóxel incompatibles.

### 5.4 Props humanos (`props_toon.png`)
Kenney food (latas, lata aplastada, lata abierta, ketchup, cartón, taza, envoltorios, caja de pizza, bolsa, media
manzana, sandía, banana, galleta, palito de helado, plato roto, telgopor, tenedor) y **Tiny Treats** (regaderas A/B,
pala, macetas, macetas apiladas, plato, monstera en maceta, suculentas) se leen al instante como "objetos humanos" y
aguantan bien Style C. Blaster kit: caja con tapa animada, blanco, pistola de juguete, dardo.

### 5.5 Naturaleza (`nature_toon.png` vs `nature_raw.png`)
- **KayKit Forest**: cerrados, suaves, degradados → Style C perfecto.
- **Tiny Treats hojas sueltas** (monstera 612 tris, sansevieria, yuca, pothos): **hojas gigantes** listas para escala insecto.
- **Quaternius Nature**: texturas con recorte alfa; con Style C **pierden el alfa** (ver §7).
- **Kenney nature**: planos de una cara → manchas negras con el contorno (ver §7).
- UPP árbol/arbusto con fruta y nube: cartoon redondo; la nube sirve para cielo.

### 5.6 Agua / lago (`water_toon.png`)
Seguro: Kenney `lily_large/small` (nenúfar con flor), `ground_river*`, `canoe`, `canoe_paddle`, `cliff_waterfall_*`,
`platform_beach`, `plant_flatTall`; rana, serpiente (Quaternius) y cangrejo (UPP). Verificar: totoras y agua de
modular_terrain; Lilypad de los blends. Dudoso: nenúfar de `flores/` (5,4k tris, realista).
El agua de Kenney es translúcida y el toon la vuelve opaca/negra: **el agua habrá que hacerla con shader propio** (barato).

---

## 6. Animaciones por candidato (clips reales leídos del archivo)

✔ = existe · ✘ = no existe · (n) = nombre real del clip

| Candidato | idle | walk | run | fly | attack | hit | death | jump | glide | otros |
|---|---|---|---|---|---|---|---|---|---|---|
| Hipster (actual) | ✔ Idle 2,0 s | ✘ | ✔ Run 0,8 s | ✘ | ✔ Melee 0,5 / Throw 0,7 | ✘ | ✘ | ✔ Jump 0,4 | ✘ | Fall 0,6 |
| KayKit (rig Medium) | ✔ Idle_A/B | ✔ Walking_A/B/C | ✔ Running_A/B | ✘ | ✘ (en pack pago) | ✔ Hit_A/B | ✔ Death_A/B | ✔ 5 jump | ✘ | Interact, PickUp, Throw, Use_Item, Spawn_Air/Ground |
| UPP Character (conejo) | ✔ | ✔ (+_Gun) | ✔ (+_Gun/_Shoot) | ✘ | ✔ Punch | ✔ HitReact | ✔ | ✔ 3 | ✘ | Duck, Wave, Yes/No, Idle_Shoot |
| Kenney archer | ✔ | ✔ | ✔ sprint | ✘ | ✔ melee/kick | ✘ | ✔ die | ✔ | ✘ | 32 clips (holding, wheelchair…) |
| male_casual / Male_Avatar | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ | Male_Avatar: 1 acción genérica |
| **Frog** (en uso) | ✔ 2,50 s | ✘ | ✘ | ✘ | ✔ 0,75 | ✘ | ✔ 0,83 | ✔ 0,88 | ✘ | **sin nadar** |
| **Rat** | ✔ 2,38 | ✔ 1,33 | ✔ 0,50 | ✘ | ✔ 0,67 | ✘ | ✔ 1,08 | ✔ 0,83 | ✘ | — |
| **Snake / Snake_angry** | ✔ 2,08 | ✔ 0,83 | ✘ | ✘ | ✔ 0,67 | ✘ | ✘ en FBX (✔ en .blend) | ✔ 0,96 | ✘ | — |
| **Spider** | ✔ 4,17 | ✔ 0,83 | ✘ | ✘ | ✔ 0,75 | ✘ | ✔ 1,04 | ✔ 0,71 | ✘ | — |
| Wasp (Quaternius) | ✘ | ✘ | ✘ | ✔ Flying 1,50 | ✔ 0,75 | ✘ | ✔ 0,75 | ✘ | ✘ | — |
| UPP Bee | ✘ | ✘ | ✘ | ✔ 1,13 | ✔ Bite_Front | ✔ HitRecieve | ✔ | ✘ | ✘ | — |
| UPP Crab / Enemy / Skull | ✔ | ✔ | ✘ | ✘ | ✔ Bite_Front/InPlace | ✔ | ✔ | ✔ | ✘ | Dance, Yes, No |
| Alien Quaternius (en uso) | ✔ | ✔ | ✘ | ✘ | ✔ Bite_Front | ✔ | ✔ | ✔ | ✘ | Dance, Yes, No |
| Free Wild (10, incl. búho) | ✘ | ✘ | ✘ | ✘ (búho posado en pose de vuelo) | ✘ | ✘ | ✘ | ✘ | ✘ | solo esqueleto (16–27 huesos) |
| Alien Cyclop / Oculichrysalis / Scolitex | ✔ Alien_Idle 3,3 s | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ | — |
| EyeDrone (en uso) | ✔ | ✘ | ✘ | (flota) | ✔ | ✔ Hit | ✘ | ✘ | ✘ | BackFlip, Charging, Look |
| QuadShell | ✔ | ✔ | ✔ | ✘ | ✔ | ✔ | ✘ | ✘ | ✘ | Charge, Look, TurnOff |
| Trilobite | ✔ | ✔ | ✔ | ✘ | ✔ + AttackAuto | ✔ | ✘ | ✘ | ✘ | Hanging, Look, TurnOff |
| Walker (en uso) | ✔ | ✔ | ✔ | ✘ | ✔ + Shoot | ✘ | ✔ | ✔ | ✘ | — |
| UFO.blend (dudoso) | — | — | — | — | 6 acciones de cañones | — | — | — | — | — |
| UPP Hazard_SpikeTrap / Bouncer / Chest | — | — | — | — | Activate / Bounce / Open | — | — | — | — | — |
| Kenney blaster crates | — | — | — | — | — | — | — | — | — | open / close |

Ningún asset de la biblioteca tiene **glide** ni **swim**. Para aves, aleteo procedural por hueso es la vía realista.

---

## 7. Compatibilidad con Style C

Escala 1–5 (5 = mejor). En **import** 5 = trivial, 1 = muy costoso. Probado con `BeeToonStyle.apply` real
(`*_toon.png`) frente a materiales originales (`*_raw.png`).

| Candidato | Silueta | Topología | Suavidad | Proporción | Animación | Adapt. Style C | Utilidad | Import | Toon 2–3 bandas | Outline | Paleta | Rim |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Hipster (actual) | 3 | 2 | 1 | 4 | 2 | 3 | 4 | 5 | sí (planos duros) | se ve "sticker" a 6× (por eso va sin outline) | sí | sí |
| KayKit Rogue (humano) | 5 | 5 | 4 | **1** | 4 | 5 | **1** | 4 | sí | sí | sí (textura degradada) | sí |
| UPP Character | 4 | 4 | 4 | 1 | 5 | 4 | 1 | 4 | sí | sí | sí | sí |
| Rana Quaternius | 4 | 4 | 3 | 4 | 3 | 4 | 4 | 4 | sí | sí | sí (colores de material) | sí |
| Rata | 4 | 4 | 3 | 4 | 5 | 4 | 4 | 4 | sí | sí | sí | sí |
| Araña | 5 | 4 | 3 | 4 | 4 | 4 | 5 | 4 | sí | patas finas: outline engrosa, usar ancho bajo | sí | sí |
| Serpiente | 4 | 4 | 3 | 3 | 3 | 4 | 3 | 4 | sí | sí | sí | sí |
| UPP Crab | 4 | 4 | 4 | 3 | 5 | 4 | 3 | 4 | sí | sí | sí | sí |
| Búho Free Wild | 4 | 3 | 2 | 4 | 1 | 3 | 4 | 2 | sí | sí | requiere repintar atlas | sí |
| Owz (insecto) | 4 | 3 | 2 | 4 | 1 | 3 | 3 | 3 | sí | alas: usar material de ala | sí | sí |
| Alien Scolitex | 4 | 3 | 3 | 4 | 1 | 3 | 3 | 2 | sí | sí | texturas a reubicar | sí |
| QuadShell / Trilobite | 4 | 4 | 3 | 4 | 4 | 3 | 4 | 3 | sí, pero PBR oscuro → recolorear | sí | requiere repintar | sí |
| Kenney craft_* | 4 | 4 | 2 | 4 | 1 | 4 | 3 | 5 | sí | sí | recolor gris/cian simple | sí |
| Saucer fojR (CC BY web) | 4 | 4 | 3 | 4 | 1 | 4 | 4 | 4 | sí | sí | sí | sí |
| Tiny Treats (props/hojas) | 5 | 5 | 5 | 5 | — | 5 | 5 | 5 | sí | sí | sí | sí |
| KayKit Forest | 5 | 5 | 5 | 5 | — | 5 | 5 | 5 | sí | sí | sí | sí |
| Kenney food | 5 | 4 | 3 | 5 | — | 4 | 5 | 5 | sí | sí | sí | sí |
| Kenney nature (planos) | 4 | 3 | 2 | 4 | — | 2 | 4 | 5 | sí | **no** (manchas negras) | sí | sí |
| Quaternius Nature (alfa) | 4 | 3 | 4 | 4 | — | 2 | 4 | 4 | **pierde el alfa** | no | sí | sí |

**Hallazgos técnicos de Style C** (útiles para cualquier integración futura):
1. **Geometría de una sola cara** (pasto/flores Kenney, trébol/pétalos Quaternius, agua Kenney): el contorno *inverted
   hull* pinta de negro la cara vista por detrás. Aplicar `BeeToonStyle.apply(model, false)` o material doble cara.
2. **Recorte alfa**: `toon_body.gdshader` no hace alpha-scissor; el follaje con textura alfa (Quaternius Nature: arbusto
   con flores, Flower_4, trébol) se vuelve un bloque. Mantener material original o agregar alpha-scissor al toon.
3. **Agua translúcida** de Kenney → shader propio.
4. **Modular SciFi MegaKit**: los glTF referencian texturas en `glTF/<subcarpeta>/T_Trim_*.png` que no existen ahí
   (están en otra carpeta del pack): al promover, reubicar texturas. 863 errores de carga solo por esto.
5. **FBX con textura externa** (Free Wild, male_casual, Devil's) no carga la textura en runtime; al importarlos en el
   editor sí. `male_casual` viene en Z-up (acostado).
6. KayKit/Tiny Treats usan una textura-degradado compartida: el toon la respeta y mantiene el look suave.

---

## 8. Giant Human — revisión especial

**Conclusión: NO existe en la biblioteca local un reemplazo VERIFIED SAFE mejor. No se hizo POC de reemplazo.**

Evidencia (`sheets/human_compare_giant.png`, todos a 12,66 m = altura actual 2,11 m × 6, pose run/walk, Style C sin
contorno como en Level 01, abeja a escala real, línea roja = borde superior visible de la cámara E, 7,1 m):

| Modelo | Entrepierna (hueso de muslo, posado) | % de la altura | Lectura |
|---|---:|---:|---|
| **Hipster actual** | **5,5 m** | **43 %** | adulto; el corredor entre piernas (2,4 m mínimo) cabe de sobra |
| KayKit Rogue | 2,6 m | 21 % | chibi: cabeza y torso dominan; piernas cortas |
| KayKit Knight | 2,4 m | 19 % | ídem |
| UPP Character | 1,6 m | 13 % | conejo; no humano |
| Kenney archer | — (sin huesos) | — | bloque |

Por qué los candidatos son **peores** aunque estén mejor modelados:
1. **Rompen la mecánica**: el cruce del humano se basa en volar entre piernas largas y bajo un torso que empieza a
   Y≈3,2 m. Un chibi a la misma altura tiene la entrepierna a 2,4–2,6 m: no queda corredor jugable.
2. **Rompen la escala**: un chibi gigante se lee como "muñeco/juguete", no como "humano colosal".
3. **Rompen el tono**: KayKit son aventureros de fantasía medieval (capa, armadura, sombrero de mago).
4. El único adulto suave (`male_casual`) no tiene licencia ni clips; Male_Avatar es realista, 244 MB, sin walk/run.

**Reencuadre importante** (ver `dev/level01_transformation_review/08_giant_human.png`): con la cámara E, del humano
solo se ve **una pierna con jean y una bota** (y a veces la mano). El problema real no es "el humano entero es cúbico",
sino que **la bota es un bloque gris y el jean tiene facetas duras**. Por eso la solución recomendada es un asset de
**piernas + zapatilla** (o un humano estilizado adulto cuya prioridad sean piernas/calzado), no un personaje completo
cualquiera. Especificación exacta en `BEE_ASSET_SHORTLIST_ACTIONABLE_01.md`, descarga #1.

---

## 9. Audio — revisión completa

Formato y duración medidos. Sonniss viene a 96/192 kHz 24–32 bit estéreo: al integrar, convertir a 44,1/48 kHz 16 bit
(mono para SFX), como ya hace el pipeline del proyecto. Licencias: K = Kenney CC0 · L = Lentikula CC0 · FX = FX Laser
(comercial, no redistribuir) · S = Sonniss (royalty-free, no redistribuir, no entrenar IA).
Rutas: `D:\proyectos\V_Asset_Library\01_Extracted\audio\` + lo indicado (Sonniss abreviado `SON\<librería>\`).

Ya usados en el juego (no repetir búsqueda): `laserSmall_000` (base), `impactPunch_medium_*`, `forceField_000` +
`lowFrequency_explosion_000` (bomba), `impactPlank_medium_000`, `footstep_grass_000` (×0,7), `minimize_001`,
`maximize_001`, Highlands of Norway (ambiente), Toy Quadcopter (aleteo), Halloween Game (sting OVNI).

### PLAYER
| Uso | Archivo | Formato | Dur. | Lic. | Recomendación |
|---|---|---|---:|---|---|
| firing | `(free)FX_Laser_Sound_Pack\…\Laser_Shot_01..04.wav` | 44,1k 32f st | 0,19–0,22 s | FX | alternativa más "energía" al laserSmall actual; 4 variaciones = no repetitivo |
| firing | `kenney_sci-fi-sounds\Audio\laserRetro_000..004.ogg` | OGG | 0,23–0,28 s | K | variación retro para el disparo base |
| spread | `…FX_Laser…\Laser_Impulse_Double_01.wav` | 44,1k | 0,32 s | FX | doble impulso = lectura de "3 disparos" |
| spread | `…FX_Laser…\Energy_Impulse_01..04.wav` | 44,1k | 0,21–0,32 s | FX | capa para el spread |
| charge | `SON\InMotionAudio - Arc\ELECArc_ArcPowerUpDesign04_….wav` | 96k/24 | 7,48 s | S | recortar 0,8–1,2 s: carga de bomba/aguijón |
| impact (golpe a enemigo tech) | `kenney_impact-sounds\Audio\impactMetal_light_000..004.ogg` | OGG | 0,21–0,48 s | K | variaciones de `tech_hit` |
| impact (orgánico) | `SON\Epic Stock Media - Anime Game\FGHTImpt_Combat Punch Impact Light Hit…_05_ESM_AG.wav` | 96k | 1,06 s | S | recortar: golpe con más cuerpo |
| damage | `kenney_impact-sounds\Audio\impactPunch_heavy_000..004.ogg` | OGG | 0,46–0,65 s | K | daño fuerte (overload, humano) |
| damage | `SON\Cinematic Sound Design - Cartoon Bloopers\Arrow Hit Rattle.wav` | 96k | 1,08 s | S | daño con humor |
| wing/movement | `SON\344 Audio - Barbershop Vol. 2\OBJMisc_Wahl Sterling Trimmer, On, Idle, Off_….wav` | 96k | 44,7 s | S | **zumbido de insecto creíble** (máquina de cortar pelo); loop del idle para avispas |
| wing/movement | `SON\InMotionAudio - Arc\ELECBuzz_Buzz27_InMotionAudio_Arc.wav` | 96k | 9,8 s | S | zumbido eléctrico: implante alien |
| pickup | `SON\CB_Sounddesign - Applicable Sounds…\UIMisc_Kalimba 3 Up_….wav` | 48k | 0,55 s | S | pickup de polen (orgánico, cálido) |
| pickup | `SON\Epic Stock Media - Fantasy Game 2…\UIAlert_Collect Scifi Futuristic Electronic Bass Burst Sweep Heavy 04_ESM_FG2.wav` | 96k | 0,31 s | S | pickup de tecnología alien |

### ENEMIES
| Uso | Archivo | Formato | Dur. | Lic. | Recomendación |
|---|---|---|---:|---|---|
| alien shots | `Sci-Fi Weapon SFX by Lentikula\Laser Pistol 1..5.wav` | 48k/24 st | 1,23–1,59 s | L | disparo enemigo (recortar cola a ~0,4 s) |
| alien shots (pesado) | `Sci-Fi Weapon SFX by Lentikula\Laser Rifle 1..5.wav` | 48k/24 | 1,88–2,55 s | L | barrido del Walker |
| alien shots | `kenney_sci-fi-sounds\Audio\laserLarge_000..004.ogg` | OGG | 0,68–0,74 s | K | abanico del EyeDrone |
| organic | `SON\SoundBits - Vox Bestiae - Source Elements\CREAInsc_Insectoid Creature Tremble Attack Long 1_….wav` | 96k mono | 2,47 s | S | **aviso de embestida de la avispa** |
| organic | `SON\Epic Stock Media - Anime Game\DSGNMisc_Misc Monster Tentacle Modulated Creature…_02_ESM_AG.wav` | 96k | 2,04 s | S | RANGED del Organic Alien |
| organic | `kenney_sci-fi-sounds\Audio\slime_000/001.ogg` | OGG | 0,50 / 4,71 s | K | bio-orbes |
| mechanical | `SON\Epic Stock Media - Tower Defense Game\ROBTMvmt_Tower Deploy Hitech Robot Motor Dark Thump Servo Whine 04_ESM_TDG.wav` | 96k | 1,04 s | S | torreta desplegándose / Walker |
| mechanical | `SON\The Noisery - Moaning Metal\DSGNImpt_Metal Hit Thud Thump Low Ring Geofon 1_….wav` | 192k mono | 5,17 s | S | pisada pesada del Walker (recortar) |
| warnings | `SON\Cinematic Sound Design - System & UI Feedback Elements\Interface Sci-Fi Ping Down.wav` | 96k | 0,75 s | S | telegrafía genérica |
| warnings | `SON\Epic Stock Media - Halloween Game…\UIAlert_Alert Designed Transition Swell Creature Strange Alien Layered 01_ESM_HALG.wav` | 96k | 6,14 s | S | anuncio de amenaza grande |
| charge | `SON\Epic Stock Media - Elemental Mutation Whooshes and Impacts\ELECMisc_Impact Electric Tonal Deep Movement Motion Hiss Glitch 01_ESM_EMWI.wav` | 96k | 3,69 s | S | carga violeta del barrido |
| explosions | `SON\Epic Stock Media - Anime Game\EXPLDsgn_Explosion Small Blast Enemy Death Crunchy Boom Cartoon Noisy Crash Impact Delay 03_ESM_AG.wav` | 96k | 1,48 s | S | **muerte de enemigo** (el nombre lo dice; arcade) |
| explosions | `kenney_sci-fi-sounds\Audio\explosionCrunch_000..004.ogg` | OGG | 0,78–1,98 s | K | variaciones |

### WORLD
| Uso | Archivo | Formato | Dur. | Lic. | Recomendación |
|---|---|---|---:|---|---|
| garden ambience | `SON\Just Sound Effects - Highlands of Norway\AMBSwmp_Meadow Pipits calling many Insects humming Wind blowing through Grass_JSE_HoN_Stereo.wav` | 96k | 86,5 s | S | **en uso** (loop de 21,5 s). Se puede alargar el loop |
| garden ambience (alt.) | `SON\344 Audio - East Coast America Vol. 1\AMBSubn_Ambience, Forest Crickets, Birds, Connecticut 02_….wav` | 96k | 52,3 s | S | tramo atardecer del Level 01 |
| insects / noche | `SON\Epic Stock Media - Synthesized Nature Loops and Sounds\AMBTrop_Loop Ambience Jungle Night Humid Birds Bug Chirps 01_ESM_SNLS.wav` | 96k | 41,6 s | S | loop nativo; jardín contaminado |
| wind | `SON\Epic Stock Media - Synthesized Nature Loops and Sounds\WINDInt_Loop Weather Wind Whipping Constricted Flow Turbulent 01_ESM_SNLS.wav` | 96k | 7,5 s | S | ráfagas (hazard de viento) |
| wind | `SON\344 Audio - Elemental Palette Designed Vol. 1\WINDDsgn_Wind, Rush, Whoosh, Long x5 01_….wav` | 96k | 1,05 s | S | paso de objeto gigante |
| leaves | — | — | — | — | **no hay** follaje/hojas secas. Probar `Cinematic Sound Design - Paper Foley\Encyclopedia Glossy Page Turn Muted.wav` (escuchar) |
| footsteps (humano gigante) | `SON\TheWorkRoom - Flip Flops\FFG002.wav` / `FFW003.wav` | 96k | 39,2 / 31,5 s | S | **ojotas**: pasos del humano con humor (cortar 3–4 golpes) |
| impacts | `SON\Cinematic Sound Design - Colossal Impacts\Impact Cut Sweep.wav` | 96k | 2,79 s | S | aterrizaje de objeto gigante |
| human props | `SON\344 Audio - Barbershop Vol. 1\OBJMisc_Spray Bottle, Spray 1_….wav` | 96k | 0,52 s | S | **pulverizador de jardín** como hazard |
| human props | `SON\344 Audio - Barbershop Vol. 1\OBJMisc_Hair Dryer, On, Idle, Off 4_….wav` | 96k | 12,3 s | S | soplador/viento humano |
| human props | `SON\Ivo Vicic - Campfire - Bonfire FX\42 Campfire, Putting Out Fire, Water from Bottle, Variation, Close.wav` | 96k | 30,9 s | S | **chorro de regadera** (escuchar) |
| human props | `SON\344 Audio - Dog Vocalisations Vol. 1\ANMLDog_Dog Barks, Multiple, Indoors, Perspective,_….wav` | 96k | 5,9 s | S | perro lejano (mundo humano) |
| human props (lejanía) | `SON\Epic Stock Media - Public Spaces - Crowds Walla…\CRWDChld_Walla Children Kids Daytime School Playing…_ESM_CPS.wav` | 96k | 147 s | S | niños jugando lejos: "hay humanos cerca" |
| lake | `SON\Epic Stock Media - Public Spaces - Storms Lakes Parks…\WATRLap_Summer Tennessee Lake Dock Water Ripples Wake Wave Gentle 05 Distant_ESM_CPS.wav` | 96k | 103 s | S | **ambiente de lago** |
| lake | `SON\Just Sound Effects - Highlands of Norway\WATRLap_Small Waves sloshing onto Rock Slabs at huge Glacial Lake _JSE_HoN_Quad.wav` | 96k **4 canales** | 92 s | S | lago (hay que bajar a estéreo) |
| water hit | `SON\344 Audio - Elemental Palette Designed Vol. 1\WATRMisc_Water, Liquid Impact, Bubble, Sci Fi, Hit 04_….wav` | 96k | 1,21 s | S | gota/burbuja alien |
| frog | `SON\Epic Stock Media - Synthesized Nature Loops and Sounds\ANMLAmph_Animal Frog Echo Short Squished Frequency Formant 03_ESM_SNLS.wav` | 96k mono | 2,32 s | S | **croar de la rana** (ya tenemos el modelo) |
| aquatic creature | `SON\SoundBits - Vox Bestiae - Source Elements\CREAAqua_Aquatic Creature Gurgling 2_….wav` | 96k mono | 4,17 s | S | criatura del lago |
| storm | `SON\InMotionAudio - Back Garden Storm\STORM_StormAmbience11/13_….wav` | 96k | 205 / 151 s | S | jardín con tormenta (nivel futuro) |

### UFO
| Uso | Archivo | Formato | Dur. | Lic. | Recomendación |
|---|---|---|---:|---|---|
| engine / hum | `SON\344 Audio - Air Designed\AEROJet_Unidentified Encounter_344 Audio_Air Designed.wav` | 96k | 58,0 s | S | **diseñado como "encuentro no identificado"**: entrada del OVNI |
| engine / hum | `kenney_sci-fi-sounds\Audio\spaceEngineLow_000..004.ogg` / `engineCircular_*` | OGG | 5,0 s (loops) | K | hover (ya hay uno de Kenney) |
| hum (capa grave) | `SON\Epic Stock Media - Strange Game Ambient Loops 3\DSGNSynth_Scifi Loop Ship Reactor Synth Layer Layered Saw Buzz_ESM_SGA3.wav` | 96k | 60 s | S | reactor del boss |
| hum (ambiente) | `SON\Cinematic Sound Design - Sci-Fi Drones\Dark Industrial Ambience.wav` | 96k | 31,3 s | S | jardín invadido |
| lasers | `Sci-Fi Weapon SFX by Lentikula\Laser Beam 1..5.wav` | 48k/24 | 4,1–13,1 s | L | **rayo del boss** (loop sostenido) |
| alarms | `SON\Federico Soler - Effective Trailer Alarms Vol. 2\EffectiveTrailer_Alarms_Vol2_*.wav` (3) | 48k | 30 s | S | alarma de invasión (fase 3) |
| explosions | `SON\Federico Soler - Effective Trailer Booms Vol. 2\EffectiveTrailer_Booms_Vol2_011/075/214.wav` | 96k | 15–17 s | S | **muerte del boss** (cortar el golpe) |
| explosions | `SON\Ivo Vicic - Fireworks FX\13 Fireworks_powerful explosions_multiples in a row_near.wav` | 96k | 24,2 s | S | cadena de explosiones al morir |
| sting | `SON\Jake Fielding - Cinematic Horn Braams\…Huge-32.wav` / `…-67.wav` | 96k | 16,5 / 13,7 s | S | revelación del OVNI (trailer) |

### UI
| Uso | Archivo | Dur. | Lic. |
|---|---|---:|---|
| confirm | `kenney_interface-sounds\Audio\confirmation_001..004.ogg` | 0,29–0,54 s | K |
| confirm | `SON\Cinematic Sound Design - Interface & Infographics\Interface Accept Glassy Snap.wav` | 0,44 s | S |
| warning | `SON\Cinematic Sound Design - System & UI Feedback Elements\Interface Deny Low Fat Dark.wav` | 0,74 s | S |
| warning | `kenney_interface-sounds\Audio\error_001..008.ogg` | 0,10–0,53 s | K |
| pickup | `SON\Cinematic Sound Design - UI Interaction Elements\Ting Coins.wav` | 1,10 s | S |
| upgrade | `SON\Epic Stock Media - Anime Game\DSGNStngr_Power Up Bright Positive Successful Light Saturation Crash Shimmer 05_ESM_AG.wav` | 1,52 s | S |
| upgrade | `SON\Cinematic Sound Design - User Interface\Button Arp Twinkle.wav` | 1,81 s | S |

### MUSIC
**No existe música en la biblioteca.** Lo más cercano: 4 cajitas de música (`Sonic Bat - Music Boxes`, 1,6–2,8 s,
192k mono), 2 horn braams (stingers), 3 alarmas rítmicas de trailer. El bus `Music` del proyecto está vacío. Es una
carencia real (ver shortlist, descarga #5).

---

## 10. Oportunidades de enemigos (nueva función, no reskin)

| Candidato | Licencia | Mecánica nueva | Por qué ayuda | Estilo |
|---|---|---|---|---|
| **Araña** (Quaternius) | CC0 | **hazard vertical**: baja colgada de un hilo desde arriba del encuadre y sube (Idle/Walk/Attack/Death); el hilo es el telegraph | hoy todas las amenazas vienen de la derecha; ésta ataca el eje Y y castiga quedarse arriba | encaja; outline fino |
| **Rata** (Quaternius, Run 0,5 s) | CC0 | **cruce rápido por el suelo** que patea basura/proyectiles hacia arriba | castiga la ruta baja (polen) que hoy es segura | encaja |
| **Serpiente** | CC0 | **emboscada desde el pasto**: asoma, telegrafía y lanza mordida en arco | amenaza que obliga a leer el suelo | encaja |
| **Alien Scolitex / Oculichrysalis** | CC0 | **organismo alien fijo** (nido): genera popcorn hasta destruirlo; enemigo grande persistente | da un objetivo con prioridad, no "otro que entra y sale" | encaja (raro, orgánico) |
| **QuadShell** | CC0 | **enemigo pesado persistente** que avanza por el suelo con el scroll y dispara Charge | hoy el Walker es el único "heavy" | AJUSTES (recolor) |
| **Trilobite** (clip `Hanging`) | CC0 | cuelga del techo de una hoja/maceta y cae | variante vertical para Level 02 | AJUSTES |
| UPP `Hazard_Saw` / `SpikyBall` | CC0 | hazard móvil indestructible (sierra = tijera de podar alien) | obstáculos con patrón, no enemigos | AJUSTES (recolor metal/cian) |
| **Búho** (Free Wild, verificar) | VERIFY | **depredador que cruza el cielo** en picada (aleteo por huesos) | fauna controlada grande; amenaza "de escala" | encaja facetado |
| Owz (CC BY web) | VERIFY | insecto gigante controlado (mini-jefe orgánico) | variedad de insecto que no sea avispa | AJUSTES |
| Tree Blob (CC0 web) | VERIFY archivo | planta-criatura que se arranca del suelo | sorpresa del jardín | encaja |
| **Rana** (en uso, decorativa) | CC0 | **amenaza de lengua**: telegrafía (Idle→Attack 0,75 s) y barre una franja | convierte el evento de escala en gameplay sin modelo nuevo | encaja |
| **UPP Crab** | CC0 | enemigo **anfibio de orilla** (camina, muerde en el sitio) | nivel de lago | cartoon, aceptable |

## 11. Oportunidades de mundo en miniatura

| Plano | Candidatos (todos CC0) | Rol |
|---|---|---|
| **Foreground** | Tiny Treats hojas sueltas (monstera, sansevieria, yuca), KayKit `Grass_1/2`, Kenney `soda-can-crushed`, `candy-bar-wrapper`, `popsicle-stick` | marco cercano que refuerza "soy diminuta" |
| **Midground** | Tiny Treats `pot_A_large`, `pots_stacked`, `saucer_A_large`, regaderas; Kenney `pizza-box`, `cup-coffee`, `mug`, `carton`, `apple-half`, `watermelon`; KayKit `Rock_*`, `Bush_*` | obstáculos y cobertura de escala humana |
| **Background** | KayKit `Tree_*`, Tiny Treats `monstera_plant_large_potted`, `yucca_plant_large`; Kenney `fence_*`, UPP `Cloud_*` | horizonte de jardín doméstico |
| **Animated moment** | regadera que inclina y "llueve" (Tiny Treats + partículas), caja de blaster que se abre (clip), rana (clips), perro ladrando fuera de cuadro (audio) | respiros con vida |
| **Set piece** | maceta gigante caída como túnel; caja de pizza abierta como hangar alien; pala clavada | encuentros memorables |
| **Destructible** | `crate-*` (blaster, con clip de tapa), `styrofoam`, `plate-broken`, `soda-can` | romper cosas humanas |
| **Scale reference** | `soda-can` (0,35 m real), `cup-coffee`, `banana`, `shovel` (0,83 m), `watering_can_B` (1,15 m) | objetos que todo jugador sabe medir |

## 12. Futuro nivel de agua / lago (solo oportunidad detectada; **no implementar ahora**)
- **Fauna**: rana (CC0, ya importada; Idle/Jump/Attack/Death; sin nadar) = candidata natural a **jefe o amenaza grande
  del lago** (lengua, saltos que hacen olas). Serpiente de agua (CC0), cangrejo UPP (CC0). Criatura acuática: solo audio.
- **Escenario**: Kenney `lily_large/small`, `ground_river*`, `canoe`, `canoe_paddle`, `cliff_waterfall_*`,
  `platform_beach`, `plant_flatTall`; verificar totoras/agua de modular_terrain y Lilypad de los blends.
- **Audio**: lago Tennessee (103 s), olas de lago glacial (92 s, 4 canales), croar sintético (2,3 s), gorgoteo acuático
  (4,2 s), impacto de agua sci-fi (1,2 s), burbujas cartoon (0,9 s).
- **Falta**: superficie de agua con shader propio (barato), libélula/zapatero de agua, pez. No hay ningún pez.

## 13. Assets que NO debemos usar
- Todo lo de §4 DO NOT USE (sin licencia), aunque visualmente tienten: **UFO.blend** (el mejor platillo de la biblioteca)
  y **male_casual** (el único adulto suave).
- Robots vóxel: además de sin licencia, el vóxel contradice Style C.
- Devil's Workshop: pixel-art, otro juego.
- UPP Bee como enemigo: es una abeja cartoon que confunde con la protagonista.
- KayKit Adventurers como Giant Human (§8).
- UFO_Wavefront (33,8k), UFO Scene EdwinRC (40,7k), UFO TIME (32,5k), ricks ufo (25,9k): pesados y fuera de estilo.
- Free Wild y CC BY de extras: **no integrar** hasta archivar la licencia; no están prohibidos, están pendientes.
