extends "res://tests/art/validate_future_biomes_v09.gd"

func run() -> void:
	var visual = await verify_model("controlled_eagle_flight","eagle_sky_v01")
	if visual != null:
		visual.animate_wings = false
		check(visual.wing_pivots.size()==2,"Two independent wing pivots required")
		var triangles := 0
		var meshes := visual.find_children("*","MeshInstance3D",true,false)
		for mesh: MeshInstance3D in meshes:
			for surface in mesh.mesh.get_surface_count():
				triangles += mesh.mesh.surface_get_array_index_len(surface)/3
		check(triangles<=7000 and triangles>6000,"Eagle budget must be 6–7k triangles")
		check(meshes.size()==4,"Body, two wings and controller must remain separate")
		for wing in visual.wing_pivots:
			check(wing.find_children("*","MeshInstance3D",true,false).size()==1,"Wing pivot has no movable geometry")
		visual.set_flight_pose(0)
		visual.seek(0.0)
		var rest: Vector3 = visual.wing_pivots[0].rotation
		visual.seek(0.2)
		check(visual.wing_pivots[0].rotation.distance_to(rest)>0.3,"Wing flap did not move")
		check(visual.wing_pivots[1].rotation.x>visual.wing_rest[1].x,"Far wing must move opposite near wing")
		visual.set_flight_pose(1)
		visual.seek(0.4)
		check(visual.wing_pivots[0].rotation.is_equal_approx(rest),"Glide must restore spread wings")
		visual.set_flight_pose(2)
		check(visual.wing_pivots[0].rotation.distance_to(rest)>0.5,"Dive pose did not tuck wings")
		visual.face_right(true)
		check(is_equal_approx(visual.rotation.y,PI),"Horizontal facing did not reverse")
		print("EAGLE_SKY_MODEL: ",triangles," triangles / ",meshes.size()," meshes")
		visual.queue_free()
		await settle()
	var lab = load("res://scenes/art_labs/eagle_sky_v01.tscn").instantiate()
	root.add_child(lab)
	await settle()
	lab.animating = false
	check(lab.stage.get_child_count()==1,"Studio must contain only eagle")
	lab.show_sky()
	await settle()
	check(lab.stage.find_child("BeeScaleReference",true,false)!=null,"Sky needs tiny Bee scale reference")
	lab.seek_preview(0.2)
	var initial: Vector3 = lab.eagle.position
	lab.seek_preview(0.6)
	check(lab.eagle.position.distance_to(initial)>0.05,"Flight preview is static")
	lab.start_dive()
	lab.seek_preview(1.5)
	check(lab.eagle.position.x<0 and lab.eagle.position.y<0,"Dive must traverse XY plane")
	check(is_zero_approx(lab.eagle.position.z),"Dive left gameplay plane")
	lab.toggle_control()
	check(not lab.eagle.find_child("AlienControlDevice",true,false).visible,"Sky eagle failed release")
	lab.toggle_control()
	lab.show_single("controlled_eagle_flight",true,true)
	await settle()
	check(not lab.ui.visible and lab.stage.get_child_count()==1,"Clean concept view has unwanted scenery or UI")
	check(not lab.stage.get_child(0).animate_wings,"Studio pose must be frozen")
	lab.queue_free()
	await settle()
	print("EAGLE_SKY_VALIDATION: ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
