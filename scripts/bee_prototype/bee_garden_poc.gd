extends Node3D
## Garden POC: shared proxy and approved scenery, two proximity triggers, simple restart.
@onready var bee: BeePlayer = $BeePlayer
var materials: Dictionary = {}
var meshes: Dictionary = {}
var pollen_count := 0
var decoration_count := 0

func _ready() -> void:
	_build_garden()
	bee.defeated.connect(func():
		$CanvasLayer/Status.text = "PLAYER DOWN — PRESS R TO RESTART"
		for enemy in $Enemies.get_children(): enemy.set_physics_process(false))
	for pickup in $Pollen.get_children():
		pickup.collected.connect(func(_p: BeePollenPickup, _heal: int): pollen_count += 1)

func _process(_delta: float) -> void:
	if bee.is_defeated:
		if Input.is_action_just_pressed("restart"): get_tree().reload_current_scene()
		return
	if bee.position.x >= -7.0: $Enemies/Wasp.activate(bee)
	if bee.position.x >= 4.0: $Enemies/Probe.activate(bee)
	$CanvasLayer/Status.text = "JARDÍN · POLEN %d/3 · Z melee · X disparo" % pollen_count

func material(key: String, color: Color) -> StandardMaterial3D:
	if not materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 1.0
		materials[key] = mat
	return materials[key]

func piece(kind: String, key: String, color: Color, pos: Vector3, size: Vector3, tilt := 0.0) -> MeshInstance3D:
	var mesh_key := kind + key
	if not meshes.has(mesh_key):
		var mesh: PrimitiveMesh
		match kind:
			"stem":
				var cylinder := CylinderMesh.new()
				cylinder.top_radius = 0.38
				cylinder.bottom_radius = 0.5
				cylinder.height = 1.0
				cylinder.radial_segments = 7
				mesh = cylinder
			"box": mesh = BoxMesh.new()
			_:
				var sphere := SphereMesh.new()
				sphere.radius = 0.5
				sphere.height = 1.0
				sphere.radial_segments = 8
				sphere.rings = 3
				mesh = sphere
		mesh.material = material(key,color)
		meshes[mesh_key] = mesh
	var item := MeshInstance3D.new()
	item.mesh = meshes[mesh_key]
	$Scenery.add_child(item)
	item.position = pos
	item.scale = size
	item.rotation.z = tilt
	decoration_count += 1
	return item

func flower(x: float, height: float, z: float, color: Color, key: String, lean: float) -> void:
	piece("stem","stem",Color(0.18,0.32,0.13),Vector3(x,height/2,z),Vector3(0.3,height,0.3),lean)
	for side in [-1,1]:
		piece("leaf","leaf",Color(0.24,0.40,0.16),Vector3(x+side*0.65,height*0.48,z),Vector3(1.7,0.55,0.40),side*0.45)
	# Broad heads, 2–3 m across, compared with the 0.98 m bee.
	for i in 5:
		var angle := i*TAU/5.0 + lean
		piece("petal",key,color,Vector3(x+cos(angle)*0.83,height+sin(angle)*0.55,z),Vector3(1.45,1.1,0.5),angle)
	piece("petal","center",Color(0.64,0.43,0.09),Vector3(x,height,z+0.27),Vector3(0.85,0.85,0.45))

func _build_garden() -> void:
	# Background stays muted; negative Z is behind the flight plane.
	piece("box","distantsoil",Color(0.38,0.44,0.28),Vector3(0,-0.55,-9),Vector3(55,1,8))
	for x in [-10,12]:
		piece("stem","fartrunk",Color(0.40,0.40,0.30),Vector3(x,5,-10),Vector3(1,10,1))
		piece("leaf","farcanopy",Color(0.37,0.48,0.35),Vector3(x,10,-10),Vector3(8,6,4))
	for x in [-10,-8,3]:
		flower(x,2.0,-3.0,Color(0.72,0.34,0.43),"rose",0.16)
	for i in 16:
		var x := -15.0+i*2.0
		piece("leaf","grass",Color(0.20,0.32,0.12),Vector3(x,1.1,-1.8),Vector3(0.38,2.8+float(i%3)*0.6,0.25),0.22 if i%2==0 else -0.17)
	for x in [-13,-6,2,9]:
		piece("rock","stone",Color(0.39,0.38,0.32),Vector3(x,0.35,0),Vector3(1.8,0.9,1.3),0.18)
	# Sparse low foreground leaves, below the combat corridor.
	for x in [-14,0,13]:
		piece("leaf","foreground",Color(0.13,0.25,0.10),Vector3(x,0.4,2.5),Vector3(2.3,0.6,0.4),0.3)
	# Fallen log presentation and its manual box collider are separate.
	# Giant bottle replaces the pot; retain the proxy orange tree behind it.
	piece("stem","bark",Color(0.30,0.19,0.09),Vector3(12.5,6.2,-4.7),Vector3(1.1,12.4,1.1),-0.05)
	for side in [-1,1]:
		piece("stem","bark",Color(0.30,0.19,0.09),Vector3(12.5+side*1.4,8.6,-4.7),Vector3(0.55,5,0.55),side*0.7)
	for x in [9,12,15]:
		piece("leaf","canopy",Color(0.22,0.36,0.15),Vector3(x,10,-4.7),Vector3(6,4.3,4))
	for i in 7:
		piece("fruit","orange",Color(0.86,0.39,0.06),Vector3(9.5+i*0.9,7.5+float(i%3)*0.5,-2.7),Vector3(0.85,0.85,0.85))


