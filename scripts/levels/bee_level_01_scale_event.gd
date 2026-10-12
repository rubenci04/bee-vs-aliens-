class_name BeeLevel01ScaleEvent
extends Node3D
## LOTE 10 C: reuses the lake toad as a removable-control encounter on the garden flight plane.
@export var stage_path: NodePath = ^".."
var stage: BeeShmupStage
var frog: Node3D
var landings := 0
var played := false
func _ready() -> void:
	stage = get_node(stage_path) as BeeShmupStage
	stage.get_node("WaveController").director_moment.connect(_on_moment)
func _on_moment(id: StringName) -> void:
	if id == &"scale_event" and not played:
		played = true
		_begin()
func _half_at_depth() -> float:
	return BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(get_viewport()))
func _relative_x() -> float:
	return frog.global_position.x - stage.camera.global_position.x
func _begin() -> void:
	var encounter := BeeGardenToadEncounter.new()
	encounter.name = "GardenFrog"
	add_child(encounter)
	frog = encounter
	stage.wave.register_extra_animal()
	encounter.landing.connect(func(): landings += 1)
	encounter.liberated_now.connect(func(animal): stage.wave.note_extra_liberated(animal))
	encounter.defeated.connect(func(_animal):
		if is_equal_approx(stage.scroll_speed, BeeLevel01Controller.LEVEL_SCROLL * BeeGardenToadEncounter.SCROLL_FACTOR):
			stage.scroll_speed = BeeLevel01Controller.LEVEL_SCROLL)
	stage.scroll_speed = BeeLevel01Controller.LEVEL_SCROLL * BeeGardenToadEncounter.SCROLL_FACTOR
	encounter.activate(stage.bee)
