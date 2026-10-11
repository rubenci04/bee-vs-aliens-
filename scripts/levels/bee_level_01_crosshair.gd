class_name BeeLevel01Crosshair
extends Control
## LOTE 7 — FREE AIM crosshair (HUD). Drawn only while Bee is aiming with the mouse (BeePlayer.is_free_aiming()); otherwise the
## usual auto-aim marker is used and the OS cursor comes back. Toon look like the HUD: thick dark outline + warm yellow ring,
## four ticks and a dot. While it is shown the OS cursor is hidden (and restored on pause / defeat / exit).

const RADIUS := 13.0
const OUTLINE := Color(0.07, 0.05, 0.04, 0.95)
const RING := Color(1.0, 0.86, 0.28)
const DOT := Color(0.35, 1.0, 1.0) # Same cyan as the weapon HUD.
const OUTLINE_WIDTH := 6.0
const RING_WIDTH := 2.6
const TICK := 7.0
## LOTE 9 — cyan means hostile: over an enemy / implant (within HOVER_RADIUS m of the aim point) the ring turns cyan,
## grows and pulses, and lock brackets frame the target.
const HOSTILE := Color(0.25, 1.0, 1.0)
const HOVER_RADIUS := 1.1
const HOVER_GROW := 1.3

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
	var aiming := bee != null and is_instance_valid(bee) and not bee.is_defeated and not get_tree().paused and bee.is_free_aiming()
	visible = aiming
	_set_cursor_hidden(aiming)
	hovered = hostile_at(bee.aim_point) if aiming else null
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
	return camera.unproject_position(bee.aim_point)


func _draw() -> void:
	var c := aim_screen_point()
	var hostile := hovered != null and is_instance_valid(hovered)
	var colour := HOSTILE if hostile else RING
	var radius := RADIUS * (HOVER_GROW + 0.08 * sin(_t * TAU * 2.0) if hostile else 1.0)
	draw_arc(c, radius, 0.0, TAU, 32, OUTLINE, OUTLINE_WIDTH, true)
	draw_arc(c, radius, 0.0, TAU, 32, colour, RING_WIDTH, true)
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		var from: Vector2 = c + direction * (radius + 3.0)
		var to: Vector2 = c + direction * (radius + 3.0 + TICK)
		draw_line(from, to, OUTLINE, OUTLINE_WIDTH - 1.0, true)
		draw_line(from, to, colour, RING_WIDTH, true)
	draw_circle(c, 3.6, OUTLINE)
	draw_circle(c, 2.2, DOT)
	if hostile:
		# Lock brackets around the hostile itself (where its cyan implant / core is).
		var camera := get_viewport().get_camera_3d()
		if camera != null:
			var at: Vector3 = hovered.call("auto_aim_point") if hovered.has_method("auto_aim_point") else hovered.global_position
			var p := camera.unproject_position(at)
			var s := 22.0
			for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				var k: Vector2 = p + corner * s
				draw_line(k, k - Vector2(corner.x * 9.0, 0.0), OUTLINE, 5.0, true)
				draw_line(k, k - Vector2(0.0, corner.y * 9.0), OUTLINE, 5.0, true)
				draw_line(k, k - Vector2(corner.x * 9.0, 0.0), HOSTILE, 2.4, true)
				draw_line(k, k - Vector2(0.0, corner.y * 9.0), HOSTILE, 2.4, true)


func _set_cursor_hidden(hidden: bool) -> void:
	if hidden == _cursor_hidden:
		return
	_cursor_hidden = hidden
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if hidden else Input.MOUSE_MODE_VISIBLE


func _exit_tree() -> void:
	if _cursor_hidden:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
