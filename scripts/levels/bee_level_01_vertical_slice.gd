extends BeeShmupStage

@onready var level_wave: BeeLevel01Controller = $WaveController
@onready var section_label: Label = $CanvasLayer/Section

var elapsed_seconds := 0.0
@onready var checkpoint: BeeCheckpointQoL = $CheckpointQoL

func _ready() -> void:
	super._ready()
	checkpoint.setup(self)

func _process(_delta: float) -> void:
	# Esc/Shift+R and the defeat R are handled by the always-processing QoL component.
	# After victory R is a full restart (same as Shift+R).
	if sector_complete and not bee.is_defeated and not get_tree().paused \
			and Input.is_action_just_pressed("restart") and not Input.is_action_just_pressed("bee_full_restart"):
		checkpoint.restart_level(true)

func _on_bee_defeated() -> void:
	super._on_bee_defeated()
	checkpoint.defeat_hint()

func _physics_process(delta: float) -> void:
	if not bee.is_defeated and not sector_complete:
		elapsed_seconds += delta
	super._physics_process(delta)
	if bee.is_defeated:
		return
	if sector_complete:
		status.text = "SECTOR DESPEJADO"
		section_label.text = "LEVEL 01 COMPLETADO\nR — JUGAR DE NUEVO"
		_secure_victory()
		return
	if not wave_clear_announced:
		status.text = "HP %d/%d · POLEN %d/17 · WASD/FLECHAS VOLAR · X DISPARO · Z MELEE" % [bee.health.current_health, bee.health.max_health, pollen_count]
	section_label.text = level_wave.encounter_label

func _secure_victory() -> void:
	# Terminal state: Bee takes no damage and no enemy shot stays in flight.
	bee.health.damage_blocked = true
	for node in find_children("*", "Node3D", true, false):
		if node is AlienEnemyProjectile:
			(node as AlienEnemyProjectile).hitbox.set_enabled(false)
			node.queue_free()
