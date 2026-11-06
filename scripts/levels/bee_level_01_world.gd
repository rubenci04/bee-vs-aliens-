class_name BeeLevel01World
extends Node3D
## Mejora visual: el jardín cambia de verdad a lo largo del nivel. Césped con franjas de corte, macizo de flores con muro de ladrillo,
## huerta con surcos e invernadero, sombra húmeda bajo hojas gigantes y patio de baldosas con la casa encendida. La tarántula pelea de noche.
## Solo presentación: sin colisiones ni nada que toque la jugabilidad. Interruptor: BeeWorldSettings WORLD_ENABLED.
const S := preload("res://scripts/game/bee_world_settings.gd")
const GROUND := preload("res://assets/style/garden_ground.gdshader")
const SKY := preload("res://assets/style/garden_sky.gdshader")
const TUFT := preload("res://assets/style/grass_tuft.gdshader")
const SHAFT := preload("res://assets/style/light_shaft.gdshader")
const GRADE := preload("res://assets/style/screen_grade.gdshader")
const SHEET := preload("res://assets/style/world_sheet.gdshader")
const BACKDROP_SHADER := preload("res://assets/style/world_backdrop.gdshader")
const CANOPY_SHADER := preload("res://assets/style/canopy_leaf.gdshader")
const SKY_RADIUS := 900.0
const LIFE_SEED := 7171

