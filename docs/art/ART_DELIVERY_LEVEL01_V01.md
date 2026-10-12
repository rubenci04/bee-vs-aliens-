# Bee Alien · Fauna ligera y assets de campaña

Entrega del 11 de octubre de 2026. Tandas pequeñas, con revisión lateral y 3/4 en Godot 4.7.2 Compatibility y fuentes Blender 5.2.1. Geometría original local, sin biblioteca externa.

## Versiones ligeras

Los recuentos incluyen animal, alas, accesorios e implante. La comparación usa los modelos de arte originales de Codex; no los enemigos de ~1.000 triángulos que ya están integrados en el Nivel 01.

| Pieza | Original de arte | GLB ligero | Reducción |
| --- | ---: | ---: | ---: |
| Hormiga | 13.456 | 4.980 | 63,0% |
| Mosquito | 7.840 | 4.954 | 36,8% |
| Mariquita voladora | 9.384 | 4.954 | 47,2% |
| Oruga blindada | 20.344 | 4.968 | 75,6% |

Fuentes detalladas conservadas. Copias editables en `art_source/blender/swarm_lite_v01/`, exportaciones en `assets/models/swarm_lite_v01/`, wrappers toon en `scenes/art_labs/swarm_lite_v01/`. `manifest.json` incluye las rutas de origen, triángulos, reducción y superficies. El generador contrasta el recuento de Blender con los índices reales del GLB y verifica sólidos cerrados sin caras degeneradas.

Cada copia tiene dos mallas: `NaturalFauna` y `AlienControlDevice`. El implante se puede ocultar entero sin perder anatomía. Se conservan referencias vacías para futuros rigs; la geometría se agrupa para reducir objetos. Hay 8–10 superficies de material por modelo, más el pase de contorno: el número de triángulos no equivale a un benchmark de FPS ni a dos draw calls. No tienen rig ni LOD automático.

## Piezas nuevas

| Tanda | Pieza | Triángulos |
| --- | --- | ---: |
| `future_biomes_v11` | Araña colgante, ocho patas, seda natural y anclaje `SilkAnchor` | 4.930 |
| `future_biomes_v11` | Águila, pico ganchudo, alas anchas y plumas separadas | 6.914 |
| `pickups_toon_v01` | Polen dorado | 2.096 |
| `pickups_toon_v01` | Spread, tres flechas divergentes | 1.564 |
| `pickups_toon_v01` | Bomba Bee | 2.068 |
| `pickups_toon_v01` | Curación, tarro de miel con corazón | 1.656 |
| `projectiles_toon_v01` | Disparo Bee | 864 |
| `projectiles_toon_v01` | Disparo alien | 864 |
| `mothership_v01` | Nave nodriza, puente, brazos, hangar y motores gemelos | 6.764 |

Fuentes `.blend` en `art_source/blender/<tanda>/`, GLB y manifiesto en `assets/models/<tanda>/`. Wrappers toon: `scenes/art_labs/assets_v11/` para araña/águila; las demás tandas usan `scenes/art_labs/<tanda>/`. Las criaturas tienen el implante canónico removible. La nave tiene referencias `HangarSpawn`, `MainLensTarget`, `BossOrigin` y dos `EscortDock` para una futura integración de jefe.

Cel shading, bandas planas, rim suave y contorno fino con `BeeToonStyle`; emisiones limitadas a 0,65 para mantener los colores en Compatibility. Polen y mejoras usan miel, crema, verde y terracota sin emisión. Cian y violeta pertenecen al dispositivo o al disparo alien.

## Explosiones y mini-jefe del lago

`scenes/vfx/bee_toon_burst.tscn` y `alien_toon_burst.tscn` usan `scripts/art/toon_burst_visual.gd`: núcleo, anillo expansivo y diez fragmentos, sin dependencia de bloom. Las explosiones son procedurales nativas de Godot; su fuente editable es el script. `play()` permite repetir; `seek(segundos)` permite revisar cuadros; `finished` se emite al terminar y `free_when_finished` controla la eliminación. Bee amarillo/crema; alien cian/violeta. No aplican daño.

