# Informe Lote 10

## A. Nivel 01 — fauna, utilería, ciclo solar y vuelo

- Luciérnagas reservadas para un futuro bosque mediante `FIREFLIES_ENABLED`; Nivel 01 ya no instancia sus modelos ni partículas. Se conservaron las escenas y el movimiento.
- El modelo Kenney `log_large.glb` de X≈55 se ocultó y el tronco hueco marrón existente se colocó después de la botella verde y antes del árbol. El collider original del tramo permanece.
- La paleta compartida de las rocas cambió de gris cálido a oliva gris apagado. Corrige el hexágono claro junto a la manzana y la roca beige junto al momento de la rana sin alterar geometría ni colisiones.
- Se conectó el sol toon existente al avance del nivel, con halo cálido suave: bajo por la mañana, alto al mediodía y oscurecido al salir la luna. Está en la zona superior derecha, fuera del HUD.
- Bee puede recorrer el 95% del ancho visible, con márgenes horizontales iguales del 2,5%; los márgenes verticales siguen iguales. La validación cubre 16:9 y 16:10. El encuadre previo del prototipo de lago se conserva.

Pruebas dirigidas: `validate_bee_level_01_framing_v01`, `validate_bee_threat_camera_boss_v03`, `validate_bee_asset_fauna_v01`, `validate_bee_visual_target_01`, `validate_bee_polish_props_v01` y `validate_bee_level02_lake_proto`. Suite completa: **78/78 PASS** (Godot 4.7.2, `--headless`; sin errores de script).
