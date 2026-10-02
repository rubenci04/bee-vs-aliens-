extends SceneTree

const LIBRARY := "D:/proyectos/V_Asset_Library/01_Extracted/audio/"
const CANDIDATES := {
	"base": ["Sci-Fi Weapon SFX by Lentikula/Laser Pistol 1.wav", "Sci-Fi Weapon SFX by Lentikula/Laser Pistol 2.wav", "kenney_sci-fi-sounds/Audio/laserSmall_000.ogg", "kenney_sci-fi-sounds/Audio/laserSmall_001.ogg"],
	"spread": ["Sci-Fi Weapon SFX by Lentikula/Laser Rifle 1.wav", "Sci-Fi Weapon SFX by Lentikula/Laser Rifle 2.wav", "kenney_sci-fi-sounds/Audio/laserLarge_000.ogg"],
	"tech_hit": ["kenney_sci-fi-sounds/Audio/impactMetal_000.ogg", "kenney_impact-sounds/Audio/impactTin_medium_000.ogg"],
	"organic_hit": ["kenney_impact-sounds/Audio/impactSoft_medium_000.ogg", "kenney_impact-sounds/Audio/impactSoft_medium_001.ogg"],
	"melee": ["kenney_impact-sounds/Audio/impactPunch_medium_000.ogg", "kenney_impact-sounds/Audio/impactPunch_heavy_000.ogg"],
	"bomb": ["kenney_sci-fi-sounds/Audio/forceField_000.ogg", "kenney_sci-fi-sounds/Audio/lowFrequency_explosion_000.ogg", "kenney_sci-fi-sounds/Audio/explosionCrunch_000.ogg"],
	"bee_damage": ["kenney_impact-sounds/Audio/impactPunch_medium_001.ogg", "kenney_impact-sounds/Audio/impactSoft_heavy_001.ogg"],
	"bee_defeat": ["kenney_interface-sounds/Audio/minimize_001.ogg", "kenney_interface-sounds/Audio/minimize_002.ogg"],
	"tech_death": ["kenney_sci-fi-sounds/Audio/explosionCrunch_001.ogg", "kenney_sci-fi-sounds/Audio/explosionCrunch_002.ogg"],
	"organic_death": ["kenney_sci-fi-sounds/Audio/slime_000.ogg", "kenney_sci-fi-sounds/Audio/slime_001.ogg"],
	"crate": ["kenney_impact-sounds/Audio/impactWood_heavy_000.ogg", "kenney_impact-sounds/Audio/impactPlank_medium_000.ogg"],
	"spread_pickup": ["kenney_interface-sounds/Audio/confirmation_001.ogg", "kenney_interface-sounds/Audio/confirmation_002.ogg"],
	"bomb_pickup": ["kenney_interface-sounds/Audio/maximize_001.ogg", "kenney_interface-sounds/Audio/maximize_002.ogg"],
	"pollen": ["kenney_interface-sounds/Audio/pluck_001.ogg", "kenney_interface-sounds/Audio/pluck_002.ogg"],
	"human_warning": ["kenney_sci-fi-sounds/Audio/lowFrequency_explosion_001.ogg", "kenney_sci-fi-sounds/Audio/forceField_001.ogg"],
	"human_step": ["kenney_impact-sounds/Audio/footstep_grass_000.ogg", "kenney_impact-sounds/Audio/footstep_concrete_000.ogg"],
}

static func decode(relative: String) -> PackedVector2Array:
	var stream: AudioStream
	var path := LIBRARY + relative
	if path.ends_with(".ogg"):
		stream = AudioStreamOggVorbis.load_from_file(path)
	else:
		stream = AudioStreamWAV.load_from_file(path)
	if stream == null:
		return PackedVector2Array()
	var playback := stream.instantiate_playback()
	playback.start()
	var samples := playback.mix_audio(1.0, ceili(stream.get_length() * AudioServer.get_mix_rate()))
	playback.stop()
	return samples

func _initialize() -> void:
	var rows: Array = []
	for cue in CANDIDATES:
		for path in CANDIDATES[cue]:
			var samples := decode(path)
			if samples.is_empty():
				push_error("Cannot decode " + path)
				quit(1)
				return
			var peak := 0.0
			var energy := 0.0
			var first := -1
			var last := 0
			for i in samples.size():
				var value := (samples[i].x + samples[i].y) * 0.5
				peak = maxf(peak, absf(value))
				energy += value * value
				if absf(value) > 0.005:
					if first < 0:
						first = i
					last = i
			var row := {"cue": cue, "source": path, "duration": float(samples.size()) / AudioServer.get_mix_rate(), "peak": peak, "rms": sqrt(energy / samples.size()), "onset": float(first) / AudioServer.get_mix_rate(), "tail": float(last) / AudioServer.get_mix_rate()}
			rows.append(row)
			print(JSON.stringify(row))
	var file := FileAccess.open("res://dev/audio_asset_review/candidates.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(rows, "\t"))
	quit(0)
