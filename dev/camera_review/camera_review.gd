extends Node
## DEV ONLY. Loads Level 01 untouched and overrides the camera each frame.
## 1/2/3/4 = presets A/B/C/D, PageUp/PageDown = camera height offset.
## Bee is additionally clamped to the visible area of the active preset.

const PRESETS := [
	{"name": "A · ACTUAL", "dist": 13.0, "y": 4.0, "pitch": 0.0},
	{"name": "B · INTERMEDIA", "dist": 8.5, "y": 4.0, "pitch": 0.0},
	{"name": "C · CERCANA", "dist": 6.5, "y": 4.0, "pitch": 0.0},
	{"name": "D · EXPERIMENTAL (baja, mira arriba)", "dist": 8.5, "y": 2.0, "pitch": 5.0},
]
const MARGIN := Vector2(0.55, 0.35) # Bee half length / half height plus a little air.

@onready var level: BeeShmupStage = $Level
var camera: Camera3D
var label: Label
var index := 0
var y_offset := 0.0
var visible_rect := Rect2() # World X/Y visible at the Z=0 flight plane.

func _ready() -> void:
	process_priority = 100 # Run after the stage so our camera/clamp win.
	camera = level.camera
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	layer.add_child(label)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1: index = 0
			KEY_2: index = 1
			KEY_3: index = 2
			KEY_4: index = 3
			KEY_PAGEUP: y_offset += 0.25
			KEY_PAGEDOWN: y_offset -= 0.25
			KEY_HOME: y_offset = 0.0

func _physics_process(_delta: float) -> void:
	_refresh()
	if level.bee == null:
		return
	var p := level.bee.global_position
	p.x = clampf(p.x, visible_rect.position.x + MARGIN.x, visible_rect.end.x - MARGIN.x)
	p.y = clampf(p.y, visible_rect.position.y + MARGIN.y, visible_rect.end.y - MARGIN.y)
	level.bee.global_position = p

func _process(_delta: float) -> void:
	_refresh()
	var size := get_viewport().get_visible_rect().size
	label.size = Vector2(760, 90)
	label.position = Vector2(size.x - 776, 10)

func _refresh() -> void:
	var preset: Dictionary = PRESETS[index]
	camera.global_position = Vector3(level.distance, float(preset["y"]) + y_offset, float(preset["dist"]))
	camera.rotation = Vector3(deg_to_rad(float(preset["pitch"])), 0.0, 0.0)
	camera.fov = 40.0
	visible_rect = compute_visible_rect(camera)
	label.text = "CÁMARA %s\ndist %.1f · FOV 40 · y %.2f · pitch %.0f° · visible %.1f × %.1f m\n[1][2][3][4] preset · [RePág/AvPág] altura · [Inicio] reset" % [
		preset["name"], preset["dist"], float(preset["y"]) + y_offset, preset["pitch"], visible_rect.size.x, visible_rect.size.y]

static func compute_visible_rect(cam: Camera3D) -> Rect2:
	var vp := cam.get_viewport().get_visible_rect().size
	var tl := _hit(cam, Vector2(0, 0))
	var tr := _hit(cam, Vector2(vp.x, 0))
	var bl := _hit(cam, Vector2(0, vp.y))
	var br := _hit(cam, Vector2(vp.x, vp.y))
	var x_min := maxf(tl.x, bl.x)
	var x_max := minf(tr.x, br.x)
	var y_min := minf(bl.y, br.y)
	var y_max := maxf(tl.y, tr.y)
	return Rect2(Vector2(x_min, y_min), Vector2(x_max - x_min, y_max - y_min))

static func _hit(cam: Camera3D, point: Vector2) -> Vector2:
	var origin := cam.project_ray_origin(point)
	var dir := cam.project_ray_normal(point)
	var t := -origin.z / dir.z
	var hit := origin + dir * t
	return Vector2(hit.x, hit.y)
