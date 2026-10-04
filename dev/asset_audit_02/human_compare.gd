extends SceneTree
## DEV ONLY (ASSET LIBRARY DEEP AUDIT 02). Giant Human comparison: the current Hipster vs the library
## humanoids, all scaled to the Hipster's in-game height (2.11 m x 6), Style C without outline (as in
## Level 01), in their run/walk pose, with Bee at real scale and the visible band of camera E (0..7.1 m).
## Also prints leg proportions (crotch height / total height) measured from the posed skeleton.
## NOTHING is imported; library files are read at runtime.
##   godot --path . --resolution 640x360 --script res://dev/asset_audit_02/human_compare.gd
## Writes dev/asset_audit_02/sheets/human_compare_giant.png.

const LIB := "D:/proyectos/V_Asset_Library/01_Extracted/"
const KK := LIB + "nuevos/KayKit_Adventurers_2.0_FREE/KayKit_Adventurers_2.0_FREE/"
const UPP := LIB + "nuevos/Ultimate Platformer Pack by Quaternius/Ultimate Platformer Pack - Dec 2021/"
const TARGET_HEIGHT := 2.11 * 6.0
const CANDIDATES := [
	["res://assets/models/human_reuse/hipster_poc.glb", "ACTUAL Hipster", "", "run", ["thigh_L", "thigh_R"]],
	[KK + "Characters/gltf/Rogue.glb", "KayKit Rogue (CC0)", KK + "Animations/gltf/Rig_Medium/Rig_Medium_MovementBasic.glb", "running_a", ["upperleg.l", "upperleg.r"]],
	[KK + "Characters/gltf/Knight.glb", "KayKit Knight (CC0)", KK + "Animations/gltf/Rig_Medium/Rig_Medium_MovementBasic.glb", "walking_a", ["upperleg.l", "upperleg.r"]],
	[UPP + "Character/glTF/Character.gltf", "UPP Character (CC0)", "", "run", ["UpperLeg.L", "UpperLeg.R"]],
	[LIB + "kenney/kenney_mini-forest_1.0/Models/GLB format/character-archer.glb", "Kenney archer (CC0)", "", "sprint", []],
]


func _initialize() -> void:
	call_deferred("run")


func load_model(path: String) -> Node3D:
	if path.begins_with("res://"):
		return (load(path) as PackedScene).instantiate() as Node3D
	var fbx := path.to_lower().ends_with(".fbx")
	var state: GLTFState = FBXState.new() if fbx else GLTFState.new()
	var document: GLTFDocument = FBXDocument.new() if fbx else GLTFDocument.new()
	document.append_from_file(path, state)
	return document.generate_scene(state) as Node3D


func bounds(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null or not mesh.is_visible_in_tree():
			continue
		var b: AABB = mesh.global_transform * mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(3600, 900)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.own_world_3d = true
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.74, 0.84, 0.92)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1, 0.95, 0.85)
	env.environment.ambient_light_energy = 0.6
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.7, 0.5, 0)
	world.add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 40)
	ground.mesh = plane
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.45, 0.6, 0.3)
	ground.material_override = ground_material
	world.add_child(ground)
	# Camera E visible band on Bee's plane: 0 .. 7.1 m.
	var band := MeshInstance3D.new()
	var band_mesh := BoxMesh.new()
	band_mesh.size = Vector3(120, 0.08, 0.08)
	band.mesh = band_mesh
	band.position = Vector3(0, 7.1, 3)
	var band_material := StandardMaterial3D.new()
	band_material.albedo_color = Color(0.9, 0.2, 0.2)
	band_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	band.material_override = band_material
	world.add_child(band)
	var bee_scene := load("res://assets/style/models/bee_mid_poly.glb") as PackedScene
	var spacing := 15.0
	for i in CANDIDATES.size():
		var entry: Array = CANDIDATES[i]
		var model := load_model(entry[0])
		world.add_child(model)
		if entry[2] != "":
			var donor := load_model(entry[2])
			var donor_player := donor.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
			var player := AnimationPlayer.new()
			model.add_child(player)
			player.root_node = NodePath("..")
			var library := AnimationLibrary.new()
			for clip in donor_player.get_animation_list():
				library.add_animation(clip, donor_player.get_animation(clip).duplicate())
			player.add_animation_library("", library)
			donor.free()
		for player: AnimationPlayer in model.find_children("*", "AnimationPlayer", true, false):
			for clip in player.get_animation_list():
				if entry[3] != "" and str(clip).to_lower().contains(entry[3]):
					player.play(clip)
					player.seek(player.get_animation(clip).length * 0.3, true)
					player.pause()
					break
		model.rotation.y = PI * 0.5 # side view, like the crossing in Level 01
		await process_frame
		var box := bounds(model)
		var s := TARGET_HEIGHT / maxf(box.size.y, 0.001)
		model.scale = Vector3.ONE * s
		await process_frame
		box = bounds(model)
		var x := (i - (CANDIDATES.size() - 1) * 0.5) * spacing
		model.global_position += Vector3(x - box.get_center().x, -box.position.y, -box.get_center().z)
		await process_frame
		BeeToonStyle.apply(model, false)
		# Crotch height from the posed upper-leg bones.
		var crotch := -1.0
		for skeleton: Skeleton3D in model.find_children("*", "Skeleton3D", true, false):
			for bone_name in entry[4]:
				var b := skeleton.find_bone(bone_name)
				if b >= 0:
					var y := (skeleton.global_transform * skeleton.get_bone_global_pose(b)).origin.y
					crotch = y if crotch < 0 else minf(crotch, y)
		var ratio := crotch / TARGET_HEIGHT if crotch > 0 else -1.0
		print("HUMAN %s crotch=%.2f m of %.2f m -> legs %.0f%% | in-view (<=7.1 m) fraction of body %.0f%%" % [entry[1], crotch, TARGET_HEIGHT, ratio * 100.0, 7.1 / TARGET_HEIGHT * 100.0])
		var label := Label3D.new()
		label.text = "%s\nentrepierna %.1f m (%.0f%% de la altura)" % [entry[1], crotch, ratio * 100.0] if crotch > 0 else str(entry[1]) + "\n(sin hueso de pierna)"
		label.font_size = 64
		label.pixel_size = 0.012
		label.modulate = Color(0.05, 0.05, 0.05)
		label.position = Vector3(x, -1.6, 6)
		world.add_child(label)
		var bee := bee_scene.instantiate() as Node3D
		world.add_child(bee)
		BeeToonStyle.apply(bee, true, BeeToonStyle.OUTLINE_BEE)
		bee.position = Vector3(x + 0.0, 2.2, 5)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 22.5
	camera.position = Vector3(0, 8.3, 40)
	world.add_child(camera)
	camera.make_current()
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://dev/asset_audit_02/sheets/human_compare_giant.png")
	print("HUMAN COMPARE DONE")
	quit(0)
