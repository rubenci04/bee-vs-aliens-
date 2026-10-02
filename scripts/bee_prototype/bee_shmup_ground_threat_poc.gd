extends BeeShmupStage

@onready var encounter_label: Label = $CanvasLayer/Encounter

func _ready() -> void:
	super._ready()
	$Scenery/GiantBottle.hide()
	$BottleObstacle/CollisionShape3D.disabled = true

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	encounter_label.text = "GROUND %d/3" % wave.wave_index
	if sector_complete and not bee.is_defeated:
		status.text = "SECTOR DESPEJADO"
