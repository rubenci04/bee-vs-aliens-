extends Control
## DEV ONLY (GARDEN IDENTITY & AUDIO PASS 04). Listening station for the audio candidates and the cues integrated
## in this pass. Open res://dev/audio_audition/audio_audition.tscn and press F6.
##   Up / Down      select a row            Left / Right   previous / next category
##   Space / Enter  play the selected row   S              stop
##   A              play what the GAME uses now for this category (row 0) for A/B
## Rows marked "NUEVO" are the files this pass wrote into res://audio (what the game plays now).
## Library files are read in place (absolute paths): nothing is imported or copied by this scene.

const C := preload("res://dev/audio_audition/audition_candidates.gd")

## The integrated results (category -> rows), shown after the library candidates.
const INTEGRATED := {
	"enemy_death_tech": [["NUEVO tech_death (Epic Anime explosion, recortado)", "res://audio/sfx/real/tech_death.wav", "S"]],
	"enemy_death_organic": [["NUEVO organic_death (splat + burbujas)", "res://audio/sfx/real/organic_death.wav", "S"]],
	"wasp_warning": [["NUEVO wasp_overload (Insectoid Tremble)", "res://audio/sfx/real/wasp_overload.wav", "S"]],
	"organic_identity": [["NUEVO organic_charge (tentacle wobble)", "res://audio/sfx/real/organic_charge.wav", "S"]],
	"walker_mechanical": [["NUEVO walker_charge (robot servo)", "res://audio/sfx/real/walker_charge.wav", "S"]],
	"human_step": [["NUEVO human_step (pasto + impacto grave)", "res://audio/sfx/real/human_step.wav", "S"]],
	"ufo_entry": [["NUEVO ufo_approach (Unidentified Encounter)", "res://audio/sfx/real/ufo_approach.wav", "S"]],
	"ambient_insects": [["NUEVO dusk_loop (grillos, atardecer)", "res://audio/ambience/dusk_loop.wav", "S"]],
	"spider": [["NUEVO spider_telegraph", "res://audio/sfx/real/spider_telegraph.wav", "S"], ["NUEVO spider_drop", "res://audio/sfx/real/spider_drop.wav", "S"],
			["NUEVO spider_retract", "res://audio/sfx/real/spider_retract.wav", "S"]],
}

var categories: Array = []
var category_index := 0
var row := 0
var player: AudioStreamPlayer
var label: Label
var _streams := {}


func _ready() -> void:
	categories = C.CATEGORIES.keys()
	player = AudioStreamPlayer.new()
	player.bus = &"SFX"
	add_child(player)
	var background := ColorRect.new()
	background.color = Color(0.07, 0.08, 0.1)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	label = Label.new()
	label.position = Vector2(24, 18)
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)
	refresh()


func rows() -> Array:
	var category: String = categories[category_index]
	var list: Array = C.CATEGORIES[category].duplicate()
	for entry in INTEGRATED.get(category, []):
		if FileAccess.file_exists(entry[1]):
			list.append(entry)
	return list


func refresh() -> void:
	var list := rows()
	row = clampi(row, 0, list.size() - 1)
	var text := "AUDICIÓN · %s  (%d/%d)   ↑↓ fila · ←→ categoría · Espacio reproducir · S stop · A = lo que usa el juego\n\n" % [categories[category_index], category_index + 1, categories.size()]
	for i in list.size():
		var entry: Array = list[i]
		var stream := cached(entry[1])
		var length := stream.get_length() if stream != null else -1.0
		text += "%s %-52s %6.2f s  [%s]\n" % ["▶" if i == row else " ", entry[0], length, entry[2]]
	var selected: Array = list[row]
	text += "\nArchivo: %s\nRuta: %s" % [str(selected[1]).get_file(), C.absolute(selected[1])]
	label.text = text


func cached(path: String) -> AudioStream:
	if not _streams.has(path):
		_streams[path] = C.load_stream(path)
	return _streams[path]


func play(entry: Array) -> void:
	player.stop()
	player.stream = cached(entry[1])
	if player.stream != null:
		player.play()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match (event as InputEventKey).keycode:
		KEY_UP:
			row -= 1
		KEY_DOWN:
			row += 1
		KEY_LEFT:
			category_index = posmod(category_index - 1, categories.size())
			row = 0
		KEY_RIGHT:
			category_index = posmod(category_index + 1, categories.size())
			row = 0
		KEY_SPACE, KEY_ENTER:
			play(rows()[clampi(row, 0, rows().size() - 1)])
		KEY_A:
			play(rows()[0])
		KEY_S:
			player.stop()
	refresh()
