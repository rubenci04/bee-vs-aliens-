extends SceneTree
## Tanda X · PASO 1 (sin director_log de Rubén): una partida de bot hasta el robot. Vuela en el tercio izquierdo, dispara,
## tira bomba con 4+ enemigos en pantalla, usa el Enjambre cuando está lleno; si la vida baja de 30 la rellena (cuenta como
## "muerte"). Mide zonas, pausas sin enemigos > 4 s, vida mínima, bombas, enjambres y muertes.
## Uso: godot --headless --path . --script res://dev/tanda_x/measure_run.gd -- <semilla>
const SPEED := 2.0
const KILL_DELAY := 7.0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var run_seed := int(OS.get_cmdline_user_args()[0]) if not OS.get_cmdline_user_args().is_empty() else 1
	seed(run_seed)
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 4: await physics_frame
	stage.get_node("CheckpointQoL").set_process(false)
	var wave := stage.wave as BeeLevel01Controller
	var bee := stage.bee
	bee.set_physics_process(false)
	var swarm := stage.get_node_or_null("FreeSwarm")
	Engine.time_scale = SPEED
	var born := {}
	var t := 0.0
	var deaths := 0
	var min_hp := 100
	var quiet := 0.0
	var pauses: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed
	var wobble := rng.randf_range(0.0, TAU)
	while wave.miniboss == null and t < 700.0:
		await physics_frame
		t += SPEED / 60.0 # Segundos de juego (el bot corre a SPEED).
		var half := BeeLevel01Framing.half_width_min(BeeLevel01Framing.DESIGN_ASPECT)
		bee.global_position = Vector3(stage.distance - half * (0.55 + 0.2 * sin(t * 0.5 + wobble)), 3.2 + sin(t * 0.8 + wobble) * 1.6, 0.0)
		if int(t * 10) % 3 == 0: bee.fire()
		min_hp = mini(min_hp, bee.health.current_health)
		if bee.health.current_health < 30:
			bee.health.current_health = bee.health.max_health
			deaths += 1
		var alive := (wave.active_units + wave.swarm_units).filter(func(u): return is_instance_valid(u))
		if alive.size() >= 4 and bee.bomb_charges > 0 and not is_instance_valid(bee.active_bomb) and int(t * 10) % 20 == 0:
			bee.use_bomb()
		if is_instance_valid(bee.active_bomb) and int(t * 10) % 5 == 0:
			bee.use_bomb() # Segundo toque: detona.
		if swarm != null and swarm.is_ready() and not alive.is_empty():
			swarm.activate()
		var pieces := stage.get_node_or_null("SetPieces")
		var moment_on: bool = pieces != null and pieces.running != &""
		var watering: Node = stage.get_node_or_null("WateringEvent")
		if watering != null and bool(watering.get("running")): moment_on = true
		if alive.is_empty() and not wave.in_arena() and not moment_on:
			quiet += SPEED / 60.0
		else:
			if quiet > 4.0: pauses.append("%.0fs@x%.0f" % [quiet, stage.distance])
			quiet = 0.0
		for u in alive:
			if u is WalkerMiniboss: continue
			var id: int = u.get_instance_id()
			if not born.has(id): born[id] = t
			elif t - float(born[id]) >= KILL_DELAY * SPEED and u.has_node("HealthComponent") and not bool(u.get_meta("teleporting", false)):
				u.get_node("HealthComponent").take_damage(99999)
	var zones: Array = wave.arena_log.map(func(a): return "%.0fs" % float(a["seconds"]))
	print("RUN seed=%d robot_at=%.0fs zones=%s pauses>4s=%s min_hp=%d bombs=%d swarms=%d deaths=%d liberated=%d" % [run_seed, t, str(zones), str(pauses), min_hp, bee.bombs_used, int(swarm.uses) if swarm != null else -1, deaths, wave.liberated_count])
	Engine.time_scale = 1.0
	quit(0)
