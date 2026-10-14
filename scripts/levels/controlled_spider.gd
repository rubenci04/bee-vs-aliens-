class_name ControlledSpider
extends Node3D
## GARDEN IDENTITY 04 — alien-controlled garden spider: a VERTICAL LANE THREAT (hostile controlled fauna V0).
## It hangs from a silk thread and rides its web line along the screen; an alien implant on its back drives it.
##   ENTER (from above the top edge, inside the screen) -> HANG -> TELEGRAPH (implant charges cyan; a column and a
##   target ring show where it will drop; the target follows Bee's height, then LOCKS) -> DROP (fast, to the locked
##   height) -> HOLD (a short barrier in that column) -> RETRACT -> REPOSITION (along the web line, towards Bee) ->
##   second attack -> EXIT (climbs out of the top edge).
## What it asks: read the column and the ring, then change height (or slide sideways) before the lock lands.
## Fairness: it only telegraphs fully inside the screen; the drop target is clamped so a low lane (under the body)
## and the space above the body (the thread never hurts) are always free; one heavy pattern at a time
## (BeeAttackTokens); only its body hurts (8 on contact, 14 while striking), once per phase.
## Shooting the implant out frees the spider: it scurries up out of the frame (no gore). A future pass may turn this
## into the full liberation language of the dragonfly (see docs/BEE_GARDEN_IDENTITY_AUDIO_PASS_04.md).
## Asset: Quaternius Spider (CC0, assets/external/ASSET_PROVENANCE.md).

signal defeated(enemy: ControlledSpider)
## NOCHE 01: emitted when the implant breaks (the spider is freed, not killed).
signal liberated_now(enemy: ControlledSpider)

enum State { IDLE, ENTER, HANG, TELEGRAPH, DROP, HOLD, RETRACT, REPOSITION, EXIT, FREED }

const MODEL := preload("res://assets/external/approved/fauna/quaternius/Easy Animated Enemy Pack - Jan 2019/FBX/Spider.fbx")
## NOCHE 01: size relative to Bee (BeeFaunaSizes "spider" 1.4). SPIDER_LENGTH_AT_034 = measured body length at the old scale 0.34.
const SPIDER_LENGTH_AT_034 := 2.02 # Body (legs spread) only, without silk / implant.
const SIZE_FACTOR := 1.4 * 1.18 / SPIDER_LENGTH_AT_034 # = BeeFaunaSizes.target_length(&"spider") / SPIDER_LENGTH_AT_034
const AUTO_AIM_DROP := 0.45 # LOTE 9: m below the hurtbox centre where the auto-aim points (the body, not the implant).
const MODEL_SCALE := 0.34 * SIZE_FACTOR
## NOCHE 01: a freed spider climbs its thread out of the top edge, relaxed, in FREED_SECONDS.
const FREED_SECONDS := 1.8
const MODEL_ROTATION := Vector3(deg_to_rad(90.0), 0.0, 0.0) ## hanging head-down, belly to the camera, legs spread
const SILK := Color(0.93, 0.93, 0.88, 0.75)

@export var hang_height := 5.5
@export var min_strike_y := 2.0 ## the body never drops below this: the low lane stays free
@export var hang_seconds := 0.4
@export var telegraph_seconds := 0.85
@export var lock_before_drop := 0.3 ## the target stops following Bee this long before the drop
@export var drop_seconds := 0.22
@export var hold_seconds := 0.45
@export var retract_seconds := 0.5
@export var reposition_seconds := 0.6
@export var enter_seconds := 0.85
@export var exit_seconds := 0.9
@export var attacks := 2
@export var contact_damage := 8
@export var strike_damage := 14
@export var follow_speed := 3.2 ## m/s along the web line while hanging / repositioning (camera-relative)

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: DamageHurtbox3D = $Hurtbox3D
@onready var contact: DamageHitbox3D = $ContactHitbox
@onready var visual_root: Node3D = $VisualRoot

var target: BeePlayer
var current_state := State.IDLE
var attack_count := 0
var strike_count := 0
var telegraph_count := 0
var strike_hits := 0
var lock_y := 0.0
var locked := false
var escaped := false
var implant: WaspImplant
var max_drop_seen := 0.0 ## dev/tests: deepest body Y reached in a strike (always >= min_strike_y)
var _rel_x := 0.0
var _goal_rel_x := 0.0
var _state_left := 0.0
var _from_y := 0.0
var _model: Node3D
var _player: AnimationPlayer
var _thread: MeshInstance3D
var _column: MeshInstance3D
var _ring: MeshInstance3D
var _column_material: StandardMaterial3D
var _t := 0.0

