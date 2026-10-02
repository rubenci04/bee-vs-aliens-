extends SceneTree

# POLISH-02 audio contract: ambience loop on its own bus with fade-in, wing buzz, footsteps synced to
# the Run clip, and a mix where shots and explosions stay the loudest things.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

## Peak level in dBFS of a cue as heard: file peak + cue gain + bus gain.
func shot_peak_db(cue: StringName) -> float:
	return linear_to_db(0.40) + float(BeeAudio.CUES[cue][1]) + AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))

func run() -> void:
	create_timer(90.0, true, false, true).timeout.connect(func(): quit(1))
	var ambience_bus := AudioServer.get_bus_index("Ambience")
	check(ambience_bus > 0, "Missing Ambience bus")
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(3)
	stage.set_physics_process(false)
	(stage.wave as Node).set_physics_process(false)

	# (a) Ambience: loops, uses the Ambience bus, starts silent and fades in to its target.
	var ambience := stage.get_node("GardenAmbience") as BeeAmbience
	check(ambience != null and ambience.player != null, "Garden ambience missing")
	var ambience_stream := ambience.player.stream as AudioStreamWAV
	check(ambience_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and ambience_stream.get_length() > 15.0, "Ambience must be a loop of at least 15 s")
	check(ambience.player.bus == &"Ambience", "Ambience on the wrong bus")
	check(ambience.player.volume_db < ambience.target_db - 3.0, "Ambience must fade in from silence")
	await ambience.tween.finished
	check(is_equal_approx(ambience.player.volume_db, ambience.target_db), "Ambience did not reach its target volume")
	var ambience_peak := linear_to_db(0.30) + ambience.target_db + AudioServer.get_bus_volume_db(ambience_bus)

	# (c) Wing buzz: soft loop on Bee, silent once she is defeated.
	var visual := stage.bee.get_node("VisualRoot/BeeVisual")
	var buzz: AudioStreamPlayer = visual.buzz_player
	check(buzz != null and (buzz.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "Wing buzz missing or not looping")
	var buzz_peak := linear_to_db(0.50) + buzz.volume_db + AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))

	# (b) Footsteps: one per foot contact of the Run clip (every 0.4 s of clip).
	var human := stage.get_node("GiantHuman") as GiantHumanCrossingHazard
	var human_audio := human.get_node("HumanAudio")
	stage.bee.global_position = Vector3(-50, 3, 0)
	check(human.begin_crossing(stage.camera), "Crossing rejected")
	for i in 400:
		await physics_frame
		if human.current_phase == GiantHumanCrossingHazard.Phase.CROSSING:
			break
	check(human_audio.steps_played == 1, "First contact step missing")
	var clip_time := 0.0
	var last := human.animation_player.current_animation_position
	for i in 300:
		await physics_frame
		var now := human.animation_player.current_animation_position
		clip_time += now - last if now >= last else now - last + human.animation_player.current_animation_length
		last = now
	var expected := 1 + floori(clip_time / 0.4)
	check(absi(human_audio.steps_played - expected) <= 1, "Steps out of sync with the clip: %d played, %d contacts" % [human_audio.steps_played, expected])
	check(human_audio.steps_played >= 5, "Too few footsteps")
	var step_peak := shot_peak_db(&"human_step")
	var steps_total: int = human_audio.steps_played

	# Resources: every new stream exists and loads; footstep variants are wired as cues.
	for path in ["res://audio/ambience/garden_loop.wav", "res://audio/sfx/real/wing_buzz.wav", "res://audio/sfx/real/human_step.wav", "res://audio/sfx/real/human_step_b.wav", "res://audio/sfx/real/human_step_c.wav"]:
		check(ResourceLoader.exists(path) and load(path) is AudioStreamWAV, "Missing audio resource " + path)
	for cue in [&"human_step", &"human_step_b", &"human_step_c"]:
		check(BeeAudio.CUES.has(cue) and cue in BeeAudio.REAL_CUES and BeeAudio.stream_for(cue).resource_path.begins_with("res://audio/sfx/real/"), "Footstep variant not wired: " + str(cue))
	check(is_equal_approx(float(BeeAudio.CUES[&"human_step"][1]), -21.0), "Footstep level changed")
	check(not FileAccess.get_file_as_string("res://scripts/audio/bee_human_audio.gd").contains("create_timer"), "Old timed footstep system still present")
	check(stage.bee.find_children("WingBuzz", "AudioStreamPlayer", true, false).size() == 1 and stage.find_children("GardenAmbience", "AudioStreamPlayer", true, false).size() == 1, "Duplicate audio players")

	# Restart cleanup: freeing the level frees its audio; a fresh level has exactly one of each.
	var old_ambience := ambience.player
	var old_buzz := buzz
	stage.queue_free()
	await frames(3)
	check(not is_instance_valid(old_ambience) and not is_instance_valid(old_buzz), "Audio players survive a level restart")
	var second := LEVEL.instantiate() as BeeShmupStage
	root.add_child(second)
	current_scene = second
	await frames(3)
	check(second.find_children("GardenAmbience", "AudioStreamPlayer", true, false).size() == 1 and second.bee.find_children("WingBuzz", "AudioStreamPlayer", true, false).size() == 1, "Restart duplicated audio players")
	check(get_nodes_in_group("bee_audio_voice").size() < BeeAudio.MAX_VOICES, "Stale voices after restart")

	# Mix: weapons and explosions stay the loudest; ambience and buzz sit well below a base shot.
	var base_peak := shot_peak_db(&"base")
	check(ambience_peak <= base_peak - 8.0, "Ambience too loud (%.1f vs shot %.1f dBFS)" % [ambience_peak, base_peak])
	check(buzz_peak <= base_peak - 8.0, "Wing buzz too loud (%.1f vs shot %.1f dBFS)" % [buzz_peak, base_peak])
	check(step_peak <= shot_peak_db(&"tech_death") - 3.0 and step_peak <= base_peak + 3.0, "Footsteps must not overpower shots/explosions")
	check(shot_peak_db(&"bomb") > step_peak + 10.0 and shot_peak_db(&"tech_death") > step_peak, "Bomb and explosions must be louder than footsteps")
	print("POLISH_AUDIO_OK ambience=%.1f buzz=%.1f step=%.1f base_shot=%.1f dBFS steps=%d" % [ambience_peak, buzz_peak, step_peak, base_peak, steps_total])
	quit(0)
