extends RefCounted
const SAVE_PATH := "user://bee_training.cfg"
const SECTION := "controls"
const KEY_SEEN := "training_seen"
const SKIP_HOLD_SECONDS := 1.0
static var seen_override = null # Tests can exercise first-run behavior without changing user://.
const STEPS := [
	{"id": &"move", "keyboard": "WASD / FLECHAS", "gamepad": "STICK IZQ.", "what": "Volá en cualquier dirección.", "when": "Movete para esquivar y buscar una línea de tiro."},
	{"id": &"fire", "keyboard": "X / CLIC", "gamepad": "A / RT", "what": "Dispará el arma activa.", "when": "Mantené el tiro sobre los enemigos visibles."},
	{"id": &"roll", "keyboard": "SHIFT", "gamepad": "B / LB", "what": "La pirueta te hace inmune un instante.", "when": "Usala cuando veas el aviso de un disparo."},
	{"id": &"melee", "keyboard": "Z", "gamepad": "Y / RB", "what": "El puñetazo embiste al enemigo cercano.", "when": "Usalo cuerpo a cuerpo, incluso si quedó atrás."},
	{"id": &"bomb", "keyboard": "C", "gamepad": "X", "what": "La bomba limpia grupos.", "when": "Usala cuando haya muchos enemigos juntos."},
	{"id": &"pollen", "keyboard": "Q", "gamepad": "LT", "what": "Un cartucho cura 25, da escudo y disparo doble por 4 s.", "when": "Usalo con poca vida o si te rodean; requiere 7 granos."},
]

static func description(step: Dictionary, gamepad: bool) -> String:
	return "%s · %s\n%s" % [step.gamepad if gamepad else step.keyboard, step.what, step.when]

static func device_icon(gamepad: bool) -> String:
	return "🎮" if gamepad else "⌨"

static func lines(gamepad: bool) -> Array[String]:
	var result: Array[String] = []
	for step in STEPS:
		result.append(description(step, gamepad).replace("\n", " "))
	return result

static func seen() -> bool:
	if seen_override != null:
		return bool(seen_override)
	var config := ConfigFile.new()
	return config.load(SAVE_PATH) == OK and bool(config.get_value(SECTION, KEY_SEEN, false))

static func mark_seen() -> void:
	if seen_override != null:
		seen_override = true
		return
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value(SECTION, KEY_SEEN, true)
	config.save(SAVE_PATH)