static var _thread_mesh: CylinderMesh
static var _column_mesh: BoxMesh
static var _ring_mesh: TorusMesh
static var _thread_material: StandardMaterial3D


func _ready() -> void:
	health.died.connect(_on_died)
	contact.damage = contact_damage
	contact.set_enabled(false)
	contact.hit_confirmed.connect(_on_hit_confirmed)
	hurtbox.set_deferred("monitorable", false)
	_build_visual()
	hide()
	set_physics_process(false)


func activate(new_target: BeePlayer) -> bool:
	if current_state != State.IDLE or new_target == null:
		return false
	target = new_target
	var camera := get_viewport().get_camera_3d()
	_rel_x = global_position.x - (camera.global_position.x if camera != null else 0.0)
	_goal_rel_x = _rel_x
	global_position.y = BeeLevel01Framing.top_y() + 1.6 # Above the top edge: the thread is seen first.
	_from_y = global_position.y
	hang_height = minf(hang_height, BeeLevel01Framing.max_entity_y() - 0.4)
	show()
	_enter(State.ENTER, enter_seconds)
	add_to_group("bee_auto_aim_targets")
	hurtbox.set_deferred("monitorable", true)
	contact.set_enabled(true)
	_play(&"Idle")
	set_physics_process(true)
	return true


## LOTE 9: the auto-aim takes the lower body (abdomen / legs, 1x); the implant above it is the deliberate 2x shot.
func auto_aim_point() -> Vector3:
	return hurtbox.global_position + Vector3(0.0, -AUTO_AIM_DROP, 0.0)


## LOTE 13: true while a warning shows (the drop column): tests measure the time to the first one.
func is_telegraphing() -> bool:
	return current_state == State.TELEGRAPH


func is_active() -> bool:
	return current_state not in [State.IDLE, State.FREED] and not escaped


func is_defeated() -> bool:
	return current_state == State.FREED


func _enter(state: State, seconds: float) -> void:
	current_state = state
	_state_left = seconds


func _physics_process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null or target == null:
		return
	_t += delta
	_state_left -= delta
	var y := global_position.y
	match current_state:
		State.ENTER:
			var t := 1.0 - clampf(_state_left / enter_seconds, 0.0, 1.0)
			y = lerpf(_from_y, hang_height, ease(t, 0.4))
			if _state_left <= 0.0:
				_enter(State.HANG, hang_seconds)
		State.HANG:
			y = hang_height + sin(_t * 2.4) * 0.08
			_goal_rel_x = _bee_rel(camera)
			if _state_left <= 0.0:
				_try_telegraph()
		State.TELEGRAPH:
			y = hang_height + sin(_t * 9.0) * 0.05
			if not locked:
				lock_y = _strike_y()
				_goal_rel_x = _bee_rel(camera)
			if _state_left <= lock_before_drop and not locked:
				locked = true
				_goal_rel_x = _rel_x # The column stops following Bee too.
				_column_material.albedo_color = Color(1.0, 0.45, 0.15, 0.4) # Locked: orange, like every committed attack.
			_update_telegraph(y)
			if _state_left <= 0.0:
				_begin_drop()
		State.DROP:
			var t := 1.0 - clampf(_state_left / drop_seconds, 0.0, 1.0)
			y = lerpf(hang_height, lock_y, t * t)
			max_drop_seen = minf(max_drop_seen, y) if max_drop_seen > 0.0 else y
			if _state_left <= 0.0:
				y = lock_y
				_enter(State.HOLD, hold_seconds)
		State.HOLD:
			y = lock_y + sin(_t * 14.0) * 0.04
			if _state_left <= 0.0:
				_begin_retract()
		State.RETRACT:
			var t := 1.0 - clampf(_state_left / retract_seconds, 0.0, 1.0)
			y = lerpf(lock_y, hang_height, ease(t, 0.5))
			if _state_left <= 0.0:
				attack_count += 1
				if attack_count >= attacks and not bool(get_meta("level_hard", false)):
					_from_y = hang_height
					_enter(State.EXIT, exit_seconds)
				else:
					_goal_rel_x = _bee_rel(camera)
					_play(&"Walk")
					_enter(State.REPOSITION, reposition_seconds)
		State.REPOSITION:
			y = hang_height
			if _state_left <= 0.0:
				_play(&"Idle")
				_enter(State.HANG, hang_seconds * 0.6)
		State.EXIT:
			var t := 1.0 - clampf(_state_left / exit_seconds, 0.0, 1.0)
			y = lerpf(_from_y, BeeLevel01Framing.top_y() + 2.2, t * t)
			if _state_left <= 0.0:
				_leave(camera)
				return
		State.FREED:
			var t := 1.0 - clampf(_state_left / FREED_SECONDS, 0.0, 1.0)
			y = lerpf(_from_y, BeeLevel01Framing.top_y() + 2.2, t * t)
			if _state_left <= 0.0:
				hide()
				set_physics_process(false)
				defeated.emit(self) # NOCHE 01: released only once it has climbed away.
	# The web line rides with the camera; the spider slides along it.
	if current_state in [State.HANG, State.TELEGRAPH, State.REPOSITION]:
		_rel_x = move_toward(_rel_x, _goal_rel_x, follow_speed * delta)
	global_position = Vector3(camera.global_position.x + _rel_x, y, 0.0)
	_update_thread(camera)


