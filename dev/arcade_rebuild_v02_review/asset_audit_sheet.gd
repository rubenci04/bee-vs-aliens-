extends SceneTree
## DEV ONLY. Contact sheet of local asset-library candidates (ARCADE REBUILD 02 asset audit). Loads each file at
## runtime from its absolute path (GLTFDocument / FBXDocument): NOTHING is imported into the project.
##   godot --path . --resolution 1600x900 --script res://dev/arcade_rebuild_v02_review/asset_audit_sheet.gd -- sheet=humans
## Writes dev/arcade_rebuild_v02_review/asset_audit/<sheet>.png (dev PNGs are git-ignored).

const LIB := "D:/proyectos/V_Asset_Library/01_Extracted/"
const OUT := "res://dev/arcade_rebuild_v02_review/asset_audit/"
const SHEETS := {
	"humans": [
		["res://assets/models/human_reuse/hipster_poc.glb", "ACTUAL hipster (Tucuman Rush)"],
		[LIB + "kenney/kenney_mini-forest_1.0/Models/GLB format/character-archer.glb", "Kenney archer CC0"],
		[LIB + "quaternius/Easy Animated Enemy Pack - Jan 2019-20260929T144515Z-1-001/Easy Animated Enemy Pack - Jan 2019/FBX/Rat.fbx", "Quaternius Rat CC0"],
	],
	"fauna": [
		[LIB + "quaternius/Easy Animated Enemy Pack - Jan 2019-20260929T144515Z-1-001/Easy Animated Enemy Pack - Jan 2019/FBX/Spider.fbx", "Spider CC0"],
		[LIB + "quaternius/Easy Animated Enemy Pack - Jan 2019-20260929T144515Z-1-001/Easy Animated Enemy Pack - Jan 2019/FBX/Frog.fbx", "Frog CC0"],
		[LIB + "quaternius/Easy Animated Enemy Pack - Jan 2019-20260929T144515Z-1-001/Easy Animated Enemy Pack - Jan 2019/FBX/Snake.fbx", "Snake CC0"],
		[LIB + "quaternius/Easy Animated Enemy Pack - Jan 2019-20260929T144515Z-1-001/Easy Animated Enemy Pack - Jan 2019/FBX/Wasp.fbx", "Wasp CC0"],
	],
	"props": [
		[LIB + "kenney/kenney_food-kit/Models/GLB format/orange.glb", "orange CC0"],
		[LIB + "kenney/kenney_food-kit/Models/GLB format/apple.glb", "apple CC0"],
		[LIB + "kenney/kenney_food-kit/Models/GLB format/soda-can.glb", "soda-can CC0"],
		[LIB + "kenney/kenney_food-kit/Models/GLB format/soda-can-crushed.glb", "can crushed CC0"],
		[LIB + "kenney/kenney_food-kit/Models/GLB format/cup-coffee.glb", "cup CC0"],
		[LIB + "kenney/kenney_food-kit/Models/GLB format/candy-bar-wrapper.glb", "wrapper CC0"],
		[LIB + "kenney/kenney_food-kit/Models/GLB format/watermelon.glb", "watermelon CC0"],
		[LIB + "kenney/kenney_food-kit/Models/GLB format/cookie.glb", "cookie CC0"],
	],
	"alien": [
		[LIB + "quaternius/Sci-Fi Essentials Kit[Standard]/glTF/Enemy_QuadShell.gltf", "QuadShell CC0"],
		[LIB + "quaternius/Sci-Fi Essentials Kit[Standard]/glTF/Enemy_Trilobite.gltf", "Trilobite CC0"],
		[LIB + "quaternius/Sci-Fi Essentials Kit[Standard]/glTF/Prop_SatelliteDish.gltf", "SatelliteDish CC0"],
		[LIB + "quaternius/Sci-Fi Essentials Kit[Standard]/glTF/Prop_Mine.gltf", "Mine CC0"],
	],
}

var sheet := "humans"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("sheet="):
			sheet = arg.substr(6)
	call_deferred("run")

func load_model(path: String) -> Node3D:
	if path.begins_with("res://"):
		return (load(path) as PackedScene).instantiate() as Node3D
	var state: GLTFState
	var document: GLTFDocument
	if path.to_lower().ends_with(".fbx"):
		state = FBXState.new()
		document = FBXDocument.new()
	else:
		state = GLTFState.new()
		document = GLTFDocument.new()
	if document.append_from_file(path, state) != OK:
		push_error("Could not read " + path)
		return null
	return document.generate_scene(state) as Node3D

func bounds(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mesh.global_transform * mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box

func run() -> void:
	root.size = Vector2i(1600, 900)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.78, 0.84, 0.74)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1, 0.95, 0.85)
	env.environment.ambient_light_energy = 0.7
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.8, 0.6, 0)
	world.add_child(sun)
	var entries: Array = SHEETS[sheet]
	var cell := 3.2
	for i in entries.size():
		var model := load_model(str(entries[i][0]))
		if model == null:
			continue
		world.add_child(model)
		await process_frame
		var box := bounds(model)
		var size := maxf(box.size.y, maxf(box.size.x, box.size.z))
		model.scale = Vector3.ONE * (2.2 / maxf(size, 0.001))
		await process_frame
		box = bounds(model)
		var x := (float(i) - (entries.size() - 1) * 0.5) * cell
		model.global_position += Vector3(x - box.get_center().x, -box.position.y - 1.2, -box.get_center().z)
		model.rotation.y = -0.5
		BeeToonStyle.apply(model, true)
		for player: AnimationPlayer in model.find_children("*", "AnimationPlayer", true, false):
			var clips := player.get_animation_list()
			for clip in clips:
				if str(clip).to_lower().contains("run") or str(clip).to_lower().contains("walk"):
					player.play(clip)
					player.seek(0.3, true)
					break
		var label := Label3D.new()
		label.text = str(entries[i][1])
		label.font_size = 40
		label.pixel_size = 0.004
		label.modulate = Color(0.1, 0.1, 0.1)
		label.position = Vector3(x, -1.75, 0.5)
		world.add_child(label)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 0.2, 9.5)
	camera.fov = 45.0
	world.add_child(camera)
	camera.make_current()
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.get_texture().get_image().save_png(OUT + sheet + ".png")
	print("SHEET ", sheet, " ", entries.size())
	quit(0)
