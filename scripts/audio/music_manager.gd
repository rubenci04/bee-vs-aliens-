extends Node
## LOTE 14 · ETAPA 4 — MusicManager (autoload `MusicManager`). One music bus ("Music", -8 dB by default so the sound effects stay audible),
## two players for crossfades, and the rules of the game:
##   title    loops on the title screen
##   story    loops through the illustrated introduction
##   level    loops during Level 1 action
##   boss     starts when the robot mini-boss enters
##   boss_tarantula fades in after a short break during the final boss entrance
##   victory  plays ONCE with the results after the tarantula leaves
##   pause    the music ducks (PAUSE_DUCK_DB) while the game is paused
##   death    fades out (DEATH_FADE_SECONDS) when Bee is defeated; a restart starts the right theme again
##   explosions  a big explosion (the bomb) ducks the music for a moment (EXPLOSION_DUCK_DB)
## The game code talks to it through BeeMusic (static, safe when the autoload is missing, e.g. in scene tests run without it).
## Volumes: `set_music_volume` / `set_sfx_volume` (0..1, the pause menu sliders) around the default dB of each bus.

const TRACKS := {
	&"title": {"path": "res://audio/musica titulos.mp3", "loop": true},
	&"story": {"path": "res://audio/musica storyboard.mp3", "loop": true},
	&"level": {"path": "res://audio/musica gameplay accion!.mp3", "loop": true},
	&"zone": {"path": "res://audio/Nivel 1 El Jardín Acción Fuerte 1era opcion.mp3", "loop": true}, # Tanda T: zonas de combate.
	&"boss": {"path": "res://audio/entra minijefe.mp3", "loop": true},
	&"boss_tarantula": {"path": "res://audio/entra jefe tarantula.mp3", "loop": true},
	&"victory": {"path": "res://audio/victoria! jefe vencido y nivel pasado.mp3", "loop": false},
}
## -45 dBFS, decoded with Godot 4.7.2 AudioStreamPlayback.mix_audio (seconds).
## The four legacy tracks remain mapped here for audit, although the game uses the six tracks above.
const SILENCE_TRIMS := {
	"res://audio/Introducción al Jefe Final 1era opcion.mp3": {"start_trim": 0.063, "end_trim": 2.537},
	"res://audio/Jefe Derrotado y Pantalla de Victoria.mp3": {"start_trim": 0.077, "end_trim": 2.276},
	"res://audio/Menú Principal y Pantalla de Títulos.mp3": {"start_trim": 0.138, "end_trim": 2.512},
	"res://audio/Nivel 1 El Jardín Acción Fuerte 1era opcion.mp3": {"start_trim": 0.780, "end_trim": 2.640},
	"res://audio/entra jefe tarantula.mp3": {"start_trim": 0.082, "end_trim": 2.748},
	"res://audio/entra minijefe.mp3": {"start_trim": 0.075, "end_trim": 2.590},
	"res://audio/musica gameplay accion!.mp3": {"start_trim": 0.086, "end_trim": 2.731},
	"res://audio/musica storyboard.mp3": {"start_trim": 0.041, "end_trim": 1.853},
	"res://audio/musica titulos.mp3": {"start_trim": 0.041, "end_trim": 2.610},
	"res://audio/victoria! jefe vencido y nivel pasado.mp3": {"start_trim": 0.133, "end_trim": 2.216},
}
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const MUSIC_DEFAULT_DB := -8.0 ## Default volume of the music bus (default_bus_layout.tres says the same).
const SFX_DEFAULT_DB := -3.0
const SILENT_DB := -80.0
const FADE_IN_SECONDS := BeeGameSettings.MUSIC_FADE_IN_SEC
const CROSSFADE_SECONDS := BeeMusic.CROSSFADE_SECONDS ## Level -> boss.
const LOOP_CROSSFADE_SECONDS := 1.5
const BOSS_BREAK_SECONDS := BeeMusic.BOSS_BREAK_SECONDS
const DEATH_FADE_SECONDS := BeeMusic.DEATH_FADE_SECONDS
const VICTORY_FADE_IN_SECONDS := BeeMusic.VICTORY_FADE_IN_SECONDS
const VICTORY_TAIL_FADE := 3.0 ## The victory theme fades out over its last seconds.
const PAUSE_DUCK_DB := -12.0
const PAUSE_DUCK_SPEED := 40.0 ## dB per second the pause duck moves at.
const EXPLOSION_DUCK_DB := BeeGameSettings.MUSIC_DUCK_DB
const EXPLOSION_ATTACK_SECONDS := 0.05
const EXPLOSION_HOLD_SECONDS := BeeGameSettings.MUSIC_DUCK_SEC
const EXPLOSION_RELEASE_SECONDS := 0.8

