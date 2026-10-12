class_name BeeLevel01WateringEvent
extends Node3D
## LOTE 11 · C5 — "la regadera": the giant watering can of act 2 (X=127) empties over the garden. Columns of water fall
## straight down with a 1 s warning (a pulsing mark on the ground + a faint column), do moderate damage and are easy to
## sidestep. Played once, from the director moment `watering_can` (EVENTS, X=128); no gate, the scroll never stops.

const MOMENT := &"watering_can"
const WARNING_SECONDS := 1.0 ## Never below the 0.4 s minimum telegraph.
const ACTIVE_SECONDS := 0.5
const WAVE_GAP_SECONDS := 3.0 ## From one wave's warning to the next one's.
const START_DELAY := 0.4
const DAMAGE := 8 ## Moderate (same as the frog's tongue).
const COLUMN_WIDTH := 1.1
const COLUMN_TOP_Y := 8.5
const GROUND_Y := -0.12
## Lanes as fractions of the visible half width (0 = screen centre); each wave uses two with a gap Bee can sidestep into.
const LANES := [-0.62, -0.18, 0.28, 0.66]
const WAVES := [[0, 2], [1, 3], [0, 3]]
const WARNING_COLOR := Color(0.55, 0.82, 1.0, 0.42)
const COLUMN_COLOR := Color(0.62, 0.86, 1.0, 0.62)

signal column_warned(x: float)
signal column_fell(x: float)

@export var stage_path: NodePath = ^".."
var stage: BeeShmupStage
var played := false
var running := false
var columns: Array[Dictionary] = []
var columns_spawned := 0
var columns_hit := 0
var min_warning_measured := INF
var _time := 0.0
var _next_wave := 0
var _next_wave_at := 0.0


func _ready() -> void:
	stage = get_node(stage_path) as BeeShmupStage
	stage.get_node("WaveController").director_moment.connect(_on_moment)


func _on_moment(id: StringName) -> void:
	if id == MOMENT and not played:
		begin()


func begin() -> void:
	played = true
	running = true
	_time = 0.0
	_next_wave = 0
	_next_wave_at = START_DELAY


func _physics_process(delta: float) -> void:
	if not running:
		return
	_time += delta
	if stage.bee.is_defeated:
		_clear()
		return
	if _next_wave < WAVES.size() and _time >= _next_wave_at:
		_spawn_wave(WAVES[_next_wave])
		_next_wave += 1
		_next_wave_at += WAVE_GAP_SECONDS
	for column in columns.duplicate():
		_update_column(column, delta)
	if _next_wave >= WAVES.size() and columns.is_empty():
		running = false


func _half() -> float:
	return BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(get_viewport()))


func _spawn_wave(lanes: Array) -> void:
	for lane in lanes:
		var x := stage.camera.global_position.x + float(LANES[int(lane)]) * _half()
		_spawn_column(x)


func _spawn_column(x: float) -> void:
	var mark := BeeAttackVisuals.ground_disc(self, Vector3(x, GROUND_Y, 0.0), COLUMN_WIDTH * 1.1, WARNING_COLOR)
	mark.name = "WaterMark"
	var guide := MeshInstance3D.new() # Faint column: where the water will be.
	guide.name = "WaterGuide"
	var guide_mesh := BoxMesh.new()
	guide_mesh.size = Vector3(COLUMN_WIDTH * 0.9, COLUMN_TOP_Y, 0.05)
	guide_mesh.material = BeeAttackVisuals.material(Color(WARNING_COLOR, 0.2))
	guide.mesh = guide_mesh
	guide.top_level = true
	guide.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(guide)
	guide.global_position = Vector3(x, COLUMN_TOP_Y * 0.5 + GROUND_Y, 0.0)
	var shape := BoxShape3D.new()
	shape.size = Vector3(COLUMN_WIDTH, COLUMN_TOP_Y, 1.4)
	var hitbox := BeeAttackVisuals.hazard_area(self, self, DAMAGE, shape)
	hitbox.name = "WaterHitbox"
	hitbox.top_level = true
	hitbox.global_position = Vector3(x, COLUMN_TOP_Y * 0.5 + GROUND_Y, 0.0)
	hitbox.hit_confirmed.connect(func(_hurt, _amount): columns_hit += 1)
	var beam := MeshInstance3D.new()
	beam.name = "WaterColumn"
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = COLUMN_WIDTH * 0.45
	beam_mesh.bottom_radius = COLUMN_WIDTH * 0.5
	beam_mesh.height = COLUMN_TOP_Y
	beam_mesh.radial_segments = 10
	beam_mesh.material = BeeAttackVisuals.material(COLUMN_COLOR)
	beam.mesh = beam_mesh
	beam.top_level = true
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(beam)
	beam.global_position = Vector3(x, COLUMN_TOP_Y * 0.5 + GROUND_Y, 0.0)
	beam.hide()
	columns.append({"x": x, "t": 0.0, "state": &"warning", "mark": mark, "guide": guide, "hitbox": hitbox, "beam": beam})
	columns_spawned += 1
	column_warned.emit(x)


func _update_column(column: Dictionary, delta: float) -> void:
	column["t"] = float(column["t"]) + delta
	var t := float(column["t"])
	var mark := column["mark"] as MeshInstance3D
	var beam := column["beam"] as MeshInstance3D
	var hitbox := column["hitbox"] as DamageHitbox3D
	if column["state"] == &"warning":
		var pulse := 0.85 + 0.25 * sin(t * 14.0)
		mark.scale = Vector3(COLUMN_WIDTH * 1.1 * pulse, 1.0, COLUMN_WIDTH * 1.1 * pulse * 0.6)
		if t >= WARNING_SECONDS:
			min_warning_measured = minf(min_warning_measured, t)
			column["state"] = &"falling"
			column["t"] = 0.0
			hitbox.set_enabled(true)
			beam.show()
			(column["guide"] as Node3D).hide()
			mark.hide()
			column_fell.emit(float(column["x"]))
	elif column["state"] == &"falling":
		beam.scale = Vector3(1.0 + 0.2 * sin(t * 30.0), 1.0, 1.0)
		if t >= ACTIVE_SECONDS:
			hitbox.set_enabled(false)
			for key in ["mark", "guide", "hitbox", "beam"]:
				(column[key] as Node).queue_free()
			columns.erase(column)


func _clear() -> void:
	running = false
	for column in columns:
		for key in ["mark", "guide", "hitbox", "beam"]:
			if is_instance_valid(column[key]):
				(column[key] as Node).queue_free()
	columns.clear()
