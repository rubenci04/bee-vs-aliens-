class_name BeeAudio
extends RefCounted

# path, relative dB, priority, spatial. One cue per accepted gameplay event.
const CUES := {
	&"base": ["weapons/base", -20.0, 1, false],
	&"spread": ["weapons/spread", -18.0, 1, false],
	&"tech_hit": ["enemies/tech_hit", -20.0, 2, true],
	&"organic_hit": ["enemies/organic_hit", -21.0, 2, true],
	&"melee": ["weapons/melee", -16.0, 2, true],
	&"bomb": ["weapons/bomb", -8.0, 6, false],
	&"bee_damage": ["player/damage", -11.0, 5, false],
	&"bee_defeat": ["player/defeat", -9.0, 7, false],
	# GARDEN IDENTITY 04: deaths are brighter and longer now -> 2 dB under the hostile telegraphs (mix hierarchy:
	# player danger > hostile telegraph > impact > ambience). BEFORE: tech -15, organic -16.
	&"tech_death": ["enemies/tech_death", -17.0, 3, true],
	&"organic_death": ["enemies/organic_death", -17.0, 3, true],
	&"crate": ["environment/crate", -16.0, 3, true],
	&"spread_pickup": ["pickups/spread", -21.0, 1, true],
	&"bomb_pickup": ["pickups/bomb", -19.0, 1, true],
	&"pollen": ["pickups/pollen", -26.0, 0, true],
	&"liberate": ["pickups/pollen", -19.0, 1, true], # NOCHE 01: a freed animal (the approved pollen chime, played higher).
	&"human_warning": ["environment/human_warning", -14.0, 4, true],
	&"human_step": ["environment/human_step", -21.0, 2, true],
	&"human_step_b": ["environment/human_step", -21.0, 2, true],
	&"human_step_c": ["environment/human_step", -21.0, 2, true],
	&"ufo_charge": ["weapons/bomb", -19.0, 3, true],
	# GARDEN IDENTITY 04 — hostile telegraphs (priority 4: never stolen by deaths/hits in a full voice pool).
	&"wasp_overload": ["weapons/bomb", -15.0, 4, true],
	&"walker_charge": ["enemies/tech_hit", -16.0, 4, true],
	&"organic_charge": ["enemies/organic_hit", -16.0, 4, true],
	&"spider_telegraph": ["enemies/tech_hit", -16.0, 4, true],
	&"spider_drop": ["weapons/melee", -17.0, 3, true],
	&"spider_retract": ["pickups/pollen", -23.0, 1, true],
}
const MAX_VOICES := 16
const REAL_CUES := [&"base", &"spread", &"tech_hit", &"organic_hit", &"melee", &"bomb", &"bee_damage", &"bee_defeat", &"tech_death", &"crate", &"spread_pickup", &"bomb_pickup", &"pollen", &"human_step", &"human_step_b", &"human_step_c", &"ufo_charge",
		&"organic_death", &"wasp_overload", &"walker_charge", &"organic_charge", &"spider_telegraph", &"spider_drop", &"spider_retract"]
## NOCHE 01: cues that reuse another real (approved) recording instead of a file of their own.
const REAL_ALIAS := {&"liberate": &"pollen"}
const REAL_GAIN_DB := {&"spread_pickup": -3.0, &"bomb_pickup": -3.0, &"pollen": -3.0}
## GARDEN IDENTITY 04: small per-play variation so repeated cues (30 deaths in a level) never sound identical.
## cue -> [pitch spread (+-), volume spread in dB (+-)]. Base/spread keep their own +-2.5 % pitch.
const VARIATION := {&"tech_death": [0.05, 1.5], &"organic_death": [0.06, 1.5], &"tech_hit": [0.04, 1.0], &"organic_hit": [0.04, 1.0],
		&"crate": [0.05, 1.0], &"spider_drop": [0.04, 0.5], &"spider_retract": [0.05, 1.0], &"melee": [0.03, 0.5]}
