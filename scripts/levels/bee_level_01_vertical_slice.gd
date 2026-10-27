extends BeeShmupStage

@onready var level_wave: BeeLevel01Controller = $WaveController
@onready var section_label: Label = $CanvasLayer/Section

var elapsed_seconds := 0.0
## BOSS v2 (combat variety 01): during the NODO ALIEN fight the saucer changes side, so Bee may use the whole width.
var boss_arena_wide := false
var _victory_seconds := 0.0
var _robot_arena_weight := 0.0
var clear_banner: Label # LOTE 9: "SECTOR DESPEJADO · LIBERADOS n/N" in the middle of the screen.
@onready var checkpoint: BeeCheckpointQoL = $CheckpointQoL

## NOCHE 01 · ETAPA 2 — Codex toon items, shots and explosions (Level 01 only; the POCs keep the old ones).
const TOON_POLLEN := preload("res://scenes/items/toon/pollen.tscn")
const TOON_SPREAD := preload("res://scenes/items/toon/spread.tscn")
const TOON_BOMB := preload("res://scenes/items/toon/bomb.tscn")
const TOON_BEE_BOLT := preload("res://scenes/levels/bee_level_toon_bolt.tscn") # Codex toon bolt + the game hit rules.
const TOON_HEALING := preload("res://scenes/items/toon/pollen_cluster.tscn") # LOTE 13: pollen cluster (was the honey jar).
## LOTE 9 · ETAPA B — supply right before the X=340 last-defence gate: a bomb pickup (+3 bombs) and a honey jar (heals
## when hurt). [x, y] per item; it is part of the level (a respawn at the X=281 checkpoint finds it again; the boss
## checkpoint is past it, so it can never be farmed).
const PREBOSS_SUPPLY := {"bomb": Vector2(337.0, 3.8), "healing": Vector2(338.8, 2.6)}
## LOTE 12 · ETAPA 2 (roster only): the supply right before the walking-robot gate (X=290) and the BREATHING VALLEY supplies after
## checkpoint 1 (X=190): [kind, x, y] - honey jars heal, the bomb capsule gives +3 bombs.
const ROSTER_GATE_SUPPLY := {"bomb": Vector2(285.5, 3.8), "healing": Vector2(287.3, 2.6)}
## LOTE 13 · ETAPA 1: loose pollen clusters along the route ([x, y]; each is CLUSTER_VALUE pollen; skipped once the level resumes past them).
## LOTE 14 · ETAPA 2.2: 12 clusters of 10 pollen (half a bar of 20), all from the second half of the level (X>=148) where the damage starts; the loose scene pollen is halved too (every LOOSE_POLLEN_KEEP_EVERY-th pickup stays).
const POLLEN_CLUSTERS := [[148.0, 4.0], [162.0, 3.4], [176.0, 4.4], [190.0, 3.0], [204.0, 4.0], [218.0, 3.4], [232.0, 4.4], [246.0, 3.0], [258.0, 4.0], [268.0, 3.4], [276.0, 4.4], [281.0, 3.0]]
const LOOSE_POLLEN_KEEP_EVERY := 2
const VALLEY_SUPPLY := [["healing", 192.5, 2.8], ["bomb", 196.0, 3.8], ["healing", 200.0, 2.6]]

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
	if BeeLevel01Controller.roster_only:
		var mushrooms := BeeLevel01GardenMushrooms.new() # LOTE 12: destructible garden mushrooms that drop pollen.
		mushrooms.name = "GardenMushrooms"
		add_child(mushrooms)
		var anthills := BeeLevel01Anthills.new() # LOTE 13: anthills the ants come out of.
		anthills.name = "Anthills"
		add_child(anthills)
	checkpoint.setup(self)
	BeeMusic.play_level_from_start() # LOTE 14: the Level 1 theme loops from the start (a restart plays it again; it crossfades from the title).
	_place_preboss_supply()
	_place_valley_supply()
	_place_pollen_clusters()
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
	var live_readability := preload("res://scripts/levels/bee_live_readability.gd").new()
	live_readability.name = "LiveReadability"
	add_child(live_readability)
	if distance < 1.0: # Fresh start: Bee rests at the player anchor (~32 % of the width from the left).
		bee.global_position.x = distance + BeeLevel01Framing.player_anchor_offset(BeeLevel01Framing.view_aspect(get_viewport()))
	preload("res://scripts/game/bee_scene_fade.gd").enter(self)

