extends "res://tests/art/validate_future_biomes_v09.gd"
func run() -> void:
	for id in ["controlled_hanging_spider", "controlled_eagle"]:
		var visual := await verify_model(id,"v11")
		var triangles := 0
		for mesh: MeshInstance3D in visual.find_children("*","MeshInstance3D",true,false):
			for surface in mesh.mesh.get_surface_count():
				triangles += mesh.mesh.surface_get_array_index_len(surface)/3
		if id == "controlled_hanging_spider":
			check(triangles<=5000,"Spider budget exceeded")
			check(visual.find_children("SpiderLeg_*","Node3D",true,false).filter(func(n): return not n is MeshInstance3D).size()==8,"Eight spider legs required")
			visual.release_control()
			check(visual.find_child("NaturalSilk",true,false).is_visible_in_tree(),"Release removed natural silk")
			check(visual.find_child("SilkAnchor",true,false)!=null,"Hanging anchor missing")
		else:
			check(triangles<=7000,"Eagle budget exceeded")
			check(visual.find_children("EagleWing_*","Node3D",true,false).filter(func(n): return not n is MeshInstance3D).size()==2,"Two eagle wings required")
		visual.queue_free()
		await settle()
	print("FUTURE_BIOMES_V11_VALIDATION: ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