static var use_real_assets := true
static var _streams: Dictionary = {}

static func stream_for(cue: StringName) -> AudioStream:
	if not CUES.has(cue):
		push_error("Unknown Bee sound: " + str(cue))
		return null
	var path := "res://audio/sfx/%s.wav" % CUES[cue][0]
	var selected := "res://audio/sfx/real/%s.wav" % REAL_ALIAS.get(cue, cue)
	if use_real_assets and (cue in REAL_CUES or REAL_ALIAS.has(cue)) and ResourceLoader.exists(selected):
		path = selected
	if not _streams.has(path):
		_streams[path] = load(path) as AudioStream
		if _streams[path] == null and path == selected:
			_streams.erase(path)
			path = "res://audio/sfx/%s.wav" % CUES[cue][0]
			if not _streams.has(path):
				_streams[path] = load(path) as AudioStream
	return _streams[path]

static func play(parent: Node, cue: StringName, point := Vector3.ZERO, pitch := 1.0) -> Node:
	var stream := stream_for(cue)
	if stream == null:
		return null
	var host := parent
	while host.get_parent() is Node3D:
		host = host.get_parent()
	var container := host.get_node_or_null("BeeAudio") as Node3D
	if container == null:
		container = Node3D.new()
		container.name = "BeeAudio"
		host.add_child(container)
	var voices: Array[Node] = []
	for child in container.get_children():
		if not child.is_queued_for_deletion():
			voices.append(child)
	if voices.size() >= MAX_VOICES:
		var weakest := voices[0]
		for voice in voices:
			if int(voice.get_meta("priority")) < int(weakest.get_meta("priority")):
				weakest = voice
		if int(weakest.get_meta("priority")) >= int(CUES[cue][2]):
			return null
		weakest.call("stop")
		weakest.queue_free()
	var spatial := bool(CUES[cue][3])
	var player: Node = AudioStreamPlayer3D.new() if spatial else AudioStreamPlayer.new()
	player.name = "SFX_" + str(cue)
	player.set_meta("cue", cue)
	player.set_meta("priority", CUES[cue][2])
	player.set("stream", stream)
	player.set("bus", &"SFX")
	player.set("volume_db", CUES[cue][1] + (2.0 if pitch < 0.9 else 0.0))
	if stream.resource_path.begins_with("res://audio/sfx/real/"):
		player.set("volume_db", player.get("volume_db") + float(REAL_GAIN_DB.get(cue, 0.0)))
	var variation := randf_range(0.975, 1.025) if cue in [&"base", &"spread"] else 1.0
	if VARIATION.has(cue):
		var spread: Array = VARIATION[cue]
		variation = randf_range(1.0 - float(spread[0]), 1.0 + float(spread[0]))
		player.set("volume_db", player.get("volume_db") + randf_range(-float(spread[1]), float(spread[1])))
	player.set("pitch_scale", pitch * variation)
	if spatial:
		var world := player as AudioStreamPlayer3D
		world.unit_size = 12.0
		world.max_db = 0.0
		world.max_distance = 32.0 if cue in [&"human_step", &"human_step_b", &"human_step_c", &"human_warning"] else 26.0
		world.panning_strength = 0.35
		world.position = container.to_local(point)
	container.add_child(player)
	player.add_to_group("bee_audio_voice")
	# Explicitly release playback when a scene is freed during a short cue.
	player.tree_exiting.connect(func():
		player.call("stop")
		player.set("stream", null)
	)
	player.connect("finished", player.queue_free)
	# Also cleans up on Dummy/headless; real-time sounds ignore simulation speed.
	host.get_tree().create_timer(stream.get_length() / (pitch * variation) + 0.15, true, false, true).timeout.connect(player.queue_free)
	# Headless validates streams/events/lifetime without starting a Dummy mixer.
	# Actual playback is exercised by the same tests with the Windows renderer.
	if DisplayServer.get_name() != "headless":
		player.call("play")
	return player
