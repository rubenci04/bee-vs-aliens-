class_name UfoBoss01
extends Node3D
## BEE UFO BOSS 01 — FIRST CONTACT. Level 01 climax: the first alien ship Bee sees.
## Simple state machine: APPROACH -> PHASE_1 -> PHASE_2 -> PHASE_3 -> DEATH (TRANSITION in between).
## Gameplay stays on the Z=0 plane; only the approach uses visual depth (it flies in from far Z).
## Everything is built in code (no external UFO asset) with Style C toon materials.

signal defeated(boss: UfoBoss01)
signal phase_changed(state: int)
signal projectile_fired(projectile: AlienEnemyProjectile, pattern: StringName)
## BOSS CHALLENGE V2 (REBUILD 03): the level director spawns `count` minions of `family` launched from the saucer.
signal summon_requested(family: StringName, count: int)

enum State { APPROACH, PHASE_1, PHASE_2, PHASE_3, TRANSITION, DEATH, DONE }

const PROJECTILE := preload("res://scenes/levels/ufo_boss_projectile.tscn")
const PROJECTILE_GROUP := &"ufo_boss_projectiles"
const DISPLAY_NAME := "ALIEN SCOUT"

## HP from the measured DPS (see docs/BEE_UFO_BOSS_01.md): ~60 s for a reasonable player.
@export var max_hp := 1300
const PHASE_2_RATIO := 0.66
const PHASE_3_RATIO := 0.33

const APPROACH_SECONDS := 3.2
const START_OFFSET := Vector3(4.0, 2.4, -38.0) # Far in depth, up and to the right of the arena anchor.
const ANCHOR_DX := 3.3 # Arena position: right part of the screen, Bee keeps the left.
const CENTER_Y := 3.9
const TRANSITION_SECONDS := 0.9

# Per phase: [bob amplitude, bob period, cooldown, aimed telegraph, fan telegraph].
# Amplitude keeps the whole saucer inside the preset E frame (top edge ~7.1 m at the play plane).
## BOSS CHALLENGE V2 (REBUILD 03): more active movement per phase - a figure-eight over the right part of the arena
## (X amplitude per phase) plus, from phase 2, a slow approach / retreat. Never chases Bee and never leaves the band
## [X_MIN, half width - X_EDGE] in front of the camera, so the left of the screen is always an escape route.
const MOVE_X := {State.PHASE_1: 0.7, State.PHASE_2: 1.1, State.PHASE_3: 1.4}
const APPROACH_X := {State.PHASE_1: 0.0, State.PHASE_2: 0.8, State.PHASE_3: 1.1}
const X_MIN := 1.4
const X_EDGE := 2.2
## Minions: phase 2 launches 2 EyeDrones (then again whenever none is left, every MINION_COOLDOWN s); phase 3 launches
## a single Probe only when the screen is clean enough. While summoning the saucer does not attack (~1 s).
const SUMMON_SECONDS := 1.0
const MINION_COOLDOWN := {State.PHASE_2: 11.0, State.PHASE_3: 13.0}
const MAX_MINIONS := {State.PHASE_2: 2, State.PHASE_3: 1}
const PHASE_TUNING := {
	State.PHASE_1: [1.0, 5.4, 1.45, 0.6, 0.7],
	State.PHASE_2: [1.3, 4.6, 1.3, 0.55, 0.7],
	State.PHASE_3: [1.5, 3.4, 1.0, 0.5, 0.6],
}
const AIMED_SHOTS := 3
const AIMED_INTERVAL := 0.14
const AIMED_SPEED := 6.2
const FAN_SHOTS := 5
const FAN_STEP_DEGREES := 17.0 # 5 shots over 68°: gaps of ~1.7 m at Bee's distance.
const FAN_SPEED := 4.8
const SHOT_DAMAGE := 8
const CONTACT_DAMAGE := 12

const COLORS := {
	"hull": Color(0.56, 0.6, 0.66), "ring": Color(0.3, 0.33, 0.4), "panel": Color(0.2, 0.22, 0.27),
	"dome": Color(0.25, 0.85, 0.95), "emitter": Color(0.15, 0.95, 1.0), "core": Color(0.62, 0.22, 0.95),
}

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: DamageHurtbox3D = $Hurtbox3D
@onready var contact: DamageHitbox3D = $ContactHitbox
@onready var visual_root: Node3D = $VisualRoot
@onready var hit_flash: HitFlash3D = $HitFlash3D

