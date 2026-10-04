# BEE ALIEN — GARDEN IDENTITY, ASSET INTEGRATION & AUDIO PASS 04

Fecha: 2026-10-04 · Rama: `level01-garden-identity-04` (hija de `level01-threat-camera-boss-03` + el commit documental
`6d33908`). Sin merge, sin push. Base: `docs/BEE_ASSET_LIBRARY_DEEP_AUDIT_02.md`, `docs/BEE_ASSET_SHORTLIST_ACTIONABLE_01.md`,
`docs/BEE_PROJECT_VIABILITY_REVIEW_01.md`. Contexto del usuario: aprueba el Style C, la paleta y el color (sobre todo
después del checkpoint); pide un mundo más rico, un poco más de desafío y aprovechar los assets que ya existen.

## 0. Estado y seguridad
- Suite completa **antes** de tocar runtime: 37/38. El fallo (`validate_bee_weapons_powerups_v01`) era una expectativa
  vieja (4 pickups; hay 5 desde que el Rebuild 02 agregó `PrebossPower`) que el test escondía porque terminaba con
  `quit(0)` aunque fallara. Corregido en un commit de test aislado (`b2cdfa2`), sin tocar runtime. Baseline en verde.
- `addons/` y `demo/` (del usuario) intactos y sin trackear. Sin reset/clean/stash/rebase.

## 1. Fase A — Jardín doméstico gigante
Capa nueva `DomesticGarden01` (`scripts/levels/bee_level_01_domestic_garden.gd`), solo decoración: sin colisión, sin
nodos de gameplay. Datos por acto, no un volcado de assets: **9 composiciones**.

| Acto | Composición | Assets (todos CC0 con `License.txt` local) | Función |
|---|---|---|---|
| 1 jardín natural | arbustos, pasto y rocas KayKit (tinte apagado) | KayKit Forest `Bush_1/2/4`, `Grass_1/2`, `Rock_1/3` | midground/background, naturaleza |
| 1 | **A1 maceta volcada** con enredadera saliendo | Tiny Treats `pot_A_large`, `pothos_vine_large_A` | único objeto humano del acto; escala |
| 2 más rico | **A2 túnel de hojas de monstera** (4 hojas de 8–9 m arqueadas detrás del plano + 2 puntas en primer plano) | Tiny Treats `monstera_leaf_large_A–D` | traversal framing, foreground |
| 2 | **A2 regadera gigante vertiendo** (gotas animadas) | Tiny Treats `watering_can_B` | landmark + momento animado |
| 2 | yuca y sansevieria gigantes | Tiny Treats `yucca_plant_large`, `sansevieria_plant_large` | background |
| 3 territorio humano | **A3 pala clavada** junto a las pisadas del gigante | Tiny Treats `shovel` | scale reference |
| 3 | **A3 macetas apiladas + plato** | Tiny Treats `pots_stacked`, `saucer_A_large` | composition separator |
| 3 | **A3 picnic abandonado** | Kenney Food `apple-half`, `cup-coffee`, `candy-bar-wrapper`, `popsicle-stick` | scale reference |
| 4 color + alien | monstera en maceta gigante, suculentas, cactus | Tiny Treats `monstera_plant_large_potted`, `succulent_plant_pot_large`, `cacti_plant_pot_large` | color post-checkpoint |
| 4 | **A4 maceta invadida** (placas oscuras, nodos cian, mancha violeta) | Tiny Treats `pot_C_large` + `sansevieria` + paleta alien | contaminación |
| 4 | **A4 regadera volcada** | Tiny Treats `watering_can_A` | set piece |
| 5 OVNI | **A5 macetas volcadas**, a la izquierda del encuadre | Tiny Treats `pots_stacked`, `saucer_A_large` | arena limpia para el jefe |

- **Progresión** natural → doméstico → humano → alien: objetos humanos por acto 1 / 1 / 7 / 2 / 2; tinte por acto
  (acto 1 más apagado; el salto de color después del checkpoint sigue siendo el momento más fuerte). Los verdes lima de
  KayKit se tiran hacia el oliva del pasto procedural.
- **Legibilidad** (testeada): toda malla detrás de z = −3 (no solo el pivote); nada más alto de 0,35 m en |z| < 2,5;
  los 5 acentos de primer plano se proyectan por debajo del área de juego. No tapan a Bee, balas ni telegraphs.
