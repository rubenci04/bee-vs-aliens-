class_name BeeLevel01Moments
extends Node3D
## LEVEL 01 TRANSFORMATION PASS 01 — miniature-world set pieces driven by the director (`director_moment`).
## Presentation and light interaction only: no enemies, no drops, no new systems. Everything sits behind the flight
## plane (z < -1) unless it is an impact surface, so it never blocks Bee.
##   opening_can      "La lata del despertar": a giant crushed soda can; it rocks and puffs dust as Bee wakes up.
##   human_aftermath  dust settling where the giant stepped + a harmless beetle crossing the ground.
##   bomb_reward      the Bomb recharge pulses right after the Walker gate (peak -> reward -> recovery).
##   walker_showcase  (REBUILD 02) dust + low rumble at the right edge: something heavy walks in.
##   preboss_power    (REBUILD 02) the S+ capsule pulses and rings, a charge rises, the HUD says it once.
## Foreground ferns sway when Bee flies low past them (tiny tweens).
## Impact surfaces: the hollow log shells (real solids) stop Bee's shots with the usual spark (never break);
## the structural rock already does it through BreakableRock.

const CAN_X := 6.0
const CAN_Z := -3.6
const BEETLE_SECONDS := 9.0
## NOCHE 01: the aftermath turtle (BeeAftermathTurtle). Flag to remove it if it ever reads badly; scale ~1.7 x Bee long.
const TURTLE_ENABLED := true
const TURTLE_SCALE := 1.0
const POWER_HINT := "¡PREPARATE! · SPREAD+"

@export var stage_path: NodePath = ^".."

var stage: BeeShmupStage
var giant_can: Node3D
var beetle: Node3D
var moments_played: Array[StringName] = []
var impact_surfaces: Array[Node] = []
var foreground_plants: Array[Node3D] = []
var sway_count := 0
var _swaying: Dictionary = {}


func _ready() -> void:
	stage = get_node(stage_path) as BeeShmupStage
	_build_giant_can()
	_attach_impact_surfaces()
	for plant in stage.get_node("Scenery").get_children():
		if plant is Node3D and (str(plant.name).begins_with("FrontFern") or str(plant.name).begins_with("NearFern")):
			foreground_plants.append(plant)
	var wave := stage.get_node("WaveController")
	if wave.has_signal("director_moment"):
		wave.director_moment.connect(play)


func play(id: StringName) -> void:
	moments_played.append(id)
	match id:
		&"opening_can":
			_opening_can()
		&"human_aftermath":
			_human_aftermath()
		&"bomb_reward":
			_bomb_reward()
		&"walker_showcase":
			_walker_showcase()
		&"preboss_power":
			_preboss_power()


# --- opening: the giant can ---------------------------------------------------------------------------

func _build_giant_can() -> void:
	giant_can = Node3D.new()
	giant_can.name = "GiantCan"
	add_child(giant_can)
	# A real soda can is ~8x a bee: lying on its side, 3.6 m long, 2.6 m across, slightly crushed.
	var body := MeshInstance3D.new()
	body.name = "CanBody"
	body.mesh = GardenProps.loft([[0.0, 1.1, 1.1, 0, 0], [0.2, 1.3, 1.3, 0, 0], [1.5, 1.32, 1.2, 0, 0], [1.9, 1.24, 1.0, 0.0, 0.0],
			[2.4, 1.32, 1.18, 0, 0], [3.4, 1.3, 1.3, 0, 0], [3.6, 1.0, 1.0, 0, 0]], 16, true, true)
	body.mesh.surface_set_material(0, GardenProps.flat(Color(0.66, 0.14, 0.13)))
	giant_can.add_child(body)
	var band := MeshInstance3D.new()
	band.name = "CanBand"
	band.mesh = GardenProps.loft([[0.0, 1.335, 1.335, 0, 0], [0.7, 1.335, 1.335, 0, 0]], 16, false, false)
	band.mesh.surface_set_material(0, GardenProps.flat(Color(0.92, 0.9, 0.84)))
	band.position.y = 2.2
	giant_can.add_child(band)
	var lid := MeshInstance3D.new()
	lid.name = "CanLid"
	var lid_mesh := CylinderMesh.new()
	lid_mesh.top_radius = 1.0
	lid_mesh.bottom_radius = 1.0
	lid_mesh.height = 0.08
	lid_mesh.radial_segments = 16
	lid_mesh.material = GardenProps.flat(Color(0.7, 0.72, 0.74))
	lid.mesh = lid_mesh
	lid.position.y = 3.62
	giant_can.add_child(lid)
	for end_y in [0.06, 3.54]: # Pressed aluminium rims at both ends.
		var rim := MeshInstance3D.new()
		rim.name = "CanRim"
		var ring := TorusMesh.new()
		ring.inner_radius = 1.0
		ring.outer_radius = 1.14
		ring.rings = 18
		ring.ring_segments = 6
		ring.material = GardenProps.flat(Color(0.72, 0.74, 0.76))
		rim.mesh = ring
		rim.position.y = end_y
		giant_can.add_child(rim)
	BeeToonStyle.apply(giant_can, true)
	# Lying along X (the loft is built along +Y), resting on the mulch behind the flight plane.
	giant_can.rotation = Vector3(0.0, -0.35, -PI * 0.5) # Lid end turned towards the camera.
	giant_can.position = Vector3(CAN_X - 1.8, 1.2, CAN_Z)


