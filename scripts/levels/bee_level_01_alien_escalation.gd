class_name BeeLevel01AlienEscalation
extends Node3D
## LEVEL 01 TRANSFORMATION PASS 01 — PHASE D: the invasion advances through the scenery.
##   * Before the checkpoint nature dominates (no alien dressing). After it, small alien pylons appear behind the
##     flight plane, a few more as the sunset deepens; their cyan glow reads more at dusk. Never a neon field.
##   * CONTAMINATED GARDEN (director moment "contaminated_garden", X~262): one big flower wrapped in dark alien plates,
##     pulsing cyan/violet nodes and thin tendrils. A small CONTROL DEVICE in the flight plane can be shot: the glow
##     dies, the flower recovers its colour, particles; no drop, no new system (HealthComponent + Hurtbox3D).
##   * THE LAST SILENCE (director moment "last_silence", before the UFO): light and ambience dip, a low hum rises and
##     a huge UFO shadow sweeps the garden. Then the existing UFO reveal, unchanged.
## Visual alien language shared with the UFO and the dragonfly implant: dark shell, cyan core, violet accents.

const ALIEN_SHELL := BeeAlienPalette.SHELL
const ALIEN_CYAN := BeeAlienPalette.CYAN
const ALIEN_VIOLET := BeeAlienPalette.VIOLET
const FLOWER_X := 266.0
const FLOWER_Z := -2.4
const DEVICE_HP := 30
## Alien pylons after the checkpoint: [X, z, scale]. Sparse first, a little denser towards the sunset.
const PYLONS := [[214.0, -6.5, 0.8], [236.0, -5.2, 0.9], [251.0, -7.0, 1.0], [271.0, -5.8, 1.1], [289.0, -6.6, 1.0],
		[304.0, -5.0, 1.15], [318.0, -6.2, 1.2], [331.0, -5.4, 1.25], [349.0, -6.8, 1.3]]
const HEALTH_SCENE := preload("res://scenes/components/health_component.tscn")
const HURTBOX_SCENE := preload("res://scenes/components/hurtbox_3d.tscn")
const FLASH_SCENE := preload("res://scenes/components/hit_flash_3d.tscn")
const HOVER_STREAM := "res://audio/sfx/real/ufo_hover.wav" # Approved (Kenney spaceEngineLow), already used by the UFO.

@export var stage_path: NodePath = ^".."

var stage: BeeShmupStage
var pylons: Array[Node3D] = []
var flower: Node3D
var device: Node3D
var device_health: HealthComponent
var device_hurtbox: DamageHurtbox3D
var flower_freed := false
var silence_played := false
var ufo_shadow: MeshInstance3D
var hum: AudioStreamPlayer
var _glow: Array[ShaderMaterial] = []
var _petals: Array[ShaderMaterial] = []
var _clock := 0.0


func _ready() -> void:
	stage = get_node(stage_path) as BeeShmupStage
	for entry in PYLONS:
		pylons.append(_pylon(float(entry[0]), float(entry[1]), float(entry[2])))
	_build_contaminated_flower()
	var wave := stage.get_node("WaveController")
	if wave.has_signal("director_moment"):
		wave.director_moment.connect(_on_moment)


func _on_moment(id: StringName) -> void:
	if id == &"contaminated_garden":
		_garden_reveal()
	elif id == &"last_silence":
		_last_silence()


func _process(delta: float) -> void:
	_clock += delta
	var pulse := 1.0 + 0.4 * sin(_clock * 3.2)
	for material in _glow:
		material.set_shader_parameter("emission_energy", minf(float(material.get_meta("base_energy")) * pulse, BeeAlienPalette.MAX_EMISSION * 1.2))


# --- alien dressing --------------------------------------------------------------------------------------

func _alien_material(color: Color, glow: bool, energy := 2.0) -> StandardMaterial3D:
	var material := GardenProps.flat(color)
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = energy
	return material


