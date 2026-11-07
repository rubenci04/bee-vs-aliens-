class_name BeeFx
extends RefCounted
## Mejora visual: efectos de combate estilo dibujo animado. Destellos en estrella, anillos, chispas, humo y confeti.
## Solo presentación. Todos los números están acá; `enabled` lo prende el nivel con ventana (tests y bots no los generan).

static var enabled := false

const STAR_TEXTURE_SIZE := 64
const HIT_MIN_GAP := 0.09 ## s entre chispas de impacto: una ráfaga de 12 tiros por segundo no llena la pantalla.
const HIT_FLASH_SIZE := 0.65
const HIT_SPARKS := 4
const HIT_SPARK_SPEED := 4.5
const HIT_COLOR := Color(1.0, 0.86, 0.42)
const FREE_FLASH_SIZE := 1.7
const FREE_FLASH_SIZE_BIG := 2.8
const FREE_RING := 0.9
const FREE_RING_BIG := 1.6
const FREE_CONFETTI := 5
const FREE_CONFETTI_BIG := 10
const FREE_CONFETTI_SECONDS := 0.5
const FREE_MIN_GAP := 0.14 ## s: si se liberan muchos juntos, los demás solo dan un destello chico.
const FREE_COLORS: Array[Color] = [Color(1.0, 0.84, 0.2), Color(1.0, 0.52, 0.66), Color(0.66, 0.92, 0.36), Color(0.56, 0.84, 1.0), Color(1.0, 0.96, 0.8)]
const BLAST_PUFFS := 8
const BLAST_DEBRIS := 16
const BLAST_FIRE: Array[Color] = [Color(1.0, 0.96, 0.6), Color(1.0, 0.66, 0.16), Color(0.92, 0.3, 0.1), Color(0.3, 0.26, 0.26)]
const SMOKE_COLOR := Color(0.32, 0.29, 0.3)
const DEBRIS_COLOR := Color(0.24, 0.27, 0.32)
const MUZZLE_SIZE := 0.9
const MUZZLE_SECONDS := 0.06
const MUZZLE_COLOR := Color(1.0, 0.9, 0.5)

static var _star: ImageTexture
static var _disc: GradientTexture2D
static var _flash_materials: Dictionary = {}
static var _ring_mesh: TorusMesh
static var _ring_materials: Dictionary = {}
static var _spark_mesh: QuadMesh
static var _puff_mesh: SphereMesh
static var _chunk_mesh: BoxMesh
static var _confetti_mesh: QuadMesh
static var _last_hit_msec := -1000
static var _last_free_msec := -1000


static func _star_texture() -> ImageTexture:
	if _star != null:
		return _star
	var size := STAR_TEXTURE_SIZE
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var p := Vector2((float(x) + 0.5) / size * 2.0 - 1.0, (float(y) + 0.5) / size * 2.0 - 1.0)
			var r := p.length()
			var angle := absf(sin(atan2(p.y, p.x) * 2.0)) # 4 puntas
			var shape := pow(1.0 - clampf(r / lerpf(1.0, 0.28, angle), 0.0, 1.0), 1.3)
			image.set_pixel(x, y, Color(1, 1, 1, clampf(shape * 1.7, 0.0, 1.0)))
	_star = ImageTexture.create_from_image(image)
	return _star


static func _disc_texture() -> GradientTexture2D:
	if _disc != null:
		return _disc
	_disc = GradientTexture2D.new()
	_disc.fill = GradientTexture2D.FILL_RADIAL
	_disc.fill_from = Vector2(0.5, 0.5)
	_disc.fill_to = Vector2(1.0, 0.5)
	_disc.width = 48
	_disc.height = 48
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	_disc.gradient = ramp
	return _disc


static func _flash_material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if _flash_materials.has(key):
		return _flash_materials[key]
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.no_depth_test = true
	material.albedo_texture = _star_texture()
	material.albedo_color = color
	material.vertex_color_use_as_albedo = true
	material.disable_receive_shadows = true
	_flash_materials[key] = material
	return material


## Contenedor de los efectos: se limpia solo con el nivel.
static func _host(from: Node) -> Node3D:
	var host: Node = from
	while host.get_parent() is Node3D:
		host = host.get_parent()
	var box := host.get_node_or_null("FxLayer") as Node3D
	if box == null:
		box = Node3D.new()
		box.name = "FxLayer"
		host.add_child(box)
	return box