## Camera-relative X of Bee, kept inside the readable screen.
func _bee_rel(camera: Camera3D) -> float:
	var half := BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(get_viewport())) - 1.2
	return clampf(target.global_position.x - camera.global_position.x, -half, half)


## Drop target: Bee's height, clamped so the low lane and the band above the body stay free.
func _strike_y() -> float:
	return clampf(target.global_position.y, min_strike_y, hang_height - 1.0)


func _try_telegraph() -> void:
	if target.is_defeated or not BeeShmupFairness.is_inside_screen(self, 0.8) \
			or not BeeAttackTokens.try_claim(self, telegraph_seconds + drop_seconds + hold_seconds):
		_state_left = 0.35 # Wait a beat (another heavy pattern is running, or not readable yet).
		return
	locked = false
	lock_y = _strike_y()
	telegraph_count += 1
	BeeShotWarning.begin(self, &"spider", visual_root)
	_column_material.albedo_color = Color(BeeAlienPalette.CYAN, 0.32)
	_column.show()
	_ring.show()
	if implant != null:
		implant.set_mode(&"sting")
	BeeAudio.play(get_parent(), &"spider_telegraph", global_position)
	_enter(State.TELEGRAPH, telegraph_seconds)


func _begin_drop() -> void:
	_column.hide()
	_ring.hide()
	if implant != null:
		implant.set_mode(&"idle")
	contact.damage = strike_damage
	contact.set_enabled(true) # A fresh phase: one strike hit at most.
	strike_count += 1
	_play(&"Attack")
	BeeAudio.play(get_parent(), &"spider_drop", global_position)
	_enter(State.DROP, drop_seconds)


func _begin_retract() -> void:
	contact.damage = contact_damage
	contact.set_enabled(true)
	BeeAttackTokens.release(self)
	_play(&"Idle")
	BeeAudio.play(get_parent(), &"spider_retract", global_position)
	_enter(State.RETRACT, retract_seconds)


## Out of the top edge: leaves play at once (the director drops it as an escaped soft unit).
func _leave(camera: Camera3D) -> void:
	escaped = true
	current_state = State.IDLE
	contact.set_enabled(false)
	hurtbox.set_deferred("monitorable", false)
	remove_from_group("bee_auto_aim_targets")
	set_physics_process(false)
	hide()
	BeeAttackTokens.release(self)
	global_position.x = camera.global_position.x - 9.0


func _on_hit_confirmed(_hurtbox: DamageHurtbox3D, _damage: int) -> void:
	strike_hits += 1


## The implant is shot out: sparks, the spider is free and scurries up out of the frame.
func _on_died() -> void:
	if current_state == State.FREED:
		return
	_from_y = global_position.y
	_enter(State.FREED, FREED_SECONDS)
	contact.set_enabled(false)
	hurtbox.set_deferred("monitorable", false)
	remove_from_group("bee_auto_aim_targets")
	BeeAttackTokens.release(self)
	_column.hide()
	_ring.hide()
	if implant != null:
		implant.set_mode(&"off")
	_play(&"Walk")
	add_to_group("bee_liberated")
	liberated_now.emit(self)
	BeeLiberation.free_animal(get_parent(), _model, implant, implant.global_position if implant != null else global_position)


func _play(clip: StringName) -> void:
	if _player == null:
		return
	for name in _player.get_animation_list():
		if str(name).ends_with("_" + str(clip)):
			if _player.current_animation != name:
				_player.play(name, 0.12)
			return


# --- visual -----------------------------------------------------------------------------------------------------