func _mesh(parent: Node3D, label: String, mesh: PrimitiveMesh, material: StandardMaterial3D, at: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	mesh.material = material
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.position = at
	node.rotation = rot
	parent.add_child(node)
	return node


## Own copies of the glowing materials so the pulse never touches the UFO, Bee or the dragonfly.
func _own_glow(root: Node3D) -> void:
	for node: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if not node.has_meta("glow"):
			continue
		var shared := node.get_surface_override_material(0) as ShaderMaterial
		if shared == null:
			continue
		var own := shared.duplicate() as ShaderMaterial
		own.set_meta("base_energy", own.get_shader_parameter("emission_energy"))
		node.set_surface_override_material(0, own)
		_glow.append(own)


func _pylon(x: float, z: float, size: float) -> Node3D:
	var pylon := Node3D.new()
	pylon.name = "AlienPylon%d" % int(x)
	add_child(pylon)
	pylon.position = Vector3(x, -0.1, z)
	pylon.scale = Vector3.ONE * size
	var column := CylinderMesh.new()
	column.top_radius = 0.16
	column.bottom_radius = 0.34
	column.height = 1.8
	column.radial_segments = 6
	_mesh(pylon, "Column", column, _alien_material(ALIEN_SHELL, false), Vector3(0, 0.9, 0))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.22
	ring.outer_radius = 0.3
	ring.rings = 12
	ring.ring_segments = 4
	_mesh(pylon, "Ring", ring, _alien_material(ALIEN_CYAN, true, 1.6), Vector3(0, 1.25, 0)).set_meta("glow", true)
	var tip := SphereMesh.new()
	tip.radius = 0.1
	tip.height = 0.2
	_mesh(pylon, "Tip", tip, _alien_material(ALIEN_VIOLET, true, 1.4), Vector3(0, 1.88, 0)).set_meta("glow", true)
	BeeToonStyle.apply(pylon, true)
	_own_glow(pylon)
	return pylon


# --- the contaminated garden ---------------------------------------------------------------------------------

func _build_contaminated_flower() -> void:
	flower = Node3D.new()
	flower.name = "ContaminatedFlower"
	add_child(flower)
	flower.position = Vector3(FLOWER_X, -0.1, FLOWER_Z)
	var stem := CylinderMesh.new()
	stem.top_radius = 0.09
	stem.bottom_radius = 0.14
	stem.height = 4.6
	stem.radial_segments = 8
	_mesh(flower, "Stem", stem, GardenProps.flat(Color(0.26, 0.42, 0.18)), Vector3(0, 2.3, 0))
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 4.6, 0.2)
	head.rotation.x = 0.9 # The corolla faces the camera.
	flower.add_child(head)
	for i in 8:
		var angle := TAU * float(i) / 8.0
		var petal := SphereMesh.new()
		petal.radius = 0.42
		petal.height = 0.18
		petal.radial_segments = 10
		petal.rings = 4
		var node := _mesh(head, "Petal%d" % i, petal, GardenProps.flat(Color(0.93, 0.58, 0.72)), Vector3(cos(angle) * 0.62, 0, sin(angle) * 0.62))
		node.scale = Vector3(1.0, 1.0, 0.55)
		node.rotation.y = -angle
		node.set_meta("petal", true)
	var center := SphereMesh.new()
	center.radius = 0.32
	center.height = 0.3
	_mesh(head, "Center", center, GardenProps.flat(Color(0.95, 0.72, 0.2)), Vector3(0, 0.08, 0))
	# The alien grip: dark plates up the stem, tendrils into the corolla, pulsing nodes.
	for i in 4:
		var plate := BoxMesh.new()
		plate.size = Vector3(0.36, 0.26, 0.36)
		_mesh(flower, "Plate%d" % i, plate, _alien_material(ALIEN_SHELL, false), Vector3(0, 0.8 + float(i) * 0.85, 0), Vector3(0, float(i) * 0.6, 0.0))
		var node_mesh := SphereMesh.new()
		node_mesh.radius = 0.09
		node_mesh.height = 0.18
		_mesh(flower, "Node%d" % i, node_mesh, _alien_material(ALIEN_CYAN if i % 2 == 0 else ALIEN_VIOLET, true, BeeAlienPalette.MAX_EMISSION), Vector3(0.2, 0.86 + float(i) * 0.85, 0.12)).set_meta("glow", true)
	for i in 3:
		var tendril := CylinderMesh.new()
		tendril.top_radius = 0.02
		tendril.bottom_radius = 0.045
		tendril.height = 1.3
		tendril.radial_segments = 5
		var side := float(i) - 1.0
		_mesh(flower, "Tendril%d" % i, tendril, _alien_material(ALIEN_VIOLET, true, 1.2), Vector3(side * 0.3, 4.1, 0.1), Vector3(0.0, 0.0, side * 0.55)).set_meta("glow", true)
	# The control device sits in Bee's plane, low, small but readable; it can be shot (no drop).
	device = Node3D.new()
	device.name = "ControlDevice"
	add_child(device)
	device.position = Vector3(FLOWER_X - 1.4, 1.05, 0.0)
	var shell := BoxMesh.new()
	shell.size = Vector3(0.44, 0.3, 0.3)
	_mesh(device, "Shell", shell, _alien_material(ALIEN_SHELL, false), Vector3.ZERO)
	var core := SphereMesh.new()
	core.radius = 0.13
	core.height = 0.26
	_mesh(device, "Core", core, _alien_material(ALIEN_CYAN, true, BeeAlienPalette.MAX_EMISSION), Vector3(0, 0.14, 0)).set_meta("glow", true)
	var cable := CylinderMesh.new()
	cable.top_radius = 0.025
	cable.bottom_radius = 0.025
	cable.height = 2.6
	cable.radial_segments = 4
	_mesh(device, "Cable", cable, _alien_material(ALIEN_VIOLET, true, 1.0), Vector3(0.8, -0.2, -1.1), Vector3(-0.9, 0.0, -1.0)).set_meta("glow", true)
	BeeToonStyle.apply(flower, true)
	BeeToonStyle.apply(device, true, BeeToonStyle.OUTLINE_ACTOR) # A target: drawn like the actors.
	_own_glow(flower)
	_own_glow(device)
	for node: MeshInstance3D in flower.find_children("*", "MeshInstance3D", true, false):
		if node.has_meta("petal"):
			var own := (node.get_surface_override_material(0) as ShaderMaterial).duplicate() as ShaderMaterial
			own.set_shader_parameter("albedo", Color(0.93, 0.58, 0.72).lerp(Color(0.34, 0.28, 0.42), 0.78)) # Drained, violet-grey.
			node.set_surface_override_material(0, own)
			_petals.append(own)
	device_health = HEALTH_SCENE.instantiate() as HealthComponent
	device_health.name = "HealthComponent"
	device_health.max_health = DEVICE_HP
	device.add_child(device_health)
	var flash := FLASH_SCENE.instantiate() as HitFlash3D
	flash.visual_root_path = ^".."
	device.add_child(flash)
	device_hurtbox = HURTBOX_SCENE.instantiate() as DamageHurtbox3D
	device_hurtbox.name = "Hurtbox3D"
	device_hurtbox.team_id = &"alien" # Enemy fire ignores it.
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var sphere := SphereShape3D.new()
	sphere.radius = 0.38
	shape.shape = sphere
	device_hurtbox.add_child(shape)
	device.add_child(device_hurtbox)
	device_health.died.connect(_free_flower)


