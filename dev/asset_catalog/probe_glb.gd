extends SceneTree
func _init() -> void:
	await process_frame
	for p in ["v01/controlled_mosquito","v03/controlled_flying_ladybird","v10/controlled_dragonfly","v10/controlled_bomb_moth","v10/moth_stationary_bomb","v09/controlled_ant","v02/controlled_stag_beetle","v02/controlled_woodland_snail","v10/controlled_mushroom_cannon","v02/alien_signal_relay","v02/alien_seed_carrier","v03/controlled_firefly","v07/sky_crescent_moon","v07/sky_star_cluster","v04/giant_bottle_cap","v06/empty_drink_can","v06/wrapped_candy","v06/flowering_shrub","v06/garden_sapling"]:
		var parts: PackedStringArray = p.split("/")
		var path := "res://scenes/art_labs/assets_%s/%s.tscn" % [parts[0].replace("v", "v"), parts[1]]
		if parts[0] == "v01": path = "res://scenes/art_labs/assets/%s.tscn" % parts[1]
		var res := load(path)
		if res == null:
			print(p, " NO TSCN ", path); continue
		var n: Node3D = res.instantiate()
		root.add_child(n)
		await process_frame
		var dev := n.find_child("AlienControlDevice", true, false) as Node3D
		var aabb := AABB()
		var first := true
		for m: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
			var a: AABB = m.global_transform * m.get_aabb()
			aabb = a if first else aabb.merge(a); first = false
		print(p, " aabb pos=", aabb.position.snapped(Vector3(0.01,0.01,0.01)), " size=", aabb.size.snapped(Vector3(0.01,0.01,0.01)), " device=", (dev.global_position.snapped(Vector3(0.01,0.01,0.01)) if dev else "none"))
		n.queue_free()
	quit()
