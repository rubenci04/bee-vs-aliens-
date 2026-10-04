class_name BeeLevel01ScaleEvent
extends Node3D
## ARCADE CONTENT & SPECTACLE REBUILD 02 — "La rana": one large, cheap moving scale event (director moment
## `scale_event`). A garden frog five times Bee's length hops across the background, stops to snap its tongue at the
## sky, then hops away. Every landing thumps (dust + low step + a tiny shake): Bee is minuscule.
## Pure presentation: the frog lives behind the flight plane (z = FROG_Z), has no collision, no damage, no target.
## REBUILD 03 staging fix (playtest: "rough entry, it goes through the bottle"):
##   - it hops BEHIND the distant bottle (z -10.5; legs spread ~3.3 m each way in depth), never through it;
##   - it enters from beyond the real visible edge at its own depth (no popping in on screen);
##   - every hop has anticipation: crouch -> jump (stretch) -> landing squash.
## Asset: Quaternius Frog (CC0, assets/external/ASSET_PROVENANCE.md).

const FROG := preload("res://assets/external/approved/fauna/quaternius/Easy Animated Enemy Pack - Jan 2019/FBX/Frog.fbx")
const FROG_Z := -10.5
const SCALE := 1.9 ## ~6.6 m long; further back, so a little bigger to keep the "giant" read
const HOP_LENGTH := 3.4
const HOP_HEIGHT := 2.4
const HOP_SECONDS := 0.88 ## the Jump clip length
const CROUCH_SECONDS := 0.16
const OFFSCREEN_MARGIN := 4.5 ## starts this far past the visible edge (the frog is ~6 m long)
const STOP_AT := 1.0 ## camera-relative X where it stops to snap its tongue

@export var stage_path: NodePath = ^".."

var stage: BeeShmupStage
var frog: Node3D
var landings := 0
var played := false
var max_hops := 12
var _player: AnimationPlayer
var _phase := &"in" # in -> snap -> out
var _hops := 0


func _ready() -> void:
	stage = get_node(stage_path) as BeeShmupStage
	var wave := stage.get_node("WaveController")
	if wave.has_signal("director_moment"):
		wave.director_moment.connect(_on_moment)


func _on_moment(id: StringName) -> void:
	if id == &"scale_event" and not played:
		played = true
		_begin()


## Visible half width at the frog's depth (camera-aware: works for any framing preset).
func _half_at_depth() -> float:
	var point := Vector3(stage.camera.global_position.x, 1.0, FROG_Z)
	return BeeShmupFairness.visible_half_width(stage.camera, point, BeeLevel01Framing.view_aspect(get_viewport()))


func _relative_x() -> float:
	return frog.global_position.x - stage.camera.global_position.x


func _begin() -> void:
	frog = FROG.instantiate() as Node3D
	frog.name = "GardenFrog"
	frog.scale = Vector3.ONE * SCALE
	frog.rotation.y = -PI * 0.5 # Model faces +Z; the frog hops towards -X.
	add_child(frog)
	BeeToonStyle.apply(frog, true, BeeToonStyle.OUTLINE_PROP)
	for player: AnimationPlayer in frog.find_children("*", "AnimationPlayer", true, false):
		_player = player
	frog.global_position = Vector3(stage.camera.global_position.x + _half_at_depth() + OFFSCREEN_MARGIN, 0.0, FROG_Z)
	_play(&"Idle")
	_next_step()


## Decides the next beat from where the frog is now on screen (the camera keeps scrolling).
func _next_step() -> void:
	if not is_instance_valid(frog):
		return
	if _phase == &"in" and _relative_x() <= STOP_AT:
		_phase = &"snap"
		var snap := create_tween()
		snap.tween_callback(_play.bind(&"Attack")) # The tongue snap at the sky.
		snap.tween_interval(0.75)
		snap.tween_callback(_play.bind(&"Idle"))
		snap.tween_interval(0.5)
		snap.tween_callback(func(): _phase = &"out")
		snap.tween_callback(_next_step)
		return
	if (_phase == &"out" and _relative_x() < -(_half_at_depth() + OFFSCREEN_MARGIN)) or _hops >= max_hops:
		frog.queue_free()
		return
	_hop()


func _hop() -> void:
	_hops += 1
	var from := frog.global_position.x
	var to := from - HOP_LENGTH
	var base := Vector3.ONE * SCALE
	var hop := create_tween()
	# Anticipation: a quick crouch, then the jump with a little stretch, then the landing squash.
	hop.tween_property(frog, "scale", Vector3(base.x * 1.08, base.y * 0.82, base.z * 1.08), CROUCH_SECONDS)
	hop.tween_callback(_play.bind(&"Jump"))
	hop.tween_property(frog, "scale", Vector3(base.x * 0.96, base.y * 1.08, base.z * 0.96), 0.12)
	hop.parallel().tween_method(_arc.bind(from, to), 0.0, 1.0, HOP_SECONDS)
	hop.tween_callback(_land)
	hop.tween_property(frog, "scale", Vector3(base.x * 1.1, base.y * 0.86, base.z * 1.1), 0.07)
	hop.tween_property(frog, "scale", base, 0.12)
	hop.tween_callback(_play.bind(&"Idle"))
	hop.tween_interval(0.18 if _phase == &"in" else 0.1)
	hop.tween_callback(_next_step)


func _arc(progress: float, from_x: float, to_x: float) -> void:
	if not is_instance_valid(frog):
		return
	frog.global_position = Vector3(lerpf(from_x, to_x, progress), sin(progress * PI) * HOP_HEIGHT, FROG_Z)


func _land() -> void:
	if not is_instance_valid(frog):
		return
	landings += 1
	var feet := frog.global_position
	BeeCombatVFX.spawn(stage, feet + Vector3(0.0, 0.2, 0.0), &"rock_break", Vector3.UP, 2.0)
	BeeAudio.play(stage, &"human_step", feet, 1.35) # A lighter, higher thump than the human's step.
	if absf(_relative_x()) < _half_at_depth():
		BeeCameraShake.kick(self, 0.035, 0.16)


func _play(clip: StringName) -> void:
	if _player == null:
		return
	var full := StringName("FrogArmature|Frog_" + str(clip))
	if _player.has_animation(full):
		_player.get_animation(full).loop_mode = Animation.LOOP_LINEAR if clip == &"Idle" else Animation.LOOP_NONE
		_player.play(full)
