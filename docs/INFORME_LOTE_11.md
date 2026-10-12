# Informe Lote 11

## A. Orden del arte (no destructiva) + piezas blancas

- Inventario real en `docs/art/ASSET_MANIFEST.md`: 82 GLB propios (81 `.blend`), 48 referenciados por el juego, 34 solo en laboratorio. Triángulos tomados de los `manifest.json` de cada tanda.
- `ASSET_CHECKLIST_BY_LEVEL.md` y `ASSET_REQUEST_TEMPLATE.md` **no existían**: se crearon (el primero con estados según disco y una sección «Discrepancias», 7 puntos; la plantilla de pedido para A4).
- Estructura nueva (89 carpetas, cada una con `README.md` de 3 líneas y `.gitkeep`): `levels/level_01_garden … level_07_space/{enemies,props,environment,bosses,fx}`, `shared/{bee,alien_tech,pickups,projectiles,ui}`, `rail_mode/` bajo `art_source/blender/` y `assets/models/`, y `concept_art/levels/level_01 … 07`. Nombres de L02–L07 propuestos (lake, forest, sky, invasion, atmosphere, space).
- `docs/art/ASSET_MOVE_PLAN.md`: destino por tanda y referencias `res://` afectadas. No se movió nada.
- Línea de pedido de assets agregada a `CLAUDE.md` y `AGENTS.md`.
- **Piezas blancas — causa común:** los tres objetos eran el vaso de café del Kenney Food Kit (el «hexágono» junto a la manzana, acostado, y el «bloque» junto a la botella) y la piedra pálida. `BeeToonStyle.BRIGHT_ALBEDO_CAP` (0,8) solo limitaba el color del material, no la textura: los texels casi blancos pasaban sin límite y el sol los quemaba. El Lote 10 había tratado solo las rocas procedurales. Corrección de raíz: `toon_common.gdshaderinc` suma `albedo_cap` (desactivado por defecto, 10,0) y `pale_tint`; los materiales con textura o color de vértice creados por `apply_profile` (props de jardín) usan `PROP_TEXTURE_CAP = 0.5` (luminancia lineal) y `PALE_TINT` cálido. Actores, Bee y humano no cambian. Comprobado con capturas Compatibility en X=172/186/207 (`dev/lote11_review/`, ignoradas por git): el vaso queda beige cálido; la roca estructural en X=205 sigue verde oliva.

Pruebas dirigidas: `validate_bee_garden_identity_v04`, `validate_bee_visual_target_01`, `validate_bee_visual_polish_v02`. Suite completa: **82/82 PASS** (`dev/run_suite.sh`; cuenta como fallo un `SCRIPT ERROR`).
