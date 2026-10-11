extends BeeShmupStage

@onready var level_wave: BeeLevel01Controller = $WaveController
@onready var section_label: Label = $CanvasLayer/Section

var elapsed_seconds := 0.0
## BOSS v2 (combat variety 01): during the NODO ALIEN fight the saucer changes side, so Bee may use the whole width.
var boss_arena_wide := false
var _victory_seconds := 0.0
@onready var checkpoint: BeeCheckpointQoL = $CheckpointQoL

## NOCHE 01 · ETAPA 2 — Codex toon items, shots and explosions (Level 01 only; the POCs keep the old ones).
const TOON_POLLEN := preload("res://scenes/items/toon/pollen.tscn")
const TOON_SPREAD := preload("res://scenes/items/toon/spread.tscn")
const TOON_BOMB := preload("res://scenes/items/toon/bomb.tscn")
const TOON_BEE_BOLT := preload("res://scenes/levels/bee_level_toon_bolt.tscn") # Codex toon bolt + the game hit rules.

func _ready() -> void:
	_swap_toon_pickups() # Before the stage connects the pickups' signals.
	super._ready()
	bee.projectile_scene = TOON_BEE_BOLT
	BeeCombatVFX.toon_bursts = true
	bee.health.damage_scale = BeeGameSettings.damage_taken_scale() # NOCHE 01: EASY = less damage taken.
	checkpoint.setup(self)
	for leftover in ["Ground", "GroundExtension"]: # POC boxes under the mulch slab (coplanar): never visible, never styled.
		var poc_ground := get_node_or_null(leftover) as Node3D
		if poc_ground != null:
			poc_ground.hide()
	var ambient_fx := BeeLevel01AmbientFx.new() # VISUAL POLISH 02: GPU sparks, ground dust, dew glints, haze.
	ambient_fx.name = "AmbientFx"
	add_child(ambient_fx)
	var asset_dressing := BeeLevel01AssetDressing.new() # LOTE 6: signal relays, garden litter, fireflies, night sky (Codex GLB assets).
	asset_dressing.name = "AssetDressing"
	add_child(asset_dressing)
	var crosshair := BeeLevel01Crosshair.new() # LOTE 7: free-aim crosshair (mouse); auto-aim stays when there is no aiming input.
	crosshair.name = "Crosshair"
	crosshair.bee = bee
	$CanvasLayer.add_child(crosshair)
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
	if boss_arena_wide:
		screen_right = half_width
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
		status.text = "SECTOR DESPEJADO · " + level_wave.liberation_text() # NOCHE 01: freed animals n/N.
		section_label.text = "LEVEL 01 COMPLETADO\nR — JUGAR DE NUEVO"
		_secure_victory()
		if BeeGameSettings.from_title:
			# NOCHE 01 · ETAPA 2: back to the title (Enter, or after RETURN_TO_TITLE_SECONDS); R still replays.
			section_label.text = "LEVEL 01 COMPLETADO\nR — JUGAR DE NUEVO · ENTER — MENÚ"
			_victory_seconds += delta
			if _victory_seconds >= BeeGameSettings.RETURN_TO_TITLE_SECONDS or Input.is_action_just_pressed("ui_accept"):
				get_tree().change_scene_to_file(BeeGameSettings.TITLE_SCENE)
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

func _exit_tree() -> void:
	BeeCombatVFX.toon_bursts = false # Static: never leak the Level 01 look into POCs or tests that load other scenes.

## Same names, positions and settings (the checkpoint snapshot finds them by name); only the scene changes.
func _swap_toon_pickups() -> void:
	for pair in [["Pollen", true], ["Powerups", false]]:
		var parent := get_node(str(pair[0]))
		for old in parent.get_children():
			var fresh: Node3D
			if bool(pair[1]):
				fresh = TOON_POLLEN.instantiate() as Node3D
				fresh.set("heal_amount", old.get("heal_amount"))
			else:
				var is_bomb: bool = int(old.get("kind")) == BeePowerupPickup.Kind.BOMB
				fresh = (TOON_BOMB if is_bomb else TOON_SPREAD).instantiate() as Node3D
				fresh.set("kind", old.get("kind"))
				fresh.set("overcharge", old.get("overcharge"))
			var label := str(old.name)
			var where := (old as Node3D).transform
			parent.remove_child(old)
			old.free()
			fresh.name = label
			fresh.transform = where
			parent.add_child(fresh)
