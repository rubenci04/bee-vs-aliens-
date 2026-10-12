# Informe Lote 12

## Etapa 1 — Auditoría y mudanza por nivel

- **Auditoría:** `docs/art/AUDITORIA_ASSETS.md` (112 GLB medidos: triángulos, implante, material blanco, uso, `_lite`, presupuesto, nivel). Hallazgos: 1 pieza blanca (`hipster_poc`, humano gigante apagado), 0 materiales rotos, 26 GLB sobre presupuesto (4 tienen `_lite`: hormiga, mariquita, mosquito, oruga), 0 modelos sin implante separado.
- **Mudanza** (8 lotes: N1, N2, N3, N4, N7, shared, `_unassigned`, estilo; tras cada uno reimportación y 35 tests dirigidos — todos `tests/art/` más los del nivel, del imán de fauna y los de ítems/proyectiles — en verde, ningún lote revertido): 82 GLB heredados + `bee_mid_poly`/`wasp_mid_poly` (de `assets/style/models/`), con sus `.import` y `.blend`; 60 con `git mv` (historial conservado) y 27 con `mv` porque nunca se habían commiteado. Se reescribieron las rutas en 150+ archivos (escenas, `.tres`, scripts, tests, tools, manifiestos, docs de arte). Resultado: Nivel 1 = 45 GLB (29 del elenco/decorado heredados y los nuevos de Codex), Nivel 2 = 27, Nivel 3 = 11, Nivel 4 = 8, Nivel 7 = 3, shared = 14, `_unassigned` = 4 (gaviota, pulpo y mantarraya en `coastal/`; humano gigante en `human/`).
- **Rana:** código (`garden_toad_encounter.gd`, `lake_toad_boss.gd`) a `scripts/levels/level_02_lake/` (con sus `.uid`), escena a `scenes/levels/level_02_lake/lake_toad_miniboss_visual.tscn`, modelo `amphibian_mount_study` a `level_02_lake/bosses`. Se mantuvo el nombre de carpeta `level_02_lake` (el pedido dice `level_02_lagoon`; Codex ya entregó ahí, ver Discrepancias del checklist).
- **Duplicados:** `swarm_lite_v01/*` pasaron a `*_lite` (hormiga, mariquita, mosquito, oruga) para convivir con las versiones completas.
- **Documentos:** `ASSET_MANIFEST.md` regenerado (112 filas, 50 en uso), `ASSET_CHECKLIST_BY_LEVEL.md` con estados reales y 9 discrepancias, README con inventario en cada carpeta de nivel, `shared/` y `_unassigned/` (en `assets/models/` y `art_source/blender/`), `ASSET_MOVE_PLAN.md` marcado como ejecutado.
- **Commit:** incluye el arte de Codex que estaba sin versionar (GLB, `.blend`, laboratorios, scripts/tests/tools de arte, `concept_art`) porque las rutas movidas lo referencian. Quedan fuera `addons/` y `demo/` (terceros, sin tocar).
- `.git/index.lock` huérfano (0 bytes, sin proceso git): lo borré al aparecer; la primera pasada de `git mv` falló por eso y se repitió completa.

### Pendientes de mover

| Qué | Motivo |
|---|---|
| `assets/models/<tanda>/manifest.json` (24) | Los leen `tests/art/*.gd` y `tools/art/capture_requested_props_details.gd` por la ruta de la tanda (incluso construida con `"res://assets/models/"+batch+...`). Sus campos `source`/`glb` ya apuntan a las rutas nuevas. |
| `tools/art/create_*.py` (generadores de Blender) | Sus constantes `OUT`/`SRC` apuntan a la carpeta de la tanda vieja; reubicar requiere una tabla por tanda (varias tandas se repartieron entre niveles). Solo importa si se vuelven a ejecutar. |
| `scenes/art_labs/**`, `scripts/art/**`, `tests/art/**` | Laboratorios y validaciones: referencian por ruta y ya están actualizados; no son arte de nivel. |
| `bee_aftermath_turtle.gd`, `bee_level_01_scale_event.gd` (invoca la rana) | Código del Nivel 1; se apaga en la etapa 2 con la constante. |
| Carpetas vacías `assets/models/<tanda>/` y `art_source/blender/<tanda>/` | Contienen solo el `manifest.json` o un `.gdignore`; no se borran. |

### Qué falta (Nivel 1)

- Moscas común/verde/nube, gusanos A/B, hongos de jardín y tarántula: solo arte; faltan escena jugable, IA/HP/hitbox y, en la tarántula, hitbox del implante y liberación.
- Tarántula: el modelo lleva exoesqueleto alien (placas, núcleo cian, nodos); el contrato pide solo implante.
- Sin `_lite` y sobre presupuesto: escarabajo ciervo (9.952), caracol (7.748), hongo cañón (11.822). Hormiga y mariquita tienen `_lite` pero el juego sigue cargando la completa.
- Araña colgante: el GLB (`controlled_hanging_spider`) no está conectado al nodo procedural.
- Tortuga de jardín: solo pieza procedural de la secuela; falta modelo/escena de tanque.
- Robot caminante: falta modo mini-jefe con escoltas.
- Hongos destructibles que sueltan polen: no existe la lógica.

Verificación: reimportación (0 errores) y suite completa **91/91 PASS** (la primera pasada dio 48/91: la caché de clases no conocía los scripts movidos de la rana; tras reimportar quedó todo en verde). Logs `dev/lote12_1b_*`.
