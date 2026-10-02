extends BeeShmupStage

@onready var hazard: GiantHumanCrossingHazard = $GiantHuman
@onready var warning: Label = $CanvasLayer/HumanWarning

func _ready() -> void:
	super._ready()
	$Scenery.hide()
	$LogObstacle/CollisionShape3D.disabled = true
	$BottleObstacle/CollisionShape3D.disabled = true
	hazard.phase_changed.connect(_on_hazard_phase_changed)
	warning.hide()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if sector_complete and not bee.is_defeated:
		status.text = "SECTOR DESPEJADO"
	elif not wave_clear_announced and not bee.is_defeated:
		status.text = "WASD/FLECHAS VOLAR · X DISPARO · Z MELEE · POLEN %d/5" % pollen_count

func _on_hazard_phase_changed(phase: int) -> void:
	warning.visible = phase == GiantHumanCrossingHazard.Phase.TELEGRAPH
