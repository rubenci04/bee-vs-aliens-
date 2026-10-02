extends SceneTree

# Original procedural placeholders. No external recordings or samples.
const RATE := 22050
const SOUNDS := [
	["weapons/base", 0.085, 1100.0, 650.0, 0.04],
	["weapons/spread", 0.105, 920.0, 520.0, 0.08],
	["weapons/melee", 0.14, 360.0, 100.0, 0.55],
	["weapons/bomb", 0.58, 140.0, 42.0, 0.55],
	["player/damage", 0.19, 380.0, 150.0, 0.25],
	["player/defeat", 0.42, 440.0, 65.0, 0.10],
	["enemies/tech_hit", 0.12, 2200.0, 700.0, 0.35],
	["enemies/organic_hit", 0.11, 180.0, 90.0, 0.65],
	["enemies/tech_death", 0.28, 620.0, 120.0, 0.60],
	["enemies/organic_death", 0.21, 180.0, 70.0, 0.50],
	["environment/crate", 0.25, 120.0, 60.0, 0.90],
	["environment/human_warning", 0.48, 160.0, 135.0, 0.20],
	["environment/human_step", 0.26, 95.0, 38.0, 0.30],
	["pickups/spread", 0.19, 600.0, 1000.0, 0.0],
	["pickups/bomb", 0.26, 440.0, 1200.0, 0.0],
	["pickups/pollen", 0.10, 1100.0, 1500.0, 0.0],
]

func _initialize() -> void:
	for index in SOUNDS.size():
		var spec: Array = SOUNDS[index]
		var seconds := float(spec[1])
		var count := roundi(seconds * RATE)
		var data := PackedByteArray()
		data.resize(count * 2)
		var rng := RandomNumberGenerator.new()
		rng.seed = 4100 + index
		var phase := 0.0
		var filtered_noise := 0.0
		for frame in count:
			var time := float(frame) / RATE
			var progress := time / seconds
			var frequency := lerpf(float(spec[2]), float(spec[3]), progress)
			phase += TAU * frequency / RATE
			filtered_noise = lerpf(filtered_noise, rng.randf_range(-1, 1), 0.3)
			var tone := sin(phase) * 0.75 + sin(phase * 2.01) * 0.15
			var envelope := minf(time / 0.004, 1.0) * pow(1.0 - progress, 1.5)
			if spec[0] == "weapons/bomb":
				tone += sin(TAU * 900 * time) * maxf(0, 1 - time / 0.055) * 0.8
			if spec[0] == "environment/human_warning":
				envelope *= 0.35 + 0.65 * pow(sin(time * TAU * 3.0), 2)
			if spec[0] == "environment/crate":
				envelope *= 0.6 + 0.4 * absf(sin(time * TAU * 18.0))
			var mix := lerpf(tone, filtered_noise, float(spec[4]))
			var sample := clampf(mix * envelope * 0.4, -0.4, 0.4)
			data.encode_s16(frame * 2, roundi(sample * 32767))
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = RATE
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		stream.data = data
		var path := "res://audio/sfx/%s.wav" % spec[0]
		if stream.save_to_wav(ProjectSettings.globalize_path(path)) != OK:
			push_error("Cannot save " + path)
			quit(1)
			return
		print("GENERATED ", path, " seconds=", seconds)
	print("GENERATED_SFX=", SOUNDS.size())
	quit(0)
