extends SceneTree

const EXPECTED := {
	&"title": "res://audio/musica titulos.mp3",
	&"story": "res://audio/musica storyboard.mp3",
	&"level": "res://audio/musica gameplay accion!.mp3",
	&"boss": "res://audio/entra minijefe.mp3",
	&"boss_tarantula": "res://audio/entra jefe tarantula.mp3",
	&"victory": "res://audio/victoria! jefe vencido y nivel pasado.mp3",
	&"zone": "res://audio/Nivel 1 El Jardín Acción Fuerte 1era opcion.mp3", # Tanda T: zonas de combate.
}


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)


func run() -> void:
	var manager := root.get_node_or_null("MusicManager")
	check(manager != null, "MusicManager is available")
	var tracks: Dictionary = manager.TRACKS
	check(tracks.size() == EXPECTED.size(), "Exactly the mapped tracks (Tanda T: seven, with zone)")
	for id in EXPECTED:
		check(tracks.has(id), "Missing track %s" % id)
		var path: String = tracks[id]["path"]
		check(path == EXPECTED[id], "Wrong path for %s: %s" % [id, path])
		check(FileAccess.file_exists(path), "Missing MP3 %s" % path)
		var should_loop: bool = id != &"victory"
		check(bool(tracks[id]["loop"]) == should_loop, "Wrong loop setting for %s" % id)
		var imported := FileAccess.get_file_as_string(path + ".import")
		check(imported.contains("loop=" + str(should_loop)), "Wrong .import loop for %s" % id)
		var stream := manager.call("_stream_for", id) as AudioStreamMP3
		check(stream != null and stream.loop == should_loop, "Cannot load %s with expected loop" % id)
	check(BeeGameSettings.MUSIC_TRACK_GAIN_DB.size() == EXPECTED.size(), "All tracks have saved-volume gain")
	print("BEE_TANDA_H_MUSIC_MAPPING_OK title story level robot tarantula victory loops=5")
	quit(0)
