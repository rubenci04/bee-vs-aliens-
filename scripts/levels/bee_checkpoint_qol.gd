class_name BeeCheckpointQoL
extends Node

const HANDOFF := &"bee_level_01_checkpoint_handoff"
@export var checkpoint_x := 190.0
@export var protection_seconds := 1.25
var checkpoint_active := false
var snapshot: Dictionary = {}
var protection_left := 0.0
var activation_count := 0
var stage: BeeShmupStage
var notice: Label
var pause_label: Label
var controls_hint: Label
var beacon: Node3D
var _notice_left := 0.0
var _hint_left := 5.0

func setup(value: BeeShmupStage) -> void:
	stage = value
	process_mode = Node.PROCESS_MODE_ALWAYS
	notice = label("CheckpointNotice", "", Vector2(430, 180), 28)
	pause_label = label("PauseNotice", "PAUSED · ESC", Vector2(420, 275), 32)
	controls_hint = label("ControlsHint", "X FIRE   Z STING   C BOMB · ESC PAUSE · SHIFT+R FULL RESTART", Vector2(18, 165), 18)
	create_beacon()
	controls_hint.show()
	if get_tree().has_meta(HANDOFF):
		snapshot = get_tree().get_meta(HANDOFF).duplicate(true)
		get_tree().remove_meta(HANDOFF) # One-use handoff, never a save or singleton.
		restore_snapshot()

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
	material.albedo_color = Color(0.15, 0.85, 0.78)
	var post := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.18, 1.7, 0.18)
	box.material = material
	post.mesh = box
	post.position.y = 0.85
	beacon.add_child(post)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.36
	torus.outer_radius = 0.46
	torus.rings = 12
	torus.ring_segments = 6
	torus.material = material
	ring.mesh = torus
	ring.position.y = 1.8
	ring.rotation.x = PI * 0.5
	beacon.add_child(ring)
	var title := Label3D.new()
	title.text = "CHECKPOINT"
	title.position.y = 2.5
	title.font_size = 40
	title.pixel_size = 0.009
	beacon.add_child(title)

func _process(delta: float) -> void:
	if stage == null:
		return
	if Input.is_action_just_pressed("bee_full_restart"):
		restart_level(true)
		return
	if Input.is_action_just_pressed("bee_pause"):
		get_tree().paused = not get_tree().paused
		pause_label.visible = get_tree().paused
	if get_tree().paused:
		return
	if stage.bee.is_defeated:
		if Input.is_action_just_pressed("restart"):
			restart_level(false)
		return
	if not checkpoint_active and stage.distance >= checkpoint_x and not stage.wave._waiting_for_human:
		activate_checkpoint()
	_notice_left = maxf(0.0, _notice_left - delta)
	notice.visible = _notice_left > 0.0
	_hint_left = maxf(0.0, _hint_left - delta)
	controls_hint.visible = _hint_left > 0.0
	if protection_left > 0.0:
		protection_left = maxf(0.0, protection_left - delta)
		stage.bee.visual_root.visible = protection_left == 0.0 or int(protection_left * 10) % 2 == 0
		stage.bee.health.damage_blocked = protection_left > 0.0

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
	for crate in stage.get_node("Destructibles").get_children():
		if crate.position.x < checkpoint_x and crate.is_destroyed:
			broken.append(str(crate.name))
	snapshot = {"distance": checkpoint_x, "bee_position": Vector3(checkpoint_x, 5.4, 0),
		"hp": bee.health.current_health, "spread": bee.spread_ammo, "bomb": bee.bomb_charges,
		"pollen": stage.pollen_count, "pollen_available": available_names("Pollen"),
		"powerups_available": available_names("Powerups"), "broken": broken,
		"elapsed": stage.elapsed_seconds, "taught": stage.get_node("CanvasLayer/WeaponsHUD").taught.duplicate(true)}
	notice.text = "CHECKPOINT"
	_notice_left = 1.4
	notice.show()
	BeeAudio.play(stage, &"spread_pickup", beacon.global_position + Vector3(0, 1.8, 0))

func restore_snapshot() -> void:
	checkpoint_active = true
	activation_count = 1
	stage.distance = snapshot["distance"]
	stage.elapsed_seconds = snapshot["elapsed"]
	stage.pollen_count = snapshot["pollen"]
	stage._update_camera_and_bounds()
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
	for pair in [["Pollen", "pollen_available"], ["Powerups", "powerups_available"]]:
		for item in stage.get_node(pair[0]).get_children():
			if item.position.x < checkpoint_x or str(item.name) not in snapshot[pair[1]]:
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
	protection_left = protection_seconds
	bee.health.damage_blocked = true
	_hint_left = 0.0
	controls_hint.hide()
	notice.text = "RESPAWN · PROTECTED"
	_notice_left = protection_seconds
	notice.show()

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
