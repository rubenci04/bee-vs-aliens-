class_name HitFlash3D
extends Node

@export_range(0.05, 0.5, 0.01) var duration: float = 0.10
@export var visual_root_path: NodePath = ^"../VisualRoot"
@export var health_path: NodePath = ^"../HealthComponent"
@export var flash_color: Color = Color(1.0, 0.96, 0.68, 0.72)

var activation_count := 0
var _active := false
var _flash_tween: Tween
var _saved_overlays: Dictionary = {}
var _flash_material: StandardMaterial3D


func _ready() -> void:
	_flash_material = StandardMaterial3D.new()
	_flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash_material.albedo_color = flash_color
	var health := get_node_or_null(health_path) as HealthComponent
	assert(health != null, "HitFlash3D requires a HealthComponent")
	health.health_changed.connect(_on_health_changed)
	health.died.connect(cancel)


func flash() -> void:
	cancel()
	var visual_root := get_node_or_null(visual_root_path) as Node3D
	if visual_root == null or not visual_root.visible:
		return
	for node in visual_root.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		_saved_overlays[mesh] = mesh.material_overlay
		mesh.material_overlay = _flash_material
	if _saved_overlays.is_empty():
		return
	activation_count += 1
	_active = true
	_flash_tween = create_tween()
	_flash_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_flash_tween.tween_interval(duration)
	_flash_tween.tween_callback(_finish_flash)


func cancel() -> void:
	if _flash_tween != null:
		_flash_tween.kill()
		_flash_tween = null
	_restore_overlays()
	_active = false


func is_flashing() -> bool:
	return _active


func _finish_flash() -> void:
	_flash_tween = null
	_restore_overlays()
	_active = false


func _restore_overlays() -> void:
	for mesh in _saved_overlays:
		if is_instance_valid(mesh):
			(mesh as MeshInstance3D).material_overlay = _saved_overlays[mesh]
	_saved_overlays.clear()


func _on_health_changed(_current: int, _maximum: int, change: int) -> void:
	if change < 0:
		flash()
