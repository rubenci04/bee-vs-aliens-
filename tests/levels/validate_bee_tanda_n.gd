extends "res://tests/levels/bee_t7b_fixture.gd"

const POLLEN := preload("res://scripts/game/bee_pollen_nova_settings.gd")

func run() -> void:
	var stage := await fixture()
	var wave := stage.wave as BeeLevel01Controller
	var juice := stage.get_node("Juice") as BeeLevel01Juice
	var bee := stage.bee
	check(BeeLevel01Juice.FRENZY_COMBO == 15 and BeeLevel01Juice.FRENZY_COOLDOWN_SECONDS == 12.0, "A: umbral y espera configurables")
	for i in BeeLevel01Juice.FRENZY_COMBO:
		juice._advance_combo()
	check(juice.frenzy_activations == 1 and bee.honey_left > 0.0 and juice.frenzy_label.visible, "A: Frenesí arranca y aparece en HUD")
	var first_duration := bee.honey_left
	for i in BeeLevel01Juice.FRENZY_COMBO:
		juice._advance_combo()
	check(juice.frenzy_activations == 1 and bee.honey_left == first_duration, "A: no se renueva mientras está activo")
	bee.honey_left = 0.0
	juice._physics_process(0.01)
	check(juice.frenzy_cooldown_left == BeeLevel01Juice.FRENZY_COOLDOWN_SECONDS, "A: espera comienza al terminar")
	for i in BeeLevel01Juice.FRENZY_COMBO:
		juice._advance_combo()
	check(juice.frenzy_activations == 1, "A: el combo no evita la espera")
	wave._combo_zone_clear_at = wave._clock
	juice._physics_process(BeeLevel01Juice.FRENZY_COOLDOWN_SECONDS)
	for i in BeeLevel01Juice.FRENZY_COMBO:
		juice._advance_combo()
	check(juice.frenzy_activations == 2, "A: puede volver a arrancar después de la espera")
	bee.honey_left = 0.0
	juice.combo = 10
	juice.combo_left = BeeLevel01Juice.COMBO_RESET_SECONDS
	wave._combo_zone_clear_at = wave._clock
	juice._physics_process(BeeLevel01Juice.COMBO_RESET_SECONDS + 1.0)
	check(juice.combo == 10, "B: el combo no vence durante la pausa postzona")
	wave._post_zone_clear_at = -INF
	check(wave.combo_intermission(), "B: lanzar el evento no termina la pausa antes de ver un enemigo")
	var visible := Node3D.new()
	stage.add_child(visible)
	visible.global_position = Vector3(stage.camera.global_position.x, 4.0, 0.0)
	visible.set_physics_process(true)
	wave.active_units.append(visible)
	check(not wave.combo_intermission(), "B: la pausa termina cuando aparece un enemigo")
	wave.active_units.erase(visible)
	visible.queue_free()
	wave._combo_zone_clear_at = wave._clock - BeeLevel01Controller.COMBO_POST_ZONE_GRACE_SECONDS
	check(not wave.combo_intermission(), "B: la pausa también termina a los ocho segundos")
	var protected_zones := 0
	for event in wave.events_table():
		if float(event.get("at", -1.0)) in [138.0, 214.0, 262.0]:
			if float(event.get("zone_min_seconds", 0.0)) == BeeLevel01Controller.ZONE_MIN_SECONDS and event.has("extension_wave"):
				protected_zones += 1
	check(protected_zones == 3, "D: nube, escarabajos y arañas tienen mínimo y refuerzo")
	wave._begin_arena({"arena": [], "units": ["FlyCloud"], "zone_min_seconds": BeeLevel01Controller.ZONE_MIN_SECONDS}, 0)
	wave._update_arena(0.0)
	check(wave.in_arena(), "D: la zona vacía no termina antes del mínimo")
	wave._clock += BeeLevel01Controller.ZONE_MIN_SECONDS
	wave._update_arena(0.0)
	check(not wave.in_arena() and wave.arena_log.back()["seconds"] >= BeeLevel01Controller.ZONE_MIN_SECONDS, "D: la zona termina al cumplir el mínimo")
	check(BeeLevel01Controller.DEAD_AIR_SECONDS == 4.0 and BeeLevel01Controller.DEBUT_CLEAR_MAX == 5.0, "C: rescate a cuatro segundos sin alterar debut")
	var next_index := -1
	for i in wave.events_table().size():
		if float(wave.events_table()[i]["at"]) == 138.0:
			next_index = i + 1
			break
	check(next_index >= 0, "C: existe el evento posterior a la nube")
	if next_index >= 0:
		wave.event_index = next_index
		stage.distance = 138.0
		wave._clock = 100.0
		wave._breather_until = 0.0
		wave._post_zone_clear_at = wave._clock - BeeLevel01Controller.POST_ZONE_FIRST_EVENT_MAX_SECONDS
		wave._physics_process(0.0)
		check(wave.event_index == next_index + 1, "C: el siguiente evento sale como máximo a los tres segundos")
	check(POLLEN.POLLEN_USE_COOLDOWN_SECONDS == 1.5, "E: espera del cartucho configurable")
	juice.combo = 0
	juice.add_pollen(POLLEN.CHARGE)
	check(juice.try_pollen_nova(), "E: primer cartucho disponible")
	juice._physics_process(POLLEN.POLLEN_USE_COOLDOWN_SECONDS - 0.01)
	check(not juice.try_pollen_nova(), "E: segundo cartucho bloqueado antes de 1,5 s")
	juice._physics_process(0.02)
	check(juice.try_pollen_nova(), "E: segundo cartucho disponible después de 1,5 s")
	print("TANDA_N failures=", failures)
	done()
