extends BeeShmupStage

@onready var level_wave: BeeLevel01Controller = $WaveController
@onready var section_label: Label = $CanvasLayer/Section

var elapsed_seconds := 0.0
@onready var checkpoint: BeeCheckpointQoL = $CheckpointQoL

func _ready() -> void:
	super._ready()
	checkpoint.setup(self)

func _process(_delta: float) -> void:
	pass # Level-only R/Esc/Shift+R handled by the always-processing QoL component.

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
		section_label.text = "LEVEL 01 COMPLETADO"
		return
	if not wave_clear_announced:
		status.text = "HP %d/%d · POLEN %d/17 · WASD/FLECHAS VOLAR · X DISPARO · Z MELEE" % [bee.health.current_health, bee.health.max_health, pollen_count]
	section_label.text = level_wave.encounter_label
