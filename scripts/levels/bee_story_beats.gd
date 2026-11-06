extends Node
## Tanda W — escenas cortas dentro del Nivel 1 (2 a 3 s), con el juego en pausa y barras negras; cualquier botón las saltea.
##   start   al empezar: el implante chispea, Bee sacude la cabeza y pasa de neutra a concentrada
##   robot   el robot entra en pantalla: la cámara se abre, Bee traga saliva (sorpresa) y dice "Uh..."
##   spider  la tarántula entra: Bee mira para arriba, a las telarañas, y dice "¡Arañas no!"
## Al terminar una escena de jefe aparece su cartel (nombre + una línea). Cada escena sale una vez por partida: lo jugado se
## guarda en el SceneTree (sobrevive al reintento desde checkpoint) y se borra en un arranque nuevo.
const S := preload("res://scripts/game/bee_story_settings.gd")
const PLAYED_META := "bee_story_played"
## En headless (pruebas y bots) no se disparan solas: las pruebas las llaman con play(). Un test puede prenderlas.
static var auto_in_headless := false

signal beat_started(beat: StringName)
signal beat_finished(beat: StringName, skipped: bool)

var stage: BeeShmupStage
var active := false
var current: StringName = &""
var skipped := false
var _age := 0.0
var _started_msec := 0 # La escena mide su duración con el reloj real (no depende del delta ni de la pausa).
var _length := 0.0
var _tweens: Array[Tween] = [] # Solo las animaciones de la escena: al terminar se cortan estas y ninguna más.
var _bars: CanvasLayer
var _top: ColorRect
var _bottom: ColorRect
var _visual: Node3D
var _visual_rotation := Vector3.ZERO
var _visual_scale := Vector3.ONE
var _fov := 0.0


static func attach(level: BeeShmupStage, fresh_run: bool) -> Node:
	if not S.STORY_BEATS_ENABLED and not S.BOSS_CARDS_ENABLED:
		return null
	if fresh_run or not level.get_tree().has_meta(PLAYED_META):
		level.get_tree().set_meta(PLAYED_META, {})
	var beats: Node = (load("res://scripts/levels/bee_story_beats.gd") as GDScript).new()
	beats.name = "StoryBeats"
	beats.process_mode = Node.PROCESS_MODE_ALWAYS
	beats.set("stage", level)
	level.add_child(beats)
	return beats


func played() -> Dictionary:
	return get_tree().get_meta(PLAYED_META, {})


func _ready() -> void:
	_bars = CanvasLayer.new()
	_bars.name = "StoryBars"
	_bars.layer = 40
	_bars.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_bars)
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.anchor_left = 0.0
		bar.anchor_right = 1.0
		bar.anchor_top = 0.0 if top else 1.0
		bar.anchor_bottom = 0.0 if top else 1.0
		_bars.add_child(bar)
		if top: _top = bar
		else: _bottom = bar
	_set_bars(0.0)


func _set_bars(amount: float) -> void:
	var hud := stage.get_node_or_null("CanvasLayer") as CanvasLayer
	if hud != null:
		hud.visible = amount <= 0.01 # Mejora visual: las barras negras no cortan el HUD a la mitad.
	var height := get_viewport().get_visible_rect().size.y * S.BAR_HEIGHT * amount
	_top.offset_top = 0.0
	_top.offset_bottom = height
	_bottom.offset_top = -height
	_bottom.offset_bottom = 0.0
	_bars.visible = amount > 0.001


func _process(_delta: float) -> void:
	if active:
		_age = float(Time.get_ticks_msec() - _started_msec) / 1000.0
		if _age >= _length:
			finish(false)
		return
	if DisplayServer.get_name() == "headless" and not auto_in_headless:
		return
	if get_tree().paused or stage == null or not is_instance_valid(stage.bee) or stage.bee.is_defeated or stage.sector_complete:
		return
	var wave := stage.wave as BeeLevel01Controller
	if wave == null:
		return
	var camera_x := stage.camera.global_position.x
	if not played().has(&"start") and not wave.intro_active() and stage.distance < 25.0:
		play(&"start")
	elif not played().has(&"robot") and is_instance_valid(wave.miniboss) and wave.miniboss.health.current_health > 0 and absf(wave.miniboss.global_position.x - camera_x) < S.BOSS_ON_SCREEN:
		play(&"robot")
	elif not played().has(&"spider") and is_instance_valid(wave.tarantula) and absf(wave.tarantula.global_position.x - camera_x) < S.BOSS_ON_SCREEN:
		play(&"spider")


## Cualquier tecla, botón del mando o clic saltea la escena (después de un respiro corto).
func _input(event: InputEvent) -> void:
	if not active or _age < S.SKIP_GRACE_SECONDS:
		return
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventJoypadButton and event.pressed) or (event is InputEventMouseButton and event.pressed)
	if pressed:
		get_viewport().set_input_as_handled()
		finish(true)


