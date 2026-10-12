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

## C. Vida y emoción

- **Jugo (C1).** Destello **blanco de 0,06 s** al impactar a cualquier enemigo (`BeeJuice.attach_hit_flash`: reutiliza `HitFlash3D`; el controlador lo agrega a cada unidad, incluidas la fauna y el popcorn). **Pausa de 50 ms** (`Engine.time_scale` 0,02) al destruir o liberar algo grande (HP base ≥ 90: Walker, Organic, libélulas, escarabajo, caracol, araña…, toda liberación, rana, UFO); no se apila sobre otra ralentización ni pisa un cambio externo del tiempo. **Temblor leve**: ya existía en bomba y explosión del jefe; se agregó el de **daño recibido** (0,045 m, 0,2 s) y la opción **«Temblor de pantalla: SÍ/NO»** en el título (`BeeGameSettings.screen_shake_enabled`, leída por `BeeCameraShake` en todo el juego). **Estallido de polen** (26 partículas) al liberar un animal. **Imán de ítems**: polen, Spread y bomba se acercan a Bee dentro de 2,4 m (6,5–13 m/s); la miel curativa solo si Bee está herida y la bomba solo con espacio.
- **Pirueta (C2).** Shift (acción `bee_roll`): **0,35 s** invulnerable (`HealthComponent.invulnerable`, no toca `damage_blocked`), recarga **2,5 s**, giro visual de 360°. Las balas enemigas comunes (`AlienEnemyProjectile`, no las del UFO) que tocan a Bee durante la pirueta se destruyen sin daño. Indicador en el HUD («PIRUETA · SHIFT LISTA / [####------]»). Medido: 0,37 s, lista a los 2,5 s.
- **Combo y polen (C3).** Contador **xN** (arriba a la derecha) por destrucciones/liberaciones seguidas; se reinicia a los **3 s** sin impactos ni bajas (un golpe a un enemigo lo mantiene). Puntos por baja según HP (10/40/80/150, liberación 150, UFO 1000) × multiplicador (+10 % por paso, tope ×3); la tarjeta final muestra «SECTOR DESPEJADO · LIBERADOS n/N» y «PUNTAJE n · MEJOR COMBO xN». El polen ahora tiene efecto: **cada 17 de polen** (pickups + 1 por animal liberado) arranca el **Modo Miel**: 6 s de disparo doble (el segundo tiro hace el 50 % del daño: 1,5×) con barra «MIEL [###-------] n/17». El combo, el puntaje y la barra no se guardan en el checkpoint (el nivel se recarga).
- **Primer plano (C4).** 3 capas de briznas desenfocadas (shader `foreground_blade`, alfa 0,26–0,42, z = 3,2 / 6,0 / 7,9, 400 m de largo, MultiMesh) que pasan delante de Bee con más paralaje que el decorado, y **líneas de velocidad** leves (14 trazos, alfa ≤ 0,32) solo durante la pirueta.
- **Regadera (C5).** Evento de la zona 2 (acto 2, X=128, junto a la regadera gigante): 3 oleadas de 2 columnas de agua; **aviso de 1,0 s** (marca pulsante en el suelo + columna tenue; medido 1,00 s), caída de 0,5 s, **8 de daño** (moderado, como la lengua), una vez por columna; sin gate ni cambio de scroll; se juega una sola vez. El bot recibió 8 de daño en la pasada.
- **Verificación con el bot (C6).** Jefe del Lote 10, `validate_bee_boss_fight_v04` (Normal): **Base 84,5 s / Spread 75,6 s** (Fácil 90,6 / 80,4), idéntico al Lote 10: dentro de 75–100 s. Recorrido (Normal, Base, sin Modo Miel ni pausa de impacto en el bot): entrada al jefe **378,7 s (6,3 min)**, vida perdida **66** (16 lengua + 8 regadera), mayor hueco **3,8 s**, simultáneas 5/5. Con Modo Miel activo (`-- honey`) el bot llega ~20–30 s antes y pierde ~25 HP menos: es un potenciador opcional, por eso la medición oficial lo apaga.
- Tests: nuevo `validate_bee_lote11_juice_v01` (destello 0,06 s, pausa 50 ms con restauración, temblor sí/no, estallido, pirueta con balas absorbidas e invulnerabilidad, combo/puntaje/reinicio a 3 s, Modo Miel a 17, imán, capas, regadera con aviso 1 s y daño único, opción del título). Ajustes a tests viejos: eventos 72, lista de momentos con `watering_can`, el imán se congela en 4 fixtures que miden daño/inventario cerca de ítems, el final del jefe espera 720 fotogramas (antes 600 justos) y el bot de ritmo apaga la pausa de impacto y el Modo Miel.
- `CLAUDE.md`: controles actualizados (Shift, Modo Miel, temblor); «Dash/roll» ya no figura como fuera de alcance.

Suite completa: **86/86 PASS** (`dev/run_suite.sh`; logs `dev/lote11_c2_*.log`). Primera pasada: 76 PASS y 9 fallos, causados por el imán de ítems, la lista de momentos, un `await` de 600 fotogramas y la caché de clases; corregidos y repetida la suite completa.

Para jugar: abrir Nivel 01, ver «PIRUETA · SHIFT LISTA» y pulsar Shift con balas cerca; liberar animales y encadenar bajas para el xN; juntar 17 de polen para el Modo Miel; pasar por X≈128 para las columnas de agua; mirar las briznas del primer plano; en el título, alternar «Temblor de pantalla».
