class_name BeeLevel01ScaleEvent
extends Node3D
## ARCADE CONTENT & SPECTACLE REBUILD 02 — "La rana": one large, cheap moving scale event (director moment
## `scale_event`). A garden frog five times Bee's length hops across the background, stops to look around and snaps
## its tongue at the sky, then hops away. Every landing thumps (dust + low step + a tiny shake): Bee is minuscule.
## Pure presentation: the frog lives behind the flight plane (z = FROG_Z), has no collision, no damage, no target.
## Asset: Quaternius Frog (CC0, assets/external/ASSET_PROVENANCE.md).

const FROG := preload("res://assets/external/approved/fauna/quaternius/Easy Animated Enemy Pack - Jan 2019/FBX/Frog.fbx")
const FROG_Z := -4.4
const SCALE := 1.6 ## ~5.6 m long: a real frog is ~5x a bee
const HOP_LENGTH := 2.6 ## world metres; the scroll adds ~2 m of apparent travel per hop
const HOP_HEIGHT := 2.0
const HOP_SECONDS := 0.88 ## the Jump clip length
const START_AHEAD := 10.5 ## camera-relative start, just past the right edge at this depth

@export var stage_path: NodePath = ^".."

var stage: BeeShmupStage
var frog: Node3D
var landings := 0
var played := false
var _player: AnimationPlayer


func _ready() -> void:
	stage = get_node(stage_path) as BeeShmupStage
	var wave := stage.get_node("WaveController")
	if wave.has_signal("director_moment"):
		wave.director_moment.connect(_on_moment)


func _on_moment(id: StringName) -> void:
	if id == &"scale_event" and not played:
		played = true
		_begin()


func _begin() -> void:
	frog = FROG.instantiate() as Node3D
	frog.name = "GardenFrog"
	frog.scale = Vector3.ONE * SCALE
	frog.rotation.y = -PI * 0.5 # Model faces +Z; the frog hops towards -X.
	add_child(frog)
	BeeToonStyle.apply(frog, true, BeeToonStyle.OUTLINE_PROP)
	for player: AnimationPlayer in frog.find_children("*", "AnimationPlayer", true, false):
		_player = player
	var x := stage.camera.global_position.x + START_AHEAD
	frog.global_position = Vector3(x, 0.0, FROG_Z)
	# World-anchored choreography (the camera keeps scrolling): hop in, hop to the middle, look + tongue snap,
	# hop, hop out. Feet never slide while the frog is on the ground.
	var tween := create_tween()
	# Camera-relative result: enters at +10.5, lands ~+5.6, ~+0.7 (centre), looks + snaps ~1.25 s, ~-6.9, out.
	var plan := [[1, 0.25], [1, 0.3], [0, 1.25], [1, 0.35], [1, 0.0]] # [hop? (0 = tongue snap), seconds after]
	for step in plan:
		if int(step[0]) == 1:
			var from := x
			x -= HOP_LENGTH
			tween.tween_callback(_play.bind(&"Jump"))
			tween.tween_method(_hop.bind(from, x), 0.0, 1.0, HOP_SECONDS)
			tween.tween_callback(_land)
		else:
			tween.tween_callback(_play.bind(&"Attack")) # The tongue snap, then a short look around.
			tween.tween_interval(0.75)
			tween.tween_callback(_play.bind(&"Idle"))
			tween.tween_interval(maxf(float(step[1]) - 0.75, 0.0))
			continue
		if float(step[1]) > 0.0:
			tween.tween_callback(_play.bind(&"Idle"))
			tween.tween_interval(float(step[1]))
	for i in 1: # Exit: one more hop, out of view on the left.
		var from := x
		x -= HOP_LENGTH
		tween.tween_callback(_play.bind(&"Jump"))
		tween.tween_method(_hop.bind(from, x), 0.0, 1.0, HOP_SECONDS)
		tween.tween_callback(_land)
	tween.tween_callback(frog.queue_free)


func _hop(progress: float, from_x: float, to_x: float) -> void:
	if not is_instance_valid(frog):
		return
	frog.global_position = Vector3(lerpf(from_x, to_x, progress), sin(progress * PI) * HOP_HEIGHT, FROG_Z)


func _land() -> void:
	if not is_instance_valid(frog):
		return
	landings += 1
	var feet := frog.global_position
	BeeCombatVFX.spawn(stage, feet + Vector3(0.0, 0.2, 0.0), &"rock_break", Vector3.UP, 1.8)
	BeeAudio.play(stage, &"human_step", feet, 1.35) # A lighter, higher thump than the human's step.
	if absf(feet.x - stage.camera.global_position.x) < 9.0:
		BeeCameraShake.kick(self, 0.035, 0.16)


func _play(clip: StringName) -> void:
	if _player == null:
		return
	var full := StringName("FrogArmature|Frog_" + str(clip))
	if _player.has_animation(full):
		_player.get_animation(full).loop_mode = Animation.LOOP_LINEAR if clip == &"Idle" else Animation.LOOP_NONE
		_player.play(full)
