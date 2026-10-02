extends Node
## Giant Human audio. Footsteps are synced to the Run clip: one thump per foot contact.
## Contacts were measured on Hipster's Run (0.8 s loop): both feet land at t=0.0 and t=0.4.

const STEP_PERIOD := 0.4
const STEP_CUES: Array[StringName] = [&"human_step", &"human_step_b", &"human_step_c"]

var steps_played := 0
var last_step_cue: StringName = &""
var _step_index := 0
var _previous_position := 0.0
var _travelled := 0.0

func _ready() -> void:
	get_parent().phase_changed.connect(_on_phase)

func _on_phase(phase: int) -> void:
	var human := get_parent() as GiantHumanCrossingHazard
	if phase == GiantHumanCrossingHazard.Phase.TELEGRAPH:
		BeeAudio.play(human, &"human_warning", human.global_position + Vector3(0, 3, 0))
	elif phase == GiantHumanCrossingHazard.Phase.CROSSING:
		_step_index = 0
		_travelled = 0.0
		_previous_position = 0.0
		_step() # First contact: the Run clip starts with a foot on the ground.

func _physics_process(_delta: float) -> void:
	var human := get_parent() as GiantHumanCrossingHazard
	if human.current_phase != GiantHumanCrossingHazard.Phase.CROSSING or human._paused or human.animation_player == null or not human.animation_player.is_playing():
		return
	var animation_length := human.animation_player.current_animation_length
	var position := human.animation_player.current_animation_position
	var moved := position - _previous_position
	if moved < 0.0:
		moved += animation_length # The clip looped.
	_previous_position = position
	_travelled += moved
	var contacts := floori(_travelled / STEP_PERIOD + 0.0001)
	while _step_index < contacts:
		_step_index += 1
		_step()

func _step() -> void:
	var human := get_parent() as GiantHumanCrossingHazard
	if human.current_phase != GiantHumanCrossingHazard.Phase.CROSSING or human._paused:
		return
	var cue := STEP_CUES[(steps_played + (randi() % 2)) % STEP_CUES.size()]
	if cue == last_step_cue:
		cue = STEP_CUES[(STEP_CUES.find(cue) + 1) % STEP_CUES.size()]
	last_step_cue = cue
	steps_played += 1
	BeeAudio.play(human, cue, human.global_position, randf_range(0.96, 1.04))
