# Checklist de assets por nivel

Estados según el disco al 2026-10-12 (ver `ASSET_MANIFEST.md`): ✅ en juego · ⚠️ listo (fuente, GLB y laboratorio) pero sin integrar · ❌ no existe · ❓ no verificable por archivos (depende de revisión visual/playtest).

Este archivo no existía al empezar el Lote 11; se creó desde `LEVEL01_ART_PRIORITIES.md`, los roadmaps y el contenido real de `assets/models/`.

## Nivel 01 — Jardín

| Categoría | Asset | Estado | Nota |
|---|---|---|---|
| enemigo | Mosquito, mariquita voladora, hormiga, escarabajo ciervo, caracol, libélula, polilla bomba, hongo cañón | ✅ | `asset_fauna.gd` |
| enemigo | Araña colgante (carril vertical) | ✅ | nodo propio `controlled_spider.tscn`; GLB `controlled_hanging_spider` (V11) ⚠️ sin conectar |
| enemigo | Avispa, sonda alien, caza interceptor, ojo, walker, torreta, speeder | ✅ | |
| enemigo | Rana de jardín (encuentro) | ✅ | `garden_toad_encounter.gd` |
| enemigo | Oruga blindada | ⚠️ | V09 / swarm_lite |
| enemigo | Bombardero blindado alien | ⚠️ | `alien_ships_v02` |
| jefe | UFO / NODO ALIEN | ✅ | `ufo_boss_01` |
| jefe | Nave nodriza | ⚠️ | `mothership_v01` |
| jefe | Águila (mini-jefe del cielo) | ⚠️ | `eagle_sky_v01`, `future_biomes_v11/controlled_eagle` |
| entorno | Manguera, valla, casa lejana | ✅ | `garden_backdrop_v01` |
| entorno | Regadera | ⚠️ | GLB listo; el evento de la regadera (Lote 11 C5) la usa |
| entorno | Botella, lata de atún, cáscara de banana, lata de gaseosa, caramelo, tapa gigante | ✅ | |
| entorno | Caja de cerillos, envoltorio abierto | ⚠️ | reemplazados en el nivel por atún y banana |
| entorno | Tronco hueco, campanilla, pino, arbusto, brote | ✅ | |
| entorno | Helecho | ⚠️ | solo en Nivel 02 |
| entorno | Sol, luna, estrellas | ✅ | |
| entorno | Nube | ⚠️ | |
| entorno | Casas residenciales y farol | ⚠️ | `residential_sky_v01` |
| entorno | Humano gigante | ✅ | `hipster_poc` (sin `.blend`) |
| ítem | Polen, Spread, bomba, curación | ✅ | `pickups_toon_v01` |
| fx | Proyectiles toon de Bee y alien | ✅ | `projectiles_toon_v01` |
| fx | Impactos y explosiones toon | ✅ | `scenes/vfx/toon/` |
| ui | Barra de vida POC | ⚠️ | `future_health_bar.tscn` |
| ui | Logo, iconos de armas, marcos de vida | ❌ | |
| ui | Pantalla de título y HUD de armas | ✅ | construidos por script/escena |

## Nivel 02 — Lago

✅ lago, nenúfar, juncos, raíz sumergida, perca, ninfa de libélula, zancudo; ⚠️ barca, roca de orilla, módulo de ola, boya (V05/V08), pulpo, manta; ✅ rana (sapo del lago).

## Niveles 03–07

Sin contenido jugable. En disco, reserva ⚠️ por tema: L03 bosque (pinos, búho, ratón, insecto palo, escarabajo), L04 cielo/barrio (águila, paloma, gaviota, casas, farol), L05 invasión (nodriza, bombardero, portador de semillas, relé), L06 atmósfera (manta, pulpo — sin asignación clara), L07 espacio (asteroide, patinador orbital). ❌ para todo lo demás (escenarios, jefes propios de cada nivel).

## Discrepancias

Entre los documentos de arte y el disco:

1. `LEVEL01_ART_PRIORITIES.md` lista como pendientes manguera, regadera, valla y casa: los cuatro existen en `garden_backdrop_v01` (manguera, valla y casa ya en juego).
2. Lo mismo para el águila (existe en V11 y `eagle_sky_v01`), la araña colgante (V11 y nodo propio en juego) y la nave nodriza (`mothership_v01`).
3. `ENVIRONMENT_ROADMAP.md` propone «manguera + regadera + módulo de valla» como siguiente tanda y pino/campanilla/residuos como pendientes: hechos en `garden_backdrop_v01`, `pine_woods_v01`, `forest_floor_v01`, `ground_litter_v01/v02`.
4. `LEVEL01_ART_PRIORITIES.md` marca pendiente el sapo gigante; el encuentro de la rana está integrado (Lote 10 C).
5. Logo, iconos de arma y marcos de vida siguen pendientes (coincide con el disco).
6. `CLAUDE.md` habla de «52 validaciones»; hay 82 suites `validate_*.gd`.
7. `docs/art/` tiene PNG de revisión para tandas sin manifest propio en `assets/models/` (`future_biomes_v01`–`v03` anteriores al flujo de manifests por tanda); sus triángulos figuran como `—` en el manifiesto cuando falta el dato.
