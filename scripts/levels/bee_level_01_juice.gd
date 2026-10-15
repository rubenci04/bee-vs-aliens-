class_name BeeLevel01Juice
extends Node
## LOTE 11 · ETAPA C — Level 01 "life and emotion" orchestrator (presentation + small rewards, no new enemy behaviour):
##   combo     "xN" counter for consecutive destructions / liberations (reset after COMBO_RESET_SECONDS without any hit or
##             kill); points per kill x combo multiplier; the score is shown on the SECTOR DESPEJADO card
##   pollen    20 grains charge a manually activated pollen Nova (T3m).
##   frenzy    a combo of FRENZY_COMBO starts FRENESI (6 s of double shot, BeePlayer.activate_honey: the internal name is kept)
##   juice     liberation rewards; T4f reserves local hit stop/shake for key events only
##   magnet    items drift towards Bee when she passes close
## Every number is a constant. The hit flash is attached to each enemy by the controller (BeeJuice.attach_hit_flash).

const COMBO_RESET_SECONDS := 3.0
const COMBO_STEP := 0.1 ## +10 % points per extra step of the combo...
const COMBO_MAX_MULTIPLIER := 3.0 ## ...up to x3.
const POINTS_LIBERATION := 150
const POINTS_BOSS := 1000
## [max base HP, points]: the first row whose HP limit covers the enemy.
const POINTS_BY_HP := [[10, 10], [50, 40], [100, 80], [100000, 150]]
const POLLEN_INSTANT_HEAL := 0 ## Level 1 pollen never heals directly.
const NOVA := preload("res://scripts/game/bee_pollen_nova_settings.gd")
const POLLEN_PER_HEAL := NOVA.CHARGE ## Historical public name: now the Nova charge threshold.
const POLLEN_HEAL_FRACTION := 0.0 ## Compatibility for old reports/tests: pollen no longer heals.
const LIBERATION_POLLEN_EVERY := 3 ## A freed animal drops its pollen one time in this many.
const POLLEN_CAP_PER_MINUTE := 70 ## Pollen that can be gained per rolling minute (extra pollen is lost).
const POLLEN_CAP_WINDOW := 60.0
const POLLEN_BANK_MAX := 0 ## No stored heals.
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
var pollen_healed := 0 # Historical telemetry; stays at zero since T3m.
var pollen_heal_enabled := false # Historical fixture compatibility; no healing path remains.
var pollen_lost_to_cap := 0 ## Pollen picked up beyond POLLEN_CAP_PER_MINUTE.
var banked_heals := 0 # Compatibility counter; never filled.
var pollen_spent := 0
var nova_cooldown_left := 0.0
var nova_protection_left := 0.0
var novas_used := 0
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
	nova_cooldown_left = maxf(0.0, nova_cooldown_left - delta)
	nova_protection_left = maxf(0.0, nova_protection_left - delta)
	bee.health.pollen_protected = nova_protection_left > 0.0
	if Input.is_action_just_pressed(NOVA.ACTION):
		try_pollen_nova()
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
	if liberated:
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
	pollen_total += amount
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
	return clampi(pollen_total - pollen_spent, 0, NOVA.CHARGE)


func try_pollen_nova() -> bool:
	if get_tree().paused or bee.is_defeated or stage.sector_complete or pollen_progress() < NOVA.CHARGE or nova_cooldown_left > 0.0:
		return false
	# Excess collected while full does not bank extra charges.
	pollen_spent = pollen_total
	nova_cooldown_left = NOVA.COOLDOWN_SECONDS
	nova_protection_left = NOVA.INVULNERABILITY_SECONDS
	bee.health.pollen_protected = true
	novas_used += 1
	var nova := preload("res://scripts/bee_prototype/bee_pollen_nova.gd").new()
	nova.name = "PollenNova"
	stage.add_child(nova)
	nova.attacker = bee
	nova.global_position = bee.global_position
	nova.hit_confirmed.connect(func(_hurt, _damage): wave.enemy_hit.emit())
	BeeAudio.play(stage, &"liberate", bee.global_position, 1.25)
	_refresh_pollen()
	return true


func _refresh_pollen() -> void:
	if pollen_label == null:
		return
	var filled := pollen_progress()
	var cells := filled * 10 / NOVA.CHARGE
	pollen_label.text = "POLEN [%s%s] %d/%d" % ["#".repeat(cells), "-".repeat(10 - cells), filled, NOVA.CHARGE]
	if filled == NOVA.CHARGE:
		pollen_label.text += " · NOVA " + NOVA.button_hint()


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
