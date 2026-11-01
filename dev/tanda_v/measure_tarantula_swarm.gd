extends "res://tests/levels/validate_bee_tarantula_boss_v01.gd"
## Tanda V: duración de la pelea con la tarántula (bot experto del test, Normal, Base) sin Enjambre (off) y con el
## Enjambre SIEMPRE afuera (on: se re-arma apenas termina; es el peor caso, en juego real sale una o dos veces).
## Uso: godot --headless --path . --script res://dev/tanda_v/measure_tarantula_swarm.gd -- on|off
const SWARM := preload("res://scripts/game/bee_free_swarm_settings.gd")
var mode := "off"

func run() -> void:
	var args := OS.get_cmdline_user_args()
	mode = args[0] if not args.is_empty() else "off"
	Engine.max_physics_steps_per_frame = 16
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	use_spread = false
	if mode == "on":
		_keep_swarm()
	var result := await fight("NORMAL BASE", &"expert")
	print("SWARM_MEASURE mode=%s seconds=%.1f damage=%d" % [mode, float(result.seconds), int(result.damage)])
	for line in lines: print(line)
	Engine.time_scale = 1.0
	quit(0)

func _keep_swarm() -> void:
	while true:
		await physics_frame
		var swarm: Node = stage.get_node_or_null("FreeSwarm") if is_instance_valid(stage) else null
		if swarm != null and not swarm.is_active():
			swarm.charge = SWARM.SWARM_CHARGE_NEEDED
			swarm.activate()
