extends BeeShmupStage

@onready var wave_label: Label = $CanvasLayer/Wave

func _ready() -> void:
	super._ready()
	$Scenery/GiantBottle.hide()
	$Scenery/FallenLog.hide()
	$SceneryExtension/GiantBottle.hide()
	$SceneryExtension/FallenLog.hide()
	$BottleObstacle/CollisionShape3D.disabled = true
	$LogObstacle/CollisionShape3D.disabled = true

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	wave_label.text = "WAVE %d/5" % wave.wave_index
	if sector_complete and not bee.is_defeated:
		status.text = "SECTOR DESPEJADO"
	elif not wave_clear_announced and not bee.is_defeated:
		status.text = "WASD/FLECHAS VOLAR · X DISPARO · Z MELEE · POLEN %d/5" % pollen_count
