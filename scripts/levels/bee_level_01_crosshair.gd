class_name BeeLevel01Crosshair
extends Control
const SETTINGS := preload("res://scripts/game/bee_shooting_settings.gd")
## Tanda 4a: always-visible gameplay reticle on the corrected firing ray.
## Thin open ring, faint when idle; optional F4 cone/selected-target debug.

const RING := Color(1.0, 0.86, 0.28)
const HOVER_RADIUS := 1.1

var bee: BeePlayer
var _cursor_hidden := false
var hovered: Node3D # LOTE 9: the hostile under the crosshair (null = none).
var _t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()


func _process(delta: float) -> void:
	_t += delta
	var aiming := bee != null and is_instance_valid(bee) and not bee.is_defeated and not get_tree().paused
	if aiming and bee.get_parent().get("sector_complete") == true:
		aiming = false
	visible = aiming
	# TANDA 1 · H-03: the OS cursor stays hidden for the whole gameplay (mouse or pad); it comes back on pause and defeat.
	_set_cursor_hidden(bee != null and is_instance_valid(bee) and not bee.is_defeated and not get_tree().paused)
	hovered = bee.aim_assist_target if aiming else null
	if aiming:
		queue_redraw()


## The live hostile closest to `point` within HOVER_RADIUS (X/Y plane), or null.
func hostile_at(point: Vector3) -> Node3D:
	var best: Node3D
	var best_d := HOVER_RADIUS
	for node in get_tree().get_nodes_in_group("bee_auto_aim_targets"):
		var target := node as Node3D
		if target == null or not target.is_visible_in_tree():
			continue
		var at: Vector3 = target.call("auto_aim_point") if target.has_method("auto_aim_point") else target.global_position
		var hurtbox := target.get_node_or_null("Hurtbox3D") as Node3D
		var d := Vector2(point.x - at.x, point.y - at.y).length()
		if hurtbox != null:
			d = minf(d, Vector2(point.x - hurtbox.global_position.x, point.y - hurtbox.global_position.y).length())
		if d < best_d:
			best_d = d
			best = target
	return best


func aim_screen_point() -> Vector2:
	var camera := get_viewport().get_camera_3d()
	if camera == null or bee == null:
		return get_viewport().get_mouse_position()
	var origin := bee.firing_origin()
	var from := camera.unproject_position(origin)
	var to := camera.unproject_position(origin + bee.aim_direction() * SETTINGS.RETICLE_DISTANCE)
	var delta := to - from
	var bounds := get_viewport().get_visible_rect().grow(-SETTINGS.RETICLE_SCREEN_MARGIN)
	var fraction := 1.0
	if delta.x > 0.001:
		fraction = minf(fraction, (bounds.end.x - from.x) / delta.x)
	elif delta.x < -0.001:
		fraction = minf(fraction, (bounds.position.x - from.x) / delta.x)
	if delta.y > 0.001:
		fraction = minf(fraction, (bounds.end.y - from.y) / delta.y)
	elif delta.y < -0.001:
		fraction = minf(fraction, (bounds.position.y - from.y) / delta.y)
	return from + delta * clampf(fraction, 0.0, 1.0)


func _draw() -> void:
	var c := aim_screen_point()
	var alpha := SETTINGS.RETICLE_ACTIVE_OPACITY if bee.is_free_aiming() else SETTINGS.RETICLE_IDLE_OPACITY
	var color := Color(RING, alpha)
	# Open, thin ring: no filled centre or enemy-covering lock brackets.
	for quadrant in 4:
		var start := quadrant * PI * 0.5 + 0.12
		draw_arc(c, SETTINGS.RETICLE_RADIUS, start, start + PI * 0.5 - 0.24, 8, color, SETTINGS.RETICLE_WIDTH, true)
	if bee.aim_debug_enabled:
		var camera := get_viewport().get_camera_3d()
		var origin := bee.firing_origin()
		var raw := bee.raw_aim_direction()
		var screen_origin := camera.unproject_position(origin)
		for side in [-1.0, 1.0]:
			var direction := raw.rotated(Vector3.BACK, deg_to_rad(SETTINGS.AIM_ASSIST_ANGLE * side))
			draw_line(screen_origin, camera.unproject_position(origin + direction * SETTINGS.AIM_ASSIST_RANGE), Color(0.2, 0.9, 1, 0.4), 1.0, true)
		if is_instance_valid(bee.aim_assist_target):
			var target := camera.unproject_position(bee.AIM_HELP.point(bee, bee.aim_assist_target))
			draw_line(screen_origin, target, Color(1, 0.3, 0.8, 0.6), 1.0, true)
			draw_arc(target, 10.0, 0.0, TAU, 24, Color(1, 0.3, 0.8, 0.8), 1.5, true)


func _set_cursor_hidden(hidden: bool) -> void:
	if hidden == _cursor_hidden:
		return
	_cursor_hidden = hidden
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if hidden else Input.MOUSE_MODE_VISIBLE


func _exit_tree() -> void:
	if _cursor_hidden:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