func _process(_delta: float) -> void:
	pass # ResultsScreen owns replay/menu input in the terminal state.

func _update_camera_and_bounds() -> void:
	var robot := level_wave.miniboss if is_instance_valid(level_wave) else null
	var desired := 1.0 if is_instance_valid(robot) and robot.health.current_health > 0 else 0.0
	_robot_arena_weight = move_toward(_robot_arena_weight, desired, get_physics_process_delta_time() / BeeLevel01Framing.ROBOT_TRANSITION_SECONDS)
	BeeLevel01Framing.robot_arena_weight = _robot_arena_weight
	# Use 95 % of the visible width with equal margins; vertical framing remains independently bounded.
	var aspect := BeeLevel01Framing.view_aspect(get_viewport())
	screen_left = BeeLevel01Framing.flight_left_offset(aspect)
	screen_right = BeeLevel01Framing.flight_right_offset(aspect)
	flight_top = minf(7.2, BeeLevel01Framing.top_y() - BeeLevel01Framing.FLIGHT_MARGIN)
	flight_bottom = maxf(0.7, BeeLevel01Framing.bottom_y() + BeeLevel01Framing.FLIGHT_MARGIN)
	super._update_camera_and_bounds()
	camera.global_position = Vector3(distance, BeeLevel01Framing.effective_height(), BeeLevel01Framing.CAMERA_DISTANCE)
	camera.rotation = Vector3(deg_to_rad(BeeLevel01Framing.CAMERA_PITCH_DEGREES), 0.0, 0.0)
	camera.fov = BeeLevel01Framing.effective_fov()

func _on_bee_defeated() -> void:
	super._on_bee_defeated()
	BeeMusic.fade_out() # LOTE 14: the music fades out when Bee is defeated.
	checkpoint.defeat_hint()

func _physics_process(delta: float) -> void:
	if not bee.is_defeated and not sector_complete:
		elapsed_seconds += delta
	super._physics_process(delta)
	if bee.is_defeated:
		return
	if sector_complete:
		_secure_victory()
		if not has_node("ResultsScreen"):
			_show_clear_banner()
		return
	if not wave_clear_announced:
		status.text = "HP %d/%d" % [bee.health.current_health, bee.health.max_health] # LOTE 13: the pollen bar has its own line (BeeLevel01Juice).
	section_label.text = level_wave.player_label

func _secure_victory() -> void:
	# Terminal state: Bee takes no damage and no enemy shot stays in flight.
	bee.health.damage_blocked = true
	for node in find_children("*", "Node3D", true, false):
		if node is AlienEnemyProjectile:
			(node as AlienEnemyProjectile).hitbox.set_enabled(false)
			node.queue_free()

func _exit_tree() -> void:
	BeeLevel01Framing.robot_arena_weight = 0.0
	BeeCombatVFX.toon_bursts = false # Static: never leak the Level 01 look into POCs or tests that load other scenes.

## Same names, positions and settings (the checkpoint snapshot finds them by name); only the scene changes.
func _swap_toon_pickups() -> void:
	_thin_loose_pollen()
	for pair in [["Pollen", true], ["Powerups", false]]:
		var parent := get_node(str(pair[0]))
		for old in parent.get_children():
			var fresh: Node3D
			if bool(pair[1]):
				fresh = TOON_POLLEN.instantiate() as Node3D
				fresh.set("heal_amount", BeeLevel01Juice.POLLEN_INSTANT_HEAL) # LOTE 13: pollen fills the bar, it does not heal at once.
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
			if BeeLevel01Controller.roster_only and label == "PrebossPower":
				fresh.position.x = BeeLevel01Controller.PREBOSS_POWER_X
			if BeeLevel01Controller.roster_only and label == "BombRecharge":
				fresh.position.x = BeeLevel01Controller.BOMB_RECHARGE_X
			parent.add_child(fresh)


## LOTE 9: every enemy shot of this level is dressed as the cold cyan / violet orb (BeeShotPalette) and every item that
## appears later (boss supplies, rewards) gets its beacon (BeeItemBeacon).
func _on_node_added_lote9(node: Variant) -> void:
	if not is_instance_valid(node):
		return # Freed before the deferred call (a shot that hit at once).
	BeeShotPalette.on_node_added(node)
	if (node is BeePowerupPickup or node is BeePollenPickup) and (node as Node).is_inside_tree():
		if node is BeePowerupPickup:
			preload("res://scripts/items/bee_pickup_medallion.gd").dress_old(node)
		BeeItemBeacon.attach(node)

