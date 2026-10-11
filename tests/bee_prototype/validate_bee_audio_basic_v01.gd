extends SceneTree

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
var stage: BeeShmupStage
var bee: BeePlayer
var counts: Dictionary = {}
var failed := false

func _initialize() -> void:
	BeeLevel01Controller.giant_human_enabled = true # NOCHE 01: the human is off in the game (GIANT_HUMAN_ENABLED); this test covers it.
	node_added.connect(record_voice)
	call_deferred("run")

func record_voice(node: Node) -> void:
	if node.has_meta("cue"):
		var cue: StringName = node.get_meta("cue")
		counts[cue] = int(counts.get(cue, 0)) + 1

func count(cue: StringName) -> int:
	return int(counts.get(cue, 0))

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
		quit(1)
		assert(ok, message)

func frames(n: int) -> void:
	for i in n:
		await physics_frame
		await process_frame

func clear_shots() -> void:
	for child in stage.get_children():
		if child is BeeEnergyProjectile:
			child.queue_free()
	await create_timer(1.0, true, false, true).timeout
	check(get_nodes_in_group("bee_audio_voice").is_empty(), "Temporary audio accumulated")

func unit(scene: PackedScene, point: Vector3) -> Node3D:
	var enemy := scene.instantiate() as Node3D
	stage.add_child(enemy)
	enemy.global_position = point
	enemy.call("activate", bee)
	enemy.set_physics_process(false)
	return enemy

func impact(scene: PackedScene, cue: StringName) -> void:
	var enemy := unit(scene, bee.global_position + Vector3(2.5, 0, 0))
	await frames(3)
	var before := count(cue)
	var health: HealthComponent = enemy.get_node("HealthComponent")
	var hp := health.current_health
	bee.fire()
	await frames(25)
	check(count(cue) == before + 1 and health.current_health == hp - 10, "Impact audio/damage mismatch " + str(cue))
	enemy.queue_free()
	await clear_shots()

