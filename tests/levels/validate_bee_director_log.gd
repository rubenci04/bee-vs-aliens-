extends SceneTree
## Fresh boot verifies that the editor writes the director's black-box file.
const TITLE := "res://scenes/game/bee_title_screen.tscn"
const LEVEL := "res://scenes/levels/bee_level_01_vertical_slice.tscn"


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var title := load(TITLE) as PackedScene
	var scene := title.instantiate()
	root.add_child(scene)
	current_scene = scene
	for i in 4: await process_frame
	if change_scene_to_file(LEVEL) != OK:
		push_error("Level did not load")
		quit(1)
		return
	for i in 12: await process_frame
	var stage := current_scene
	var wave = stage.get("wave")
	var logger = wave.get("_director_log")
	if logger == null or not logger.get("enabled"):
		push_error("Director logger did not start in editor build")
		quit(1)
		return
	logger.call("write_event", "prueba caja negra")
	var path := ProjectSettings.globalize_path("user://director_log.txt")
	var content := FileAccess.get_file_as_string("user://director_log.txt")
	if not content.contains("prueba caja negra"):
		push_error("Director log was not written at " + path)
		quit(1)
		return
	print("BEE_DIRECTOR_LOG_OK path=" + path)
	quit(0)
