extends SceneTree
const S := preload("res://scripts/game/bee_pollen_nova_settings.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func frames(count: int) -> void:
	for i in count: await physics_frame

func target_at(stage: Node3D, point: Vector3, team: StringName = &"alien") -> Node3D:
	var target := Node3D.new()
	var hp := HealthComponent.new()
	hp.name = "HealthComponent"
	hp.max_health = 30
	target.add_child(hp)
	for i in 2: # Shared body/implant HP: damage must not be doubled.
		var hurt := DamageHurtbox3D.new()
		hurt.team_id = team
		hurt.collision_layer = 2
		hurt.collision_mask = 0
		hurt.damage_multiplier = 2.0 if i == 1 else 1.0
		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 0.1
		shape.shape = sphere
		hurt.add_child(shape)
		target.add_child(hurt)
	stage.add_child(target)
	target.add_to_group("bee_auto_aim_targets")
	target.global_position = point
	return target

func bullet_at(stage: Node3D, point: Vector3, boss: bool = false) -> Node3D:
	var shot := (load("res://scenes/bee_prototype/alien_enemy_projectile.tscn") as PackedScene).instantiate()
	stage.add_child(shot)
	shot.global_position = point
	shot.set_physics_process(false)
	if boss: shot.add_to_group("ufo_boss_projectiles")
	return shot

func run() -> void:
	BeeJuice.hit_stop_enabled = false
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(4)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	var juice := stage.get_node("Juice") as BeeLevel01Juice
	juice.set_physics_process(false)
	var bee := stage.bee
	bee.set_physics_process(false)
	bee.global_position = Vector3(25, 4, 0)
	bee.health.damage_blocked = false
	bee.health.take_damage(25)
	var before_hp := bee.health.current_health
	check(not juice.try_pollen_nova(), "Empty charge cannot activate")
	juice.add_pollen(6)
	check(not juice.try_pollen_nova(), "6/7 cannot activate")
	juice.add_pollen(1)
	check(juice.pollen_progress() == 7 and bee.health.current_health == before_hp and juice.banked_heals == 0, "7 grains stay charged; no automatic or banked healing")
	check(juice.pollen_label.text.contains("CURAR + ESCUDO"), "E1: charge hint reads CURAR + ESCUDO")
	get_tree_paused_check(juice)
	var near := target_at(stage, bee.global_position + Vector3(2, 0, 0))
	var far := target_at(stage, bee.global_position + Vector3(S.RADIUS + 1.0, 0, 0))
	var behind := target_at(stage, bee.global_position + Vector3(0, 0, S.RADIUS + 1.0))
	var friend := target_at(stage, bee.global_position + Vector3(0, 1, 0), &"bee")
	var blocked := target_at(stage, bee.global_position + Vector3(-2, 0, 0))
	blocked.get_node("HealthComponent").damage_blocked = true
	var bullet := bullet_at(stage, bee.global_position + Vector3(1, 0, 0))
	var boss_bullet := bullet_at(stage, bee.global_position + Vector3(0, 2, 0), true)
	var far_bullet := bullet_at(stage, bee.global_position + Vector3(6, 0, 0))
	var player_shot := bee.fire()
	player_shot.set_physics_process(false)
	await frames(3)
	check(juice.try_pollen_nova() and juice.pollen_progress() == 0 and juice.novas_used == 1, "Nova consumes one cartridge exactly once")
	check(bee.health.current_health == before_hp + 25 and juice.pollen_heals == 1 and bee.get_node_or_null("PollenShield") != null, "E1: the same press heals +25 and raises the golden shield")
	check(bee.health.pollen_protected and bee.health.take_damage(5) == 0, "Pollen power grants protection immediately")
	juice.add_pollen(7)
	check(not juice.try_pollen_nova(), "Refilling cannot bypass the three-second cooldown")
	juice._physics_process(2.4)
	check(bee.health.take_damage(5) == 0, "Still protected before 2.5 s")
	bee.health.invulnerable = true # Existing roll/sting protection is independently owned.
	juice._physics_process(0.12)
	check(not bee.health.pollen_protected and bee.health.invulnerable, "Shield ends at 2.5 s without cancelling other protection")
	bee.health.invulnerable = false
	check(bee.health.take_damage(5) == 5, "Damage resumes after Nova")
	await frames(30)
	check(near.get_node("HealthComponent").current_health == 30 - S.COMMON_DAMAGE, "Expanding sphere damages shared body/implant HP once, without weakpoint multiplier")
	check(far.get_node("HealthComponent").current_health == 30 and behind.get_node("HealthComponent").current_health == 30, "Outside radius in X or Z is untouched")
	check(friend.get_node("HealthComponent").current_health == 30 and blocked.get_node("HealthComponent").current_health == 30, "Friendly and protected targets are untouched")
	check(not is_instance_valid(bullet) and not is_instance_valid(boss_bullet) and is_instance_valid(far_bullet), "Clears common and boss bullets only inside area")
	check(is_instance_valid(player_shot), "Bee projectiles survive Nova")
	juice._physics_process(0.9)
	check(juice.try_pollen_nova(), "New charge can activate after cooldown")
	await frames(30)
	# Actual boss: each health receives 6 base damage, respecting existing hull limits.
	var boss := preload("res://scenes/levels/tarantula_boss_01.tscn").instantiate() as TarantulaBoss01
	stage.add_child(boss)
	boss.begin(stage.camera, bee)
	boss.set_physics_process(false)
	boss.global_position = bee.global_position + Vector3(2, 0, 0)
	boss.health.damage_blocked = false
	boss.state = TarantulaBoss01.State.PHASE_1
	boss._hull_tokens = 100.0
	boss.add_to_group("bee_auto_aim_targets")
	var nova := preload("res://scripts/bee_prototype/bee_pollen_nova.gd").new()
	stage.add_child(nova)
	nova.attacker = bee
	nova.set_physics_process(false)
	check(nova._is_boss(boss), "Actual boss classified separately")
	nova.damage = S.BOSS_DAMAGE
	var boss_hp := boss.health.current_health
	var applied := boss.implant_hurtbox.receive_hit(nova)
	check(applied == 6 and boss.health.current_health == boss_hp - 6, "Boss receives 6 without implant bonus")
	check(boss.implant_hurtbox.receive_hit(nova) == 0, "Boss health cannot be hit twice by the same Nova")
	nova.queue_free()
	stage.sector_complete = true
	juice.pollen_spent = 0
	juice.nova_cooldown_left = 0
	check(not juice.try_pollen_nova(), "Victory blocks Nova")
	stage.sector_complete = false
	bee.is_defeated = true
	check(not juice.try_pollen_nova(), "Defeat blocks Nova")
	bee.is_defeated = false
	var events := InputMap.action_get_events(S.ACTION)
	check(events.any(func(e): return e is InputEventKey and e.physical_keycode == KEY_Q), "Q is bound")
	check(events.any(func(e): return e is InputEventJoypadMotion and e.axis == JOY_AXIS_TRIGGER_LEFT and e.device == -1), "LT/L2 is bound for all devices")
	BeeGameSettings.last_input_joypad = true
	check(S.button_hint() == "LT/L2", "Controller hint")
	BeeGameSettings.last_input_joypad = false
	check(S.button_hint() == "Q", "Keyboard hint")
	juice.nova_cooldown_left = 0
	juice._pollen_window.clear()
	juice.add_pollen(7)
	var uses := juice.novas_used
	juice.set_physics_process(true)
	Input.action_press(S.ACTION)
	await frames(3)
	Input.action_release(S.ACTION)
	await frames(2)
	juice.set_physics_process(false)
	check(juice.novas_used == uses + 1, "Action activates through the gameplay physics loop")
	Input.action_release(S.ACTION)
	print("T3M_NOVA failures=", failures)
	quit(1 if failures else 0)

func get_tree_paused_check(juice: BeeLevel01Juice) -> void:
	paused = true
	check(not juice.try_pollen_nova(), "Pause blocks Nova without consuming charge")
	paused = false