## Piezas por zona: [plantilla, X inicial, X final, paso mínimo, paso máximo, Z mínima, Z máxima, escala mínima, escala máxima].
const LIFE := [
	# --- Césped: flores silvestres, pelota, regador. ---
	[&"daisy", -8.0, 66.0, 4.0, 9.0, -12.0, -4.5, 0.9, 1.25], [&"dandelion", -8.0, 70.0, 5.0, 11.0, -14.0, -5.0, 0.9, 1.3], [&"clover", -8.0, 70.0, 2.4, 5.0, -8.0, 1.6, 0.8, 1.2],
	[&"toadstool", 6.0, 60.0, 16.0, 26.0, -9.0, -4.5, 0.8, 1.15], [&"ball", 24.0, 30.0, 40.0, 41.0, -9.0, -8.0, 1.2, 1.2], [&"sprinkler", 48.0, 52.0, 40.0, 41.0, -6.0, -5.6, 1.0, 1.0],
	# --- Macizo: masas de color atrás, poco adelante. ---
	[&"tulips", 60.0, 190.0, 4.5, 8.0, -12.0, -5.2, 0.95, 1.3], [&"rose_bush", 64.0, 188.0, 6.5, 11.0, -15.0, -7.0, 1.1, 1.6], [&"lavender", 64.0, 186.0, 7.0, 13.0, -9.0, -5.0, 1.0, 1.3],
	[&"sunflower", 70.0, 188.0, 11.0, 19.0, -16.0, -10.0, 1.0, 1.3], [&"brick_edge", 64.0, 186.0, 3.3, 3.31, -3.3, -3.2, 0.85, 0.85], [&"trellis", 78.0, 180.0, 24.0, 38.0, -19.5, -19.0, 1.4, 1.6],
	# --- Huerta: surcos con verduras, estacas y calabazas. ---
	[&"lettuce", 186.0, 262.0, 3.0, 5.2, -8.0, -4.4, 0.95, 1.25], [&"carrots", 186.0, 262.0, 6.0, 10.0, -11.0, -6.0, 1.0, 1.2], [&"tomato", 188.0, 260.0, 5.5, 9.0, -15.0, -9.5, 1.0, 1.25],
	[&"pumpkin", 190.0, 260.0, 11.0, 19.0, -10.0, -5.5, 0.85, 1.2], [&"seed_sign", 190.0, 258.0, 12.0, 20.0, -4.8, -4.2, 0.9, 1.1], [&"wheelbarrow", 226.0, 230.0, 80.0, 81.0, -11.0, -10.0, 1.4, 1.4],
	# --- Sombra: helechos, hostas y hongos pálidos. ---
	[&"fern", 262.0, 298.0, 2.4, 4.4, -11.0, -4.4, 1.0, 1.4], [&"hosta", 262.0, 298.0, 4.6, 8.0, -14.0, -5.5, 1.0, 1.4], [&"mushrooms", 262.0, 298.0, 4.0, 7.5, -8.0, -4.2, 1.0, 1.4],
	[&"mossy_log", 276.0, 277.0, 40.0, 41.0, -8.0, -7.8, 1.0, 1.0],
	# --- Patio: macetas, faroles, muebles. ---
	[&"flower_pot", 296.0, 372.0, 9.0, 15.0, -8.0, -4.6, 0.9, 1.3], [&"lantern", 300.0, 372.0, 15.0, 21.0, -7.0, -5.2, 1.1, 1.35], [&"chair", 312.0, 372.0, 26.0, 34.0, -14.0, -11.0, 1.0, 1.15],
	[&"table", 324.0, 325.0, 60.0, 61.0, -16.0, -15.0, 1.15, 1.15], [&"bbq", 352.0, 353.0, 60.0, 61.0, -11.0, -10.0, 1.0, 1.0], [&"clothesline", 310.0, 311.0, 60.0, 61.0, -20.0, -19.5, 1.0, 1.0],
	# --- Basura de picnic: latas, caramelos, chupetines y envoltorios en todo el jardín. ---
	[&"soda_can", 8.0, 372.0, 24.0, 42.0, -7.0, -4.2, 0.8, 1.1], [&"lollipop", 20.0, 372.0, 28.0, 50.0, -8.5, -4.8, 0.7, 1.0], [&"candy", 4.0, 372.0, 15.0, 28.0, -5.5, -3.6, 0.8, 1.1],
	[&"wrapper", 0.0, 372.0, 11.0, 22.0, -6.0, 3.0, 0.7, 1.0], [&"popsicle", 12.0, 372.0, 24.0, 40.0, -5.0, 2.8, 0.7, 1.0], [&"bottle_cap", 0.0, 372.0, 12.0, 24.0, -5.0, 3.2, 0.7, 1.1],
]
## Piezas sueltas: [plantilla, X, Z, escala, giro]. Los muros reemplazan a la cerca fuera del césped.
const LANDMARKS := [
	[&"scarecrow", 214.0, -16.0, 1.25, 0.0],
	[&"trunk", 268.0, -14.0, 1.25, 20.0], [&"trunk", 284.0, -18.0, 1.5, 70.0], [&"trunk", 292.0, -11.5, 1.0, 110.0],
	[&"house_wall", 318.0, -38.0, 1.0, 0.0], [&"house_wall", 372.0, -40.0, 1.0, 0.0],
]
## Lejos: sin contorno, con aire encima.
const DISTANT_LANDMARKS := [[&"greenhouse", 204.0, -48.0, 1.5, 12.0], [&"greenhouse", 246.0, -52.0, 1.3, -8.0]]
const CANOPY_FROM := 256.0
const CANOPY_TO := 300.0
const CANOPY_STEP := 3.0
## Fondo lejano por zona (sin contorno ni sombra): [plantilla, X inicial, X final, paso, Z mín, Z máx, escala mín, escala máx].
const BACKDROP := [
	[&"hill", -50.0, 420.0, 30.0, -112.0, -92.0, 1.2, 1.9],
	[&"round_tree", -30.0, 80.0, 16.0, -84.0, -58.0, 0.8, 1.25], [&"poplar", 60.0, 190.0, 11.0, -82.0, -56.0, 0.75, 1.1],
	[&"round_tree", 186.0, 262.0, 21.0, -86.0, -62.0, 0.8, 1.3], [&"poplar", 262.0, 300.0, 8.0, -70.0, -44.0, 1.0, 1.4],
	[&"roof_house", 296.0, 400.0, 38.0, -80.0, -66.0, 0.9, 1.2],
]

