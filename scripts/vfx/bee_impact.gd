extends RefCounted
## Tanda V · parte 1 — golpes con peso. Un solo lugar para los tres momentos: liberar, puñetazo/aguijón y bomba.
## Usa el congelado local (bee_local_hit_stop.gd), la sacudida (BeeCameraShake) y los efectos que ya existían.
const S := preload("res://scripts/game/bee_impact_settings.gd")
const HIT_STOP := preload("res://scripts/vfx/bee_local_hit_stop.gd")

## Zoom de cámara pendiente (lo aplica el nivel sobre el FOV, sin tocar los límites de vuelo).
static var zoom_left := 0.0


## A. Un insecto fue liberado: congelado local corto (más largo y con sacudida si es grande) y estallido dorado.
static func freed(host: Node, visual: Node3D, at: Vector3) -> void:
	if not S.IMPACT_ENABLED or host == null or not host.is_inside_tree():
		return
	var unit := _unit_of(visual)
	var big := is_big(unit)
	var bee := host.get_tree().get_first_node_in_group("bee_player") as Node3D
	if bee != null:
		var direction := Vector2(at.x - bee.global_position.x, at.y - bee.global_position.y)
		HIT_STOP.for_host(bee).trigger(bee, &"free_big" if big else &"free_small", unit, direction if direction != Vector2.ZERO else Vector2.RIGHT, S.FREE_BIG_STOP if big else S.FREE_SMALL_STOP)
		if big:
			BeeCameraShake.kick(bee, S.FREE_BIG_SHAKE, 0.18, Vector2.UP)
	BeeCombatVFX.spawn(host, at, &"pollen", Vector3.UP, S.FREE_BURST_SCALE)


## Escarabajos y arañas cuentan como grandes.
static func is_big(unit: Node) -> bool:
	if unit == null:
		return false
	var script_path: String = (unit.get_script() as Script).resource_path if unit.get_script() != null else ""
	var text := (str(unit.name) + " " + script_path).to_lower()
	for kind in S.FREE_BIG_KINDS:
		if kind in text:
			return true
	return false


static func _unit_of(visual: Node) -> Node:
	var node := visual
	while node != null and not (node.has_node("HealthComponent")):
		node = node.get_parent()
	return node


## B. Puñetazo / aguijón que conecta: zoom corto (el congelado lo pide bee_player con MELEE_STOP).
static func melee_connect() -> void:
	if S.IMPACT_ENABLED:
		zoom_left = S.MELEE_ZOOM_SECONDS


## Factor de FOV del zoom: 1 sin zoom; sube y baja en MELEE_ZOOM_SECONDS.
static func fov_factor(delta: float) -> float:
	if zoom_left <= 0.0:
		return 1.0
	zoom_left = maxf(0.0, zoom_left - delta)
	var t := 1.0 - zoom_left / S.MELEE_ZOOM_SECONDS
	return 1.0 - S.MELEE_ZOOM * sin(PI * t)


## C. La bomba explota: destello de pantalla, sacudida, onda del radio real y cara contenta.
static func bomb(bomb_node: Node3D, radius: float) -> void:
	if not S.IMPACT_ENABLED or bomb_node == null or not bomb_node.is_inside_tree():
		return
	var parent := bomb_node.get_parent()
	BeeCameraShake.kick(bomb_node, S.BOMB_SHAKE, 0.24, Vector2.UP)
	_wave(parent, bomb_node.global_position, radius)
	_flash(bomb_node)
	for visual in bomb_node.get_tree().get_nodes_in_group("bee_visual_instances"):
		if visual.has_method("feel_happy"): visual.call("feel_happy")


static func _wave(parent: Node, at: Vector3, radius: float) -> void:
	var ring := BeeAttackVisuals.ring(parent, at, radius, S.BOMB_WAVE_THICKNESS, S.BOMB_WAVE_COLOR)
	if ring == null:
		return
	ring.name = "BombWave"
	ring.scale = Vector3(radius * 0.2, 1.0, radius * 0.2) # El aro crece hasta el radio real de la bomba.
	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector3(radius, 1.0, radius), S.BOMB_WAVE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(ring.queue_free)


static func _flash(from: Node) -> void:
	var layer := CanvasLayer.new()
	layer.name = "BombFlash"
	layer.layer = 25
	var rect := ColorRect.new()
	rect.color = S.BOMB_FLASH_COLOR
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	var host: Node = from.get_tree().current_scene if from.get_tree().current_scene != null else from.get_tree().root
	host.add_child(layer)
	var tween := rect.create_tween()
	tween.tween_property(rect, "color:a", 0.0, S.BOMB_FLASH_SECONDS)
	tween.tween_callback(layer.queue_free)
