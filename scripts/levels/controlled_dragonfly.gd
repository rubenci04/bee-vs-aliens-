class_name ControlledDragonfly
extends Node3D
## LEVEL 01 TRANSFORMATION PASS 01 — CONTROLLED FAUNA: a dragonfly driven by an alien implant.
## The animal is never the target: only the CONTROL DEVICE on its thorax has health. Shots on the body are absorbed
## with a neutral puff (no damage, no "animal HP"). Breaking the implant LIBERATES the dragonfly: the attack is
## cancelled at once, the device cracks off, the alien glow dies, natural colours return, the flight loosens, it loops
## and flies away. No corpse, no explosion of the animal.
##   ENTER -> HOVER (rigid, controlled) -> TELEGRAPH (wings flare, implant flares) -> PASS (broad, locked, no homing)
##   -> RECOVERY -> REPOSITION -> ... (3 passes) -> EXIT (still controlled)    |   any time: implant broken -> LIBERATED
## Built in code (Style C, no external asset), like the UFO.

signal defeated(enemy: ControlledDragonfly)
## Emitted the moment the implant breaks: the animal is no longer a threat (it still flies away before `defeated`).
signal liberated_now(enemy: ControlledDragonfly)

enum State { IDLE, ENTER, HOVER, TELEGRAPH, PASS, RECOVERY, REPOSITION, EXIT, LIBERATED, DONE }

@export var implant_hp := 60
@export var hover_distance := 4.6
@export var hover_time := 1.6
@export var telegraph_time := 0.75
@export var pass_time := 1.15
@export var recovery_time := 0.8
@export var reposition_speed := 4.2
@export var max_passes := 3
@export var contact_damage := 13
@export var liberation_seconds := 2.4

const NATURAL := {"thorax": Color(0.16, 0.52, 0.46), "head": Color(0.2, 0.56, 0.42), "eyes": Color(0.08, 0.26, 0.2), "abdomen": Color(0.16, 0.4, 0.74)}
const CONTROLLED_TINT := Color(0.42, 0.36, 0.52) # Desaturated violet-grey while controlled.
const IMPLANT_SHELL := Color(0.09, 0.09, 0.12)
const IMPLANT_CORE := Color(0.25, 0.95, 1.0)
const IMPLANT_VIOLET := Color(0.72, 0.32, 1.0)
const HEALTH_SCENE := preload("res://scenes/components/health_component.tscn")
const HURTBOX_SCENE := preload("res://scenes/components/hurtbox_3d.tscn")
const HITBOX_SCENE := preload("res://scenes/components/hitbox_3d.tscn")
const FLASH_SCENE := preload("res://scenes/components/hit_flash_3d.tscn")

var target: BeePlayer
var state := State.IDLE
var passes_done := 0
var liberated := false
var visual_root: Node3D
var health: HealthComponent        # The implant's health (the only damageable thing).
var hurtbox: DamageHurtbox3D       # On the implant; auto-aim aims here ("Hurtbox3D").
var body_shield: DamageHurtbox3D   # Absorbs shots on the animal body with neutral feedback.
var pass_hitbox: DamageHitbox3D
var implant: Node3D
var body_absorbed := 0
var _body_health: HealthComponent
var _wings: Array[Node3D] = []
var _body_materials: Dictionary = {} # part -> ShaderMaterial (own copies, tinted)
var _core_material: ShaderMaterial
var _state_left := 0.0
var _clock := 0.0
var _pass_from := Vector3.ZERO
var _pass_to := Vector3.ZERO
var _pass_arc := 0.0
var _facing := -1.0


