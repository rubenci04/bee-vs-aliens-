class_name TarantulaDropSpider
extends Node3D
const COMMON_CUE := preload("res://scripts/vfx/bee_common_attack_cue.gd")
## LOTE 12 · ETAPA 3 — the small hanging spiders the tarantula sends from above (phase 1 and later). The thread is drawn first
## (TELEGRAPH s, the column is the warning), then the spider drops on it, hangs HOLD s (touching it hurts) and climbs back.
## One or two shots break its tiny implant: it is freed and climbs away at once (not counted in LIBERADOS: it is part of the boss).
## Model: assets/models/levels/level_01_garden/enemies/controlled_hanging_spider.glb (its own silk is replaced by a thread to the top).

const MODEL := preload("res://assets/models/levels/level_01_garden/enemies/controlled_hanging_spider.glb")
const HEALTH_SCENE := preload("res://scenes/components/health_component.tscn")
const HURTBOX_SCENE := preload("res://scenes/components/hurtbox_3d.tscn")
const TELEGRAPH := 0.7
const DROP_SECONDS := 0.25
const HOLD := 1.3
const CLIMB_SECONDS := 0.5
const DAMAGE := 5
const HP := 12
const RADIUS := 0.42
const MODEL_SCALE := 0.42
const THREAD_COLOR := Color(0.95, 0.95, 0.9, 0.85)
const WARNING_COLOR := Color(1.0, 0.62, 0.2, 0.35)

var boss: Node
var low_y := 3.0
var top := 7.5
var freed := false
var _clock := 0.0
var _thread: MeshInstance3D
var _model: Node3D
var _hitbox: DamageHitbox3D
var _hurtbox: DamageHurtbox3D
var _health: HealthComponent
var _drop_started := false # Visibility of the warning pose must not gate damage activation.


func setup(owner_boss: Node, x: float, hang_y: float, top_y: float) -> void:
	boss = owner_boss
	low_y = hang_y
	top = top_y
	top_level = true
	global_position = Vector3(x, top, 0.0)
	_thread = BeeAttackVisuals.line(self, Vector3(x, top, 0.0), Vector3(x, low_y, 0.0), 0.05, WARNING_COLOR)
	_model = MODEL.instantiate() as Node3D
	_model.scale = Vector3.ONE * MODEL_SCALE
	_model.rotation = Vector3(0.0, 0.0, deg_to_rad(-90.0)) # Head down on the thread.
	add_child(_model)
	for silk: Node3D in _model.find_children("NaturalSilk", "Node3D", true, false):
		silk.hide()
	if COMMON_CUE.enabled:
		_model.show()
		COMMON_CUE.suppress(_thread)
		var unit_ref: WeakRef = weakref(self)
		get_tree().create_timer(TELEGRAPH - COMMON_CUE.SECONDS, false).timeout.connect(func():
			var unit = unit_ref.get_ref()
			if is_instance_valid(unit) and not unit.freed:
				COMMON_CUE.begin(unit, &"spider", unit._model))
	else:
		_model.hide()
	var shape := SphereShape3D.new()
	shape.radius = RADIUS
	_hitbox = BeeAttackVisuals.hazard_area(self, boss, DAMAGE, shape)
	_health = HEALTH_SCENE.instantiate() as HealthComponent
	_health.max_health = BeeGameSettings.scaled_hp(HP)
	add_child(_health)
	_health.current_health = _health.max_health
	_health.died.connect(_free_it)
	_hurtbox = HURTBOX_SCENE.instantiate() as DamageHurtbox3D
	_hurtbox.team_id = &"alien"
	_hurtbox.health_component_path = NodePath("../" + str(_health.name))
	_hurtbox.owner_entity_path = NodePath("..")
	var collider := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = RADIUS + 0.08
	collider.shape = sphere
	_hurtbox.add_child(collider)
	_hurtbox.monitorable = false
	add_child(_hurtbox)


func is_active() -> bool:
	return not freed and _clock >= TELEGRAPH


func _physics_process(delta: float) -> void:
	_clock += delta
	var y := top
	if _clock < TELEGRAPH:
		var blink := 0.5 + 0.5 * sin(_clock * 18.0)
		_thread.scale.y = 1.0 + blink
		return
	var t := _clock - TELEGRAPH
	if freed:
		y = global_position.y + 9.0 * delta
	elif t < DROP_SECONDS:
		if not _drop_started:
			_start_drop()
		y = lerpf(top, low_y, t / DROP_SECONDS)
	elif t < DROP_SECONDS + HOLD:
		y = low_y + 0.12 * sin(t * 6.0)
	elif t < DROP_SECONDS + HOLD + CLIMB_SECONDS:
		_hitbox.set_enabled(false)
		y = lerpf(low_y, top, (t - DROP_SECONDS - HOLD) / CLIMB_SECONDS)
	else:
		queue_free()
		return
	global_position.y = y
	_model.global_position = global_position
	BeeAttackVisuals.place_line(_thread, Vector3(global_position.x, top + 1.0, 0.0), global_position)
	if freed and global_position.y > top + 0.5:
		queue_free()


func _start_drop() -> void:
	_drop_started = true
	COMMON_CUE.restore(_thread)
	_model.show()
	BeeAudio.play(get_parent(), &"spider_drop", global_position, 1.2)
	_thread.mesh.material = BeeAttackVisuals.material(THREAD_COLOR)
	_thread.scale.y = 1.0
	_hitbox.set_enabled(true)
	_hurtbox.set_deferred("monitorable", true)
	add_to_group("bee_auto_aim_targets")


func _free_it() -> void:
	if freed:
		return
	freed = true
	_hitbox.set_enabled(false)
	_hurtbox.set_deferred("monitorable", false)
	remove_from_group("bee_auto_aim_targets")
	var device := _model.find_child("AlienControlDevice", true, false) as Node3D
	BeeLiberation.free_animal(get_parent(), _model, device, global_position)


func dismiss() -> void:
	if _hitbox != null:
		_hitbox.set_enabled(false)
	queue_free()
