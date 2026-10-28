extends SceneTree

# LOTE 14 · ETAPA 4: MusicManager. Files and loops, music bus (-8 dB) and sliders, title / story / level / robot / tarantula / victory themes, crossfade of 1.5 s, pause duck,
# death fade, restart, explosion duck.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const TITLE := preload("res://scenes/game/bee_title_screen.tscn")

var manager: Node
var stage: BeeShmupStage


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)


func wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func volume(track: StringName) -> float:
	return float(manager.call("track_volume_db", track))


func press(action: String) -> void:
	await process_frame
	Input.action_press(action)
	for i in 6:
		await process_frame
	Input.action_release(action)
	await process_frame


func load_level() -> void:
	if stage != null and is_instance_valid(stage):
		stage.queue_free()
		await process_frame
	stage = LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await process_frame
	await process_frame


func run() -> void:
	create_timer(100.0, true, false, true).timeout.connect(func(): quit(1))
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	manager = root.get_node_or_null("MusicManager")
	check(manager != null, "MusicManager must be an autoload")

	# --- files, formats, loops, buses ---------------------------------------------------------------------------------------------
	var tracks: Dictionary = manager.TRACKS
	check(tracks.size() == 6, "Six themes: title, story, level, robot, tarantula, victory")
	for id in tracks:
		var stream := load(str(tracks[id]["path"])) as AudioStreamMP3
		check(stream != null and stream.get_length() > 55.0, "%s: an mp3 of more than 55 s" % id)
		check(stream.loop == bool(tracks[id]["loop"]), "%s: the import loop flag matches (%s)" % [id, str(tracks[id]["loop"])])
	check(bool(tracks[&"title"]["loop"]) and bool(tracks[&"story"]["loop"]) and bool(tracks[&"level"]["loop"]) and bool(tracks[&"boss"]["loop"]) and bool(tracks[&"boss_tarantula"]["loop"]) and not bool(tracks[&"victory"]["loop"]), "All but victory loop")
	var music_bus := AudioServer.get_bus_index(&"Music")
	var sfx_bus := AudioServer.get_bus_index(&"SFX")
	check(music_bus >= 0 and sfx_bus >= 0 and music_bus != sfx_bus, "Separate music and effects buses")
	BeeGameSettings.music_volume = BeeGameSettings.MUSIC_DEFAULT_VOLUME # Tanda E: independent of the player's saved slider (not written to disk)
	manager.apply_volumes()
	check(is_equal_approx(AudioServer.get_bus_volume_db(music_bus), -8.0 + linear_to_db(BeeGameSettings.music_volume)) and is_equal_approx(manager.MUSIC_DEFAULT_DB, -8.0), "The music bus defaults to -8 dB")
	check(is_equal_approx(BeeGameSettings.MUSIC_DEFAULT_VOLUME, 0.25) and is_equal_approx(BeeGameSettings.sfx_volume, 1.0), "Sliders start at 100 %")

	# --- title -----------------------------------------------------------------------------------------------------------------------
	var title := TITLE.instantiate()
	root.add_child(title)
	current_scene = title
	await process_frame
	await wait(0.4)
	check(manager.current_track == &"title" and manager.is_playing(), "The title theme plays on the title screen")
	await wait(2.5)
	check(volume(&"title") > -4.0, "The title theme faded in (%.1f dB)" % volume(&"title"))
	title.queue_free()
	await process_frame
	var intro: Node = load("res://scenes/game/bee_intro_screen.tscn").instantiate()
	root.add_child(intro)
	current_scene = intro
	await process_frame
	check(manager.current_track == &"story" and manager.track_player(&"story") != null, "The illustrated introduction starts the story theme")
	intro.queue_free()
	await process_frame

	# --- level starts: crossfade from the story, loops, continues -----------------------------------------------------------------------------
	var crossfades_before := int(manager.crossfades)
	await load_level()
	check(manager.current_track == &"level" and manager.track_player(&"level") != null, "The level theme starts with Level 1")
	check(int(manager.crossfades) == crossfades_before + 1 and manager.track_player(&"story") != null, "Story -> level is a crossfade")
	await wait(2.7)
	check(manager.track_player(&"story") == null and volume(&"level") > -4.0, "The story theme is gone after the crossfade")
	check((manager.track_player(&"level").stream as AudioStreamMP3).loop, "The level theme loops")
	check(not stage.bee.is_defeated and manager.current_track == &"level", "The level theme goes on")

	# --- pause: the music goes down and comes back; sliders ---------------------------------------------------------------------------------------
	var qol := stage.get_node("CheckpointQoL") as BeeCheckpointQoL
	var before_pause := volume(&"level")
	await press("bee_pause")
	check(paused and qol.pause_panel.visible and manager.paused_duck, "Esc pauses and shows the music / effects sliders")
	await wait(0.6)
	check(volume(&"level") < before_pause - 6.0, "The music is quieter while paused (%.1f -> %.1f dB)" % [before_pause, volume(&"level")])
	qol.music_slider.value = 0.5
	qol.sfx_slider.value = 0.0
	check(is_equal_approx(BeeGameSettings.music_volume, 0.5) and absf(AudioServer.get_bus_volume_db(music_bus) - (-8.0 + linear_to_db(0.5))) < 0.01, "The music slider sets the music bus around its -8 dB default")
	check(AudioServer.get_bus_volume_db(sfx_bus) <= -79.0, "The effects slider at 0 silences the effects bus")
	qol.music_slider.value = 1.0
	qol.sfx_slider.value = 1.0
	check(is_equal_approx(AudioServer.get_bus_volume_db(music_bus), -8.0) and is_equal_approx(AudioServer.get_bus_volume_db(sfx_bus), -3.0), "Both sliders back at 100 % = the default buses")
	await press("bee_pause")
	check(not paused and not manager.paused_duck, "Esc resumes")
	await wait(0.6)
	check(volume(&"level") > before_pause - 1.0, "The music comes back after the pause (%.1f dB)" % volume(&"level"))

	# --- explosions duck the music a little ----------------------------------------------------------------------------------------------------------
	var level_db := volume(&"level")
	BeeAudio.play(stage, &"bomb")
	await wait(0.25)
	var ducked := volume(&"level")
	check(ducked < level_db - 2.5 and ducked > level_db - 6.0, "A big explosion ducks the music slightly (%.1f -> %.1f dB)" % [level_db, ducked])
	await wait(1.6)
	check(volume(&"level") > level_db - 0.5, "...and it comes back")

	# --- robot theme starts at the mini-boss and survives its defeat ---------------------------------------------------------------------------
	BeeMusic.boss()
	check(manager.current_track == &"boss" and manager.track_player(&"level") != null, "The robot theme crossfades from gameplay")
	await wait(manager.CROSSFADE_SECONDS + 0.1)
	var robot_player: AudioStreamPlayer = manager.track_player(&"boss")
	var robot_starts: int = manager.starts
	BeeMusic.boss()
	check(manager.track_player(&"boss") == robot_player and manager.starts == robot_starts, "The robot theme does not restart")

	# --- tarantula: crossfade when its bar appears ------------------------------------------------------------------------------------------------
	var wave := stage.wave as BeeLevel01Controller
	stage.scroll_speed = 0.0
	stage.distance = 296.0
	stage._update_camera_and_bounds()
	wave.event_index = BeeLevel01Controller.EVENTS_ROSTER.size()
	for unit in wave.active_units:
		unit.queue_free()
	wave.active_units.clear()
	wave._pending.clear()
	stage.bee.global_position = Vector3(stage.camera.global_position.x - 3.5, 3.4, 0.0)
	wave._tarantula_breather_left = 0.01
	var boss: TarantulaBoss01
	for i in 600:
		await physics_frame
		boss = wave.tarantula
		if boss != null and boss.health_bar_visible():
			break
	check(boss != null and boss.health_bar_visible(), "The tarantula walked in")
	boss.set_physics_process(false) # Isolate crossfade from the new boss-attack ducking.
	check(manager.current_track == &"boss_tarantula", "The tarantula theme starts when the health bar appears")
	check(manager.track_player(&"boss") != null and manager.track_player(&"boss_tarantula") != null, "Both boss themes overlap during the crossfade")
	await wait(0.75)
	var mid_level := volume(&"boss")
	var mid_boss := volume(&"boss_tarantula")
	check(mid_level < -1.0 and mid_level > -8.0 and mid_boss < -1.0 and mid_boss > -8.0, "Halfway the crossfade both sit near -3 dB (equal power, %.1f / %.1f dB)" % [mid_level, mid_boss])
	await wait(2.5)
	check(manager.track_player(&"boss") == null and volume(&"boss_tarantula") > -4.0, "After %.1f s only the tarantula theme is left" % manager.CROSSFADE_SECONDS)
	check(is_equal_approx(manager.CROSSFADE_SECONDS, 1.5), "The crossfade lasts 1.5 s")
	check((manager.track_player(&"boss_tarantula").stream as AudioStreamMP3).loop, "The tarantula theme loops")

	# --- victory: once, then fade ------------------------------------------------------------------------------------------------------------------------
	wave._on_tarantula_freed(boss)
	await wait(0.2)
	check(manager.current_track == &"boss_tarantula", "Victory does not play at the robot or before the results")
	wave._on_tarantula_gone(boss)
	await wait(0.2)
	check(manager.current_track == &"victory", "The victory theme plays when the tarantula is freed")
	var victory_player := manager.track_player(&"victory") as AudioStreamPlayer
	check(victory_player != null and not (victory_player.stream as AudioStreamMP3).loop, "The victory theme does not loop")
	await wait(1.0)
	victory_player.seek(victory_player.stream.get_length() - 1.0)
	await wait(0.25)
	check(volume(&"victory") < -6.0, "The victory theme fades out at its end (%.1f dB)" % volume(&"victory"))

	# --- death fades the music; the restart plays the right theme ------------------------------------------------------------------------------------------
	await load_level()
	await wait(0.6)
	check(manager.current_track == &"level", "A reloaded level plays the level theme")
	stage.bee.health.damage_blocked = false
	stage.bee.health.take_damage(9999)
	await wait(1.0)
	check(manager.current_track == &"" and volume(&"level") < -6.0, "The music fades out when Bee is defeated (%.1f dB)" % volume(&"level"))
	await wait(manager.DEATH_FADE_SECONDS)
	check(not manager.is_playing(), "Silence after the death fade")
	await load_level()
	await wait(0.4)
	check(manager.current_track == &"level" and manager.is_playing() and manager.track_player(&"level").get_playback_position() < 2.0, "A restart plays the level theme again from the start")
	print("BEE_LOTE14_MUSIC_V01_OK themes=6 loops=title,story,level,boss,boss_tarantula crossfade=1.5s music_bus=-8dB sliders pause_duck death_fade victory_once explosion_duck")
	quit(0)
