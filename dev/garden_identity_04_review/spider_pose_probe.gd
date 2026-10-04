extends SceneTree
## DEV ONLY (GARDEN IDENTITY 04). Renders the CC0 Quaternius Spider (library copy, loaded at runtime) in candidate
## orientations with Style C, to choose how the hanging spider is presented. Writes spider_pose_probe.png here.
##   godot --path . --resolution 640x360 --script res://dev/garden_identity_04_review/spider_pose_probe.gd
const SPIDER := "D:/proyectos/V_Asset_Library/01_Extracted/quaternius/Easy Animated Enemy Pack - Jan 2019-20260929T144515Z-1-001/Easy Animated Enemy Pack - Jan 2019/FBX/Spider.fbx"
const POSES := [["side yaw0", Vector3(0, 0, 0), "Idle"], ["side yaw90", Vector3(0, 90, 0), "Idle"], ["hang head-down", Vector3(-90, 90, 0), "Idle"],
	["hang back-to-cam", Vector3(-90, 0, 0), "Idle"], ["hang attack", Vector3(-90, 90, 0), "Attack"], ["front yaw-90", Vector3(0, -90, 0), "Walk"]]

func _initialize() -> void:
	call_deferred("run")

func load_model() -> Node3D:
	var state := FBXState.new()
	var doc := FBXDocument.new()
	doc.append_from_file(SPIDER, state)
	return doc.generate_scene(state) as Node3D

func run() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1800, 700)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.78, 0.84, 0.72)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1, 0.95, 0.85)
	env.environment.ambient_light_energy = 0.6
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -25, 0)
	vp.add_child(sun)
	for i in POSES.size():
		var m := load_model()
		vp.add_child(m)
		m.scale = Vector3.ONE * 0.3
		m.rotation_degrees = POSES[i][1]
		m.position = Vector3((i - 2.5) * 2.4, 0, 0)
		for p: AnimationPlayer in m.find_children("*", "AnimationPlayer", true, false):
			for c in p.get_animation_list():
				if str(c).contains(POSES[i][2]):
					p.play(c); p.seek(p.get_animation(c).length * 0.4, true); p.pause()
		BeeToonStyle.apply(m, true, BeeToonStyle.OUTLINE_ACTOR)
		var l := Label3D.new()
		l.text = POSES[i][0]
		l.font_size = 48; l.pixel_size = 0.006; l.modulate = Color.BLACK
		l.position = Vector3((i - 2.5) * 2.4, -1.6, 1)
		vp.add_child(l)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0, 14)
	cam.fov = 40
	vp.add_child(cam)
	cam.make_current()
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("res://dev/garden_identity_04_review/spider_pose_probe.png")
	quit(0)
