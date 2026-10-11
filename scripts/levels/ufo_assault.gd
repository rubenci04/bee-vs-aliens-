class_name BeeUfoAssault
extends Node
## Two additional hull attacks share a slot with the existing gun; no simultaneous unmarked charge.
const NOTICE := 0.8
const REST := 8.0
const LASER_SECONDS := 1.2
const GAP_HALF := 0.85
const GAP_DRIFT := 0.45
const RAM_SECONDS := 1.1
const LASER_DAMAGE := 7
const RAM_DAMAGE := 8
var busy := false
var kind := &"sweep"
var clock := REST
var active := false
var volleys := 0
var sweeps := 0
var rams := 0
var gap_centres := Vector2(1.8, 5.1)
var bands: Array[MeshInstance3D] = []
var boxes: Array[DamageHitbox3D] = []
var ram_line: MeshInstance3D
var _from := Vector3.ZERO
var _to := Vector3.ZERO

func _physics_process(delta: float) -> void:
	var boss := get_parent() as UfoBoss01
	if not boss.is_active() or boss.state == UfoBoss01.State.TRANSITION or not boss.is_physics_processing():
		cancel()
		return
	clock -= delta
	if not busy:
		if clock <= 0 and boss.state >= UfoBoss01.State.PHASE_3 and boss._attack_step == &"cooldown" and not boss.crossing and boss.live_mines().is_empty():
			_start()
		return
	if kind == &"sweep":
		_place_bands()
	if clock > 0:
		if active and kind == &"ram":
			boss.global_position = _from.lerp(_to, clampf(1.0 - clock / RAM_SECONDS, 0, 1))
			boxes[0].global_position = boss.global_position
		return
	if not active:
		active = true
		boss.hazards.append({"kind": kind, "telegraph": NOTICE})
		for area in boxes:
			area.set_enabled(true)
		if kind == &"sweep":
			sweeps += 1
			clock = LASER_SECONDS
			for mesh in bands:
				(mesh.mesh.material as StandardMaterial3D).albedo_color.a = 0.7
		else:
			rams += 1
			clock = RAM_SECONDS
			_from = boss.global_position
			_to = Vector3(boss.camera.global_position.x - boss.side * UfoBoss01.ANCHOR_DX, _from.y, 0)
		return
	if kind == &"ram":
		boss.side *= -1.0
		boss.side_switches += 1
		boss.global_position = _to
	cancel()
	clock = REST
	volleys += 1

func _start() -> void:
	var boss := get_parent() as UfoBoss01
	busy = true
	active = false
	kind = &"sweep" if volleys % 2 == 0 else &"ram"
	clock = NOTICE
	boss.attacks_started += 1
	boss.contact.set_enabled(false)
	if kind == &"sweep":
		for i in 3:
			var mesh := BeeAttackVisuals.line(boss, Vector3.ZERO, Vector3.RIGHT, 1.0, Color(0.2, 0.95, 1, 0.2))
			mesh.mesh.material = mesh.mesh.material.duplicate()
			bands.append(mesh)
			var shape := BoxShape3D.new()
			shape.size = Vector3.ONE
			var area := BeeAttackVisuals.hazard_area(boss, boss, LASER_DAMAGE, shape)
			area.top_level = true
			boxes.append(area)
		_place_bands()
	else:
		_from = boss.global_position
		_to = Vector3(boss.camera.global_position.x - boss.side * UfoBoss01.ANCHOR_DX, _from.y, 0)
		ram_line = BeeAttackVisuals.line(boss, _from, _to, 1.5, Color(0.6, 0.25, 1.0, 0.3))
		var shape := BoxShape3D.new()
		shape.size = Vector3(3.8, 1.5, 1.0)
		var area := BeeAttackVisuals.hazard_area(boss, boss, RAM_DAMAGE, shape)
		area.top_level = true
		boxes.append(area)

func _place_bands() -> void:
	var boss := get_parent() as UfoBoss01
	var drift := sin((LASER_SECONDS - clock) * PI) * GAP_DRIFT if active else 0.0
	gap_centres = Vector2(1.8 + drift, 5.1 + drift)
	var lows := [BeeLevel01Framing.bottom_y(), gap_centres.x + GAP_HALF, gap_centres.y + GAP_HALF]
	var highs := [gap_centres.x - GAP_HALF, gap_centres.y - GAP_HALF, BeeLevel01Framing.top_y()]
	var half := BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(get_viewport()))
	for i in bands.size():
		var y := (float(lows[i]) + float(highs[i])) * 0.5
		var height := maxf(0.1, float(highs[i]) - float(lows[i]))
		var left := Vector3(boss.camera.global_position.x - half, y, 0)
		BeeAttackVisuals.place_line(bands[i], left, left + Vector3(half * 2, 0, 0))
		bands[i].scale.y = height
		boxes[i].global_position = left + Vector3(half, 0, 0)
		(boxes[i].get_child(0).shape as BoxShape3D).size = Vector3(half * 2, height, 1.0)

func cancel() -> void:
	for area in boxes:
		area.set_enabled(false)
		area.queue_free()
	boxes.clear()
	for mesh in bands:
		mesh.queue_free()
	bands.clear()
	if is_instance_valid(ram_line):
		ram_line.queue_free()
	ram_line = null
	busy = false
	active = false
