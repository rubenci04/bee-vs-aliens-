class_name BeeMusic
extends RefCounted
## LOTE 14 · ETAPA 4 — static entry point to the MusicManager autoload for the game code: every call is a no-op when the autoload is not there
## (scene tests started with `--script` before the project autoloads exist, tools, other projects), so no gameplay script depends on it.

const MANAGER := "MusicManager"
## Music timings (owned here so the manager and the game code share them).
const CROSSFADE_SECONDS := 1.5 ## Theme changes and boss fade-in after the entrance break.
const BOSS_BREAK_SECONDS := 1.5 ## Brief silence during each boss entrance.
const DEATH_FADE_SECONDS := 1.6 ## Bee defeated.
const VICTORY_FADE_IN_SECONDS := 0.6


static func manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(MANAGER)


static func play(track: StringName, fade: float = -1.0, restart := false) -> void:
	var node := manager()
	if node != null:
		node.call("play_track", track, fade, restart)


## Level 1 theme from its start: a restarted level begins it again from the top.
static func play_level_from_start() -> void:
	play(&"level", BeeGameSettings.LEVEL_MUSIC_FADE_IN_SECONDS, true)


static func boss() -> void:
	play(&"boss", BeeMusic.CROSSFADE_SECONDS)


static func tarantula() -> void:
	play(&"boss_tarantula", BeeGameSettings.BOSS_BREAK_FADE_IN_SECONDS)

static func prepare_boss_break() -> void:
	var node := manager()
	if node != null:
		node.call("prepare_boss_break")

static func clear_pre_boss_duck() -> void:
	var node := manager()
	if node != null:
		node.call("clear_pre_boss_duck")


static func victory() -> void:
	play(&"victory", BeeMusic.VICTORY_FADE_IN_SECONDS)


static func fade_out(seconds: float = BeeMusic.DEATH_FADE_SECONDS) -> void:
	var node := manager()
	if node != null:
		node.call("fade_out", seconds)


static func set_intro_duck(enabled: bool) -> void:
	BeeGameSettings.intro_duck_enabled = enabled


static func set_paused(value: bool) -> void:
	var node := manager()
	if node != null:
		node.call("set_paused", value)


static func duck_for_explosion() -> void:
	var node := manager()
	if node != null:
		node.call("duck_for_explosion")


## Pause-menu sliders (0..1): stored in BeeGameSettings (the session) and applied to the buses when the manager exists.
static func set_music_volume(value: float) -> void:
	BeeGameSettings.music_volume = clampf(value, 0.0, 1.0)
	BeeGameSettings.save_audio_settings()
	var node := manager()
	if node != null:
		node.call("apply_volumes")


static func set_sfx_volume(value: float) -> void:
	BeeGameSettings.sfx_volume = clampf(value, 0.0, 1.0)
	BeeGameSettings.save_audio_settings()
	var node := manager()
	if node != null:
		node.call("apply_volumes")
