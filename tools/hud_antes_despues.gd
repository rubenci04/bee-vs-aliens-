extends SceneTree
const SIZE := Vector2i(1154,648)
const CAPTION_HEIGHT := 36
const CAPTIONS := ["Inicio · cambio de dispositivo", "Checkpoint 2", "Enjambre · ocho liberaciones", "Tarántula · instrucción del implante"]
var stage: BeeShmupStage
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for tick in count: await process_frame
func caption(text: String) -> Image:
	var view := SubViewport.new()
	view.size = Vector2i(SIZE.x, CAPTION_HEIGHT)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var label := Label.new()
	view.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	await frames(2)
	await RenderingServer.frame_post_draw
	var result := view.get_texture().get_image()
	result.convert(Image.FORMAT_RGBA8)
	view.queue_free()
	return result
func run() -> void:
	root.size = SIZE
	var after := "--after" in OS.get_cmdline_user_args()
	var montage := Image.create(SIZE.x*2,(SIZE.y+CAPTION_HEIGHT)*4,false,Image.FORMAT_RGBA8)
	for sample in 4:
		stage = preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
		root.add_child(stage)
		current_scene = stage
		await frames(5)
		stage.set_physics_process(false)
		stage.wave.set_physics_process(false)
		stage.bee.set_physics_process(false)
		stage.get_node("CheckpointQoL").set_process(false)
		stage.bee.health.damage_blocked = true
		BeeGameSettings.last_input_joypad = true
		var banner := stage.get_node_or_null("HUDNotices")
		if after and banner != null:
			banner.pending.clear()
			banner.left = 0
			banner.active_kind = ""
		root.get_node("InputDevices").notice_left = 0
		if sample == 0:
			var devices := root.get_node("InputDevices")
			if devices.has_method("show_device_notice"):
				devices.show_device_notice("Mando detectado: XInput Controller")
			else:
				devices.notice.text = "Mando detectado: XInput Controller"
				devices.notice_left = 3
		elif sample == 1:
			stage.distance = 281
			stage._update_camera_and_bounds()
			stage.bee.global_position = Vector3(281,5.4,0)
			stage.get_node("CheckpointQoL").activate_second_checkpoint()
		elif sample == 2:
			stage.distance = 110
			stage._update_camera_and_bounds()
			stage.bee.global_position = Vector3(107,4,0)
			var swarm: Array[Node3D] = []
			for i in 8:
				stage.wave._spawn({"family": "FlyCommon", "slot": 0, "event": 0, "hard": false, "y": 4.0})
				var fly := stage.wave.active_units.back() as Node3D
				fly.global_position = Vector3(109+float(i%4)*1.4,2.5+float(i/4)*1.4,0)
				fly.set_physics_process(false)
				swarm.append(fly)
			banner = stage.get_node_or_null("HUDNotices")
			if after and banner != null:
				banner.pending.clear()
				banner.left = 0
				banner.active_kind = ""
			for fly in swarm:
				(fly.get_node("HealthComponent") as HealthComponent).take_damage(99999)
		else:
			stage.distance = 310
			stage._update_camera_and_bounds()
			stage.bee.global_position = Vector3(307,4,0)
			var boss := preload("res://scenes/levels/tarantula_boss_01.tscn").instantiate() as TarantulaBoss01
			stage.add_child(boss)
			boss.begin(stage.camera,stage.bee)
			boss.global_position = Vector3(313,-.1,0)
			boss._apply_pose()
			boss.set_physics_process(false)
			boss._bar_layer.show()
			boss._boss_hint("PATAS BLINDADAS: APUNTÁ AL IMPLANTE")
		await frames(5)
		await RenderingServer.frame_post_draw
		var screenshot := root.get_texture().get_image()
		screenshot.convert(Image.FORMAT_RGBA8)
		if not after:
			screenshot.save_png("res://dev/t1b_before_%d.png" % sample)
		else:
			var before := Image.load_from_file("res://dev/t1b_before_%d.png" % sample)
			var y := sample * (SIZE.y + CAPTION_HEIGHT)
			montage.blit_rect(before,Rect2i(Vector2i.ZERO,SIZE),Vector2i(0,y+CAPTION_HEIGHT))
			montage.blit_rect(screenshot,Rect2i(Vector2i.ZERO,SIZE),Vector2i(SIZE.x,y+CAPTION_HEIGHT))
			var left_caption := await caption("ANTES · " + CAPTIONS[sample])
			var right_caption := await caption("AHORA · " + CAPTIONS[sample])
			montage.blit_rect(left_caption,Rect2i(Vector2i.ZERO,Vector2i(SIZE.x,CAPTION_HEIGHT)),Vector2i(0,y))
			montage.blit_rect(right_caption,Rect2i(Vector2i.ZERO,Vector2i(SIZE.x,CAPTION_HEIGHT)),Vector2i(SIZE.x,y))
		stage.free()
		await frames(2)
	if after:
		assert(montage.save_png("res://docs/hud_antes_despues.png") == OK)
	print("HUD_CAPTURE_OK after=",after)
	quit()
