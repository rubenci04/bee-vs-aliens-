extends Node3D
const PLASMA_SPEED := 7.0
const PLASMA_LIFETIME := 1.2
const SHOT_TIMES := [0.75, 1.25]
var attack_time := -1.0
var shot_index := 0
var shots: Array[MeshInstance3D] = []
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var clip := ""
	match event.keycode:
		KEY_1: clip = "idle"
		KEY_2: clip = "hop"
		KEY_3: clip = "plasma_fire"
		KEY_4: clip = "tongue_attack"
		KEY_L: $Controlled.controlled = not $Controlled.controlled
	if clip != "":
		$Controlled.play_clip(clip)
		attack_time = 0.0 if clip == "plasma_fire" else -1.0
		shot_index = 0
func _process(delta: float) -> void:
	if attack_time >= 0:
		attack_time += delta
		if shot_index < SHOT_TIMES.size() and attack_time >= SHOT_TIMES[shot_index]:
			if $Controlled.controlled:
				for label in ["L", "R"]:
					_spawn_plasma($Controlled.find_child("Muzzle_" + label, true, false))
			shot_index += 1
	for shot in shots.duplicate():
		shot.position.x -= PLASMA_SPEED * delta
		var age: float = float(shot.get_meta("age")) + delta
		shot.set_meta("age", age)
		if age >= PLASMA_LIFETIME:
			shots.erase(shot)
			shot.queue_free()
func _spawn_plasma(anchor: Node3D) -> void:
	var shot := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.14
	mesh.height = 0.28
	mesh.radial_segments = 12
	mesh.rings = 6
	shot.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.80, 0.88)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.65
	shot.material_override = mat
	add_child(shot)
	shot.global_position = anchor.global_position
	shot.set_meta("age", 0.0)
	BeeToonStyle.apply(shot, true, BeeToonStyle.OUTLINE_PROP)
	shots.append(shot)
