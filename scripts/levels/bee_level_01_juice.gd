class_name BeeLevel01Juice
extends Node
## LOTE 11 · ETAPA C — Level 01 "life and emotion" orchestrator (presentation + small rewards, no new enemy behaviour):
##   combo     "xN" counter for consecutive destructions / liberations (reset after COMBO_RESET_SECONDS without any hit or
##             kill); points per kill x combo multiplier; the score is shown on the SECTOR DESPEJADO card
##   pollen    pollen (pickups, clusters, mushrooms and flowers, +POLLEN_PER_LIBERATION per freed animal) fills a bar; every
##             POLLEN_PER_HEAL pollen heals POLLEN_HEAL_FRACTION of max HP (flash + sound). It never heals instantly.
##   frenzy    a combo of FRENZY_COMBO starts FRENESI (6 s of double shot, BeePlayer.activate_honey: the internal name is kept)
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
const POLLEN_INSTANT_HEAL := 0 ## Direct healing of a pollen pickup in Level 1: none (the bar heals).
## LOTE 14 · ETAPA 2.2: POLLEN IS SCARCE. 20 pollen fill the bar and heal 10 % (was 10 -> 15 %); liberations drop pollen 1 time in 3; at most
## POLLEN_CAP_PER_MINUTE pollen can be gained in any rolling minute; the loose pollen of the level was halved (see BeeLevel01VerticalSlice).
const POLLEN_PER_HEAL := 20 ## Pollen needed to fill the bar (one heal).
const POLLEN_HEAL_FRACTION := 0.10 ## Fraction of max HP restored per full bar.
const LIBERATION_POLLEN_EVERY := 3 ## A freed animal drops its pollen one time in this many.
const POLLEN_CAP_PER_MINUTE := 70 ## Pollen that can be gained per rolling minute (extra pollen is lost).
const POLLEN_CAP_WINDOW := 60.0
const POLLEN_BANK_MAX := 1 ## A full bar reached at full health waits (at most this many heals) and fires on the next damage.
const FRENZY_COMBO := 8 ## Combo that starts FRENESI (double shot).
const HEAL_FLASH_COLOR := Color(1.0, 0.86, 0.3, 0.24)
const HEAL_FLASH_SECONDS := 0.4
const POLLEN_PER_LIBERATION := 3 ## LOTE 14: pollen of the liberation that drops it (one in LIBERATION_POLLEN_EVERY; was 1 per liberation)
const DAMAGE_SHAKE_AMPLITUDE := 0.045
const DAMAGE_SHAKE_SECONDS := 0.2
const MAGNET_RADIUS := 2.4
const MAGNET_SPEED := 6.5
const MAGNET_SCAN_SECONDS := 0.25
const COMBO_COLOR := Color(1.0, 0.86, 0.3)
const POLLEN_COLOR := Color(1.0, 0.84, 0.25)
const FRENZY_COLOR := Color(1.0, 0.55, 0.15)

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
var frenzy_activations := 0
var pollen_heals := 0
var pollen_healed := 0 # HP restored by the pollen bar.
var pollen_heal_enabled := true # Tests that kill many units switch the heal off to keep their HP fixtures exact.
var pollen_lost_to_cap := 0 ## Pollen picked up beyond POLLEN_CAP_PER_MINUTE.
var banked_heals := 0
var liberations_seen := 0
var _pollen_window: Array[Vector2] = [] ## (time, amount) gained in the last POLLEN_CAP_WINDOW seconds.
var _pollen_clock := 0.0
var magnet_pulls := 0
var big_stops := 0
var combo_label: Label
var pollen_label: Label
var frenzy_label: Label
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
	bee.honey_changed.connect(_refresh_frenzy)
	get_tree().node_added.connect(_on_node_added)
	_build_hud()
	for pickup in stage.find_children("*", "Area3D", true, false):
		_register_pickup(pickup)
	_refresh_pollen()
	_refresh_frenzy()


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
	pollen_label = _hud_label(layer, "PollenLabel", 148.0, POLLEN_COLOR)
	frenzy_label = _hud_label(layer, "FrenzyLabel", 178.0, FRENZY_COLOR)


