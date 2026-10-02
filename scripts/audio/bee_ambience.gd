class_name BeeAmbience
extends Node
## Looping garden ambience (meadow, insects, distant birds, wind) on the Ambience bus.
## Fades in when the level starts. Level target is far below the weapons/explosions:
## see docs/AUDIO_MUSIC_AUDIT_01.md and the levels in tests/levels/validate_bee_polish_audio_v01.gd.

@export var stream_path := "res://audio/ambience/garden_loop.wav"
@export var target_db := -24.0
@export var fade_seconds := 4.0

var player: AudioStreamPlayer
var tween: Tween

func _ready() -> void:
	var source := load(stream_path) as AudioStreamWAV
	if source == null:
		push_error("Missing ambience " + stream_path)
		return
	var stream := source.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / (4 if stream.stereo else 2)
	player = AudioStreamPlayer.new()
	player.name = "GardenAmbience"
	player.stream = stream
	player.bus = &"Ambience"
	player.volume_db = -60.0
	add_child(player)
	# Headless runs validate wiring without starting a Dummy mixer (same convention as BeeAudio).
	if DisplayServer.get_name() != "headless":
		player.play()
	tween = create_tween()
	tween.tween_property(player, "volume_db", target_db, fade_seconds).set_trans(Tween.TRANS_SINE)
