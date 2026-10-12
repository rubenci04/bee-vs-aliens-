# BEE — LOCAL ASSET OPPORTUNITY AUDIT 01

Parte de **ARCADE CONTENT & SPECTACLE REBUILD 02** (rama `level01-arcade-rebuild-02`). Objetivo: saber qué hay
realmente disponible en local antes de crear modelos o pedir descargas. **No se descargó nada.** Sólo se importó al
proyecto lo marcado como USADO, con licencia local verificable.

## Fuentes revisadas

| Fuente | Contenido | Licencia local |
|---|---|---|
| `D:\proyectos\V_Asset_Library\01_Extracted\kenney\*` (8 packs: blaster, food, mini-forest, modular-space, nature, prototype, space, space-station) | ~1.000 modelos GLB/FBX/OBJ | `License.txt` CC0 1.0 en cada pack — **VERIFIED SAFE** |
| `...\01_Extracted\quaternius\Easy Animated Enemy Pack - Jan 2019` (2 copias, mismo hash) | Frog, Rat, Snake, Snake_angry, Spider, Wasp (FBX animados) | `License.txt` CC0 1.0 — **VERIFIED SAFE** |
| `...\01_Extracted\quaternius\Sci-Fi Essentials Kit`, `Modular SciFi MegaKit`, `Stylized Nature MegaKit` | enemigos sci-fi, props, naturaleza | `License_Standard.txt` CC0 1.0 — **VERIFIED SAFE** |
| `...\01_Extracted\quaternius\Blends-*` | 150 `.blend` de naturaleza (árboles, rocas, cactus) | sin licencia en la carpeta — **LICENSE UNCLEAR** (y requiere Blender) |
| `...\01_Extracted\extras\*` | UFOs, naves, abeja, avispas, rover, alien, "Owz" | sin licencia local salvo los 2 Quaternius ya aprobados por verificación externa previa — resto **LICENSE UNCLEAR** |
| `...\01_Extracted\flores\*` | 15 GLB de flores (prefijos `quaternius_cc0-*`, `plaggy_cc0-*`, `eiacreations-*`, `mohamed_hassan-*`, `tilixia-*`, `gal-b-*`) | sin licencia local; el nombre del archivo no prueba CC0 (regla del proyecto) — **LICENSE UNCLEAR** |
| `...\01_Extracted\nuevos\*` | `Male_Avatar_Character_Free.blend` (255 MB), `UFO.blend`, `Space_Rocket.blend`, `Stylized_Foliage_Coniferous_Kit.blend`, `Low Poly UFO Scene By EdwinRC.fbx/.3ds`, `UFO_Wavefront.obj` | sin licencia local — **LICENSE UNCLEAR / DO NOT USE** hasta tener texto de licencia |
| `...\01_Extracted\audio\*` | Kenney (CC0), Lentikula y FX Laser (ya aprobados), Sonniss GDC 2026 | ver `docs/THIRD_PARTY_AUDIO_CREDITS.md`; no se agregó audio en esta pasada |
| `02_Selected_For_Game\*` | selección curada previa (food-kit, nature-kit, space-kit, Alien, Robot Legs Gun, Sci-Fi Essentials, Nature MegaKit) | ídem origen |
| Proyecto: `assets/models/_unassigned/human/hipster_poc.glb` | humano actual (del propio proyecto Tucumán Rush del usuario) | propio |
| Proyecto: `addons/sky_3d/`, `demo/` | plugin de cielo instalado por el usuario (sin habilitar) | fuera del alcance de este pase; no se tocó |

Hojas de miniaturas (render en runtime, sin importar nada): `dev/arcade_rebuild_v02_review/asset_audit/{humans,fauna,props,alien}.png`
(generadas con `dev/arcade_rebuild_v02_review/asset_audit_sheet.gd`; los PNG de `dev/` están ignorados por git).

## Por categoría

### Humanos
| Candidato | Licencia | Veredicto |
|---|---|---|
| Hipster (actual) | propio | se mantiene |
| Kenney `character-archer.glb` (mini-forest) | CC0 VERIFIED | **REJECT**: más cúbico/chibi que el actual, proporciones de juguete, sin `Run` adecuado para cruce gigante |
| Agente / Grandote / Ciruja (Tucumán Rush, propios) | propio | mismo estilo low-poly del Hipster: no mejoran el problema "cuadriculado" |
| `Male_Avatar_Character_Free.blend` | **UNCLEAR** | DO NOT USE (sin licencia; 255 MB de .blend, requiere Blender) |

**Conclusión:** no existe localmente un humano VERIFIED SAFE visualmente mejor. El Giant Human **no se cambia**. Hace falta asset externo (ver shortlist).

### Pájaros
No hay ningún pájaro con licencia verificable (sólo "Owz" en `extras`, OBJ sin licencia: UNCLEAR). **Falta** para Level 2 (gaviota/paloma/gorrión).

