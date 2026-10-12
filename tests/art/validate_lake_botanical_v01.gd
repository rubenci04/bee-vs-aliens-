extends SceneTree
const IDS := ["floating_branch","totoras_cluster","flowering_lily_pads"]
const COUNTS := [708,1720,1540]
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func run() -> void:
	for index in IDS.size():
		var id: String = IDS[index]
		var model := load("res://scenes/art_labs/lake_botanical_v01/"+id+".tscn").instantiate() as Node3D
		model.preview_motion = false
		root.add_child(model)
		await process_frame
		await process_frame
		var triangles := 0
		var materials := {}
		var bounds := AABB()
		var first := true
		for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			var box: AABB = mesh.global_transform * mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
			check(mesh.scale.is_equal_approx(Vector3.ONE), "Nonapplied mesh scale: "+mesh.name)
			for surface in mesh.mesh.get_surface_count():
				triangles += mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size()/3
				var source := mesh.mesh.surface_get_material(surface) as BaseMaterial3D
				materials[source.get_instance_id()] = true
				check(not source.emission_enabled, "Nature must not emit")
				var toon := mesh.get_surface_override_material(surface) as ShaderMaterial
				check(toon != null and toon.next_pass != null, "Missing toon/outline: "+mesh.name)
		check(triangles == COUNTS[index] and triangles <= 2000, "Repeatable prop budget wrong: "+id)
		check(materials.size() <= 4, "Too many materials: "+id)
		check(absf(bounds.position.y) < 0.01, "Base origin must be Y=0: "+id)
		check(model.find_children("*","CollisionObject3D",true,false).is_empty(), "Decorative prop introduces collisions")
		check(model.find_child("PlacementAnchor",true,false) != null, "Missing placement anchor")
		var pivot := model.find_child("WindPivot" if index==1 else "FloatPivot",true,false) as Node3D
		var player := model.find_child("AnimationPlayer",true,false) as AnimationPlayer
		check(player != null and player.has_animation("idle"), "Missing GLB idle animation")
		player.play("idle")
		player.seek(0.4,true)
		var pose := pivot.transform
		player.seek(1.4,true)
		check(not pivot.transform.is_equal_approx(pose), "Idle must move floating/wind pivot: "+id)
		if index==1:
			check(model.find_children("seed_head_*","MeshInstance3D",true,false).size()==5, "Five cattail heads required")
		if index==2:
			check(model.find_children("lily_pad_*","MeshInstance3D",true,false).size()==2, "Two separate lily leaves required")
		print("LAKE_BOTANICAL ",id," tris=",triangles," materials=",materials.size()," size=",bounds.size)
		model.queue_free()
		await process_frame
	print("LAKE_BOTANICAL_VALIDATION failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
