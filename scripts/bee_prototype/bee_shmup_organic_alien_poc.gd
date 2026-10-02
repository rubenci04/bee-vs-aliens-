extends BeeShmupStage

func _ready() -> void:
	super._ready()
	# The inherited bottle crosses the first ambush's sightline.
	$Scenery/GiantBottle.hide()
