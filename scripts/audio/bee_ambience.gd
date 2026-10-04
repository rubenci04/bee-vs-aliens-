class_name BeeAmbience
extends Node
## Looping garden ambience (meadow, insects, distant birds, wind) on the Ambience bus.
## Fades in when the level starts. Level target is far below the weapons/explosions:
## see docs/AUDIO_MUSIC_AUDIT_01.md and the levels in tests/levels/validate_bee_polish_audio_v01.gd.
## GARDEN IDENTITY 04: a second loop, crickets and far birds at dusk (DuskAmbience), follows the sunset of the light
## progression (silent before DUSK_FROM, full from DUSK_FULL) under the meadow, which dips a little as it rises.

@export var stream_path := "res://audio/ambience/garden_loop.wav"
@export var target_db := -24.0
@export var fade_seconds := 4.0
@export var dusk_stream_path := "res://audio/ambience/dusk_loop.wav"
@export var dusk_target_db := -27.0
## Stage X where the dusk layer starts / reaches its target (the sunset blend of BeeLevel01LightProgression).
const DUSK_FROM := 210.0
const DUSK_FULL := 290.0
const MEADOW_DIP_DB := 3.0
const SILENT_DB := -60.0

var player: AudioStreamPlayer
var dusk_player: AudioStreamPlayer
var tween: Tween
var dusk_amount := 0.0

func _ready() -> void:
	player = _loop_player("GardenAmbience", stream_path)
	if player == null:
		return
	dusk_player = _loop_player("DuskAmbience", dusk_stream_path)
	# Headless runs validate wiring without starting a Dummy mixer (same convention as BeeAudio).
	if DisplayServer.get_name() != "headless":
		player.play()
		if dusk_player != null:
			dusk_player.play()
	tween = create_tween()
	tween.tween_property(player, "volume_db", target_db, fade_seconds).set_trans(Tween.TRANS_SINE)

func _loop_player(label: String, path: String) -> AudioStreamPlayer:
	var source := load(path) as AudioStreamWAV
	if source == null:
		push_error("Missing ambience " + path)
		return null
	var stream := source.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / (4 if stream.stereo else 2)
	var loop := AudioStreamPlayer.new()
	loop.name = label
	loop.stream = stream
	loop.bus = &"Ambience"
	loop.volume_db = SILENT_DB
	add_child(loop)
	return loop

func _process(_delta: float) -> void:
	if dusk_player == null:
		return
	var stage := get_parent()
	var x: float = stage.get("distance") if stage != null and "distance" in stage else 0.0
	dusk_amount = smoothstep(DUSK_FROM, DUSK_FULL, x)
	dusk_player.volume_db = lerpf(SILENT_DB, dusk_target_db, sqrt(dusk_amount)) if dusk_amount > 0.0 else SILENT_DB
	if tween == null or not tween.is_running():
		player.volume_db = target_db - MEADOW_DIP_DB * dusk_amount
