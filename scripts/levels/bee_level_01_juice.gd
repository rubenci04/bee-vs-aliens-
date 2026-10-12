class_name BeeLevel01Juice
extends Node
## LOTE 11 · ETAPA C — Level 01 "life and emotion" orchestrator (presentation + small rewards, no new enemy behaviour):
##   combo     "xN" counter for consecutive destructions / liberations (reset after COMBO_RESET_SECONDS without any hit or
##             kill); points per kill x combo multiplier; the score is shown on the SECTOR DESPEJADO card
##   honey     pollen (collected pickups, +POLLEN_PER_LIBERATION per freed animal) fills a bar; every POLLEN_PER_HONEY starts
##             HONEY MODE (6 s of double shot, see BeePlayer.activate_honey)
##   juice     hit stop on big kills / liberations, camera shake when Bee is hurt, pollen burst on a liberation
##   magnet    items drift towards Bee when she passes close
## Every number is a constant. The hit flash is attached to each enemy by the controller (BeeJuice.attach_hit_flash).

const COMBO_RESET_SECONDS := 3.0
const COMBO_STEP := 0.1 ## +10 % points per extra step of the combo...
const COMBO_MAX_MULTIPLIER := 3.0 ## ...up to x3.
const POINTS_LIBERATION := 150
const POINTS_BOSS := 1000
## [max base HP, points]: the first row whose HP limit covers the enemy.
const POINTS_BY_HP := [[10, 10], [50, 40], [100, 80], [100000, 150]]
const POLLEN_PER_HONEY := 17
const POLLEN_PER_LIBERATION := 1
const DAMAGE_SHAKE_AMPLITUDE := 0.045
const DAMAGE_SHAKE_SECONDS := 0.2
const MAGNET_RADIUS := 2.4
const MAGNET_SPEED := 6.5
const MAGNET_SCAN_SECONDS := 0.25
const COMBO_COLOR := Color(1.0, 0.86, 0.3)
const HONEY_COLOR := Color(1.0, 0.78, 0.2)

signal combo_changed(combo: int)

@export var stage_path: NodePath = ^".."

var stage: BeeShmupStage
var bee: BeePlayer
var wave: BeeLevel01Controller
var combo := 0
var best_combo := 0
var score := 0
var combo_left := 0.0
var pollen_total := 0
var pollen_from_pickups := 0
var pollen_from_liberations := 0
var honey_activations := 0
var magnet_pulls := 0
var big_stops := 0
var combo_label: Label
var honey_label: Label
var _pickups: Array[Area3D] = []
var _connected_pollen := {}
var _scan_left := 0.0


func _ready() -> void:
	stage = get_node(stage_path) as BeeShmupStage
	bee = stage.bee
	wave = stage.wave as BeeLevel01Controller
	wave.unit_downed.connect(_on_unit_downed)
	wave.enemy_hit.connect(_on_enemy_hit)
	bee.health.health_changed.connect(_on_bee_health_changed)
	bee.honey_changed.connect(_refresh_honey)
	get_tree().node_added.connect(_on_node_added)
	_build_hud()
	for pickup in stage.find_children("*", "Area3D", true, false):
		_register_pickup(pickup)
	_refresh_honey()


func _build_hud() -> void:
	var layer := stage.get_node("CanvasLayer")
	combo_label = Label.new()
	combo_label.name = "ComboLabel"
	combo_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	combo_label.offset_left = -260.0
	combo_label.offset_right = -24.0
	combo_label.offset_top = 150.0
	combo_label.offset_bottom = 210.0
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	combo_label.add_theme_font_size_override("font_size", 44)
	combo_label.add_theme_color_override("font_color", COMBO_COLOR)
	combo_label.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.02))
	combo_label.add_theme_constant_override("outline_size", 8)
	combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_label.hide()
	layer.add_child(combo_label)
	honey_label = Label.new()
	honey_label.name = "HoneyLabel"
	honey_label.offset_left = 18.0
	honey_label.offset_top = 108.0
	honey_label.offset_right = 520.0
	honey_label.offset_bottom = 136.0
	honey_label.add_theme_font_size_override("font_size", 20)
	honey_label.add_theme_color_override("font_color", HONEY_COLOR)
	honey_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	honey_label.add_theme_constant_override("shadow_offset_x", 1)
	honey_label.add_theme_constant_override("shadow_offset_y", 1)
	honey_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(honey_label)


func _physics_process(delta: float) -> void:
	if combo > 0:
		combo_left -= delta
		if combo_left <= 0.0:
			_reset_combo()
	if bee.honey_left > 0.0:
		_refresh_honey()
	_scan_left -= delta
	if _scan_left <= 0.0:
		_scan_left = MAGNET_SCAN_SECONDS
		_pickups = _pickups.filter(func(p): return is_instance_valid(p) and p.is_inside_tree())
	_update_magnet(delta)


# --- combo / score -----------------------------------------------------------------------------------------------

func combo_multiplier() -> float:
	return minf(1.0 + COMBO_STEP * float(maxi(combo - 1, 0)), COMBO_MAX_MULTIPLIER)


