extends SceneTree
const S := preload("res://scripts/game/bee_sting_settings.gd")
const TRACE := preload("res://scripts/game/bee_damage_trace.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		push_error(text)
func frames(n: int) -> void:
	for i in n: await physics_frame
func run() -> void:
	BeeJuice.hit_stop_enabled=false # T4f microfreeze is tested separately; this fixture counts exact dash/roll ticks.
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(4)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.distance = 25
	stage._update_camera_and_bounds()
	var bee := stage.bee
	bee.global_position = Vector3(23,4,0)
	stage.wave._spawn({"family":"Wasp","slot":0,"event":0,"hard":false})
	var wasp := stage.wave.active_units.back() as WaspEnemy
	wasp.global_position = Vector3(24.8,4.5,0)
	wasp.set_physics_process(false)
	wasp.health.max_health = 200
	wasp.health.current_health = 200
	await frames(2)
	var start := bee.global_position
	check(bee.start_melee() and bee.health.invulnerable and not bee.melee_hitbox.enabled, "Dash starts invulnerable without instant damage")
	check(bee.health.take_damage(20) == 0, "No damage during dash")
	await frames(4)
	check(bee.global_position.distance_to(start) > .2 and wasp.health.current_health == 200, "Bee travels before damage")
	check(not bee.start_roll() and bee.sting_dash.queued_roll, "Roll waits for sting")
	await frames(22)
	check(wasp.health.current_health < 200 and bee.is_rolling and not bee.sting_dash.active, "Impact damages; queued roll starts afterwards")
	check(not bee.start_melee() and bee.sting_dash.queued_sting, "Sting waits for roll")
	await frames(26)
	check(bee.melee_count == 2, "Queued sting ran once")
	await frames(30)
	wasp.remove_from_group("bee_auto_aim_targets")
	bee.clear_aim()
	bee.set_aim_point(bee.global_position+Vector3.UP*4)
	start = bee.global_position
	check(bee.start_melee() and bee.melee_target == null, "Empty dash works")
	await frames(16)
	check(bee.global_position.y > start.y+.7 and not bee.melee_hitbox.enabled, "Empty dash follows aim and never damages")
	await frames(18)
	check(bee.melee_ready_ratio() == 1 and bee.start_melee(), "Available immediately after animation, no charge")
	await frames(28)
	bee.health.invulnerable = false
	TRACE.records.clear()
	var hit := DamageHitbox3D.new()
	hit.damage = 5
	hit.attacker_path = NodePath("..")
	hit.team_id = &"alien"
	stage.add_child(hit)
	hit.attacker = wasp
	hit.set_enabled(true)
	check(bee.hurtbox.receive_hit(hit) == 5, "Damage remains unchanged")
	check(bee.get_node("HitFlash3D").is_flashing() and is_equal_approx(bee.get_node("HitFlash3D").duration,.12), "Brief low-opacity damage flash")
	var dev := preload("res://scripts/game/bee_readability_settings.gd").development_enabled()
	check(TRACE.records.size() == (1 if dev else 0), "Damage trace gated to development")
	check(not preload("res://scripts/game/bee_readability_settings.gd").development_for(false,true,true), "Even a debug standalone export cannot log")
	stage.wave._spawn({"family":"Ant","slot":0,"event":0,"hard":false,"anthill":true,"y":4})
	var ant := stage.wave.active_units.back() as AssetFauna
	var initial_y := ant.global_position.y
	check(ant.get_meta("anthill_entry",false) and not ant.is_active(), "Ant emerges visibly but is not active above ground")
	var last_y := initial_y
	for i in 72:
		await physics_frame
		check(ant.global_position.y <= last_y+.02, "Ant descends from mouth, never hops upward")
		last_y = ant.global_position.y
	check(is_equal_approx(ant.global_position.y,BeeLevel01Anthills.GROUND_Y) and ant.is_active(), "Ant finishes anchored to soil despite authored y=4")
	print("T4B_OK failures=",failures," reach=",bee.melee_reach())
	quit(1 if failures else 0)
