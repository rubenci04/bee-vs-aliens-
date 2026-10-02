extends Node3D
## BEE STYLE TEST 01 (dev only). Bee + wasp in 3 styles inside the Visual Target environment,
## seen from camera preset D. Keys: 1/2/3 style, P post-process, C close-up camera.
## Run with "-- --capture" to save screenshots and a frame-time benchmark, then quit.

const BEE_A := preload("res://assets/models/bee_prototype/bee_alien_visual.glb")
const WASP_A := preload("res://scenes/bee_prototype/visuals/wasp_enemy_visual.tscn")
const BEE_B := preload("res://dev/style_test/models/bee_style_b.glb")
const WASP_B := preload("res://dev/style_test/models/wasp_style_b.glb")
const WASP_VISUAL_SCRIPT := preload("res://scripts/bee_prototype/wasp_enemy_visual.gd")
const TOON := preload("res://dev/style_test/toon_body.gdshader")
const OUTLINE := preload("res://dev/style_test/toon_outline.gdshader")
const WING := preload("res://dev/style_test/toon_wing.gdshader")

const CAM_X := 30.0
const BEE_POS := Vector3(28.6, 2.7, 0.0)
const WASP_POS := Vector3(31.5, 3.0, 0.0)
const STYLES := ["A", "B", "C"]
const STYLE_NAMES := {"A": "A actual (low poly facetado)", "B": "B mid poly suave", "C": "C estilizado (toon + rim + contorno)"}

var environment := Environment.new()
var camera := Camera3D.new()
var dof := CameraAttributesPractical.new()
var hud := CanvasLayer.new()
var label := Label.new()
var variants := {} # style -> {root, bee, wasp, bee_wings}
var current := "A"
var post_enabled := false
var close_up := false
var flap_time := 0.0
var freeze_flap := false
var _outline_material := ShaderMaterial.new()


func _ready() -> void:
	_build_world()
	_outline_material.shader = OUTLINE
	for style in STYLES:
		variants[style] = _build_variant(style)
	_build_shots()
	hud.add_child(label)
	label.position = Vector2(16, 12)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	add_child(hud)
	_select("A")
	_set_post(false)
	_set_close(false)
	if "--capture" in OS.get_cmdline_user_args():
		_capture_all.call_deferred()


func _build_world() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.24, 0.55, 0.82)
	sky_material.sky_horizon_color = Color(0.86, 0.88, 0.8)
	sky_material.ground_bottom_color = Color(0.24, 0.31, 0.22)
	sky_material.ground_horizon_color = Color(0.63, 0.72, 0.53)
	var sky := Sky.new()
	sky.sky_material = sky_material
	# Same values as garden_environment in bee_level_01_vertical_slice.tscn.
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(1, 0.91, 0.76)
	environment.ambient_light_energy = 0.7
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_light_color = Color(0.86, 0.87, 0.78)
	environment.fog_density = 0.8
	environment.fog_sky_affect = 0.35
	environment.fog_depth_curve = 1.4
	environment.fog_depth_begin = 14.0
	environment.fog_depth_end = 55.0
	# Post-process candidates (toggled with P).
	environment.ssao_radius = 0.6
	environment.ssao_intensity = 1.2
	environment.ssao_power = 1.5
	environment.glow_intensity = 0.6
	environment.glow_strength = 1.0
	environment.glow_bloom = 0.0
	environment.glow_hdr_threshold = 1.0
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	for level in 7:
		environment.set_glow_level(level, 1.0 if level in [1, 2, 3] else 0.0)
	dof.dof_blur_far_enabled = true
	dof.dof_blur_far_distance = 14.0
	dof.dof_blur_far_transition = 12.0
	dof.dof_blur_amount = 0.06
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -25, 0)
	sun.light_color = Color(1, 0.9, 0.72)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.shadow_blur = 1.6
	sun.directional_shadow_max_distance = 45.0
	add_child(sun)

	add_child(BeeLevel01VisualTarget.new())
	camera.fov = BeeLevel01Framing.CAMERA_FOV
	camera.current = true
	add_child(camera)


