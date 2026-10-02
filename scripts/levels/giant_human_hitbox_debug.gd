class_name GiantHumanHitboxDebug
extends Node
## DIAGNOSTIC ONLY (GIANT HUMAN HITBOX INSTRUMENTATION 01). It reads the Giant Human's damage
## shapes and Bee, never writes to them: no hitbox, damage or movement is changed.
##   H          show / hide the human's hitboxes as translucent coloured volumes with their names
##   on damage  "DAÑO: <hitbox>, Bee x/y/z" on screen for 2 s, and a line in dev/logs/giant_human_damage.log
## The culprit comes from the physics engine itself (area_shape_entered on the human's hitbox),
## cross-checked with the distance from Bee's hurtbox centre to each enabled shape.

const LOG_DIR := "res://dev/logs"
const LOG_FILE := "res://dev/logs/giant_human_damage.log"
const DAMAGE_SECONDS := 2.0
const SHAPE_COLORS := {
	"LeftThigh": Color(1.0, 0.25, 0.25), "LeftLeg": Color(1.0, 0.6, 0.15),
	"RightThigh": Color(0.95, 0.9, 0.2), "RightLeg": Color(0.4, 0.9, 0.3),
	"Torso": Color(0.75, 0.3, 1.0),
}
const FALLBACK_COLOR := Color(1.0, 1.0, 1.0)
const BEE_COLOR := Color(0.2, 1.0, 1.0)

@export var human_path: NodePath = ^"../GiantHuman"
@export var bee_path: NodePath = ^"../BeePlayer"

var viewing := false
var damage_events: Array[Dictionary] = []

var _human: GiantHumanCrossingHazard
var _bee: Node3D
var _hurtbox_shape: CollisionShape3D
var _stage: Node
var _volumes := Node3D.new()
var _items: Dictionary = {} # CollisionShape3D -> {mesh, label, signature}
var _bee_item: Dictionary = {}
var _hud := Label.new()
var _damage_label := Label.new()
var _damage_left := 0.0
var _shape_entries: Array[Dictionary] = []
var _log: FileAccess


func _ready() -> void:
	_human = get_node_or_null(human_path) as GiantHumanCrossingHazard
	_bee = get_node_or_null(bee_path) as Node3D
	_stage = get_parent()
	if _human == null or _bee == null:
		push_error("GiantHumanHitboxDebug needs GiantHuman and BeePlayer")
		set_process(false)
		return
	_hurtbox_shape = _bee.get_node_or_null("Hurtbox3D/CollisionShape3D") as CollisionShape3D
	_volumes.top_level = true
	add_child(_volumes)
	_volumes.visible = false
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_hud.position = Vector2(16, 140)
	_hud.visible = false
	_style_label(_hud, 15, Color(1, 1, 1))
	_damage_label.position = Vector2(16, 110)
	_damage_label.visible = false
	_style_label(_damage_label, 24, Color(1.0, 0.45, 0.35))
	layer.add_child(_hud)
	layer.add_child(_damage_label)
	_human.hitbox.area_shape_entered.connect(_on_shape_entered)
	_human.hitbox.hit_confirmed.connect(_on_hit_confirmed)
	_human.phase_changed.connect(_on_phase_changed)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LOG_DIR))
	_log = FileAccess.open(LOG_FILE, FileAccess.READ_WRITE) if FileAccess.file_exists(LOG_FILE) else FileAccess.open(LOG_FILE, FileAccess.WRITE)
	if _log != null:
		_log.seek_end()
		_write("SESSION_START %s (H toggles hitbox view)" % Time.get_datetime_string_from_system())