`scenes/levels/level_02_lake/lake_toad_miniboss_visual.tscn` instancia directamente el sapo original `assets_v09/amphibian_mount_study.tscn`, que a su vez usa su GLB original y fuente V09. No se duplica ni remodela. La presentación añade anticipación, salto y regreso al nenúfar. `release_control()` retira tecnología y detiene el patrón. `lake_miniboss_v01.tscn` muestra su escala respecto de Bee en el lago.

Estos son assets y estudios visuales. Falta conectar daño, colisiones, IA, recompensas, animación esquelética y estados de combate del mini-jefe/nodriza. Los enemigos del nivel no se sustituyen automáticamente. La araña incluye la seda modelada y el anclaje, pero no un controlador de peligro vertical.

## Logo y pantalla de título

`assets/ui/bee_alien_logo_v01.svg`: vector editable con letras trazadas, contorno cálido y emblema de abeja; sin dependencia de una fuente tipográfica. Cian/violeta sólo en el módulo externo del emblema. La pantalla `scenes/art_labs/title_screen_v01.tscn` reutiliza Bee mid-poly, árboles y flores locales, con partículas de polen cálidas. No cambia `project.godot`.

El botón **Jugar Nivel 01** abre la escena existente del nivel. **Colección de arte** abre el índice de las seis galerías. **Salir** cierra esta ejecución. Se usa el foco y la navegación de teclado normales de Godot.

## Cómo visualizar

1. Abrir el proyecto en Godot y ejecutar `scenes/art_labs/title_screen_v01.tscn` con **F6**.
2. Elegir **Colección de arte**, o ejecutar directamente `scenes/art_labs/art_delivery_hub_v01.tscn`.
3. En los catálogos: **1–4** seleccionan piezas, **E** regresa al estudio, **V** cambia lateral/3/4, **H** oculta la interfaz, **L** retira/restaura los implantes de fauna. **Esc** vuelve al índice.
4. En efectos: **Espacio** repite las explosiones. En el lago: **P** pausa, **L** libera y **H** oculta UI.

Las fichas individuales de criaturas tienen fondo neutro, sin escenario ni texto. Las capturas limpias y con UI están en `docs/art/<tanda>/`. Para uso real en niveles, instanciar los wrappers toon, no sólo el GLB sin estilizar.

## Archivos y verificación

- Generadores: `tools/art/create_swarm_lite_v01.py`, `create_future_biomes_v11.py`, `create_pickups_toon_v01.py`, `create_projectiles_toon_v01.py`, `create_mothership_v01.py`.
- Galería compartida: `scripts/art/asset_catalog_lab.gd`; galerías y wrappers nuevos en las carpetas descritas arriba.
- Efectos: `scripts/art/toon_burst_visual.gd`, `projectiles_toon_lab.gd`, escenas en `scenes/vfx/`.
- Lago: `scripts/art/lake_toad_miniboss_visual.gd`, `lake_miniboss_lab.gd`, wrapper `assets_lake/` y escena de estudio.
- Menú: `scripts/art/title_screen_v01.gd`, `art_delivery_hub_v01.gd`, sus escenas y logo SVG.
- Captura: `tools/art/capture_catalog.gd`, `capture_lake_miniboss.gd`, `capture_title_v01.gd`.
- Validadores: `tests/art/validate_swarm_lite_v01.gd`, `validate_future_biomes_v11.gd`, `validate_pickups_toon_v01.gd`, `validate_effects_and_lake_v01.gd`, `validate_mothership_and_title_v01.gd`.

Los cinco validadores pasaron con **0 fallos**: importación, presupuestos reales, materiales toon/contorno, separación y retirada de implantes, anatomía de araña/águila, paleta de ítems/efectos, finalización/repetición de explosiones y reutilización del sapo. Revisión visual de las capturas reales con Intel Arc B580 en Compatibility.

Problemas del entorno: Godot no puede escribir la caché de shaders `user://` ni guardar sus preferencias del editor dentro de esta sesión restringida. Las importaciones, capturas y validadores completaron; esas advertencias no invalidan los assets. No se midió rendimiento de enjambres en juego.

No se modificaron las fuentes detalladas, los controladores de juego, la escena principal ni otros proyectos. Los cambios ajenos que ya existen en el directorio se preservan.
