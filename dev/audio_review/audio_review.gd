extends Node3D

var cues: Array = BeeAudio.CUES.keys()
var index := 0
var label: Label
var detail: Label
var spam_running := false

func _ready() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0, 0, 8)
	add_child(camera)
	camera.current = true
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := VBoxContainer.new()
	panel.position = Vector2(45, 45)
	canvas.add_child(panel)
	label = Label.new()
	label.add_theme_font_size_override("font_size", 26)
	panel.add_child(label)
	detail = Label.new()
	panel.add_child(detail)
	var actions := HBoxContainer.new()
	panel.add_child(actions)
	button(actions, "← Anterior", func(): advance(-1))
	button(actions, "Siguiente →", func(): advance(1))
	button(actions, "A · Procedural", func(): play_selected(false))
	button(actions, "B · Asset V02", func(): play_selected(true))
	button(panel, "Base repetido ×10 (V02)", spam_base)
	var hint := Label.new()
	hint.text = "Flechas: cue · A: procedural · B/Space: seleccionado\nHerramienta DEV; no afecta gameplay ni mezcla definitiva.\nOrganic death / human warning conservan su placeholder."
	panel.add_child(hint)
	refresh()

func button(parent: Control, title: String, callback: Callable) -> void:
	var node := Button.new()
	node.text = title
	node.pressed.connect(callback)
	parent.add_child(node)

func advance(direction: int) -> void:
	index = posmod(index + direction, cues.size())
	refresh()

func refresh() -> void:
	var cue: StringName = cues[index]
	label.text = "%d/16 · %s" % [index + 1, cue]
	detail.text = "A: %s.wav\nB: %s" % [BeeAudio.CUES[cue][0], "real/%s.wav" % cue if cue in BeeAudio.REAL_CUES else "placeholder conservado"]

func play_selected(real: bool) -> Node:
	for voice in get_tree().get_nodes_in_group("bee_audio_voice"):
		voice.call("stop")
		voice.queue_free()
	var previous := BeeAudio.use_real_assets
	BeeAudio.use_real_assets = real
	var voice := BeeAudio.play(self, cues[index], Vector3.ZERO)
	BeeAudio.use_real_assets = previous
	return voice

func spam_base() -> void:
	if spam_running:
		return
	spam_running = true
	var previous := BeeAudio.use_real_assets
	for i in 10:
		BeeAudio.use_real_assets = true
		BeeAudio.play(self, &"base")
		BeeAudio.use_real_assets = previous
		await get_tree().create_timer(0.16).timeout
	spam_running = false

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_LEFT: advance(-1)
		KEY_RIGHT: advance(1)
		KEY_A: play_selected(false)
		KEY_B, KEY_SPACE: play_selected(true)
