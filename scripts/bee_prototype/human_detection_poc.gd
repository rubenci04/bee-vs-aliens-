extends Node3D
## Isolated experiment: observes accepted Bee actions without changing BeePlayer.
const TREE = preload("res://assets/external/approved/nature/quaternius/Stylized Nature MegaKit[Standard]/glTF/CommonTree_1.gltf")
const FERN = preload("res://assets/external/approved/nature/quaternius/Stylized Nature MegaKit[Standard]/glTF/Fern_1.gltf")
const BOTTLE = preload("res://assets/external/approved/props/kenney/kenney_food-kit/Models/GLB format/soda-bottle.glb")

@onready var bee: BeePlayer = $BeePlayer
@onready var human: HumanObserver = $HumanObserver
@onready var probe: AlienProbeRanged = $AlienProbe
@onready var suspicion_label: Label = $CanvasLayer/SuspicionLabel
@onready var suspicion_bar: ProgressBar = $CanvasLayer/SuspicionBar
@onready var status: Label = $CanvasLayer/Status
var _previous_shots := 0
var _previous_melee := 0
var probe_started := false

func _ready() -> void:
	_previous_shots = bee.shots_fired
	_previous_melee = bee.melee_count
	_place_asset(TREE, "Tree", Vector3(-9,0,-7), 0.9)
	_place_asset(FERN, "Fern", Vector3(-1,0,-3.5), 2.2)
	_place_asset(BOTTLE, "Bottle", Vector3(9,0,-3.5), 9.7)
	bee.defeated.connect(func(): status.text = "PLAYER DOWN — R PARA REINICIAR")

func _physics_process(_delta: float) -> void:
	if bee.shots_fired > _previous_shots:
		for i in bee.shots_fired - _previous_shots: human.notify_bee_action("shot")
		_previous_shots = bee.shots_fired
	if bee.melee_count > _previous_melee:
		for i in bee.melee_count - _previous_melee: human.notify_bee_action("melee")
		_previous_melee = bee.melee_count
	if not probe_started and bee.position.x >= 3.0:
		probe_started = probe.activate(bee)

func _process(_delta: float) -> void:
	if bee.is_defeated:
		if Input.is_action_just_pressed("restart"): get_tree().reload_current_scene()
		return
	var visible := human.suspicion > 0.01 or human.can_see_bee()
	suspicion_label.visible = visible
	suspicion_bar.visible = visible
	suspicion_label.text = "SOSPECHA %d/100" % int(human.suspicion)
	suspicion_bar.value = human.suspicion
	status.text = "HUMANO %s · Z melee · X disparo · VOLÁ DETRÁS PARA EVITARLO" % HumanObserver.State.keys()[human.current_state]

func _place_asset(asset: PackedScene, label: String, floor_position: Vector3, factor: float) -> void:
	var instance: Node3D = asset.instantiate()
	instance.name = label
	$Scenery.add_child(instance)
	var bounds := AABB()
	var first := true
	for mesh: MeshInstance3D in instance.find_children("*", "MeshInstance3D", true, false):
		var local := instance.global_transform.affine_inverse() * mesh.global_transform
		var box: AABB = local * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	instance.scale = Vector3.ONE * factor
	instance.position = floor_position - Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