func _hud_label(layer: Node, label_name: String, top: float, color: Color) -> Label:
	var label := Label.new()
	label.name = label_name
	label.offset_left = 18.0
	label.offset_top = top
	label.offset_right = 520.0
	label.offset_bottom = top + 28.0
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(label)
	return label


func _physics_process(delta: float) -> void:
	_pollen_clock += delta
	if combo > 0:
		combo_left -= delta
		if combo_left <= 0.0:
			_reset_combo()
	if bee.honey_left > 0.0:
		_refresh_frenzy()
	_scan_left -= delta
	if _scan_left <= 0.0:
		_scan_left = MAGNET_SCAN_SECONDS
		_pickups = _pickups.filter(func(p): return is_instance_valid(p) and p.is_inside_tree())
	_update_magnet(delta)


# --- combo / score -----------------------------------------------------------------------------------------------

func combo_multiplier() -> float:
	return minf(1.0 + COMBO_STEP * float(maxi(combo - 1, 0)), COMBO_MAX_MULTIPLIER)


static func base_points(unit: Node, liberated: bool) -> int:
	if unit is TarantulaBoss01 or unit is WalkerMiniboss: # LOTE 12 · ETAPA 3: Level 1's bosses (freed / exploded).
		return POINTS_BOSS
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
	if combo % FRENZY_COMBO == 0: # FRENESI at combo x8 (and every further x8 of an unbroken chain): the double shot no longer depends on pollen.
		frenzy_activations += 1
		bee.activate_honey()
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
		liberations_seen += 1
		if liberations_seen % LIBERATION_POLLEN_EVERY == 0:
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
	_refresh_frenzy()
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


# --- pollen bar / frenzy -----------------------------------------------------------------------------------------

func add_pollen(amount: int) -> void:
	amount = _apply_pollen_cap(amount)
	for i in amount:
		pollen_total += 1
		if pollen_total % POLLEN_PER_HEAL == 0:
			_heal_from_pollen()
	_refresh_pollen()


## LOTE 14: rolling-minute cap. Returns how much of `amount` still fits.
func _apply_pollen_cap(amount: int) -> int:
	while not _pollen_window.is_empty() and _pollen_clock - _pollen_window[0].x > POLLEN_CAP_WINDOW:
		_pollen_window.pop_front()
	var used := 0
	for entry in _pollen_window:
		used += int(entry.y)
	var allowed := clampi(POLLEN_CAP_PER_MINUTE - used, 0, amount)
	pollen_lost_to_cap += amount - allowed
	if allowed > 0:
		_pollen_window.append(Vector2(_pollen_clock, allowed))
	return allowed

func pollen_progress() -> int:
	return pollen_total % POLLEN_PER_HEAL


## A full bar: POLLEN_HEAL_FRACTION of max HP back, with a golden flash, a chime and a floating text.
func _heal_from_pollen() -> void:
	pollen_heals += 1
	if bee.is_defeated:
		return
	if not pollen_heal_enabled:
		return
	if bee.health.current_health >= bee.health.max_health - 1 and banked_heals < POLLEN_BANK_MAX:
		banked_heals += 1 # LOTE 14: a full bar at full health is kept for the next hit instead of being wasted.
		_refresh_pollen()
		return
	_apply_heal()


## The healing itself (flash, chime, floating text). Also used when a banked heal is released by the next hit.
func _apply_heal() -> void:
	var amount := maxi(1, ceili(float(bee.health.max_health) * POLLEN_HEAL_FRACTION))
	pollen_healed += bee.health.restore_health(amount)
	BeeAudio.play(stage, &"liberate", bee.global_position, 1.25)
	BeeCombatVFX.spawn(stage, bee.global_position, &"pollen", Vector3.UP, 1.3)
	_heal_flash()
	var text := Label3D.new()
	text.text = "+%d%% VIDA" % roundi(POLLEN_HEAL_FRACTION * 100.0)
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	text.no_depth_test = true
	text.font_size = 40
	text.outline_size = 12
	text.pixel_size = 0.0075
	text.modulate = POLLEN_COLOR
	text.outline_modulate = Color(0.16, 0.09, 0.03)
	stage.add_child(text)
	text.global_position = bee.global_position + Vector3(0.0, 0.9, 0.3)
	var rise := text.create_tween().set_parallel(true)
	rise.tween_property(text, "global_position", text.global_position + Vector3(0.0, 0.9, 0.0), 1.0)
	rise.tween_property(text, "modulate:a", 0.0, 0.5).set_delay(0.5)
	rise.chain().tween_callback(text.queue_free)