func _build_visual() -> void:
	_model = MODEL.instantiate() as Node3D
	_model.name = "Spider"
	_model.scale = Vector3.ONE * MODEL_SCALE
	_model.rotation = MODEL_ROTATION
	visual_root.add_child(_model)
	_player = _model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for clip in _player.get_animation_list():
		var animation := _player.get_animation(clip)
		if not str(clip).ends_with("_Death") and not str(clip).ends_with("_Attack"):
			animation.loop_mode = Animation.LOOP_LINEAR
	BeeToonStyle.apply(_model, true, BeeToonStyle.OUTLINE_ACTOR)
	implant = WaspImplant.new()
	implant.name = "Implant"
	implant.position = Vector3(0.0, 0.18, 0.32) * SIZE_FACTOR # On the abdomen, towards the camera.
	implant.scale = Vector3.ONE * 1.4 * maxf(SIZE_FACTOR, 0.8)
	# Hit areas follow the smaller body (shapes are per-scene sub-resources: absolute values, never compounded).
	((get_node("Hurtbox3D/CollisionShape3D") as CollisionShape3D).shape as SphereShape3D).radius = 0.7 * maxf(SIZE_FACTOR, 0.75)
	((get_node("ContactHitbox/CollisionShape3D") as CollisionShape3D).shape as SphereShape3D).radius = 0.55 * SIZE_FACTOR
	visual_root.add_child(implant)
	# LOTE 9: the whole spider damages the implant (1x); a shot lined up on the implant does 2x.
	hurtbox.weak_point = implant
	hurtbox.weak_point_radius = BeeLiberation.WEAK_POINT_RADIUS
	hurtbox.weak_point_multiplier = BeeLiberation.IMPLANT_MULTIPLIER
	if _thread_mesh == null:
		_thread_mesh = CylinderMesh.new()
		_thread_mesh.top_radius = 0.025
		_thread_mesh.bottom_radius = 0.025
		_thread_mesh.height = 1.0
		_thread_mesh.radial_segments = 5
		_thread_mesh.rings = 1
		_thread_material = StandardMaterial3D.new()
		_thread_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_thread_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_thread_material.albedo_color = SILK
		_thread_mesh.material = _thread_material
		_column_mesh = BoxMesh.new()
		_column_mesh.size = Vector3(0.5, 1.0, 0.05)
		_ring_mesh = TorusMesh.new()
		_ring_mesh.inner_radius = 0.42
		_ring_mesh.outer_radius = 0.55
		_ring_mesh.rings = 16
		_ring_mesh.ring_segments = 6
	_thread = MeshInstance3D.new()
	_thread.name = "Silk"
	_thread.mesh = _thread_mesh
	_thread.top_level = true
	_thread.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_thread)
	_column_material = StandardMaterial3D.new()
	_column_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_column_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_column_material.albedo_color = Color(BeeAlienPalette.CYAN, 0.32)
	_column = MeshInstance3D.new()
	_column.name = "TelegraphColumn"
	_column.mesh = _column_mesh
	_column.material_override = _column_material
	_column.top_level = true
	_column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_column.hide()
	add_child(_column)
	BeeAttackVisuals.WARNING_STYLE.dress(_column, BeeAlienPalette.CYAN, 7.0, telegraph_seconds)
	_ring = MeshInstance3D.new()
	_ring.name = "TelegraphRing"
	_ring.mesh = _ring_mesh
	_ring.material_override = _column_material
	_ring.top_level = true
	_ring.rotation.x = PI * 0.5 # Faces the camera.
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.hide()
	add_child(_ring)


func _update_thread(camera: Camera3D) -> void:
	var top := BeeLevel01Framing.top_y() + 2.5
	var bottom := global_position.y + 0.35
	_thread.visible = visible and current_state not in [State.FREED] and top > bottom
	var length := maxf(top - bottom, 0.01)
	_thread.global_position = Vector3(global_position.x, bottom + length * 0.5, -0.05)
	_thread.scale = Vector3(1.0, length, 1.0)


func _update_telegraph(y: float) -> void:
	var length := maxf(y - lock_y, 0.2)
	_column.global_position = Vector3(global_position.x, lock_y + length * 0.5, -0.02)
	_column.scale = Vector3(1.0, length, 1.0)
	var pulse := 1.0 + 0.12 * sin(_t * 18.0)
	_ring.global_position = Vector3(global_position.x, lock_y, 0.0)
	_ring.scale = Vector3.ONE * pulse
