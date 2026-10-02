extends BeeShmupStage

@onready var encounter_label: Label = $CanvasLayer/Encounter

func _ready() -> void:
	super._ready()
	$LogObstacle/CollisionShape3D.disabled = true
	$BottleObstacle/CollisionShape3D.disabled = true
	$Scenery/FallenLog.position.z = -4.0
	$Scenery/GiantBottle.position.z = -4.0
	$Scenery.position.z = -2.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	encounter_label.text = "WALKER %d/3" % wave.wave_index
	if sector_complete and not bee.is_defeated:
		status.text = "SECTOR DESPEJADO"
	elif not wave_clear_announced and not bee.is_defeated:
		status.text = "WASD/FLECHAS VOLAR · X DISPARO · Z MELEE · POLEN %d/5" % pollen_count