var stage: Node
var ground_material: ShaderMaterial
var sky_material: ShaderMaterial
var sky_dome: MeshInstance3D
var shafts: Array[MeshInstance3D] = []
var shaft_materials: Array[ShaderMaterial] = []
var overlay_material: ShaderMaterial
var air: GPUParticles3D
var air_material: StandardMaterial3D
var tufts: Array[MultiMeshInstance3D] = []
var life_meshes: Array[MeshInstance3D] = []
var hidden_nodes: Array[Node3D] = []
var _last_x := -99999.0
var _solid_material: ShaderMaterial
var _sheet_material: ShaderMaterial
var _back_material: ShaderMaterial
var _wall_material: ShaderMaterial
var _canopy_material: ShaderMaterial
var _chunks: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _combat := 0.0
var _zone := -1
var _zone_label: Label


static func attach(parent: Node) -> BeeLevel01World:
	if not S.world_active():
		return null
	var world := BeeLevel01World.new()
	world.name = "World"
	world.stage = parent
	parent.add_child(world)
	return world


func _ready() -> void:
	_rng.seed = LIFE_SEED
	var progression := stage.get_node_or_null("LightProgression") as BeeLevel01LightProgression
	if progression != null:
		progression.external_light = true
	BeeLevel01AssetDressing.sun_by_world = true
	_restyle_ground()
	_tint_batches()
	_swap_boundaries()
	_build_tufts()
	_build_life()
	_build_backdrop()
	_flush_chunks()
	_build_sky()
	_build_shafts()
	_build_air()
	_build_overlay()
	_apply_light(float(stage.get("distance")))
	_lighten_shadows()


## Rendimiento: el pase de sombras era la mitad de los draw calls y Bee sola gastaba unos 440. Bee ya tiene su sombra suave en el suelo,
## lo lejano casi no se ve proyectar sombra, y dos cortes de sombra alcanzan para este estilo.
func _lighten_shadows() -> void:
	var sun := stage.get_node("Sun") as DirectionalLight3D
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = S.SHADOW_DISTANCE
	var bee := stage.get("bee") as Node3D
	if bee != null:
		for mesh: GeometryInstance3D in bee.find_children("*", "GeometryInstance3D", true, false):
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for owner_name in ["AssetDressing", "VisualTarget01", "DomesticGarden01", "GroundLife01", "LivingGarden", "Scenery"]:
		var owner_node := stage.get_node_or_null(owner_name)
		if owner_node == null:
			continue
		for mesh: GeometryInstance3D in owner_node.find_children("*", "GeometryInstance3D", true, false):
			var box := mesh.get_aabb()
			var far_z: float = (mesh.global_transform * box).get_center().z
			if far_z < S.SHADOW_CAST_MIN_Z or mesh is MultiMeshInstance3D:
				mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _exit_tree() -> void:
	BeeLevel01AssetDressing.sun_by_world = false


# --- suelo ---------------------------------------------------------------------------------------------------------

## El suelo plano y sus parches hexagonales dejan lugar al suelo pintado por zonas.
func _restyle_ground() -> void:
	var target := stage.get_node_or_null("VisualTarget01")
	if target == null:
		return
	ground_material = ShaderMaterial.new()
	ground_material.shader = GROUND
	ground_material.set_shader_parameter("edge_lawn", S.EDGE_LAWN)
	ground_material.set_shader_parameter("edge_bed", S.EDGE_BED)
	ground_material.set_shader_parameter("edge_patch", S.EDGE_PATCH)
	ground_material.set_shader_parameter("edge_shade", S.EDGE_SHADE)
	var slab := target.get_node_or_null("MulchGround") as MeshInstance3D
	if slab != null:
		slab.material_override = ground_material
	for node in target.get_children():
		var label := str(node.name)
		if label.begins_with("Batch_") and ("_mulch" in label or "_leaf_fallen" in label):
			(node as Node3D).hide()
			hidden_nodes.append(node)