- **Style C sin aplicarlo a ciegas** (`BeeToonStyle.apply_profile`): `prop` = toon + contorno fino de prop;
  `foliage` = toon doble cara **sin contorno** (el inverted hull pintaba de negro el dorso); `cutout` = toon doble cara
  con alpha scissor (nuevo `toon_body_cutout.gdshader`, variante de compilación del include común; probado sobre el
  helecho Quaternius con alfa). Los shaders existentes no cambian de comportamiento.
- Capturas BEFORE/AFTER: `dev/garden_identity_04_review/before_*.png` y `after_*.png` (jardín temprano, humano,
  post-checkpoint y 12 más).

## 2. Fase B — Giant Human: pulido, no reemplazo
`scripts/levels/giant_human_close_up.gd`, aplicado al final de `_ready` del humano del nivel, **después** de que los
hulls de daño muestrearon el cuerpo.
- **Jean**: normales suaves en los laterales (tapas duras) → pierna redonda con bandas toon suaves en vez de rayas
  hexagonales; denim azul que sobrevive al sol cálido (antes se leía gris verdoso) con un degradé sutil (más oscuro en el
  ruedo). Shader `toon_fabric.gdshader` (variante del include común).
- **Bota → zapatilla de lona**: capellada rojo ladrillo, suela de goma crema y puntera. La bota es un elipsoide: la suela
  son sus propios anillos inferiores y la puntera sus anillos delanteros, copiados como mallas con el **mismo skin y pesos**
  (siguen al pie) y apenas inflados (2 %). Nada se aplana, así que no aparece el "plato" que criticó el playtest 02.
- **Sin cambios** en daño (20), timing, corredor seguro (2,4 m), arquitectura de colisión, esqueleto, clip `Run` ni GLB.
  La bota conserva exactamente sus posiciones de vértice (testeado contra el GLB original). `validate_bee_giant_human_corridor_v01`
  sigue verde.

## 3. Fase C — Araña: amenaza de carril vertical
`scripts/levels/controlled_spider.gd` + `scenes/levels/controlled_spider.tscn`. Modelo: Quaternius `Spider.fbx` (CC0),
colgando cabeza abajo de su hilo, con el implante alien de las avispas (`WaspImplant`) en el lomo.
- Ciclo: ENTRA desde arriba (dentro de la pantalla) → CUELGA → TELEGRAPH (implante cian + columna y anillo que siguen la
  altura de Bee y se **bloquean** 0,3 s antes) → CAE a esa altura → SOSTIENE (barrera) → RETRAE → SE REPOSICIONA por
  su línea de tela hacia Bee → segundo ataque → SALE por arriba. Clips: `Idle`, `Walk` (reposición/huida), `Attack`.
- Qué exige: leer la columna y el anillo y **cambiar de altura** (o deslizarse de lado) antes del bloqueo.
- Fairness: telegraph solo dentro de la pantalla; el cuerpo nunca baja de 2,0 m (carril bajo siempre libre) y el hilo
  no daña (la columna por encima del cuerpo caído es un carril libre); un solo patrón pesado a la vez (`BeeAttackTokens`);
  8 de daño por contacto, 14 en el golpe, una vez por fase.
- Implante destruido = araña liberada: huye trepando (sin gore). Liberación completa estilo libélula: pendiente.
- Rol MEDIUM, **90 HP**. Apariciones: X=91 (acto 2, sola), X=166 (acto 3, con avispa), X=315 (acto 4, con EyeDrone, en el hueco más largo del acto).
  Nunca en hard gates, siempre bajo el tope de amenazas.
- Test: `tests/levels/validate_bee_controlled_spider_v01.gd`.

## 4. Fase D — Identidad de audio
**Límite honesto: no puedo escuchar audio.** "Audicionar" en este pase = análisis de señal (nivel, envolvente, ataque,
duración útil, centroide, bandas, planitud espectral) + inspección visual de espectrogramas de **60 candidatos en 14
categorías** y de los 11 resultados (`dev/audio_audition/analyze_candidates.gd`, hojas en `dev/audio_audition/analysis/`).
Nada se eligió solo por el nombre, pero la **escucha humana queda pendiente**: escena `dev/audio_audition/audio_audition.tscn`
(F6; ↑↓ fila, ←→ categoría, Espacio reproducir, **A = lo que sonaba antes** para A/B).