var state := State.APPROACH
var camera: Camera3D
var target: BeePlayer
var anchor := Vector3.ZERO
var fired_aimed := 0
var fired_fan := 0
var attacks_started := 0
var transitions := 0
var _next_state := State.PHASE_1
var _state_time := 0.0
var _bob_time := 0.0
var _attack_step := &"cooldown" # cooldown | telegraph | burst
var _attack_left := 0.6
var _pattern := &"aimed"
var _burst_left := 0
var _emitters: Array[MeshInstance3D] = []
var _core: MeshInstance3D
var _glow_materials: Array[ShaderMaterial] = []
var _hover: AudioStreamPlayer3D
var _bar_layer: CanvasLayer
var _bar: ProgressBar
var _death_tween: Tween
var _contact_refresh := 0.0
var minions_alive := 0 # Written by the level director every frame.
var summons := 0
var _summon_cooldown := 1.6


func _ready() -> void:
	health.max_health = max_hp
	health.current_health = max_hp
	health.damage_blocked = true
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_die)
	hurtbox.monitorable = false
	contact.team_id = &"alien"
	contact.damage = CONTACT_DAMAGE
	contact.set_enabled(false)
	_build_visual()
	_build_health_bar()
	_hover = AudioStreamPlayer3D.new()
	_hover.name = "HoverLoop"
	var source := load("res://audio/sfx/real/ufo_hover.wav") as AudioStreamWAV
	if source != null:
		var stream := source.duplicate() as AudioStreamWAV
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.data.size() / 2
		_hover.stream = stream
	_hover.bus = &"SFX"
	_hover.volume_db = -60.0
	_hover.unit_size = 12.0
	_hover.max_distance = 60.0
	add_child(_hover)
	set_physics_process(false)


## Called by the level controller once the last encounter is cleared and the arena is locked.
func begin(stage_camera: Camera3D, bee: BeePlayer) -> void:
	camera = stage_camera
	target = bee
	anchor = Vector3(camera.global_position.x + ANCHOR_DX, CENTER_Y, 0.0)
	global_position = anchor + START_OFFSET
	state = State.APPROACH
	_state_time = 0.0
	visual_root.scale = Vector3.ONE * 0.8
	_play_long("res://audio/sfx/real/ufo_sting.wav", "UfoSting", -12.0)
	if DisplayServer.get_name() != "headless" and _hover.stream != null:
		_hover.play()
	create_tween().tween_property(_hover, "volume_db", -22.0, APPROACH_SECONDS)
	set_physics_process(true)


func is_active() -> bool:
	return state in [State.PHASE_1, State.PHASE_2, State.PHASE_3, State.TRANSITION]


func is_defeated() -> bool:
	return state == State.DEATH or state == State.DONE


func is_vulnerable() -> bool:
	return is_active() and not health.damage_blocked


func live_projectiles() -> Array:
	return get_tree().get_nodes_in_group(PROJECTILE_GROUP).filter(func(p: Node): return not p.is_queued_for_deletion())


## Bee defeated: everything stops in place (the scene is reloaded by R).
func freeze() -> void:
	set_physics_process(false)
	contact.set_enabled(false)
	_set_charge(0.0)
	if _hover != null:
		_hover.stop()


func _physics_process(delta: float) -> void:
	_state_time += delta
	match state:
		State.APPROACH:
			var t := clampf(_state_time / APPROACH_SECONDS, 0.0, 1.0)
			var eased := 1.0 - pow(1.0 - t, 3.0)
			global_position = (anchor + START_OFFSET).lerp(anchor, eased)
			visual_root.rotation.y += delta * lerpf(2.6, 0.6, t)
			_set_glow(lerpf(3.0, 1.0, t))
			if t >= 1.0:
				_enter_fight()
		State.PHASE_1, State.PHASE_2, State.PHASE_3:
			_move(delta)
			_attack(delta)
			_refresh_contact(delta)
		State.TRANSITION:
			_move(delta * 0.5)
			var pulse := sin(_state_time / TRANSITION_SECONDS * PI)
			_core.scale = Vector3.ONE * (1.0 + 0.5 * pulse)
			_set_glow(1.0 + 2.5 * pulse)
			if _state_time >= TRANSITION_SECONDS:
				_core.scale = Vector3.ONE
				_set_glow(1.0)
				_change_state(_next_state)
				_attack_step = &"cooldown"
				_attack_left = 0.5


