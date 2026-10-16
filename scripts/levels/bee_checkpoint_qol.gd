class_name BeeCheckpointQoL
extends Node
const HUD_NOTICES := preload("res://scripts/ui/bee_hud_notices.gd")
const HUD_TEXT := preload("res://scripts/game/bee_hud_text_settings.gd")

const HANDOFF := &"bee_level_01_checkpoint_handoff"
const CHECKPOINT_FLOWER := preload("res://scenes/decoration/recovered_garden_rose.tscn")
## UFO BOSS 01: the fight has its own checkpoint (taken when the boss starts) and a debug jump (F9) straight to it.
const BOSS_ARENA_X := 340.5
const BEACON_COLOR := Color(0.96, 0.7, 0.22)
@export var checkpoint_x := 190.0
## Breakable rocks and (LOTE 12) the garden mushrooms: both are BreakableRock and both keep their broken state across a respawn.
func _rock_nodes() -> Array[Node]:
	var nodes: Array[Node] = []
	nodes.append_array(get_tree().get_nodes_in_group("breakable_rocks"))
	nodes.append_array(get_tree().get_nodes_in_group("garden_mushrooms"))
	return nodes

## LOTE 7: second checkpoint, in act 4 after the third combat zone and the contaminated flower (X=266), before the 296 gate.
@export var second_checkpoint_x := 281.0
var second_checkpoint_active := false
var beacon_2: Node3D
@export var protection_seconds := 1.25
var checkpoint_active := false
var snapshot: Dictionary = {}
var protection_left := 0.0
var activation_count := 0
var stage: BeeShmupStage
var notice: Label
var pause_label: Label
var pause_panel: PanelContainer ## LOTE 14 · ETAPA 4: music and effects sliders, shown while paused.
var music_slider: HSlider
var sfx_slider: HSlider
var controls_hint: Label
var beacon: Node3D
var _notice_left := 0.0
var _hint_left := 0.0
var debug_active := false
var boss_checkpoint_count := 0
var _f9_was_down := false
var debug_label: Label

func setup(value: BeeShmupStage) -> void:
	stage = value
	process_mode = Node.PROCESS_MODE_ALWAYS
	notice = label("CheckpointNotice", "", Vector2(430, 52), 28)
	pause_label = label("PauseNotice", "PAUSED · ESC", Vector2(420, 275), 32)
	_build_pause_panel()
	controls_hint = label("ControlsHint", "", Vector2(18, 212), 18)
	debug_label = label("DebugNotice", "DEBUG · SALTO AL JEFE (F9) — NO ES EL JUEGO NORMAL", Vector2(300, 8), 20)
	debug_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.2))
	debug_label = label("DebugNotice", "DEBUG · SALTO AL JEFE (F9) · NO ES EL JUEGO NORMAL", Vector2(330, 6), 20)
	debug_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2))
	debug_label.add_theme_color_override("font_outline_color", Color.BLACK)
	debug_label.add_theme_constant_override("outline_size", 6)
	create_beacon()
	beacon_2 = beacon.duplicate() as Node3D
	beacon_2.name = "CheckpointBeacon2"
	stage.add_child(beacon_2)
	beacon_2.position = Vector3(second_checkpoint_x, 0, -1.3)
	var stem := beacon_2.get_node("BeaconStem") as MeshInstance3D
	beacon_2.remove_child(stem)
	stem.queue_free()
	var flower := CHECKPOINT_FLOWER.instantiate() as Node3D
	flower.name = "CheckpointFlower"
	flower.position = Vector3(0.0, 0.0, BeeGameSettings.CHECKPOINT_2_FLOWER_Z + 1.3)
	flower.scale = Vector3.ONE * BeeGameSettings.CHECKPOINT_2_FLOWER_SCALE
	beacon_2.add_child(flower)
	BeeToonStyle.apply(flower, true, BeeToonStyle.OUTLINE_PROP)
	if get_tree().has_meta(HANDOFF):
		snapshot = get_tree().get_meta(HANDOFF).duplicate(true)
		get_tree().remove_meta(HANDOFF) # One-use handoff, never a save or singleton.
		restore_snapshot()

## LOTE 14 · ETAPA 4: the pause menu has a music slider and an effects slider (0..100 %, 100 % = the default level of each bus).
func _build_pause_panel() -> void:
	pause_panel = PanelContainer.new()
	pause_panel.name = "PausePanel"
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_panel.position = Vector2(400, 330)
	pause_panel.custom_minimum_size = Vector2(480, 0)
	pause_panel.visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	pause_panel.add_child(box)
	music_slider = _slider_row(box, "MÚSICA", BeeGameSettings.music_volume, BeeMusic.set_music_volume)
	sfx_slider = _slider_row(box, "EFECTOS", BeeGameSettings.sfx_volume, BeeMusic.set_sfx_volume)
	var hint := Label.new()
	hint.text = "NOVA DE POLEN: Q / LT (L2) · 20/20\nBorra balas cercanas y daña en área.\nFLECHAS: AJUSTAR · ARRIBA/ABAJO: CAMBIAR · ESC: SEGUIR"
	hint.add_theme_font_size_override("font_size", 14)
	box.add_child(hint)
	stage.get_node("CanvasLayer").add_child(pause_panel)


