extends Node

func _ready() -> void:
	get_parent().phase_changed.connect(_on_phase)

func _on_phase(phase: int) -> void:
	var human := get_parent() as GiantHumanCrossingHazard
	if phase == GiantHumanCrossingHazard.Phase.TELEGRAPH:
		BeeAudio.play(human, &"human_warning", human.global_position + Vector3(0, 3, 0))
	elif phase == GiantHumanCrossingHazard.Phase.CROSSING:
		_step()
		get_tree().create_timer(3.0, true, false, true).timeout.connect(_step)

func _step() -> void:
	var human := get_parent() as GiantHumanCrossingHazard
	if human.current_phase == GiantHumanCrossingHazard.Phase.CROSSING and not human._paused:
		BeeAudio.play(human, &"human_step", human.global_position)