func play(beat: StringName) -> bool:
	if active or played().has(beat):
		return false
	played()[beat] = true
	if not S.STORY_BEATS_ENABLED:
		_show_card(beat)
		return false
	active = true
	current = beat
	skipped = false
	_age = 0.0
	_started_msec = Time.get_ticks_msec()
	_length = {&"start": S.START_SECONDS, &"robot": S.ROBOT_SECONDS, &"spider": S.SPIDER_SECONDS}.get(beat, 2.5)
	_visual = stage.bee.get_node_or_null("VisualRoot/BeeVisual") as Node3D
	if _visual != null:
		_visual_rotation = _visual.rotation
		_visual_scale = _visual.scale
	_fov = stage.camera.fov
	get_tree().paused = true
	var bars := _beat_tween()
	bars.tween_method(_set_bars, 0.0, 1.0, S.BAR_IN_SECONDS)
	match beat:
		&"start": _start_beat()
		&"robot": _robot_beat()
		&"spider": _spider_beat()
	beat_started.emit(beat)
	return true


func _beat_tween() -> Tween:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tweens.append(tween)
	return tween


func _face(face: StringName) -> void:
	if _visual != null and _visual.get("expressions") != null and _visual.expressions.is_bound():
		_visual.expressions.set_face_now(face)


func _say(moment: String) -> void:
	for barks in get_tree().get_nodes_in_group("bee_barks"):
		barks.call("say", moment, false, true)


func _spark() -> void:
	var socket: Node3D = _visual.get("helmet_socket") if _visual != null else null
	var at := socket.global_position if is_instance_valid(socket) else stage.bee.global_position + Vector3(0, 0.3, 0)
	var effect: Variant = BeeCombatVFX.spawn(stage, at, &"tech_hit", Vector3.UP, 0.5)
	if effect is Node:
		(effect as Node).process_mode = Node.PROCESS_MODE_ALWAYS # Se ve aunque el juego esté en pausa.


func _start_beat() -> void:
	_face(&"neutral")
	var head := _beat_tween()
	head.tween_interval(0.35)
	head.tween_callback(_spark)
	head.tween_interval(0.25)
	for i in S.START_SHAKES:
		var side := deg_to_rad(S.START_SHAKE_DEGREES) * (1.0 if i % 2 == 0 else -1.0)
		head.tween_property(_visual, "rotation:y", _visual_rotation.y + side, 0.1)
	head.tween_property(_visual, "rotation:y", _visual_rotation.y, 0.1)
	head.tween_interval(0.2)
	head.tween_callback(_face.bind(&"focused"))


func _robot_beat() -> void:
	var look := _beat_tween()
	look.tween_property(stage.camera, "fov", _fov * S.ROBOT_FOV_OPEN, 0.5).set_trans(Tween.TRANS_SINE)
	look.tween_callback(_face.bind(&"surprised"))
	look.tween_property(_visual, "scale:y", _visual_scale.y * S.GULP_SQUASH, 0.12) # Traga saliva.
	look.tween_property(_visual, "scale:y", _visual_scale.y, 0.15)
	look.tween_callback(_say.bind("beat_robot"))


func _spider_beat() -> void:
	var look := _beat_tween()
	look.tween_property(_visual, "rotation:x", _visual_rotation.x + deg_to_rad(S.LOOK_UP_DEGREES), 0.4).set_trans(Tween.TRANS_SINE)
	look.tween_callback(_face.bind(&"surprised"))
	look.tween_interval(0.5)
	look.tween_callback(_say.bind("beat_spider"))


func finish(was_skipped: bool) -> void:
	if not active:
		return
	active = false
	skipped = was_skipped
	for tween in _tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_tweens.clear()
	if is_instance_valid(_visual):
		_visual.rotation = _visual_rotation
		_visual.scale = _visual_scale
	stage.camera.fov = _fov
	_set_bars(0.0)
	get_tree().paused = false
	var beat := current
	current = &""
	if beat in [&"robot", &"spider"]:
		_show_card(beat)
	beat_finished.emit(beat, was_skipped)


## Cartel de entrada del jefe: nombre grande y una línea, 1,5 s, debajo de la barra de vida.
func _show_card(beat: StringName) -> void:
	var kind: StringName = &"robot" if beat == &"robot" else &"spider"
	if not S.BOSS_CARDS_ENABLED or not S.CARDS.has(kind):
		return
	var layer := CanvasLayer.new()
	layer.name = "BossCard"
	layer.layer = 35
	var box := VBoxContainer.new()
	box.anchor_left = 0.0
	box.anchor_right = 1.0
	box.anchor_top = S.CARD_TOP
	box.anchor_bottom = S.CARD_TOP
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(box)
	for i in 2:
		var label := Label.new()
		label.text = str(S.CARDS[kind][i])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 54 if i == 0 else 24)
		label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35) if i == 0 else Color(1.0, 0.97, 0.9))
		label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02))
		label.add_theme_constant_override("outline_size", 10 if i == 0 else 6)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(label)
	add_child(layer)
	var fade := box.create_tween()
	fade.tween_interval(S.CARD_SECONDS * 0.7)
	fade.tween_property(box, "modulate:a", 0.0, S.CARD_SECONDS * 0.3)
	fade.tween_callback(layer.queue_free)
