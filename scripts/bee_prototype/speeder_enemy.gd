class_name SpeederEnemy
extends CharacterBody3D

signal defeated(enemy: SpeederEnemy)

enum Phase { ENTER, TELEGRAPH, DASH, EXIT, DEAD, RETREAT }

@export var entry_speed := 4.0
@export var dash_speed := 9.5
@export var telegraph_time := 0.7
@export var contact_damage := 13
@export var entry_screen_x := 4.5
@export var exit_screen_x := -9.0
@export var respawn_screen_x := 10.8
## THREAT REBUILD 03 (Level 01 only, off by default): during the telegraph a thin lane line crosses the screen at the
## dash height, so the FAST CROSSING THREAT is fully predictable (straight, fixed height).
@export var lane_telegraph := false
var _lane: MeshInstance3D
## COMBAT VARIETY 01 (Level 01 only; off by default): RAM. The telegraph flashes white (RAM_FLASH_HZ) and a thin line
## points at Bee; the direction LOCKS `RAM_LOCK` s before the charge; then a straight ram along it (can be diagonal),
## and the Speeder RETREATS back to the right side (harmless) before the next ram.
@export var ram_mode := false
const RAM_TELEGRAPH := 0.75
const RAM_LOCK := 0.25
const RAM_SPEED := 11.0
const RAM_DISTANCE := 13.0
const RAM_FLASH_HZ := 8.0
const RETREAT_SPEED := 6.0
var ram_count := 0
var _ram_dir := Vector3.LEFT
var _ram_left := 0.0
var _home := Vector3.ZERO
static var _lane_material: StandardMaterial3D

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: DamageHurtbox3D = $Hurtbox3D
@onready var visual_root: Node3D = $VisualRoot
@onready var telegraph: Node3D = $AttackTelegraph
@onready var dash_hitbox: DamageHitbox3D = $DashHitbox

var target: BeePlayer
var current_state := Phase.ENTER
var pass_count := 0
var _active := false
var _state_left := 0.0
var _dash_height := 0.0

func _ready() -> void:
	add_to_group("bee_auto_aim_targets")
	health.died.connect(_on_died)
	dash_hitbox.damage = contact_damage
	dash_hitbox.set_enabled(false)
	telegraph.hide()
	_set_inactive()

func activate(new_target: BeePlayer) -> bool:
	if _active or current_state == Phase.DEAD or new_target == null:
		return false
	target = new_target
	_active = true
	current_state = Phase.ENTER
	show()
	hurtbox.set_deferred("monitorable", true)
	set_physics_process(true)
	return true

func is_active() -> bool:
	return _active and current_state != Phase.DEAD

func is_defeated() -> bool:
	return current_state == Phase.DEAD

func _set_inactive() -> void:
	_active = false
	target = null
	hide()
	hurtbox.set_deferred("monitorable", false)
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	if not _active or target == null or target.is_defeated:
		velocity = Vector3.ZERO
		return
	var stage_camera := get_viewport().get_camera_3d()
	if stage_camera == null:
		return
	match current_state:
		Phase.ENTER:
			velocity = Vector3(-entry_speed, 0, 0)
			move_and_slide()
			if global_position.x <= stage_camera.global_position.x + entry_screen_x:
				_begin_telegraph()
		Phase.TELEGRAPH:
			velocity = Vector3.ZERO
			_state_left -= delta
			if ram_mode:
				_update_ram_telegraph()
			if _state_left <= 0.0:
				_begin_dash()
		Phase.DASH:
			if ram_mode:
				_ram(delta, stage_camera)
				return
			velocity = Vector3(-dash_speed, 0, 0)
			move_and_slide()
			global_position.y = _dash_height
			if global_position.x < stage_camera.global_position.x + exit_screen_x:
				_end_pass(stage_camera)
		Phase.EXIT:
			velocity = Vector3.ZERO
		Phase.RETREAT:
			_retreat(delta, stage_camera)
	position.z = 0.0

func _begin_telegraph() -> void:
	current_state = Phase.TELEGRAPH
	_state_left = telegraph_time
	if ram_mode:
		_state_left = RAM_TELEGRAPH
		_home = Vector3(0.0, global_position.y, 0.0)
	velocity = Vector3.ZERO
	telegraph.show()
	visual_root.scale = Vector3(1.1,0.9,1.1)
	_show_lane()