func _slider_row(box: VBoxContainer, title: String, value: float, on_change: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name_label := Label.new()
	name_label.text = title
	name_label.custom_minimum_size = Vector2(110, 0)
	name_label.add_theme_font_size_override("font_size", 20)
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(250, 24)
	slider.focus_mode = Control.FOCUS_ALL
	slider.process_mode = Node.PROCESS_MODE_ALWAYS
	row.add_child(slider)
	var percent := Label.new()
	percent.text = "%d %%" % roundi(value * 100.0)
	percent.custom_minimum_size = Vector2(60, 0)
	percent.add_theme_font_size_override("font_size", 20)
	row.add_child(percent)
	slider.value_changed.connect(func(v: float):
		percent.text = "%d %%" % roundi(v * 100.0)
		on_change.call(v))
	box.add_child(row)
	return slider


func label(node_name: String, text: String, point: Vector2, size: int) -> Label:
	var node := Label.new()
	node.name = node_name
	node.text = text
	node.position = point
	node.add_theme_font_size_override("font_size", size)
	node.hide()
	stage.get_node("CanvasLayer").add_child(node)
	return node

func create_beacon() -> void:
	beacon = Node3D.new()
	beacon.name = "CheckpointBeacon"
	stage.add_child(beacon)
	beacon.position = Vector3(checkpoint_x, 0, -1.3)
	var material := StandardMaterial3D.new()
	material.albedo_color = BEACON_COLOR # NOCHE 01 · ETAPA 3: honey, not cyan (cyan is alien technology only).
	var post := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.18, 1.7, 0.18)
	box.material = material
	post.mesh = box
	post.name = "BeaconStem"
	post.position.y = 0.85
	beacon.add_child(post)
	BeeToonStyle.apply(post, true, BeeToonStyle.OUTLINE_PROP)

func _process(delta: float) -> void:
	if stage == null or stage.sector_complete:
		return
	if Input.is_action_just_pressed("bee_full_restart"):
		restart_level(true)
		return
	if Input.is_action_just_pressed("bee_pause") or (get_tree().paused and Input.is_action_just_pressed("ui_cancel")):
		get_tree().paused = not get_tree().paused
		pause_label.visible = get_tree().paused
		BeeMusic.set_paused(get_tree().paused) # LOTE 14: the music ducks while paused.
		pause_panel.visible = get_tree().paused
		if pause_panel.visible:
			music_slider.grab_focus()
	var f9_down := Input.is_action_pressed("bee_debug_boss")
	if f9_down and not _f9_was_down and not get_tree().paused:
		_f9_was_down = true
		debug_jump_to_boss()
		return
	_f9_was_down = f9_down
	if get_tree().paused:
		return
	if stage.bee.is_defeated:
		if Input.is_action_just_pressed("restart"):
			restart_level(false)
		return
	if not checkpoint_active and stage.distance >= checkpoint_x and not stage.wave._waiting_for_human:
		activate_checkpoint()
	elif checkpoint_active and not second_checkpoint_active and stage.distance >= second_checkpoint_x and not stage.wave.in_arena():
		activate_second_checkpoint()
	_notice_left = maxf(0.0, _notice_left - delta)
	notice.hide() # All notices share the upper banner lane.
	_hint_left = maxf(0.0, _hint_left - delta)
	controls_hint.visible = _hint_left > 0.0
	if protection_left > 0.0:
		protection_left = maxf(0.0, protection_left - delta)
		stage.bee.visual_root.visible = protection_left == 0.0 or int(protection_left * 10) % 2 == 0
		stage.bee.health.damage_blocked = protection_left > 0.0

func checkpoint_list() -> Array:
	return [checkpoint_x, second_checkpoint_x]

func available_names(parent_name: String) -> Array[String]:
	var result: Array[String] = []
	for node in stage.get_node(parent_name).get_children():
		if not node.is_queued_for_deletion():
			result.append(str(node.name))
	return result

