extends SceneTree
const S := preload("res://scripts/game/bee_punch_settings.gd")
const T4B := preload("res://scripts/game/bee_sting_settings.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 5: await physics_frame
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.get_node("Juice").set_physics_process(false)
	var bee := stage.bee
	bee.set_physics_process(false)
	var visual := bee.get_node("VisualRoot/BeeVisual")
	visual.set_process(false)
	var model: Node3D = visual.model
	var pose = visual.punch_pose
	check(pose.parts.size() == 8, "v02 has two imported front legs, joints and feet; no procedural proxy")
	check(not model.find_child("Stinger", true, false).visible and bee.stinger == null and not bee.has_node("ChromeStinger"), "Imported and chrome stingers are absent from presentation")
	check(is_equal_approx(bee.melee_reach(), 2.08) and bee.melee_damage == 30 and bee.melee_cooldown == 0.0, "Reach, damage and cooldown retained")
	check(is_equal_approx(T4B.DASH_SECONDS, 0.22) and is_equal_approx(T4B.IMPACT_SECONDS, 0.06) and is_equal_approx(T4B.RECOIL_SECONDS, 0.10) and is_equal_approx(T4B.EMPTY_DISTANCE, 1.0), "T4b timing and empty distance unchanged")
	var shape := bee.melee_hitbox.get_node("CollisionShape3D").shape as BoxShape3D
	check(shape.size == Vector3(0.75, 0.5, 0.5), "Existing hitbox dimensions retained")
	var other_leg: Node3D = model.find_child("Leg_L_1_Upper", true, false)
	var other_rest := other_leg.transform
	var front: Node3D = model.find_child("Foot_L_0", true, false)
	var front_rest := front.transform
	var actor_rest := bee.global_transform
	check(bee.start_melee(), "Punch starts through the same action")
	var hitbox_rest := bee.melee_hitbox.transform
	var dash = bee.sting_dash
	var cases := [[0.12, 0.0], [0.06, S.DRAW_BACK_ANGLE], [0.03, (S.DRAW_BACK_ANGLE + S.CONTACT_ANGLE) * 0.5]]
	for sample in cases:
		dash.left = sample[0]
		pose.update(dash)
		check(is_equal_approx(pose.angle, sample[1]), "Preparation/strike interpolates in the last 0.12 s of OUT")
	dash.phase = dash.Phase.IMPACT
	dash.left = T4B.IMPACT_SECONDS
	pose.update(dash)
	check(is_equal_approx(pose.angle, S.CONTACT_ANGLE) and pose.extension == 1.0, "Maximum extension aligns with T4b contact")
	check(front.position.z < front_rest.origin.z - 0.20, "Imported feet extend forward to form fists")
	check(other_leg.transform.is_equal_approx(other_rest), "Middle/back legs stay unchanged")
	check(bee.global_transform.is_equal_approx(actor_rest) and bee.melee_hitbox.transform.is_equal_approx(hitbox_rest) and not bee.melee_hitbox.enabled, "Pose update cannot move Bee, move/enable hitbox or apply damage")
	var frozen := front.transform
	var wasp := preload("res://scenes/bee_prototype/wasp_enemy.tscn").instantiate() as WaspEnemy
	stage.add_child(wasp)
	wasp.activate(bee)
	wasp.set_physics_process(false)
	var hp := wasp.health.current_health
	bee._on_melee_impact(wasp.get_node("Hurtbox3D"), 30)
	var stop := stage.get_node("LocalHitStop")
	check(stop.remaining > 0 and Engine.time_scale == 1.0, "Actual impact keeps T4f local hit-stop")
	pose.update(dash)
	check(front.transform.is_equal_approx(frozen), "Pose remains frozen when physical phase is frozen")
	check(wasp.health.current_health == hp, "Visual impact callback never applies extra damage")
	check(stage.find_child("BeeDrillMetalTrail", true, false) == null, "No metal drill trail")
	var star := stage.get_node("PunchContactStar")
	star.set_process(false)
	check(star.global_position.is_equal_approx(bee.melee_hitbox.global_position) and star.get_child_count() == 2, "White/gold star at contact, two small layers")
	star._process(0.099)
	check(not star.is_queued_for_deletion(), "Star lasts through 0.099 s")
	star._process(0.002)
	check(star.is_queued_for_deletion(), "Star ends at 0.1 s")
	stop.restore()
	dash.phase = dash.Phase.RECOIL
	dash.left = S.RECOVER_SECONDS * 0.5
	pose.update(dash)
	check(is_equal_approx(pose.angle, S.CONTACT_ANGLE * 0.5), "Recovery folds over the existing 0.10 s recoil")
	dash.finish()
	check(front.transform.is_equal_approx(front_rest) and pose.angle == 0, "Finish restores exact transforms immediately, including defeat")
	check((model.find_child("AnimationPlayer", true, false) as AnimationPlayer).current_animation == "wingbeat", "No drill animation replaces wingbeat")
	visual.apply_model_version("v01")
	check(visual.punch_pose.parts.size() == 4 and not visual.model.find_child("Stinger", true, false).visible, "v01 animates its own four front leg segments, hides old stinger")
	visual.apply_model_version("v02")
	var hud := stage.get_node("CanvasLayer/WeaponsHUD")
	BeeGameSettings.last_input_joypad = false
	check(hud.control_text().contains("PUÑETAZO Z") and not hud.control_text().contains("AGUIJÓN"), "Keyboard control renamed")
	BeeGameSettings.last_input_joypad = true
	check(hud.control_text().contains("PUÑETAZO Y / RB"), "Controller control renamed")
	print("T4G_PUNCH failures=", failures)
	quit(1 if failures else 0)
