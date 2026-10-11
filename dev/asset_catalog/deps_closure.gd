extends SceneTree
## DEV (noche 01): prints every res:// file a set of root resources depends on (recursive), one per line: DEP <path>.
## godot --headless --path . --script res://dev/asset_catalog/deps_closure.gd -- res://a.tscn res://b.gd ...
func _init() -> void:
	var seen := {}
	var queue: Array = OS.get_cmdline_user_args().duplicate()
	while not queue.is_empty():
		var path: String = queue.pop_back()
		if seen.has(path) or not path.begins_with("res://"):
			continue
		seen[path] = true
		if path.get_extension() in ["gd", "tscn", "tres", "gdshader", "gdshaderinc"] and FileAccess.file_exists(path):
			var text := FileAccess.get_file_as_string(path)
			var regex := RegEx.create_from_string("res://[^\"'\\s\\)]+")
			for m in regex.search_all(text):
				var found := m.get_string()
				if "%" in found:
					continue
				if FileAccess.file_exists(found) or DirAccess.dir_exists_absolute(found):
					queue.append(found)
		for dep in ResourceLoader.get_dependencies(path):
			var p: String = dep.get_slice("::", 2) if dep.contains("::") else dep
			if p.begins_with("uid://"):
				p = ResourceUID.get_id_path(ResourceUID.text_to_id(p))
			queue.append(p)
	for path in seen:
		print("DEP ", path)
	quit()
