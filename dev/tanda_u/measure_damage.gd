extends SceneTree
## Tanda U: cuánto daño evita la invulnerabilidad de 0,35 s. Juega el Nivel 1 hasta el robot (director activo) con un bot
## que vuela en el tercio izquierdo y dispara; si la vida baja de 30 la vuelve a llenar (cuenta las recargas).
## Uso: godot --headless --path . --script res://dev/tanda_u/measure_damage.gd -- on|off
const SPEED := 2.0 # time_scale <= 2 (ver memoria: a 4 los bots derivan).
const KILL_DELAY := 7.0 # Si un enemigo sigue vivo tanto tiempo, el bot lo resuelve (no apunta al suelo).
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var mode: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "on"
	preload("res://scripts/game/bee_expression_settings.gd").HIT_REACTION_ENABLED = mode == "on"
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	seed(1234)
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 4: await physics_frame
	stage.get_node("CheckpointQoL").set_process(false)
	var wave := stage.wave as BeeLevel01Controller
	var bee := stage.bee
	bee.set_physics_process(false)
	var tally := {"taken": 0, "hits": 0} # Diccionario: las lambdas copian las variables locales.
	var refills := 0
	bee.health.health_changed.connect(func(_c: int, _m: int, change: int):
		if change < 0:
			tally["taken"] -= change
			tally["hits"] += 1)
	Engine.time_scale = SPEED
	var born := {}
	var t := 0.0
	while wave.miniboss == null and t < 600.0:
		await physics_frame
		t += 1.0 / 60.0
		var half := BeeLevel01Framing.half_width_min(BeeLevel01Framing.DESIGN_ASPECT)
		bee.global_position = Vector3(stage.distance - half * (0.55 + 0.2 * sin(t * 0.5)), 3.2 + sin(t * 0.8) * 1.6, 0.0)
		if int(t * 10) % 3 == 0: bee.fire()
		if bee.health.current_health < 30:
			bee.health.current_health = bee.health.max_health
			refills += 1
		for u in wave.active_units + wave.swarm_units:
			if not is_instance_valid(u) or u is WalkerMiniboss: continue
			var id := u.get_instance_id()
			if not born.has(id): born[id] = t
			elif t - float(born[id]) >= KILL_DELAY and u.has_node("HealthComponent") and not bool(u.get_meta("teleporting", false)):
				u.get_node("HealthComponent").take_damage(99999)
	print("DAMAGE mode=%s t=%.0fs taken=%d hits=%d refills=%d" % [mode, t, tally["taken"], tally["hits"], refills])
	Engine.time_scale = 1.0
	quit(0)
