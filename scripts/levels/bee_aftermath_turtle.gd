class_name BeeAftermathTurtle
extends Node3D
## NOCHE 01 — the garden turtle of the "human aftermath" moment, rebuilt (it read as a grey blob with a cyan eye):
##   domed shell covered with HEXAGONAL plates (two warm greens / ochre, dark rims), a skin-coloured head with a dark eye
##   and a light catch-light, four stubby legs, a short tail. Toon + outline + rim like every creature (BeeToonStyle).
##   Alien implant (cyan, the shared WaspImplant) on the shell: one shot breaks it -> the turtle is FREED (BeeLiberation),
##   walks off relaxed and counts in "LIBERADOS n/N". It never attacks and has no contact damage.
## Looks along +X in its own space; the moment rotates it to walk towards -X (it faces where it walks).

signal liberated_now(turtle: BeeAftermathTurtle)

const SHELL := Color(0.24, 0.32, 0.15)
const PLATE_A := Color(0.52, 0.6, 0.26)
const PLATE_B := Color(0.7, 0.56, 0.24)
const RIM := Color(0.2, 0.22, 0.12)
const SKIN := Color(0.66, 0.68, 0.4)
const EYE := Color(0.08, 0.07, 0.05)
const SHELL_RADII := Vector3(0.62, 0.38, 0.5)
const PLATE_RADIUS := 0.17
const IMPLANT_HP := 20
const HEALTH_SCENE := preload("res://scenes/components/health_component.tscn")
const HURTBOX_SCENE := preload("res://scenes/components/hurtbox_3d.tscn")

var body: Node3D
var legs: Array[Node3D] = []
var implant: WaspImplant
var health: HealthComponent
var hurtbox: DamageHurtbox3D
var liberated := false
var plates := 0


func _init() -> void:
	name = "AftermathTurtle"
	body = Node3D.new()
	body.name = "Body"
	add_child(body)
	_build_shell()
	_build_head()
	for spec in [[0.36, 0.28], [0.36, -0.28], [-0.36, 0.28], [-0.36, -0.28]]:
		var leg := _part(self, "Leg", _capsule(0.08, 0.26), SKIN, Vector3(float(spec[0]), 0.13, float(spec[1])))
		leg.rotation.z = 0.15 * signf(float(spec[0]))
		legs.append(leg)
	var tail := _part(body, "Tail", _cone(0.06, 0.2), SKIN, Vector3(-0.66, 0.2, 0.0))
	tail.rotation.z = PI * 0.5 + 0.3
	set_meta("legs", legs)


func _ready() -> void:
	BeeToonStyle.apply(self, true, BeeToonStyle.OUTLINE_ACTOR)
	implant = WaspImplant.new()
	implant.name = "Implant"
	implant.position = Vector3(-0.05, SHELL_RADII.y + 0.27, 0.14) # On top of the shell, slightly towards the camera.
	body.add_child(implant)
	health = HEALTH_SCENE.instantiate() as HealthComponent
	health.name = "HealthComponent"
	health.max_health = IMPLANT_HP
	add_child(health)
	hurtbox = HURTBOX_SCENE.instantiate() as DamageHurtbox3D
	hurtbox.name = "Hurtbox3D"
	hurtbox.team_id = &"alien"
	hurtbox.health_component_path = NodePath("../HealthComponent")
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.45
	shape.shape = sphere
	shape.position = implant.position
	hurtbox.add_child(shape)
	add_child(hurtbox)
	health.died.connect(_liberate)
	add_to_group("bee_auto_aim_targets")


func is_active() -> bool:
	return not liberated


func _liberate() -> void:
	if liberated:
		return
	liberated = true
	remove_from_group("bee_auto_aim_targets")
	hurtbox.set_deferred("monitorable", false)
	add_to_group("bee_liberated")
	implant.set_mode(&"off")
	BeeLiberation.free_animal(get_parent(), self, implant, implant.global_position)
	liberated_now.emit(self)


# --- model ------------------------------------------------------------------------------------------------------