func _enter_fight() -> void:
	global_position = anchor
	health.damage_blocked = false
	hurtbox.set_deferred("monitorable", true)
	add_to_group("bee_auto_aim_targets")
	contact.set_enabled(true)
	_bar_layer.visible = true
	_bob_time = 0.0
	_attack_step = &"cooldown"
	_attack_left = 0.8
	_change_state(State.PHASE_1)


func _change_state(value: int) -> void:
	state = value
	_state_time = 0.0
	phase_changed.emit(state)


func _tuning() -> Array:
	return PHASE_TUNING.get(state if state != State.TRANSITION else _next_state, PHASE_TUNING[State.PHASE_1])


func _move(delta: float) -> void:
	var tuning := _tuning()
	_bob_time += delta
	var phase: int = state if state != State.TRANSITION else _next_state
	var period := float(tuning[1])
	var y := CENTER_Y + sin(_bob_time * TAU / period) * float(tuning[0])
	# Figure-eight: X runs at half the vertical frequency; from phase 2 a slow approach / retreat on top.
	var x := anchor.x + sin(_bob_time * PI / period) * float(MOVE_X.get(phase, 0.35)) \
			- maxf(0.0, sin(_bob_time * 0.42)) * float(APPROACH_X.get(phase, 0.0))
	if camera != null:
		var half := BeeShmupFairness.visible_half_width(camera, Vector3(camera.global_position.x, y, 0.0), BeeLevel01Framing.view_aspect(get_viewport()))
		x = clampf(x, camera.global_position.x + X_MIN, camera.global_position.x + half - X_EDGE)
	global_position = Vector3(x, y, 0.0)
	visual_root.rotation.y += delta * 0.6
	visual_root.rotation.z = lerpf(visual_root.rotation.z, cos(_bob_time * TAU / float(tuning[1])) * 0.08, delta * 3.0)


func _refresh_contact(delta: float) -> void:
	# The contact hitbox hits once per enable; re-arm it so touching the hull keeps hurting.
	_contact_refresh -= delta
	if _contact_refresh <= 0.0:
		_contact_refresh = 1.5
		contact.set_enabled(true)


# --- attacks ----------------------------------------------------------------------------------

func _attack(delta: float) -> void:
	_attack_left -= delta
	var tuning := _tuning()
	if state == State.PHASE_2 or state == State.PHASE_3:
		_summon_cooldown -= delta
	match _attack_step:
		&"summon":
			# Pressure dip: no attack while the hatch opens (the core pulses), then the minions launch.
			var pulse := sin(clampf(1.0 - _attack_left / SUMMON_SECONDS, 0.0, 1.0) * PI)
			_core.scale = Vector3.ONE * (1.0 + 0.6 * pulse)
			_set_glow(1.0 + 2.0 * pulse)
			if _attack_left <= 0.0:
				_core.scale = Vector3.ONE
				_set_glow(1.0)
				var family := &"EyeDrone" if state == State.PHASE_2 else &"Probe"
				summon_requested.emit(family, maxi(int(MAX_MINIONS.get(state, 0)) - minions_alive, 0))
				summons += 1
				_summon_cooldown = float(MINION_COOLDOWN.get(state, 12.0))
				_attack_step = &"cooldown"
				_attack_left = 0.8
		&"cooldown":
			if _attack_left <= 0.0 and _wants_summon():
				_attack_step = &"summon"
				_attack_left = SUMMON_SECONDS
				BeeAudio.play(get_parent(), &"ufo_charge", global_position, 0.7)
			elif _attack_left <= 0.0:
				_pattern = _choose_pattern()
				_attack_step = &"telegraph"
				_attack_left = float(tuning[3]) if _pattern == &"aimed" else float(tuning[4])
				attacks_started += 1
				BeeAudio.play(get_parent(), &"ufo_charge", global_position, 1.2 if _pattern == &"aimed" else 0.85)
		&"telegraph":
			var total := float(tuning[3]) if _pattern == &"aimed" else float(tuning[4])
			_set_charge(1.0 - _attack_left / total)
			if _attack_left <= 0.0:
				_set_charge(0.0)
				if _pattern == &"fan" or _pattern == &"fan_aimed":
					_fire_fan()
				if _pattern == &"aimed" or _pattern == &"fan_aimed":
					_attack_step = &"burst"
					_burst_left = AIMED_SHOTS
					_attack_left = 0.0 if _pattern == &"aimed" else 0.35
				else:
					_attack_step = &"cooldown"
					_attack_left = float(tuning[2])
		&"burst":
			if _attack_left <= 0.0:
				_fire_aimed()
				_burst_left -= 1
				_attack_left = AIMED_INTERVAL
				if _burst_left <= 0:
					_attack_step = &"cooldown"
					_attack_left = float(tuning[2])