func activate_checkpoint() -> void:
	if checkpoint_active or stage.bee.is_defeated:
		return
	checkpoint_active = true
	activation_count += 1
	var bee := stage.bee
	var minimum := ceili(bee.health.max_health * 0.6)
	bee.health.restore_health(maxi(0, minimum - bee.health.current_health))
	var broken: Array[String] = []
	for surface: ImpactSurface in get_tree().get_nodes_in_group("bee_destructibles"):
		if stage.is_ancestor_of(surface) and surface.is_destroyed:
			broken.append(str(surface.name))
	for crate in stage.get_node("Destructibles").get_children():
		if crate.position.x < checkpoint_x and crate.is_destroyed:
			broken.append(str(crate.name))
	for rock: BreakableRock in _rock_nodes():
		if stage.is_ancestor_of(rock) and rock.global_position.x < checkpoint_x and rock.is_destroyed:
			broken.append(str(rock.name))
	snapshot = {"distance": checkpoint_x, "bee_position": Vector3(checkpoint_x, 5.4, 0),
		"hp": bee.health.current_health, "spread": bee.spread_ammo, "bomb": bee.bomb_charges,
		"pollen": stage.pollen_count, "pollen_available": available_names("Pollen"),
		"powerups_available": available_names("Powerups"), "broken": broken,
		"elapsed": stage.elapsed_seconds, "taught": stage.get_node("CanvasLayer/WeaponsHUD").taught.duplicate(true),
		"animals": stage.wave.animals_total, "liberated": stage.wave.liberated_count}
	notice.text = "CHECKPOINT"
	_notice_left = HUD_TEXT.CHECKPOINT_SECONDS
	HUD_NOTICES.for_host(self).show_notice(notice.text, HUD_TEXT.CHECKPOINT_SECONDS, "checkpoint")
	BeeAudio.play(stage, &"spread_pickup", beacon.global_position + Vector3(0, 1.8, 0))


## LOTE 7: second checkpoint (same rules as the first: HP back to at least 60 %, run state saved).
func activate_second_checkpoint() -> void:
	if second_checkpoint_active or stage.bee.is_defeated:
		return
	second_checkpoint_active = true
	activation_count += 1
	var bee := stage.bee
	var minimum := ceili(bee.health.max_health * 0.6)
	bee.health.restore_health(maxi(0, minimum - bee.health.current_health))
	snapshot = _build_snapshot(second_checkpoint_x, Vector3(second_checkpoint_x, 5.4, 0), second_checkpoint_x, second_checkpoint_x)
	notice.text = "CHECKPOINT 2"
	_notice_left = HUD_TEXT.CHECKPOINT_SECONDS
	HUD_NOTICES.for_host(self).show_notice(notice.text, HUD_TEXT.CHECKPOINT_SECONDS, "checkpoint")
	BeeAudio.play(stage, &"spread_pickup", beacon_2.global_position + Vector3(0, 1.8, 0))
## Snapshot of the current run state. `limit`: pollen / powerups / crates left of it count as already gone.
func _build_snapshot(distance: float, bee_position: Vector3, limit: float, keep_from: float) -> Dictionary:
	var bee := stage.bee
	var broken: Array[String] = []
	for surface: ImpactSurface in get_tree().get_nodes_in_group("bee_destructibles"):
		if stage.is_ancestor_of(surface) and surface.is_destroyed:
			broken.append(str(surface.name))
	for crate in stage.get_node("Destructibles").get_children():
		if crate.position.x < limit and crate.is_destroyed:
			broken.append(str(crate.name))
	for rock: BreakableRock in _rock_nodes():
		if stage.is_ancestor_of(rock) and rock.global_position.x < limit and rock.is_destroyed:
			broken.append(str(rock.name))
	return {"distance": distance, "bee_position": bee_position,
		"hp": bee.health.current_health, "spread": bee.spread_ammo, "bomb": bee.bomb_charges,
		"pollen": stage.pollen_count, "pollen_available": available_names("Pollen"),
		"powerups_available": available_names("Powerups"), "broken": broken, "keep_from": keep_from,
		"elapsed": stage.elapsed_seconds, "taught": stage.get_node("CanvasLayer/WeaponsHUD").taught.duplicate(true),
		"animals": stage.wave.animals_total, "liberated": stage.wave.liberated_count}

## UFO BOSS 01: called by the director the moment the boss fight starts. Retrying after a defeat respawns here (not at
## X=190) with the same minimum HP as the normal checkpoint (60 %).
func activate_boss_checkpoint() -> void:
	var bee := stage.bee
	if bee.is_defeated:
		return
	var minimum := ceili(bee.health.max_health * 0.6)
	bee.health.restore_health(maxi(0, minimum - bee.health.current_health))
	var was_debug := debug_active
	snapshot = _build_snapshot(stage.distance + 0.25, Vector3(stage.distance - 3.0, 3.4, 0), 1.0e9, -1.0e9)
	snapshot["debug"] = was_debug
	checkpoint_active = true
	boss_checkpoint_count += 1
	snapshot["boss_attempts"] = boss_checkpoint_count # BOSS v2: the entry side alternates between attempts.