func _build_variant(style: String) -> Dictionary:
	var root := Node3D.new()
	root.name = "Style" + style
	add_child(root)
	var bee_pivot := Node3D.new()
	bee_pivot.position = BEE_POS
	bee_pivot.rotation.y = -PI * 0.5 # Faces +X, like BeeVisual with facing_x = 1.
	root.add_child(bee_pivot)
	var bee := (BEE_A if style == "A" else BEE_B).instantiate() as Node3D
	bee_pivot.add_child(bee)

	var wasp_pivot := Node3D.new()
	wasp_pivot.position = WASP_POS
	wasp_pivot.rotation.y = PI * 0.5 # Faces -X, toward the bee.
	root.add_child(wasp_pivot)
	var wasp: Node3D
	if style == "A":
		wasp = WASP_A.instantiate()
		wasp_pivot.add_child(wasp)
	else:
		wasp = Node3D.new()
		wasp.set_script(WASP_VISUAL_SCRIPT) # Same alien palette (red + cyan eyes) as the game.
		var model := WASP_B.instantiate()
		model.name = "Model"
		wasp.add_child(model)
		wasp_pivot.add_child(wasp)
	if style == "C":
		_toonify(bee)
		_toonify(wasp)
	var wings: Array[Node3D] = []
	for wing_name in ["Wing_L", "Wing_R"]:
		wings.append(bee.find_child(wing_name, true, false) as Node3D)
	return {"root": root, "bee": bee, "wasp": wasp, "bee_wings": wings, "bee_rest": wings.map(func(w: Node3D): return w.rotation)}


func _toonify(model: Node3D) -> void:
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.get_surface_override_material(surface) as BaseMaterial3D
			if source == null:
				source = mesh.mesh.surface_get_material(surface) as BaseMaterial3D
			var material := ShaderMaterial.new()
			if source.resource_name == "Wing":
				material.shader = WING
				material.set_shader_parameter("tint", source.albedo_color.lerp(Color.WHITE, 0.35))
			else:
				material.shader = TOON
				material.set_shader_parameter("albedo", source.albedo_color)
				if source.emission_enabled:
					material.set_shader_parameter("emission", source.emission)
					material.set_shader_parameter("emission_energy", source.emission_energy_multiplier)
				material.next_pass = _outline_material
			mesh.set_surface_override_material(surface, material)


## Stand-ins for Bee's energy shots (same mesh and colours as bee_energy_projectile.tscn) to judge glow.
func _build_shots() -> void:
	var outer := StandardMaterial3D.new()
	outer.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outer.albedo_color = Color(0.25, 0.95, 1)
	var core := StandardMaterial3D.new()
	core.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core.albedo_color = Color(0.9, 1, 1)
	for i in 3:
		var shot := Node3D.new()
		shot.position = BEE_POS + Vector3(0.75 + i * 0.6, 0.05, 0)
		add_child(shot)
		for spec in [[0.11, outer], [0.065, core]]:
			var sphere := SphereMesh.new()
			sphere.radius = spec[0]
			sphere.height = spec[0] * 2.0
			sphere.radial_segments = 8
			sphere.rings = 4
			sphere.material = spec[1]
			var instance := MeshInstance3D.new()
			instance.mesh = sphere
			shot.add_child(instance)


func _select(style: String) -> void:
	current = style
	for key in variants:
		(variants[key]["root"] as Node3D).visible = key == style


func _set_post(enabled: bool) -> void:
	post_enabled = enabled
	environment.ssao_enabled = enabled
	environment.glow_enabled = enabled
	camera.attributes = dof if enabled else null


func _set_close(enabled: bool) -> void:
	close_up = enabled
	if enabled:
		camera.position = Vector3((BEE_POS.x + WASP_POS.x) * 0.5, 2.95, 3.4)
		camera.rotation = Vector3.ZERO
	else:
		camera.position = Vector3(CAM_X, BeeLevel01Framing.CAMERA_HEIGHT, BeeLevel01Framing.CAMERA_DISTANCE)
		camera.rotation = Vector3(deg_to_rad(BeeLevel01Framing.CAMERA_PITCH_DEGREES), 0, 0)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_1: _select("A")
		KEY_2: _select("B")
		KEY_3: _select("C")
		KEY_P: _set_post(not post_enabled)
		KEY_C: _set_close(not close_up)