func _ready() -> void:
	add_to_group("bee_auto_aim_targets")
	add_to_group("controlled_fauna")
	_build_visual()
	health = HEALTH_SCENE.instantiate() as HealthComponent
	health.name = "HealthComponent"
	health.max_health = implant_hp
	add_child(health)
	var flash := FLASH_SCENE.instantiate() as HitFlash3D
	flash.name = "HitFlash3D"
	flash.visual_root_path = ^"../VisualRoot/Body/Implant"
	add_child(flash)
	hurtbox = _make_hurtbox("Hurtbox3D", 0.5, health)
	_body_health = HEALTH_SCENE.instantiate() as HealthComponent
	_body_health.name = "BodyHealth"
	_body_health.max_health = 1000000
	add_child(_body_health)
	body_shield = _make_hurtbox("BodyShield", 0.0, _body_health)
	body_shield.set_meta("neutral_hit", true)
	_body_health.health_changed.connect(_on_body_hit)
	pass_hitbox = HITBOX_SCENE.instantiate() as DamageHitbox3D
	pass_hitbox.name = "PassHitbox"
	pass_hitbox.team_id = &"alien"
	pass_hitbox.damage = contact_damage
	var pass_shape := CollisionShape3D.new()
	pass_shape.name = "CollisionShape3D"
	var sphere := SphereShape3D.new()
	sphere.radius = 0.62
	pass_shape.shape = sphere
	pass_hitbox.add_child(pass_shape)
	add_child(pass_hitbox)
	pass_hitbox.set_enabled(false)
	health.died.connect(_liberate)
	hide()
	set_physics_process(false)


func _make_hurtbox(label: String, radius: float, source: HealthComponent) -> DamageHurtbox3D:
	var area := HURTBOX_SCENE.instantiate() as DamageHurtbox3D
	area.name = label
	area.team_id = &"alien"
	area.health_component_path = NodePath("../" + str(source.name))
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	if radius > 0.0:
		var sphere := SphereShape3D.new()
		sphere.radius = radius # Generous: the device is ~0.35 m, the hurtbox 0.5 m (no pixel hunting).
		shape.shape = sphere
	else:
		var capsule := CapsuleShape3D.new() # Only the long abdomen behind the implant: shots at the head reach the implant.
		capsule.radius = 0.24
		capsule.height = 1.6
		shape.shape = capsule
		shape.rotation.z = PI * 0.5
		shape.position = Vector3(1.3, -0.05, 0.0)
	area.add_child(shape)
	if radius > 0.0:
		add_child(area)
	else:
		# The abdomen absorber turns with the animal (VisualRoot flips with the facing).
		area.health_component_path = NodePath("../../" + str(source.name))
		area.owner_entity_path = NodePath("../..")
		visual_root.add_child(area)
	return area


func activate(new_target: BeePlayer) -> bool:
	if state != State.IDLE or new_target == null:
		return false
	target = new_target
	state = State.ENTER
	show()
	set_physics_process(true)
	return true


func is_active() -> bool:
	return state != State.IDLE and not liberated and state != State.DONE


func is_defeated() -> bool:
	return liberated


func _physics_process(delta: float) -> void:
	_clock += delta
	_animate_wings(delta)
	if liberated or target == null:
		return
	var camera := get_viewport().get_camera_3d()
	var camera_x := camera.global_position.x if camera != null else global_position.x
	var hover := Vector3(minf(target.global_position.x + hover_distance, camera_x + 5.0), clampf(target.global_position.y + 0.6, 1.6, 6.0), 0.0)
	match state:
		State.ENTER:
			global_position = global_position.move_toward(hover, 5.5 * delta)
			if global_position.distance_to(hover) < 0.3:
				_begin(State.HOVER, hover_time)
		State.HOVER:
			# Controlled hover: rigid and mechanical (no natural bob), slowly tracking Bee's height.
			global_position = global_position.move_toward(hover, 2.2 * delta)
			_tick_to(State.TELEGRAPH, telegraph_time, delta)
			if state == State.TELEGRAPH:
				_lock_pass()
		State.TELEGRAPH:
			var flare := 1.0 + 0.35 * sin(minf(1.0 - _state_left / telegraph_time, 1.0) * PI)
			for wing in _wings:
				wing.scale = Vector3(1.0, 1.0, flare)
			_set_core(1.0 + 1.8 * (1.0 - _state_left / telegraph_time))
			_tick_to(State.PASS, pass_time, delta)
			if state == State.PASS:
				for wing in _wings:
					wing.scale = Vector3.ONE
				pass_hitbox.set_enabled(true)
				passes_done += 1
		State.PASS:
			var t := clampf(1.0 - _state_left / pass_time, 0.0, 1.0)
			var eased := t * t * (3.0 - 2.0 * t)
			global_position = _pass_from.lerp(_pass_to, eased) + Vector3(0.0, sin(t * PI) * _pass_arc, 0.0)
			_tick_to(State.RECOVERY, recovery_time, delta)
			if state == State.RECOVERY:
				pass_hitbox.set_enabled(false)
				_set_core(1.0)
		State.RECOVERY:
			_tick_to(State.REPOSITION, 0.0, delta)
		State.REPOSITION:
			if passes_done >= max_passes:
				_begin(State.EXIT, 0.0)
			else:
				var lifted := hover + Vector3(0.0, 0.8, 0.0)
				global_position = global_position.move_toward(lifted, reposition_speed * delta)
				if global_position.distance_to(lifted) < 0.35:
					_begin(State.HOVER, hover_time * 0.75)
		State.EXIT:
			global_position.x -= 5.0 * delta
	_update_facing()