var current_track: StringName = &"" ## The theme that is audible now (the incoming one during a crossfade); &"" = silence.
var paused_duck := false
var _players: Array[AudioStreamPlayer] = []
var _tracks: Array[StringName] = [&"", &""]
var _fade_gain: Array[float] = [0.0, 0.0] ## Fade level of each player (linear gain 0..1; fades are equal-power so a crossfade keeps its loudness).
var _active := 0
var _tweens: Array[Tween] = [null, null]
var _duck_db := 0.0 ## Current extra attenuation (pause + explosion).
var _explosion_db := 0.0
var _explosion_tween: Tween
var _streams: Dictionary = {}
var starts := 0 ## Themes started (tests).
var crossfades := 0
var loop_crossfades := 0
var boss_breaks := 0


func _ready() -> void:
	BeeGameSettings.load_audio_settings()
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.name = "MusicPlayer%d" % i
		player.bus = MUSIC_BUS
		player.volume_db = SILENT_DB
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_players.append(player)
	apply_volumes()


func _process(delta: float) -> void:
	var target := PAUSE_DUCK_DB if paused_duck else 0.0
	_duck_db = move_toward(_duck_db, target, PAUSE_DUCK_SPEED * delta)
	for i in 2:
		var player := _players[i]
		if not player.playing:
			continue
		var gain := _fade_gain[i]
		if _tracks[i] == &"victory": # No loop: the last seconds fade out.
			var left := player.stream.get_length() - player.get_playback_position()
			if left < VICTORY_TAIL_FADE:
				gain = minf(gain, clampf(left / VICTORY_TAIL_FADE, 0.0, 1.0))
		var intro_duck := BeeGameSettings.INTRO_MUSIC_DUCK_DB if BeeGameSettings.intro_duck_enabled else 0.0
		player.volume_db = maxf(linear_to_db(maxf(gain, 0.0001)) + float(BeeGameSettings.MUSIC_TRACK_GAIN_DB.get(_tracks[i], 0.0)) + _duck_db + _explosion_db + intro_duck, SILENT_DB)
	if not paused_duck and current_track != &"" and bool(TRACKS[current_track]["loop"]):
		var active_player := _players[_active]
		if active_player.playing and active_player.get_playback_position() >= loop_start_at(current_track, active_player.stream.get_length()):
			_loop_current_track()

func loop_start_at(track: StringName, duration: float) -> float:
	var trim: Dictionary = SILENCE_TRIMS[str(TRACKS[track]["path"])]
	return duration - float(trim["end_trim"]) - LOOP_CROSSFADE_SECONDS

func _start_trim(track: StringName) -> float:
	return float(SILENCE_TRIMS[str(TRACKS[track]["path"])]["start_trim"])

func _loop_current_track() -> void:
	var track := current_track
	var outgoing := _active
	var incoming := 1 - outgoing
	_stop_player(incoming)
	var player := _players[incoming]
	player.stream = _stream_for(track)
	_tracks[incoming] = track
	_fade_gain[incoming] = 0.0
	player.volume_db = SILENT_DB
	player.play(_start_trim(track))
	_fade_to(outgoing, 0.0, LOOP_CROSSFADE_SECONDS, true)
	_fade_to(incoming, 1.0, LOOP_CROSSFADE_SECONDS, false)
	_active = incoming
	starts += 1
	crossfades += 1
	loop_crossfades += 1

## A deliberate break before a boss: called 1.5 s before its theme begins.
func prepare_boss_break() -> void:
	if current_track == &"" or current_track == &"victory":
		return
	clear_pre_boss_duck()
	for i in 2:
		if _players[i].playing:
			_fade_to(i, 0.0, 0.08, true, true)
	current_track = &""
	boss_breaks += 1

func clear_pre_boss_duck() -> void:
	_explosion_db = BeeGameSettings.BOSS_PRE_BREAK_DUCK_DB
	if _explosion_tween != null and _explosion_tween.is_valid():
		_explosion_tween.kill()