func _garden_reveal() -> void:
	if flower_freed:
		return
	BeeCombatVFX.spawn(self, device.global_position + Vector3(0, 0.2, 0), &"pickup", Vector3.UP, 0.8)


func _free_flower() -> void:
	if flower_freed:
		return
	flower_freed = true
	device_hurtbox.set_deferred("monitorable", false)
	BeeCombatVFX.spawn(self, device.global_position, &"tech_death", Vector3.UP, 0.6)
	BeeAudio.play(self, &"tech_death", device.global_position)
	for material in _glow.duplicate():
		if _is_part_of(material, flower) or _is_part_of(material, device):
			_glow.erase(material)
			material.set_shader_parameter("emission_energy", 0.0)
	var drop := device.create_tween()
	drop.tween_property(device, "position:y", 0.2, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop.tween_callback(device.hide)
	for material in _petals:
		var recover := create_tween()
		recover.tween_method(func(c: Color): material.set_shader_parameter("albedo", c), material.get_shader_parameter("albedo"), Color(0.93, 0.58, 0.72), 0.8)
	BeeCombatVFX.spawn(self, flower.global_position + Vector3(0, 4.6, 0.4), &"pollen", Vector3.UP, 1.4)


func _is_part_of(material: ShaderMaterial, root: Node3D) -> bool:
	for node: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if node.get_surface_override_material(0) == material:
			return true
	return false


# --- the last silence -------------------------------------------------------------------------------------------

func _last_silence() -> void:
	if silence_played:
		return
	silence_played = true
	var sun := stage.get_node("Sun") as DirectionalLight3D
	var environment := (stage.get_node("WorldEnvironment") as WorldEnvironment).environment
	var sun_energy := sun.light_energy
	var ambient_energy := environment.ambient_light_energy
	var dim := create_tween()
	dim.tween_property(sun, "light_energy", sun_energy * 0.62, 1.4)
	dim.parallel().tween_property(environment, "ambient_light_energy", ambient_energy * 0.78, 1.4)
	# The light comes back with the reveal: the boss fight keeps the usual sunset readability.
	dim.tween_interval(3.0)
	dim.tween_property(sun, "light_energy", sun_energy, 1.6)
	dim.parallel().tween_property(environment, "ambient_light_energy", ambient_energy, 1.6)
	# The shadow of something enormous crosses the garden from right to left.
	ufo_shadow = MeshInstance3D.new()
	ufo_shadow.name = "UfoShadow"
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.01
	disc.radial_segments = 24
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.03, 0.02, 0.06, 0.55)
	disc.material = material
	ufo_shadow.mesh = disc
	ufo_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ufo_shadow)
	var camera_x := stage.camera.global_position.x
	ufo_shadow.scale = Vector3(7.0, 1.0, 2.6)
	ufo_shadow.global_position = Vector3(camera_x + 14.0, -0.08, -1.5)
	var sweep := ufo_shadow.create_tween()
	sweep.tween_property(ufo_shadow, "global_position:x", camera_x - 16.0, 2.2).set_trans(Tween.TRANS_SINE)
	sweep.tween_callback(ufo_shadow.queue_free)
	# A low engine hum rises (the same approved loop the UFO uses), then the boss takes over its own sound.
	hum = AudioStreamPlayer.new()
	hum.name = "SilenceHum"
	hum.stream = load(HOVER_STREAM)
	hum.bus = &"SFX"
	hum.volume_db = -34.0
	add_child(hum)
	hum.play()
	var swell := hum.create_tween()
	swell.tween_property(hum, "volume_db", -20.0, 1.8)
	swell.tween_property(hum, "volume_db", -40.0, 1.0)
	swell.tween_callback(hum.queue_free)
