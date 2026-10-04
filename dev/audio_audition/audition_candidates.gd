extends RefCounted
## DEV ONLY (GARDEN IDENTITY & AUDIO PASS 04). The audio candidates of docs/BEE_ASSET_LIBRARY_DEEP_AUDIT_02.md §9,
## grouped by the gameplay need they answer, next to what the game plays today. Shared by the listening scene
## (audio_audition.tscn) and the signal analyser (analyze_candidates.gd). Paths: library-relative (LIB) or res://.
## License tags: K = Kenney CC0, L = Lentikula CC0, FX = FX Laser (commercial, no redistribution),
## S = Sonniss GDC 2026 (royalty-free, no redistribution, no AI training), P = project file.

const LIB := "D:/proyectos/V_Asset_Library/01_Extracted/audio/"
const SON := "Sonniss.com-GDC2026-GameAudioBundle/"

## category -> [ [label, path, license], ... ]. The first row of each category is what the game uses today.
const CATEGORIES := {
	"enemy_death_tech": [
		["ACTUAL tech_death", "res://audio/sfx/real/tech_death.wav", "P"],
		["Epic Anime explosion enemy death", SON + "Epic Stock Media - Anime Game/EXPLDsgn_Explosion Small Blast Enemy Death Crunchy Boom Cartoon Noisy Crash Impact Delay 03_ESM_AG.wav", "S"],
		["Kenney explosionCrunch_000", "kenney_sci-fi-sounds/Audio/explosionCrunch_000.ogg", "K"],
		["Kenney explosionCrunch_003", "kenney_sci-fi-sounds/Audio/explosionCrunch_003.ogg", "K"],
		["Kenney explosionCrunch_004", "kenney_sci-fi-sounds/Audio/explosionCrunch_004.ogg", "K"],
	],
	"enemy_death_organic": [
		["ACTUAL organic_death (placeholder procedural)", "res://audio/sfx/enemies/organic_death.wav", "P"],
		["Kenney slime_000", "kenney_sci-fi-sounds/Audio/slime_000.ogg", "K"],
		["Tower Defense blood splat wood thump", SON + "Epic Stock Media - Tower Defense Game/WOODImpt_Hit Blood Spill Splat Wood Impact Light Hit Squelch Small Thump 03_ESM_TDG.wav", "S"],
		["Cartoon Bubbles Short", SON + "Cinematic Sound Design - Cartoon & Animation Vol 2/Cartoon Bubbles Short.wav", "S"],
		["Ethereal Entity Grim Pain", SON + "SoundBits - Vox Bestiae - Source Elements/CREAEthr_Ethereal Entity Grim Pain Long 4_SNDBTS_VB-SE.wav", "S"],
	],
	"wasp_warning": [
		["ACTUAL overload whine (ufo_charge x1.7)", "res://audio/sfx/real/ufo_charge.wav", "P"],
		["Insectoid Tremble Attack", SON + "SoundBits - Vox Bestiae - Source Elements/CREAInsc_Insectoid Creature Tremble Attack Long 1_SNDBTS_VB-SE.wav", "S"],
		["Interface Sci-Fi Ping Down", SON + "Cinematic Sound Design - System & UI Feedback Elements/Interface Sci-Fi Ping Down.wav", "S"],
		["Arc design 15", SON + "InMotionAudio - Arc/ELECArc_ArcDesign15_InMotionAudio_Arc.wav", "S"],
	],
	"insect_buzz": [
		["ACTUAL wing_buzz (Toy Quadcopter)", "res://audio/sfx/real/wing_buzz.wav", "P"],
		["Wahl trimmer on-idle-off", SON + "344 Audio - Barbershop Vol. 2/OBJMisc_Wahl Sterling Trimmer, On, Idle, Off_344 Audio_Barbershop Vol 2.wav", "S"],
		["Arc Buzz 27", SON + "InMotionAudio - Arc/ELECBuzz_Buzz27_InMotionAudio_Arc.wav", "S"],
		["Hair dryer on-idle-off", SON + "344 Audio - Barbershop Vol. 1/OBJMisc_Hair Dryer, On, Idle, Off 4_344 Audio_Barbershop Vol 1.wav", "S"],
	],
	"organic_identity": [
		["ACTUAL organic_hit", "res://audio/sfx/real/organic_hit.wav", "P"],
		["Monster tentacle wobble", SON + "Epic Stock Media - Anime Game/DSGNMisc_Misc Monster Tentacle Modulated Creature Shadow Abstract Swept Wobble Lfo 02_ESM_AG.wav", "S"],
		["Kenney slime_001", "kenney_sci-fi-sounds/Audio/slime_001.ogg", "K"],
		["Aquatic creature gurgling", SON + "SoundBits - Vox Bestiae - Source Elements/CREAAqua_Aquatic Creature Gurgling 2_SNDBTS_VB-SE.wav", "S"],
	],
	"walker_mechanical": [
		["ACTUAL (none: generic tech cues)", "res://audio/sfx/real/tech_hit.wav", "P"],
		["Tower Deploy robot servo whine", SON + "Epic Stock Media - Tower Defense Game/ROBTMvmt_Tower Deploy Hitech Robot Motor Dark Thump Servo Whine 04_ESM_TDG.wav", "S"],
		["Moaning Metal hit thud", SON + "The Noisery - Moaning Metal/DSGNImpt_Metal Hit Thud Thump Low Ring Geofon 1_The Noisery_Moaning Metal.wav", "S"],
		["Lentikula Laser Rifle 1", "Sci-Fi Weapon SFX by Lentikula/Laser Rifle 1.wav", "L"],
		["Electric tonal impact glitch", SON + "Epic Stock Media - Elemental Mutation Whooshes and Impacts/ELECMisc_Impact Electric Tonal Deep Movement Motion Hiss Glitch 01_ESM_EMWI.wav", "S"],
	],
	"enemy_shot": [
		["ACTUAL (enemy shots are silent; Bee base)", "res://audio/sfx/real/base.wav", "P"],
		["Lentikula Laser Pistol 1", "Sci-Fi Weapon SFX by Lentikula/Laser Pistol 1.wav", "L"],
		["Lentikula Laser Pistol 3", "Sci-Fi Weapon SFX by Lentikula/Laser Pistol 3.wav", "L"],
		["Kenney laserLarge_000", "kenney_sci-fi-sounds/Audio/laserLarge_000.ogg", "K"],
	],
	"player_fire_hit": [
		["ACTUAL base", "res://audio/sfx/real/base.wav", "P"],
		["FX Laser_Shot_01", "(free)FX_Laser_Sound_Pack/(free)FX_Laser_Sound_Pack/Laser_Shot_01.wav", "FX"],
		["Kenney laserRetro_002", "kenney_sci-fi-sounds/Audio/laserRetro_002.ogg", "K"],
		["ACTUAL bee_damage", "res://audio/sfx/real/bee_damage.wav", "P"],
		["Kenney impactPunch_heavy_001", "kenney_impact-sounds/Audio/impactPunch_heavy_001.ogg", "K"],
	],
	"ufo_entry": [
		["ACTUAL ufo_sting", "res://audio/sfx/real/ufo_sting.wav", "P"],
		["344 AEROJet Unidentified Encounter", SON + "344 Audio - Air Designed/AEROJet_Unidentified Encounter_344 Audio_Air Designed.wav", "S"],
		["Horn Braam 67", SON + "Jake Fielding - Cinematic Horn Braams/DSGNBram____Cinematic Horn Braam, Epic, Cinematic, Dark, Instrument, Huge-67.wav", "S"],
		["Ship reactor synth loop", SON + "Epic Stock Media - Strange Game Ambient Loops 3/DSGNSynth_Scifi Loop Ship Reactor Synth Layer Layered Saw Buzz_ESM_SGA3.wav", "S"],
	],
	"boss_laser": [
		["ACTUAL ufo_charge", "res://audio/sfx/real/ufo_charge.wav", "P"],
		["Lentikula Laser Beam 1", "Sci-Fi Weapon SFX by Lentikula/Laser Beam 1.wav", "L"],
		["Lentikula Laser Beam 2", "Sci-Fi Weapon SFX by Lentikula/Laser Beam 2.wav", "L"],
	],
	"human_step": [
		["ACTUAL human_step", "res://audio/sfx/real/human_step.wav", "P"],
		["Flip Flops FFG002", SON + "TheWorkRoom - Flip Flops/FFG002.wav", "S"],
		["Flip Flops FFW003", SON + "TheWorkRoom - Flip Flops/FFW003.wav", "S"],
		["Colossal Impact Cut Sweep", SON + "Cinematic Sound Design - Colossal Impacts/Impact Cut Sweep.wav", "S"],
		["Kenney impactSoft_heavy_002", "kenney_impact-sounds/Audio/impactSoft_heavy_002.ogg", "K"],
	],
	"ambient_insects": [
		["ACTUAL garden_loop (Highlands meadow)", "res://audio/ambience/garden_loop.wav", "P"],
		["Forest crickets birds Connecticut", SON + "344 Audio - East Coast America Vol. 1/AMBSubn_Ambience, Forest Crickets, Birds, Connecticut 02_344 Audio_East Coast America.wav", "S"],
		["Jungle night humid birds bugs", SON + "Epic Stock Media - Synthesized Nature Loops and Sounds/AMBTrop_Loop Ambience Jungle Night Humid Birds Bug Chirps 01_ESM_SNLS.wav", "S"],
	],
	"garden_wind": [
		["Wind whipping loop", SON + "Epic Stock Media - Synthesized Nature Loops and Sounds/WINDInt_Loop Weather Wind Whipping Constricted Flow Turbulent 01_ESM_SNLS.wav", "S"],
		["Wind rush whoosh x5", SON + "344 Audio - Elemental Palette Designed Vol. 1/WINDDsgn_Wind, Rush, Whoosh, Long x5 01_344 Audio_Elemental Palette Designed Vol 1.wav", "S"],
		["Berlin park strong wind on trees", SON + "Epic Stock Media - Public Spaces - Storms Lakes Parks and Rural Nature Exteriors/AMBPark_Berlin City Humboldthain Park Strong Wind On Trees Foliage Traffic Wash 03_ESM_CPS.wav", "S"],
	],
	"integrated_v04": [
		["tech_death v04", "res://audio/sfx/real/tech_death.wav", "S"],
		["organic_death v04", "res://audio/sfx/real/organic_death.wav", "S"],
		["wasp_overload v04", "res://audio/sfx/real/wasp_overload.wav", "S"],
		["organic_charge v04", "res://audio/sfx/real/organic_charge.wav", "S"],
		["walker_charge v04", "res://audio/sfx/real/walker_charge.wav", "S"],
		["human_step v04", "res://audio/sfx/real/human_step.wav", "S"],
		["spider_telegraph v04", "res://audio/sfx/real/spider_telegraph.wav", "S"],
		["spider_drop v04", "res://audio/sfx/real/spider_drop.wav", "S"],
		["spider_retract v04", "res://audio/sfx/real/spider_retract.wav", "S"],
		["ufo_approach v04", "res://audio/sfx/real/ufo_approach.wav", "S"],
		["dusk_loop v04", "res://audio/ambience/dusk_loop.wav", "S"],
	],
	"spider": [
		["Insectoid Tremble Attack (drop)", SON + "SoundBits - Vox Bestiae - Source Elements/CREAInsc_Insectoid Creature Tremble Attack Long 1_SNDBTS_VB-SE.wav", "S"],
		["Whip snap crack", SON + "David Dumais Audio - Melee Weapons Sound Effects Pack 2/WEAPWhip_WHIP Snap Crack 05_DDUMAIS_MWP2.wav", "S"],
		["Woosh sweep slide basic", SON + "Cinematic Sound Design - Ultra Transitions & Impacts/Woosh Sweep Slide Infographics Basic.wav", "S"],
		["Tape measure pull retract", SON + "Epic Stock Media - HD Lock And Mechanism Sound Design Kit/MECHMisc_Tool Tape Measure Pull Retract Spring Slide Spin Long 07_ESM_HDLM.wav", "S"],
	],
}


