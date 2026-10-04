extends SceneTree
## DEV ONLY (ASSET LIBRARY DEEP AUDIT 02). Reads format and duration of every WAV/OGG in the library
## audio folder. WAV: RIFF chunk headers only (the 7.6 GB of audio data is never decoded).
## OGG: Vorbis identification header + AudioStreamOggVorbis.get_length(). Nothing is imported.
##   godot --headless --path . --script res://dev/asset_audit_02/probe_audio.gd
## Writes dev/asset_audit_02/data/audio_probe.tsv.

const ROOTS := ["D:/proyectos/V_Asset_Library/01_Extracted/audio", "D:/proyectos/bee_alien_3d/audio"]
const OUT := "res://dev/asset_audit_02/data/audio_probe.tsv"


func _initialize() -> void:
	call_deferred("run")


func collect(dir_path: String, into: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		collect(dir_path.path_join(sub), into)
	for file in dir.get_files():
		var ext := file.get_extension().to_lower()
		if ext == "wav" or ext == "ogg":
			into.append(dir_path.path_join(file))


func probe_wav(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"status": "OPEN_ERROR"}
	if f.get_buffer(4).get_string_from_ascii() != "RIFF":
		return {"status": "NOT_RIFF"}
	f.get_32()
	if f.get_buffer(4).get_string_from_ascii() != "WAVE":
		return {"status": "NOT_WAVE"}
	var r := {"status": "OK"}
	var byte_rate := 0
	var data_size := -1
	var chunks: Array[String] = []
	while f.get_position() + 8 <= f.get_length():
		var id := f.get_buffer(4).get_string_from_ascii()
		var size := f.get_32()
		var next := f.get_position() + size + (size & 1)
		chunks.append(id.strip_edges())
		if id == "fmt ":
			r["format"] = f.get_16()
			r["channels"] = f.get_16()
			r["rate"] = f.get_32()
			byte_rate = f.get_32()
			f.get_16()
			r["bits"] = f.get_16()
		elif id == "data":
			data_size = size
			break
		f.seek(next)
	r["chunks"] = ",".join(PackedStringArray(chunks))
	if byte_rate > 0 and data_size >= 0:
		r["duration"] = float(data_size) / float(byte_rate)
	else:
		r["status"] = "NO_DATA"
	return r


func probe_ogg(path: String) -> Dictionary:
	var r := {"status": "OK"}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null or f.get_buffer(4).get_string_from_ascii() != "OggS":
		return {"status": "NOT_OGG"}
	f.seek(26)
	var segments := f.get_8()
	f.seek(27 + segments)
	if f.get_8() == 1 and f.get_buffer(6).get_string_from_ascii() == "vorbis":
		f.get_32()
		r["channels"] = f.get_8()
		r["rate"] = f.get_32()
	f.close()
	var stream := AudioStreamOggVorbis.load_from_file(path)
	r["duration"] = stream.get_length() if stream != null else -1.0
	r["bits"] = 0
	return r


func run() -> void:
	var files: Array[String] = []
	for dir in ROOTS:
		collect(dir, files)
	var out := FileAccess.open(OUT, FileAccess.WRITE)
	out.store_line("path\text\tbytes\tstatus\tchannels\trate\tbits\tduration_s\twav_chunks")
	for path in files:
		var ext := path.get_extension().to_lower()
		var r := probe_wav(path) if ext == "wav" else probe_ogg(path)
		var bytes := FileAccess.open(path, FileAccess.READ).get_length()
		out.store_line("\t".join(PackedStringArray([path, ext, str(bytes), r["status"], str(r.get("channels", 0)), str(r.get("rate", 0)),
				str(r.get("bits", 0)), "%.3f" % float(r.get("duration", -1.0)), str(r.get("chunks", ""))])))
	out.close()
	print("AUDIO PROBE DONE ", files.size())
	quit(0)
