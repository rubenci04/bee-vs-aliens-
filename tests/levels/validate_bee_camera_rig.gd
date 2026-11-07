extends SceneTree
# Mejora visual: la cámara 2.5D. En modo headless no corre (los bots siguen midiendo la lateral). Toda la zona de vuelo tiene que
# quedar dentro de la pantalla en cualquier punto del nivel, y las apariciones tienen que nacer fuera de lo que se ve.
const S := preload("res://scripts/game/bee_camera_settings.gd")
const STEP := 2.0

func _initialize() -> void:
	call_deferred("run")

func fail(message: String) -> void:
	push_error(message)
	print("FAIL: ", message)
	quit(1)

func corner_at(at: float, left: float, right: float, top: float, bottom: float) -> float:
	var framing := BeeCameraRig.framing_at(at)
	var worst := 0.0
	for point in [Vector3(left, top, 0), Vector3(left, bottom, 0), Vector3(right, top, 0), Vector3(right, bottom, 0)]:
		var s := BeeCameraRig.screen_point(point, framing, BeeLevel01Framing.DESIGN_ASPECT, S.BEE_YAW_FROM_X + S.BREATH_YAW, S.ROLL_MAX)
		worst = maxf(worst, maxf(absf(s.x), absf(s.y)))
	return worst

func run() -> void:
	if BeeCameraRig.enabled():
		fail("el rig no debe correr en headless")
		return
	if BeeCameraRig.attach(root) != null:
		fail("attach debe devolver null en headless")
		return
	if BeeCameraRig.logic_active or BeeLevel01Framing.render_right_extra != 0.0:
		fail("sin rig no puede cambiar la lógica de pantalla")
		return
	var left := BeeLevel01Framing.flight_left_offset(BeeLevel01Framing.DESIGN_ASPECT)
	var right := BeeLevel01Framing.flight_right_offset(BeeLevel01Framing.DESIGN_ASPECT)
	var top := minf(7.2, BeeLevel01Framing.top_y() - BeeLevel01Framing.FLIGHT_MARGIN)
	var bottom := maxf(0.7, BeeLevel01Framing.bottom_y() + BeeLevel01Framing.FLIGHT_MARGIN)
	var worst := 0.0
	var worst_at := 0.0
	var x := 0.0
	while x <= 365.0:
		var framing := BeeCameraRig.framing_at(x)
		BeeLevel01Framing.robot_arena_weight = 1.0 if x >= 294.0 and x <= 325.0 else 0.0 # La arena del robot abre y baja la cámara.
		left = BeeLevel01Framing.flight_left_offset(BeeLevel01Framing.DESIGN_ASPECT)
		right = BeeLevel01Framing.flight_right_offset(BeeLevel01Framing.DESIGN_ASPECT)
		top = minf(7.2, BeeLevel01Framing.top_y() - BeeLevel01Framing.FLIGHT_MARGIN)
		bottom = maxf(0.7, BeeLevel01Framing.bottom_y() + BeeLevel01Framing.FLIGHT_MARGIN)
		var boss_yaw: float = S.BOSS_ENTRY_YAW if x >= S.BOSS_ENTRY_FROM_X else 0.0 # El giro extra solo existe donde entra un jefe.
		for extra_yaw in [-(S.BEE_YAW_FROM_X + S.BREATH_YAW), S.BEE_YAW_FROM_X + S.BREATH_YAW + boss_yaw]:
			for roll in [-S.ROLL_MAX, S.ROLL_MAX]:
				# Mejora de claridad: no alcanza con la zona de vuelo de Bee. También tienen que entrar los enemigos del suelo y los de arriba de todo.
				var enemy_top := BeeLevel01Framing.max_entity_y() + S.ENEMY_TOP_EXTRA
				for point in [Vector3(left, maxf(top, enemy_top), 0), Vector3(left, S.ENEMY_FEET_Y, 0), Vector3(right, maxf(top, enemy_top), 0), Vector3(right, S.ENEMY_FEET_Y, 0)]:
					var s := BeeCameraRig.screen_point(point, framing, BeeLevel01Framing.DESIGN_ASPECT, extra_yaw, roll)
					var edge := maxf(absf(s.x), absf(s.y))
					if edge > worst:
						worst = edge
						worst_at = x
		x += STEP
	BeeLevel01Framing.robot_arena_weight = 0.0
	for row: Array in S.KEYFRAMES:
		print("X=%s" % row[0], " esquina=%.3f" % corner_at(float(row[0]), left, right, top, bottom))
	if S.BEE_FOLLOW_Y != 0.0:
		fail("la vista no debe seguir la altura de Bee: se pierden enemigos del otro lado")
		return
	print("peor esquina de la zona de vuelo: %.3f de la pantalla en X=%.0f" % [worst, worst_at])
	if worst > S.VIEW_MARGIN:
		fail("la zona de vuelo se sale de la pantalla: %.3f en X=%.0f" % [worst, worst_at])
		return
	# El borde derecho visible nunca pasa la línea de aparición con la extensión aplicada.
	var extra := maxf(0.0, BeeCameraRig.widest_right(BeeLevel01Framing.DESIGN_ASPECT) - BeeLevel01Framing.half_width_max(BeeLevel01Framing.DESIGN_ASPECT))
	BeeLevel01Framing.render_right_extra = extra
	var spawn := BeeLevel01Framing.spawn_offset_x(BeeLevel01Framing.DESIGN_ASPECT)
	BeeLevel01Framing.render_right_extra = 0.0
	if spawn <= BeeCameraRig.widest_right(BeeLevel01Framing.DESIGN_ASPECT):
		fail("las apariciones nacen a la vista")
		return
	# La tabla empieza en 0 y crece.
	var last := -1.0
	for row: Array in S.KEYFRAMES:
		if float(row[0]) <= last or row.size() != 6:
			fail("tabla de cámara mal armada en X=%s" % row[0])
			return
		last = float(row[0])
	print("PASS validate_bee_camera_rig")
	quit(0)