static func absolute(path: String) -> String:
	return ProjectSettings.globalize_path(path) if path.begins_with("res://") else LIB + path


static func load_stream(path: String) -> AudioStream:
	var file := absolute(path)
	if file.to_lower().ends_with(".ogg"):
		return AudioStreamOggVorbis.load_from_file(file)
	if is_extensible_wav(file):
		return wav_from_raw(file) # Godot's loader rejects WAVE_FORMAT_EXTENSIBLE (0xFFFE) files.
	return AudioStreamWAV.load_from_file(file)


static func is_extensible_wav(file: String) -> bool:
	var raw := read_wav_header(file)
	return int(raw.get("format", 1)) == 0xFFFE


## RIFF header walk: format tag, channels, rate, bits, data offset/size (no sample decoding).
static func read_wav_header(file: String) -> Dictionary:
	var f := FileAccess.open(file, FileAccess.READ)
	if f == null or f.get_buffer(4).get_string_from_ascii() != "RIFF":
		return {}
	f.get_32()
	if f.get_buffer(4).get_string_from_ascii() != "WAVE":
		return {}
	var info := {}
	while f.get_position() + 8 <= f.get_length():
		var id := f.get_buffer(4).get_string_from_ascii()
		var size := f.get_32()
		var next := f.get_position() + size + (size & 1)
		if id == "fmt ":
			info["format"] = f.get_16()
			info["channels"] = f.get_16()
			info["rate"] = f.get_32()
			f.get_32()
			f.get_16()
			info["bits"] = f.get_16()
			if int(info["format"]) == 0xFFFE and size >= 40:
				f.get_16()
				f.get_16()
				f.get_32()
				info["sub_format"] = f.get_16() # 1 = PCM, 3 = IEEE float
		elif id == "data":
			info["data_offset"] = f.get_position()
			info["data_size"] = mini(size, f.get_length() - f.get_position())
			break
		f.seek(next)
	return info