func _begin(next: int, seconds: float) -> void:
	state = next
	_state_left = seconds


func _tick_to(next: int, next_seconds: float, delta: float) -> void:
	_state_left -= delta
	if _state_left <= 0.0:
		_begin(next, next_seconds)


## The pass is locked when the telegraph starts: a broad, readable sweep through where Bee was, no homing.
func _lock_pass() -> void:
	_pass_from = global_position
	var through := target.global_position
	var direction := (through - _pass_from)
	direction.z = 0.0
	direction = direction.normalized() if direction.length() > 0.01 else Vector3.LEFT
	_pass_to = through + direction * 3.2
	_pass_to.y = clampf(_pass_to.y, 1.0, 6.4)
	_pass_arc = -1.1 if through.y > 3.6 else 1.1 # Swoops away from the nearest edge.


func _update_facing() -> void:
	var dx := 0.0
	if state == State.PASS or state == State.TELEGRAPH:
		dx = _pass_to.x - _pass_from.x
	elif target != null:
		dx = target.global_position.x - global_position.x
	if absf(dx) > 0.1:
		_facing = signf(dx)
	visual_root.rotation.y = 0.0 if _facing < 0.0 else PI


func _animate_wings(delta: float) -> void:
	var rate := 18.0 if liberated else 28.0 # Controlled: stiff, mechanical beat. Free: looser.
	for i in _wings.size():
		var phase := 0.0 if i < 2 else 0.9
		_wings[i].rotation.x = sin(_clock * rate + phase) * (0.55 if liberated else 0.32) * (1.0 if i % 2 == 0 else -1.0)
	if _core_material != null and not liberated and state != State.TELEGRAPH:
		_set_core(1.0 + 0.35 * sin(_clock * 6.0))


func _set_core(multiplier: float) -> void:
	if _core_material != null:
		_core_material.set_shader_parameter("emission_energy", 2.2 * multiplier)


func _on_body_hit(_current: int, _maximum: int, change: int) -> void:
	if change < 0:
		body_absorbed += 1
		_body_health.current_health = _body_health.max_health # The animal is never hurt.


# --- liberation -------------------------------------------------------------------------------------------

