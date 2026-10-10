extends Node3D
## DEV ONLY SPIKE (rama camera-fp-spike). NOT part of Level 01 and it touches none of its scripts.
## Same flight seen three ways: 1 = A lateral (preset D, reference), 2 = B chase camera behind Bee (rails, Star Fox),
## 3 = C first person from Bee's eyes with reticle. WASD / arrows move, X fires (auto-aim), 1/2/3 switch view.
## Enemies are the real Level 01 visuals (wasp, probe, eye drone, style C) with their AI switched off; behaviour is a
## handful of lines in this file. Every enemy lives in LOGICAL coordinates (d = distance ahead, u = lateral, v = height)
## and is mapped to the world per view: A flattens u to 0 (the real game plays on the z=0 plane).

enum View { A, B, C }

const BEE := preload("res://scenes/bee_prototype/bee_player.tscn")
const WASP := preload("res://scenes/bee_prototype/wasp_enemy.tscn")
const PROBE := preload("res://scenes/bee_prototype/alien_probe_ranged.tscn")
const EYE := preload("res://scenes/bee_prototype/eye_drone_enemy.tscn")

const ADVANCE_SPEED := 6.0
const WRAP_AT := 300.0
const LANE_U := 4.2 # Bee lateral range in B / C.
const LANE_V := Vector2(0.9, 6.4)
const DEPTH_SCALE := {View.A: 0.3, View.B: 1.0, View.C: 1.0} # A keeps the real game's ~10 m of visible depth.
const SPAWN_D := 34.0
const PERIOD := 11.0
# [time in period, kind, lateral u, height v]
const SPAWNS := [
	[1.0, "wasp", -3.0, 2.2], [2.2, "probe", 2.8, 4.8], [3.4, "eye", -0.5, 3.4], [4.6, "wasp", 3.4, 5.4],
	[5.6, "eye", -3.0, 5.6], [6.8, "probe", 0.5, 1.8], [8.0, "wasp", -1.5, 3.8], [9.2, "wasp", 2.0, 2.6],
]
const KIND := {
	"wasp": {"scene": WASP, "hp": 30, "radius": 0.85},
	"probe": {"scene": PROBE, "hp": 20, "radius": 0.85},
	"eye": {"scene": EYE, "hp": 18, "radius": 0.85},
}

var view := View.A
var autoplay := true # The capture script turns it off and calls step() itself.
var scripted_input: Variant = null # Vector2 in capture mode.
var force_fire := false
var rig_x := 20.0
var clock := 0.0
var lat := 0.0
var h := 3.0
var lat_vel := 0.0
var h_vel := 0.0
var hp := 100
var kills := 0
var bee: BeePlayer
var cam: Camera3D
var enemies: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var orbs: Array[Dictionary] = []
var target: Dictionary = {}
var _fire_cd := 0.0
var _spawn_index := 0
var _spawn_cycle := 0
var _roll := 0.0
var _pitch := 0.0
var _cam_pos := Vector3.ZERO
var _cam_look := Vector3.ZERO
var _shot_mesh: Mesh
var _shot_mat: StandardMaterial3D
var _orb_mesh: Mesh
var _label: Label
var _hint: Label
var _overlay: Control


