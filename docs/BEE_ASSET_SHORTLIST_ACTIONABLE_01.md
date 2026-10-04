# BEE — ASSET SHORTLIST ACTIONABLE 01

Fecha: 2026-10-04. Derivado de `docs/BEE_ASSET_LIBRARY_DEEP_AUDIT_02.md` (evidencia, sheets, datos).
Nada de esto se importó todavía. Para promover cualquier asset: copiar solo el archivo + `License.txt` del pack a
`assets/external/approved/<rol>/…`, registrar fuente/autor/licencia/SHA-256 en `assets/external/ASSET_PROVENANCE.md`
y, si es audio, en `docs/THIRD_PARTY_AUDIO_CREDITS.md` + `audio/sfx/PROVENANCE.md`. **Una tarea por prompt.**

Abreviaturas de ruta (todas bajo `D:\proyectos\V_Asset_Library\01_Extracted\`):
`TT` = `nuevos\Tiny_Treats_House_Plants_1.0_FREE\Tiny_Treats_House_Plants_1.0_FREE\Assets\gltf\` ·
`KF` = `nuevos\KayKit_Forest_Nature_Pack_1.0_FREE\KayKit_Forest_Nature_Pack_1.0_FREE\Assets\gltf\` ·
`KFD` = `kenney\kenney_food-kit\Models\GLB format\` · `KN` = `kenney\kenney_nature-kit\Models\GLTF format\` ·
`QE` = `quaternius\Easy Animated Enemy Pack - Jan 2019-20260929T144515Z-1-001\Easy Animated Enemy Pack - Jan 2019\FBX\` ·
`QM` = `quaternius\Modular SciFi MegaKit[Standard]\Modular SciFi MegaKit[Standard]\glTF\` ·
`QS` = `quaternius\Sci-Fi Essentials Kit[Standard]\glTF\` ·
`UPP` = `nuevos\Ultimate Platformer Pack by Quaternius\Ultimate Platformer Pack - Dec 2021\` ·
`SON` = `audio\Sonniss.com-GDC2026-GameAudioBundle\`

---

## 1. Top 12 locales VERIFIED SAFE (mejor impacto por esfuerzo)

| # | Asset | Ruta | Rol en el juego | Esfuerzo |
|---|---|---|---|---|
| 1 | Tiny Treats: `watering_can_B`, `shovel`, `pot_A_large`, `pots_stacked`, `saucer_A_large` | `TT\` (glTF + `Textures\`) | midground/set pieces de **jardín humano**; refuerzan escala | bajo (glTF + 1 textura) |
| 2 | Tiny Treats hojas sueltas: `monstera_leaf_large_A..D`, `sansevieria_leaf_large_A..C`, `yucca_branch_large_A..C` | `TT\` | **foreground gigante** (hojas que enmarcan) | bajo |
| 3 | KayKit Forest: `Bush_1..4`, `Grass_1/2`, `Rock_1/2/3_*`, `Tree_1..4` | `KF\` | sustituir follaje plano Kenney (que falla con el contorno) | bajo |
| 4 | Kenney food: `soda-can-crushed`, `candy-bar-wrapper`, `chocolate-wrapper`, `popsicle-stick`, `styrofoam`, `plate-broken`, `pizza-box`, `apple-half` | `KFD\` | basura/destructibles de escala | trivial (GLB) |
| 5 | Araña | `QE\Spider.fbx` | **hazard vertical colgante** (nueva función) | medio (comportamiento) |
| 6 | Rata | `QE\Rat.fbx` | cruce rápido por suelo que castiga la ruta baja | medio |
| 7 | Alien Scolitex / Oculichrysalis | `QM\Aliens\Alien_Scolitex.gltf`, `Alien_Oculichrysalis.gltf` (+ reubicar texturas) | **nido alien persistente** que genera popcorn | medio |
| 8 | QuadShell | `QS\Enemy_QuadShell.gltf` | heavy terrestre persistente (Level 02) | medio (recolor) |
| 9 | UPP `Hazard_Saw`, `SpikyBall` | `UPP\Level and Mechanics\glTF\` | hazards mecánicos alien | bajo |
| 10 | Kenney `lily_large`, `ground_river*`, `canoe` | `KN\` | reserva para nivel de lago | — (no ahora) |
| 11 | Kenney space `rock_crystalsLargeA`, `satelliteDish_large`, `machine_wireless` | `kenney\kenney_space-kit\Models\GLTF format\` | "contaminación alien" del jardín | trivial (recolor) |
| 12 | UPP `Heart`, `Star`, `Coin` | `UPP\Powerups and Pickups\glTF\` | pickups legibles (si se decide score) | trivial |

## 2. Top audio para integrar (escuchar antes de decidir)

| Prioridad | Uso | Archivo | Licencia |
|---|---|---|---|
| A | muerte de enemigo | `SON\Epic Stock Media - Anime Game\EXPLDsgn_Explosion Small Blast Enemy Death Crunchy Boom Cartoon Noisy Crash Impact Delay 03_ESM_AG.wav` (1,48 s) | Sonniss |
| A | entrada del OVNI | `SON\344 Audio - Air Designed\AEROJet_Unidentified Encounter_344 Audio_Air Designed.wav` (58 s, recortar) | Sonniss |
| A | rayo del boss | `audio\Sci-Fi Weapon SFX by Lentikula\Laser Beam 1.wav` (4,1 s) | CC0 |
| A | disparo enemigo | `audio\Sci-Fi Weapon SFX by Lentikula\Laser Pistol 1..5.wav` (recortar a ~0,4 s) | CC0 |
| A | aviso de embestida avispa | `SON\SoundBits - Vox Bestiae - Source Elements\CREAInsc_Insectoid Creature Tremble Attack Long 1_SNDBTS_VB-SE.wav` (2,5 s) | Sonniss |
| B | zumbido de avispas | `SON\344 Audio - Barbershop Vol. 2\OBJMisc_Wahl Sterling Trimmer, On, Idle, Off_344 Audio_Barbershop Vol 2.wav` (loop del idle) | Sonniss |
| B | pasos del humano | `SON\TheWorkRoom - Flip Flops\FFG002.wav` (ojotas; humor) | Sonniss |
| B | croar de la rana | `SON\Epic Stock Media - Synthesized Nature Loops and Sounds\ANMLAmph_Animal Frog Echo Short…_ESM_SNLS.wav` (2,3 s) | Sonniss |
| B | polen | `SON\CB_Sounddesign - Applicable Sounds - Organic UI and Building Games SFX\UIMisc_Kalimba 3 Up_CB Sounddesign_APPlicable Sounds.wav` (0,55 s) | Sonniss |
| B | muerte del boss | `SON\Federico Soler - Effective Trailer Booms Vol. 2\EffectiveTrailer_Booms_Vol2_011.wav` | Sonniss |
| C | disparo del jugador (variación) | `audio\(free)FX_Laser_Sound_Pack\(free)FX_Laser_Sound_Pack\Laser_Shot_01..04.wav` | comercial, no redistribuir |

---

## 3. Qué nos falta (objetivo 10)

### YA TENEMOS
- Core: abeja y avispa Style C, 7 familias enemigas, boss procedural, VFX procedurales, audio SFX real (Kenney + Sonniss).
- Fauna terrestre animada CC0: rana (importada), rata, araña, serpiente.
- Alien/sci-fi CC0 de sobra para Level 01–02: EyeDrone, Walker, Alien, QuadShell, Trilobite, 3 aliens orgánicos, 153 Kenney space.
- Props humanos CC0 de sobra: 200 de cocina/basura (Kenney) + 113 de jardín doméstico (Tiny Treats).
- Naturaleza CC0 de sobra: KayKit Forest, Quaternius Nature, Kenney nature, mini-forest.
- SFX: 214 min de Sonniss + Kenney + Lentikula: cubre jugador, enemigos, UFO, UI, mundo y lago.

### TENEMOS PERO REQUIERE ADAPTACIÓN
- Follaje Kenney de un plano y Quaternius con alfa: **no aguantan el contorno de Style C** → aplicar sin outline, o
  alpha-scissor/doble cara en `toon_body`.
- Modular SciFi aliens: texturas en otra carpeta; solo clip Idle (animar por código: pulso/escala).
- QuadShell/Trilobite: PBR oscuro → recolor a la paleta alien (gris + cian).
- Kenney space: blanco/amarillo de juguete → recolor.
- Búho Free Wild: único pájaro, sin clips (aleteo por huesos) y **licencia por verificar** (craftpix).
- Agua: piezas Kenney sí, superficie no → shader propio.
- Audio Sonniss: recortar y bajar a 44,1/48 kHz 16 bit mono.

### NO TENEMOS
- **Humano adulto estilizado suave** con piernas/calzado legibles (el problema visible real del Giant Human).
- **Aves** con licencia segura y animación de vuelo.
- Insectos pequeños: polilla, mariposa, escarabajo, libélula, mosca, mosquito (los actuales son procedurales).
- **Música** (cero pistas).
- **OVNI jefe** modelado con licencia segura (el boss es de primitivas: toro + esferas).
- Basura específica de jardín: botella PET, manguera, tapita, colilla, juguete de plástico.
- Peces / fauna acuática.
- Assets gráficos de UI (íconos, fuente con identidad).

### NO VALE LA PENA CONSEGUIR TODAVÍA
- Humanos completos para cinemáticas, más personajes humanos, NPCs.
- Kits de ciudad/atmósfera/espacio (Level 03+): el jardín todavía no está cerrado.
- Interiores de nave (ya hay 137 piezas Kenney sin uso).
- Packs de VFX/partículas: los VFX procedurales funcionan y combinan con Style C.
- Más mamíferos (oso, ciervo, lobo): no aportan a la escala insecto-jardín.
- Plugins (ver revisión de viabilidad).

---

## 4. Descargas externas — máximo 5 (NO descargado)

Solo carencias reales. Licencia requerida en todos los casos: **CC0 o royalty-free comercial con texto de licencia
descargable y archivable** (nada CC BY-NC, nada "free for personal use", nada sin página de licencia).

### #1 — Piernas + calzado del Giant Human (PRIORIDAD ALTA)
- **Tipo**: humano adulto estilizado *o* "lower body" (cadera → zapatillas) con rig humanoide estándar.
- **Estilo**: stylized low/mid poly **suave** (sombreado suave, sin facetas cúbicas), proporciones adultas (entrepierna
  ≥ 45 % de la altura), colores planos o textura-degradado; zapatilla deportiva con suela gruesa y cordones modelados
  (es lo que más se ve), jean o pantalón corto.
- **Poly**: 4–10 k tris el cuerpo completo; si es solo piernas, 2–5 k.
- **Animaciones**: `Walk` y `Run` en loop **in place** (indispensable), ideal `Stop`/`Look_Down`/`Stomp`. Compatible
  con retarget a esqueleto humanoide de Godot.
- **Formato**: GLB/glTF (preferido) o FBX con texturas embebidas.
- **Mecánica**: el cruce del humano (corredor entre piernas, pisotón). Es el objeto más grande que ve el jugador.
- **Nota**: alternativa interna sin descarga: modelar en Blender solo la zapatilla (low poly suave) y reemplazar
  `BootL/BootR` del Hipster, que es lo que la cámara E muestra. Más barato y mantiene rig/hitboxes.

### #2 — Ave de jardín animada (PRIORIDAD MEDIA)
- **Tipo**: gorrión, paloma o gaviota (una especie basta).
- **Estilo**: low poly estilizado, silueta legible **de perfil**, colores planos.
- **Poly**: 1,5–4 k tris.
- **Animaciones**: `Fly` (aleteo loop), `Glide`, `Dive`/`Swoop`, `Idle`(posado). Sin estos clips no sirve.
- **Formato**: GLB/glTF.
- **Mecánica**: **depredador controlado por implante** que cruza en picada (amenaza de escala de Level 02); también
  "liberable" como la libélula.

### #3 — Pack de insectos pequeños animados (PRIORIDAD MEDIA)
- **Tipo**: polilla o mariposa + escarabajo + mosca/mosquito (3–5 especies).
- **Estilo**: low poly colores planos, alas como mallas separadas (para material translúcido de Style C).
- **Poly**: 500–2.500 tris c/u.
- **Animaciones**: `Fly` loop (alas), `Death`; escarabajo `Walk`.
- **Formato**: GLB/glTF.
- **Mecánica**: **popcorn orgánico** controlado (enjambres) y fauna liberable; da variedad sin otro dron.

### #4 — OVNI jefe modelado (PRIORIDAD MEDIA-BAJA)
- **Tipo**: platillo clásico con cúpula, anillo y piezas separables (cañones/paneles como nodos independientes).
- **Estilo**: low poly arcade, metal gris + luces cian, silueta inconfundible de lejos.
- **Poly**: 3–8 k tris.
- **Animaciones**: no indispensables (se animan por código); ideal cañones/compuertas como nodos con pivote correcto.
- **Formato**: GLB.
- **Mecánica**: boss del Level 01 con partes destruibles (fases visibles). Alternativa: obtener la licencia del
  `UFO.blend` local (ya tiene 6 acciones de cañones) — si el usuario encuentra su URL/licencia, se ahorra la descarga.

### #5 — Música (PRIORIDAD ALTA para demo)
- **Tipo**: 2–3 pistas loopeables: jardín (calma con pulso), combate (energía arcade), boss (tensión sci-fi).
- **Estilo**: "naturaleza + tecnología": percusión orgánica/marimba + sintetizador; 110–140 BPM.
- **Duración**: 1:30–3:00 con loop limpio (o stems intro/loop).
- **Formato**: OGG o WAV 44,1 kHz.
- **Licencia**: CC0 o royalty-free comercial explícita para juegos (sin Content ID que reclame videos del juego).
- **Mecánica**: ritmo y sensación de arcade; sin música el juego se percibe prototipo en cualquier playtest/video.
