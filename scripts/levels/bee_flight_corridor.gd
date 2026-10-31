extends Node
## Tanda S · F — pasillo limpio: el decorado que está en el plano de vuelo o delante de él (hojas de primer plano, campanillas,
## props grandes) y que en pantalla tapa a Bee o a un enemigo se vuelve CORRIDOR_ALPHA opaco mientras haya algo detrás.
## Solo dibujo: colisiones y gameplay no cambian. Los materiales toon se cambian por una copia translúcida (TOON_FADE) y
## vuelven al original cuando el prop deja de tapar. Los obstáculos destructibles (latas, cajas) NO se tocan: son juego.
const HERO := preload("res://scripts/game/bee_hero_look_settings.gd")
const FADE_SHADER := preload("res://assets/style/toon_body_fade.gdshader")
const SCREEN_RANGE := 14.0 # m desde la cámara en X: más lejos no se revisa.

var stage: BeeShmupStage
var candidates: Array[GeometryInstance3D] = []
var faded: Dictionary = {} # mesh -> {"value": float, "originals": Array, "copies": Array}
var _clock := 0.0
var _covering: Dictionary = {} # meshes que tapan algo en este momento


static func attach(level: BeeShmupStage) -> Node:
	if not HERO.HERO_LOOK_ENABLED:
		return null
	var corridor: Node = (load("res://scripts/levels/bee_flight_corridor.gd") as GDScript).new()
	corridor.name = "FlightCorridor"
	corridor.set("stage", level)
	level.add_child(corridor)
	return corridor


func _ready() -> void:
	_collect.call_deferred()


func _collect() -> void:
	candidates.clear()
	for owner_name in HERO.CORRIDOR_OWNERS:
		var root := stage.get_node_or_null(owner_name)
		if root == null:
			continue
		for mesh: GeometryInstance3D in root.find_children("*", "MeshInstance3D", true, false):
			if not mesh is MeshInstance3D or (mesh as MeshInstance3D).mesh == null:
				continue
			var box := mesh.global_transform * mesh.get_aabb()
			# El centro tiene que estar en el plano de vuelo o delante: lo que queda detrás de Bee nunca la tapa.
			if box.get_center().z < HERO.CORRIDOR_MIN_Z or box.end.y < stage.flight_bottom or box.size.y > 30.0:
				continue
			candidates.append(mesh)


func _process(delta: float) -> void:
	if stage == null or stage.camera == null:
		return
	_clock -= delta
	if _clock <= 0.0:
		_clock = HERO.CORRIDOR_CHECK_SECONDS
		_covering = _find_covering()
	for mesh in _covering:
		if not faded.has(mesh) and is_instance_valid(mesh):
			_begin_fade(mesh)
	var step := delta / HERO.CORRIDOR_FADE_SECONDS * (1.0 - HERO.CORRIDOR_ALPHA)
	for mesh in faded.keys():
		var entry: Dictionary = faded[mesh]
		if not is_instance_valid(mesh):
			faded.erase(mesh)
			continue
		var target := HERO.CORRIDOR_ALPHA if _covering.has(mesh) else 1.0
		entry["value"] = move_toward(float(entry["value"]), target, step)
		for copy: Material in entry["copies"]:
			_set_alpha(copy, float(entry["value"]))
		if is_equal_approx(float(entry["value"]), 1.0) and not _covering.has(mesh):
			_restore(mesh, entry)
			faded.erase(mesh)


## Puntos de pantalla de Bee y de los enemigos activos.
func actor_points() -> Array[Vector2]:
	var camera := stage.camera
	var points: Array[Vector2] = []
	var actors: Array[Node3D] = [stage.bee]
	for node in get_tree().get_nodes_in_group("bee_auto_aim_targets"):
		if node is Node3D and (node as Node3D).is_visible_in_tree():
			actors.append(node)
	for actor in actors:
		if is_instance_valid(actor) and not camera.is_position_behind(actor.global_position):
			points.append(camera.unproject_position(actor.global_position))
	return points


func _find_covering() -> Dictionary:
	var result := {}
	var camera := stage.camera
	var points := actor_points()
	for mesh in candidates:
		if not is_instance_valid(mesh) or not mesh.is_visible_in_tree():
			continue
		var box := mesh.global_transform * mesh.get_aabb()
		if absf(box.get_center().x - camera.global_position.x) > SCREEN_RANGE + box.size.x * 0.5:
			continue
		var rect := _screen_rect(camera, box)
		if rect.size == Vector2.ZERO:
			continue
		for point in points:
			if rect.grow(HERO.CORRIDOR_PAD_PX).has_point(point):
				result[mesh] = true
				break
	return result


func _screen_rect(camera: Camera3D, box: AABB) -> Rect2:
	var rect := Rect2()
	var first := true
	for i in 8:
		var corner := box.get_endpoint(i)
		if camera.is_position_behind(corner):
			return Rect2()
		var point := camera.unproject_position(corner)
		if first:
			rect = Rect2(point, Vector2.ZERO)
			first = false
		else:
			rect = rect.expand(point)
	return rect


func _begin_fade(mesh: GeometryInstance3D) -> void:
	var instance := mesh as MeshInstance3D
	var entry := {"value": 1.0, "originals": [], "copies": [], "override": instance.material_override}
	if instance.material_override != null:
		var copy := _translucent(instance.material_override)
		instance.material_override = copy
		entry["copies"].append(copy)
	else:
		for surface in instance.mesh.get_surface_count():
			entry["originals"].append(instance.get_surface_override_material(surface))
			var copy := _translucent(instance.get_active_material(surface))
			instance.set_surface_override_material(surface, copy)
			if copy != null:
				entry["copies"].append(copy)
	faded[mesh] = entry


func _restore(mesh: GeometryInstance3D, entry: Dictionary) -> void:
	var instance := mesh as MeshInstance3D
	if entry["override"] != null:
		instance.material_override = entry["override"]
		return
	var originals: Array = entry["originals"]
	for surface in originals.size():
		instance.set_surface_override_material(surface, originals[surface])


func _translucent(source: Material) -> Material:
	if source is ShaderMaterial:
		var copy := (source as ShaderMaterial).duplicate() as ShaderMaterial
		copy.shader = FADE_SHADER # Mismos parámetros que el toon; se pierde el contorno mientras está translúcido.
		copy.next_pass = null
		return copy
	if source is BaseMaterial3D:
		var copy := (source as BaseMaterial3D).duplicate() as BaseMaterial3D
		copy.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		copy.next_pass = null
		copy.set_meta("corridor_alpha", copy.albedo_color.a)
		return copy
	return source


func _set_alpha(material: Material, value: float) -> void:
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("fade", value)
	elif material is BaseMaterial3D:
		var base := material as BaseMaterial3D
		base.albedo_color.a = float(base.get_meta("corridor_alpha", 1.0)) * value
