extends BeeShmupStage

@onready var level_wave: BeeLevel01Controller = $WaveController
@onready var section_label: Label = $CanvasLayer/Section

var elapsed_seconds := 0.0
@onready var checkpoint: BeeCheckpointQoL = $CheckpointQoL

func _ready() -> void:
	super._ready()
	checkpoint.setup(self)
	if distance < 1.0: # Fresh start: Bee rests at the player anchor (~32 % of the width from the left).
		bee.global_position.x = distance + BeeLevel01Framing.player_anchor_offset(BeeLevel01Framing.view_aspect(get_viewport()))

func _process(_delta: float) -> void:
	# Esc/Shift+R and the defeat R are handled by the always-processing QoL component.
	# After victory R is a full restart (same as Shift+R).
	if sector_complete and not bee.is_defeated and not get_tree().paused \
			and Input.is_action_just_pressed("restart") and not Input.is_action_just_pressed("bee_full_restart"):
		checkpoint.restart_level(true)

func _update_camera_and_bounds() -> void:
	# Flight window = visible area of the Level 01 camera minus a margin (the old fixed
	# +-5.2 / 7.2 bounds are only the outer limit now). Set before the base class uses them.
	var aspect := BeeLevel01Framing.view_aspect(get_viewport())
	var half_width := BeeLevel01Framing.half_width_min(aspect) - BeeLevel01Framing.FLIGHT_MARGIN
	screen_left = -half_width
	screen_right = BeeLevel01Framing.flight_right_offset(aspect) # REBUILD 03: Bee lives in the left ~2/3; the right third reads threats.
	flight_top = minf(7.2, BeeLevel01Framing.top_y() - BeeLevel01Framing.FLIGHT_MARGIN)
	flight_bottom = maxf(0.7, BeeLevel01Framing.bottom_y() + BeeLevel01Framing.FLIGHT_MARGIN)
	super._update_camera_and_bounds()
	camera.global_position = Vector3(distance, BeeLevel01Framing.CAMERA_HEIGHT, BeeLevel01Framing.CAMERA_DISTANCE)
	camera.rotation = Vector3(deg_to_rad(BeeLevel01Framing.CAMERA_PITCH_DEGREES), 0.0, 0.0)
	camera.fov = BeeLevel01Framing.CAMERA_FOV

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
		status.text = "HP %d/%d · POLEN %d/17" % [bee.health.current_health, bee.health.max_health, pollen_count]
	section_label.text = level_wave.player_label

func _secure_victory() -> void:
	# Terminal state: Bee takes no damage and no enemy shot stays in flight.
	bee.health.damage_blocked = true
	for node in find_children("*", "Node3D", true, false):
		if node is AlienEnemyProjectile:
			(node as AlienEnemyProjectile).hitbox.set_enabled(false)
			node.queue_free()
