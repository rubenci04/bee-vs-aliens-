extends BeeShmupStage

@onready var level_wave: BeeLevel01Controller = $WaveController
@onready var section_label: Label = $CanvasLayer/Section

var elapsed_seconds := 0.0
## BOSS v2 (combat variety 01): during the NODO ALIEN fight the saucer changes side, so Bee may use the whole width.
var boss_arena_wide := false
var _victory_seconds := 0.0
var clear_banner: Label # LOTE 9: "SECTOR DESPEJADO · LIBERADOS n/N" in the middle of the screen.
@onready var checkpoint: BeeCheckpointQoL = $CheckpointQoL

## NOCHE 01 · ETAPA 2 — Codex toon items, shots and explosions (Level 01 only; the POCs keep the old ones).
const TOON_POLLEN := preload("res://scenes/items/toon/pollen.tscn")
const TOON_SPREAD := preload("res://scenes/items/toon/spread.tscn")
const TOON_BOMB := preload("res://scenes/items/toon/bomb.tscn")
const TOON_BEE_BOLT := preload("res://scenes/levels/bee_level_toon_bolt.tscn") # Codex toon bolt + the game hit rules.
const TOON_HEALING := preload("res://scenes/items/toon/healing.tscn")
## LOTE 9 · ETAPA B — supply right before the X=340 last-defence gate: a bomb pickup (+3 bombs) and a honey jar (heals
## when hurt). [x, y] per item; it is part of the level (a respawn at the X=281 checkpoint finds it again; the boss
## checkpoint is past it, so it can never be farmed).
const PREBOSS_SUPPLY := {"bomb": Vector2(337.0, 3.8), "healing": Vector2(338.8, 2.6)}

func _ready() -> void:
	_swap_toon_pickups() # Before the stage connects the pickups' signals.
	super._ready()
	bee.projectile_scene = TOON_BEE_BOLT
	get_tree().node_added.connect(_on_node_added_lote9, CONNECT_DEFERRED) # LOTE 9: enemy orbs + item beacons.
	for item in find_children("*", "Area3D", true, false):
		if item is BeePowerupPickup or item is BeePollenPickup:
			BeeItemBeacon.attach(item)
	BeeCombatVFX.toon_bursts = true
	bee.health.damage_scale = BeeGameSettings.damage_taken_scale() # NOCHE 01: EASY = less damage taken.
	checkpoint.setup(self)
	_place_preboss_supply()
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
	var readability := BeeLevel01Readability.new() # NOCHE 01 · ETAPA 3: clean central corridor (after the decoration).
	readability.name = "Readability"
	add_child(readability)
	var crosshair := BeeLevel01Crosshair.new() # LOTE 7: free-aim crosshair (mouse); auto-aim stays when there is no aiming input.
	crosshair.name = "Crosshair"
	crosshair.bee = bee
	$CanvasLayer.add_child(crosshair)
	var juice := BeeLevel01Juice.new() # LOTE 11: combo, honey mode, hit stop, damage shake, item magnet.
	juice.name = "Juice"
	add_child(juice)
	var foreground := BeeLevel01Foreground.new() # LOTE 11 C4: out-of-focus grass layers in front of Bee.
	foreground.name = "Foreground"
	add_child(foreground)
	var speed_lines := BeeLevel01SpeedLines.new() # LOTE 11 C4: streaks while Bee rolls.
	speed_lines.name = "SpeedLines"
	speed_lines.bee = bee
	$CanvasLayer.add_child(speed_lines)
	var watering := BeeLevel01WateringEvent.new() # LOTE 11 C5: water columns near the giant watering can.
	watering.name = "WateringEvent"
	add_child(watering)
	if distance < 1.0: # Fresh start: Bee rests at the player anchor (~32 % of the width from the left).
		bee.global_position.x = distance + BeeLevel01Framing.player_anchor_offset(BeeLevel01Framing.view_aspect(get_viewport()))

func _process(_delta: float) -> void:
	# Esc/Shift+R and the defeat R are handled by the always-processing QoL component.
	# After victory R is a full restart (same as Shift+R).
	if sector_complete and not bee.is_defeated and not get_tree().paused \
			and Input.is_action_just_pressed("restart") and not Input.is_action_just_pressed("bee_full_restart"):
		checkpoint.restart_level(true)

func _update_camera_and_bounds() -> void:
	# Use 95 % of the visible width with equal margins; vertical framing remains independently bounded.
	var aspect := BeeLevel01Framing.view_aspect(get_viewport())
	screen_left = BeeLevel01Framing.flight_left_offset(aspect)
	screen_right = BeeLevel01Framing.flight_right_offset(aspect)
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
		if clear_banner == null:
			_show_clear_banner() # LOTE 9: the big closing card after the UFO explosion.
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


## LOTE 9: every enemy shot of this level is dressed as the cold cyan / violet orb (BeeShotPalette) and every item that
## appears later (boss supplies, rewards) gets its beacon (BeeItemBeacon).
func _on_node_added_lote9(node: Variant) -> void:
	if not is_instance_valid(node):
		return # Freed before the deferred call (a shot that hit at once).
	BeeShotPalette.on_node_added(node)
	if (node is BeePowerupPickup or node is BeePollenPickup) and (node as Node).is_inside_tree():
		BeeItemBeacon.attach(node)

## LOTE 9 · ETAPA B: the pre-boss supply (PREBOSS_SUPPLY), skipped when the level resumes past it.
func _place_preboss_supply() -> void:
	if distance > float(PREBOSS_SUPPLY["healing"].x):
		return
	var group := Node3D.new()
	group.name = "PreBossSupply"
	add_child(group)
	var bomb := TOON_BOMB.instantiate() as Node3D
	bomb.name = "SupplyBomb"
	bomb.set("kind", BeePowerupPickup.Kind.BOMB)
	group.add_child(bomb)
	bomb.global_position = Vector3(PREBOSS_SUPPLY["bomb"].x, PREBOSS_SUPPLY["bomb"].y, 0.0)
	var jar := TOON_HEALING.instantiate() as Node3D
	jar.name = "SupplyHealing"
	group.add_child(jar)
	jar.global_position = Vector3(PREBOSS_SUPPLY["healing"].x, PREBOSS_SUPPLY["healing"].y, 0.0)

## LOTE 9 · ETAPA C: the closing card (big, centred, pops in) once the UFO explosion is over.
func _show_clear_banner() -> void:
	clear_banner = Label.new()
	clear_banner.name = "ClearBanner"
	clear_banner.text = "SECTOR DESPEJADO · " + level_wave.liberation_text() + "\n" + ($Juice as BeeLevel01Juice).summary_text()
	clear_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clear_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	clear_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	clear_banner.offset_bottom = -120.0
	clear_banner.add_theme_font_size_override("font_size", 46)
	clear_banner.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	clear_banner.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.02))
	clear_banner.add_theme_constant_override("outline_size", 10)
	clear_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clear_banner.modulate.a = 0.0
	$CanvasLayer.add_child(clear_banner)
	clear_banner.pivot_offset = get_viewport().get_visible_rect().size * 0.5
	clear_banner.scale = Vector2.ONE * 1.25
	var pop := clear_banner.create_tween().set_parallel(true)
	pop.tween_property(clear_banner, "modulate:a", 1.0, 0.35)
	pop.tween_property(clear_banner, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