func _build_shell() -> void:
	var dome := MeshInstance3D.new()
	dome.name = "Shell"
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 1.0 # Hemisphere: the dome spans y 0..1 before scaling (2.0 doubled it and buried the plates).
	sphere.radial_segments = 16
	sphere.rings = 8
	sphere.is_hemisphere = true
	sphere.material = GardenProps.flat(SHELL)
	dome.mesh = sphere
	dome.scale = SHELL_RADII
	dome.position = Vector3(0.0, 0.2, 0.0)
	body.add_child(dome)
	var skirt := _part(body, "ShellRim", _disc(1.0, 0.06), RIM, Vector3(0.0, 0.2, 0.0))
	skirt.scale = Vector3(SHELL_RADII.x + 0.05, 1.0, SHELL_RADII.z + 0.05)
	# Hexagonal plates on the dome: a crown plate plus two rings, each oriented along the dome's normal.
	var rows := [[1.4, 1, 0.0], [0.92, 6, 0.0], [0.42, 9, 0.31]]
	for row in rows:
		var phi := float(row[0])
		var count := int(row[1])
		for i in count:
			var theta := TAU * float(i) / float(count) + float(row[2])
			var p := Vector3(SHELL_RADII.x * cos(phi) * cos(theta), SHELL_RADII.y * sin(phi), SHELL_RADII.z * cos(phi) * sin(theta))
			var normal := Vector3(p.x / (SHELL_RADII.x * SHELL_RADII.x), p.y / (SHELL_RADII.y * SHELL_RADII.y), p.z / (SHELL_RADII.z * SHELL_RADII.z)).normalized()
			var plate := _part(body, "Plate%d" % plates, _hex(PLATE_RADIUS, 0.07), PLATE_A if (plates % 2 == 0) else PLATE_B, p + Vector3(0.0, 0.2, 0.0) + normal * 0.045)
			plate.basis = Basis(Quaternion(Vector3.UP, normal))
			var rim := _part(plate, "Rim", _hex(PLATE_RADIUS * 1.12, 0.03), RIM, Vector3(0.0, -0.012, 0.0))
			rim.name = "Rim"
			plates += 1


func _build_head() -> void:
	var neck := _part(body, "Neck", _capsule(0.09, 0.26), SKIN, Vector3(0.62, 0.26, 0.0))
	neck.rotation.z = -PI * 0.5 + 0.35
	var head := _part(body, "Head", _ellipsoid(Vector3(0.17, 0.13, 0.13)), SKIN, Vector3(0.82, 0.36, 0.0))
	for side in [-1.0, 1.0]: # One eye per side: the side camera always sees one.
		_part(head, "Eye", _ellipsoid(Vector3(0.045, 0.05, 0.03)), EYE, Vector3(0.07, 0.04, 0.1 * side))
		_part(head, "EyeLight", _ellipsoid(Vector3(0.014, 0.014, 0.01)), Color(1, 1, 0.95), Vector3(0.09, 0.06, 0.125 * side))
	_part(head, "Beak", _ellipsoid(Vector3(0.06, 0.04, 0.07)), SKIN.darkened(0.25), Vector3(0.15, -0.03, 0.0))


func _part(parent: Node3D, label: String, mesh: PrimitiveMesh, color: Color, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	mesh.material = GardenProps.flat(color)
	node.mesh = mesh
	node.position = at
	parent.add_child(node)
	return node


static func _hex(radius: float, height: float) -> CylinderMesh:
	var hex := CylinderMesh.new()
	hex.top_radius = radius
	hex.bottom_radius = radius
	hex.height = height
	hex.radial_segments = 6
	hex.rings = 1
	return hex


static func _disc(radius: float, height: float) -> CylinderMesh:
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = height
	disc.radial_segments = 18
	disc.rings = 1
	return disc


static func _capsule(radius: float, height: float) -> CapsuleMesh:
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height
	capsule.radial_segments = 8
	capsule.rings = 3
	return capsule


static func _cone(radius: float, height: float) -> CylinderMesh:
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = radius
	cone.height = height
	cone.radial_segments = 6
	return cone


static func _ellipsoid(radii: Vector3) -> SphereMesh:
	var sphere := SphereMesh.new()
	sphere.radius = maxf(radii.x, radii.z)
	sphere.height = radii.y * 2.0
	sphere.radial_segments = 12
	sphere.rings = 6
	return sphere
