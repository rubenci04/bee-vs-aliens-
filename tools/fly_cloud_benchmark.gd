extends SceneTree
## Rendered T6c comparison. Legacy uses the untouched imported swarm, not a rebuilt approximation.
const SIZE := Vector2i(1154,648)
const VISIBLE_FLIES := 60
const WARMUP_SECONDS := 3.0
const SAMPLE_SECONDS := 5.0
var stage: BeeShmupStage
var variant := "legacy"
var actors: Array[Node3D] = []

func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await process_frame

func census(host: Node) -> Dictionary:
	var data := {"nodes":0,"scripts":0,"active_script_callbacks":0,"areas":0,"enabled_shapes":0,"meshes":0,"multimeshes":0,"shadow_meshes":0,"transparent_surfaces":0,"lights":0,"animation_players":0,"fly_roots":0}
	var pending: Array[Node] = [host]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		data.nodes += 1
		if node.get_script() != null:
			data.scripts += 1
			if node.is_processing() or node.is_physics_processing(): data.active_script_callbacks += 1
		if node is Area3D: data.areas += 1
		if node is CollisionShape3D and not node.disabled: data.enabled_shapes += 1
		if node is Light3D: data.lights += 1
		if node is AnimationPlayer: data.animation_players += 1
		if node is MultiMeshInstance3D: data.multimeshes += 1
		if str(node.name).begins_with("Fly_"): data.fly_roots += 1
		if node is MeshInstance3D:
			data.meshes += 1
			if node.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF: data.shadow_meshes += 1
			if node.mesh != null:
				for surface in node.mesh.get_surface_count():
					var mat: Material = node.get_active_material(surface)
					if mat is BaseMaterial3D and mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED: data.transparent_surfaces += 1
					if mat is ShaderMaterial and mat.shader.code.contains("ALPHA ="): data.transparent_surfaces += 1
		for child in node.get_children(): pending.append(child)
	return data

func sample() -> Dictionary:
	var start := Time.get_ticks_usec()
	var previous := start
	var milliseconds: Array[float] = []
	var windows: Array[float] = []
	var window_start := start
	var window_frames := 0
	while Time.get_ticks_usec()-start < SAMPLE_SECONDS*1000000.0:
		await process_frame
		var now := Time.get_ticks_usec()
		milliseconds.append((now-previous)/1000.0)
		window_frames += 1
		if now-window_start >= 1000000:
			windows.append(window_frames*1000000.0/(now-window_start))
			window_start = now
			window_frames = 0
		previous = now
	var elapsed := (Time.get_ticks_usec()-start)/1000000.0
	milliseconds.sort()
	return {"fps":milliseconds.size()/elapsed,"fps_min_1s":windows.min(),"frame_ms_p95":milliseconds[int(milliseconds.size()*0.95)],"frame_ms_p99":milliseconds[int(milliseconds.size()*0.99)],"frames":milliseconds.size(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"objects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)}

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--variant="): variant = arg.get_slice("=",1)
	root.size = SIZE
	Engine.max_fps = 0
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	stage = preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.get_node("Juice").set_process(false)
	stage.get_node("LightProgression").set_process(false)
	stage.distance = 138
	stage._update_camera_and_bounds()
	stage.get_node("LightProgression").apply_distance(138)
	stage.bee.global_position = Vector3(134,3,0)
	stage.bee.set_physics_process(false)
	stage.bee.health.damage_blocked = true
	var empty := await sample()
	var before: Dictionary = {}
	if variant == "legacy":
		for i in 8:
			var cloud := AssetFauna.new()
			cloud.kind = &"fly_cloud"
			stage.get_node("Enemies").add_child(cloud)
			cloud.global_position = Vector3(139+(i%3)*1.1,1.9+(i/3)*1.25,0)
			cloud.activate(stage.bee)
			BeeHostileGlow.ensure.call_deferred(cloud)
			if i == 0: before = census(cloud)
			# Eight native rigs have 64 flies. Hide four in the last rig: exactly 60 visible,
			# with the conservative overhead of four hidden animated rigs disclosed in the report.
			if i == 7:
				for j in range(4,8): cloud.visual.find_child("Fly_%02d"%j,true,false).hide()
			actors.append(cloud)
	else:
		for i in (9 if variant == "encounter" else 1):
			var cloud: Node3D
			if variant == "encounter":
				stage.wave._spawn({"family":"FlyCloud","event":606,"slot":i,"hard":false})
				cloud = stage.wave.active_units.back()
			else:
				cloud = load("res://scenes/levels/asset_fauna/fly_cloud.tscn").instantiate()
				stage.get_node("Enemies").add_child(cloud)
				cloud.call("configure_population",60,60 if variant == "optimized" else 24)
				cloud.call("activate",stage.bee)
			cloud.global_position = Vector3(139+(i%3)*0.8,2+(i/3)*1.1,0)
			actors.append(cloud)
	await create_timer(WARMUP_SECONDS).timeout
	before = census(actors[0])
	var samples: Array[Dictionary] = []
	for i in 3: samples.append(await sample())
	var shown := 216 if variant == "encounter" else (24 if variant == "game" else 60)
	var result := {"variant":variant,"clouds":actors.size(),"visible_flies":shown,"resolution":[SIZE.x,SIZE.y],"renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),"empty":empty,"census":before,"samples":samples,"headless":DisplayServer.get_name()=="headless"}
	var file := FileAccess.open("res://dev/t6c_benchmark_%s.json"%variant,FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://dev/t6c_%s.png"%variant)
	print("T6C_BENCHMARK ",JSON.stringify(result))
	quit()
