extends Node3D
## Garden-only presentation. No dependencies on the review lab or gameplay changes.
const TREE = preload("res://assets/external/approved/nature/quaternius/Stylized Nature MegaKit[Standard]/glTF/CommonTree_1.gltf")
const FERN = preload("res://assets/external/approved/nature/quaternius/Stylized Nature MegaKit[Standard]/glTF/Fern_1.gltf")
const LOG = preload("res://assets/external/approved/nature/kenney/kenney_nature-kit/Models/GLTF format/log_large.glb")
const FLOWER = preload("res://assets/external/approved/nature/kenney/kenney_nature-kit/Models/GLTF format/flower_purpleA.glb")
const BOTTLE = preload("res://assets/external/approved/props/kenney/kenney_food-kit/Models/GLB format/soda-bottle.glb")

func _ready() -> void:
	place(TREE,"TreeA",Vector3(-19,0,-10),0.94,0.3)
	place(TREE,"TreeB",Vector3(0,0,-10),1.10,-0.7)
	place(TREE,"TreeC",Vector3(22,0,-10),0.87,1.8)
	for entry in [[-14.0,2.1,0.1],[-8.0,2.38,1.0],[-1.0,2.0,-0.6],[5.0,2.5,0.4],[10.0,2.15,-1.3],[15.0,2.38,2.0]]:
		place(FERN,"Fern%d" % get_child_count(),Vector3(entry[0],0,-3.8),entry[1],entry[2])
	place(LOG,"FallenLog",Vector3(1,0,0),4.799,0)
	for entry in [[-12.0,15.26,-1.3],[-4.0,21.855,-1.6],[7.0,18.144,-1.7],[1.0,8.247,-3.0]]:
		place(FLOWER,"Flower%d" % get_child_count(),Vector3(entry[0],0,entry[2]),entry[1],0.2)
	place(BOTTLE,"GiantBottle",Vector3(13,0,-2.7),10.337,0.15)

func place(asset: PackedScene, label: String, floor_position: Vector3, factor: float, yaw: float) -> void:
	var instance: Node3D = asset.instantiate()
	instance.name = label
	add_child(instance)
	var bounds := AABB()
	var first := true
	for mesh: MeshInstance3D in instance.find_children("*","MeshInstance3D",true,false):
		var local := instance.global_transform.affine_inverse() * mesh.global_transform
		var box: AABB = local * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	instance.scale = Vector3.ONE * factor
	instance.rotation.y = yaw
	var center := bounds.get_center()
	var offset := Vector3(center.x,bounds.position.y,center.z) * factor
	offset = offset.rotated(Vector3.UP,yaw)
	instance.position = floor_position - offset

