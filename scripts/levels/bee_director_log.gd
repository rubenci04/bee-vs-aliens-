extends Node
## One line per second plus director events. F4 toggles logging in exported games.
const LOG_PATH := "user://director_log.txt"
const SAMPLE_SECONDS := 1.0
var director: Node3D
var enabled := false
var elapsed := 0.0
var key_held := false
var output: FileAccess


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	enabled = OS.has_feature("editor")
	if enabled:
		_open()


func _exit_tree() -> void:
	if output != null:
		output.flush()
		output.close()


func _process(delta: float) -> void:
	var pressed := Input.is_key_pressed(KEY_F4)
	if pressed and not key_held:
		enabled = not enabled
		if enabled:
			_open()
			write_event("registro activado")
		else:
			write_event("registro desactivado", true)
	key_held = pressed
	if not enabled or output == null or not is_instance_valid(director):
		return
	elapsed += delta
	if elapsed >= SAMPLE_SECONDS:
		elapsed = 0.0
		_sample()


func _open() -> void:
	if output != null:
		return
	var folder := ProjectSettings.globalize_path("user://")
	DirAccess.make_dir_recursive_absolute(folder)
	output = FileAccess.open(LOG_PATH, FileAccess.WRITE_READ)
	if output != null:
		output.seek_end()
		output.store_line("--- sesión %s ---" % Time.get_datetime_string_from_system())
		output.flush()


func write_event(message: String, force := false) -> void:
	if (not enabled and not force) or output == null:
		return
	output.store_line("EVENT t=%.1f x=%.1f %s" % [float(director.get("_clock")), float(director.stage.distance), message])
	output.flush()


func _sample() -> void:
	var stage: Node3D = director.stage
	var camera_x: float = stage.camera.global_position.x
	var table: Array = director.events_table()
	var index: int = director.event_index
	var next := "%d:%s" % [index, str(table[index].get("label", ""))] if index < table.size() else "fin"
	var units: Array[String] = []
	for unit in director.active_units + director.swarm_units:
		if not is_instance_valid(unit):
			continue
		var state: Variant = unit.get("state")
		if state == null: state = unit.get("current_state")
		if state == null: state = unit.get("_step")
		units.append("%s(rel=%.1f,vis=%s,tp=%s,age=%.1f,state=%s)" % [unit.name, unit.global_position.x - camera_x, unit.is_visible_in_tree(), unit.get_meta("teleporting", false), float(director.get("_clock")) - float(unit.get_meta("level_born", 0.0)), str(state)])
	var teleports := 0
	var oldest := 0.0
	for node in stage.get_node("Enemies").get_children():
		if node.name == "EnemyTeleport":
			teleports += 1
			oldest = maxf(oldest, float(node.get("elapsed")))
	output.store_line("STATE t=%.1f dist=%.1f cam=%.1f gate=%s arena=%s calma=%.1f pending=%d swarm_pending=%d next=%s debut_wait=%.1f units=[%s] teleport=%d oldest=%.1f frozen=%s no_visible=%.1f" % [float(director.get("_clock")), float(stage.distance), camera_x, director.get("_hard_gate"), director.in_arena(), maxf(0.0, float(director.get("_breather_until")) - float(director.get("_clock"))), director.get("_pending").size(), director.get("_swarm_pending").size(), next, float(director.get("_debut_wait")), ",".join(units), teleports, oldest, director.get("_frozen"), float(director.get("_no_visible_seconds"))])
	output.flush()
