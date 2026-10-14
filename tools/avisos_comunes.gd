extends SceneTree
## Real enemy models and warning methods, paused at their anticipation pose.
const CUE := preload("res://scripts/vfx/bee_common_attack_cue.gd")
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const SIZE := Vector2i(1154,648)
const CELL := Vector2i(577,324)
const CASES := ["Ant", "FlyCommon", "FlyGreen", "FlyCloud", "Wasp", "Ladybird", "Snail", "WormB", "StagBeetle", "Spider", "MushroomCannon", "WormA/erupción", "WormA/láser", "WormA/salto", "Mosquito", "WaveDragonfly", "Moth", "AlienFighter", "SeedCarrier", "Speeder", "EyeDrone", "Probe", "Turtle", "Swarm", "Turret", "Walker", "Dragonfly", "Nymph", "Perch", "Strider", "Arañita auxiliar", "OrganicAlien"]
var stage: BeeShmupStage
var caption: Label
var actors: Array[Node3D] = []
var extras: Array[Node] = []
var before := false
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for tick in count: await process_frame
func clear() -> void:
	for actor in actors:
		if is_instance_valid(actor): actor.queue_free()
	actors.clear()
	for node in extras:
		if is_instance_valid(node): node.queue_free()
	extras.clear()
	stage.wave.active_units.clear()
	stage.wave.swarm_units.clear()
	BeeAttackTokens.reset()
	await frames(3)
func prepare(which: String, x := 111.0, y := 3.0) -> void:
	var family := which.get_slice("/",0)
	var previous := stage.get_children()
	var enemy: Node3D
	if family in ["Nymph", "Perch", "Strider"]:
		enemy = load("res://scenes/levels/asset_fauna/%s.tscn" % family.to_lower()).instantiate()
		stage.add_child(enemy)
		enemy.activate(stage.bee)
	elif family == "Arañita auxiliar":
		enemy = TarantulaDropSpider.new()
		stage.add_child(enemy)
		enemy.setup(stage,x,3,6)
	else:
		stage.wave._spawn({"family":family,"slot":0,"event":0,"hard":false,"y":y})
		enemy = (stage.wave.swarm_units.back() if family == "Swarm" else stage.wave.active_units.back()) as Node3D
	actors.append(enemy)
	await frames(2)
	var ground := family in ["Turret", "Walker", "Turtle"] or (enemy.has_method("is_ground") and bool(enemy.call("is_ground")))
	enemy.global_position = Vector3(x, 0 if ground else y, 0)
	enemy.set_physics_process(false)
	for child in enemy.find_children("*", "Node", true, false):
		child.set_physics_process(false)
	var pose: Node3D
	var species := StringName(family)
	if enemy is AssetFauna:
		pose = enemy.visual
		if family == "WormA":
			if which.ends_with("erupción"):
				enemy._worm._begin_mark()
			elif which.ends_with("láser"):
				enemy.rig.position.y = 0
				enemy._worm._stand(1)
				enemy._worm._begin_peek()
			else:
				enemy.rig.position.y = 0
				enemy._worm._land = Vector3(113,0,0)
				enemy._worm._begin_crouch()
			species = &"worm"
		else:
			enemy.state = AssetFauna.State.IDLE
			enemy._start_telegraph()
			if before:
				enemy._telegraph(.25)
	elif enemy is WaspEnemy:
		pose = enemy.visual_root
		enemy._begin_windup()
		enemy._lock_overload_line()
		species = &"wasp"
	elif enemy is ControlledSpider:
		pose = enemy.visual_root
		enemy.global_position.y = 5.5
		enemy._try_telegraph()
		enemy._update_telegraph(5.5)
		species = &"spider"
	elif enemy is BeeGardenTurtle:
		pose = enemy.body
		enemy._begin_roll_warn()
	elif enemy is EyeDroneEnemy:
		pose = enemy.visual_root
		enemy._begin_laser_charge()
	elif enemy is SpeederEnemy:
		pose = enemy.visual_root
		enemy.ram_mode = true
		enemy._begin_telegraph()
	elif enemy is AlienProbeRanged:
		pose = enemy.visual_root
		enemy._begin_windup()
	elif enemy is TarantulaDropSpider:
		enemy.global_position.y = 6
		pose = enemy._model
		species = &"spider"
	elif enemy is OrganicAlienEnemy:
		enemy._begin_windup() # Already a local core cue, retained in the game.
	if enemy is PopcornDrone:
		pose = enemy.visual_root
		enemy._kz_vel = Vector2(-8,0)
		enemy._show_kamikaze_line()
	elif enemy is GroundTurretEnemy:
		pose = enemy.visual_root
		enemy._mark_mortar()
	elif enemy is GroundWalkerEnemy:
		pose = enemy.visual_root
		enemy.aim_charge.show()
		if not before: CUE.suppress(enemy.aim_charge)
	elif enemy is ControlledDragonfly:
		pose = enemy.visual_root.get_node("Body")
		enemy.state = ControlledDragonfly.State.TELEGRAPH
		enemy._lock_pass()
	if not before and pose != null:
		stage.get_node("LiveReadability")._collect_actors()
		enemy.set_meta("shot_warning_token", int(enemy.get_meta("shot_warning_token",0)) + 1)
		CUE.begin(enemy,species,pose)
		var pulse: Dictionary = pose.get_meta("t3j_cue")
		pulse.tween.custom_step(CUE.SECONDS*.5)
		pulse.tween.set_speed_scale(0)
	for node in stage.get_children():
		if node not in previous and node is MeshInstance3D: extras.append(node)
	# Suppress unrelated HUD; gallery captions identify species/state.
	var notices := stage.get_node_or_null("HUDNotices")
	if notices != null: notices.hide()
	for audio in get_nodes_in_group("bee_audio_voice"): audio.queue_free()
