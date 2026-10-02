extends SceneTree
const MODEL := preload("res://assets/external/approved/ground_threat/kenney/kenney_space-kit/Models/GLTF format/turret_single.glb")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var node: Node3D = MODEL.instantiate()
	root.add_child(node)
	var box := AABB()
	var first := true
	var count := 0
	for mesh: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		var local := node.global_transform.affine_inverse() * mesh.global_transform
		var part: AABB = local * mesh.get_aabb()
		print("PART ",mesh.name," ",part)
		box = part if first else box.merge(part)
		first = false
		count += 1
	print("TURRET meshes=",count," bounds=",box," size=",box.size," center=",box.get_center())
	for child in node.get_children():
		if child is Node3D: print("CHILD ",child.name," transform=",child.transform)
	quit(0)