func _process(delta: float) -> void:
	if not freeze_flap:
		flap_time += delta
	var data: Dictionary = variants[current]
	var wings: Array = data["bee_wings"]
	for i in wings.size():
		(wings[i] as Node3D).rotation = (data["bee_rest"][i] as Vector3) + Vector3(0, 0, sin(flap_time * TAU * 16.0) * 0.55 * (-1.0 if i == 0 else 1.0))
	var wasp = data["wasp"] # Untyped: wings/rest_angles live on wasp_enemy_visual.gd.
	wasp.set_process(not freeze_flap)
	if freeze_flap:
		for i in wasp.wings.size():
			wasp.wings[i].rotation = wasp.rest_angles[i] + Vector3(0, 0, 0.3 * (-1.0 if i == 0 else 1.0))
	label.text = "STYLE TEST 01   [1] A   [2] B   [3] C   [P] post-proceso   [C] cámara cercana\n%s   ·   Post: %s   ·   Cámara: %s\nTris abeja %d + avispa %d   ·   FPS %d" % [
		STYLE_NAMES[current], "ON" if post_enabled else "OFF", "cercana" if close_up else "preset D",
		triangles(data["bee"]), triangles(data["wasp"]), Engine.get_frames_per_second()]


static func triangles(node: Node) -> int:
	var total := 0
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			total += (indices.size() if indices.size() > 0 else vertices.size()) / 3
	return total


func _capture_all() -> void:
	hud.visible = false
	freeze_flap = true
	flap_time = 0.3 / 16.0 # Wings frozen mid-stroke so all captures match.
	var out := ProjectSettings.globalize_path("res://dev/style_test/")
	for style in STYLES:
		_select(style)
		print("STYLE_TRIS ", style, " bee=", triangles(variants[style]["bee"]), " wasp=", triangles(variants[style]["wasp"]))
		for close in [false, true]:
			_set_close(close)
			for post in [false, true]:
				_set_post(post)
				for i in 12:
					await get_tree().process_frame
				await RenderingServer.frame_post_draw
				var file := "style_%s_post_%s%s.png" % [style, "on" if post else "off", "_close" if close else ""]
				get_viewport().get_texture().get_image().save_png(out + file)
				print("CAPTURE ", file)
	# Diagnostics: each post effect alone on style C, to see which one the renderer actually applies.
	_select("C")
	for effect in ["ssao", "glow", "dof"]:
		_set_post(false)
		environment.ssao_enabled = effect == "ssao"
		environment.glow_enabled = effect == "glow"
		camera.attributes = dof if effect == "dof" else null
		for i in 12:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out + "diag_C_only_%s.png" % effect)
	_set_post(false)
	_set_close(false)
	freeze_flap = false
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var viewport_rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport_rid, true)
	for stress in [false, true]:
		var extras := _spawn_stress() if stress else []
		for style in STYLES:
			_select(style)
			for post in [false, true]:
				_set_post(post)
				for i in 30:
					await get_tree().process_frame
				var start := Time.get_ticks_usec()
				var gpu := 0.0
				var cpu := 0.0
				for i in 300:
					await get_tree().process_frame
					gpu += RenderingServer.viewport_get_measured_render_time_gpu(viewport_rid)
					cpu += RenderingServer.viewport_get_measured_render_time_cpu(viewport_rid)
				var ms := (Time.get_ticks_usec() - start) / 300.0 / 1000.0
				print("BENCH %s style=%s post=%s frame_ms=%.3f fps=%.0f render_cpu_ms=%.3f render_gpu_ms=%.3f" % [
					"stress24" if stress else "pair", style, "on" if post else "off", ms, 1000.0 / ms, cpu / 300.0, gpu / 300.0])
		for node: Node in extras:
			node.queue_free()
	get_tree().quit()


## 24 extra wasps of the current style family, to see whether B/C cost shows up with a crowd.
func _spawn_stress() -> Array:
	var extras := []
	for style in STYLES:
		var root: Node3D = variants[style]["root"]
		var template: Node3D = variants[style]["wasp"].get_parent()
		for i in 24:
			var copy := template.duplicate() as Node3D
			copy.position = Vector3(CAM_X - 4.5 + (i % 8) * 1.3, 1.0 + (i / 8) * 1.3, -0.5)
			root.add_child(copy)
			if style == "C":
				_toonify(copy) # The copy's wasp script re-applied its standard palette in _ready.
			extras.append(copy)
	return extras
