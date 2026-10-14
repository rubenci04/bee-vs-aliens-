extends SceneTree
## T4b: captures real Level 01 movement and existing anthill entrance, with rendering.
const SIZE := Vector2i(1154,648)
var stage: BeeShmupStage
var caption: Label
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for tick in count: await physics_frame
func capture(montage: Image, index: int, columns: int, text: String) -> void:
	caption.text = text
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	picture.convert(Image.FORMAT_RGBA8)
	montage.blit_rect(picture,Rect2i(Vector2i.ZERO,SIZE),Vector2i((index%columns)*SIZE.x,(index/columns)*SIZE.y))
func run() -> void:
	root.size = SIZE
	stage = preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.distance = 25
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(23,4,0)
	stage.wave._spawn({"family":"Wasp","slot":0,"event":0,"hard":false})
	var wasp := stage.wave.active_units.back() as WaspEnemy
	wasp.global_position = Vector3(24.8,4.5,0)
	wasp.set_physics_process(false)
	var layer := CanvasLayer.new()
	layer.layer = 40
	stage.add_child(layer)
	caption = Label.new()
	caption.position = Vector2(280,116)
	caption.add_theme_font_size_override("font_size",26)
	caption.add_theme_constant_override("outline_size",5)
	layer.add_child(caption)
	await frames(4)
	var sting := Image.create(SIZE.x,SIZE.y*5,false,Image.FORMAT_RGBA8)
	await capture(sting,0,1,"1 · Antes de activar: enemigo cercano")
	assert(stage.bee.start_melee())
	await frames(4)
	await capture(sting,1,1,"2 · Embestida: Bee avanza invulnerable")
	await frames(4)
	await capture(sting,2,1,"3 · Cuerpo orientado y estela breve")
	await frames(7)
	await capture(sting,3,1,"4 · Impacto al llegar: destello")
	await frames(12)
	await capture(sting,4,1,"5 · Retroceso terminado, sin carga")
	assert(sting.save_png("res://docs/aguijon_embestida.png") == OK)
	stage.bee.set_physics_process(false)
	stage.bee.global_position = Vector3(23,5,0)
	stage.wave._spawn({"family":"Ant","slot":0,"event":0,"hard":false,"anthill":true,"y":4})
	var ant := stage.wave.active_units.back() as AssetFauna
	var entry := Image.create(SIZE.x*2,SIZE.y*2,false,Image.FORMAT_RGBA8)
	await capture(entry,0,2,"1 · Boca del hormiguero: salida con polvo")
	await frames(21)
	await capture(entry,1,2,"2 · Crece y baja desde la abertura")
	await frames(28)
	await capture(entry,2,2,"3 · Descenso final, sin salto")
	await frames(23)
	await capture(entry,3,2,"4 · Activa en el carril del suelo (y = -0,2)")
	assert(is_equal_approx(ant.global_position.y,BeeLevel01Anthills.GROUND_Y))
	assert(entry.save_png("res://docs/hormigas_entrada.png") == OK)
	print("T4B_CAPTURE_OK sting=",stage.bee.melee_count," ant_y=",ant.global_position.y)
	stage.queue_free()
	await frames(3)
	quit()