### Insectos / fauna
| Candidato | Licencia | Uso |
|---|---|---|
| **Quaternius `Frog.fbx`** (Jump/Idle/Attack/Death, 4.9 k tris) | CC0 VERIFIED (`License.txt` del pack) | **USADO AHORA**: evento de escala "La rana" (decorativo, sin colisión) |
| Quaternius `Spider.fbx` (Walk/Jump/Attack) | CC0 VERIFIED | Level 2/3: fauna controlada terrestre o set piece |
| Quaternius `Rat.fbx` (Run/Walk) | CC0 VERIFIED | Level 2 (territorio humano): cruce de escala |
| Quaternius `Snake.fbx` | CC0 VERIFIED | Level 2/3 |
| Quaternius `Wasp.fbx` | CC0 VERIFIED | referencia; la Wasp actual ya tiene visual propio |
| Polilla / mariposa / escarabajo | — | **no hay** modelo local; el escarabajo actual es procedural |
| `Bee by apelab`, `Wasp by Poly by Google` (extras) | UNCLEAR | DO NOT USE |

Segunda fauna controlada (opcional del brief): **DEFER**. La rana es excelente como evento de escala pero no como fauna
controlada de Level 01 (sería un sistema nuevo); polilla/pájaro no existen en local.

### Jardín / escala humana
| Candidato | Licencia | Uso |
|---|---|---|
| Kenney food-kit: `soda-can`, `soda-can-crushed`, `candy-bar-wrapper`, `cup-coffee`, `cookie`, `apple`, `orange`, `watermelon`, `pizza-box`, `bottle-ketchup` | CC0 VERIFIED | **útiles** como basura/props gigantes; no importados en este pase (la lata gigante de la apertura ya existe procedural) |
| Kenney nature-kit (329 modelos: troncos, piedras, pasto, flores, hongos) | CC0 VERIFIED | ya parcialmente usado; más variedad posible |
| Quaternius Stylized Nature MegaKit (68) | CC0 VERIFIED | ya usado (CommonTree, Fern) |
| `flores/*` (tulipanes 7-14 MB, girasol, nenúfar) | UNCLEAR | DO NOT USE (sin licencia local y además muy pesados) |

### Enemigos / alien
| Candidato | Licencia | Uso |
|---|---|---|
| Quaternius `Enemy_QuadShell` (cuadrúpedo con cañón) | CC0 VERIFIED | Level 2: enemigo terrestre pesado |
| Quaternius `Enemy_Trilobite` (bípedo blindado) | CC0 VERIFIED | Level 2: variante del Walker |
| Quaternius `Prop_SatelliteDish`, `Prop_Mine` | CC0 VERIFIED | dispositivos alien de escenario |
| Kenney space-kit `craft_racer/miner/speederB-D`, `alien`, `satelliteDish`, `machine_wireless` | CC0 VERIFIED | variedad de naves/dispositivos futura |
| UFOs y naves de `extras`/`nuevos` | UNCLEAR | DO NOT USE |

### VFX / audio
No se agregaron. Las cues usadas por los eventos nuevos reutilizan audio ya aprobado (`human_step`, `crate`, `ufo_charge`, `spread_pickup`).

## Importado en este pase

| Asset | Origen | Destino | SHA-256 |
|---|---|---|---|
| `Frog.fbx` | `...\quaternius\Easy Animated Enemy Pack - Jan 2019-20260929T144515Z-1-001\Easy Animated Enemy Pack - Jan 2019\FBX\Frog.fbx` | `res://assets/external/approved/fauna/quaternius/Easy Animated Enemy Pack - Jan 2019/FBX/Frog.fbx` (+ `License.txt`) | `E7366C2ED4681AA353A832E2BFEE20865717B782F3D256DFEAC0060DABBDEBEE` (idéntico en las dos copias del pack) |

Registrado en `assets/external/ASSET_PROVENANCE.md`.

## Shortlist externa (NO descargado) — máximo 5

1. **Humano estilizado suave, corriendo** — para el Giant Human. Estilo: low-poly *suave* (sin facetas cúbicas), proporciones adultas, ropa simple de jardín. GLB con esqueleto humanoide; clips `Run` y `Walk` (idealmente `Stop/LookDown`). ≤ 8 k tris. Licencia: CC0 o comercial royalty-free con texto de licencia descargable.
2. **Gaviota / paloma estilizada** — Level 2 (costa/ciudad). GLB, clips `Fly` (aleteo en loop), `Glide`, `Dive`. Silueta legible de perfil. ≤ 3 k tris. CC0/comercial.
3. **Polilla o mariposa** — fauna controlada / mundo vivo. GLB con alas separadas o clip `Flap`; ≤ 1.5 k tris; colores fuertes. CC0.
4. **Pack de basura de jardín** (botella plástica, envoltorio, tapita, colilla, lata aplastada, hoja seca grande) — escala humana. GLB estáticos ≤ 1 k tris c/u, estilo plano. CC0.
5. **Hoja seca gigante / gota de agua animable** — eventos de escala. GLB estático (la animación se hace en Godot), ≤ 500 tris. CC0.
