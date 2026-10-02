extends SceneTree
## POLISH-02 audio integration. Reads ONLY already approved files from the local asset library and
## writes derived copies into the project (never touches the originals):
##   audio/ambience/garden_loop.wav   Sonniss / Just Sound Effects "Highlands of Norway" meadow ambience
##   audio/sfx/real/wing_buzz.wav     Sonniss / Sonik Sound Library "Toy Quadcopter" sustained flight
##   audio/sfx/real/human_step_b|c    Kenney footstep_grass_001 / _002 (same recipe as human_step)
## Run: godot --headless --path . --script res://tools/integrate_audio_polish02.gd
## Prints one JSON record per output (source, sha256, edits) to copy into audio/sfx/PROVENANCE.md.

const INSPECT := preload("res://tools/inspect_audio_v02.gd")
const MEADOW := "Sonniss.com-GDC2026-GameAudioBundle/Just Sound Effects - Highlands of Norway/AMBSwmp_Meadow Pipits calling many Insects humming Wind blowing through Grass_JSE_HoN_Stereo.wav"
const QUADCOPTER := "Sonniss.com-GDC2026-GameAudioBundle/Sonik Sound Library - Toy Quadcopter/AERORadio_Quadcopter, Toy, Flying Sustained Close to Mic_KSL_KS013.wav"
const STEPS := {"human_step_b": "kenney_impact-sounds/Audio/footstep_grass_001.ogg", "human_step_c": "kenney_impact-sounds/Audio/footstep_grass_002.ogg"}
const AMBIENCE_SECONDS := 24.0
const AMBIENCE_CROSSFADE := 2.5
const BUZZ_SECONDS := 4.0
const BUZZ_CROSSFADE := 0.4


func _initialize() -> void:
	var rate := AudioServer.get_mix_rate()
	_ambience(rate)
	_buzz(rate)
	for cue in STEPS:
		_step(cue, STEPS[cue], rate)
	quit(0)


func _mono(samples: PackedVector2Array) -> PackedFloat32Array:
	var mono := PackedFloat32Array()
	mono.resize(samples.size())
	for i in samples.size():
		mono[i] = (samples[i].x + samples[i].y) * 0.5
	return mono


## Window of `seconds` whose per-second loudness varies the least (no bird shout, no gust).
func _calmest_window(mono: PackedFloat32Array, rate: float, seconds: float) -> int:
	var per_second: Array[float] = []
	for s in int(mono.size() / rate):
		var energy := 0.0
		for i in range(int(s * rate), int((s + 1) * rate), 8):
			energy += mono[i] * mono[i]
		per_second.append(sqrt(energy / (rate / 8.0)))
	var best_start := 0
	var best_score := INF
	var window := int(seconds)
	for start in range(0, per_second.size() - window):
		var mean := 0.0
		for k in window:
			mean += per_second[start + k]
		mean /= window
		var variance := 0.0
		var peak := 0.0
		for k in window:
			variance += pow(per_second[start + k] - mean, 2.0)
			peak = maxf(peak, per_second[start + k])
		var score := variance / window + 0.5 * pow(peak - mean, 2.0)
		if score < best_score:
			best_score = score
			best_start = start
	return int(best_start * rate)


func _loop_crossfade(segment: Array, crossfade: int) -> Array:
	var length: int = segment.size() - crossfade
	var out := []
	out.resize(length)
	for i in length:
		out[i] = segment[i]
	for i in crossfade:
		var t := float(i) / float(crossfade)
		var fade_in := sin(t * PI * 0.5)
		var fade_out := cos(t * PI * 0.5)
		out[i] = segment[i] * fade_in + segment[length + i] * fade_out
	return out