func _wants_summon() -> bool:
	var cap := int(MAX_MINIONS.get(state, 0))
	if cap <= 0 or _summon_cooldown > 0.0 or minions_alive > 0:
		return false
	if state == State.PHASE_3: # Only when the screen is clean enough: never a minion on top of a full pattern.
		return get_tree().get_nodes_in_group("alien_projectiles").size() <= 4
	return true


func _choose_pattern() -> StringName:
	match state:
		State.PHASE_1:
			return &"aimed"
		State.PHASE_2:
			return &"fan" if attacks_started % 2 == 1 else &"aimed"
		_:
			return &"fan_aimed" if attacks_started % 2 == 1 else &"aimed"


func _muzzle_for_aimed() -> Vector3:
	# The emitter closest to Bee fires; the visual and the origin match.
	var best := global_position
	var best_distance := INF
	for emitter in _emitters:
		var p := emitter.global_position
		var d := p.distance_to(target.global_position)
		if d < best_distance:
			best_distance = d
			best = p
	return Vector3(best.x, best.y, 0.0)


func _fire_aimed() -> void:
	if target == null or not BeeShmupFairness.can_fire(self):
		return
	var origin := _muzzle_for_aimed()
	var direction := target.global_position - origin # Bee's position at the moment of this shot.
	_spawn_projectile(origin, Vector3(direction.x, direction.y, 0.0).normalized(), AIMED_SPEED, &"aimed")
	fired_aimed += 1


func _fire_fan() -> void:
	if target == null or not BeeShmupFairness.can_fire(self):
		return
	var origin := Vector3(_core.global_position.x, _core.global_position.y, 0.0)
	var to_bee := target.global_position - origin
	var base := atan2(to_bee.y, to_bee.x)
	for i in FAN_SHOTS:
		var angle := base + deg_to_rad(FAN_STEP_DEGREES) * (float(i) - float(FAN_SHOTS - 1) * 0.5)
		_spawn_projectile(origin, Vector3(cos(angle), sin(angle), 0.0), FAN_SPEED, &"fan")
		fired_fan += 1


func _spawn_projectile(origin: Vector3, direction: Vector3, speed: float, pattern: StringName) -> void:
	var projectile := PROJECTILE.instantiate() as AlienEnemyProjectile
	projectile.damage = SHOT_DAMAGE
	projectile.speed = speed
	projectile.add_to_group(PROJECTILE_GROUP)
	get_parent().add_child(projectile)
	projectile.global_position = origin
	projectile.rotation.z = atan2(direction.y, direction.x) # Trail points backwards.
	projectile.launch(direction, self)
	projectile_fired.emit(projectile, pattern)


func clear_projectiles() -> int:
	var cleared := 0
	for node in get_tree().get_nodes_in_group(PROJECTILE_GROUP):
		var projectile := node as AlienEnemyProjectile
		if projectile == null or projectile.is_queued_for_deletion():
			continue
		projectile.hitbox.set_enabled(false)
		projectile.queue_free()
		cleared += 1
	return cleared


# --- health and phases ------------------------------------------------------------------------

func _on_health_changed(current: int, maximum: int, change: int) -> void:
	if _bar != null:
		_bar.value = float(current) / float(maximum) * 100.0
	if change < 0 and current > 0:
		var punch := create_tween()
		punch.tween_property(visual_root, "scale", Vector3.ONE * 0.84, 0.05)
		punch.tween_property(visual_root, "scale", Vector3.ONE * 0.8, 0.08)
	if not (state in [State.PHASE_1, State.PHASE_2, State.PHASE_3]) or current <= 0:
		return
	var ratio := float(current) / float(maximum)
	var wanted := State.PHASE_3 if ratio <= PHASE_3_RATIO else (State.PHASE_2 if ratio <= PHASE_2_RATIO else State.PHASE_1)
	if wanted > state:
		_next_state = wanted
		_summon_cooldown = 1.6 if wanted == State.PHASE_2 else 3.0
		transitions += 1
		_set_charge(0.0)
		_attack_step = &"cooldown"
		_change_state(State.TRANSITION)
		BeeAudio.play(get_parent(), &"ufo_charge", global_position, 0.6)