func _begin_dash() -> void:
	current_state = Phase.DASH
	if ram_mode:
		_ram_left = RAM_DISTANCE
		ram_count += 1
		visual_root.visible = true
	_hide_lane()
	_dash_height = global_position.y
	telegraph.hide()
	visual_root.scale = Vector3.ONE
	dash_hitbox.damage = contact_damage
	dash_hitbox.set_enabled(true)

func _end_pass(stage_camera: Camera3D) -> void:
	dash_hitbox.set_enabled(false)
	current_state = Phase.EXIT
	pass_count += 1
	# Re-enter from beyond the viewport while alive, so a missed first dash cannot stall the wave.
	global_position = Vector3(stage_camera.global_position.x + respawn_screen_x, _dash_height, 0.0)
	current_state = Phase.ENTER

func _on_died() -> void:
	if current_state == Phase.DEAD:
		return
	_hide_lane()
	current_state = Phase.DEAD
	_active = false
	velocity = Vector3.ZERO
	dash_hitbox.set_enabled(false)
	telegraph.hide()
	hurtbox.set_deferred("monitorable", false)
	visual_root.hide()
	set_physics_process(false)
	defeated.emit(self)


func _show_lane() -> void:
	if ram_mode:
		_ram_dir = _aim_at_bee()
		_lane = BeeAttackVisuals.line(self, global_position, global_position + _ram_dir * RAM_DISTANCE, 0.07, Color(1.0, 0.45, 0.15, 0.5))
		return
	if not lane_telegraph:
		return
	if _lane_material == null:
		_lane_material = StandardMaterial3D.new()
		_lane_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_lane_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_lane_material.albedo_color = Color(1.0, 0.45, 0.15, 0.35)
	_lane = MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(30.0, 0.05, 0.05)
	bar.material = _lane_material
	_lane.mesh = bar
	_lane.top_level = true
	_lane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_lane)
	_lane.global_position = global_position + Vector3(-15.0, 0.0, 0.0) # From the Speeder leftwards: its whole path.


func _hide_lane() -> void:
	if _lane != null and is_instance_valid(_lane):
		_lane.queue_free()
	_lane = null


# --- COMBAT VARIETY 01: ram -------------------------------------------------------------------------------------

func _aim_at_bee() -> Vector3:
	if target == null:
		return Vector3.LEFT
	var to_bee := target.global_position - global_position
	var flat := Vector3(to_bee.x, to_bee.y, 0.0).normalized()
	if flat.x > -0.35: # Never rams backwards or straight up/down: it charges across the screen.
		flat = Vector3(-0.94, signf(flat.y) * 0.34, 0.0).normalized()
	return flat


## Warning: the body flashes and the line keeps pointing at Bee until the lock, then freezes.
func _update_ram_telegraph() -> void:
	var flash_on := int(_state_left * RAM_FLASH_HZ * 2.0) % 2 == 0
	visual_root.visible = flash_on or _state_left > RAM_TELEGRAPH - 0.1
	telegraph.visible = true
	if _state_left > RAM_LOCK:
		_ram_dir = _aim_at_bee()
		if _lane != null and is_instance_valid(_lane):
			BeeAttackVisuals.place_line(_lane, global_position, global_position + _ram_dir * RAM_DISTANCE)


func _ram(delta: float, stage_camera: Camera3D) -> void:
	var step := minf(RAM_SPEED * delta, _ram_left)
	global_position += _ram_dir * step
	_ram_left -= step
	var half := BeeShmupFairness.visible_half_width(stage_camera, global_position, BeeLevel01Framing.view_aspect(get_viewport()))
	var top := BeeLevel01Framing.top_y()
	global_position.y = clampf(global_position.y, 0.8, top - 0.6)
	if _ram_left <= 0.0 or global_position.x < stage_camera.global_position.x - half - 1.0:
		dash_hitbox.set_enabled(false)
		pass_count += 1
		current_state = Phase.RETREAT
	position.z = 0.0


## Harmless return to the right part of the screen, then the next ram.
func _retreat(delta: float, stage_camera: Camera3D) -> void:
	var home := Vector3(stage_camera.global_position.x + entry_screen_x, _home.y, 0.0)
	var to_home := home - global_position
	if to_home.length() <= RETREAT_SPEED * delta:
		global_position = home
		_begin_telegraph()
		return
	global_position += to_home.normalized() * RETREAT_SPEED * delta
	position.z = 0.0