## Starts (or switches to) a theme. From silence it fades in over `fade_in` seconds; with another theme playing it crossfades over `crossfade`.
## `restart` replays the same theme from the beginning (a restarted level).
func play_track(track: StringName, fade: float = -1.0, restart := false) -> void:
	if not TRACKS.has(track):
		push_error("Unknown music track: " + str(track))
		return
	if current_track == track and _players[_active].playing and not restart:
		return
	var seconds := fade if fade >= 0.0 else (FADE_IN_SECONDS if track in [&"title", &"level"] else CROSSFADE_SECONDS)
	var incoming := 1 - _active
	var outgoing := _active
	_stop_player(incoming)
	var crossfading := _players[outgoing].playing and _fade_gain[outgoing] > 0.001 and current_track != &""
	if crossfading:
		crossfades += 1
		_fade_to(outgoing, 0.0, seconds, true)
	else:
		_stop_player(outgoing)
	var player := _players[incoming]
	player.stream = _stream_for(track)
	_tracks[incoming] = track
	_fade_gain[incoming] = 0.0
	player.volume_db = SILENT_DB
	player.play(_start_trim(track))
	_fade_to(incoming, 1.0, maxf(seconds, 0.01), false)
	_active = incoming
	current_track = track
	starts += 1


## Fades the whole music out (Bee defeated) and leaves silence.
func fade_out(seconds: float = DEATH_FADE_SECONDS) -> void:
	for i in 2:
		if _players[i].playing:
			_fade_to(i, 0.0, seconds, true, true)
	current_track = &""


func stop_all() -> void:
	for i in 2:
		_stop_player(i)
	current_track = &""


func is_playing() -> bool:
	return _players[0].playing or _players[1].playing


func track_player(track: StringName) -> AudioStreamPlayer:
	for i in 2:
		if _tracks[i] == track and _players[i].playing:
			return _players[i]
	return null


## Real volume (dB, fades and ducks included) of the player that holds `track`; SILENT_DB when it is not playing.
func track_volume_db(track: StringName) -> float:
	var player := track_player(track)
	return player.volume_db if player != null else SILENT_DB


func set_paused(value: bool) -> void:
	paused_duck = value
	for player in _players:
		player.stream_paused = value
	for tween in _tweens:
		if tween != null and tween.is_valid():
			if value: tween.pause()
			else: tween.play()


## A big explosion: the music dips by EXPLOSION_DUCK_DB for a moment and comes back.
func duck_for_explosion() -> void:
	if _explosion_tween != null and _explosion_tween.is_valid():
		_explosion_tween.kill()
	_explosion_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_explosion_tween.tween_property(self, "_explosion_db", EXPLOSION_DUCK_DB, EXPLOSION_ATTACK_SECONDS)
	_explosion_tween.tween_interval(EXPLOSION_HOLD_SECONDS)
	_explosion_tween.tween_property(self, "_explosion_db", 0.0, EXPLOSION_RELEASE_SECONDS)


## Pause-menu sliders (0..1). 1.0 keeps the default level of each bus (music -8 dB, effects -3 dB); 0.0 mutes it.
func set_music_volume(value: float) -> void:
	BeeGameSettings.music_volume = clampf(value, 0.0, 1.0)
	BeeGameSettings.save_audio_settings()
	apply_volumes()


func set_sfx_volume(value: float) -> void:
	BeeGameSettings.sfx_volume = clampf(value, 0.0, 1.0)
	BeeGameSettings.save_audio_settings()
	apply_volumes()


func apply_volumes() -> void:
	_set_bus(MUSIC_BUS, MUSIC_DEFAULT_DB, BeeGameSettings.music_volume)
	_set_bus(SFX_BUS, SFX_DEFAULT_DB, BeeGameSettings.sfx_volume)


func _set_bus(bus_name: StringName, default_db: float, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, SILENT_DB if volume <= 0.001 else default_db + linear_to_db(volume))


func _fade_to(index: int, target: float, seconds: float, stop_at_end: bool, linear := false) -> void:
	if _tweens[index] != null and _tweens[index].is_valid():
		_tweens[index].kill()
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tweens[index] = tween
	if paused_duck:
		tween.pause()
	var start := _fade_gain[index]
	tween.tween_method(func(t: float):
		# Crossfades are equal power (fade in = sin, fade out = cos: they cross at -3 dB); a plain fade-out (death) is linear.
		_fade_gain[index] = start + (target - start) * (t if linear else (sin(t * PI * 0.5) if target > start else 1.0 - cos(t * PI * 0.5))), 0.0, 1.0, seconds)
	if stop_at_end:
		tween.tween_callback(_stop_player.bind(index))


func _stop_player(index: int) -> void:
	if _tweens[index] != null and _tweens[index].is_valid():
		_tweens[index].kill()
	_players[index].stop()
	_fade_gain[index] = 0.0
	_tracks[index] = &""


func _stream_for(track: StringName) -> AudioStream:
	if not _streams.has(track):
		var spec: Dictionary = TRACKS[track]
		var stream := load(str(spec["path"])) as AudioStream
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = bool(spec["loop"]) # Also set by the import (loop=true in the .mp3.import).
		_streams[track] = stream
	return _streams[track]
