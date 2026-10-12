extends "res://tests/art/validate_future_biomes_v09.gd"
func run() -> void:
	var mothership = load("res://scenes/art_labs/mothership_v01/alien_mothership.tscn").instantiate()
	root.add_child(mothership)
	await settle()
	var triangles := 0
	for mesh: MeshInstance3D in mothership.find_children("*","MeshInstance3D",true,false):
		for surface in mesh.mesh.get_surface_count():
			triangles += mesh.mesh.surface_get_array_index_len(surface)/3
			var material := mesh.get_surface_override_material(surface) as ShaderMaterial
			check(material!=null and material.next_pass!=null,"Mothership toon missing")
	check(triangles==6764,"Mothership budget mismatch")
	for marker in ["HangarSpawn","MainLensTarget","BossOrigin","EscortDock_-1","EscortDock_1"]:
		check(mothership.find_child(marker,true,false)!=null,"Missing boss reference marker: "+marker)
	mothership.queue_free()
	await settle()
	check(ResourceLoader.exists("res://assets/ui/bee_alien_logo_v01.svg"),"Logo import absent")
	var title_scene = load("res://scenes/art_labs/title_screen_v01.tscn").instantiate()
	root.add_child(title_scene)
	await settle()
	check(title_scene.hero.scene_file_path=="res://assets/models/shared/bee/bee_mid_poly.glb","Title must use canonical smooth Bee")
	check(title_scene.ui.find_children("*","Button",true,false).size()==3,"Title menu incomplete")
	title_scene.queue_free()
	await settle()
	var hub = load("res://scenes/art_labs/art_delivery_hub_v01.tscn").instantiate()
	root.add_child(hub)
	await settle()
	for entry in hub.LABS:
		check(ResourceLoader.exists("res://scenes/art_labs/"+entry[1]+".tscn"),"Hub link missing: "+entry[1])
	check(hub.find_children("*","Button",true,false).size()==hub.LABS.size()+1,"Hub navigation incomplete")
	hub.queue_free()
	await settle()
	print("MOTHERSHIP_TITLE_VALIDATION: ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