## LOTE 9 · ETAPA B: the pre-boss supply (PREBOSS_SUPPLY), skipped when the level resumes past it.
func _place_preboss_supply() -> void:
	var supply: Dictionary = ROSTER_GATE_SUPPLY if BeeLevel01Controller.roster_only else PREBOSS_SUPPLY
	if distance > float(supply["healing"].x):
		return
	var group := Node3D.new()
	group.name = "PreBossSupply"
	add_child(group)
	var bomb := TOON_BOMB.instantiate() as Node3D
	bomb.name = "SupplyBomb"
	bomb.set("kind", BeePowerupPickup.Kind.BOMB)
	group.add_child(bomb)
	bomb.global_position = Vector3(supply["bomb"].x, supply["bomb"].y, 0.0)
	var jar := TOON_HEALING.instantiate() as Node3D
	jar.name = "SupplyHealing"
	group.add_child(jar)
	jar.global_position = Vector3(supply["healing"].x, supply["healing"].y, 0.0)

## LOTE 12: the breathing valley of checkpoint 1 - honey jars and a bomb capsule on the way (skipped once passed).
func _place_valley_supply() -> void:
	if not BeeLevel01Controller.roster_only:
		return
	var group := Node3D.new()
	group.name = "ValleySupply"
	add_child(group)
	var index := 0
	for entry in VALLEY_SUPPLY:
		if distance > float(entry[1]):
			continue
		var item := (TOON_BOMB if entry[0] == "bomb" else TOON_HEALING).instantiate() as Node3D
		if entry[0] == "bomb":
			item.set("kind", BeePowerupPickup.Kind.BOMB)
		item.name = "Valley%s%d" % [str(entry[0]).capitalize(), index]
		index += 1
		group.add_child(item)
		item.global_position = Vector3(float(entry[1]), float(entry[2]), 0.0)

## LOTE 9 · ETAPA C: the closing card (big, centred, pops in) once the UFO explosion is over.
func _show_clear_banner() -> void:
	if has_node("ResultsScreen"): return
	bee.set_physics_process(false)
	bee.hide()
	for layer in find_children("*","CanvasLayer",true,false): layer.hide()
	var results := preload("res://scenes/game/bee_results_screen.tscn").instantiate()
	results.released=level_wave.liberated_count
	results.total=level_wave.animals_total
	results.score=($Juice as BeeLevel01Juice).score
	results.combo=($Juice as BeeLevel01Juice).best_combo
	add_child(results)
	clear_banner=Label.new() # Compatibility handle for old review tools; no world text.
	clear_banner.name="ClearBanner"
	clear_banner.hide()
	results.add_child(clear_banner)

func _layout_victory_title() -> void:
	section_label.set_anchors_preset(Control.PRESET_CENTER)
	section_label.offset_left = -450.0
	section_label.offset_right = 450.0
	section_label.offset_top = BeeGameSettings.HUD_VICTORY_TITLE_TOP
	section_label.offset_bottom = BeeGameSettings.HUD_VICTORY_TITLE_BOTTOM
	section_label.add_theme_font_size_override("font_size", 28)
	section_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	section_label.z_index = 2
	if checkpoint.controls_hint != null:
		checkpoint.controls_hint.hide()

## LOTE 13: pollen clusters on the way (a respawn finds the ones ahead of it again, like the valley supplies).
func _place_pollen_clusters() -> void:
	if not BeeLevel01Controller.roster_only:
		return
	var group := Node3D.new()
	group.name = "PollenClusters"
	add_child(group)
	var index := 0
	for entry in POLLEN_CLUSTERS:
		if distance > float(entry[0]):
			continue
		var item := TOON_HEALING.instantiate() as Node3D
		item.name = "PollenCluster%d" % index
		index += 1
		group.add_child(item)
		item.global_position = Vector3(float(entry[0]), float(entry[1]), 0.0)


## LOTE 14 · ETAPA 2.2: pollen is scarce - only every LOOSE_POLLEN_KEEP_EVERY-th scene pollen pickup stays (roster Level 1 only).
func _thin_loose_pollen() -> void:
	if not BeeLevel01Controller.roster_only:
		return
	var parent := get_node("Pollen")
	var index := 0
	for old in parent.get_children():
		if index % LOOSE_POLLEN_KEEP_EVERY != 0:
			parent.remove_child(old)
			old.free()
		index += 1
