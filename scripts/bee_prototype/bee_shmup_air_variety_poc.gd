extends BeeShmupStage

@onready var wave_label: Label = $CanvasLayer/Wave

func _ready() -> void:
	super._ready()
	$Scenery/GiantBottle.hide()
	$BottleObstacle/CollisionShape3D.disabled = true

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	wave_label.text = "WAVE %d/4" % wave.wave_index
	if sector_complete and not bee.is_defeated:
		status.text = "SECTOR DESPEJADO"


