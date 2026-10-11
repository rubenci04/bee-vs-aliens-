extends "res://scripts/art/title_screen_v01.gd"
## NOCHE 01 · ETAPA 2 — the game's title screen (main scene). It REUSES Codex's title POC (scripts/art/title_screen_v01.gd:
## garden backdrop, Bee, logo, warm buttons) without modifying it, and adapts the menu:
##   Jugar Nivel 01   opens Level 01 (and marks that we came from the title: the level returns here when completed)
##   Dificultad       toggles FÁCIL / NORMAL (BeeGameSettings)
##   Colección de arte  only in debug mode (editor runs or --debug-art): hidden in an exported game
##   Salir

const PLAY_TEXT := "Jugar Nivel 01"
const ART_TEXT := "Colección de arte"
const DIFFICULTY_PREFIX := "Dificultad: "
const LAKE_TEXT := "Laguna (prototipo · debug)"
const LAKE_SCENE := "res://scenes/levels/bee_level_02_lake.tscn"

var difficulty_button: Button


static func debug_menu_enabled() -> bool:
	return OS.has_feature("editor") or "--debug-art" in OS.get_cmdline_user_args()


func _make_ui() -> void:
	super._make_ui()
	var play: Button = null
	for button: Button in ui.find_children("*", "Button", true, false):
		if button.text == ART_TEXT and not debug_menu_enabled():
			button.get_parent().remove_child(button)
			button.queue_free()
		elif button.text == PLAY_TEXT:
			play = button
	if play == null:
		return
	# The Play button keeps Codex's style; it now also tells the level it was opened from here.
	for connection in play.pressed.get_connections():
		play.pressed.disconnect(connection["callable"])
	difficulty_button = play.duplicate(0) as Button # No signals copied.
	play.pressed.connect(_play)
	difficulty_button.name = "DifficultyButton"
	play.get_parent().add_child(difficulty_button)
	play.get_parent().move_child(difficulty_button, play.get_index() + 1)
	difficulty_button.pressed.connect(_toggle_difficulty)
	if debug_menu_enabled():
		# NOCHE 01 · ETAPA 4: the Level 02 "Laguna" prototype, debug only (the normal flow stays Level 01).
		var lake := play.duplicate(0) as Button
		lake.name = "LakePrototypeButton"
		lake.text = LAKE_TEXT
		play.get_parent().add_child(lake)
		play.get_parent().move_child(lake, difficulty_button.get_index() + 1)
		lake.pressed.connect(_play_lake)
	_refresh_difficulty()


func _play() -> void:
	BeeGameSettings.from_title = true
	get_tree().change_scene_to_file(BeeGameSettings.LEVEL_01)


func _toggle_difficulty() -> void:
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL if BeeGameSettings.difficulty == BeeGameSettings.EASY else BeeGameSettings.EASY
	_refresh_difficulty()


func _refresh_difficulty() -> void:
	if difficulty_button != null:
		difficulty_button.text = DIFFICULTY_PREFIX + BeeGameSettings.label()


func _play_lake() -> void:
	BeeGameSettings.from_title = true
	get_tree().change_scene_to_file(LAKE_SCENE)
