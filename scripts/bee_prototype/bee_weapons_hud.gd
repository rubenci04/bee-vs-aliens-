extends Control

@export var bee_path: NodePath
@onready var bee: BeePlayer = get_node(bee_path)
var taught: Dictionary = {}

func _ready() -> void:
	bee.weapon_state_changed.connect(refresh)
	bee.powerup_collected.connect(show_hint)
	bee.defeated.connect(func(): $Hint.hide())
	$HintTimer.timeout.connect(func(): $Hint.hide())
	refresh()

func refresh() -> void:
	var weapon := "SPREAD x%d" % bee.spread_ammo if bee.spread_ammo > 0 else "BASE"
	$State.text = "%s · BOMB x%d · C BOMB" % [weapon, bee.bomb_charges]

func show_hint(kind: StringName) -> void:
	if taught.has(kind):
		return
	taught[kind] = true
	$Hint.text = "SPREAD SHOT · X — FIRE" if kind == &"spread" else "ALIEN BOMB · C — USE"
	$Hint.show()
	$HintTimer.start()
