class_name HumanObserver
extends Node3D

enum State { IDLE, NOTICE, ALERT, HOSTILE }
enum AttackPhase { READY, WINDUP, ACTIVE, RECOVERY }

@export var target_path: NodePath
@export_range(1.0, 30.0) var vision_range := 10.0
@export_range(1.0, 179.0) var vision_cone_degrees := 90.0
@export var suspicion_gain_per_second := 15.0
@export var suspicion_decay_per_second := 10.0
@export var shot_suspicion := 25.0
@export var melee_suspicion := 8.0
@export var show_vision_debug := true
@export var attack_range := 2.3
@export var windup_seconds := 0.65
@export var active_seconds := 0.18
@export var recovery_seconds := 0.9
@export var attack_damage := 20

@onready var bee: BeePlayer = get_node(target_path) as BeePlayer
@onready var body_mesh: MeshInstance3D = $Visual/Body
@onready var face: MeshInstance3D = $Visual/Face
@onready var state_label: Label3D = $StateLabel
@onready var vision_cone: MeshInstance3D = $VisionCone
@onready var telegraph: MeshInstance3D = $AttackTelegraph
@onready var attack_hitbox: DamageHitbox3D = $AttackHitbox

var suspicion := 0.0
var current_state := State.IDLE
var attack_phase := AttackPhase.READY
var facing_x := -1.0
var attack_count := 0
var _phase_left := 0.0
var _was_visible := false
var _idle_material := StandardMaterial3D.new()
var _notice_material := StandardMaterial3D.new()
var _alert_material := StandardMaterial3D.new()
var _hostile_material := StandardMaterial3D.new()

func _ready() -> void:
	_idle_material.albedo_color = Color(0.28, 0.36, 0.45)
	_notice_material.albedo_color = Color(0.72, 0.57, 0.22)
	_alert_material.albedo_color = Color(0.85, 0.36, 0.17)
	_hostile_material.albedo_color = Color(0.7, 0.12, 0.12)
	attack_hitbox.team_id = &"human"
	attack_hitbox.damage = attack_damage
	attack_hitbox.set_enabled(false)
	telegraph.hide()
	_build_vision_cone()
	_update_state_visual()

func _physics_process(delta: float) -> void:
	_was_visible = can_see_bee()
	if current_state != State.HOSTILE:
		suspicion = clampf(suspicion + (suspicion_gain_per_second if _was_visible else -suspicion_decay_per_second) * delta, 0.0, 100.0)
		_refresh_state()
	if current_state == State.ALERT or current_state == State.HOSTILE:
		if bee != null and is_instance_valid(bee):
			facing_x = signf(bee.global_position.x - global_position.x) if absf(bee.global_position.x-global_position.x)>0.25 else facing_x
			face.position.x = facing_x * 0.28
	vision_cone.visible = show_vision_debug
	vision_cone.scale.x = facing_x
	_update_attack(delta)

func can_see_bee() -> bool:
	if bee == null or not is_instance_valid(bee) or bee.is_defeated:
		return false
	var eye := global_position + Vector3(0, 1.5, 0)
	var target := bee.global_position
	var difference := Vector2(target.x-eye.x, target.y-eye.y)
	var distance := difference.length()
	if distance > vision_range or distance < 0.01:
		return false
	var forward := Vector2(facing_x, 0)
	if absf(forward.angle_to(difference.normalized())) > deg_to_rad(vision_cone_degrees * 0.5):
		return false
	var query := PhysicsRayQueryParameters3D.create(eye, target, 1)
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	return result.is_empty() or result.get("collider") == bee

func notify_bee_action(kind: String) -> void:
	if current_state == State.HOSTILE or not can_see_bee():
		return
	suspicion = minf(100.0, suspicion + (shot_suspicion if kind == "shot" else melee_suspicion))
	_refresh_state()

func _refresh_state() -> void:
	var next := State.IDLE
	if suspicion >= 100.0: next = State.HOSTILE
	elif suspicion >= 70.0: next = State.ALERT
	elif suspicion >= 35.0: next = State.NOTICE
	if next != current_state:
		current_state = next
		_update_state_visual()

func _update_state_visual() -> void:
	match current_state:
		State.IDLE:
			body_mesh.material_override = _idle_material
			state_label.text = ""
		State.NOTICE:
			body_mesh.material_override = _notice_material
			state_label.text = "?"
		State.ALERT:
			body_mesh.material_override = _alert_material
			state_label.text = "!"
		State.HOSTILE:
			body_mesh.material_override = _hostile_material
			state_label.text = "!"

func _update_attack(delta: float) -> void:
	if current_state != State.HOSTILE or bee == null or bee.is_defeated:
		return
	if attack_phase == AttackPhase.READY:
		if global_position.distance_to(bee.global_position) <= attack_range:
			attack_phase = AttackPhase.WINDUP
			_phase_left = windup_seconds
			telegraph.position.x = facing_x * 1.1
			telegraph.show()
		return
	_phase_left -= delta
	if _phase_left > 0.0: return
	match attack_phase:
		AttackPhase.WINDUP:
			attack_phase = AttackPhase.ACTIVE
			_phase_left = active_seconds
			telegraph.hide()
			attack_hitbox.position.x = facing_x * 1.1
			attack_hitbox.set_enabled(true)
			attack_count += 1
		AttackPhase.ACTIVE:
			attack_hitbox.set_enabled(false)
			attack_phase = AttackPhase.RECOVERY
			_phase_left = recovery_seconds
		AttackPhase.RECOVERY:
			attack_phase = AttackPhase.READY

func _build_vision_cone() -> void:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var half_angle := deg_to_rad(vision_cone_degrees * 0.5)
	for i in 17:
		var angle := lerpf(-half_angle, half_angle, float(i) / 16.0)
		vertices.append(Vector3(cos(angle) * vision_range, sin(angle) * vision_range, 0))
	vertices.append(Vector3.ZERO)
	for i in 16:
		indices.append_array(PackedInt32Array([17, i, i + 1]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(0.95, 0.78, 0.15, 0.08)
	mesh.surface_set_material(0, material)
	vision_cone.mesh = mesh
	vision_cone.position = Vector3(0, 1.5, -0.8)
