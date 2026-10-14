extends SceneTree
## Four real Level 01 moments: gradual emergence, fan, column, diagonal.
const SIZE := Vector2i(1154,648)
const GROUND := preload("res://scripts/levels/bee_ground_worm.gd")
var stage: BeeShmupStage
var worm: AssetFauna
var caption: Label
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for tick in count: await physics_frame
func run() -> void:
	root.size = SIZE
	stage = preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.distance = 156
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(150,5,0)
	stage.bee.health.damage_blocked = true
	stage.wave._spawn({"family":"WormA","slot":0,"event":0,"hard":false})
	worm = stage.wave.active_units.back() as AssetFauna
	stage.wave._spawn({"family":"WormB","slot":1,"event":0,"hard":false})
	var compost := stage.wave.active_units.back() as AssetFauna
	compost.global_position.x += 1.2
	var layer := CanvasLayer.new()
	layer.layer = 40
	stage.add_child(layer)
	caption = Label.new()
	caption.position = Vector2(330,116)
	caption.add_theme_font_size_override("font_size",26)
	caption.add_theme_constant_override("outline_size",5)
	layer.add_child(caption)
	var montage := Image.create(SIZE.x*2,SIZE.y*2,false,Image.FORMAT_RGBA8)
	var index := 0
	var labels := ["1 · Salida gradual con polvo", "2 · Abanico de tres gotas amarillas", "3 · Columna lenta hacia arriba", "4 · Diagonal lenta hacia arriba"]
	for tick in 60*40:
		await physics_frame
		var attack = worm._ground_worm
		var ready := false
		if index == 0:
			ready = attack.phase == GROUND.Phase.EMERGE and attack.left < .24 and attack.left > .12
		else:
			ready = attack.patterns_fired.size() >= index and worm.shots_fired >= index*3
		if not ready: continue
		caption.text = labels[index]
		if index > 0: await frames(40 if index == 1 else 12)
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		picture.convert(Image.FORMAT_RGBA8)
		montage.blit_rect(picture,Rect2i(Vector2i.ZERO,SIZE),Vector2i((index%2)*SIZE.x,(index/2)*SIZE.y))
		print("T4D_CAPTURE ",labels[index]," y=",worm.global_position.y," patterns=",attack.patterns_fired)
		index += 1
		if index == 4: break
	assert(index == 4,"Four natural attack moments must be captured")
	assert(montage.save_png("res://docs/gusanos_fase1.png") == OK)
	print("T4D_CAPTURE_OK")
	quit()
