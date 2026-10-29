extends "res://tests/levels/bee_t7b_fixture.gd"
## Tanda E1 contract: ONE press of Q / LT-L2 spends one cartridge, heals +25 and raises the 2.5 s golden shield. No tap / hold split.
const S := preload("res://scripts/game/bee_pollen_nova_settings.gd")
func run() -> void:
	var stage := await fixture()
	var juice := stage.get_node("Juice") as BeeLevel01Juice
	var bee := stage.bee
	bee.health.damage_blocked = false
	bee.health.take_damage(50)
	var hp := bee.health.current_health
	juice.add_pollen(6)
	check(juice.pollen_cartridges() == 0 and not juice.try_pollen_nova(), "Partial cartridge cannot be spent")
	juice.add_pollen(15)
	check(juice.pollen_progress() == 21 and juice.pollen_cartridges() == 3 and bee.health.current_health == hp, "Three cartridges, no automatic healing")
	Input.action_press(S.ACTION)
	juice._update_pollen_input(0.016)
	Input.action_release(S.ACTION)
	juice._update_pollen_input(0.016)
	check(juice.novas_used == 1 and juice.pollen_progress() == 14, "One press spends exactly one cartridge")
	check(bee.health.current_health == hp + S.HEAL_AMOUNT and juice.pollen_heals == 1, "The same press heals +25")
	check(bee.get_node_or_null("PollenShield") != null and bee.get_node_or_null("PollenHealGlow") != null and bee.health.pollen_protected, "Golden bubble + glow + invulnerability")
	check(is_equal_approx(S.SHIELD_SECONDS, 2.5) and S.COOLDOWN_SECONDS <= 0.25, "2.5 s shield and short chaining debounce")
	check(not juice.try_pollen_nova(), "Cooldown blocks a second press")
	juice._physics_process(2.4)
	check(bee.health.pollen_protected and bee.health.take_damage(5) == 0, "Still invulnerable at 2.4 s")
	juice._physics_process(0.2)
	check(not bee.health.pollen_protected, "Shield protection ends at 2.5 s")
	# Enemy projectiles touching the bubble are destroyed.
	var shot := (load("res://scenes/bee_prototype/alien_enemy_projectile.tscn") as PackedScene).instantiate()
	stage.add_child(shot)
	shot.global_position = bee.global_position + Vector3(0.5, 0, 0)
	shot.set_physics_process(false)
	await frames(3)
	check(not is_instance_valid(shot) or shot.is_queued_for_deletion(), "A projectile touching the bubble is destroyed")
	juice._physics_process(1.0)
	# At full health a press still raises the shield.
	bee.health.restore_health(1000)
	var full := bee.health.current_health
	juice._pollen_window.clear()
	check(juice.try_pollen_nova() and bee.health.current_health == full and bee.health.pollen_protected and juice.pollen_progress() == 7, "Full health: still spends 1 cartridge for the shield")
	juice._physics_process(3.1)
	check(juice.try_pollen_nova() and juice.pollen_progress() == 0, "Final cartridge fires independently")
	juice._physics_process(3.1)
	juice._pollen_window.clear()
	juice.add_pollen(50)
	check(juice.pollen_progress() == 21, "Inventory saturates at three cartridges")
	var notices := stage.get_node("HUDNotices")
	var count := 1 if notices.active_kind == "pollen_ready" else 0
	for item in notices.pending:
		if item.kind == "pollen_ready": count += 1
	check(count == 1, "First-ready banner is announced only once per run")
	check(S.READY_TEXT.contains("disparo doble") and S.HINT_LABEL == "CURA + ESCUDO + DOBLE", "Pollen text lists all powers")
	print("TANDA_A_POLLEN failures=", failures)
	done()