static func base_points(unit: Node, liberated: bool) -> int:
	if liberated:
		return POINTS_LIBERATION
	if unit is UfoBoss01:
		return POINTS_BOSS
	var family := str(unit.name).get_slice("_", 0)
	var hp := int(BeeLevel01Controller.LEVEL_HP.get(family, 50))
	for row in POINTS_BY_HP:
		if hp <= int(row[0]):
			return int(row[1])
	return 10


func _on_unit_downed(unit: Node3D, liberated: bool) -> void:
	if bee.is_defeated:
		return
	combo += 1
	best_combo = maxi(best_combo, combo)
	combo_left = COMBO_RESET_SECONDS
	score += roundi(float(base_points(unit, liberated)) * combo_multiplier())
	_refresh_combo()
	var family := str(unit.name).get_slice("_", 0)
	var big := liberated or unit is UfoBoss01 or int(BeeLevel01Controller.LEVEL_HP.get(family, 0)) >= BeeJuice.BIG_HP
	if big:
		big_stops += 1
		BeeJuice.hit_stop(get_tree())
	if liberated:
		if is_instance_valid(unit) and unit.is_inside_tree():
			BeeJuice.pollen_burst(stage, unit.global_position + Vector3(0.0, 0.3, 0.0))
		pollen_from_liberations += POLLEN_PER_LIBERATION
		add_pollen(POLLEN_PER_LIBERATION)


func _on_enemy_hit() -> void:
	if combo > 0:
		combo_left = COMBO_RESET_SECONDS # "no impacts for 3 s" resets it: any hit keeps the chain alive.


func _reset_combo() -> void:
	combo = 0
	combo_left = 0.0
	_refresh_combo()


func _refresh_combo() -> void:
	combo_changed.emit(combo)
	if combo_label == null:
		return
	combo_label.visible = combo >= 2
	if combo >= 2:
		combo_label.text = "x%d" % combo
		combo_label.pivot_offset = Vector2(combo_label.size.x, 0.0)
		var pop := combo_label.create_tween()
		pop.tween_property(combo_label, "scale", Vector2.ONE, 0.18).from(Vector2.ONE * 1.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func summary_text() -> String:
	return "PUNTAJE %d · MEJOR COMBO x%d" % [score, best_combo]


# --- pollen / honey mode -----------------------------------------------------------------------------------------

func add_pollen(amount: int) -> void:
	for i in amount:
		pollen_total += 1
		if pollen_total % POLLEN_PER_HONEY == 0:
			honey_activations += 1
			bee.activate_honey()
	_refresh_honey()


func honey_progress() -> int:
	return pollen_total % POLLEN_PER_HONEY


func _refresh_honey() -> void:
	if honey_label == null:
		return
	if bee.honey_left > 0.0:
		honey_label.text = "MODO MIEL · DISPARO DOBLE %.1f s" % bee.honey_left
		honey_label.visible = true
		return
	var filled := honey_progress()
	honey_label.visible = pollen_total > 0
	honey_label.text = "MIEL %s %d/%d" % ["[" + "#".repeat(filled * 10 / POLLEN_PER_HONEY) + "-".repeat(10 - filled * 10 / POLLEN_PER_HONEY) + "]", filled, POLLEN_PER_HONEY]


func _on_pollen_collected(_pickup: BeePollenPickup, _restored: int) -> void:
	pollen_from_pickups += 1
	add_pollen(1)


# --- bee hurt / item magnet --------------------------------------------------------------------------------------

func _on_bee_health_changed(_current: int, _maximum: int, change: int) -> void:
	if change < 0:
		BeeCameraShake.kick(bee, DAMAGE_SHAKE_AMPLITUDE, DAMAGE_SHAKE_SECONDS)


func _on_node_added(node: Node) -> void:
	if node is BeePollenPickup or node is BeePowerupPickup:
		_register_pickup.call_deferred(node)


func _register_pickup(node: Node) -> void:
	if not is_instance_valid(node) or not (node is BeePollenPickup or node is BeePowerupPickup):
		return
	if _pickups.has(node):
		return
	_pickups.append(node as Area3D)
	if node is BeePollenPickup and BeeItemBeacon.for_item(node as Node3D) == &"pollen" and not _connected_pollen.has(node.get_instance_id()):
		_connected_pollen[node.get_instance_id()] = true
		(node as BeePollenPickup).collected.connect(_on_pollen_collected)


func _wants(pickup: Area3D) -> bool:
	if pickup is BeePowerupPickup:
		var power := pickup as BeePowerupPickup
		return not (power.kind == BeePowerupPickup.Kind.BOMB and bee.bomb_charges >= bee.max_bomb_charges)
	if BeeItemBeacon.for_item(pickup) == &"healing":
		return bee.health.current_health < bee.health.max_health # A honey jar at full HP would stick to Bee, uncollected.
	return true


func _update_magnet(delta: float) -> void:
	if bee.is_defeated:
		return
	for pickup in _pickups:
		if not is_instance_valid(pickup) or bool(pickup.get("was_collected")) or not pickup.visible or not _wants(pickup):
			continue
		var offset := bee.global_position - pickup.global_position
		offset.z = 0.0
		var distance := offset.length()
		if distance > MAGNET_RADIUS or distance < 0.05:
			continue
		var pull := MAGNET_SPEED * (1.0 + (1.0 - distance / MAGNET_RADIUS))
		pickup.global_position += offset / distance * minf(pull * delta, distance)
		magnet_pulls += 1
