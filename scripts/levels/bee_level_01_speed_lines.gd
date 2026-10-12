class_name BeeLevel01SpeedLines
extends Control
## LOTE 11 · C4 — mild speed lines on the screen while Bee rolls: thin white streaks rushing along the flight direction.
## Pure HUD decoration (mouse ignored), invisible the rest of the time.

const LINE_COUNT := 14
const MAX_ALPHA := 0.32
const LENGTH_MIN := 0.14 ## fraction of the screen width
const LENGTH_MAX := 0.36
const FADE_SECONDS := 0.12
const SPEED := 2.4 ## screen widths per second

var bee: BeePlayer
var intensity := 0.0
var _seeds: Array[Vector3] = [] # x phase, y position (0..1), length factor


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in LINE_COUNT:
		_seeds.append(Vector3(rng.randf(), rng.randf_range(0.12, 0.88), rng.randf()))


func _process(delta: float) -> void:
	var target := 1.0 if bee != null and bee.is_rolling else 0.0
	intensity = move_toward(intensity, target, delta / FADE_SECONDS)
	visible = intensity > 0.001
	if visible:
		queue_redraw()


func _draw() -> void:
	var size_px := get_viewport_rect().size
	var direction := -1.0 if bee != null and bee.facing_x > 0.0 else 1.0 # Lines rush AGAINST the flight direction.
	var now := Time.get_ticks_msec() / 1000.0
	for seed_value in _seeds:
		var length := lerpf(LENGTH_MIN, LENGTH_MAX, seed_value.z) * size_px.x
		var travel := fposmod(seed_value.x + now * SPEED * (0.7 + seed_value.z * 0.6), 1.0)
		var x := (travel if direction > 0.0 else 1.0 - travel) * (size_px.x + length) - length
		var y := seed_value.y * size_px.y
		draw_line(Vector2(x, y), Vector2(x + length, y), Color(1.0, 1.0, 1.0, MAX_ALPHA * intensity), 2.0)