func _ready() -> void:
	BeeLevel01Framing.use_preset(&"D")
	_build_environment()
	var decoration := BeeLevel01VisualTarget.new() # Same decoration script as Level 01 / Visual Target, untouched.
	decoration.name = "VisualTarget01"
	decoration.position = Vector3(0, 0, -3.5) # Pushes the stems out of the B / C flight lane.
	add_child(decoration)
	var mirror := BeeLevel01VisualTarget.new() # Second copy rotated 180 deg so both flanks have stems.
	mirror.name = "VisualTarget01Mirror"
	mirror.position = Vector3(380.0, 0.015, 3.5)
	mirror.rotation.y = PI
	add_child(mirror)
	bee = BEE.instantiate() as BeePlayer
	add_child(bee)
	bee.set_physics_process(false)
	cam = Camera3D.new()
	cam.far = 160.0
	add_child(cam)
	cam.make_current()
	_shot_mesh = CapsuleMesh.new()
	(_shot_mesh as CapsuleMesh).radius = 0.07
	(_shot_mesh as CapsuleMesh).height = 0.7
	_shot_mat = StandardMaterial3D.new()
	_shot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shot_mat.albedo_color = Color(0.3, 1.0, 1.0)
	_shot_mat.emission_enabled = true
	_shot_mat.emission = Color(0.1, 0.9, 1.0)
	_shot_mat.emission_energy_multiplier = 2.5
	_shot_mesh.material = _shot_mat
	_orb_mesh = SphereMesh.new()
	(_orb_mesh as SphereMesh).radius = 0.22
	(_orb_mesh as SphereMesh).height = 0.44
	var orb_mat := StandardMaterial3D.new()
	orb_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	orb_mat.albedo_color = Color(1.0, 0.35, 0.9)
	orb_mat.emission_enabled = true
	orb_mat.emission = Color(1.0, 0.2, 0.9)
	_orb_mesh.material = orb_mat
	_build_hud()
	set_view(View.A)


func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.24, 0.55, 0.82)
	sky_mat.sky_horizon_color = Color(0.86, 0.88, 0.8)
	sky_mat.ground_horizon_color = Color(0.63, 0.72, 0.53)
	sky_mat.ground_bottom_color = Color(0.24, 0.31, 0.22)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.91, 0.76)
	env.ambient_light_energy = 0.7
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.86, 0.87, 0.78)
	env.fog_density = 0.8
	env.fog_sky_affect = 0.35
	env.fog_depth_curve = 1.4
	env.fog_depth_begin = 14.0
	env.fog_depth_end = 55.0
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_hdr_threshold = 1.0
	env.set("glow_levels/2", 1.0)
	env.set("glow_levels/3", 1.0)
	env.set("glow_levels/4", 1.0)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.9, 0.72)
	sun.light_energy = 1.25
	sun.rotation_degrees = Vector3(-40, -25, 0)
	sun.shadow_enabled = true
	sun.shadow_blur = 1.6
	sun.directional_shadow_max_distance = 45.0
	add_child(sun)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	layer.add_child(_overlay)
	_label = Label.new()
	_label.position = Vector2(16, 12)
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	layer.add_child(_label)
	_hint = Label.new()
	_hint.text = "1 / 2 / 3 = vista A lateral / B persecución / C primera persona   ·   WASD / flechas mover   ·   X disparar (auto-apuntado)"
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size", 5)
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hint.position = Vector2(16, -30)
	layer.add_child(_hint)


func set_view(new_view: View) -> void:
	view = new_view
	_clear_projectiles()
	bee.get_node("VisualRoot").visible = view != View.C
	cam.fov = [BeeLevel01Framing.CAMERA_FOV, 62.0, 78.0][view]
	_snap_camera()


func _clear_projectiles() -> void:
	for s in shots:
		s["node"].queue_free()
	shots.clear()
	for o in orbs:
		o["node"].queue_free()
	orbs.clear()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_1: set_view(View.A)
		KEY_2: set_view(View.B)
		KEY_3: set_view(View.C)


func _physics_process(delta: float) -> void:
	if autoplay:
		step(delta)


## One simulation tick. The capture script calls it directly with a fixed delta.
func step(delta: float) -> void:
	clock += delta
	rig_x += ADVANCE_SPEED * delta
	if rig_x > WRAP_AT:
		var shift := -(WRAP_AT - 20.0)
		rig_x += shift
		for s in shots:
			s["pos"].x += shift
		for o in orbs:
			o["pos"].x += shift
	_move_bee(delta)
	_spawn(delta)
	_update_enemies(delta)
	_update_fire(delta)
	_update_projectiles(delta)
	_apply_transforms(delta)
	_label.text = "VISTA %s   ·   HP %d   ·   derribados %d" % [["A  LATERAL (preset D)", "B  PERSECUCIÓN", "C  PRIMERA PERSONA"][view], hp, kills]
	_overlay.queue_redraw()


