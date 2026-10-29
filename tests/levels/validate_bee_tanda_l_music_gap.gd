extends SceneTree

const MAX_GAP_SECONDS := 0.3
const SAMPLE_SECONDS := 0.02
var manager: Node


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)


func wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func run() -> void:
	manager = root.get_node_or_null("MusicManager")
	check(manager != null, "MusicManager autoload is present")
	manager.stop_all()
	manager.set_paused(false)
	for path in DirAccess.get_files_at("res://audio"):
		if not path.to_lower().ends_with(".mp3"):
			continue
		var full_path := "res://audio/" + path
		check(manager.SILENCE_TRIMS.has(full_path), "Silence trims missing for " + path)
		var trim: Dictionary = manager.SILENCE_TRIMS[full_path]
		check(float(trim["start_trim"]) >= 0.0 and float(trim["end_trim"]) > 0.0, "Invalid trims for " + path)

	manager.play_track(&"level", 0.01, true)
	await wait(0.08)
	var outgoing: AudioStreamPlayer = manager._players[manager._active]
	var loop_at: float = manager.loop_start_at(&"level", outgoing.stream.get_length())
	check(absf(loop_at - (outgoing.stream.get_length() - 2.731 - 1.5)) < 0.01, "Loop begins before recorded silence")
	outgoing.seek(loop_at - 0.08)
	var loops_before: int = manager.loop_crossfades
	var max_gap := 0.0
	var gap := 0.0
	for i in 100:
		await wait(SAMPLE_SECONDS)
		var audible := false
		for j in 2:
			var player: AudioStreamPlayer = manager._players[j]
			if player.playing and manager._fade_gain[j] > 0.05:
				audible = true
		if audible:
			gap = 0.0
		else:
			gap += SAMPLE_SECONDS
			max_gap = maxf(max_gap, gap)
	check(manager.loop_crossfades == loops_before + 1, "A new level iteration began before the tail silence")
	check(max_gap < MAX_GAP_SECONDS, "Music gap %.2f s exceeds %.2f s" % [max_gap, MAX_GAP_SECONDS])
	check(manager.current_track == &"level" and manager._players[manager._active].get_playback_position() < 3.0, "New iteration starts at the trimmed head")

	# Pause during the next loop crossfade. Both playback positions and tween gains must hold.
	var current: AudioStreamPlayer = manager._players[manager._active]
	current.seek(manager.loop_start_at(&"level", current.stream.get_length()) - 0.04)
	for i in 30:
		if manager.loop_crossfades >= loops_before + 2:
			break
		await wait(0.02)
	check(manager.loop_crossfades == loops_before + 2, "Second crossfade started")
	manager.set_paused(true)
	var paused_positions := [manager._players[0].get_playback_position(), manager._players[1].get_playback_position()]
	var paused_gains: Array = manager._fade_gain.duplicate()
	await wait(0.35)
	for j in 2:
		check(absf(manager._players[j].get_playback_position() - paused_positions[j]) < 0.08, "Pause holds playback position")
		check(absf(manager._fade_gain[j] - paused_gains[j]) < 0.02, "Pause holds crossfade gain")
	manager.set_paused(false)
	await wait(1.7)
	check(manager.current_track == &"level" and manager._players[manager._active].playing, "Music continues after pause")

	manager.play_track(&"victory", 0.01, true)
	await wait(0.08)
	var victory: AudioStreamPlayer = manager._players[manager._active]
	check(not (victory.stream as AudioStreamMP3).loop, "Victory does not loop")
	victory.seek(victory.stream.get_length() - 0.3)
	var loops_at_victory: int = manager.loop_crossfades
	await wait(0.5)
	check(manager.loop_crossfades == loops_at_victory, "Victory never crossfades into itself")
	manager.stop_all()
	print("BEE_TANDA_L_MUSIC_GAP_OK trims=%d max_gap=%.2fs pause_resume victory_once" % [manager.SILENCE_TRIMS.size(), max_gap])
	quit(0)
