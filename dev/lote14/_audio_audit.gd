extends SceneTree
## Dev tool (LOTE 14 · ETAPA 4): lists the audio files of res://audio with format, duration and size.
func _initialize():
	var rows := []
	_scan("res://audio", rows)
	for r in rows:
		print("AUDIO %s | %s | %.1f s | %d bytes | loop=%s" % r)
	quit(0)
func _scan(dir_path: String, rows: Array) -> void:
	var dir := DirAccess.open(dir_path)
	for sub in dir.get_directories():
		_scan(dir_path + "/" + sub, rows)
	for file in dir.get_files():
		if file.ends_with(".import") or file.ends_with(".uid"):
			continue
		var path := dir_path + "/" + file
		var stream := load(path) as AudioStream
		var length := stream.get_length() if stream != null else -1.0
		var loop := "?"
		if stream is AudioStreamMP3:
			loop = str((stream as AudioStreamMP3).loop)
		elif stream is AudioStreamWAV:
			loop = str((stream as AudioStreamWAV).loop_mode)
		elif stream is AudioStreamOggVorbis:
			loop = str((stream as AudioStreamOggVorbis).loop)
		rows.append([path.trim_prefix("res://"), file.get_extension(), length, FileAccess.get_file_as_bytes(path).size(), loop])