func _move_bee(delta: float) -> void:
	var input: Vector2 = scripted_input if scripted_input != null else Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	lat_vel = move_toward(lat_vel, input.x * 7.0, 32.0 * delta)
	h_vel = move_toward(h_vel, input.y * 6.0, 32.0 * delta)
	lat = clampf(lat + lat_vel * delta, -LANE_U, LANE_U)
	h = clampf(h + h_vel * delta, LANE_V.x, LANE_V.y)


func _scale() -> float:
	return DEPTH_SCALE[view]


## Bee in the world. A: lateral input is the horizontal screen axis (offset along the scroll). B / C: it is Z.
func bee_world() -> Vector3:
	if view == View.A:
		return Vector3(rig_x + lerpf(-4.5, 2.0, (lat + LANE_U) / (2.0 * LANE_U)), h, 0.0)
	return Vector3(rig_x, h, lat)


func enemy_world(e: Dictionary) -> Vector3:
	return Vector3(rig_x + float(e["d"]) * _scale(), float(e["v"]), 0.0 if view == View.A else float(e["u"]))


func _spawn(_delta: float) -> void:
	while true:
		var spec: Array = SPAWNS[_spawn_index]
		if clock < float(_spawn_cycle) * PERIOD + float(spec[0]):
			return
		_spawn_enemy(str(spec[1]), float(spec[2]), float(spec[3]))
		_spawn_index += 1
		if _spawn_index >= SPAWNS.size():
			_spawn_index = 0
			_spawn_cycle += 1


func _spawn_enemy(kind: String, u: float, v: float) -> void:
	var data: Dictionary = KIND[kind]
	var node := (data["scene"] as PackedScene).instantiate() as Node3D
	add_child(node)
	node.call("activate", bee)
	node.set_physics_process(false)
	enemies.append({"node": node, "kind": kind, "d": SPAWN_D, "u": u, "v": v, "hp": data["hp"], "age": 0.0, "shoot": 1.2, "u0": u, "v0": v, "dead": false})


func _update_enemies(delta: float) -> void:
	var bee_d := (bee_world().x - rig_x) / _scale()
	for e in enemies:
		e["age"] += delta
		var age: float = e["age"]
		match e["kind"]:
			"wasp":
				# Closes in, then dives onto Bee's line; passes by if it misses.
				var closing := 12.0 + (6.0 if float(e["d"]) < bee_d + 14.0 else 0.0)
				e["d"] -= closing * delta
				if float(e["d"]) < bee_d + 16.0:
					e["u"] = move_toward(float(e["u"]), lat, 3.2 * delta)
					e["v"] = move_toward(float(e["v"]), h, 2.6 * delta)
				else:
					e["v"] = float(e["v0"]) + sin(age * 3.0) * 0.5
			_:
				var hold := 9.0 if e["kind"] == "probe" else 12.0
				if age < 11.0:
					e["d"] = move_toward(float(e["d"]), hold, (ADVANCE_SPEED + 8.0) * delta)
				else:
					e["d"] -= 10.0 * delta # Leaves.
				e["u"] = float(e["u0"]) + sin(age * 0.8) * 1.6
				e["v"] = clampf(float(e["v0"]) + sin(age * 1.1) * 0.9, 1.0, 6.2)
				e["shoot"] -= delta
				if float(e["shoot"]) <= 0.0 and float(e["d"]) < hold + 3.0 and age < 11.0:
					e["shoot"] = 2.0 if e["kind"] == "probe" else 2.6
					_enemy_fire(e)
	for e in enemies.duplicate():
		var world := enemy_world(e)
		var node := e["node"] as Node3D
		node.global_position = world
		if bool(e["dead"]) or world.x < rig_x - 8.0:
			enemies.erase(e)
			node.queue_free()
			continue
		if not bool(e["dead"]) and str(e["kind"]) == "wasp" and world.distance_to(bee_world()) < 0.9:
			hp = maxi(0, hp - 10)
			e["dead"] = true