## Mono float samples of any PCM 16/24/32 or float32 WAV (incl. extensible), resampled to `out_rate`.
static func decode_raw_wav(file: String, out_rate: float, max_seconds: float, start_seconds := 0.0) -> PackedFloat32Array:
	var info := read_wav_header(file)
	var mono := PackedFloat32Array()
	if not info.has("data_offset"):
		return mono
	var channels: int = info["channels"]
	var bits: int = info["bits"]
	var is_float: bool = int(info.get("sub_format", info["format"])) == 3
	var frame_bytes := channels * bits / 8
	var rate: float = info["rate"]
	var first := int(start_seconds * rate)
	var count := mini(int(info["data_size"]) / frame_bytes - first, int(max_seconds * rate))
	if count <= 0:
		return mono
	var f := FileAccess.open(file, FileAccess.READ)
	f.seek(int(info["data_offset"]) + first * frame_bytes)
	var bytes := f.get_buffer(count * frame_bytes)
	var source := PackedFloat32Array()
	source.resize(count)
	for i in count:
		var sum := 0.0
		for c in channels:
			var at := i * frame_bytes + c * bits / 8
			var v := 0.0
			match bits:
				16:
					v = bytes.decode_s16(at) / 32768.0
				24:
					var raw := bytes[at] | (bytes[at + 1] << 8) | (bytes[at + 2] << 16)
					if raw & 0x800000:
						raw -= 0x1000000
					v = raw / 8388608.0
				32:
					v = bytes.decode_float(at) if is_float else bytes.decode_s32(at) / 2147483648.0
			sum += v
		source[i] = sum / channels
	var out_count := int(count * out_rate / rate)
	mono.resize(out_count)
	for i in out_count:
		var x := i * rate / out_rate
		var j := int(x)
		var t := x - j
		mono[i] = lerpf(source[mini(j, count - 1)], source[mini(j + 1, count - 1)], t)
	return mono


