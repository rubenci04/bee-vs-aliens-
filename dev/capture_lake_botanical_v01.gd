extends SceneTree
const KEYS := ["floating_branch", "totoras_cluster", "flowering_lily_pads"]
const OUT := "res://concept_art/levels/level_02/lake_botanical_v01/"
func _initialize() -> void:
	call_deferred("run")
func shot(camera: Camera3D, where: Vector3, centre: Vector3, name: String, size: float, up := Vector3.UP) -> void:
	camera.position = where
	camera.size = size
	camera.look_at(centre,up)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1200,800)
	var world := load("res://scenes/art_labs/lake_botanical_v01.tscn").instantiate() as Node3D
	root.add_child(world)
	world.get_node("CanvasLayer").hide()
	var camera := world.get_node("Camera3D") as Camera3D
	var props: Array[Node3D] = []
	for key in KEYS:
		var prop := world.get_node(key) as Node3D
		prop.preview_motion = false
		var player := prop.find_child("AnimationPlayer",true,false) as AnimationPlayer
		player.stop()
		props.append(prop)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"overview.png")
	for i in props.size():
		for prop in props: prop.hide()
		var prop := props[i]
		prop.show()
		var saved := prop.position
		prop.position = Vector3.ZERO
		var centre := Vector3(0,1.50,0) if i==1 else Vector3(0,0.18,0)
		var size := 4.2 if i==1 else 2.8
		await shot(camera, centre+Vector3(0,1.1,14),centre,KEYS[i]+"_side",size)
		await shot(camera, centre+Vector3(-14,1.1,0),centre,KEYS[i]+"_front",size)
		await shot(camera, centre+Vector3(14,1.1,0),centre,KEYS[i]+"_rear",size)
		await shot(camera, Vector3(0,15,0),Vector3.ZERO,KEYS[i]+"_top",3.6 if i==1 else 2.8,Vector3.FORWARD)
		await shot(camera, centre+Vector3(-5,7,10),centre,KEYS[i]+"_hero",4.2 if i==1 else 3.0)
		prop.position = saved
	quit(0)
