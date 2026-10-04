extends SceneTree
## GARDEN IDENTITY & AUDIO PASS 04 — audio integration. Reads only approved library files (Sonniss GDC 2026,
## royalty-free; Kenney CC0) and the project's own human_step copies, and writes derived files into res://audio.
## Originals are never touched. Every choice was checked with dev/audio_audition (signal analysis + spectrogram
## sheets, analysis/*.png) and is listed for listening in dev/audio_audition/audio_audition.tscn.
##   godot --headless --path . --script res://tools/integrate_audio_garden04.gd
## Cue clips follow the V02 contract (mono PCM16, peak 0.40, <= 0.75 s, short fades). Long files: ufo_approach
## (one-shot swell) and dusk_loop (ambience loop, peak 0.30 like garden_loop).
## Prints one JSON record per output for audio/sfx/PROVENANCE.md.

const C := preload("res://dev/audio_audition/audition_candidates.gd")
const SON := "Sonniss.com-GDC2026-GameAudioBundle/"
const PEAK := 0.40
const MAX_CUE := 0.72
## Death cues are shorter: heavy deaths play at pitch 0.82 and vary -5 %, and every temporary voice must be gone
## within 1 s (tests/bee_prototype/validate_bee_audio_basic_v01.gd): 0.60 / (0.82 * 0.95) + 0.15 = 0.92 s.
const DEATH_CUE := 0.6
## Giant Human: weight under the grass step without drowning it (a plain 0.75 mix gave a 52 Hz centroid and a quieter crunch).
const IMPACT_GAIN := 0.8 ## thud peak relative to the step peak (-2 dB)

var rate := 44100.0


func _initialize() -> void:
	rate = AudioServer.get_mix_rate()
	# 1. Enemy death (tech): brighter, crunchier blast that reads over the low end of the mix.
	_cue("tech_death", [[SON + "Epic Stock Media - Anime Game/EXPLDsgn_Explosion Small Blast Enemy Death Crunchy Boom Cartoon Noisy Crash Impact Delay 03_ESM_AG.wav", 0.0, 1.0]], 0.18, DEATH_CUE)
	# 2. Enemy death (organic): a wet splat with a short tail of bubbles (it was still a procedural placeholder).
	_cue("organic_death", [[SON + "Epic Stock Media - Tower Defense Game/WOODImpt_Hit Blood Spill Splat Wood Impact Light Hit Squelch Small Thump 03_ESM_TDG.wav", 0.0, 1.0],
			[SON + "Cinematic Sound Design - Cartoon & Animation Vol 2/Cartoon Bubbles Short.wav", 0.07, 0.55]], 0.15, DEATH_CUE)
	# 3. Wasp OVERLOAD telegraph: an insect tremble instead of the generic UFO charge.
	_cue("wasp_overload", [[SON + "SoundBits - Vox Bestiae - Source Elements/CREAInsc_Insectoid Creature Tremble Attack Long 1_SNDBTS_VB-SE.wav", 0.0, 1.0]], 0.16)
	# 4. Organic Alien identity: the bio-orb windup wobbles (low modulated creature sound).
	_cue("organic_charge", [[SON + "Epic Stock Media - Anime Game/DSGNMisc_Misc Monster Tentacle Modulated Creature Shadow Abstract Swept Wobble Lfo 02_ESM_AG.wav", 0.0, 1.0]], 0.14)
	# 5. Walker identity: servo whine + thump when the violet sweep charges.
	_cue("walker_charge", [[SON + "Epic Stock Media - Tower Defense Game/ROBTMvmt_Tower Deploy Hitech Robot Motor Dark Thump Servo Whine 04_ESM_TDG.wav", 0.0, 1.0]], 0.12)
	# 6. Giant Human: the three grass steps keep their texture and get a deep impact layer (weight, scale).
	var impact := SON + "Cinematic Sound Design - Colossal Impacts/Impact Cut Sweep.wav"
	for cue in ["human_step", "human_step_b", "human_step_c"]:
		_human_step(cue, impact)
	# 7. Spider (new family): implant charge, fast drop, thread reeling back.
	_cue("spider_telegraph", [[SON + "InMotionAudio - Arc/ELECArc_ArcDesign15_InMotionAudio_Arc.wav", 0.0, 1.0]], 0.14, 0.62)
	_cue("spider_drop", [[SON + "Cinematic Sound Design - Ultra Transitions & Impacts/Woosh Sweep Slide Infographics Basic.wav", 0.0, 1.0]], 0.06)
	_cue("spider_retract", [[SON + "Epic Stock Media - HD Lock And Mechanism Sound Design Kit/MECHMisc_Tool Tape Measure Pull Retract Spring Slide Spin Long 07_ESM_HDLM.wav", 1.95, 1.0]], 0.12, 0.6)
	# 8. UFO anticipation ("the last silence"): the slow swell of a designed "unidentified encounter".
	_long("res://audio/sfx/real/ufo_approach.wav", SON + "344 Audio - Air Designed/AEROJet_Unidentified Encounter_344 Audio_Air Designed.wav", 2.0, 5.0, 1.0, 0.7, 0.5)
	# 9. Dusk ambience layer (crickets + far birds), fades in with the sunset under the meadow loop.
	_loop("res://audio/ambience/dusk_loop.wav", SON + "344 Audio - East Coast America Vol. 1/AMBSubn_Ambience, Forest Crickets, Birds, Connecticut 02_344 Audio_East Coast America.wav", 22.0, 2.5)
	quit(0)


