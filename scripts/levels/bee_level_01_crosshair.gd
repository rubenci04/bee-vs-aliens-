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

var bee: BeePlayer
var _cursor_hidden := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()


func _process(_delta: float) -> void:
	var aiming := bee != null and is_instance_valid(bee) and not bee.is_defeated and not get_tree().paused and bee.is_free_aiming()
	visible = aiming
	_set_cursor_hidden(aiming)
	if aiming:
		queue_redraw()


func aim_screen_point() -> Vector2:
	var camera := get_viewport().get_camera_3d()
	if camera == null or bee == null:
		return get_viewport().get_mouse_position()
	return camera.unproject_position(bee.aim_point)


func _draw() -> void:
	var c := aim_screen_point()
	draw_arc(c, RADIUS, 0.0, TAU, 32, OUTLINE, OUTLINE_WIDTH, true)
	draw_arc(c, RADIUS, 0.0, TAU, 32, RING, RING_WIDTH, true)
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		var from: Vector2 = c + direction * (RADIUS + 3.0)
		var to: Vector2 = c + direction * (RADIUS + 3.0 + TICK)
		draw_line(from, to, OUTLINE, OUTLINE_WIDTH - 1.0, true)
		draw_line(from, to, RING, RING_WIDTH, true)
	draw_circle(c, 3.6, OUTLINE)
	draw_circle(c, 2.2, DOT)


func _set_cursor_hidden(hidden: bool) -> void:
	if hidden == _cursor_hidden:
		return
	_cursor_hidden = hidden
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if hidden else Input.MOUSE_MODE_VISIBLE


func _exit_tree() -> void:
	if _cursor_hidden:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