## Cada tramo de hojas y tallos toma el tinte de su zona: el mismo pasto no se ve igual en la huerta que en la sombra.
func _tint_batches() -> void:
	var target := stage.get_node_or_null("VisualTarget01")
	if target == null:
		return
	var cache := {}
	for node in target.get_children():
		var mesh := node as MeshInstance3D
		var label := str(node.name)
		if mesh == null or not label.begins_with("Batch_c"):
			continue
		var material := mesh.material_override as ShaderMaterial
		if material == null:
			continue
		var chunk := label.substr(7, label.find("_", 7) - 7).to_int()
		var zone := S.zone_at((float(chunk) + 0.5) * BeeLevel01VisualTarget.CHUNK_WIDTH)
		if not (("_grass" in label) or ("_stem" in label) or ("_far_" in label) or ("_veil" in label) or ("_foreground" in label)):
			continue
		var key := "%d|%d" % [material.get_instance_id(), zone]
		if not cache.has(key):
			var copy := material.duplicate() as ShaderMaterial
			var base: Color = material.get_shader_parameter("albedo")
			var tint: Color = S.ZONE_TINT[zone]
			copy.set_shader_parameter("albedo", Color(minf(base.r * tint.r, 1.0), minf(base.g * tint.g, 1.0), minf(base.b * tint.b, 1.0)))
			cache[key] = copy
		mesh.material_override = cache[key]


## La cerca blanca es del césped. Después hay muro de ladrillo, tablones y seto; en el patio, la pared de la casa.
func _swap_boundaries() -> void:
	var dressing := stage.get_node_or_null("AssetDressing") as BeeLevel01AssetDressing
	if dressing != null:
		for item in dressing.litter:
			var at := item.position
			if absf(at.z - BeeLevel01AssetDressing.FENCE_Z) < 0.01 and at.x > S.EDGE_LAWN - 2.0:
				item.hide()
				hidden_nodes.append(item)
			if absf(at.z - BeeLevel01AssetDressing.HOUSE_Z) < 0.01 and at.x > S.EDGE_LAWN:
				item.hide() # Más atrás hay un fondo propio de cada zona.
				hidden_nodes.append(item)
	var x := S.EDGE_LAWN - 1.0
	while x < S.EDGE_SHADE + 6.0:
		var zone := S.zone_at(x + 3.0)
		var piece: StringName = [&"brick_wall", &"brick_wall", &"board_wall", &"hedge", &"hedge"][zone]
		_place(piece, Vector3(x, BeeLevel01VisualTarget.GROUND_Y, BeeLevel01AssetDressing.FENCE_Z), 1.0, 0.0, true, &"wall")
		x += 14.6 if piece == &"hedge" else 7.2


# --- pasto ---------------------------------------------------------------------------------------------------------