## Playable mono PCM16 stream built from a raw decode (used for files Godot cannot load directly).
static func wav_from_raw(file: String, max_seconds := 60.0) -> AudioStreamWAV:
	var rate := 44100.0
	var mono := decode_raw_wav(file, rate, max_seconds)
	if mono.is_empty():
		return null
	var bytes := PackedByteArray()
	bytes.resize(mono.size() * 2)
	for i in mono.size():
		bytes.encode_s16(i * 2, roundi(clampf(mono[i], -1.0, 1.0) * 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(rate)
	wav.data = bytes
	return wav


## Decoded mono samples at the mix rate (up to `max_seconds`, from `start_seconds`).
static func decode_mono(path: String, max_seconds := 12.0, start_seconds := 0.0) -> PackedFloat32Array:
	var file := absolute(path)
	var rate := AudioServer.get_mix_rate()
	if not file.to_lower().ends_with(".ogg") and is_extensible_wav(file):
		return decode_raw_wav(file, rate, max_seconds, start_seconds)
	var stream := load_stream(path)
	var mono := PackedFloat32Array()
	if stream == null:
		return mono
	var playback := stream.instantiate_playback()
	playback.start(start_seconds)
	var frames := ceili(minf(stream.get_length() - start_seconds, max_seconds) * rate)
	var samples := playback.mix_audio(1.0, maxi(frames, 1))
	playback.stop()
	mono.resize(samples.size())
	for i in samples.size():
		mono[i] = (samples[i].x + samples[i].y) * 0.5
	return mono