func _enemy_fire(e: Dictionary) -> void:
	var orb := MeshInstance3D.new()
	orb.mesh = _orb_mesh
	add_child(orb)
	var origin := enemy_world(e)
	var direction := (bee_world() - origin).normalized()
	orbs.append({"node": orb, "pos": origin, "vel": direction * 10.0, "life": 4.0})
	orb.global_position = origin


func _nearest_target() -> Dictionary:
	var origin := bee_world()
	var best: Dictionary = {}
	var best_score := INF
	var max_range := 14.0 if view == View.A else 40.0
	var cone := cos(deg_to_rad(80.0 if view == View.A else 38.0))
	for e in enemies:
		var to := enemy_world(e) - origin
		var dist := to.length()
		if dist > max_range or dist < 0.5 or to.normalized().x < cone or bool(e["dead"]):
			continue
		var score := dist * (1.0 + (to.normalized() - Vector3.RIGHT).length())
		if score < best_score:
			best_score = score
			best = e
	return best


func _update_fire(delta: float) -> void:
	_fire_cd -= delta
	target = _nearest_target()
	if (force_fire or Input.is_action_pressed("throw_orange")) and _fire_cd <= 0.0:
		_fire_cd = 0.2
		var origin := bee_world() + Vector3(0.5, 0.0, 0.0)
		var direction := Vector3.RIGHT
		if not target.is_empty():
			direction = (enemy_world(target) - origin).normalized()
		var shot := MeshInstance3D.new()
		shot.mesh = _shot_mesh
		add_child(shot)
		shots.append({"node": shot, "pos": origin, "vel": direction * 32.0, "life": 1.4})


func _update_projectiles(delta: float) -> void:
	for s in shots.duplicate():
		s["pos"] += s["vel"] * delta
		s["life"] -= delta
		var done: bool = s["life"] <= 0.0
		for e in enemies:
			if not bool(e["dead"]) and (s["pos"] as Vector3).distance_to(enemy_world(e)) < float(KIND[e["kind"]]["radius"]):
				e["hp"] -= 10
				done = true
				if int(e["hp"]) <= 0:
					e["dead"] = true
					kills += 1
					_burst(enemy_world(e))
				break
		if done:
			shots.erase(s)
			(s["node"] as Node3D).queue_free()
	for o in orbs.duplicate():
		o["pos"] += o["vel"] * delta
		o["life"] -= delta
		var hit: bool = (o["pos"] as Vector3).distance_to(bee_world()) < 0.55
		if hit:
			hp = maxi(0, hp - 5)
		if hit or o["life"] <= 0.0:
			orbs.erase(o)
			(o["node"] as Node3D).queue_free()


func _burst(at: Vector3) -> void:
	var flash := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.28
	mesh.height = 0.56
	var flash_mat := StandardMaterial3D.new()
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash_mat.albedo_color = Color(1.0, 0.85, 0.3, 0.9)
	mesh.material = flash_mat
	flash.mesh = mesh
	add_child(flash)
	flash.global_position = at
	var tween := create_tween()
	tween.tween_property(flash, "scale", Vector3.ONE * 1.8, 0.22)
	tween.parallel().tween_property(flash_mat, "albedo_color:a", 0.0, 0.22)
	tween.tween_callback(flash.queue_free)