func sample(seconds: float) -> float:
	var start := Time.get_ticks_usec()
	var count := 0
	while float(Time.get_ticks_usec()-start)/1000000.0 < seconds:
		await process_frame
		count += 1
	return count*1000000.0/float(Time.get_ticks_usec()-start)
func run() -> void:
	root.size = SIZE
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	before = "--before" in OS.get_cmdline_user_args()
	CUE.enabled = not before
	stage = LEVEL.instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.get_node("LightProgression").set_process(false)
	stage.get_node("CanvasLayer").hide()
	stage.get_node("LiveReadability").panel.hide()
	stage.distance = 110
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(106,4,0)
	stage.bee.health.damage_blocked = true
	var layer := CanvasLayer.new()
	layer.layer = 40
	stage.add_child(layer)
	caption = Label.new()
	caption.position = Vector2(380,6)
	caption.add_theme_font_size_override("font_size",28)
	caption.add_theme_constant_override("outline_size",6)
	layer.add_child(caption)
	var montage := Image.create(CELL.x*4,CELL.y*CASES.size(),false,Image.FORMAT_RGBA8)
	for dark in [false,true]:
		stage.get_node("LightProgression").apply_distance(310 if dark else 80)
		for i in CASES.size():
			if "--ground-only" in OS.get_cmdline_user_args() and CASES[i] not in ["Turret", "Walker", "Turtle"]: continue
			if "--extras-only" in OS.get_cmdline_user_args() and i < 27: continue
			await clear()
			await prepare(CASES[i])
			caption.text = "%s · %s · %s" % ["ANTES" if before else "AHORA", "NOCHE" if dark else "DÍA", CASES[i]]
			await frames(3)
			await RenderingServer.frame_post_draw
			var picture := root.get_texture().get_image()
			picture.convert(Image.FORMAT_RGBA8)
			picture.resize(CELL.x,CELL.y,Image.INTERPOLATE_LANCZOS)
			var file := "res://dev/t3j_before_%s_%d.png" % ["night" if dark else "day",i]
			if before:
				picture.save_png(file)
			else:
				var old := Image.load_from_file(file)
				montage.blit_rect(old,Rect2i(Vector2i.ZERO,CELL),Vector2i(CELL.x*(2 if dark else 0),i*CELL.y))
				montage.blit_rect(picture,Rect2i(Vector2i.ZERO,CELL),Vector2i(CELL.x*(3 if dark else 1),i*CELL.y))
			print("T3J_CAPTURE ", CASES[i], " dark=",dark)
	if not before:
		assert(montage.save_png("res://docs/avisos_enemigos_comunes_antes_despues.png") == OK)
	if "--ground-only" in OS.get_cmdline_user_args() or "--extras-only" in OS.get_cmdline_user_args() or "--capture-only" in OS.get_cmdline_user_args():
		quit()
		return
	# GPU/render cost of the same dense fly swarm, frozen at the warning pose.
	await clear()
	stage.get_node("LightProgression").apply_distance(80)
	for i in 20:
		await prepare("FlyCommon",107.5+float(i%5)*1.0,1.2+float(i/5)*1.1)
	caption.text = "ENJAMBRE · %s" % ("ANTES" if before else "AHORA")
	await sample(1.0)
	var readings := []
	for pass_index in 3:
		readings.append(await sample(3.0))
	FileAccess.open("res://dev/t3j_fps_%s.json" % ("before" if before else "after"),FileAccess.WRITE).store_string(JSON.stringify(readings))
	print("T3J_FPS ",readings)
	CUE.enabled = true
	quit()
