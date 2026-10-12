# Checklist de assets por nivel

Estados según el disco al 2026-10-12, tras la mudanza del Lote 12 (ver `AUDITORIA_ASSETS.md` y `ASSET_MANIFEST.md`): ✅ en juego · ⚠️ listo (fuente, GLB y laboratorio) pero sin integrar · ❌ no existe · ❓ no verificable por archivos. El elenco del Nivel 1 lo fija `LEVEL_01_ROSTER.md`.

## Nivel 1 — Jardín de una casa (`level_01_garden`)

### Elenco

| Unidad | Estado | Archivo / código | Nota |
|---|---|---|---|
| Mariquita | ✅ | `enemies/controlled_flying_ladybird` (+ `_lite`) | el juego usa la versión completa (9.384 tris) |
| Mosca común | ⚠️ | `enemies/lvl01_enemy_fly_common_v01` (+ liberada) | falta escena jugable, IA, HP |
| Mosca verde | ⚠️ | `enemies/lvl01_enemy_fly_green_v01` (+ liberada) | falta escena jugable, IA, gota apuntada |
| Nube de moscas | ⚠️ | `enemies/lvl01_enemy_fly_swarm_v01` (+ liberada) | falta unidad de grupo jugable |
| Avispa | ✅ | `enemies/wasp_mid_poly`, `wasp_enemy.tscn` | |
| Hormiga | ✅ | `enemies/controlled_ant` (+ `_lite`) | |
| Caracol | ✅ | `enemies/controlled_woodland_snail` | 7.748 tris, sin `_lite` |
| Gusano A (rosado) | ⚠️ | `enemies/lvl01_enemy_worm_rose_v01` (+ liberado) | falta emerger con marca, escena, IA |
| Gusano B (compost) | ⚠️ | `enemies/lvl01_enemy_worm_compost_v01` (+ liberado) | falta patrón propio, escena, IA |
| Escarabajo ciervo | ✅ | `enemies/controlled_stag_beetle` | 9.952 tris, sin `_lite` |
| Hongos de jardín | ⚠️ | `environment/lvl01_environment_mushroom_{button,spotted,umbrella}_v01` | falta destructible que suelta polen |
| Hongo cañón | ✅ | `enemies/controlled_mushroom_cannon` | 11.822 tris, sin `_lite` |
| Araña colgante | ✅ / ⚠️ | nodo `controlled_spider.tscn`; GLB `enemies/controlled_hanging_spider` sin conectar | |
| Tortuga de jardín | ⚠️ | solo código (`bee_aftermath_turtle.gd`) | falta modelo/escena de tanque |
| Robot caminante | ✅ | `ground_walker_enemy.tscn` (procedural) | falta mini-jefe con escoltas |
| Tarántula (jefe) | ⚠️ | `bosses/lvl01_boss_giant_spider_v01` (+ liberada) | modelo con exoesqueleto alien; el contrato pide solo implante; sin combate |

### Decorado de jardín

| Asset | Estado | Carpeta |
|---|---|---|
| Valla, casa lejana | ✅ | `environment/garden_fence_module`, `garden_distant_house` |
| Manguera | ✅ | `props/garden_hose` |
| Regadera gigante | ⚠️ | `props/garden_watering_can` (el evento de Lote 11 la usa como escena procedural) |
| Botella, lata de atún, cáscara de banana, lata de gaseosa, caramelo, tapa gigante | ✅ | `props/` |
| Caja de cerillos, envoltorio abierto | ⚠️ | `props/` (reserva) |
| Tronco hueco, campanilla, helecho | ✅ | `environment/` |
| Arbusto florido, brote | ✅ | `environment/` |
| Sol, luna, estrellas | ✅ | `environment/` |
| Props domésticos externos (macetas, regaderas, vegetación) | ✅ | `assets/external/approved/` (Tiny Treats, KayKit) |

Ítems, proyectiles, FX y UI: ver `shared/` y el manifiesto.

## Nivel 2 — Laguna (`level_02_lake`)

✅ perca, ninfa de libélula, zancudo, mosquito, libélula controlada, nenúfar, juncos, raíz sumergida, sapo (modelo `amphibian_mount_study`, escena `scenes/levels/level_02_lake/lake_toad_miniboss_visual.tscn`, código `scripts/levels/level_02_lake/`). ⚠️ listos sin integrar: garza gigante, nube de mosquitos, tortuga, salamandra, sapo Rococó (jefe), tres variantes ligeras de botánica, barca, boya, roca de orilla, módulo de ola, mosquito `_lite`.

## Nivel 3 — Bosque (`level_03_forest`)

✅ polilla bomba, polilla estacionaria, luciérnaga (en el Nivel 1 hasta la etapa 2), pinos, piña. ⚠️ búho, ratón, insecto palo, oruga (+ `_lite`).

## Nivel 4 — Cielo (`level_04_sky`)

⚠️ águila (dos modelos), paloma, nube, casas residenciales, farol, estrellas cálidas.

## Niveles 5 y 6

❌ sin contenido. La tecnología alien reutilizable está en `shared/alien_tech`.

## Nivel 7 — Espacio (`level_07_space`)

⚠️ nave nodriza, patinador orbital, asteroide. El UFO (código y escena) se conserva para este nivel.

## shared

✅ `bee/` (Bee y avispa mid poly), `pickups/` (polen, Spread, bomba, miel), `projectiles/` (disparo de Bee, orbe alien). `alien_tech/`: ✅ caza interceptor, semillero (en juego hoy), sonda; ⚠️ bombardero blindado, relé de señal, kit de implantes (referencia).

## `_unassigned`

`coastal/` (gaviota, pulpo, mantarraya: sin nivel marino en el plan) y `human/` (humano gigante, hoy apagado).

## Discrepancias

1. El checklist del Lote 11 ponía en el Nivel 1 la rana, el UFO, el mosquito, la libélula, la polilla, la sonda, el caza y el semillero: el contrato los saca (rana → N2, UFO → N7, mosquito/libélula → N2, polilla/luciérnaga → N3, resto → `shared/alien_tech`).
2. El contrato pide la carpeta `level_02_lagoon`; se conserva `level_02_lake` porque Codex ya entregó assets ahí y los manifiestos/documentos la citan. Si se prefiere el otro nombre es un renombre de carpeta.
3. El contrato dice que la tortuga de jardín «ya existe»: solo existe como pieza procedural de una escena de secuela, no como tanque jugable.
4. La tarántula entregada lleva exoesqueleto alien (placas, núcleo cian, nodos); el contrato dice «con implante, sin exoesqueleto alien».
5. El contrato propone gusanos que «emergen con marca» y escupen/embisten, pero los modelos son solo arte (3 clips, sin escena ni IA).
6. El Nivel 1 todavía instancia pinos (N3), luciérnaga (N3) y la fauna de N2/N3 desde `asset_fauna.gd`: se apaga en la etapa 2.
7. Helecho, campanilla y tronco (decorado de jardín) también los usa la laguna.
8. `CLAUDE.md` habla de 52 validaciones; hay 91 scripts `validate_*.gd`.
9. Hongos: los tres hongos de jardín de Codex son naturales (sin alien); el «hongo de color» del contrato (Nivel 3) no existe como modelo todavía.