func _tuft_mesh() -> ArrayMesh:
	var kit := BeeMeshKit.new()
	for i in 5:
		var yaw := 72.0 * i + 13.0
		kit.leaf(Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.RIGHT, deg_to_rad(10.0 + i * 3.0)), Vector3.ZERO), 1.0 - (i % 3) * 0.14, 0.22, Color.WHITE, Color.WHITE, 0.12, 2)
	var uvs := PackedVector2Array()
	for point in kit.lv:
		uvs.append(Vector2(0.0, clampf(point.y, 0.0, 1.0)))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = kit.lv
	arrays[Mesh.ARRAY_NORMAL] = kit.ln
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _build_tufts() -> void:
	var mesh := _tuft_mesh()
	var material := ShaderMaterial.new()
	material.shader = TUFT
	var x := -40.0
	while x < 410.0:
		var zone_counts: Array[Array] = []
		for i in 5:
			zone_counts.append([])
		var total := 0
		var z_span: float = S.TUFT_Z.y - S.TUFT_Z.x
		var step := 1.0
		var sample_x := x
		var transforms: Array[Transform3D] = []
		var colors: Array[Color] = []
		while sample_x < x + S.TUFT_CHUNK:
			var zone := S.zone_at(sample_x)
			var spec: Array = S.TUFT_DENSITY[zone]
			var count := int(round(float(spec[0]) * step * z_span))
			for k in count:
				var at := Vector3(sample_x + _rng.randf() * step, BeeLevel01VisualTarget.GROUND_Y, _rng.randf_range(S.TUFT_Z.x, S.TUFT_Z.y))
				var height := _rng.randf_range(float(spec[1]), float(spec[2]))
				if at.z > S.TUFT_LOW_FROM_Z:
					height *= S.TUFT_LOW_SCALE
				var yaw := _rng.randf() * TAU
				var width := height * _rng.randf_range(1.1, 1.8)
				transforms.append(Transform3D(Basis(Vector3.UP, yaw).scaled_local(Vector3(width, height, width)), at))
				var mix_color: Color = (spec[3] as Color).lerp(spec[4] as Color, _rng.randf())
				colors.append(mix_color.srgb_to_linear())
				total += 1
			sample_x += step
		if total > 0:
			var multi := MultiMesh.new()
			multi.transform_format = MultiMesh.TRANSFORM_3D
			multi.use_colors = true
			multi.mesh = mesh
			multi.instance_count = total
			for i in total:
				multi.set_instance_transform(i, transforms[i])
				multi.set_instance_color(i, colors[i])
			var instance := MultiMeshInstance3D.new()
			instance.name = "Tufts_%d" % int(x)
			instance.multimesh = multi
			instance.material_override = material
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(instance)
			tufts.append(instance)
		x += S.TUFT_CHUNK


# --- decorado horneado -----------------------------------------------------------------------------------------------

func _chunk_for(x: float, group: StringName) -> BeeMeshKit:
	var key := "%d|%s" % [floori(x / S.LIFE_CHUNK), group]
	if not _chunks.has(key):
		_chunks[key] = BeeMeshKit.new()
	return _chunks[key]


func _place(id: StringName, at: Vector3, scale_factor: float, yaw_deg: float, shadows := true, group_override := &"") -> void:
	var template := BeeMeshKit.template(id)
	var t := BeeMeshKit.xf(at, Vector3(0, yaw_deg, 0), Vector3.ONE * scale_factor)
	var normal_t := Transform3D(t.basis.orthonormalized(), Vector3.ZERO)
	var group: StringName = group_override if group_override != &"" else (&"near" if shadows else &"quiet")
	var solid := _chunk_for(at.x, group)
	if not template.v.is_empty():
		solid.v.append_array(t * template.v)
		solid.n.append_array(normal_t * template.n)
		solid.c.append_array(template.c)
	if not template.lv.is_empty():
		var sheet := _chunk_for(at.x, group)
		sheet.lv.append_array(t * template.lv)
		sheet.ln.append_array(normal_t * template.ln)
		sheet.lc.append_array(template.lc)


