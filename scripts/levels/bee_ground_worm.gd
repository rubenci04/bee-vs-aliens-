extends Node
## T4d: Level 01 adapter for both existing AssetFauna worms.
## Reuses WormB's projectile, mud style, speed, and the shared pattern factory.
enum Phase { WAIT_VISIBLE, EMERGE, REST, WARNING, FIRE }
const EARLY_RATE_RATIO := 0.6
const REFERENCE_REST := 0.6
const REFERENCE_WARNING := 0.6
const REFERENCE_LUNGE := 0.35
const REFERENCE_SPIT := 0.45
const EMERGE_SECONDS := 0.45
const EMERGE_DEPTH := 0.65
const FIRST_REST := 0.25
const WARNING_SECONDS := 0.5
const CRAWL_SPEED := 0.12
const RETRY_SECONDS := 0.15
const ENTRY_X := 4.0
const ENTRY_SPACING := 0.4
const MAX_ATTACKERS := 2
const FAN_COUNT := 3
const FAN_STEP := 16.0
const STREAM_GAP := 0.22
const DIAGONAL_ANGLE := 35.0
const ROSE_SHOT_DAMAGE := WormBehavior.LASER_DAMAGE # Preserve the replaced ranged attack's 4 damage.
const ATTACK_GROUP := &"bee_ground_worm_attacking"

var fauna: AssetFauna
var phase := Phase.WAIT_VISIBLE
var left := 0.0
var volley_interval := 0.0
var next_pattern := 0
var patterns_fired: Array[int] = []
var fired_directions: Array[Vector3] = []
var shots_left := 0
var diagonal_side := 1.0

## Original compost: lunge cycle + spit cycle, one three-shot fan every two cycles.
static func reference_interval(rest_scale: float) -> float:
	return 4.0 * REFERENCE_REST * rest_scale + 2.0 * REFERENCE_WARNING + REFERENCE_LUNGE + REFERENCE_SPIT

func setup(owner_fauna: AssetFauna, early: bool, rest_scale: float) -> void:
	fauna = owner_fauna
	name = "GroundWorm"
	volley_interval = reference_interval(rest_scale) / (EARLY_RATE_RATIO if early else 1.0)
	if fauna._worm != null: fauna._worm.cancel()
	fauna._clear_warn()
	fauna.state = AssetFauna.State.IDLE
	fauna.rig.rotation.z = 0
	fauna.rig.position.y = -EMERGE_DEPTH
	fauna.global_position.y = fauna.ground_y
	fauna._set_buried(true)
	var level := fauna.get_parent()
	var seed := int(level.get_meta("ground_worm_pattern_seed",0))
	next_pattern = seed % 3
	level.set_meta("ground_worm_pattern_seed",seed + 1)
	var camera := fauna.get_viewport().get_camera_3d()
	if camera != null:
		# Reposition only while buried, then show the complete rise at this soil spot.
		fauna.global_position.x = camera.global_position.x + ENTRY_X + ENTRY_SPACING * (seed % 3)

func is_warning() -> bool:
	return phase == Phase.WARNING

func _claim() -> bool:
	if fauna.get_tree().get_nodes_in_group(ATTACK_GROUP).size() >= MAX_ATTACKERS: return false
	fauna.add_to_group(ATTACK_GROUP)
	return true

func cancel() -> void:
	if is_instance_valid(fauna) and fauna.is_in_group(ATTACK_GROUP):
		fauna.remove_from_group(ATTACK_GROUP)
	shots_left = 0

func step_frame(delta: float) -> void:
	left -= delta
	if phase == Phase.WAIT_VISIBLE:
		if BeeShmupFairness.is_inside_screen(fauna,0.4):
			fauna._set_buried(false)
			BeeCombatVFX.spawn(fauna.get_parent(),fauna.global_position + Vector3(0,.1,0),&"rock_break",Vector3.UP,.6)
			phase = Phase.EMERGE
			left = EMERGE_SECONDS
		return
	if phase == Phase.EMERGE:
		fauna.rig.position.y = lerpf(-EMERGE_DEPTH,0.0,clampf(1.0-left/EMERGE_SECONDS,0,1))
		if left <= 0:
			fauna.rig.position.y = 0
			phase = Phase.REST
			left = FIRST_REST
		return
	fauna.global_position.y = fauna.ground_y
	if phase == Phase.REST:
		fauna.global_position.x -= CRAWL_SPEED * delta
		if left <= 0 and BeeShmupFairness.can_fire(fauna):
			if not _claim():
				left = RETRY_SECONDS
				return
			phase = Phase.WARNING
			left = WARNING_SECONDS
			fauna.attacks_started += 1
			if fauna.first_telegraph_clock < 0: fauna.first_telegraph_clock = fauna._clock
			BeeShotWarning.volley(fauna,&"worm_b",fauna.visual,WARNING_SECONDS)
	elif phase == Phase.WARNING and left <= 0:
		fauna.telegraphs.append(WARNING_SECONDS)
		phase = Phase.FIRE
		patterns_fired.append(next_pattern)
		if next_pattern == 0:
			for direction in BeeEnemyPatterns.fan_directions(Vector3.UP,FAN_COUNT,FAN_STEP): _shoot(direction)
			_finish_volley()
		else:
			shots_left = FAN_COUNT
			left = 0
	elif phase == Phase.FIRE and left <= 0:
		var direction := Vector3.UP if next_pattern == 1 else Vector3.UP.rotated(Vector3.BACK,deg_to_rad(DIAGONAL_ANGLE * diagonal_side))
		_shoot(direction)
		shots_left -= 1
		left = STREAM_GAP
		if shots_left <= 0: _finish_volley()

func _shoot(direction: Vector3) -> void:
	if not BeeShmupFairness.can_fire(fauna): return
	var reference: Dictionary = AssetFauna.KINDS[&"worm_compost"].spit
	var damage := ROSE_SHOT_DAMAGE if fauna.kind == &"worm_rose" else fauna._shot_damage()
	BeeEnemyPatterns.spawn_styled(fauna.get_parent(),AssetFauna.PROJECTILE,fauna._muzzle(),direction,damage,float(reference.speed),fauna,StringName(reference.style))
	fauna.shots_fired += 1
	fired_directions.append(direction)

func _finish_volley() -> void:
	var elapsed := WARNING_SECONDS + (STREAM_GAP * (FAN_COUNT-1) if next_pattern != 0 else 0.0)
	if next_pattern == 2: diagonal_side *= -1
	next_pattern = (next_pattern + 1) % 3
	fauna.cycles_done += 1
	cancel()
	phase = Phase.REST
	left = volley_interval - elapsed

func _exit_tree() -> void: cancel()
