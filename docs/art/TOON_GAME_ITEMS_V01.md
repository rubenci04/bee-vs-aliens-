# Bee Alien · Ítems toon reutilizables

Los cuatro modelos existentes ahora tienen escenas de recogida independientes, con triggers `Area3D`, animación suave sólo del visual y una prueba aislada con Bee. Se reutilizan las fuentes `.blend`, GLB y wrappers toon de `pickups_toon_v01`; no se duplican modelos ni se cambia el Nivel 01.

| Ítem | Modelo, triángulos | Escena de juego | Efecto |
| --- | ---: | --- | --- |
| Polen dorado | 2.096 | `scenes/items/toon/pollen.tscn` | Regla existente de polen: restaura hasta 20 HP y emite `collected` para que el nivel cuente la recogida; también se recoge con HP completa |
| Spread, tres flechas | 1.564 | `scenes/items/toon/spread.tscn` | Llama `BeePlayer.collect_spread()`; recarga la munición configurada, actualmente 32 ráfagas |
| Bomba con banda de miel | 2.068 | `scenes/items/toon/bomb.tscn` | Añade una carga con `collect_bomb()`; permanece disponible al alcanzar el máximo, actualmente 3 |
| Curación, tarro y corazón | 1.656 | `scenes/items/toon/healing.tscn` | Restaura hasta 30 HP; permanece disponible a vida completa; no revive a Bee derrotada |

`heal_amount` es configurable. Spread conserva la opción `overcharge` y su regla de munición existente, con halo cálido sin emisión. Los ítems usan miel, crema, terracota y verde, con contorno fino y cel shading. Los efectos de recogida de Spread/bomba son ahora el burst cálido existente de Bee, evitando el cian de los pickups anteriores. Polen y curación conservan el feedback cálido del polen. Los volúmenes de contacto permanecen fijos mientras el hijo visual flota y oscila suavemente.

Las clases derivadas mantienen compatibilidad con `BeePowerupPickup` y `BeePollenPickup`. La curación comparte el tipo de señal de polen: al integrarla, conectar su señal al evento de curación previsto, sin contarla automáticamente como polen de misión. No se configura moneda ni inventario de polen nuevo; se conserva el comportamiento actual del juego.

## Archivos de esta tarea

- Cuatro escenas nuevas en `scenes/items/toon/`.
- `scripts/items/toon_powerup_pickup.gd`: usa las APIs actuales de armas y feedback cálido.
- `scripts/items/toon_healing_pickup.gd`: conserva curación disponible si no hace falta.
- `scripts/items/toon_pickup_hover.gd`: presentación sin mover el trigger.
- `scenes/art_labs/pickups_game_toon_v01.tscn` y `scripts/art/pickups_game_toon_lab.gd`: prueba aislada.
- `tests/bee_prototype/validate_toon_items_v01.gd`: recogida, capacidad, salud, señales y feedback.
- `tools/art/capture_toon_items_game.gd` y `docs/art/pickups_game_toon_v01/`: capturas reales antes/después.
- Modificado `scripts/art/art_delivery_hub_v01.gd`: enlace a la prueba.

Fuentes de arte conservadas: `art_source/blender/pickups_toon_v01/*.blend`, `assets/models/pickups_toon_v01/*.glb` y sus wrappers `scenes/art_labs/pickups_toon_v01/`. No se modifican `BeePlayer`, los pickups antiguos ni la colocación o recompensas del nivel.

## Cómo probar

Ejecutar `scenes/art_labs/pickups_game_toon_v01.tscn` con **F6**, o entrar a **Ítems toon · prueba de recogida** desde la colección.

Bee inicia con 60/100 HP, sin Spread ni bombas. **1–4** o los botones recogen cada ítem mediante su método real. **R** reinicia la prueba, **H** oculta la interfaz y **Esc** vuelve a la colección. La prueba desactiva contacto automático y movimiento del jugador; los wrappers de juego conservan recogida física automática para usarlos en niveles.

Para inspeccionar sólo los modelos lateral/3/4, usar `scenes/art_labs/pickups_toon_v01.tscn`. Para integrar, instanciar las escenas de `scenes/items/toon/` bajo un `Node3D` del mundo, en el plano XY del juego. Conectar `collected` según la regla de misión que corresponda. No reemplazar por el GLB solo, que no tiene lógica de recogida.

## Verificación y problemas

Validador con Bee real: recogida física del polen, señal de HP restaurados, rechazo de cuerpos ajenos/Bee derrotada, Spread y overcharge, no doble recogida, bomba disponible al tope y curación limitada a HP máxima: **0 fallos**. Revisión de capturas en Godot 4.7.2 Compatibility, mostrando al finalizar 100/100 HP, 32 ráfagas y 1/3 bombas. También se verifica que el feedback de Bee use el burst cálido sin emisión.

Advertencia conocida de caché de shaders `user://` en la sesión restringida; no impidió capturar ni validar. Las escenas están listas para instanciar, pero aún no se han colocado en el nivel jugable.
