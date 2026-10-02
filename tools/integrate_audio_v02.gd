extends SceneTree

const INSPECT := preload("res://tools/inspect_audio_v02.gd")
# Only these selected, locally licensed CC0 files are promoted into the project.
# source, maximum seconds, pitch baked into the selected copy
const SELECTED := {
	"base": ["kenney_sci-fi-sounds/Audio/laserSmall_000.ogg", 0.20, 1.0],
	"spread": ["kenney_sci-fi-sounds/Audio/laserLarge_000.ogg", 0.34, 1.0],
	"tech_hit": ["kenney_sci-fi-sounds/Audio/impactMetal_000.ogg", 0.28, 1.0],
	"organic_hit": ["kenney_impact-sounds/Audio/impactSoft_medium_000.ogg", 0.15, 1.0],
	"melee": ["kenney_impact-sounds/Audio/impactPunch_medium_000.ogg", 0.30, 1.0],
	"bomb": ["kenney_sci-fi-sounds/Audio/forceField_000.ogg", 0.70, 1.0],
	"bee_damage": ["kenney_impact-sounds/Audio/impactPunch_medium_001.ogg", 0.29, 1.0],
	"bee_defeat": ["kenney_interface-sounds/Audio/minimize_001.ogg", 0.27, 1.0],
	"tech_death": ["kenney_sci-fi-sounds/Audio/explosionCrunch_000.ogg", 0.55, 1.0],
	"crate": ["kenney_impact-sounds/Audio/impactPlank_medium_000.ogg", 0.30, 1.0],
	"spread_pickup": ["kenney_interface-sounds/Audio/confirmation_001.ogg", 0.30, 1.0],
	"bomb_pickup": ["kenney_interface-sounds/Audio/maximize_001.ogg", 0.27, 1.0],
	"pollen": ["kenney_interface-sounds/Audio/pluck_002.ogg", 0.13, 1.0],
	"human_step": ["kenney_impact-sounds/Audio/footstep_grass_000.ogg", 0.30, 0.70],
}
const GROUPS := {
	"weapons": ["base", "spread", "tech_hit", "organic_hit", "melee", "bomb"],
	"state": ["bee_damage", "bee_defeat", "tech_death"],
	"world": ["crate", "spread_pickup", "bomb_pickup", "pollen", "human_step"],
}
const BOMB_LAYER := "kenney_sci-fi-sounds/Audio/lowFrequency_explosion_000.ogg"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or not GROUPS.has(args[0]):
		push_error("Use -- weapons|state|world")
		quit(1)
		return
	var manifest: Dictionary = {}
	var manifest_path := "res://dev/audio_asset_review/selected.json"
	if FileAccess.file_exists(manifest_path):
		manifest = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	var rate := AudioServer.get_mix_rate()
	for cue in GROUPS[args[0]]:
		var spec: Array = SELECTED[cue]
		var original := INSPECT.decode(spec[0])
		var length := mini(ceili(float(spec[1]) * rate), floori(original.size() / float(spec[2])))
		var mono := PackedFloat32Array()
		mono.resize(length)
		var peak := 0.0
		var layer := INSPECT.decode(BOMB_LAYER) if cue == "bomb" else PackedVector2Array()
		for i in length:
			var index := mini(floori(i * float(spec[2])), original.size() - 1)
			var value := (original[index].x + original[index].y) * 0.5
			if not layer.is_empty():
				var j := i - floori(0.025 * rate)
				value *= 0.60
				if j >= 0 and j < layer.size():
					value += (layer[j].x + layer[j].y) * 0.5 * 0.65
			mono[i] = value
			peak = maxf(peak, absf(value))
		if peak <= 0.0001:
			push_error("Empty selected cue " + cue)
			quit(1)
			return
		var bytes := PackedByteArray()
		bytes.resize(length * 2)
		var energy := 0.0
		for i in length:
			# Mono copy, uniform peak ceiling, 2 ms fade-in and 35 ms fade-out.
			var envelope := minf(float(i) / (rate * 0.002), 1.0) * minf(float(length - 1 - i) / (rate * 0.035), 1.0)
			var value := mono[i] * (0.40 / peak) * envelope
			energy += value * value
			bytes.encode_s16(i * 2, roundi(value * 32767))
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = rate
		wav.data = bytes
		var output := "res://audio/sfx/real/%s.wav" % cue
		if wav.save_to_wav(ProjectSettings.globalize_path(output)) != OK:
			push_error("Cannot save " + output)
			quit(1)
			return
		var record := {"source": spec[0], "source_sha256": FileAccess.get_sha256(INSPECT.LIBRARY + spec[0]), "output": output, "output_sha256": FileAccess.get_sha256(output), "duration": float(length) / rate, "rms": sqrt(energy / length), "peak_ceiling": 0.40, "pitch_baked": spec[2], "license": "CC0", "author": "Kenney", "attribution_required": false, "edits": "OGG decoded to mono PCM16 WAV; shortened; normalized to peak 0.40; 2ms/35ms fades"}
		if cue == "bomb":
			record["second_source"] = BOMB_LAYER
			record["second_sha256"] = FileAccess.get_sha256(INSPECT.LIBRARY + BOMB_LAYER)
			record["edits"] += "; two layers, low pulse delayed 25ms"
		manifest[cue] = record
		print("SELECTED ", cue, " ", JSON.stringify(record))
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	quit(0)
