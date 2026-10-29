class_name BeeLevel01Anthills
extends Node3D
## LOTE 13 · ETAPA 1 — the anthills_v01 mounds on the soil of Level 1 and the way ants COME OUT of them: the ant is born at the
## mound's entrance anchor, grows out of it in EMERGE_SECONDS with a dirt puff (it is never a target nor a threat meanwhile), descends
## down to the ground and only then the director activates it (see BeeLevel01Controller._spawn, request key "anthill").
## Events mark their ants with `"anthill": true`; with no mound on screen the ant enters from the right edge as before.

const CRATER := preload("res://scenes/art_labs/anthills_v01/crater.tscn")
const SIDE_TUNNEL := preload("res://scenes/art_labs/anthills_v01/side_tunnel.tscn")
const HILL_SCALE := 1.44 ## LOTE 14: 20 % smaller than the 1.8 of Lote 13 (small screens); the Codex mounds are 2.4 m wide at scale 1.
const HILL_Z := -0.9 ## Just behind the flight plane: the ant walks in front of the mound.
const GROUND_Y := -0.2
const EMERGE_SECONDS := 0.7
const EMERGE_START_SCALE := 0.25
const EMERGE_RISE := 0.0 ## m the ant rises above the entrance while it grows.
const HOP_SECONDS := 0.4
const HOP_DISTANCE := 1.3 ## m towards -X (towards Bee) while descending from the mouth.
const MOUTH_EXIT_FRACTION := 0.35
const DESCENT_FRACTION := 0.65
const HOP_HEIGHT := 0.0
## A mound can be used when its X is inside [camera - VISIBLE_BEHIND, camera + VISIBLE_AHEAD].
const VISIBLE_BEHIND := 3.0
const VISIBLE_AHEAD := 6.5
const PREFERRED_AHEAD := 4.0
const EVENT_LINK_DISTANCE := 7.0
const ANTS_PER_HILL := 2
## LOTE 14 · ETAPA 3.1: 5 mounds (were 8) at least MIN_SPACING m of scroll (20 s at cruise) apart, each in a gap between the solid objects of the
## flight plane (crates, rocks, mushrooms, log, bottle, litter, can) - validate_bee_lote14_anthills_v01 measures both. [kind, X]: placed near the ant groups.
const MIN_SPACING := 25.0
const PLACEMENTS := [
	[&"crater", 28.0], [&"side_tunnel", 69.45], [&"crater", 114.4], [&"side_tunnel", 143.4], [&"crater", 265.5],
]

var hills: Array[Dictionary] = [] # {node, kind, x, entrance}
var emerged := 0 # Ants that came out of a mound (tests / report).


func _ready() -> void:
	for placement in PLACEMENTS:
		var kind: StringName = placement[0]
		var node := (CRATER if kind == &"crater" else SIDE_TUNNEL).instantiate() as Node3D
		node.name = "Anthill_%s_%d" % [kind, int(placement[1])]
		node.scale = Vector3.ONE * HILL_SCALE
		add_child(node)
		node.global_position = Vector3(float(placement[1]), -0.05, HILL_Z)
		var anchor := node.find_child("EntranceAnchor", true, false) as Node3D
		var entrance := anchor.global_position if anchor != null else node.global_position + Vector3(0.0, 0.5 * HILL_SCALE, 0.0)
		hills.append({"node": node, "kind": kind, "x": float(placement[1]), "entrance": Vector3(entrance.x, entrance.y, 0.0), "sent": 0})

func pick_for_event(event_x: float) -> Dictionary:
	for hill in hills:
		if absf(float(hill["x"]) - event_x) <= EVENT_LINK_DISTANCE and int(hill["sent"]) < ANTS_PER_HILL:
			hill["sent"] = int(hill["sent"]) + 1
			return hill
	return {}


## The mound an ant can come out of now (on screen, the one nearest to PREFERRED_AHEAD of the camera); {} when there is none.
func pick(camera_x: float) -> Dictionary:
	var best := {}
	var best_distance := INF
	for hill in hills:
		var rel := float(hill["x"]) - camera_x
		if rel < -VISIBLE_BEHIND or rel > VISIBLE_AHEAD:
			continue
		var distance := absf(rel - PREFERRED_AHEAD)
		if distance < best_distance:
			best_distance = distance
			best = hill
	return best


## Grows `unit` out of `hill`, descends to the ground and calls `on_done`. The unit must be inactive (not yet `activate`d).
func emerge(unit: Node3D, hill: Dictionary, on_done: Callable) -> void:
	var entrance: Vector3 = hill["entrance"]
	emerged += 1
	unit.set_meta("anthill_entry", true) # Coming out of the mound: not active yet (tests / director).
	unit.show()
	unit.set_physics_process(false)
	unit.remove_from_group("bee_auto_aim_targets")
	unit.global_position = entrance
	unit.scale = Vector3.ONE * EMERGE_START_SCALE
	BeeCombatVFX.spawn(unit.get_parent(), entrance + Vector3(0.0, 0.1, 0.4), &"rock_break", Vector3.UP, 1.1)
	BeeAudio.play(unit.get_parent(), &"crate", entrance, 0.7)
	var up := Vector3(entrance.x - HOP_DISTANCE * MOUTH_EXIT_FRACTION, lerpf(entrance.y, GROUND_Y, DESCENT_FRACTION), 0.0)
	var landing := Vector3(entrance.x - HOP_DISTANCE, GROUND_Y, 0.0)
	var tween := unit.create_tween() # Owned by the unit: a level reload frees both.
	tween.set_parallel(true)
	tween.tween_property(unit, "scale", Vector3.ONE, EMERGE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(unit, "global_position", up, EMERGE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_method(_hop.bind(unit, up, landing), 0.0, 1.0, HOP_SECONDS)
	tween.chain().tween_callback(_land.bind(unit, on_done))


static func _hop(progress: float, unit: Node3D, from: Vector3, to: Vector3) -> void:
	if not is_instance_valid(unit):
		return
	var p := from.lerp(to, progress)
	p.y = lerpf(from.y, GROUND_Y, progress)
	unit.global_position = p


static func _land(unit: Node3D, on_done: Callable) -> void:
	if not is_instance_valid(unit):
		return
	unit.scale = Vector3.ONE
	unit.global_position.y = GROUND_Y
	if unit is AssetFauna: (unit as AssetFauna).ground_y = GROUND_Y
	unit.set_meta("anthill_entry", false)
	if unit.has_method("is_defeated") and bool(unit.call("is_defeated")):
		return
	unit.add_to_group("bee_auto_aim_targets")
	BeeCombatVFX.spawn(unit.get_parent(), unit.global_position + Vector3(0.0, 0.1, 0.3), &"rock_break", Vector3.UP, 0.6)
	on_done.call()
