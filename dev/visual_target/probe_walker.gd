extends SceneTree
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	await process_frame
	var wave := stage.wave as BeeLevel01Controller
	stage.set_physics_process(false); wave.set_physics_process(false)
	wave._spawn({"family": "Walker", "slot": 0, "event": 0, "hard": false})
	var unit: Node3D = stage.get_node("Enemies").get_child(-1)
	unit.set_physics_process(false)
	var skel := unit.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var names := []
	for i in skel.get_bone_count():
		names.append(skel.get_bone_name(i))
	print("BONES ", names)
	for clip in ["CharacterArmature|Walk", "CharacterArmature|Idle"]:
		var ap := unit.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		ap.play(clip)
		var lo := INF
		var hi := -INF
		for f in 40:
			await process_frame
			for i in skel.get_bone_count():
				var y := (skel.global_transform * skel.get_bone_global_pose(i)).origin.y
				lo = minf(lo, y); hi = maxf(hi, y)
		print("CLIP ", clip, " bone_y min=", lo, " max=", hi)
		for n in ["Root", "Foot.L", "Foot.L_end", "Foot.R_end", "PT.L_end", "Body", "Head"]:
			var bi := skel.find_bone(n)
			print("  ", n, " y=", (skel.global_transform * skel.get_bone_global_pose(bi)).origin.y)
		print("  node_y=", unit.global_position.y, " skel_scale=", skel.global_transform.basis.get_scale())
	quit(0)