func _opening_can() -> void:
	var tween := giant_can.create_tween()
	tween.tween_property(giant_can, "rotation:x", 0.06, 0.25).set_trans(Tween.TRANS_SINE)
	tween.tween_property(giant_can, "rotation:x", -0.04, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(giant_can, "rotation:x", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
	BeeCombatVFX.spawn(self, Vector3(CAN_X, 0.3, CAN_Z + 1.0), &"crate", Vector3.UP, 2.4)
	BeeAudio.play(self, &"crate", Vector3(CAN_X, 1.0, CAN_Z))


# --- after the giant: the world is still alive -----------------------------------------------------------

## FIXES VISUALES 01: the aftermath crawler was a shapeless dark-green blob (the old beetle at 2.6x). It is now a small
## alien turtle: grey-green dome shell with darker plates, short legs, a lighter head with a cyan eye and a cyan-tipped
## antenna. Clear side silhouette, harmless (no Area3D), toon style like the other creatures. Faces +X (rotated to -X to walk).
static func build_alien_turtle() -> Node3D:
	var root := Node3D.new()
	root.name = "AftermathTurtle"
	var body := Node3D.new() # Everything that bobs while it walks.
	body.name = "Body"
	root.add_child(body)
	var shell := MeshInstance3D.new()
	shell.mesh = GardenLitterMeshes._blob(Vector3(0.62, 0.36, 0.5), 8, 4)
	shell.mesh.surface_set_material(0, GardenProps.flat(Color(0.42, 0.5, 0.42)))
	shell.position = Vector3(0, 0.34, 0)
	body.add_child(shell)
	for plate in [[-0.28, 0.0], [0.0, 0.0], [0.28, 0.0]]: # Darker dorsal plates: reads as armour from the side.
		var p := MeshInstance3D.new()
		p.mesh = GardenLitterMeshes._blob(Vector3(0.14, 0.1, 0.3), 6, 3)
		p.mesh.surface_set_material(0, GardenProps.flat(Color(0.26, 0.32, 0.3)))
		p.position = Vector3(float(plate[0]), 0.66 - absf(float(plate[0])) * 0.35, 0.0)
		body.add_child(p)
	var head := MeshInstance3D.new()
	head.mesh = GardenLitterMeshes._blob(Vector3(0.2, 0.15, 0.15), 7, 4)
	head.mesh.surface_set_material(0, GardenProps.flat(Color(0.6, 0.68, 0.5)))
	head.position = Vector3(0.7, 0.3, 0.0)
	body.add_child(head)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(0.2, 0.95, 1.0)
	glow.emission_enabled = true
	glow.emission = Color(0.1, 0.9, 1.0)
	glow.emission_energy_multiplier = 2.5
	for side in [-1.0, 1.0]: # One eye per side: the lateral camera always sees one.
		var eye := MeshInstance3D.new()
		eye.mesh = GardenLitterMeshes._blob(Vector3(0.05, 0.05, 0.05), 6, 3)
		eye.mesh.surface_set_material(0, glow)
		eye.position = Vector3(0.8, 0.36, side * 0.12)
		body.add_child(eye)
	var stalk := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.015
	cylinder.bottom_radius = 0.025
	cylinder.height = 0.28
	cylinder.radial_segments = 5
	cylinder.material = GardenProps.flat(Color(0.3, 0.36, 0.32))
	stalk.mesh = cylinder
	stalk.position = Vector3(0.68, 0.55, 0.0)
	stalk.rotation.z = -0.25
	body.add_child(stalk)
	var tip := MeshInstance3D.new()
	tip.mesh = GardenLitterMeshes._blob(Vector3(0.045, 0.045, 0.045), 6, 3)
	tip.mesh.surface_set_material(0, glow)
	tip.position = Vector3(0.74, 0.69, 0.0)
	body.add_child(tip)
	var legs: Array[MeshInstance3D] = []
	for leg_spec in [[0.38, 0.28], [0.38, -0.28], [-0.38, 0.28], [-0.38, -0.28]]:
		var leg := MeshInstance3D.new()
		leg.mesh = GardenLitterMeshes._blob(Vector3(0.13, 0.12, 0.09), 6, 3)
		leg.mesh.surface_set_material(0, GardenProps.flat(Color(0.52, 0.6, 0.46)))
		leg.position = Vector3(float(leg_spec[0]), 0.1, float(leg_spec[1]))
		root.add_child(leg)
		legs.append(leg)
	root.set_meta("legs", legs)
	return root


func _human_aftermath() -> void:
	var camera_x := stage.camera.global_position.x
	if BeeLevel01Controller.giant_human_enabled: # NOCHE 01: no giant footsteps to settle when the human is off.
		for i in 4:
			var x := camera_x - 4.5 + float(i) * 2.6
			get_tree().create_timer(0.35 * float(i), false).timeout.connect(_dust.bind(Vector3(x, 0.25, -1.4 - 0.4 * float(i % 2))))
	if beetle != null and is_instance_valid(beetle):
		beetle.queue_free()
	if not TURTLE_ENABLED:
		return
	# NOCHE 01: the rebuilt garden turtle (hexagonal plates, eye, four legs) with an implant: shooting it frees it.
	var turtle := BeeAftermathTurtle.new()
	beetle = turtle
	var shell := turtle.body
	beetle.scale = Vector3.ONE * TURTLE_SCALE
	add_child(beetle)
	if stage.wave.has_method("register_extra_animal"):
		stage.wave.register_extra_animal()
		turtle.liberated_now.connect(func(_t): stage.wave.note_extra_liberated())
	beetle.position = Vector3(camera_x + 7.0, -0.15, -1.6)
	beetle.rotation.y = PI # Walks towards -X.
	var walk := beetle.create_tween()
	walk.tween_property(beetle, "position:x", camera_x - 7.5, BEETLE_SECONDS)
	walk.tween_callback(beetle.queue_free)
	var bob := beetle.create_tween().set_loops(int(BEETLE_SECONDS / 0.36))
	bob.tween_property(shell, "position:y", 0.03, 0.18)
	bob.tween_property(shell, "position:y", 0.0, 0.18)
	# Stepping: front-left + rear-right legs swing together, then the other diagonal.
	var legs: Array = beetle.get_meta("legs")
	var steps := beetle.create_tween().set_loops(int(BEETLE_SECONDS / 0.36))
	steps.tween_method(func(t: float): _step_legs(legs, t), 0.0, 1.0, 0.36)


# --- after the Walker gate: the Bomb as a reward -----------------------------------------------------------

func _bomb_reward() -> void:
	var capsule := stage.get_node_or_null("Powerups/BombRecharge") as Node3D
	if capsule == null or capsule.is_queued_for_deletion():
		return
	BeeCombatVFX.spawn(self, capsule.global_position, &"pickup_bomb", Vector3.UP, 1.0)
	var pulse := capsule.create_tween().set_loops(3)
	pulse.tween_property(capsule, "scale", Vector3.ONE * 1.35, 0.22)
	pulse.tween_property(capsule, "scale", Vector3.ONE, 0.22)


# --- ARCADE REBUILD 02: showcase cue and the pre-boss power moment ------------------------------------------

## Something heavy walks in: ground dust at the right edge, a low rumble and the faintest shake.
func _walker_showcase() -> void:
	var edge := Vector3(stage.camera.global_position.x + BeeLevel01Framing.spawn_offset_x(BeeLevel01Framing.DESIGN_ASPECT) - 1.2, 0.25, 0.0)
	BeeCombatVFX.spawn(self, edge, &"rock_break", Vector3.UP, 1.4)
	BeeAudio.play(stage, &"human_step", edge, 0.72)
	BeeCameraShake.kick(self, 0.03, 0.18)


## "Get ready for something big": the oversized Spread capsule pulses and rings, a charge sound rises and the HUD
## says it once. The capsule itself (Powerups/PrebossPower) is a normal pickup with `overcharge`.
func _preboss_power() -> void:
	var capsule := stage.get_node_or_null("Powerups/PrebossPower") as Node3D
	if capsule == null or capsule.is_queued_for_deletion():
		return
	var base := capsule.scale
	BeeAudio.play(stage, &"ufo_charge", capsule.global_position, 1.3)
	for i in 3:
		get_tree().create_timer(0.45 * i, false).timeout.connect(_power_ring.bind(capsule.get_instance_id()))
	var pulse := capsule.create_tween().set_loops(4)
	pulse.tween_property(capsule, "scale", base * 1.22, 0.25)
	pulse.tween_property(capsule, "scale", base, 0.25)
	var wave := stage.get_node("WaveController")
	wave.set("player_label", POWER_HINT)
	get_tree().create_timer(2.6, false).timeout.connect(_clear_power_hint)


func _power_ring(id: int) -> void:
	var capsule := instance_from_id(id) as Node3D
	if capsule != null and is_instance_valid(capsule) and not capsule.is_queued_for_deletion():
		BeeCombatVFX.spawn(self, capsule.global_position, &"pickup", Vector3.UP, 1.0)


func _clear_power_hint() -> void:
	var wave := stage.get_node("WaveController")
	if str(wave.get("player_label")) == POWER_HINT:
		wave.set("player_label", "")


# --- impact surfaces ---------------------------------------------------------------------------------------

## Real solids in Bee's plane stop shots until their finite HP is depleted.
func _attach_impact_surfaces() -> void:
	# The giant bottle has no collider (Bee flies through it), so it does not stop shots either: only real solids do.
	var log := stage.get_node_or_null("LogObstacle") as Node3D
	if log != null:
		for part in ["LogTop", "LogBottom"]:
			var shell := log.get_node_or_null(part) as CollisionShape3D
			if shell != null and shell.shape is BoxShape3D:
				var surface := ImpactSurface.attach(self, part + "Impact", BoxShape3D.new(), (shell.shape as BoxShape3D).size, shell.global_position)
				surface.solid_shape = shell
				impact_surfaces.append(surface)
				surface.broken.connect(_on_log_broken)


# --- vegetation reaction (cheap) ----------------------------------------------------------------------------

## Only the foreground ferns (z > 0, the ones Bee visibly brushes past) sway briefly when she flies low near them.
## A small tween on ~14 nodes: no physics, no shader changes.
func _physics_process(_delta: float) -> void:
	var bee := stage.bee
	if bee == null or bee.global_position.y > 2.6:
		return
	for plant in foreground_plants:
		if _swaying.has(plant) or absf(plant.global_position.x - bee.global_position.x) > 1.4:
			continue
		_swaying[plant] = true
		sway_count += 1
		var base := plant.rotation.z
		var sway := plant.create_tween()
		sway.tween_property(plant, "rotation:z", base - 0.14, 0.18).set_trans(Tween.TRANS_SINE)
		sway.tween_property(plant, "rotation:z", base + 0.08, 0.3).set_trans(Tween.TRANS_SINE)
		sway.tween_property(plant, "rotation:z", base, 0.35).set_trans(Tween.TRANS_SINE)
		sway.tween_callback(func(): _swaying.erase(plant))


func _dust(at: Vector3) -> void:
	BeeCombatVFX.spawn(self, at, &"crate", Vector3.UP, 2.2)


func _step_legs(legs: Array, t: float) -> void:
	var swing := sin(t * TAU) * 0.09
	for i in legs.size():
		var leg := legs[i] as Node3D
		if is_instance_valid(leg):
			leg.position.x = float([0.38, 0.38, -0.38, -0.38][i]) + swing * (1.0 if i == 0 or i == 3 else -1.0)
			leg.position.y = 0.1 + maxf(0.0, sin(t * TAU + (0.0 if i == 0 or i == 3 else PI))) * 0.05

func _on_log_broken() -> void:
	for surface: ImpactSurface in impact_surfaces:
		surface.is_destroyed = true
		surface.health.current_health = 0
		surface.hurtbox.set_deferred("collision_layer", 0)
		surface.hurtbox.set_deferred("monitorable", false)
	for shape: CollisionShape3D in stage.get_node("LogObstacle").get_children():
		shape.set_deferred("disabled", true)
	var dressing := stage.get_node_or_null("AssetDressing")
	if dressing != null:
		for prop: Node3D in dressing.litter:
			if prop.scene_file_path.ends_with("hollow_fallen_log.tscn"):
				prop.hide()
