extends SceneTree

const REVIEW := preload("res://dev/audio_review/audio_review.tscn")

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> bool:
	if not ok:
		push_error(message)
		quit(1)
	return ok

func run() -> void:
	for cue in BeeAudio.CUES:
		BeeAudio.use_real_assets = false
		var placeholder := BeeAudio.stream_for(cue) as AudioStreamWAV
		if not check(placeholder != null and placeholder.get_length() > 0, "Missing preserved placeholder " + str(cue)):
			return
		BeeAudio.use_real_assets = true
		var selected := BeeAudio.stream_for(cue) as AudioStreamWAV
		if not check(selected != null and selected.loop_mode == AudioStreamWAV.LOOP_DISABLED and selected.get_length() <= 0.75, "Invalid selected clip " + str(cue)):
			return
		if cue in BeeAudio.REAL_CUES or BeeAudio.REAL_ALIAS.has(cue): # NOCHE 01: aliases reuse another approved real clip.
			if not check(selected != placeholder and selected.resource_path == "res://audio/sfx/real/%s.wav" % BeeAudio.REAL_ALIAS.get(cue, cue), "External mapping not used " + str(cue)):
				return
			# Godot may compress the imported resource as QOA; validate the source PCM.
			var raw := AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(selected.resource_path))
			if not check(raw != null and not raw.stereo and raw.format == AudioStreamWAV.FORMAT_16_BITS, "World copy must be mono PCM16"):
				return
			for i in range(0, raw.data.size(), 2):
				if not check(absf(float(raw.data.decode_s16(i)) / 32767.0) <= 0.41, "Unbounded PCM peak"):
					return
		else:
			if not check(selected == placeholder, "Reserved cue changed"):
				return
	for name in ["Kenney_SciFi", "Kenney_Impact", "Kenney_Interface"]:
		if not check(FileAccess.file_exists("res://audio/sfx/licenses/%s.txt" % name), "Missing license copy"):
			return
	var scene := REVIEW.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	for i in BeeAudio.CUES.size():
		scene.index = i
		scene.refresh()
		var a: Node = scene.play_selected(false)
		var b: Node = scene.play_selected(true)
		if not check(a != null and b != null and b.get("bus") == &"SFX", "A/B review cue failed"):
			return
		if DisplayServer.get_name() != "headless" and not check(b.get("playing"), "Selected playback did not start"):
			return
		await process_frame
	await scene.spam_base()
	await create_timer(1.0).timeout
	if not check(get_nodes_in_group("bee_audio_voice").is_empty() and BeeAudio.use_real_assets, "Review cleanup/mode restoration failed"):
		return
	print("BEE_AUDIO_ASSETS_V02_OK real=14 placeholders_preserved=16 reserved=2 peaks loops licenses review_AB base_spam cleanup")
	quit(0)
