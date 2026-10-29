extends SceneTree

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const ROBOT := preload("res://scenes/levels/walker_miniboss.tscn")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func wait(seconds: float) -> void:
	await create_timer(seconds, true, false, false).timeout

func run() -> void:
	create_timer(90.0, true, false, true).timeout.connect(func(): quit(1))
	var manager := root.get_node("MusicManager")
	await process_frame
	manager.stop_all()
	BeeMusic.play_level_from_start()
	check(BeeGameSettings.LEVEL_MUSIC_FADE_IN_SECONDS <= 1.5, "El fade de nivel es corto")
	await wait(1.5)
	check(manager._fade_gain[manager._active] > 0.99, "La música llega al 100 % antes de 1,5 s")
	manager.prepare_boss_break()
	await wait(0.12)
	check(manager.current_track == &"" and not manager.is_playing(), "El corte del jefe conserva el silencio")
	check(manager._explosion_db == BeeGameSettings.BOSS_PRE_BREAK_DUCK_DB, "No queda atenuación anterior al corte")
	BeeMusic.tarantula()
	await wait(0.48)
	check(manager.current_track == &"boss_tarantula" and manager._fade_gain[manager._active] > 0.99, "La tarántula entra en 0,4 s")
	manager.stop_all()
	var input_devices := root.get_node("InputDevices")
	BeeGameSettings.last_input_joypad = true
	var key := InputEventKey.new()
	key.pressed = true
	key.physical_keycode = KEY_Q
	input_devices._input(key)
	check(BeeGameSettings.last_input_joypad, "Una tecla no cambia la leyenda del mando")
	input_devices._keyboard_since_msec = Time.get_ticks_msec() - int(BeeGameSettings.HUD_DEVICE_SWITCH_SECONDS * 1000.0)
	input_devices._input(key)
	check(not BeeGameSettings.last_input_joypad, "El uso continuo cambia a teclado")
	var joy := InputEventJoypadButton.new()
	joy.pressed = true
	joy.button_index = JOY_BUTTON_A
	input_devices._input(joy)
	check(BeeGameSettings.last_input_joypad, "Un botón del mando cambia inmediatamente")
	var stage := LEVEL.instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	var qol := stage.get_node("CheckpointQoL") as BeeCheckpointQoL
	check(qol.pause_label.text == BeeGameSettings.PAUSE_LABEL_TEXT and qol.pause_label.text.begins_with("PAUSA"), "La pausa está en español")
	check(qol.training_button.get_theme_font_size("font_size") >= 22, "La pausa usa letra legible")
	check(qol.music_slider.custom_minimum_size.x >= 300 and qol.music_slider.custom_minimum_size.y >= 32, "Sliders grandes")
	stage.wave.set_process(false)
	stage.wave.set_physics_process(false)
	qol.set_process(false)
	stage.distance = qol.second_checkpoint_x + 1.0
	qol.checkpoint_active = true
	var robot := ROBOT.instantiate() as WalkerMiniboss
	stage.get_node("Enemies").add_child(robot)
	robot.set_physics_process(false)
	stage.wave.miniboss = robot
	check(qol._checkpoint2_boss_alive(), "Robot vivo bloquea checkpoint 2")
	qol.activate_second_checkpoint()
	check(not qol.second_checkpoint_active, "No se reemplaza la foto del jefe")
	robot.health.current_health = 0
	check(not qol._checkpoint2_boss_alive(), "Tras morir el robot se libera checkpoint 2")
	qol.activate_second_checkpoint()
	check(qol.second_checkpoint_active, "Checkpoint 2 se activa tras la muerte")
	print("BEE_TANDA_P failures=", failures)
	quit(1 if failures else 0)