## DEBUG (F9): reload Level 01 at the start of the boss fight with the normal loadout there (Base weapon, 2 bombs, full HP), to test it without playing the level.
func debug_jump_to_boss() -> void:
	var bee := stage.bee
	var arena := BOSS_ARENA_X
	var from := arena - 8.0
	snapshot = {"distance": arena, "bee_position": Vector3(arena - 3.0, 3.4, 0), "hp": bee.health.max_health,
		"spread": 0, "bomb": 2, "pollen": stage.pollen_count, "pollen_available": [], "powerups_available": [],
		"broken": [], "keep_from": from, "elapsed": stage.elapsed_seconds, "debug": true,
		"taught": stage.get_node("CanvasLayer/WeaponsHUD").taught.duplicate(true)}
	for pair in [["Pollen", "pollen_available"], ["Powerups", "powerups_available"]]:
		for item in stage.get_node(pair[0]).get_children():
			if item.position.x >= from:
				snapshot[pair[1]].append(str(item.name))
	get_tree().paused = false
	get_tree().set_meta(HANDOFF, snapshot.duplicate(true))
	get_tree().reload_current_scene()

func restore_snapshot() -> void:
	checkpoint_active = true
	activation_count = 1
	second_checkpoint_active = float(snapshot["distance"]) >= second_checkpoint_x - 0.01
	stage.distance = snapshot["distance"]
	stage.elapsed_seconds = snapshot["elapsed"]
	stage.pollen_count = snapshot["pollen"]
	stage._update_camera_and_bounds()
	var light_progression := stage.get_node_or_null("LightProgression") as BeeLevel01LightProgression
	if light_progression != null:
		light_progression.apply_distance(stage.distance)
	var bee := stage.bee
	bee.global_position = snapshot["bee_position"]
	bee.velocity = Vector3.ZERO
	bee.health.current_health = snapshot["hp"]
	bee.health.health_changed.emit(bee.health.current_health, bee.health.max_health, 0)
	bee.spread_ammo = snapshot["spread"]
	bee.bomb_charges = snapshot["bomb"]
	bee.weapon_state_changed.emit()
	stage.get_node("CanvasLayer/WeaponsHUD").taught = snapshot["taught"].duplicate(true)
	stage.wave.resume_after_checkpoint(stage.distance)
	stage.wave.animals_total = int(snapshot.get("animals", 0)) # NOCHE 01: freed-animal tally survives the respawn.
	stage.wave.liberated_count = int(snapshot.get("liberated", 0))
	for pair in [["Pollen", "pollen_available"], ["Powerups", "powerups_available"]]:
		for item in stage.get_node(pair[0]).get_children():
			if item.position.x < float(snapshot.get("keep_from", checkpoint_x)) or str(item.name) not in snapshot[pair[1]]:
				item.hide()
				item.queue_free()
	for crate in stage.get_node("Destructibles").get_children():
		if str(crate.name) in snapshot["broken"]:
			# Restore destruction without replaying break VFX/audio/rewards.
			crate.is_destroyed = true
			crate.health.current_health = 0
			crate.visual_root.hide()
			crate.body.collision_layer = 0
			crate.collider.set_deferred("disabled", true)
			crate.hurtbox.set_deferred("monitorable", false)
	for rock: BreakableRock in _rock_nodes():
		if stage.is_ancestor_of(rock) and str(rock.name) in snapshot["broken"]:
			rock.restore_broken()
	for surface: ImpactSurface in get_tree().get_nodes_in_group("bee_destructibles"):
		if stage.is_ancestor_of(surface) and str(surface.name) in snapshot["broken"]:
			surface.restore_broken()
	debug_active = bool(snapshot.get("debug", false))
	boss_checkpoint_count = int(snapshot.get("boss_attempts", 0))
	debug_label.visible = debug_active
	protection_left = protection_seconds
	bee.health.damage_blocked = true
	_hint_left = 0.0
	controls_hint.hide()
	notice.text = "RESPAWN · PROTECTED"
	_notice_left = protection_seconds
	HUD_NOTICES.for_host(self).show_notice("REAPARICIÓN · PROTEGIDA", protection_seconds, "respawn", true)

func defeat_hint() -> void:
	stage.status.text = "PLAYER DOWN — PRESS R TO RESPAWN" if checkpoint_active else "PLAYER DOWN — PRESS R TO RESTART"
	controls_hint.hide()
	notice.hide()

func restart_level(full: bool) -> void:
	get_tree().paused = false
	if get_tree().has_meta(HANDOFF):
		get_tree().remove_meta(HANDOFF)
	if not full and checkpoint_active:
		get_tree().set_meta(HANDOFF, snapshot.duplicate(true))
	get_tree().reload_current_scene()

func _exit_tree() -> void:
	if stage != null and is_instance_valid(stage.bee):
		stage.bee.health.damage_blocked = false
