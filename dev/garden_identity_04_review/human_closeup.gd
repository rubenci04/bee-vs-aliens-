extends SceneTree
## DEV ONLY (GARDEN IDENTITY 04). Close-up of the Giant Human's leg, jean and boot as the Level 01 camera E frames them
## (6x scale, side view, Style C without outline), in two Run poses. `variant=before` uses the plain level look;
## `variant=after` also applies the close-up polish of this pass (GiantHumanCloseUp.apply). Bee at real scale.
##   godot --path . --resolution 640x360 --script res://dev/garden_identity_04_review/human_closeup.gd -- variant=before
## Writes dev/garden_identity_04_review/human_closeup_<variant>.png.

const HIPSTER := preload("res://assets/models/human_reuse/hipster_poc.glb")
const BEE := preload("res://assets/style/models/bee_mid_poly.glb")

var variant := "before"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("variant="):
			variant = arg.substr(8)
	call_deferred("run")


func run() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1600, 900)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.86, 0.87, 0.78)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1.0, 0.88, 0.62)
	env.environment.ambient_light_energy = 0.75
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.82, 0.5)
	sun.light_energy = 1.4
	sun.rotation_degrees = Vector3(-58, -18, 0)
	vp.add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 40)
	ground.mesh = plane
	var soil := StandardMaterial3D.new()
	soil.albedo_color = Color(0.47, 0.33, 0.18)
	ground.material_override = soil
	ground.position.y = -0.2
	vp.add_child(ground)
	for i in 2:
		var root3d := Node3D.new()
		root3d.rotation.y = PI * 0.5
		root3d.scale = Vector3.ONE * 6.0
		root3d.position = Vector3(-4.2 + i * 9.0, 0.0, -1.0)
		vp.add_child(root3d)
		var human := HIPSTER.instantiate() as Node3D
		root3d.add_child(human)
		for sole in ["SoleL", "SoleR"]:
			var node := human.find_child(sole, true, false) as Node3D
			if node != null:
				node.hide()
		var player := human.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		player.play(&"Run")
		player.seek(0.1 + 0.3 * i, true)
		player.pause()
		BeeToonStyle.apply(human, false)
		if variant == "after":
			load("res://scripts/levels/giant_human_close_up.gd").apply(human) # Loaded late: absent before this pass.
		var bee := BEE.instantiate() as Node3D
		vp.add_child(bee)
		BeeToonStyle.apply(bee, true, BeeToonStyle.OUTLINE_BEE)
		bee.position = Vector3(-4.2 + i * 9.0 + 2.6, 2.4, 0.0)
	var camera := Camera3D.new()
	camera.fov = 40.0
	camera.position = Vector3(0.3, 2.45, 10.0)
	camera.rotation_degrees.x = 5.0
	vp.add_child(camera)
	camera.make_current()
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("res://dev/garden_identity_04_review/human_closeup_%s.png" % variant)
	print("HUMAN CLOSEUP ", variant)
	quit(0)
