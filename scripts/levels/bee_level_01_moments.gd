class_name BeeLevel01Moments
extends Node3D
## LEVEL 01 TRANSFORMATION PASS 01 — miniature-world set pieces driven by the director (`director_moment`).
## Presentation and light interaction only: no enemies, no drops, no new systems. Everything sits behind the flight
## plane (z < -1) unless it is an impact surface, so it never blocks Bee.
##   opening_can      "La lata del despertar": a giant crushed soda can; it rocks and puffs dust as Bee wakes up.
##   human_aftermath  dust settling where the giant stepped + a harmless beetle crossing the ground.
##   bomb_reward      the Bomb recharge pulses right after the Walker gate (peak -> reward -> recovery).
## Foreground ferns sway when Bee flies low past them (tiny tweens).
## Impact surfaces: the hollow log shells (real solids) stop Bee's shots with the usual spark (never break);
## the structural rock already does it through BreakableRock.

const CAN_X := 6.0
const CAN_Z := -3.6
const BEETLE_SECONDS := 9.0

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

func _human_aftermath() -> void:
	var camera_x := stage.camera.global_position.x
	for i in 4:
		var timer := get_tree().create_timer(0.35 * float(i), false)
		var x := camera_x - 4.5 + float(i) * 2.6
		timer.timeout.connect(func():
			if is_inside_tree():
				BeeCombatVFX.spawn(self, Vector3(x, 0.25, -1.4 - 0.4 * float(i % 2)), &"crate", Vector3.UP, 2.2))
	if beetle != null and is_instance_valid(beetle):
		beetle.queue_free()
	beetle = Node3D.new()
	beetle.name = "AftermathBeetle"
	var shell := MeshInstance3D.new()
	shell.mesh = GardenLitterMeshes.beetle()
	shell.mesh.surface_set_material(0, GardenProps.flat(Color(0.12, 0.24, 0.16)))
	beetle.add_child(shell)
	BeeToonStyle.apply(beetle, true)
	beetle.scale = Vector3.ONE * 2.6
	add_child(beetle)
	beetle.position = Vector3(camera_x + 7.0, -0.12, -1.6)
	beetle.rotation.y = PI # Walks towards -X.
	var walk := beetle.create_tween()
	walk.tween_property(beetle, "position:x", camera_x - 7.5, BEETLE_SECONDS)
	walk.tween_callback(beetle.queue_free)
	var bob := beetle.create_tween().set_loops(int(BEETLE_SECONDS / 0.36))
	bob.tween_property(shell, "position:y", 0.03, 0.18)
	bob.tween_property(shell, "position:y", 0.0, 0.18)


# --- after the Walker gate: the Bomb as a reward -----------------------------------------------------------

func _bomb_reward() -> void:
	var capsule := stage.get_node_or_null("Powerups/BombRecharge") as Node3D
	if capsule == null or capsule.is_queued_for_deletion():
		return
	BeeCombatVFX.spawn(self, capsule.global_position, &"pickup_bomb", Vector3.UP, 1.0)
	var pulse := capsule.create_tween().set_loops(3)
	pulse.tween_property(capsule, "scale", Vector3.ONE * 1.35, 0.22)
	pulse.tween_property(capsule, "scale", Vector3.ONE, 0.22)


# --- impact surfaces ---------------------------------------------------------------------------------------

## Real solids in Bee's plane stop shots (the projectile spark + hit sound); they never break.
func _attach_impact_surfaces() -> void:
	# The giant bottle has no collider (Bee flies through it), so it does not stop shots either: only real solids do.
	var log := stage.get_node_or_null("LogObstacle") as Node3D
	if log != null:
		for part in ["LogTop", "LogBottom"]:
			var shell := log.get_node_or_null(part) as CollisionShape3D
			if shell != null and shell.shape is BoxShape3D:
				impact_surfaces.append(ImpactSurface.attach(self, part + "Impact", BoxShape3D.new(), (shell.shape as BoxShape3D).size, shell.global_position))


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
