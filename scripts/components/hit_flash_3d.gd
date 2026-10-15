class_name HitFlash3D
extends Node
const S := preload("res://scripts/game/bee_feedback_settings.gd")
@export_range(0.05, 0.5, 0.01) var duration: float = S.FLASH_SECONDS
@export var visual_root_path: NodePath = ^"../VisualRoot"
@export var health_path: NodePath = ^"../HealthComponent"
@export var flash_color: Color = S.FLASH_COLOR
var activation_count := 0
var _active := false
var _flash_tween: Tween
var _saved_overlays: Dictionary = {}
var _flash_material: StandardMaterial3D
var _legacy_material: StandardMaterial3D
var _outlined_materials: Dictionary = {}
var _lockout_left := 0.0

func _ready() -> void:
	_flash_material = StandardMaterial3D.new()
	_flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash_material.albedo_color = flash_color
	_flash_material.render_priority = S.OVERLAY_PRIORITY
	var health := get_node_or_null(health_path) as HealthComponent
	assert(health != null,"HitFlash3D requires a HealthComponent")
	health.health_changed.connect(_on_health_changed)
	health.died.connect(cancel)

func _physics_process(delta: float) -> void:
	_lockout_left = maxf(0,_lockout_left-delta)

func flash() -> void:
	if not S.legacy_flash and (_active or _lockout_left > 0): return
	cancel()
	var root := get_node_or_null(visual_root_path) as Node3D
	if root == null or not root.visible: return
	for mesh: MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh == null or mesh.get_meta("boss_visual_only",false): continue
		_saved_overlays[mesh] = mesh.material_overlay
		if S.legacy_flash:
			if _legacy_material == null:
				_legacy_material = _flash_material.duplicate() as StandardMaterial3D
				_legacy_material.albedo_color = Color(1,1,1,.9)
				_legacy_material.render_priority = 0
			mesh.material_overlay = _legacy_material
			continue
		# Keep the base materials and their next_pass untouched. Redraw exactly their
		# outline after the translucent tint, rather than whitening the silhouette.
		var source := mesh.get_active_material(0)
		var outline: Material = source.next_pass if source != null else null
		var key := outline.get_instance_id() if outline != null else 0
		if not _outlined_materials.has(key):
			var overlay := _flash_material.duplicate() as StandardMaterial3D
			if outline != null:
				var final_outline := outline.duplicate() as Material
				final_outline.render_priority = S.OUTLINE_PRIORITY
				overlay.next_pass = final_outline
			_outlined_materials[key] = overlay
		mesh.material_overlay = _outlined_materials[key]
	if _saved_overlays.is_empty(): return
	activation_count += 1
	_active = true
	_flash_tween = create_tween()
	_flash_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_flash_tween.tween_interval(duration)
	_flash_tween.tween_callback(_finish_flash)

func set_flash_color(color: Color) -> void:
	flash_color = color
	_outlined_materials.clear()
	if _flash_material != null: _flash_material.albedo_color = color

func cancel() -> void:
	if _flash_tween != null:
		_flash_tween.kill()
		_flash_tween = null
	_restore_overlays()
	_active = false

func is_flashing() -> bool: return _active

func _finish_flash() -> void:
	_flash_tween = null
	_restore_overlays()
	_active = false
	_lockout_left = S.FLASH_LOCKOUT

func _restore_overlays() -> void:
	for mesh in _saved_overlays:
		if is_instance_valid(mesh): mesh.material_overlay = _saved_overlays[mesh]
	_saved_overlays.clear()

func _on_health_changed(_current: int, _maximum: int, change: int) -> void:
	if change < 0: flash()
