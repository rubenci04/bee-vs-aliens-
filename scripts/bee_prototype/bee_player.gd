class_name BeePlayer
extends CharacterBody3D

signal health_changed(current: int, maximum: int)
signal auto_aim_changed(target: Node3D)
signal melee_started
signal defeated

@export_category("Flight")
@export var horizontal_speed := 7.0
@export var vertical_speed := 6.0
@export var acceleration := 32.0
@export var deceleration := 40.0
@export var flight_min := Vector2(-10.0, 0.7)
@export var flight_max := Vector2(10.0, 7.2)

@export_category("Ranged combat")
@export var projectile_scene: PackedScene
@export var auto_aim_range := 12.0
@export_range(1.0, 179.0, 1.0) var auto_aim_cone_degrees := 80.0
@export var muzzle_offset := Vector3(0.48, 0.0, 0.0)

@export_category("Melee")
@export var melee_damage := 15
@export var melee_range := 0.85
@export var melee_active_time := 0.12
@export var melee_cooldown := 0.52

@onready var visual_root: Node3D = $VisualRoot
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: DamageHurtbox3D = $Hurtbox3D
@onready var target_indicator: Node3D = $TargetIndicator
@onready var melee_hitbox: DamageHitbox3D = $MeleeHitbox

var facing_x := 1.0
var current_auto_target: Node3D
var shots_fired := 0
var melee_count := 0
var is_defeated := false
var _melee_active_left := 0.0
var _melee_cooldown_left := 0.0
var _melee_tween: Tween


func _ready() -> void:
	add_to_group("bee_player")
	target_indicator.set_as_top_level(true)
	target_indicator.hide()
	melee_hitbox.damage = melee_damage
	melee_hitbox.set_enabled(false)
	_place_melee_hitbox()
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	_update_melee(delta)
	if is_defeated:
		velocity = Vector3.ZERO
		return
	var input := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var desired := Vector2(input.x * horizontal_speed, input.y * vertical_speed)
	var rate := acceleration if desired.length_squared() > 0.0 else deceleration
	velocity.x = move_toward(velocity.x, desired.x, rate * delta)
	velocity.y = move_toward(velocity.y, desired.y, rate * delta)
	velocity.z = 0.0
	if absf(input.x) > 0.05:
		facing_x = signf(input.x)
		visual_root.rotation.y = -facing_x * PI * 0.5
		_place_melee_hitbox()
	move_and_slide()
	position.x = clampf(position.x, flight_min.x, flight_max.x)
	position.y = clampf(position.y, flight_min.y, flight_max.y)
	position.z = 0.0
	refresh_auto_aim()
	if Input.is_action_just_pressed("throw_orange"):
		fire()
	if Input.is_action_just_pressed("debug_attack"):
		start_melee()


func refresh_auto_aim() -> Node3D:
	if is_defeated:
		current_auto_target = null
		_update_target_indicator()
		return null
	var best: Node3D
	var best_score := INF
	var forward := Vector2(facing_x, 0.0)
	var half_cone := deg_to_rad(auto_aim_cone_degrees * 0.5)
	for candidate_node in get_tree().get_nodes_in_group("bee_auto_aim_targets"):
		var candidate := candidate_node as Node3D
		if not _is_valid_target(candidate):
			continue
		var delta := Vector2(candidate.global_position.x - global_position.x, candidate.global_position.y - global_position.y)
		var distance := delta.length()
		if distance <= 0.001 or distance > auto_aim_range:
			continue
		var angle := absf(forward.angle_to(delta.normalized()))
		if angle > half_cone:
			continue
		var score := distance + angle * 3.0
		if score < best_score:
			best_score = score
			best = candidate
	if best != current_auto_target:
		current_auto_target = best
		auto_aim_changed.emit(current_auto_target)
	_update_target_indicator()
	return current_auto_target


func fire() -> BeeEnergyProjectile:
	if is_defeated or projectile_scene == null:
		return null
	refresh_auto_aim()
	var direction := Vector3(facing_x, 0.0, 0.0)
	if current_auto_target != null:
		direction = (_target_point(current_auto_target) - global_position).normalized()
	var projectile := projectile_scene.instantiate() as BeeEnergyProjectile
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector3(facing_x * absf(muzzle_offset.x), muzzle_offset.y, 0.0)
	projectile.launch(direction, self)
	shots_fired += 1
	return projectile


func start_melee() -> bool:
	if is_defeated or _melee_cooldown_left > 0.0:
		return false
	_place_melee_hitbox()
	melee_hitbox.damage = melee_damage
	melee_hitbox.set_enabled(true)
	_melee_active_left = melee_active_time
	_melee_cooldown_left = melee_cooldown
	melee_count += 1
	if _melee_tween != null:
		_melee_tween.kill()
	visual_root.scale = Vector3(1.22, 0.82, 0.82)
	_melee_tween = create_tween()
	_melee_tween.tween_property(visual_root, "scale", Vector3.ONE, 0.14)
	melee_started.emit()
	return true


func _update_melee(delta: float) -> void:
	_melee_cooldown_left = maxf(0.0, _melee_cooldown_left - delta)
	if _melee_active_left <= 0.0:
		return
	_melee_active_left = maxf(0.0, _melee_active_left - delta)
	if _melee_active_left == 0.0:
		melee_hitbox.set_enabled(false)


func _place_melee_hitbox() -> void:
	if is_instance_valid(melee_hitbox):
		melee_hitbox.position = Vector3(facing_x * melee_range, 0.0, 0.0)


func _is_valid_target(candidate: Node3D) -> bool:
	if candidate == null or not is_instance_valid(candidate) or not candidate.is_inside_tree():
		return false
	if not candidate.visible or not candidate.is_visible_in_tree():
		return false
	if candidate.has_method("is_active") and not bool(candidate.call("is_active")):
		return false
	if candidate.has_method("is_defeated") and bool(candidate.call("is_defeated")):
		return false
	return true


func _target_point(candidate: Node3D) -> Vector3:
	var hurtbox := candidate.get_node_or_null("Hurtbox3D") as Node3D
	return hurtbox.global_position if hurtbox != null else candidate.global_position


func _update_target_indicator() -> void:
	if current_auto_target == null:
		target_indicator.hide()
		return
	target_indicator.global_position = _target_point(current_auto_target) + Vector3(0.0, 0.55, 0.0)
	target_indicator.show()


func _on_health_changed(current: int, maximum: int, _change: int) -> void:
	health_changed.emit(current, maximum)


func _on_died() -> void:
	if is_defeated:
		return
	is_defeated = true
	velocity = Vector3.ZERO
	current_auto_target = null
	target_indicator.hide()
	melee_hitbox.set_enabled(false)
	_melee_active_left = 0.0
	if _melee_tween != null:
		_melee_tween.kill()
	visual_root.scale = Vector3(1.0, 0.45, 1.0)
	health_changed.emit(0, health.max_health)
	defeated.emit()