| # | Cambio | Fuente | Por qué (señal) |
|---|---|---|---|
| 1 | muerte de enemigo tech | Epic Stock Media "Explosion Small Blast Enemy Death…" (Sonniss) | más brillo (centroide 770 Hz vs 273) y cuerpo: se recorta sobre los graves de la mezcla; 0,60 s |
| 2 | muerte orgánica (era placeholder procedural) | splat "Hit Blood Spill Splat…" + "Cartoon Bubbles Short" | identidad húmeda + burbujas, sin gore; 0,60 s |
| 3 | aviso de overload de la avispa | SoundBits "Insectoid Creature Tremble Attack" | temblor insectoide (antes: carga genérica del OVNI a pitch 1,7) |
| 4 | identidad del Organic (carga de bio-orbes) | "Monster Tentacle Modulated… Wobble" | ondulación grave modulada, distinta de todo lo tech |
| 5 | identidad del Walker (carga del barrido violeta) | "Tower Deploy Hitech Robot Motor… Servo Whine" | golpe + servo |
| 6 | pisadas del humano gigante | Kenney pasto (igual que antes) + "Colossal Impacts – Impact Cut Sweep" | el crujido conserva su pico; se suma peso grave 30 ms después |
| 7 | anticipación del OVNI ("último silencio") | 344 Audio "AEROJet Unidentified Encounter" | oleada de 5 s bajo el zumbido existente |
| 8 | ambiente de atardecer | 344 Audio "Forest Crickets, Birds, Connecticut" | grillos que entran con el ocaso (X 210→290) bajo el prado |
| + | araña (familia nueva) | InMotion "Arc" (telegraph), "Woosh Sweep Slide" (caída), cinta métrica retráctil (hilo) | — |

Rechazados tras el análisis (y por qué): Kenney `explosionCrunch_*` (misma familia que lo actual); `slime_000`
(pops sueltos, demasiado finos para una muerte); "Ethereal Entity Grim Pain" (gemido de 1,7 s, tono de terror);
"Interface Sci-Fi Ping Down" (ping de UI); zumbidos "Wahl trimmer"/"Hair dryer"/"Arc Buzz 27" (el aleteo actual funciona;
el Arc Buzz es ruido >4 kHz); "Moaning Metal" (casi todo bajo 60 Hz: inaudible en laptops); Lentikula Laser Rifle y
"Electric tonal impact" (largos, compiten con los disparos del Walker); disparos enemigos Lentikula/Kenney (los disparos
hostiles son silenciosos por diseño: hasta 14 en pantalla saturarían la mezcla); FX Laser y `laserRetro` para Bee (el
disparo actual funciona; FX Laser además restringe redistribución); "Horn Braam" (demasiado tráiler) y "Ship reactor"
(redundante con el hover); Lentikula Laser Beam (el jefe no tiene un ataque de rayo al que atarlo); ojotas FFG002/FFW003
(el gigante ahora usa zapatillas); "Jungle Night" (pájaros tropicales, fuera de tono); viento "Whipping Loop" (silbido
tonal), "Wind Rush" y parque de Berlín (tráfico): no se agregó capa de viento (el ambiente actual ya trae viento);
"Whip snap crack" para la araña (se lee como arma).
- **Mezcla**: peligro del jugador (`bee_damage` −11, `bomb` −8) > telegraphs hostiles (−15/−16, prioridad 4) > muertes
  (−17, antes −15/−16) > golpes (−20/−21) > ambiente (−24; atardecer −27). Testeado.
- **Variación**: muertes, golpes, cajas y araña con pitch ±3–6 % y volumen ±0,5–1,5 dB por reproducción.
- Duraciones: las muertes quedaron en 0,60 s para que toda voz temporal termine en 1 s (contrato de
  `validate_bee_audio_basic_v01`, que con 0,72 s fallaba de forma intermitente según el pitch aleatorio).
- Herramienta: `tools/integrate_audio_garden04.gd` (idempotente). Procedencia y hashes: `audio/sfx/PROVENANCE.md`.

## 5. Música
`docs/BEE_LEVEL01_MUSIC_BRIEF_01.md`: BPM 118–126 (jefe 132–140), mood arcade de fines de los 90 con humor, capas
naturaleza/arcade/alien en stems, transición al jefe, requisitos de loop y licencia. No se fabricó ni descargó música.

## 6. Fase E — Micro-pase de dificultad
Medido con `dev/garden_identity_04_review/threat_analysis_04.gd` (bot que mantiene el disparo y sigue la altura de la
amenaza más cercana, puntería perfecta, `ghost=1`). La base se midió sobre el commit previo (`6d33908`) en un worktree
temporal, no con números de documentos viejos. Bots a 0,30 / 0,40 / 0,50 s entre disparos:

| Métrica (solo combate) | Base `6d33908` | Final |
|---|---|---|
| balas hostiles visibles (promedio) | 2,48 / 3,09 / 3,11 | 2,44 / 2,91 / 3,30 |
| ocupación de ataque (telegraph incluido) | 60 / 63 / 64 % | 61 / 63 / 66 % |
| amenazas simultáneas (promedio) | 1,91 / 2,10 / 2,18 | 1,87 / 2,11 / 2,27 |
| segundos de combate | 157 / 185 / 201 | 169 / 195 / 207 |
| EyeDrone: ataques por unidad | 1,1 / 1,3 / 1,4 | 1,1 / 1,1 / 1,7 |
| Araña (nueva): ataques por unidad | — | 1,0 / 1,7 / 1,7 (a 70 HP sin compresión: 1,0 / 1,0 / 1,3) |

Lectura honesta: el aumento es pequeño y desigual. Hay más combate (+6 a +12 s) y, para jugadores más lentos, más
presión (3,11 → 3,30 balas; 64 → 66 %); para bots muy eficientes el promedio de balas incluso baja un poco, porque la
araña suma tiempo de amenaza **sin** proyectiles. El desafío nuevo es sobre todo cualitativo: la columna de la araña
obliga a cambiar de altura, algo que ningún enemigo pedía así. Ningún número mide diversión: decide el playtest.
Cambios, todos locales:
1. Araña (familia nueva): 90 HP y ciclo comprimido para que el segundo ataque exista frente a un jugador medio.
2. Avispa: reposo entre pasadas 1,0 → 0,85 s.
3. EyeDrone: cooldown 1,2 → 1,1 s.
4. Popcorn del acto 4 (X=222 y 245): 3 tiradores por fila en vez de 2.
Sin multiplicador global de vida ni de daño; telegraphs, daño y velocidad de balas sin cambios. Jefe: no se tocó;
`validate_bee_threat_camera_boss_v03` y `validate_bee_ufo_boss_01` verifican movimiento, secuaces, S+ y cámara E juntos.

## 7. Fase F — Futuro nivel de lago
`docs/BEE_FUTURE_LAKE_LEVEL_CONCEPT_01.md` (solo documentación): rana controlada como jefe (destruir el dispositivo,
no matar a la rana), patrones posibles, fauna sin inflar, assets locales reutilizables y carencias (shader de agua).

## 8. Rendimiento (1152×648, Intel Arc B580, GL Compatibility; `dev/garden_identity_04_review/bench_garden04.gd`)
| Escenario | Antes: media / CPU render / draws | Después: media / CPU render / draws |
|---|---|---|
| apertura | 10,00 ms / 1,03 / 242 | 10,00 ms / 1,50 / 253 |
| jardín denso (túnel de hojas) | 10,00 / 1,06 / 214 | 10,00 / 1,08 / 233 |
| regadera | 10,00 / 1,03 / 248 | 10,00 / 1,09 / 270 |
| humano | 10,03 / 1,44 / 303 | 10,08 / 1,63 / 329 |
| araña + EyeDrone | — | 10,06 / 1,28 / 257 |
| post-checkpoint | 10,00 / 1,36 / 235 | 10,00 / 1,62 / 245 |
| jefe fase 2 | 10,05 / 1,38 / 380 | 10,00 / 1,42 / 398 |
~100 FPS sostenido (vsync) en todos. Nodos +103. Picos aislados la primera vez que aparece cada material nuevo (humano
48,8 ms, araña 32 ms): compilación de shaders, el mismo fenómeno ya documentado en el Rebuild 03 (precalentar shaders al
cargar sigue pendiente).

## 9. Tests
Nuevos: `validate_bee_garden_identity_v04` y `validate_bee_controlled_spider_v01` (suite: 40). Actualizados de forma
deliberada (con comentario en cada línea): cantidad de eventos 44 → 47 y tabla de vida con `Spider: 90` (combat patterns,
pressure world interaction, challenge balance); unidades 92 → 97 (vertical slice); presupuesto de unidades 82–92 → 82–97
(5 suites: 3 arañas + 2 escoltas); la araña excluida del chequeo de "altura de formación" como Turret y Walker
(transformation: entra desde arriba a propósito); y el arreglo del test de armas (§0). La primera corrida completa con la
araña detectó además que la araña tardía (X=281) quedaba a 3 m de sus vecinos (regla del director: 4–16 m): se movió a
X=315, el hueco más largo del acto 4. Resultado de la suite completa: ver el reporte final de la sesión.
