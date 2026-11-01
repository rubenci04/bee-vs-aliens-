extends Node3D
## Tanda U · E — globito de frase sobre Bee: Label3D chico, 1 a 3 palabras en rioplatense, como mucho uno cada
## BARK_MIN_GAP_SECONDS. Las frases viven en assets/ui/bee_barks.json (editable sin tocar código). Se apaga con
## BARKS_ENABLED (también desde la pausa). Momentos: primera liberación, primer golpe, zona despejada, vida baja, jefe.
const S := preload("res://scripts/game/bee_expression_settings.gd")

var bee: BeePlayer
var lines: Dictionary = {}
var label: Label3D
var shown_left := 0.0
var since_last := INF # Segundos desde la última frase.
var said_once: Dictionary = {} # Momentos que van una sola vez por partida.
var history: Array[String] = [] # Frases dichas (tests, informe).
var _rng := RandomNumberGenerator.new()


static func attach(stage: Node, player: BeePlayer) -> Node3D:
	if player == null:
		return null
	var barks := (load("res://scripts/vfx/bee_barks.gd") as GDScript).new() as Node3D
	barks.name = "BeeBarks"
	barks.set("bee", player)
	stage.add_child(barks)
	return barks


static func load_lines() -> Dictionary:
	var text := FileAccess.get_file_as_string(S.BARKS_FILE)
	var data: Variant = JSON.parse_string(text) if not text.is_empty() else null
	return data if data is Dictionary else {}


func _ready() -> void:
	_rng.randomize()
	lines = load_lines()
	label = Label3D.new()
	label.name = "Bark"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = S.BARK_FONT
	label.outline_size = 10
	label.pixel_size = 0.0075
	label.modulate = S.BARK_COLOR
	label.outline_modulate = S.BARK_OUTLINE
	label.top_level = true
	add_to_group("bee_barks")
	label.visible = false
	add_child(label)


## Pide una frase para un momento. `once`: ese momento habla una sola vez por partida. Devuelve si habló.
func say(moment: String, once := false) -> bool:
	if not S.BARKS_ENABLED or not is_instance_valid(bee) or bee.is_defeated:
		return false
	if once and said_once.has(moment):
		return false
	if since_last < S.BARK_MIN_GAP_SECONDS:
		return false
	var options: Array = lines.get(moment, [])
	if options.is_empty():
		return false
	if once:
		said_once[moment] = true
	var text := str(options[_rng.randi_range(0, options.size() - 1)])
	history.append(text)
	label.text = text
	label.visible = true
	label.modulate.a = 1.0
	label.outline_modulate.a = 1.0
	shown_left = S.BARK_SECONDS
	since_last = 0.0
	return true


func _process(delta: float) -> void:
	since_last += delta
	if not label.visible:
		return
	if not S.BARKS_ENABLED or not is_instance_valid(bee):
		label.visible = false
		return
	shown_left -= delta
	label.global_position = bee.global_position + Vector3(0.0, S.BARK_HEIGHT, 0.3)
	var fade := clampf(shown_left / 0.3, 0.0, 1.0) # Se desvanece en los últimos 0,3 s.
	label.modulate.a = fade
	label.outline_modulate.a = fade
	if shown_left <= 0.0:
		label.visible = false
