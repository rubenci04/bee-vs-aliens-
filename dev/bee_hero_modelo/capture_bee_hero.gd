extends SceneTree
const OUT := "res://docs/art/renders/bee_hero/"
var round_name := "round_01"
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("round_"):round_name=arg
	call_deferred("run")
func capture(camera: Camera3D,point: Vector3,target: Vector3,path: String,size: float,up:=Vector3.UP) -> void:
	camera.position=point
	camera.size=size
	camera.look_at(target,up)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+round_name+"/"+path+".png")
func run() -> void:
	root.size=Vector2i(1400,1000)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color(.63,.63,.61)
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color(1,.91,.76)
	env.environment.ambient_light_energy=.7
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	world.add_child(sun)
	sun.rotation_degrees=Vector3(-40,-25,0)
	sun.light_color=Color(1,.9,.72)
	sun.light_energy=1.25
	var camera := Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.current=true
	world.add_child(camera)
	for version in ["full","lite"]:
		var model := load("res://scenes/art_labs/bee_hero_v02/"+version+".tscn").instantiate() as Node3D
		model.preview_motion=false
		world.add_child(model)
		await process_frame
		var centre := Vector3(0,.11,0)
		await capture(camera,Vector3(4,.11,0),centre,version+"_side",2.5)
		await capture(camera,Vector3(0,.11,-4),centre,version+"_front",2.5)
		await capture(camera,Vector3(0,.11,4),centre,version+"_rear",2.5)
		await capture(camera,Vector3(0,4,0),Vector3.ZERO,version+"_top",2.5,Vector3.FORWARD)
		await capture(camera,Vector3(3,1.4,-4),centre,version+"_three_quarter",2.5)
		var black := StandardMaterial3D.new()
		black.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		black.albedo_color=Color.BLACK
		for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			mesh.material_override=black
		await capture(camera,Vector3(4,.11,0),centre,version+"_silhouette",2.5)
		model.queue_free()
		await process_frame
	quit(0)
