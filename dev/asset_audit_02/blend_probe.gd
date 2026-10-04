extends SceneTree
## DEV ONLY (ASSET LIBRARY DEEP AUDIT 02). Reads .blend files WITHOUT Blender: walks the file-block
## headers, counts ID blocks (OB objects, ME meshes, AR armatures, AC actions, IM images, MA materials),
## lists action names and extracts the embedded preview thumbnail (TEST block) as PNG.
## Handles uncompressed files and Blender's zstd "seekable" compression (one frame decoded at a time).
##   godot --headless --path . --script res://dev/asset_audit_02/blend_probe.gd
## Writes dev/asset_audit_02/data/blend_probe.tsv and dev/asset_audit_02/blend_thumbs/*.png.

const LIB := "D:/proyectos/V_Asset_Library/01_Extracted"
const OUT := "res://dev/asset_audit_02/data/blend_probe.tsv"
const THUMBS := "res://dev/asset_audit_02/blend_thumbs/"
const ZSTD_MAGIC := 0xFD2FB528
const SEEKABLE_MAGIC := 0x8F92EAB1
const ID_CODES := ["OB", "ME", "AR", "AC", "IM", "MA", "SC"]

# Random-access reader over the (possibly compressed) file.
var _file: FileAccess
var _compressed := false
var _frame_comp_offset := PackedInt64Array()
var _frame_comp_size := PackedInt64Array()
var _frame_raw_offset := PackedInt64Array()
var _frame_raw_size := PackedInt64Array()
var _cache_index := -1
var _cache := PackedByteArray()
var _raw_length := 0


func _initialize() -> void:
	call_deferred("run")


func open_blend(path: String) -> bool:
	_file = FileAccess.open(path, FileAccess.READ)
	_cache_index = -1
	_frame_comp_offset.clear(); _frame_comp_size.clear(); _frame_raw_offset.clear(); _frame_raw_size.clear()
	if _file == null:
		return false
	_file.big_endian = false
	_compressed = _file.get_32() == ZSTD_MAGIC
	if not _compressed:
		_raw_length = _file.get_length()
		return true
	_file.seek(_file.get_length() - 9)
	var frames := _file.get_32()
	var descriptor := _file.get_8()
	if _file.get_32() != SEEKABLE_MAGIC:
		return false # zstd without seek table: not supported here
	var entry := 12 if (descriptor & 0x80) else 8
	_file.seek(_file.get_length() - 9 - frames * entry)
	var comp := 0
	var raw := 0
	for i in frames:
		var c := _file.get_32()
		var d := _file.get_32()
		if entry == 12:
			_file.get_32()
		_frame_comp_offset.append(comp); _frame_comp_size.append(c)
		_frame_raw_offset.append(raw); _frame_raw_size.append(d)
		comp += c
		raw += d
	_raw_length = raw
	return true


func _frame_for(offset: int) -> int:
	var lo := 0
	var hi := _frame_raw_offset.size() - 1
	while lo < hi:
		var mid := (lo + hi + 1) / 2
		if _frame_raw_offset[mid] <= offset:
			lo = mid
		else:
			hi = mid - 1
	return lo


func read_bytes(offset: int, count: int) -> PackedByteArray:
	if not _compressed:
		_file.seek(offset)
		return _file.get_buffer(count)
	var result := PackedByteArray()
	while count > 0 and offset < _raw_length:
		var index := _frame_for(offset)
		if index != _cache_index:
			_file.seek(_frame_comp_offset[index])
			_cache = _file.get_buffer(_frame_comp_size[index]).decompress(_frame_raw_size[index], FileAccess.COMPRESSION_ZSTD)
			_cache_index = index
		var local := offset - _frame_raw_offset[index]
		var take := mini(count, _cache.size() - local)
		if take <= 0:
			break
		result.append_array(_cache.slice(local, local + take))
		offset += take
		count -= take
	return result


func id_name(data: PackedByteArray, code: String) -> String:
	var a := code.unicode_at(0)
	var b := code.unicode_at(1)
	for i in range(0, data.size() - 3):
		if data[i] == a and data[i + 1] == b and data[i + 2] >= 32 and data[i + 2] < 127:
			var end := i + 2
			while end < data.size() and data[end] != 0 and end - i < 64:
				end += 1
			if end < data.size() and data[end] == 0:
				return data.slice(i + 2, end).get_string_from_utf8()
	return ""


