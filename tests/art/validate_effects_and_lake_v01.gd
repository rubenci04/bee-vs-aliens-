extends "res://tests/art/validate_future_biomes_v09.gd"
func run() -> void:
	for allegiance in ["bee","alien"]:
		var visual = load("res://scenes/art_labs/projectiles_toon_v01/"+allegiance+"_bolt.tscn").instantiate()
		root.add_child(visual)
		await settle()
		var triangles := 0
		for node: MeshInstance3D in visual.find_children("*","MeshInstance3D",true,false):
			for surface in node.mesh.get_surface_count():
				triangles += node.mesh.surface_get_array_index_len(surface)/3
		check(triangles==864,"Bolt count mismatch: "+allegiance)
		visual.queue_free()
		await settle()
		var fx = load("res://scenes/vfx/"+allegiance+"_toon_burst.tscn").instantiate()
		fx.autoplay = false
		fx.free_when_finished = false
		root.add_child(fx)
		await settle()
		fx.play()
		fx.playing = false
		fx.seek(fx.duration*.5)
		check(fx.visible and fx.ring.visible,"Burst absent halfway")
		for node: MeshInstance3D in fx.find_children("*","MeshInstance3D",true,false):
			var material := node.get_surface_override_material(0) as ShaderMaterial
			var energy: float = material.get_shader_parameter("emission_energy")
			check(is_equal_approx(energy,.65 if allegiance=="alien" else 0.0),"Wrong burst allegiance/emission")
		fx.seek(fx.duration)
		check(not fx.visible,"Completed burst persists")
		fx.play()
		check(fx.visible and fx.elapsed==0,"Burst cannot replay")
		fx.queue_free()
		await settle()
	var boss = load("res://scenes/levels/level_02_lake/lake_toad_miniboss_visual.tscn").instantiate()
	boss.preview_motion = false
	root.add_child(boss)
	await settle()
	check(boss.visual.scene_file_path=="res://scenes/art_labs/assets_v09/amphibian_mount_study.tscn","Boss must reuse original V09 toad")
	boss.pose_at(1.9)
	check(boss.visual.position.y>0,"Hop preview absent")
	boss.pose_at(3.0)
	check(absf(boss.visual.position.y)<.001,"Toad never returns to ground")
	boss.release_control()
	check(not boss.preview_motion,"Liberated toad still attacks in preview")
	check(not boss.find_child("AlienControlDevice",true,false).visible,"Toad device didn't release")
	check(boss.find_child("NaturalFauna",true,false).visible,"Toad release lost anatomy")
	boss.queue_free()
	await settle()
	print("EFFECTS_LAKE_VALIDATION: ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
