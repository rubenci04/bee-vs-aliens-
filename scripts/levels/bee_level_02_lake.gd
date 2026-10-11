extends BeeShmupStage
## NOCHE 01 · ETAPA 4 — Level 02 "Laguna" PROTOTYPE stage (~90 s). Same camera (Level 01 framing E), controls, free aim,
## HUD, toon shots/pickups and liberation as Level 01; its own director (BeeLevel02Controller) and lake scenery.
## Reached from the title screen's debug menu (it does not change the Level 01 flow).

const TOON_BEE_BOLT := preload("res://scenes/levels/bee_level_toon_bolt.tscn")

@onready var section_label: Label = $CanvasLayer/Section
var elapsed_seconds := 0.0
var _victory_seconds := 0.0


func _ready() -> void:
	for leftover in ["Scenery", "Ground", "GroundExtension", "LogObstacle"]: # POC base pieces: the lake has its own.
		var node := get_node_or_null(leftover) as Node3D
		if node != null:
			node.hide()
			for body: CollisionObject3D in node.find_children("*", "CollisionObject3D", true, false):
				body.collision_layer = 0
			if node is CollisionObject3D:
				(node as CollisionObject3D).collision_layer = 0
	for pickup in $Pollen.get_children(): # The POC pollen layout does not fit the lake.
		pickup.queue_free()
	super._ready()
	bee.projectile_scene = TOON_BEE_BOLT
	get_tree().node_added.connect(_on_node_added_lote9, CONNECT_DEFERRED) # LOTE 9: enemy orbs + item beacons.
	for item in find_children("*", "Area3D", true, false):
		if item is BeePowerupPickup or item is BeePollenPickup:
			BeeItemBeacon.attach(item)
	bee.health.damage_scale = BeeGameSettings.damage_taken_scale()
	BeeCombatVFX.toon_bursts = true
	var crosshair := BeeLevel01Crosshair.new()
	crosshair.name = "Crosshair"
	crosshair.bee = bee
	$CanvasLayer.add_child(crosshair)
	bee.global_position.x = BeeLevel01Framing.player_anchor_offset(BeeLevel01Framing.view_aspect(get_viewport()))


func _exit_tree() -> void:
	BeeCombatVFX.toon_bursts = false


func _update_camera_and_bounds() -> void:
	var aspect := BeeLevel01Framing.view_aspect(get_viewport())
	var half_width := BeeLevel01Framing.half_width_min(aspect) - BeeLevel01Framing.FLIGHT_MARGIN
	screen_left = -half_width
	screen_right = half_width if wave != null and (wave as BeeLevel02Controller).boss != null else BeeLevel01Framing.flight_right_offset(aspect)
	flight_top = minf(7.2, BeeLevel01Framing.top_y() - BeeLevel01Framing.FLIGHT_MARGIN)
	flight_bottom = maxf(0.7, BeeLevel01Framing.bottom_y() + BeeLevel01Framing.FLIGHT_MARGIN)
	super._update_camera_and_bounds()
	camera.global_position = Vector3(distance, BeeLevel01Framing.CAMERA_HEIGHT, BeeLevel01Framing.CAMERA_DISTANCE)
	camera.rotation = Vector3(deg_to_rad(BeeLevel01Framing.CAMERA_PITCH_DEGREES), 0.0, 0.0)
	camera.fov = BeeLevel01Framing.CAMERA_FOV


func _physics_process(delta: float) -> void:
	if not bee.is_defeated and not sector_complete:
		elapsed_seconds += delta
	super._physics_process(delta)
	if bee.is_defeated:
		return
	var director := wave as BeeLevel02Controller
	if sector_complete:
		status.text = "LAGUNA DESPEJADA · " + director.liberation_text()
		section_label.text = "PROTOTIPO NIVEL 02 COMPLETADO\nR — JUGAR DE NUEVO" + (" · ENTER — MENÚ" if BeeGameSettings.from_title else "")
		bee.health.damage_blocked = true
		if BeeGameSettings.from_title:
			_victory_seconds += delta
			if _victory_seconds >= BeeGameSettings.RETURN_TO_TITLE_SECONDS or Input.is_action_just_pressed("ui_accept"):
				get_tree().change_scene_to_file(BeeGameSettings.TITLE_SCENE)
		return
	if not wave_clear_announced:
		status.text = "HP %d/%d · LAGUNA (PROTOTIPO)" % [bee.health.current_health, bee.health.max_health]
	section_label.text = director.player_label


func _process(_delta: float) -> void:
	if (bee.is_defeated or sector_complete) and Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()


## LOTE 9: every enemy shot of this level is dressed as the cold cyan / violet orb (BeeShotPalette) and every item that
## appears later (boss supplies, rewards) gets its beacon (BeeItemBeacon).
func _on_node_added_lote9(node: Variant) -> void:
	if not is_instance_valid(node):
		return # Freed before the deferred call (a shot that hit at once).
	BeeShotPalette.on_node_added(node)
	if (node is BeePowerupPickup or node is BeePollenPickup) and (node as Node).is_inside_tree():
		BeeItemBeacon.attach(node)