func _liberate() -> void:
	if liberated:
		return
	liberated = true
	state = State.LIBERATED
	liberated_now.emit(self)
	pass_hitbox.set_enabled(false)
	remove_from_group("bee_auto_aim_targets")
	hurtbox.set_deferred("monitorable", false)
	body_shield.set_deferred("monitorable", false)
	var at := implant.global_position
	BeeCombatVFX.spawn(get_parent(), at, &"tech_death", Vector3.UP, 0.6)
	BeeAudio.play(get_parent(), &"tech_death", at)
	BeeAudio.play(get_parent(), &"pollen", at, 1.1)
	# The device cracks off and falls; the glow dies.
	_set_core(0.0)
	var device := implant.create_tween().set_parallel(true)
	device.tween_property(implant, "position", implant.position + Vector3(0.0, 0.5, 0.6), 0.25)
	device.tween_property(implant, "scale", Vector3.ONE * 0.2, 0.6).set_delay(0.2)
	device.chain().tween_callback(implant.hide)
	# Natural colours return.
	for part in _body_materials:
		var material: ShaderMaterial = _body_materials[part]
		var colour_tween := create_tween()
		colour_tween.tween_method(func(c: Color): material.set_shader_parameter("albedo", c),
				material.get_shader_parameter("albedo"), NATURAL[part], 0.7)
	# A free little loop and away.
	var free_flight := create_tween()
	free_flight.tween_property(self, "global_position", global_position + Vector3(0.5, 0.8, 0.0), 0.6).set_trans(Tween.TRANS_SINE)
	free_flight.parallel().tween_property(visual_root, "rotation:z", TAU, 0.8)
	free_flight.tween_callback(func(): BeeCombatVFX.spawn(get_parent(), global_position, &"pollen", Vector3.UP, 1.0))
	free_flight.tween_interval(0.45) # A free, natural hover: the colours are back.
	free_flight.tween_property(self, "global_position", global_position + Vector3(-6.0, 4.6, 0.0), liberation_seconds - 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	free_flight.tween_callback(_finish_liberation)


func _finish_liberation() -> void:
	state = State.DONE
	hide()
	set_physics_process(false)
	defeated.emit(self)


# --- visual (Style C) ---------------------------------------------------------------------------------------

func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)
	var body := Node3D.new()
	body.name = "Body"
	# Seen three-quarters from above so the four wings read against the side camera.
	body.rotation.x = 1.05 # Back (and the implant on it) towards the camera.
	visual_root.add_child(body)
	_part(body, "Thorax", _ellipsoid(Vector3(0.36, 0.27, 0.27)), "thorax", Vector3.ZERO)
	_part(body, "Head", _ellipsoid(Vector3(0.22, 0.2, 0.22)), "head", Vector3(-0.46, 0.04, 0.0))
	for side in [-1.0, 1.0]:
		_part(body, "Eye%d" % int(side), _ellipsoid(Vector3(0.15, 0.15, 0.13)), "eyes", Vector3(-0.56, 0.1, 0.13 * side))
	var abdomen := GardenProps.loft([[0.0, 0.14, 0.13, 0, 0], [0.3, 0.12, 0.11, 0, 0], [1.2, 0.09, 0.08, 0, 0], [1.7, 0.07, 0.06, 0, 0], [1.85, 0.03, 0.03, 0, 0]], 10, true, true, 0.0, true)
	var abdomen_node := _part(body, "Abdomen", abdomen, "abdomen", Vector3(0.28, 0.0, 0.0))
	abdomen_node.rotation.z = -PI * 0.5 # Loft is built along +Y.
	for i in 4:
		var pivot := Node3D.new()
		pivot.name = "WingPivot%d" % i
		var front := i < 2
		var side := -1.0 if i % 2 == 0 else 1.0
		pivot.position = Vector3(-0.06 if front else 0.16, 0.18, 0.1 * side)
		body.add_child(pivot)
		var wing := MeshInstance3D.new()
		wing.name = "Wing%d" % i
		var plate := SphereMesh.new()
		plate.radius = 1.0
		plate.height = 2.0
		plate.radial_segments = 12
		plate.rings = 4
		var material := StandardMaterial3D.new()
		material.resource_name = "Wing" # BeeToonStyle -> translucent toon wing shader.
		material.albedo_color = Color(0.7, 0.86, 0.95, 0.32)
		plate.material = material
		wing.mesh = plate
		wing.scale = Vector3(0.17 if front else 0.2, 0.012, 0.95)
		wing.position = Vector3(0.0, 0.0, 0.9 * side)
		pivot.add_child(wing)
		_wings.append(pivot)
	implant = Node3D.new()
	implant.name = "Implant"
	implant.position = Vector3(0.02, 0.26, 0.0)
	body.add_child(implant)
	var shell := MeshInstance3D.new()
	shell.name = "Shell"
	var shell_mesh := BoxMesh.new()
	shell_mesh.size = Vector3(0.36, 0.12, 0.3)
	shell_mesh.material = GardenProps.flat(IMPLANT_SHELL)
	shell.mesh = shell_mesh
	implant.add_child(shell)
	var core := MeshInstance3D.new()
	core.name = "Core"
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.12
	core_mesh.height = 0.2
	var core_source := StandardMaterial3D.new()
	core_source.albedo_color = IMPLANT_CORE
	core_source.emission_enabled = true
	core_source.emission = IMPLANT_CORE
	core_source.emission_energy_multiplier = 2.2
	core_mesh.material = core_source
	core.mesh = core_mesh
	core.position.y = 0.08
	implant.add_child(core)
	for side in [-1.0, 1.0]:
		var antenna := MeshInstance3D.new()
		antenna.name = "Antenna%d" % int(side)
		var rod := CylinderMesh.new()
		rod.top_radius = 0.015
		rod.bottom_radius = 0.025
		rod.height = 0.26
		rod.material = GardenProps.flat(IMPLANT_SHELL)
		antenna.mesh = rod
		antenna.position = Vector3(0.1, 0.16, 0.1 * side)
		antenna.rotation.z = -0.35
		implant.add_child(antenna)
		var tip := MeshInstance3D.new()
		var tip_mesh := SphereMesh.new()
		tip_mesh.radius = 0.04
		tip_mesh.height = 0.08
		var tip_material := StandardMaterial3D.new()
		tip_material.albedo_color = IMPLANT_VIOLET
		tip_material.emission_enabled = true
		tip_material.emission = IMPLANT_VIOLET
		tip_material.emission_energy_multiplier = 1.6
		tip_mesh.material = tip_material
		tip.mesh = tip_mesh
		tip.position = Vector3(0.0, 0.14, 0.0)
		antenna.add_child(tip)
	BeeToonStyle.apply(visual_root, true)
	# Dragonfly membranes are larger and flatter than Bee's wings: a lighter, cooler, more transparent wing.
	for pivot in _wings:
		var wing_mesh := pivot.get_child(0) as MeshInstance3D
		var wing_material := (wing_mesh.get_surface_override_material(0) as ShaderMaterial).duplicate() as ShaderMaterial
		wing_material.set_shader_parameter("alpha", 0.16)
		wing_material.set_shader_parameter("sheen_strength", 0.18)
		wing_material.set_shader_parameter("tint", Color(0.72, 0.9, 0.92))
		wing_mesh.set_surface_override_material(0, wing_material)
	# Own material copies so the tint/glow of one dragonfly never touches anything else.
	for part_node: MeshInstance3D in body.find_children("*", "MeshInstance3D", true, false):
		var part := str(part_node.get_meta("part", ""))
		var shared := part_node.get_surface_override_material(0) as ShaderMaterial
		if shared == null:
			continue
		var own := shared.duplicate() as ShaderMaterial
		part_node.set_surface_override_material(0, own)
		if part != "":
			own.set_shader_parameter("albedo", (NATURAL[part] as Color).lerp(CONTROLLED_TINT, 0.6))
			_body_materials[part] = own
		elif part_node.name == "Core":
			_core_material = own


func _part(parent: Node3D, label: String, mesh: Mesh, part: String, position_: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	if mesh is PrimitiveMesh:
		(mesh as PrimitiveMesh).material = GardenProps.flat(NATURAL[part])
	else:
		mesh.surface_set_material(0, GardenProps.flat(NATURAL[part]))
	node.mesh = mesh
	node.position = position_
	node.set_meta("part", part)
	parent.add_child(node)
	return node


static func _ellipsoid(radii: Vector3) -> SphereMesh:
	# SphereMesh has an XZ radius and a separate Y height: enough for the rounded insect parts.
	var sphere := SphereMesh.new()
	sphere.radius = maxf(radii.x, radii.z)
	sphere.height = radii.y * 2.0
	sphere.radial_segments = 14
	sphere.rings = 7
	return sphere
