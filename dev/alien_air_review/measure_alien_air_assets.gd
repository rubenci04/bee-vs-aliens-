extends SceneTree

const EYE := preload("res://assets/external/approved/alien_air/quaternius/Sci-Fi Essentials Kit[Standard]/glTF/Enemy_EyeDrone.gltf")
const SPEEDER := preload("res://assets/external/approved/alien_air/kenney/kenney_space-kit/Models/GLTF format/craft_speederA.glb")
const BEE := preload("res://assets/models/bee_prototype/bee_alien_visual.glb")
const PROBE := preload("res://scenes/bee_prototype/visuals/alien_probe_visual.tscn")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for entry in [["Bee",BEE],["Probe",PROBE],["EyeDrone",EYE],["Speeder",SPEEDER]]:
		var node: Node3D = entry[1].instantiate()
		root.add_child(node)
		var box := AABB()
		var first := true
		var count := 0
		for mesh: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
			var local := node.global_transform.affine_inverse() * mesh.global_transform
			var part: AABB = local * mesh.get_aabb()
			box = part if first else box.merge(part)
			first = false
			count += 1
		print("ASSET ",entry[0]," meshes=",count," bounds=",box," size=",box.size," center=",box.get_center())
		for child in node.get_children():
			if child is Node3D:
				print("ROOT_CHILD ",entry[0]," ",child.name," transform=",child.transform)
		node.queue_free()
	quit(0)