## Estrella que aparece y se apaga enseguida.
static func flash(from: Node, at: Vector3, size: float, color: Color, seconds := 0.14, spin := 0.0) -> void:
	if not enabled or from == null or not from.is_inside_tree():
		return
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE
	mesh.material = _flash_material(color)
	quad.mesh = mesh
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_host(from).add_child(quad)
	quad.global_position = at + Vector3(0, 0, 0.5)
	quad.scale = Vector3.ONE * size * 0.5
	var tween := quad.create_tween()
	tween.tween_property(quad, "scale", Vector3.ONE * size, seconds * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(quad, "scale", Vector3.ONE * size * 0.15, seconds * 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(quad.queue_free)


## Anillo que crece y se desvanece.
static func ring(from: Node, at: Vector3, radius: float, color: Color, seconds := 0.32) -> void:
	if not enabled or from == null or not from.is_inside_tree():
		return
	if _ring_mesh == null:
		_ring_mesh = TorusMesh.new()
		_ring_mesh.inner_radius = 0.9
		_ring_mesh.outer_radius = 1.0
		_ring_mesh.rings = 28
		_ring_mesh.ring_segments = 4
	var key := color.to_html()
	if not _ring_materials.has(key):
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		material.albedo_color = color
		material.no_depth_test = true
		_ring_materials[key] = material
	var node := MeshInstance3D.new()
	node.mesh = _ring_mesh
	node.material_override = _ring_materials[key]
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_host(from).add_child(node)
	node.global_position = at + Vector3(0, 0, 0.4)
	node.rotation.x = PI * 0.5
	node.scale = Vector3.ONE * radius * 0.15
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector3.ONE * radius, seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(node, "transparency", 1.0, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(node.queue_free)


static func _burst(from: Node, at: Vector3, amount: int, lifetime: float, mesh: Mesh, colors: Array[Color], speed: Vector2, gravity: Vector3, scale: Vector2, spread := 180.0, direction := Vector3.UP, damping := 0.0, spin := 0.0) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = amount
	particles.lifetime = lifetime
	particles.explosiveness = 0.96
	particles.randomness = 0.4
	particles.local_coords = false
	particles.direction = direction
	particles.spread = spread
	particles.initial_velocity_min = speed.x
	particles.initial_velocity_max = speed.y
	particles.gravity = gravity
	particles.damping_min = damping
	particles.damping_max = damping
	particles.scale_amount_min = scale.x
	particles.scale_amount_max = scale.y
	particles.angular_velocity_min = -spin
	particles.angular_velocity_max = spin
	particles.mesh = mesh
	var ramp := Gradient.new()
	var stops := PackedFloat32Array()
	var tones := PackedColorArray()
	for i in colors.size():
		stops.append(float(i) / maxf(float(colors.size() - 1), 1.0) * 0.8)
		tones.append(colors[i])
	stops.append(1.0)
	var last := colors[colors.size() - 1]
	tones.append(Color(last.r, last.g, last.b, 0.0))
	ramp.offsets = stops
	ramp.colors = tones
	particles.color_ramp = ramp
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_host(from).add_child(particles)
	particles.global_position = at + Vector3(0, 0, 0.3)
	particles.restart()
	particles.emitting = true
	particles.finished.connect(particles.queue_free)
	return particles


static func _spark() -> QuadMesh:
	if _spark_mesh == null:
		_spark_mesh = QuadMesh.new()
		_spark_mesh.size = Vector2(0.16, 0.16)
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		material.vertex_color_use_as_albedo = true
		material.albedo_texture = _star_texture()
		_spark_mesh.material = material
	return _spark_mesh


static func _confetti() -> QuadMesh:
	if _confetti_mesh == null:
		_confetti_mesh = QuadMesh.new()
		_confetti_mesh.size = Vector2(0.16, 0.1)
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		material.vertex_color_use_as_albedo = true
		_confetti_mesh.material = material
	return _confetti_mesh


static func _puff() -> SphereMesh:
	if _puff_mesh == null:
		_puff_mesh = SphereMesh.new()
		_puff_mesh.radius = 0.42
		_puff_mesh.height = 0.84
		_puff_mesh.radial_segments = 10
		_puff_mesh.rings = 5
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.vertex_color_use_as_albedo = true
		_puff_mesh.material = material
	return _puff_mesh


static func _chunk() -> BoxMesh:
	if _chunk_mesh == null:
		_chunk_mesh = BoxMesh.new()
		_chunk_mesh.size = Vector3(0.2, 0.12, 0.08)
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_chunk_mesh.material = material
	return _chunk_mesh


## Bala que pega: una estrellita y chispas hacia atrás. Tiene tope por tiempo para no saturar con el fuego continuo.
static func hit(from: Node, at: Vector3, direction: Vector3, color := HIT_COLOR) -> void:
	if not enabled:
		return
	var now := Time.get_ticks_msec()
	if float(now - _last_hit_msec) / 1000.0 < HIT_MIN_GAP:
		return
	_last_hit_msec = now
	flash(from, at, HIT_FLASH_SIZE, color, 0.1)
	_burst(from, at, HIT_SPARKS, 0.24, _spark(), [color, Color(color.r, color.g * 0.6, color.b * 0.3)], Vector2(HIT_SPARK_SPEED * 0.4, HIT_SPARK_SPEED), Vector3(0, -6, 0), Vector2(0.7, 1.3), 55.0, -direction)


## Insecto liberado: el momento más feliz del juego. Destello dorado, anillo y confeti de colores.
static func liberation(from: Node, at: Vector3, big: bool) -> void:
	if not enabled:
		return
	flash(from, at, FREE_FLASH_SIZE_BIG if big else FREE_FLASH_SIZE, Color(1.0, 0.92, 0.5), 0.16)
	var now := Time.get_ticks_msec()
	if float(now - _last_free_msec) / 1000.0 < FREE_MIN_GAP and not big:
		return
	_last_free_msec = now
	ring(from, at, FREE_RING_BIG if big else FREE_RING, Color(1.0, 0.86, 0.36), 0.24)
	_burst(from, at, FREE_CONFETTI_BIG if big else FREE_CONFETTI, FREE_CONFETTI_SECONDS, _confetti(), FREE_COLORS, Vector2(1.8, 3.6), Vector3(0, -6.0, 0), Vector2(0.8, 1.3), 180.0, Vector3.UP, 1.4, 360.0)


## Máquina que revienta (implante, robot): bola de fuego, humo, esquirlas y onda.
static func explosion(from: Node, at: Vector3, size := 1.0) -> void:
	if not enabled:
		return
	flash(from, at, 4.0 * size, Color(1.0, 0.94, 0.66), 0.18)
	ring(from, at, 2.0 * size, Color(1.0, 0.72, 0.3), 0.34)
	_burst(from, at, BLAST_PUFFS, 0.42, _puff(), BLAST_FIRE, Vector2(1.8 * size, 4.4 * size), Vector3(0, 0.8, 0), Vector2(0.45 * size, 1.15 * size), 180.0, Vector3.UP, 3.0)
	_burst(from, at, int(BLAST_PUFFS * 0.75), 0.95, _puff(), [Color(SMOKE_COLOR.r, SMOKE_COLOR.g, SMOKE_COLOR.b, 0.7), Color(0.5, 0.48, 0.46, 0.25)], Vector2(0.8, 2.2 * size), Vector3(0, 1.2, 0), Vector2(0.4 * size, 1.0 * size), 75.0, Vector3.UP, 1.4)
	_burst(from, at, BLAST_DEBRIS, 0.95, _chunk(), [DEBRIS_COLOR], Vector2(3.0 * size, 8.0 * size), Vector3(0, -11, 0), Vector2(0.7, 1.7), 180.0, Vector3.UP, 0.2, 720.0)
	_burst(from, at, 12, 0.5, _spark(), [Color(1.0, 0.9, 0.5), Color(1.0, 0.44, 0.1)], Vector2(5.0 * size, 11.0 * size), Vector3(0, -6, 0), Vector2(0.8, 1.6))


## Fogonazo de Bee: una estrella corta en la boca del arma.
static func muzzle(from: Node, at: Vector3) -> void:
	if enabled:
		flash(from, at, MUZZLE_SIZE, MUZZLE_COLOR, MUZZLE_SECONDS)


## Polvo que levanta un golpe en el suelo.
static func dust(from: Node, at: Vector3, size := 1.0, color := Color(0.74, 0.64, 0.5, 0.75)) -> void:
	if enabled:
		_burst(from, at, 7, 0.7, _puff(), [color, Color(color.r, color.g, color.b, 0.25)], Vector2(0.6, 2.0 * size), Vector3(0, 0.3, 0), Vector2(0.5 * size, 1.3 * size), 70.0, Vector3.UP, 2.2)
