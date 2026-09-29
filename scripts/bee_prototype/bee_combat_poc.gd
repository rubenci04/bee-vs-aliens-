extends Node3D

enum Stage { APPROACH_A, ENCOUNTER_A, PAUSE_B, ENCOUNTER_B, PAUSE_C, ENCOUNTER_C, COMPLETE, DEFEATED }

@onready var bee: BeePlayer = $BeePlayer
@onready var wasp_a: WaspEnemy = $Enemies/WaspA
@onready var probe_a: AlienProbeRanged = $Enemies/ProbeA
@onready var wasp_b: WaspEnemy = $Enemies/WaspB
@onready var probe_b: AlienProbeRanged = $Enemies/ProbeB
@onready var hp_label: Label = $CanvasLayer/Panel/VBox/HP
@onready var pollen_label: Label = $CanvasLayer/Panel/VBox/Pollen
@onready var auto_aim_label: Label = $CanvasLayer/Panel/VBox/AutoAim
@onready var status_label: Label = $CanvasLayer/Status
@onready var completion_label: Label = $CanvasLayer/Completion
@onready var defeat_label: Label = $CanvasLayer/Defeat
@onready var retry_label: Label = $CanvasLayer/Retry

var stage := Stage.APPROACH_A
var pollen_count := 0
var completion_count := 0
var defeat_count := 0


func _ready() -> void:
	for pickup in $Pollen.get_children():
		pickup.collected.connect(_on_pollen_collected)
	bee.health_changed.connect(_on_bee_health_changed)
	bee.auto_aim_changed.connect(_on_auto_aim_changed)
	bee.defeated.connect(_on_bee_defeated)
	wasp_a.defeated.connect(_on_wasp_a_defeated)
	probe_a.defeated.connect(_on_probe_a_defeated)
	wasp_b.defeated.connect(_on_final_enemy_defeated)
	probe_b.defeated.connect(_on_final_enemy_defeated)
	_on_bee_health_changed(bee.health.current_health, bee.health.max_health)
	_update_pollen_label()
	auto_aim_label.hide()
	completion_label.hide()
	defeat_label.hide()
	retry_label.hide()


func _process(_delta: float) -> void:
	if stage == Stage.DEFEATED:
		if Input.is_action_just_pressed("restart"):
			get_tree().reload_current_scene()
		return
	match stage:
		Stage.APPROACH_A:
			status_label.text = "ENCUENTRO A · AVISPA"
			if bee.position.x >= -6.0:
				wasp_a.activate(bee)
				stage = Stage.ENCOUNTER_A
		Stage.PAUSE_B:
			status_label.text = "AVANZÁ HACIA LA SONDA →"
			if bee.position.x >= -0.5:
				probe_a.activate(bee)
				stage = Stage.ENCOUNTER_B
		Stage.PAUSE_C:
			status_label.text = "ÚLTIMO SECTOR →"
			if bee.position.x >= 4.0:
				wasp_b.activate(bee)
				probe_b.activate(bee)
				stage = Stage.ENCOUNTER_C
		Stage.ENCOUNTER_A:
			status_label.text = "Z: AGUIJÓN · X: DISPARO"
		Stage.ENCOUNTER_B:
			status_label.text = "ESQUIVÁ EL PROYECTIL ALIENÍGENA"
		Stage.ENCOUNTER_C:
			status_label.text = "AVISPA + SONDA"
		Stage.COMPLETE:
			status_label.text = "SECTOR ASEGURADO"


func _on_wasp_a_defeated(_enemy: WaspEnemy) -> void:
	if stage == Stage.ENCOUNTER_A:
		stage = Stage.PAUSE_B


func _on_probe_a_defeated(_enemy: AlienProbeRanged) -> void:
	if stage == Stage.ENCOUNTER_B:
		stage = Stage.PAUSE_C


func _on_final_enemy_defeated(_enemy: Node) -> void:
	if stage != Stage.ENCOUNTER_C:
		return
	if wasp_b.is_defeated() and probe_b.is_defeated():
		stage = Stage.COMPLETE
		completion_count += 1
		completion_label.show()


func _on_pollen_collected(_pickup: BeePollenPickup, _restored_health: int) -> void:
	pollen_count += 1
	_update_pollen_label()


func _on_bee_health_changed(current: int, maximum: int) -> void:
	hp_label.text = "HP: %d/%d" % [current, maximum]


func _on_auto_aim_changed(target: Node3D) -> void:
	auto_aim_label.visible = target != null


func _on_bee_defeated() -> void:
	if stage == Stage.DEFEATED:
		return
	stage = Stage.DEFEATED
	defeat_count += 1
	defeat_label.show()
	retry_label.show()
	for enemy in [wasp_a, probe_a, wasp_b, probe_b]:
		enemy.set_physics_process(false)


func _update_pollen_label() -> void:
	pollen_label.text = "POLEN: %d/2" % pollen_count