func probe(path: String) -> Dictionary:
	var r := {"status": "OK", "compressed": false, "version": "", "counts": {}, "actions": [], "thumb": ""}
	if not open_blend(path):
		r["status"] = "OPEN_OR_ZSTD_ERROR"
		return r
	r["compressed"] = _compressed
	var header := read_bytes(0, 17)
	if header.slice(0, 7).get_string_from_ascii() != "BLENDER":
		r["status"] = "NOT_BLEND"
		return r
	var offset := 12
	var pointer_size := 8 if header[7] == 45 else 4 # '-' = 64-bit pointers
	var large_bhead := false
	if header[7] == 49 and header[8] == 55: # "17": Blender 5.x header "BLENDER17-01v0500"
		large_bhead = true
		offset = 17
		r["version"] = header.slice(13, 17).get_string_from_ascii()
	else:
		r["version"] = header.slice(9, 12).get_string_from_ascii()
	var counts := {}
	for code in ID_CODES:
		counts[code] = 0
	var actions: Array[String] = []
	var blocks := 0
	while offset + 16 < _raw_length:
		var bhead: PackedByteArray
		var code: String
		var length: int
		var head_size: int
		if large_bhead:
			bhead = read_bytes(offset, 32)
			code = bhead.slice(0, 4).get_string_from_ascii()
			length = bhead.decode_s64(16)
			head_size = 32
		else:
			head_size = 16 + pointer_size
			bhead = read_bytes(offset, head_size)
			if bhead.size() < head_size:
				break
			code = bhead.slice(0, 4).get_string_from_ascii()
			length = bhead.decode_s32(4)
		blocks += 1
		if code == "ENDB" or length < 0:
			break
		var data_offset := offset + head_size
		if code == "TEST" and r["thumb"] == "":
			var dims := read_bytes(data_offset, 8)
			var w := dims.decode_s32(0)
			var h := dims.decode_s32(4)
			if w > 0 and h > 0 and w <= 1024 and h <= 1024 and w * h * 4 + 8 <= length:
				var pixels := read_bytes(data_offset + 8, w * h * 4)
				var image := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, pixels)
				image.flip_y()
				r["thumb"] = "%dx%d" % [w, h]
				r["image"] = image
		var short := code.substr(0, 2)
		if code.length() >= 2 and counts.has(short) and (code.length() == 2 or code.unicode_at(2) == 0):
			counts[short] += 1
			if short == "AC" and actions.size() < 60:
				var name := id_name(read_bytes(data_offset, mini(length, 512)), "AC")
				if name != "":
					actions.append(name)
		offset = data_offset + length
	r["counts"] = counts
	r["actions"] = actions
	r["blocks"] = blocks
	return r


func collect(dir_path: String, into: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		collect(dir_path.path_join(sub), into)
	for file in dir.get_files():
		var ext := file.get_extension().to_lower()
		if ext == "blend" or ext == "blend1":
			into.append(dir_path.path_join(file))


func run() -> void:
	var files: Array[String] = []
	collect(LIB, files)
	var out := FileAccess.open(OUT, FileAccess.WRITE)
	out.store_line("path\tbytes\tstatus\tcompressed\tversion\tobjects\tmeshes\tarmatures\tactions\timages\tmaterials\tscenes\tthumb\taction_names")
	for path in files:
		var r := probe(path)
		var c: Dictionary = r["counts"]
		var thumb_name := ""
		if r.has("image"):
			thumb_name = path.replace(LIB + "/", "").replace("/", "__").get_basename() + ".png"
			(r["image"] as Image).save_png(THUMBS + thumb_name)
		out.store_line("\t".join(PackedStringArray([path, str(FileAccess.open(path, FileAccess.READ).get_length()), r["status"], str(r["compressed"]), r["version"],
				str(c.get("OB", 0)), str(c.get("ME", 0)), str(c.get("AR", 0)), str(c.get("AC", 0)), str(c.get("IM", 0)), str(c.get("MA", 0)), str(c.get("SC", 0)),
				thumb_name, ";".join(PackedStringArray(r["actions"]))])))
		out.flush()
		print("BLEND ", path.get_file(), " ", r["status"], " ", r["thumb"])
	out.close()
	print("BLEND PROBE DONE ", files.size())
	quit(0)