func _apply_transforms(delta: float) -> void:
	for s in shots:
		var node := s["node"] as Node3D
		node.global_position = s["pos"]
		var dir: Vector3 = (s["vel"] as Vector3).normalized()
		node.basis = Basis.looking_at(dir, Vector3.UP) * Basis.from_euler(Vector3(PI * 0.5, 0, 0))
	for o in orbs:
		(o["node"] as Node3D).global_position = o["pos"]
	bee.global_position = bee_world()
	if view == View.A:
		bee.rotation = Vector3.ZERO
	else:
		bee.rotation = Vector3(clampf(lat_vel * 0.05, -0.4, 0.4), 0.0, clampf(h_vel * 0.035, -0.25, 0.25))
	_update_camera(delta)


func _camera_targets() -> Array:
	var b := bee_world()
	match view:
		View.A:
			return [Vector3(rig_x, BeeLevel01Framing.CAMERA_HEIGHT, BeeLevel01Framing.CAMERA_DISTANCE), Vector3.ZERO]
		View.B:
			return [Vector3(b.x - 5.2, b.y * 0.55 + 1.4, lat * 0.7), Vector3(b.x + 18.0, b.y * 0.7 + 0.9, lat * 0.4)]
		_:
			return [b + Vector3(0.45, 0.05, 0.0), Vector3.ZERO]


func _snap_camera() -> void:
	var t := _camera_targets()
	_cam_pos = t[0]
	_cam_look = t[1]
	_place_camera(0.0)


func _update_camera(delta: float) -> void:
	var t := _camera_targets()
	var k := 1.0 if view != View.B else 1.0 - exp(-6.0 * delta)
	_cam_pos = _cam_pos.lerp(t[0], k)
	_cam_look = _cam_look.lerp(t[1], k)
	_place_camera(delta)


func _place_camera(delta: float) -> void:
	match view:
		View.A:
			cam.global_position = _cam_pos
			cam.rotation = Vector3(deg_to_rad(BeeLevel01Framing.CAMERA_PITCH_DEGREES), 0.0, 0.0)
		View.B:
			cam.global_position = _cam_pos
			cam.look_at(_cam_look, Vector3.UP)
		_:
			# First person: slight bank into the turn, nose follows climb / dive, tiny idle bob.
			var smooth := 1.0 - exp(-9.0 * delta)
			_roll = lerpf(_roll, -lat_vel * 0.012 + sin(clock * 1.7) * 0.006, smooth)
			_pitch = lerpf(_pitch, h_vel * 0.009, smooth)
			cam.global_position = _cam_pos + Vector3(0, sin(clock * 2.3) * 0.015, 0)
			cam.basis = Basis.from_euler(Vector3(_pitch, -PI * 0.5, _roll))


func _draw_overlay() -> void:
	var size := _overlay.size
	var cyan := Color(0.2, 1.0, 1.0, 0.95)
	if view == View.C:
		var c := size * 0.5
		_overlay.draw_arc(c, 18.0, 0, TAU, 32, cyan, 2.0)
		for dir in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			_overlay.draw_line(c + dir * 24.0, c + dir * 38.0, cyan, 2.0)
		_overlay.draw_circle(c, 2.0, cyan)
	elif view == View.B:
		var ahead := cam.unproject_position(bee_world() + Vector3(24.0, 0.0, 0.0))
		_overlay.draw_arc(ahead, 15.0, 0, TAU, 32, cyan, 2.0)
		_overlay.draw_line(ahead + Vector2(-24, 0), ahead + Vector2(-9, 0), cyan, 2.0)
		_overlay.draw_line(ahead + Vector2(24, 0), ahead + Vector2(9, 0), cyan, 2.0)
	if not target.is_empty() and not cam.is_position_behind(enemy_world(target)):
		var p := cam.unproject_position(enemy_world(target))
		var r := 26.0 if view == View.A else 22.0
		var lock := Color(1.0, 0.85, 0.2, 0.95)
		for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var q: Vector2 = p + corner * r
			_overlay.draw_line(q, q - Vector2(corner.x * 9.0, 0), lock, 2.5)
			_overlay.draw_line(q, q - Vector2(0, corner.y * 9.0), lock, 2.5)