func _build_life() -> void:
	for spec in LIFE:
		var x := float(spec[1]) + _rng.randf() * float(spec[3])
		while x < float(spec[2]):
			var z := _rng.randf_range(float(spec[5]), float(spec[6]))
			_place(spec[0], Vector3(x, BeeLevel01VisualTarget.GROUND_Y, z), _rng.randf_range(float(spec[7]), float(spec[8])), _rng.randf_range(-35.0, 35.0))
			x += _rng.randf_range(float(spec[3]), float(spec[4]))
	for spec in LANDMARKS:
		_place(spec[0], Vector3(float(spec[1]), BeeLevel01VisualTarget.GROUND_Y, float(spec[2])), float(spec[3]), float(spec[4]))
	for spec in DISTANT_LANDMARKS:
		_place(spec[0], Vector3(float(spec[1]), BeeLevel01VisualTarget.GROUND_Y, float(spec[2])), float(spec[3]), float(spec[4]), false)
	# Hojas gigantes arriba de la pantalla: el techo de la zona de sombra.
	var x := CANOPY_FROM
	while x < CANOPY_TO:
		var at := Vector3(x + _rng.randf() * 2.0, _rng.randf_range(10.5, 13.5), _rng.randf_range(-10.0, -2.0))
		var template := BeeMeshKit.template(&"canopy_leaf")
		var t := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU) * Basis(Vector3.RIGHT, deg_to_rad(_rng.randf_range(100.0, 118.0))).scaled_local(Vector3.ONE * _rng.randf_range(0.8, 1.15)), at)
		var chunk := _chunk_for(x, &"canopy")
		chunk.lv.append_array(t * template.lv)
		chunk.ln.append_array(Transform3D(t.basis.orthonormalized(), Vector3.ZERO) * template.ln)
		chunk.lc.append_array(template.lc)
		x += CANOPY_STEP


func _build_backdrop() -> void:
	for spec in BACKDROP:
		var x := float(spec[1]) + _rng.randf() * float(spec[3])
		while x < float(spec[2]):
			_place(spec[0], Vector3(x, BeeLevel01VisualTarget.GROUND_Y, _rng.randf_range(float(spec[4]), float(spec[5]))), _rng.randf_range(float(spec[6]), float(spec[7])), _rng.randf_range(-25.0, 25.0), false)
			x += float(spec[3]) * _rng.randf_range(0.7, 1.3)


## El decorado se apaga un poco y se aclara: los colores fuertes son de Bee, los enemigos y los ítems.
func _linear(colors: PackedColorArray, saturation: float) -> PackedColorArray:
	var out := PackedColorArray()
	out.resize(colors.size())
	for i in colors.size():
		var col := colors[i]
		var gray := col.get_luminance()
		col = Color(gray, gray, gray).lerp(col, saturation)
		out[i] = col.lerp(Color.WHITE, S.DECOR_LIFT).srgb_to_linear()
	return out


func _commit(vertices: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray, material: Material, label: String, shadows: bool, saturation := S.DECOR_SATURATION) -> void:
	if vertices.is_empty():
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = _linear(colors, saturation)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	life_meshes.append(node)


func _flush_chunks() -> void:
	_solid_material = ShaderMaterial.new()
	_solid_material.shader = BeeToonStyle.TOON
	_solid_material.set_shader_parameter("use_vertex_color", true)
	_solid_material.set_shader_parameter("rim_strength", 0.12)
	_solid_material.next_pass = BeeToonStyle.shared_outline(BeeToonStyle.OUTLINE_PROP)
	_wall_material = ShaderMaterial.new()
	_wall_material.shader = BeeToonStyle.TOON
	_wall_material.set_shader_parameter("use_vertex_color", true)
	_wall_material.set_shader_parameter("rim_strength", 0.0)
	_sheet_material = ShaderMaterial.new()
	_sheet_material.shader = SHEET
	_back_material = ShaderMaterial.new()
	_back_material.shader = BACKDROP_SHADER
	_canopy_material = ShaderMaterial.new()
	_canopy_material.shader = CANOPY_SHADER
	var keys := _chunks.keys()
	keys.sort()
	for key: String in keys:
		var kit: BeeMeshKit = _chunks[key]
		var group := key.get_slice("|", 1)
		match group:
			"quiet":
				_commit(kit.v, kit.n, kit.c, _back_material, "Back_" + key, false, 1.0)
				_commit(kit.lv, kit.ln, kit.lc, _back_material, "BackSheet_" + key, false, 1.0)
			"canopy":
				_commit(kit.lv, kit.ln, kit.lc, _canopy_material, "Canopy_" + key, false, 1.0)
			"wall":
				_commit(kit.v, kit.n, kit.c, _wall_material, "Wall_" + key, false)
			_:
				_commit(kit.v, kit.n, kit.c, _solid_material, "Solid_" + key, true)
				_commit(kit.lv, kit.ln, kit.lc, _sheet_material, "Sheet_" + key, true)
	_chunks.clear()


