extends "res://dev/tanda_o/measure_burst.gd"
## Tanda U: el bot de ráfagas de la Tanda O con la reacción al golpe prendida (on) o apagada (off).
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	preload("res://scripts/game/bee_expression_settings.gd").HIT_REACTION_ENABLED = args.is_empty() or args[0] == "on"
	super._initialize()
