extends Node3D

const SOURCE_PATHS := [
	"res://dev/extras_scifi_review/source/alien_quaternius/Alien by Quaternius - sUTLXji0aL.glb",
	"res://dev/extras_scifi_review/source/robot_walker/Enemy_2Legs_Gun.fbx",
	"res://dev/extras_scifi_review/source/ufo_hat/ufo.fbx",
	"res://dev/extras_scifi_review/source/flying_saucer/flying sacuer.obj",
	"res://dev/extras_scifi_review/source/mars_rover/model.obj",
	"res://dev/extras_scifi_review/source/spaceship_goodnews/model.obj",
]
const LABELS := ["ALIEN QUATERNIUS", "ROBOT WALKER", "UFO HAT", "FLYING SAUCER", "MARS ROVER", "SPACESHIP GOODNEWS"]

@onready var model_mount: Node3D = $ModelMount
@onready var model_label: Label = $CanvasLayer/ModelLabel
@onready var detail_label: Label = $CanvasLayer/DetailLabel

var candidate_index := 0
var current_model: Node3D
var current_animation_player: AnimationPlayer
var raw_bounds := AABB()
var review_scale := 1.0
var last_error := ""

func _ready() -> void:
	$Camera3D.look_at(Vector3(0, 1.75, 0))
	show_candidate(0)

func show_candidate(index: int) -> bool:
	candidate_index = posmod(index, SOURCE_PATHS.size())
	for child in model_mount.get_children():
		child.queue_free()
	current_model = null
	current_animation_player = null
	last_error = ""
	var resource := load(SOURCE_PATHS[candidate_index])
	if resource is PackedScene:
		current_model = (resource as PackedScene).instantiate() as Node3D
	elif resource is Mesh:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = resource as Mesh
		current_model = mesh_instance
	else:
		last_error = "Resource not importable as scene or mesh: %s" % SOURCE_PATHS[candidate_index]
		push_error(last_error)
		return false
	model_mount.add_child(current_model)
	raw_bounds = _model_bounds(current_model)
	if raw_bounds.size.length_squared() < 0.000001:
		last_error = "No visible mesh bounds: %s" % SOURCE_PATHS[candidate_index]
		push_error(last_error)
		return false
	review_scale = 4.4 / maxf(raw_bounds.size.x, maxf(raw_bounds.size.y, raw_bounds.size.z))
	if candidate_index == 1:
		# The Walker's long depth dominates its AABB; use a legible display scale.
		review_scale = 2.8
	current_model.scale = Vector3.ONE * review_scale
	current_model.position = Vector3(-raw_bounds.get_center().x, -raw_bounds.position.y, -raw_bounds.get_center().z) * review_scale
	var players := current_model.find_children("*", "AnimationPlayer", true, false)
	if players.size() > 0:
		current_animation_player = players[0] as AnimationPlayer
	model_label.text = "%d/6 · %s" % [candidate_index + 1, LABELS[candidate_index]]
	detail_label.text = "Bee reference at left · imported AABB %s · review scale %.2f×\n1–6: model   I: Idle   W: Walk/Run   A: Attack/Shoot" % [str(raw_bounds.size.snappedf(0.001)), review_scale]
	return true

func _model_bounds(model: Node3D) -> AABB:
	var bounds := AABB()
	var first := true
	var nodes: Array[Node] = [model]
	nodes.append_array(model.find_children("*", "MeshInstance3D", true, false))
	for node in nodes:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var local := model.global_transform.affine_inverse() * mesh_instance.global_transform
		var box := local * mesh_instance.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	return bounds

func animation_names() -> Array[String]:
	var result: Array[String] = []
	if current_animation_player == null:
		return result
	for name in current_animation_player.get_animation_list():
		result.append(str(name))
	return result

func play_matching_clip(fragment: String) -> bool:
	if current_animation_player == null:
		return false
	for name in current_animation_player.get_animation_list():
		if str(name).to_lower().contains(fragment.to_lower()):
			current_animation_player.play(name)
			return true
	return false

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_6:
		show_candidate(event.physical_keycode - KEY_1)
	match event.physical_keycode:
		KEY_I: play_matching_clip("Idle")
		KEY_W:
			if not play_matching_clip("Walk"):
				play_matching_clip("Run")
		KEY_A:
			if not play_matching_clip("Bite") and not play_matching_clip("Attack"):
				play_matching_clip("Shoot")