# --- cielo, luz y aire ---------------------------------------------------------------------------------------------

func _build_sky() -> void:
	var environment := (stage.get_node("WorldEnvironment") as WorldEnvironment).environment
	environment.background_mode = Environment.BG_COLOR
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.fog_depth_begin = S.FOG_BEGIN
	environment.fog_depth_end = S.FOG_END
	environment.fog_depth_curve = S.FOG_CURVE
	var sphere := SphereMesh.new()
	sphere.radius = SKY_RADIUS
	sphere.height = SKY_RADIUS * 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	sky_material = ShaderMaterial.new()
	sky_material.shader = SKY
	sky_dome = MeshInstance3D.new()
	sky_dome.name = "SkyDome"
	sky_dome.mesh = sphere
	sky_dome.material_override = sky_material
	sky_dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sky_dome.extra_cull_margin = 16000.0
	add_child(sky_dome)
	var camera := stage.get("camera") as Camera3D
	if camera != null:
		camera.far = maxf(camera.far, SKY_RADIUS * 1.5)


func _build_shafts() -> void:
	for i in S.SHAFT_COUNT:
		var quad := QuadMesh.new()
		quad.size = Vector2(2.4 + i * 0.5, 22.0)
		var material := ShaderMaterial.new()
		material.shader = SHAFT
		material.set_shader_parameter("phase", float(i) * 1.7)
		var shaft := MeshInstance3D.new()
		shaft.name = "LightShaft%d" % i
		shaft.mesh = quad
		shaft.material_override = material
		shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shaft.rotation = Vector3(0.0, 0.0, deg_to_rad(-20.0))
		add_child(shaft)
		shafts.append(shaft)
		shaft_materials.append(material)


## Pétalos, pelusa de diente de león, hojas secas o esporas según la zona: un solo sistema que cambia de color y de cantidad.
func _build_air() -> void:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(15.0, 4.5, 7.0)
	process.direction = Vector3(-1.0, -0.25, 0.0)
	process.spread = 28.0
	process.initial_velocity_min = 0.5
	process.initial_velocity_max = 1.3
	process.gravity = Vector3(0.0, -0.12, 0.0)
	process.angular_velocity_min = -120.0
	process.angular_velocity_max = 120.0
	process.angle_min = 0.0
	process.angle_max = 360.0
	process.scale_min = 0.6
	process.scale_max = 1.3
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.12, 0.85, 1.0])
	ramp.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	var fade := GradientTexture1D.new()
	fade.gradient = ramp
	process.color_ramp = fade
	var quad := QuadMesh.new()
	quad.size = Vector2(0.15, 0.1)
	air_material = StandardMaterial3D.new()
	air_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	air_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	air_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	air_material.vertex_color_use_as_albedo = true
	air_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	quad.material = air_material
	air = GPUParticles3D.new()
	air.name = "ZoneAir"
	air.amount = S.AIR_AMOUNT
	air.lifetime = 9.0
	air.preprocess = 9.0
	air.local_coords = false
	air.process_material = process
	air.draw_pass_1 = quad
	air.visibility_aabb = AABB(Vector3(-20, -8, -12), Vector3(40, 16, 24))
	air.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(air)


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "WorldOverlay"
	layer.layer = S.OVERLAY_LAYER
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_material = ShaderMaterial.new()
	overlay_material.shader = GRADE
	rect.material = overlay_material
	layer.add_child(rect)