func _style_label(label: Label, size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_H:
		set_viewing(not viewing)


func set_viewing(value: bool) -> void:
	viewing = value
	_volumes.visible = value
	_hud.visible = value
	_write("VIEW %s" % ("ON" if value else "OFF"))


func _process(delta: float) -> void:
	if _damage_left > 0.0:
		_damage_left -= delta
		_damage_label.visible = _damage_left > 0.0
	if viewing:
		_refresh_volumes()


# --- damage reporting -------------------------------------------------------------------------

func _on_shape_entered(_area_rid: RID, area: Area3D, _area_shape_index: int, local_shape_index: int) -> void:
	if not area is DamageHurtbox3D or (area as DamageHurtbox3D).owner_entity != _bee:
		return
	var owner_id := _human.hitbox.shape_find_owner(local_shape_index)
	var shape_node := _human.hitbox.shape_owner_get_owner(owner_id) as Node
	_shape_entries.append({"frame": Engine.get_physics_frames(), "name": str(shape_node.name) if shape_node != null else "shape#%d" % local_shape_index})


func _on_hit_confirmed(hurtbox: DamageHurtbox3D, applied_damage: int) -> void:
	if hurtbox.owner_entity != _bee:
		_write("OTHER_HIT (not Bee) target=%s damage=%d human_x=%.2f" % [hurtbox.owner_entity.name if hurtbox.owner_entity != null else hurtbox.name, applied_damage, _human.global_position.x])
		return
	# area_shape_entered and area_entered fire in the same physics step; read both after they ran.
	_report.call_deferred(hurtbox, applied_damage, Engine.get_physics_frames())


func _report(hurtbox: DamageHurtbox3D, applied_damage: int, frame: int) -> void:
	var engine_names: Array[String] = []
	for entry in _shape_entries:
		if absi(int(entry["frame"]) - frame) <= 1 and not engine_names.has(entry["name"]):
			engine_names.append(entry["name"])
	_shape_entries.clear()
	var bee_position := _bee.global_position
	var distances := _shape_distances(bee_position)
	var nearest := ""
	var best := INF
	for shape_name: String in distances:
		if distances[shape_name] < best:
			best = distances[shape_name]
			nearest = shape_name
	var culprit := ", ".join(engine_names) if not engine_names.is_empty() else "(motor sin forma: más cercana %s)" % nearest
	var text := "DAÑO: %s, posición de Bee x=%.2f y=%.2f z=%.2f" % [culprit, bee_position.x, bee_position.y, bee_position.z]
	_damage_label.text = text
	_damage_label.visible = true
	_damage_left = DAMAGE_SECONDS
	var event := {"engine_shapes": engine_names, "nearest_shape": nearest, "nearest_distance": best, "bee": bee_position, "human_x": _human.global_position.x, "damage": applied_damage}
	damage_events.append(event)
	var shapes := []
	for node in _shape_nodes():
		shapes.append("%s%s %s" % [node.name, "(off)" if node.disabled else "", _describe_bounds(node)])
	var anim_time := _human.animation_player.current_animation_position if _human.animation_player != null and _human.animation_player.is_playing() else -1.0
	_write("DAMAGE %s | damage=%d | bee_hp=%s | bee=(%.3f, %.3f, %.3f) | bee_minus_human_x=%.3f | human_x=%.3f | camera_x=%.3f | anim_t=%.3f | distances_to_bee_centre=%s | shapes=[%s]" % [
		text, applied_damage, str(hurtbox.health_component.current_health) if hurtbox.health_component != null else "?", bee_position.x, bee_position.y, bee_position.z,
		bee_position.x - _human.global_position.x, _human.global_position.x, _camera_x(), anim_time, _format_distances(distances), "; ".join(shapes)])



func _on_phase_changed(phase: int) -> void:
	if phase == GiantHumanCrossingHazard.Phase.CROSSING or phase == GiantHumanCrossingHazard.Phase.EXITED:
		var bee_position := _bee.global_position
		_write("%s human_x=%.2f camera_x=%.2f bee=(%.2f, %.2f)" % ["CROSSING_START" if phase == GiantHumanCrossingHazard.Phase.CROSSING else "CROSSING_END", _human.global_position.x, _camera_x(), bee_position.x, bee_position.y])


func _camera_x() -> float:
	var camera := _stage.get("camera") as Camera3D
	return camera.global_position.x if camera != null else NAN


func _write(line: String) -> void:
	print("[HUMAN_DEBUG] ", line)
	if _log != null:
		_log.store_line("%s  %s" % [Time.get_time_string_from_system(), line])
		_log.flush()


# --- geometry helpers -------------------------------------------------------------------------

func _shape_nodes() -> Array[CollisionShape3D]:
	var result: Array[CollisionShape3D] = []
	for child in _human.hitbox.get_children():
		if child is CollisionShape3D:
			result.append(child)
	return result


## Points of a shape in world space (convex slabs and boxes; other shapes use their debug mesh).
func _world_points(node: CollisionShape3D) -> PackedVector3Array:
	var result := PackedVector3Array()
	var shape := node.shape
	if shape is ConvexPolygonShape3D:
		for point in (shape as ConvexPolygonShape3D).points:
			result.append(node.global_transform * point)
	elif shape is BoxShape3D:
		var half := (shape as BoxShape3D).size * 0.5
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					result.append(node.global_transform * Vector3(half.x * sx, half.y * sy, half.z * sz))
	return result


func _describe_bounds(node: CollisionShape3D) -> String:
	var points := _world_points(node)
	if points.is_empty():
		return "?"
	var low := points[0]
	var high := points[0]
	for point in points:
		low = low.min(point)
		high = high.max(point)
	return "x[%.2f..%.2f] y[%.2f..%.2f] z[%.2f..%.2f]" % [low.x, high.x, low.y, high.y, low.z, high.z]


## 2D distance from Bee's centre to each enabled shape (slabs live in the Z=0 plane): <= Bee's radius means touching.
func _shape_distances(bee_position: Vector3) -> Dictionary:
	var result := {}
	for node in _shape_nodes():
		if node.disabled:
			continue
		var points := _world_points(node)
		if points.size() < 3:
			continue
		var flat := PackedVector2Array()
		for point in points:
			flat.append(Vector2(point.x, point.y))
		var hull := Geometry2D.convex_hull(flat)
		var here := Vector2(bee_position.x, bee_position.y)
		var distance := 0.0
		if not Geometry2D.is_point_in_polygon(here, hull):
			distance = INF
			for i in hull.size() - 1:
				distance = minf(distance, here.distance_to(Geometry2D.get_closest_point_to_segment(here, hull[i], hull[i + 1])))
		result[str(node.name)] = distance
	return result


func _format_distances(distances: Dictionary) -> String:
	var parts := []
	for shape_name: String in distances:
		parts.append("%s=%.2f" % [shape_name, distances[shape_name]])
	return "{" + ", ".join(parts) + "}"


# --- visualisation ----------------------------------------------------------------------------

func _refresh_volumes() -> void:
	var lines := ["HITBOXES DEL HUMANO (H)  fase=%s  hitbox %s" % [GiantHumanCrossingHazard.Phase.keys()[_human.current_phase], "ACTIVA" if _human.hitbox.enabled else "apagada"]]
	for node in _shape_nodes():
		var item := _item_for(node)
		var visible_now := not node.disabled and _human.hitbox.enabled
		item["mesh"].visible = visible_now
		item["label"].visible = visible_now
		lines.append("%s %s %s" % [node.name, "ON " if not node.disabled else "off", _describe_bounds(node) if not node.disabled else ""])
		if not visible_now:
			continue
		var signature := _signature(node)
		if signature != item["signature"]:
			item["signature"] = signature
			(item["mesh"] as MeshInstance3D).mesh = _build_mesh(node)
		var points := _world_points(node)
		var top := Vector3(0, -INF, 0)
		var centre := Vector3.ZERO
		for point in points:
			centre += point
			if point.y > top.y:
				top = point
		(item["label"] as Label3D).global_position = Vector3(centre.x / maxf(points.size(), 1), top.y + 0.25, 0.6)
	if _hurtbox_shape != null:
		_refresh_bee()
		lines.append("Bee hurtbox (cian)  centro=(%.2f, %.2f)  bee-humano x=%.2f" % [_bee.global_position.x, _bee.global_position.y, _bee.global_position.x - _human.global_position.x])
	_hud.text = "\n".join(lines)


func _signature(node: CollisionShape3D) -> int:
	var shape := node.shape
	if shape is ConvexPolygonShape3D:
		return hash((shape as ConvexPolygonShape3D).points)
	return hash(shape)


func _item_for(node: CollisionShape3D) -> Dictionary:
	if not _items.has(node):
		var color: Color = SHAPE_COLORS.get(str(node.name), FALLBACK_COLOR)
		_items[node] = _make_item(str(node.name), color)
	return _items[node]


func _make_item(label_text: String, color: Color) -> Dictionary:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color.r, color.g, color.b, 0.38)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = true
	material.render_priority = 100
	var mesh := MeshInstance3D.new()
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_volumes.add_child(mesh)
	var label := Label3D.new()
	label.text = label_text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.pixel_size = 0.0009
	label.font_size = 36
	label.outline_size = 12
	label.modulate = Color(color.r, color.g, color.b).lightened(0.35)
	label.render_priority = 101
	_volumes.add_child(label)
	return {"mesh": mesh, "label": label, "signature": 0}