func _save_wav(path: String, left: PackedFloat32Array, right: PackedFloat32Array, rate: int) -> void:
	var stereo := right.size() > 0
	var bytes := PackedByteArray()
	bytes.resize(left.size() * (4 if stereo else 2))
	for i in left.size():
		if stereo:
			bytes.encode_s16(i * 4, roundi(clampf(left[i], -1.0, 1.0) * 32767))
			bytes.encode_s16(i * 4 + 2, roundi(clampf(right[i], -1.0, 1.0) * 32767))
		else:
			bytes.encode_s16(i * 2, roundi(clampf(left[i], -1.0, 1.0) * 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = stereo
	wav.mix_rate = rate
	wav.data = bytes
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	if wav.save_to_wav(ProjectSettings.globalize_path(path)) != OK:
		push_error("Cannot save " + path)
		quit(1)


func _record(output: String, source: String, extra: Dictionary) -> void:
	var record := {"output": output, "source": INSPECT.LIBRARY + source, "source_sha256": FileAccess.get_sha256(INSPECT.LIBRARY + source), "output_sha256": FileAccess.get_sha256(output)}
	record.merge(extra)
	print("INTEGRATED ", JSON.stringify(record))


func _ambience(rate: int) -> void:
	var samples := INSPECT.decode(MEADOW)
	var start := _calmest_window(_mono(samples), rate, AMBIENCE_SECONDS)
	var length := int(AMBIENCE_SECONDS * rate)
	var crossfade := int(AMBIENCE_CROSSFADE * rate)
	var left := []
	var right := []
	for i in length:
		left.append(samples[start + i].x)
		right.append(samples[start + i].y)
	var looped_left := _loop_crossfade(left, crossfade)
	var looped_right := _loop_crossfade(right, crossfade)
	var peak := 0.0
	var energy := 0.0
	for i in looped_left.size():
		peak = maxf(peak, maxf(absf(looped_left[i]), absf(looped_right[i])))
		energy += looped_left[i] * looped_left[i] + looped_right[i] * looped_right[i]
	var scale := 0.30 / peak
	var out_left := PackedFloat32Array()
	var out_right := PackedFloat32Array()
	for i in looped_left.size():
		var fade := minf(float(i) / (rate * 0.01), 1.0) * minf(float(looped_left.size() - 1 - i) / (rate * 0.01), 1.0)
		out_left.append(looped_left[i] * scale * fade)
		out_right.append(looped_right[i] * scale * fade)
	_save_wav("res://audio/ambience/garden_loop.wav", out_left, out_right, rate)
	_record("res://audio/ambience/garden_loop.wav", MEADOW, {"start_seconds": float(start) / rate, "duration": float(out_left.size()) / rate, "rms": sqrt(energy / (2.0 * looped_left.size())) * scale, "peak": 0.30, "edits": "decoded 96 kHz/24 bit stereo, calmest %.0f s window, %.1f s equal-power loop crossfade, resampled to mix rate, peak 0.30, 10 ms edge fades, PCM16 stereo" % [AMBIENCE_SECONDS, AMBIENCE_CROSSFADE]})


func _buzz(rate: int) -> void:
	var samples := INSPECT.decode(QUADCOPTER)
	var mono := _mono(samples)
	var start := _calmest_window(mono, rate, BUZZ_SECONDS + 1.0)
	var length := int(BUZZ_SECONDS * rate)
	var crossfade := int(BUZZ_CROSSFADE * rate)
	# Soft insect-like hum: two cascaded one-pole low-passes (about 900 Hz) and a 110 Hz high-pass.
	var low_a := 0.0
	var low_b := 0.0
	var alpha := 1.0 - exp(-TAU * 900.0 / rate)
	var hp := exp(-TAU * 110.0 / rate)
	var warm: Array = []
	for i in length:
		var x := mono[start + i]
		low_a += alpha * (x - low_a)
		low_b += alpha * (low_a - low_b)
		warm.append(low_b)
	var previous_in := 0.0
	var previous_out := 0.0
	var filtered: Array = []
	for i in length:
		var value: float = warm[i]
		previous_out = hp * (previous_out + value - previous_in)
		previous_in = value
		filtered.append(previous_out)
	var looped := _loop_crossfade(filtered, crossfade)
	var peak := 0.0
	var energy := 0.0
	for value in looped:
		peak = maxf(peak, absf(value))
		energy += value * value
	var scale := 0.5 / peak
	var out := PackedFloat32Array()
	for i in looped.size():
		out.append(looped[i] * scale)
	_save_wav("res://audio/sfx/real/wing_buzz.wav", out, PackedFloat32Array(), rate)
	_record("res://audio/sfx/real/wing_buzz.wav", QUADCOPTER, {"start_seconds": float(start) / rate, "duration": float(out.size()) / rate, "rms": sqrt(energy / looped.size()) * scale, "peak": 0.5, "edits": "decoded 48 kHz/24 bit stereo to mono, calmest %.0f s window, 2 x one-pole low-pass 900 Hz, one-pole high-pass 110 Hz, %.1f s equal-power loop crossfade, peak 0.50, PCM16 mono" % [BUZZ_SECONDS, BUZZ_CROSSFADE]})


func _step(cue: String, source: String, rate: int) -> void:
	var original := INSPECT.decode(source)
	var pitch := 0.70
	var length := mini(ceili(0.30 * rate), floori(original.size() / pitch))
	var mono := PackedFloat32Array()
	mono.resize(length)
	var peak := 0.0
	for i in length:
		var index := mini(floori(i * pitch), original.size() - 1)
		mono[i] = (original[index].x + original[index].y) * 0.5
		peak = maxf(peak, absf(mono[i]))
	var out := PackedFloat32Array()
	out.resize(length)
	for i in length:
		var envelope := minf(float(i) / (rate * 0.002), 1.0) * minf(float(length - 1 - i) / (rate * 0.035), 1.0)
		out[i] = mono[i] * (0.40 / peak) * envelope
	var path := "res://audio/sfx/real/%s.wav" % cue
	_save_wav(path, out, PackedFloat32Array(), rate)
	_record(path, source, {"duration": float(length) / rate, "peak": 0.40, "pitch_baked": pitch, "license": "CC0", "author": "Kenney", "edits": "OGG decoded to mono PCM16 WAV; shortened; normalized to peak 0.40; 2ms/35ms fades; pitch baked 0.70"})