## Cartel con el nombre de la zona: aparece, queda un momento y se va.
func _update_zone_title(x: float) -> void:
	var zone := S.zone_at(x)
	if zone == _zone:
		return
	var first := _zone < 0
	_zone = zone
	var title: String = S.ZONE_TITLES[zone]
	if first or title == "":
		return
	if _zone_label == null:
		var layer := CanvasLayer.new()
		layer.name = "ZoneTitle"
		layer.layer = 2
		add_child(layer)
		_zone_label = Label.new()
		_zone_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
		_zone_label.anchor_top = S.ZONE_TITLE_TOP
		_zone_label.anchor_bottom = S.ZONE_TITLE_TOP
		_zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_zone_label.add_theme_font_size_override("font_size", S.ZONE_TITLE_FONT)
		_zone_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.78))
		_zone_label.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.05))
		_zone_label.add_theme_constant_override("outline_size", 10)
		_zone_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_zone_label)
	_zone_label.text = title
	_zone_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_zone_label, "modulate:a", 1.0, 0.35)
	tween.tween_interval(S.ZONE_TITLE_SECONDS - 0.85)
	tween.tween_property(_zone_label, "modulate:a", 0.0, 0.5)


func _process(delta: float) -> void:
	var camera := stage.get("camera") as Camera3D
	if camera == null:
		return
	var x := camera.global_position.x
	_update_zone_title(x)
	sky_dome.global_position = camera.global_position
	if absf(x - _last_x) > 0.04:
		_apply_light(x)
	for i in shafts.size():
		# Paralaje suave: los rayos van más despacio que el suelo y vuelven a entrar por el otro lado.
		var span := 42.0
		var base := fposmod(float(i) * span / float(shafts.size()) - x * 0.35, span) - span * 0.5
		shafts[i].global_position = Vector3(x + base + 2.0, 8.4, -9.0 - float(i % 3) * 3.0)
	air.global_position = Vector3(x + 2.0, 3.8, -1.5)
	var target := float(BeeGameSettings.presentation_combat_intensity(stage))
	_combat = move_toward(_combat, target, delta * 1.5)
	var zone_air: Array = S.AIR_ZONE[S.zone_at(x)]
	air.amount_ratio = float(zone_air[0]) * lerpf(S.AIR_CALM_RATIO, S.AIR_COMBAT_RATIO, _combat)
	air_material.albedo_color = air_material.albedo_color.lerp(zone_air[1], clampf(delta * 0.8, 0.0, 1.0))


func _apply_light(x: float) -> void:
	_last_x = x
	var s: Dictionary = S.light_at(x)
	var sun := stage.get_node("Sun") as DirectionalLight3D
	sun.light_color = s["sun_color"]
	sun.light_energy = s["sun_energy"]
	sun.rotation_degrees = s["sun_rotation"]
	var environment := (stage.get_node("WorldEnvironment") as WorldEnvironment).environment
	environment.ambient_light_color = s["ambient_color"]
	environment.ambient_light_energy = s["ambient_energy"]
	environment.fog_light_color = s["fog_color"]
	environment.fog_density = s["fog_density"]
	environment.fog_sky_affect = 0.0
	environment.background_color = s["sky_horizon"]
	environment.adjustment_enabled = true
	environment.adjustment_contrast = s["contrast"]
	environment.adjustment_saturation = s["saturation"]
	environment.glow_intensity = s["glow"]
	BeeToonStyle.bee_rim_boost = s["bee_rim"]
	BeeToonStyle.set_outline_tint(s["outline_tint"])
	for key in ["sky_top", "sky_horizon", "cloud_light", "cloud_shadow", "cloud_amount", "stars", "sun_dir", "sun_disc"]:
		sky_material.set_shader_parameter(key, s[key])
	sky_material.set_shader_parameter("scroll", x)
	_back_material.set_shader_parameter("haze", s["fog_color"])
	for i in shaft_materials.size():
		shaft_materials[i].set_shader_parameter("strength", float(s["shaft"]) * (0.34 + 0.16 * float(i % 3)))
		shaft_materials[i].set_shader_parameter("color", (s["sun_color"] as Color).lerp(Color.WHITE, 0.25))
	overlay_material.set_shader_parameter("vignette", s["vignette"])
