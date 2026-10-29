extends "res://tests/levels/bee_t7b_fixture.gd"
const GUIDE := preload("res://scripts/game/bee_controls_guide.gd")

func run() -> void:
	GUIDE.seen_override = false
	BeeGameSettings.level_intro_pending = true
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	var wave := stage.wave
	var bee := stage.bee
	var juice := stage.get_node("Juice") as BeeLevel01Juice
	var card := stage.get_node("HowToCard")
	check(wave.intro_active() and card.training and wave.active_units.is_empty(), "Training gates the first enemy")
	bee.velocity = Vector3(2, 0, 0)
	card._process(0.016)
	check(card.step_index == 1, "Movement advances to shooting")
	bee.fire_trigger_count += 1
	card._process(0.016)
	check(card.step_index == 2, "Shooting advances to roll")
	bee.roll_count += 1
	card._process(0.016)
	check(card.step_index == 3, "Roll advances to melee")
	bee.melee_count += 1
	card._process(0.016)
	check(card.step_index == 4 and bee.bomb_charges > 0, "Melee advances to bomb with a training charge")
	bee.bomb_charges -= 1
	card._process(0.016)
	check(card.step_index == 5 and juice.pollen_progress() >= 7, "Bomb advances to pollen with a training cartridge")
	check(juice.try_pollen_nova(), "Training pollen cartridge can activate its powers")
	card._process(0.016)
	await frames(3)
	check(not wave.intro_active() and GUIDE.seen() and stage.get_node_or_null("HowToCard") == null, "Training completes and is remembered")
	stage.queue_free()
	await frames(2)
	BeeGameSettings.level_intro_pending = true
	stage = preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	check(stage.wave.intro_active() and stage.get_node_or_null("HowToCard") == null, "Training appears only on first play")
	stage.scroll_speed = 0.0
	paused = true
	stage.get_node("CheckpointQoL")._open_training()
	await frames(2)
	check(not paused and stage.get_node_or_null("HowToCard") != null, "Pause Controls reopens training")
	var skip := InputEventKey.new()
	skip.keycode = KEY_ENTER
	skip.pressed = true
	stage.get_node("HowToCard")._input(skip)
	await frames(3)
	check(not stage.wave.intro_active() and stage.scroll_speed == 0.0, "Repeating training restores prior scroll state")
	GUIDE.seen_override = null
	print("TANDA_K_TRAINING failures=", failures)
	done()