## layers: [[library path, start offset in the output (s), gain]]; each layer starts at its own onset.
func _cue(cue: String, layers: Array, fade_out: float, length := MAX_CUE) -> void:
	var out := PackedFloat32Array()
	out.resize(int(length * rate))
	var first_source := ""
	for layer in layers:
		var mono := C.decode_mono(layer[0], 8.0)
		var onset := _onset(mono)
		var offset := int(float(layer[1]) * rate) if float(layer[1]) < 1.0 else 0
		var source_start := onset if float(layer[1]) < 1.0 else int(float(layer[1]) * rate) # >= 1 s means "start here in the source"
		for i in range(offset, out.size()):
			var j := source_start + i - offset
			if j >= mono.size():
				break
			out[i] += mono[j] * float(layer[2])
		if first_source == "":
			first_source = layer[0]
	_shape(out, 0.002, fade_out)
	_normalize(out, PEAK)
	var path := "res://audio/sfx/real/%s.wav" % cue
	_save(path, out, PackedFloat32Array())
	_record(path, layers, {"duration": out.size() / rate, "peak": PEAK, "edits": "decoded, from onset, %d layer(s), %.2f s, %.0f ms fade-out, mono PCM16, peak 0.40" % [layers.size(), out.size() / rate, fade_out * 1000.0]})


## Always rebuilt from the Kenney sources (V02 / POLISH-02 recipe: pitch 0.7 baked), so the tool is idempotent.
const STEP_SOURCES := {"human_step": "kenney_impact-sounds/Audio/footstep_grass_000.ogg", "human_step_b": "kenney_impact-sounds/Audio/footstep_grass_001.ogg",
		"human_step_c": "kenney_impact-sounds/Audio/footstep_grass_002.ogg"}


func _human_step(cue: String, impact_path: String) -> void:
	var raw := C.decode_mono(STEP_SOURCES[cue], 2.0)
	var onset := _onset(raw)
	var step := PackedFloat32Array()
	for i in int(0.3 * rate):
		var x := onset + i * 0.7 # Pitch 0.7: a lower, heavier grass step (unchanged V02 recipe).
		var j := int(x)
		step.append(lerpf(raw[mini(j, raw.size() - 1)], raw[mini(j + 1, raw.size() - 1)], x - j) if j < raw.size() else 0.0)
	var impact := C.decode_mono(impact_path, 4.0)
	# The impact is the loudest moment of the source (after its whoosh): start 15 ms before it.
	var peak_at := 0
	for i in impact.size():
		if absf(impact[i]) > absf(impact[peak_at]):
			peak_at = i
	var start := maxi(0, peak_at - int(0.015 * rate))
	# The grass crunch keeps exactly its previous level (peak 0.40); the low thud follows 30 ms later, 2 dB under it,
	# so the step never gets quieter on small speakers and gains weight where there is bass.
	_normalize(step, PEAK)
	var thud := impact.slice(start, start + int(0.6 * rate))
	_normalize(thud, PEAK * IMPACT_GAIN)
	var delay := int(0.03 * rate)
	var out := PackedFloat32Array()
	out.resize(int(0.6 * rate))
	for i in out.size():
		var a := step[i] if i < step.size() else 0.0
		var b := thud[i - delay] if i >= delay and i - delay < thud.size() else 0.0
		out[i] = a + b
	_shape(out, 0.002, 0.2)
	var peak := 0.0
	for v in out:
		peak = maxf(peak, absf(v))
	if peak > PEAK:
		_normalize(out, PEAK)
	var path := "res://audio/sfx/real/%s.wav" % cue
	_save(path, out, PackedFloat32Array())
	_record(path, [[STEP_SOURCES[cue], 0.0, 1.0], [impact_path, 0.03, IMPACT_GAIN]], {"duration": out.size() / rate, "peak": PEAK,
			"edits": "Kenney grass step (from onset, pitch 0.7 baked, peak 0.40 as before) + Colossal Impact low hit (from 15 ms before its peak, peak 0.32, +30 ms), 0.60 s, 200 ms fade-out, mono PCM16, peak <= 0.40"})