func _heal_flash() -> void:
	var layer := CanvasLayer.new()
	layer.name = "PollenHealFlash"
	layer.layer = 6
	stage.add_child(layer)
	var rect := ColorRect.new()
	rect.color = HEAL_FLASH_COLOR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	var fade := layer.create_tween()
	fade.tween_property(rect, "color:a", 0.0, HEAL_FLASH_SECONDS)
	fade.tween_callback(layer.queue_free)


func _refresh_pollen() -> void:
	if pollen_label == null:
		return
	var filled := pollen_progress()
	var cells := filled * 10 / POLLEN_PER_HEAL
	pollen_label.visible = true
	pollen_label.text = "POLEN [%s%s] %d/%d · +%d%% VIDA" % ["#".repeat(cells), "-".repeat(10 - cells), filled, POLLEN_PER_HEAL, roundi(POLLEN_HEAL_FRACTION * 100.0)] + (" · CURA LISTA" if banked_heals > 0 else "")


func _refresh_frenzy() -> void:
	if frenzy_label == null:
		return
	var active := bee.honey_left > 0.0
	frenzy_label.visible = active or combo > 0
	if active:
		frenzy_label.text = "FRENESÍ · DISPARO DOBLE %.1f s" % bee.honey_left
	else:
		frenzy_label.text = "FRENESÍ: COMBO x%d (%d/%d)" % [FRENZY_COMBO, mini(combo, FRENZY_COMBO), FRENZY_COMBO]


func _on_pollen_collected(pickup: BeePollenPickup, _restored: int) -> void:
	pollen_from_pickups += pickup.pollen_value
	add_pollen(pickup.pollen_value)


# --- bee hurt / item magnet --------------------------------------------------------------------------------------

func _on_bee_health_changed(_current: int, _maximum: int, change: int) -> void:
	if change < 0:
		BeeCameraShake.kick(bee, DAMAGE_SHAKE_AMPLITUDE, DAMAGE_SHAKE_SECONDS)
		if banked_heals > 0 and not bee.is_defeated and pollen_heal_enabled:
			banked_heals -= 1 # LOTE 14: the banked heal fires on the first damage after it was earned.
			_apply_heal.call_deferred()
			_refresh_pollen()


func _on_node_added(node: Node) -> void:
	if node is BeePollenPickup or node is BeePowerupPickup:
		_register_pickup.call_deferred(node)


func _register_pickup(node: Node) -> void:
	if not is_instance_valid(node) or not (node is BeePollenPickup or node is BeePowerupPickup):
		return
	if _pickups.has(node):
		return
	_pickups.append(node as Area3D)
	if node is BeePollenPickup and BeeItemBeacon.for_item(node as Node3D) in [&"pollen", &"cluster"] and not _connected_pollen.has(node.get_instance_id()):
		_connected_pollen[node.get_instance_id()] = true
		(node as BeePollenPickup).collected.connect(_on_pollen_collected)


func _wants(pickup: Area3D) -> bool:
	if pickup is BeePowerupPickup:
		var power := pickup as BeePowerupPickup
		return not (power.kind == BeePowerupPickup.Kind.BOMB and bee.bomb_charges >= bee.max_bomb_charges)
	return true


func _update_magnet(delta: float) -> void:
	if bee.is_defeated:
		return
	for pickup in _pickups:
		if not is_instance_valid(pickup) or bool(pickup.get("was_collected")) or not pickup.visible or not _wants(pickup):
			continue
		if pickup is BeePollenPickup and not preload("res://scripts/game/bee_pollen_settings.gd").legacy_review:
			if preload("res://scripts/items/bee_pollen_magnet.gd").step(pickup,bee,delta): magnet_pulls += 1
			continue
		var offset := bee.global_position - pickup.global_position
		offset.z = 0.0
		var distance := offset.length()
		if distance > MAGNET_RADIUS or distance < 0.05:
			continue
		var pull := MAGNET_SPEED * (1.0 + (1.0 - distance / MAGNET_RADIUS))
		pickup.global_position += offset / distance * minf(pull * delta, distance)
		magnet_pulls += 1
