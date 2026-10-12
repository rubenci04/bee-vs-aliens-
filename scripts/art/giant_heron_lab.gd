extends Node3D
## Natural wind demonstration only: no collision or gameplay damage.
const WIND_SPEED := 5.5
const WIND_LIFETIME := 1.4
const WIND_RELEASE_TIME := 0.75
var attack_time := -1.0
var released := false
var gusts: Array[MeshInstance3D] = []
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var clip := ""
	match event.keycode:
		KEY_1: clip = "idle"
		KEY_2: clip = "walk"
		KEY_3: clip = "fly"
		KEY_4: clip = "wind_attack"
		KEY_5: clip = "peck_attack"
		KEY_L: $Controlled.controlled = not $Controlled.controlled
	if clip != "":
		$Controlled.play_clip(clip)
		attack_time = 0.0 if clip == "wind_attack" else -1.0
		released = false
func _process(delta: float) -> void:
	if attack_time >= 0:
		attack_time += delta
		if not released and attack_time >= WIND_RELEASE_TIME:
			for side in ["L", "R"]:
				spawn_wind($Controlled.find_child("WindAnchor_" + side,true,false).global_position)
			released = true
	for gust in gusts.duplicate():
		gust.position.x -= WIND_SPEED * delta
		var age := float(gust.get_meta("age")) + delta
		gust.set_meta("age", age)
		if age > WIND_LIFETIME:
			gusts.erase(gust)
			gust.queue_free()
func spawn_wind(origin: Vector3) -> void:
	for trail in range(3):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var radius := 0.40 + trail * 0.15
		for i in range(12):
			var a := (-0.8 + i / 12.0 * 1.6) * PI
			var b := (-0.8 + (i+1) / 12.0 * 1.6) * PI
			var p := Vector3(0,cos(a)*radius,sin(a)*radius)
			var q := Vector3(0,cos(b)*radius,sin(b)*radius)
			var p2 := p * 1.07
			var q2 := q * 1.07
			for v in [p,q,p2,q,q2,p2]:
				st.set_normal(Vector3.LEFT)
				st.add_vertex(v)
		var gust := MeshInstance3D.new()
		gust.mesh = st.commit()
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.89,0.87,0.75)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		gust.material_override = mat
		add_child(gust)
		gust.global_position = origin + Vector3(-trail*.28,0,0)
		gust.set_meta("age",0.0)
		gusts.append(gust)