## Filled prism for the convex slabs (world space); a box for BoxShape3D.
func _build_mesh(node: CollisionShape3D) -> Mesh:
	var points := _world_points(node)
	if points.size() < 4:
		return ArrayMesh.new()
	var flat := PackedVector2Array()
	var z_low := INF
	var z_high := -INF
	for point in points:
		flat.append(Vector2(point.x, point.y))
		z_low = minf(z_low, point.z)
		z_high = maxf(z_high, point.z)
	var hull := Geometry2D.convex_hull(flat)
	hull.remove_at(hull.size() - 1)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1, hull.size() - 1):
		for z in [z_low, z_high]:
			st.add_vertex(Vector3(hull[0].x, hull[0].y, z))
			st.add_vertex(Vector3(hull[i].x, hull[i].y, z))
			st.add_vertex(Vector3(hull[i + 1].x, hull[i + 1].y, z))
	for i in hull.size():
		var a := hull[i]
		var b := hull[(i + 1) % hull.size()]
		st.add_vertex(Vector3(a.x, a.y, z_low))
		st.add_vertex(Vector3(b.x, b.y, z_low))
		st.add_vertex(Vector3(b.x, b.y, z_high))
		st.add_vertex(Vector3(a.x, a.y, z_low))
		st.add_vertex(Vector3(b.x, b.y, z_high))
		st.add_vertex(Vector3(a.x, a.y, z_high))
	return st.commit()


func _refresh_bee() -> void:
	if _bee_item.is_empty():
		_bee_item = _make_item("Bee", BEE_COLOR)
		var sphere := SphereMesh.new()
		var shape := _hurtbox_shape.shape as SphereShape3D
		var radius := shape.radius if shape != null else 0.28
		sphere.radius = radius
		sphere.height = radius * 2.0
		sphere.radial_segments = 16
		sphere.rings = 8
		(_bee_item["mesh"] as MeshInstance3D).mesh = sphere
	(_bee_item["mesh"] as MeshInstance3D).global_position = _hurtbox_shape.global_position
	(_bee_item["label"] as Label3D).global_position = _hurtbox_shape.global_position + Vector3(0, 0.55, 0.6)
