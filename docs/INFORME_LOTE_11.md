# Informe Lote 11

## A. Orden del arte (no destructiva) + piezas blancas

- Inventario real en `docs/art/ASSET_MANIFEST.md`: 82 GLB propios (81 `.blend`), 48 referenciados por el juego, 34 solo en laboratorio. Triángulos tomados de los `manifest.json` de cada tanda.
- `ASSET_CHECKLIST_BY_LEVEL.md` y `ASSET_REQUEST_TEMPLATE.md` **no existían**: se crearon (el primero con estados según disco y una sección «Discrepancias», 7 puntos; la plantilla de pedido para A4).
- Estructura nueva (89 carpetas, cada una con `README.md` de 3 líneas y `.gitkeep`): `levels/level_01_garden … level_07_space/{enemies,props,environment,bosses,fx}`, `shared/{bee,alien_tech,pickups,projectiles,ui}`, `rail_mode/` bajo `art_source/blender/` y `assets/models/`, y `concept_art/levels/level_01 … 07`. Nombres de L02–L07 propuestos (lake, forest, sky, invasion, atmosphere, space).
- `docs/art/ASSET_MOVE_PLAN.md`: destino por tanda y referencias `res://` afectadas. No se movió nada.
- Línea de pedido de assets agregada a `CLAUDE.md` y `AGENTS.md`.
- **Piezas blancas — causa común:** los tres objetos eran el vaso de café del Kenney Food Kit (el «hexágono» junto a la manzana, acostado, y el «bloque» junto a la botella) y la piedra pálida. `BeeToonStyle.BRIGHT_ALBEDO_CAP` (0,8) solo limitaba el color del material, no la textura: los texels casi blancos pasaban sin límite y el sol los quemaba. El Lote 10 había tratado solo las rocas procedurales. Corrección de raíz: `toon_common.gdshaderinc` suma `albedo_cap` (desactivado por defecto, 10,0) y `pale_tint`; los materiales con textura o color de vértice creados por `apply_profile` (props de jardín) usan `PROP_TEXTURE_CAP = 0.5` (luminancia lineal) y `PALE_TINT` cálido. Actores, Bee y humano no cambian. Comprobado con capturas Compatibility en X=172/186/207 (`dev/lote11_review/`, ignoradas por git): el vaso queda beige cálido; la roca estructural en X=205 sigue verde oliva.

Pruebas dirigidas: `validate_bee_garden_identity_v04`, `validate_bee_visual_target_01`, `validate_bee_visual_polish_v02`. Suite completa: **82/82 PASS** (`dev/run_suite.sh`; cuenta como fallo un `SCRIPT ERROR`).

## B. Nivel 01 — densidad y dificultad

- **149 unidades / 71 eventos** (antes 107 / 59: +42 unidades, **+39,3 %**). Mismas familias, sin luciérnagas: las unidades nuevas son popcorn (un tiro). Doce eventos nuevos rellenan los tramos que quedaban vacíos; gates (X=254/296/340), checkpoints (190/281), telegrafía mínima y tiempos de liberación sin cambios.
- Formaciones: **V** de 5 (x2), **ola senoidal** (x3), **pinza desde ambos lados** (x2, `sides`), **entrada desde atrás** (x3, `from_left`, 5 m/s) y **kamikazes** (x2 eventos de 3): el popcorn se detiene, parpadea y muestra una línea cian **0,5 s** (medido 0,52 s), y embiste a 9 m/s por la dirección fijada al inicio del aviso (esquivable). Nuevas constantes: `KAMIKAZE_WARNING/SPEED/AIM_X/CONTACT_DAMAGE`, `SWARM_PATHS`.
- Topes: simultáneas **7 en ruta / 10 en zonas** (`MAX_ON_SCREEN`, `MAX_ON_SCREEN_ARENA`); las amenazas no popcorn siguen en 4/5/6 (`MAX_ROUTE_THREATS`).
- Medición del bot (Normal, Base, 3 tiros/s, sin invulnerabilidad antes del jefe):

| Métrica | Lote 10 | Lote 11 |
| --- | --- | --- |
| Entrada al jefe | 379,9 s (6,3 min) | 379,5 s (6,3 min) |
| Mayor hueco sin amenaza | 7,3 s | 3,8 s |
| Tiempo acumulado sin amenaza | 139 s | 105 s |
| Vida perdida antes del jefe | 60 (16 de lengua) | 60 (16 de lengua) |
| HP al entrar al jefe | 96 | 96 |
| Máx. simultáneas ruta / zonas (popcorn incl.) | 5 / 5 | 5 / 5 |

  El bot mata el popcorn al entrar, por eso las simultáneas medidas no suben de 5 aunque el tope sea 7/10; un jugador humano más lento debería acercarse al tope. Tampoco sube el daño: los kamikazes llegan a Bee solo si no se esquivan (el bot no los esquiva activamente). Rango objetivo de daño 45–70 y duración 5,5–7 min: cumplidos.
- Tests actualizados: conteos 59→71 eventos y 107→149 unidades (rango 144–150), topes 7/10, formaciones nuevas, primer evento en X=1,5, razón de eventos con arma a distancia (excluye el popcorn de relleno sin tiradores), cola pendiente (tope de ruta 6 amenazas). `validate_bee_pacing_v01` ahora exige entrada al jefe 330–420 s, daño 45–70, hueco ≤ 5 s. Nuevo `validate_bee_lote11_density_v01` (tabla, kamikaze 0,5 s con dirección fijada, entrada desde atrás).

Suite completa: **84/84 PASS** (`dev/run_suite.sh`, logs `dev/lote11_b_*.log`).