func _long(path: String, source: String, from_s: float, seconds: float, fade_in: float, fade_out: float, peak: float) -> void:
	var mono := C.decode_mono(source, seconds, from_s)
	_shape(mono, fade_in, fade_out)
	_normalize(mono, peak)
	_save(path, mono, PackedFloat32Array())
	_record(path, [[source, from_s, 1.0]], {"duration": mono.size() / rate, "peak": peak, "edits": "decoded %.1f-%.1f s, %.1f s fade-in, %.1f s fade-out, mono PCM16, peak %.2f" % [from_s, from_s + seconds, fade_in, fade_out, peak]})


## Seamless loop: the steadiest window of `seconds`, equal-power crossfade of `crossfade` seconds, peak 0.30.
func _loop(path: String, source: String, seconds: float, crossfade: float) -> void:
	var mono := C.decode_mono(source, 52.0)
	var per_second: Array[float] = []
	for s in int(mono.size() / rate):
		var energy := 0.0
		for i in range(int(s * rate), int((s + 1) * rate), 8):
			energy += mono[i] * mono[i]
		per_second.append(sqrt(energy / (rate / 8.0)))
	var best := 0
	var best_score := INF
	for start in range(0, per_second.size() - int(seconds) - int(crossfade) - 1):
		var mean := 0.0
		var peak := 0.0
		for k in int(seconds):
			mean += per_second[start + k]
			peak = maxf(peak, per_second[start + k])
		mean /= seconds
		var score := 0.0
		for k in int(seconds):
			score += pow(per_second[start + k] - mean, 2.0)
		score += pow(peak - mean, 2.0) * seconds * 0.5
		if score < best_score:
			best_score = score
			best = start
	var length := int(seconds * rate)
	var xfade := int(crossfade * rate)
	var base := int(best * rate)
	var out := PackedFloat32Array()
	out.resize(length)
	for i in length:
		out[i] = mono[base + i]
	for i in xfade:
		var t := float(i) / xfade
		out[i] = out[i] * sin(t * PI * 0.5) + mono[base + length + i] * cos(t * PI * 0.5)
	_normalize(out, 0.30)
	_save(path, out, PackedFloat32Array())
	_record(path, [[source, float(best), 1.0]], {"duration": seconds, "peak": 0.30, "edits": "decoded, steadiest %.0f s window from %d s, %.1f s equal-power loop crossfade, mono PCM16, peak 0.30" % [seconds, best, crossfade]})


func _onset(mono: PackedFloat32Array) -> int:
	var peak := 0.0
	for v in mono:
		peak = maxf(peak, absf(v))
	var i := 0
	while i < mono.size() and absf(mono[i]) < peak * 0.01:
		i += 1
	return maxi(0, i - int(0.003 * rate))


func _shape(samples: PackedFloat32Array, fade_in: float, fade_out: float) -> void:
	var a := maxi(1, int(fade_in * rate))
	var b := maxi(1, int(fade_out * rate))
	for i in mini(a, samples.size()):
		samples[i] *= sin(float(i) / a * PI * 0.5)
	for k in mini(b, samples.size()):
		samples[samples.size() - 1 - k] *= sin(float(k) / b * PI * 0.5)


func _normalize(samples: PackedFloat32Array, target: float) -> void:
	var peak := 0.0
	for v in samples:
		peak = maxf(peak, absf(v))
	if peak <= 0.0:
		return
	var scale := target / peak
	for i in samples.size():
		samples[i] *= scale


func _save(path: String, left: PackedFloat32Array, right: PackedFloat32Array) -> void:
	var stereo := right.size() > 0
	var bytes := PackedByteArray()
	bytes.resize(left.size() * (4 if stereo else 2))
	for i in left.size():
		bytes.encode_s16(i * (4 if stereo else 2), roundi(clampf(left[i], -1.0, 1.0) * 32767))
		if stereo:
			bytes.encode_s16(i * 4 + 2, roundi(clampf(right[i], -1.0, 1.0) * 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = stereo
	wav.mix_rate = int(rate)
	wav.data = bytes
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	if wav.save_to_wav(ProjectSettings.globalize_path(path)) != OK:
		push_error("Cannot save " + path)
		quit(1)


func _record(output: String, layers: Array, extra: Dictionary) -> void:
	var sources := []
	for layer in layers:
		var file := C.absolute(layer[0])
		sources.append({"source": file, "sha256": FileAccess.get_sha256(file)})
	var record := {"output": output, "sources": sources, "output_sha256": FileAccess.get_sha256(output)}
	record.merge(extra)
	print("INTEGRATED ", JSON.stringify(record))
