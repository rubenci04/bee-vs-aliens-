class_name UfoShieldNode
extends Node3D
## LOTE 9 · ETAPA C — a shield node of the NODO ALIEN (phase 2). Two or three of them orbit the saucer and power its cyan
## shield (a cyan tether links each node to the core). They never attack: shooting them all drops the shield for a clear
## vulnerability window. Technology: they explode. Built in code (cyan core, violet ring, tether).

signal destroyed(node: UfoShieldNode)

const HEALTH_SCENE := preload("res://scenes/components/health_component.tscn")
const HURTBOX_SCENE := preload("res://scenes/components/hurtbox_3d.tscn")
const CORE_RADIUS := 0.24
const HIT_RADIUS := 0.6
const ORBIT_SPEED := 1.6 # rad/s of the sweep along its arc.
## The nodes guard the side of the saucer that faces Bee: each one sweeps +-ARC_SWEEP rad around its slot on that arc.
const ARC_SWEEP := 0.35
const COLOR := Color(0.2, 0.95, 1.0)
const RING_COLOR := Color(0.66, 0.28, 1.0)

var boss: Node3D
var angle := 0.0
var slot := 0.0 # Offset (rad) on the guard arc, from setup().
var orbit := Vector2(4.4, 2.8) # Ellipse radii (m): wide, flat, outside the shield bubble, clamped inside the frame.
var health: HealthComponent
var hurtbox: DamageHurtbox3D
var _tether: MeshInstance3D
var _dead := false
var _t := 0.0


func _ready() -> void:
	add_to_group("bee_auto_aim_targets")
	add_to_group("ufo_shield_nodes")
	health = HEALTH_SCENE.instantiate() as HealthComponent
	health.name = "HealthComponent"
	add_child(health)
	hurtbox = HURTBOX_SCENE.instantiate() as DamageHurtbox3D
	hurtbox.name = "Hurtbox3D"
	hurtbox.team_id = &"alien"
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = HIT_RADIUS
	shape.shape = sphere
	hurtbox.add_child(shape)
	add_child(hurtbox)
	health.died.connect(_on_died)
	health.health_changed.connect(func(_c: int, _m: int, change: int): if change < 0: _punch())
	_build_visual()


func setup(owner_boss: Node3D, start_angle: float, hp: int) -> void:
	boss = owner_boss
	slot = start_angle
	var facing := PI if float(owner_boss.get("side")) > 0.0 else 0.0
	angle = facing + slot
	if health == null:
		await ready
	health.max_health = hp
	health.current_health = hp
	_place(0.0)


func is_active() -> bool:
	return not _dead


func is_defeated() -> bool:
	return _dead


func _build_visual() -> void:
	var core := MeshInstance3D.new()
	core.name = "Core"
	var ball := SphereMesh.new()
	ball.radius = CORE_RADIUS
	ball.height = CORE_RADIUS * 2.0
	ball.radial_segments = 12
	ball.rings = 6
	ball.material = _glow(COLOR, 1.0, 1.8)
	core.mesh = ball
	add_child(core)
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	var torus := TorusMesh.new()
	torus.inner_radius = CORE_RADIUS + 0.08
	torus.outer_radius = CORE_RADIUS + 0.16
	torus.rings = 20
	torus.ring_segments = 6
	torus.material = _glow(RING_COLOR, 1.0, 1.2)
	ring.mesh = torus
	ring.rotation.x = PI * 0.5
	add_child(ring)
	_tether = MeshInstance3D.new()
	_tether.name = "Tether"
	var beam := CylinderMesh.new()
	beam.top_radius = 0.03
	beam.bottom_radius = 0.03
	beam.height = 1.0
	beam.radial_segments = 6
	beam.rings = 1
	beam.material = _glow(COLOR, 0.45, 1.0)
	_tether.mesh = beam
	_tether.top_level = true
	add_child(_tether)
	for mesh: MeshInstance3D in [core, ring, _tether]:
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _glow(color: Color, alpha: float, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(color, alpha)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _physics_process(delta: float) -> void:
	if _dead or boss == null or not is_instance_valid(boss):
		return
	_t += delta
	var facing := PI if float(boss.get("side")) > 0.0 else 0.0 # Saucer on the right: its guard arc points left.
	angle = facing + slot + sin(_t * ORBIT_SPEED + slot * 3.0) * ARC_SWEEP
	_place(delta)


func _place(_delta: float) -> void:
	var centre := boss.global_position
	var p := centre + Vector3(cos(angle) * orbit.x, sin(angle) * orbit.y, 0.0)
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	if camera != null:
		# Always inside the frame (the saucer can sit near an edge).
		var half := BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(get_viewport())) - 0.9
		p.x = clampf(p.x, camera.global_position.x - half, camera.global_position.x + half)
		p.y = clampf(p.y, BeeLevel01Framing.bottom_y() + 1.0, BeeLevel01Framing.top_y() - 0.9)
	global_position = p
	# Tether from the node to the saucer's core.
	var to := centre - p
	to.z = 0.0
	var length := to.length()
	if length > 0.05:
		var direction := to / length
		var side := Vector3(direction.y, -direction.x, 0.0) # In the play plane, perpendicular to the tether.
		var turn := Basis(side, direction, Vector3.BACK)
		_tether.global_transform = Transform3D(turn * Basis.from_scale(Vector3(1.0, length, 1.0)), p + to * 0.5)
	rotation.z = _t * 1.4


func _punch() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * 1.25, 0.05)
	tween.tween_property(self, "scale", Vector3.ONE, 0.08)


func _on_died() -> void:
	if _dead:
		return
	_dead = true
	remove_from_group("bee_auto_aim_targets")
	hurtbox.set_deferred("monitorable", false)
	BeeLiberation.explode_tech(get_parent(), global_position, 0.7)
	destroyed.emit(self)
	queue_free()


## The saucer dies or leaves phase 2: the node blows harmlessly.
func dismiss() -> void:
	if _dead:
		return
	_dead = true
	remove_from_group("bee_auto_aim_targets")
	BeeCombatVFX.spawn(get_parent(), global_position, &"tech_hit", Vector3.UP, 0.6)
	queue_free()