func _die() -> void:
	if is_defeated():
		return
	_change_state(State.DEATH)
	health.damage_blocked = true
	contact.set_enabled(false)
	hurtbox.set_deferred("monitorable", false)
	remove_from_group("bee_auto_aim_targets")
	_set_charge(0.0)
	clear_projectiles() # No unfair hit after the win.
	_bar_layer.visible = false
	set_physics_process(false)
	hit_flash.flash()
	BeeAudio.play(get_parent(), &"tech_death", global_position)
	var fall := create_tween().set_parallel(true)
	fall.tween_property(self, "global_position", global_position + Vector3(0.6, -2.4, 0.0), 2.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	fall.tween_property(visual_root, "rotation:z", 0.55, 2.2)
	fall.tween_method(_set_glow, 2.5, 0.0, 2.0)
	fall.tween_property(_hover, "volume_db", -60.0, 1.2)
	_death_tween = create_tween()
	for i in 4:
		_death_tween.tween_callback(_spark.bind(i))
		_death_tween.tween_interval(0.3)
	_death_tween.tween_callback(_main_explosion)
	_death_tween.tween_interval(1.1)
	_death_tween.tween_callback(_finish)


func _spark(index: int) -> void:
	var offset := Vector3([-0.9, 0.8, -0.3, 0.5][index], [0.2, -0.1, 0.35, -0.25][index], 0.4)
	BeeCombatVFX.spawn(get_parent(), global_position + offset, &"tech_death", Vector3.RIGHT, 0.8)
	BeeAudio.play(get_parent(), &"tech_hit", global_position + offset, 0.8)
	BeeCameraShake.kick(self, 0.03, 0.15)


func _main_explosion() -> void:
	BeeCombatVFX.spawn(get_parent(), global_position, &"bomb", Vector3.RIGHT, 2.6)
	BeeCombatVFX.spawn(get_parent(), global_position, &"heavy_death", Vector3.RIGHT, 2.0) # REBUILD 03: layered blast.
	BeeCameraShake.kick(self, 0.09, 0.45)
	_play_long("res://audio/sfx/real/ufo_death.wav", "UfoDeath", -9.0)
	visual_root.hide()


func _finish() -> void:
	_hover.stop()
	state = State.DONE
	defeated.emit(self)
	queue_free()


# --- visuals ----------------------------------------------------------------------------------

func _material(color: Color, emissive := false, energy := 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.6
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = energy
	return material


func _part(mesh: Mesh, material: StandardMaterial3D, label: String, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	if mesh is PrimitiveMesh:
		(mesh as PrimitiveMesh).material = material
	else:
		mesh.surface_set_material(0, material)
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.position = pos
	node.rotation = rot
	visual_root.add_child(node)
	return node


## Compact saucer: lower core, wide hull, outer ring, glass dome, 4 emitters, 4 small fins.
func _build_visual() -> void:
	var hull := GardenProps.loft([[-0.38, 0.45, 0.45, 0, 0], [-0.28, 0.95, 0.95, 0, 0], [-0.1, 1.42, 1.42, 0, 0], [0.0, 1.55, 1.55, 0, 0],
			[0.1, 1.45, 1.45, 0, 0], [0.22, 1.05, 1.05, 0, 0], [0.32, 0.64, 0.64, 0, 0]], 24, true, true, 0.0, true)
	_part(hull, _material(COLORS["hull"]), "Hull")
	var ring := TorusMesh.new()
	ring.inner_radius = 1.5
	ring.outer_radius = 1.7
	ring.rings = 28
	ring.ring_segments = 8
	_part(ring, _material(COLORS["ring"]), "OuterRing")
	var dome := SphereMesh.new()
	dome.radius = 0.62
	dome.height = 0.62
	dome.is_hemisphere = true
	dome.radial_segments = 20
	dome.rings = 6
	_part(dome, _material(COLORS["dome"], true, 0.9), "Dome", Vector3(0, 0.3, 0))
	var core := SphereMesh.new()
	core.radius = 0.34
	core.height = 0.5
	core.radial_segments = 16
	core.rings = 8
	_core = _part(core, _material(COLORS["core"], true, 1.2), "AlienCore", Vector3(0, -0.42, 0))
	for i in 4:
		var a := TAU * (float(i) + 0.5) / 4.0
		var emitter := SphereMesh.new()
		emitter.radius = 0.15
		emitter.height = 0.24
		emitter.radial_segments = 10
		emitter.rings = 5
		_emitters.append(_part(emitter, _material(COLORS["emitter"], true, 2.0), "Emitter%d" % i, Vector3(cos(a) * 1.08, -0.24, sin(a) * 1.08)))
		var fin := BoxMesh.new()
		fin.size = Vector3(0.38, 0.09, 0.2)
		var b := TAU * float(i) / 4.0
		_part(fin, _material(COLORS["panel"]), "Fin%d" % i, Vector3(cos(b) * 1.62, 0.06, sin(b) * 1.62), Vector3(0, -b, 0))
	BeeToonStyle.apply(visual_root, true, BeeToonStyle.OUTLINE_ACTOR)
	# Own copies of the glowing materials so telegraphs never touch other actors.
	var glowing: Array[MeshInstance3D] = [_core, visual_root.get_node("Dome") as MeshInstance3D]
	glowing.append_array(_emitters)
	for node: MeshInstance3D in glowing:
		var shared := node.get_surface_override_material(0) as ShaderMaterial
		var own := shared.duplicate() as ShaderMaterial
		own.set_meta("base_energy", own.get_shader_parameter("emission_energy"))
		node.set_surface_override_material(0, own)
		_glow_materials.append(own)


func _set_glow(multiplier: float) -> void:
	for material in _glow_materials:
		material.set_shader_parameter("emission_energy", float(material.get_meta("base_energy")) * multiplier)


## Telegraph: emitters (aimed) or the lower core (fan) swell and brighten while charging.
func _set_charge(progress: float) -> void:
	var fan := _pattern != &"aimed"
	for emitter in _emitters:
		emitter.scale = Vector3.ONE * (1.0 + (0.0 if fan else 0.7 * progress))
	if _core != null:
		_core.scale = Vector3.ONE * (1.0 + (0.6 * progress if fan else 0.0))
	for material in _glow_materials:
		material.set_shader_parameter("emission_energy", float(material.get_meta("base_energy")) * (1.0 + 2.2 * progress))


func _build_health_bar() -> void:
	_bar_layer = CanvasLayer.new()
	_bar_layer.name = "BossHealthBar"
	_bar_layer.layer = 5
	_bar_layer.visible = false
	add_child(_bar_layer)
	var box := VBoxContainer.new()
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.offset_left = -220.0
	box.offset_right = 220.0
	box.offset_top = 14.0
	_bar_layer.add_child(box)
	var title := Label.new()
	title.text = DISPLAY_NAME
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 5)
	box.add_child(title)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(440, 14)
	_bar.show_percentage = false
	_bar.value = 100.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.72, 0.25, 1.0)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.08, 0.06, 0.12, 0.75)
	_bar.add_theme_stylebox_override("fill", fill)
	_bar.add_theme_stylebox_override("background", back)
	box.add_child(_bar)


func health_bar_visible() -> bool:
	return _bar_layer != null and _bar_layer.visible


## Long one-shots (sting, final explosion) live under the level, not under the boss, so the
## explosion is not cut when the boss frees itself; a level reload frees them like any node.
func _play_long(path: String, label: String, volume_db: float) -> void:
	var stream := load(path) as AudioStream
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.name = label
	player.stream = stream
	player.bus = &"SFX"
	player.volume_db = volume_db
	get_parent().add_child(player)
	player.finished.connect(player.queue_free)
	var lifetime := Timer.new() # Owned by the player: no callback can outlive it.
	lifetime.one_shot = true
	lifetime.wait_time = stream.get_length() + 0.2
	lifetime.autostart = true
	lifetime.timeout.connect(player.queue_free)
	player.add_child(lifetime)
	if DisplayServer.get_name() != "headless":
		player.play()