func measure() -> void:
	if DisplayServer.get_name() == "headless":
		return
	await frames(30)
	bee.collect_spread()
	bee.collect_bomb()
	var victims: Array[Node3D] = []
	for i in 3:
		victims.append(unit(BeeLevel01Controller.PROBE, bee.global_position + Vector3(2 + i * 0.3, i * 0.4, 0)))
	var start := Time.get_ticks_usec()
	var last := start
	var worst := 0.0
	var peak := 0
	var slow := 0
	for i in 240:
		if i % 24 == 0:
			bee.fire()
		if i == 45:
			bee.use_bomb()
		if i == 75:
			for enemy in victims:
				enemy.get_node("HealthComponent").take_damage(9999)
		await process_frame
		var now := Time.get_ticks_usec()
		var ms := float(now - last) / 1000.0
		worst = maxf(worst, ms)
		if ms > 33.3:
			slow += 1
		last = now
		peak = maxi(peak, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	print("BEE_AUDIO_PERFORMANCE frames=240 fps=", 240000000.0 / float(last - start), " worst_ms=", worst, " slow_frames=", slow, " peak_nodes=", peak)
	for enemy in victims:
		enemy.queue_free()
	await clear_shots()
	bee.spread_ammo = 0

func run() -> void:
	create_timer(100.0, true, false, true).timeout.connect(func(): quit(1))
	check(AudioServer.get_bus_index("Master") == 0 and AudioServer.get_bus_index("SFX") > 0 and AudioServer.get_bus_index("Music") > 0, "Missing audio buses")
	check(AudioServer.get_bus_effect_count(0) == 1 and AudioServer.get_bus_effect(0, 0) is AudioEffectHardLimiter, "Missing clipping protection")
	for cue in BeeAudio.CUES:
		var stream := BeeAudio.stream_for(cue) as AudioStreamWAV
		check(stream != null and stream.get_length() > 0 and stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "Invalid/non-finite stream " + str(cue))
	stage = LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(4)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	bee = stage.bee
	bee.set_physics_process(false)
	bee.flight_min = Vector2(-20, 0.7)
	bee.flight_max = Vector2(400, 7.2)
	bee.hurtbox.monitorable = false
	bee.global_position = Vector3(24, 3.8, 0)
	stage.camera.set_stage_x(26)
	bee.fire()
	check(count(&"base") == 1 and count(&"spread") == 0, "Base cue missing")
	var voice: Node = get_nodes_in_group("bee_audio_voice")[0]
	check(voice is AudioStreamPlayer and voice.bus == &"SFX", "Weapon player not on SFX")
	if DisplayServer.get_name() != "headless":
		check(voice.playing, "Weapon player not playing")
	await clear_shots()
	await impact(BeeLevel01Controller.PROBE, &"tech_hit")
	await impact(BeeLevel01Controller.WASP, &"organic_hit")
	bee.collect_spread()
	bee.fire()
	check(count(&"spread") == 1 and bee.spread_ammo == 31, "Spread did not play exactly once per burst")
	await clear_shots()
	bee.spread_ammo = 0
	bee.set_physics_process(true)
	check(bee.start_melee(), "Empty melee refused")
	await frames(40)
	check(count(&"melee") == 0, "Missed melee played hit cue")
	bee.set_physics_process(false)
	var wasp := unit(BeeLevel01Controller.WASP, bee.global_position + Vector3(0.8, 0, 0))
	await frames(3)
	check(bee.start_melee(), "Melee refused")
	await frames(3)
	check(count(&"melee") == 1 and wasp.get_node("HealthComponent").current_health == 15, "Melee hit cue/damage wrong")
	wasp.queue_free()
	bee.melee_hitbox.set_enabled(false)
	await clear_shots()
	var flying_bomb := bee.use_bomb()
	check(flying_bomb != null and count(&"bomb") == 0, "Bomb must not play explosion audio on launch")
	flying_bomb.detonate()
	await frames(16)
	check(count(&"bomb") == 1, "Bomb explosion cue missing after its warning")
	await clear_shots()
	for pair in [[BeeLevel01Controller.PROBE, &"tech_death"], [BeeLevel01Controller.WASP, &"organic_death"], [BeeLevel01Controller.WALKER, &"tech_death"]]:
		var enemy := unit(pair[0], bee.global_position + Vector3(2, 0, 0))
		await frames(3)
		var before := count(pair[1])
		enemy.get_node("HealthComponent").take_damage(9999)
		enemy.get_node("HealthComponent").take_damage(9999)
		check(count(pair[1]) == before + 1, "Death cue missing/duplicated")
		var spatial: AudioStreamPlayer3D = get_nodes_in_group("bee_audio_voice").back()
		check(spatial.stream != null and spatial.max_distance > 0 and spatial.bus == &"SFX", "Invalid world audio")
		if pair[0] == BeeLevel01Controller.WALKER:
			check(spatial.pitch_scale < 1.0, "Walker heavier variation missing")
		enemy.queue_free()
		await clear_shots()
	var crate: DestructibleObstacle3D = stage.get_node("Destructibles/GardenCrate")
	crate.health.take_damage(9999)
	check(count(&"crate") == 1, "Crate cue missing")
	await frames(3)
	check(crate.collider.disabled, "Audio changed crate destruction")
	await clear_shots()
	var spread: BeePowerupPickup = stage.get_node("Powerups/SpreadFirst")
	check(spread.collect(bee) and not spread.collect(bee) and count(&"spread_pickup") == 1, "Spread pickup cue duplicated")
	var bomb: BeePowerupPickup = stage.get_node("Powerups/BombFirst")
	check(bomb.collect(bee) and not bomb.collect(bee) and count(&"bomb_pickup") == 1, "Bomb pickup cue duplicated")
	var pollen: BeePollenPickup = stage.get_node("Pollen/PollenA")
	check(pollen.collect(bee) and not pollen.collect(bee) and count(&"pollen") == 1, "Pollen cue duplicated")
	await clear_shots()
	var human: GiantHumanCrossingHazard = stage.get_node("GiantHuman")
	check(human.begin_crossing(stage.camera) and count(&"human_warning") == 1, "Human warning cue missing")
	await frames(70)
	var human_audio := human.get_node("HumanAudio")
	check(human.current_phase == GiantHumanCrossingHazard.Phase.CROSSING and human_audio.steps_played == 1, "Human crossing cue missing")
	await create_timer(3.1, true, false, true).timeout
	# Footsteps are synced to the Run clip: one per foot contact (every 0.4 s of clip, 0.72x playback).
	check(human_audio.steps_played >= 5 and human_audio.steps_played <= 8, "Human steps not synced to the Run clip (%d in 3.1 s)" % human_audio.steps_played)
	human.freeze()
	await clear_shots()
	await measure()
	for i in BeeAudio.MAX_VOICES:
		BeeAudio.play(stage, &"base")
	check(BeeAudio.play(stage, &"base") == null, "Voice cap not respected")
	check(BeeAudio.play(stage, &"bomb") != null, "Critical cue did not replace low-priority voice")
	var active := 0
	for node in get_nodes_in_group("bee_audio_voice"):
		if not node.is_queued_for_deletion():
			active += 1
	check(active == BeeAudio.MAX_VOICES, "Voice replacement exceeded cap")
	await clear_shots()
	bee.health.take_damage(5)
	check(count(&"bee_damage") == 1, "Bee damage cue missing")
	bee.health.take_damage(9999)
	bee.health.take_damage(9999)
	check(bee.is_defeated and count(&"bee_defeat") == 1 and count(&"bee_damage") == 1, "Defeat cue duplicated")
	check(bee.fire() == null and not bee.start_melee() and bee.use_bomb() == null, "Defeat controls regression")
	var old_id := stage.get_instance_id()
	stage.set_physics_process(true)
	# Resume at the frame signal, before the stage's _process input polling.
	await frames(2)
	Input.action_press("restart")
	await frames(4)
	Input.action_release("restart")
	check(current_scene != null and current_scene.get_instance_id() != old_id, "R did not reload level")
	check(get_nodes_in_group("bee_audio_voice").is_empty(), "Reload kept old voices")
	var restored := current_scene as BeeShmupStage
	check(not restored.bee.is_defeated and restored.bee.health.current_health == restored.bee.health.max_health, "Restart health regression")
	if not failed:
		print("BEE_AUDIO_BASIC_V01_OK streams=16 buses events impacts melee bomb deaths pickups human voice_cap cleanup real_restart gameplay=unchanged renderer=", DisplayServer.get_name())
	quit(1 if failed else 0)
