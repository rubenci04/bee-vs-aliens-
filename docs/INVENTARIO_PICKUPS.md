# Inventario de pickups del Nivel 1 — T3g

El aspecto depende de **cómo se instancia el objeto**. `_swap_toon_pickups()` de `scripts/levels/bee_level_01_vertical_slice.gd` reemplaza los pickups fijos por escenas nuevas. Las recompensas de `bee_level_01_controller.gd` aún instancian la escena base; ese era el origen de los círculos con letras B/S y objetos celestes. T3g conserva esas escenas y sus reglas, y cambia solo su presentación al aparecer en Nivel 1.

| Pickup / ruta | Escena | Script | Antes: forma, color e ícono | Estado tras T3g | Cantidad / momento |
|---|---|---|---|---|---|
| Spread fijo | `scenes/items/toon/spread.tscn` | `scripts/items/toon_powerup_pickup.gd` → `bee_powerup_pickup.gd` | **Nuevo**: medallón hexagonal oscuro/dorado con flecha clara; beacon azul real y borde blanco | Se conserva | Spread 20 s, extensión de 10 s con tope existente; posiciones fijas originales |
| Bomba fija / suministros | `scenes/items/toon/bomb.tscn` | `scripts/items/toon_powerup_pickup.gd` | **Nuevo**: círculo rosa/rojo de beacon, modelo cálido marrón/dorado con ícono de bomba | Se conserva | +3 bombas, máximo 5; fijos, valle y suministro anterior al robot |
| Polen suelto | `scenes/items/toon/pollen.tscn` | `scripts/bee_prototype/pollen_pickup.gd` | **Nuevo**: conjunto de orbes dorados con halo lima; sin letra | Se conserva | 1 polen; selección de posiciones fijas y reducción de cantidad ya existentes |
| Racimo de polen | `scenes/items/toon/pollen_cluster.tscn` | `scripts/items/pollen_cluster_pickup.gd` | **Nuevo**: orbes dorados mayores, halo verde; sin letra | Se conserva | 10 polen; racimos de ruta, valle, suministros y recompensa tras robot; no cura directamente |
| Spread de recompensa dinámica | `scenes/bee_prototype/bee_powerup_pickup.tscn`, `kind=SPREAD` | `scripts/bee_prototype/bee_powerup_pickup.gd` | **Viejo**: círculo azul, letra S y prisma/cone celeste | Medallón hexagonal oscuro, anillo azul real, tres flechas marfil; borde claro y halo suave; sin letra/cone celeste | Mismos 20 s/extensión; recompensa tras robot, mismos offsets |
| Bomba de recompensa dinámica / ayuda de jefe | misma escena base, `kind=BOMB` | mismo script base | **Viejo**: círculo rojo, letra B, esfera celeste | Medallón hexagonal oscuro, anillo ámbar, bomba y mecha marfil; borde claro y halo suave | Mismo +3/tope 5; recompensa tras robot y ayuda de jefe bajo las condiciones originales |
| Spread S+ base | escena base, `overcharge=true` | script base | **Viejo**: S+, cono celeste, halo adicional celeste, escala 1,35 | Mismo medallón nuevo, conserva escala 1,35 y reglas del alias S+ | No añade otro nivel de arma; `collect_spread_overcharge()` conserva su comportamiento |
| Spread S+ toon | `scenes/items/toon/spread.tscn`, `overcharge=true` | `toon_powerup_pickup.gd` | **Nuevo**: medallón con flecha, escala 1,35 y halo cálido | Se conserva | Variante fija heredada, si la escena/configuración la coloca; sin cambio de posición o aparición |

El frasco de miel `scenes/items/toon/healing.tscn` / `scripts/items/toon_healing_pickup.gd` existe como respaldo/otros contextos. **No es la provisión actual del Nivel 1**: `TOON_HEALING` apunta a `pollen_cluster.tscn`. La escena original `scenes/bee_prototype/pollen_pickup.tscn` también se conserva; los fijos de Nivel 1 se reemplazan por su variante toon.

## Presentación de los antiguos

`scripts/items/bee_pickup_medallion.gd` oculta las piezas viejas y agrega un nodo visual. No borra assets, no cambia la raíz física ni el recurso de colisión. Radio del hexágono 0,42 m; anillo 0,51 m, borde claro hasta 0,545 m; emisión 1,2. Spread: azul real (0,42/0,48/0,92); bomba: ámbar (0,95/0,65/0,30). No se usan cian, magenta ni verde neón en los anillos nuevos.

Flotación: el mismo `toon_pickup_hover.gd` de los modernos (amplitud 0,055 m, seno de 2,4 rad/s y giro suave). La colisión permanece fija. El beacon viejo se oculta solo en los objetos que reciben `PickupMedallion`, para evitar duplicar anillo y columna; sus nodos se conservan. Los orbes/halos verdes de polen ya nuevos permanecen como estaban.

`docs/pickups_antes_despues.png` muestra las ocho rutas/variantes lado a lado: antes/después de día y antes/después de noche. Usa las escenas reales y la luz del nivel; no son bocetos. Herramienta de reproducción: `tools/pickups_antes_despues.gd` (requiere GPU).
