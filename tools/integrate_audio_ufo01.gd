extends SceneTree
## UFO BOSS 01 audio. Reads ONLY approved library files (docs/AUDIO_MUSIC_AUDIT_01.md) and writes
## derived copies into audio/sfx/real/ (originals untouched):
##   ufo_sting   Sonniss / Epic Stock Media "Halloween Game" alien swell  (entrance sting)
##   ufo_charge  Kenney Sci-Fi forceField_002                             (attack telegraph)
##   ufo_hover   Kenney Sci-Fi spaceEngineLow_000                         (hover loop)
##   ufo_death   Kenney Sci-Fi lowFrequency_explosion_000 + explosionCrunch_004 (final explosion)
## Run: godot --headless --path . --script res://tools/integrate_audio_ufo01.gd

const INSPECT := preload("res://tools/inspect_audio_v02.gd")
const STING := "Sonniss.com-GDC2026-GameAudioBundle/Epic Stock Media - Halloween Game - Haunted House and Horror Audio Scare Kit/UIAlert_Alert Designed Transition Swell Creature Strange Alien Layered 01_ESM_HALG.wav"
const CHARGE := "kenney_sci-fi-sounds/Audio/forceField_002.ogg"
const HOVER := "kenney_sci-fi-sounds/Audio/spaceEngineLow_000.ogg"
const DEATH_LOW := "kenney_sci-fi-sounds/Audio/lowFrequency_explosion_000.ogg"
const DEATH_CRUNCH := "kenney_sci-fi-sounds/Audio/explosionCrunch_004.ogg"


func _initialize() -> void:
	var rate := int(AudioServer.get_mix_rate())
	_one_shot("ufo_sting", STING, rate, 3.4, 0.8, 0.45, "Sonniss GDC Royalty-Free", "Epic Stock Media (Sonniss GDC 2026)")
	_one_shot("ufo_charge", CHARGE, rate, 0.45, 0.12, 0.40, "CC0", "Kenney")
	_hover(rate)
	_death(rate)
	quit(0)


func _mono(source: String) -> PackedFloat32Array:
	var samples := INSPECT.decode(source)
	var mono := PackedFloat32Array()
	mono.resize(samples.size())
	for i in samples.size():
		mono[i] = (samples[i].x + samples[i].y) * 0.5
	return mono


func _write(path: String, data: PackedFloat32Array, rate: int, peak_target: float) -> float:
	var peak := 0.0
	for v in data:
		peak = maxf(peak, absf(v))
	var scale := peak_target / maxf(peak, 0.0001)
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, roundi(clampf(data[i] * scale, -1.0, 1.0) * 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = bytes
	wav.save_to_wav(ProjectSettings.globalize_path(path))
	return float(data.size()) / rate


func _record(cue: String, sources: Array, extra: Dictionary) -> void:
	var path := "res://audio/sfx/real/%s.wav" % cue
	var record := {"output": path, "output_sha256": FileAccess.get_sha256(path)}
	for i in sources.size():
		record["source_%d" % i] = sources[i]
		record["source_%d_sha256" % i] = FileAccess.get_sha256(INSPECT.LIBRARY + sources[i])
	record.merge(extra)
	print("INTEGRATED ", JSON.stringify(record))


func _one_shot(cue: String, source: String, rate: int, seconds: float, fade_out: float, peak: float, license: String, author: String) -> void:
	var mono := _mono(source)
	var length := mini(int(seconds * rate), mono.size())
	var out := PackedFloat32Array()
	out.resize(length)
	for i in length:
		var envelope := minf(float(i) / (rate * 0.004), 1.0) * minf(float(length - 1 - i) / (rate * fade_out), 1.0)
		out[i] = mono[i] * envelope
	var duration := _write("res://audio/sfx/real/%s.wav" % cue, out, rate, peak)
	_record(cue, [source], {"duration": duration, "peak": peak, "license": license, "author": author,
		"edits": "decoded to mono PCM16, first %.2f s, 4 ms fade-in, %.2f s fade-out, peak %.2f" % [seconds, fade_out, peak]})


func _hover(rate: int) -> void:
	var mono := _mono(HOVER)
	var crossfade := int(0.5 * rate)
	var length := mono.size() - crossfade
	var out := PackedFloat32Array()
	out.resize(length)
	for i in length:
		out[i] = mono[i]
	for i in crossfade:
		var t := float(i) / float(crossfade)
		out[i] = mono[i] * sin(t * PI * 0.5) + mono[length + i] * cos(t * PI * 0.5)
	var duration := _write("res://audio/sfx/real/ufo_hover.wav", out, rate, 0.35)
	_record("ufo_hover", [HOVER], {"duration": duration, "peak": 0.35, "license": "CC0", "author": "Kenney",
		"edits": "decoded to mono PCM16, 0.5 s equal-power loop crossfade, peak 0.35 (looped at runtime)"})


func _death(rate: int) -> void:
	var low := _mono(DEATH_LOW)
	var crunch := _mono(DEATH_CRUNCH)
	var length := int(2.2 * rate)
	var out := PackedFloat32Array()
	out.resize(length)
	for i in length:
		var value := 0.0
		if i < low.size():
			value += low[i] * 0.75
		var j := i - int(0.03 * rate)
		if j >= 0 and j < crunch.size():
			value += crunch[j] * 0.6
		var envelope := minf(float(i) / (rate * 0.002), 1.0) * minf(float(length - 1 - i) / (rate * 0.4), 1.0)
		out[i] = value * envelope
	var duration := _write("res://audio/sfx/real/ufo_death.wav", out, rate, 0.45)
	_record("ufo_death", [DEATH_LOW, DEATH_CRUNCH], {"duration": duration, "peak": 0.45, "license": "CC0", "author": "Kenney",
		"edits": "two layers mixed to mono PCM16 (crunch delayed 30 ms), 2.2 s, 0.4 s fade-out, peak 0.45"})
