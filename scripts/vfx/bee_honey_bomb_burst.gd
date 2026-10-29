extends RefCounted
## Soft honey droplets and pollen flecks for Bee's bomb. The damage query stays in BeeAlienBomb.
const DROPLETS := 34
const POLLEN := 22
const LIFE := 0.72
const GOLD := Color(1.0, 0.68, 0.12, 0.9)
const PALE := Color(1.0, 0.92, 0.51, 0.75)
const TEXTURE_SIZE := 48


static func spawn(parent: Node3D, point: Vector3, radius: float) -> void:
	var texture := _drop_texture()
	_emit(parent, point, texture, DROPLETS, GOLD, radius, 0.28)
	_emit(parent, point, texture, POLLEN, PALE, radius * 0.65, 0.12)
	var flash := Sprite3D.new()
	flash.name = "HoneyFlash"
	flash.texture = texture
	flash.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	flash.modulate = Color(1.0, 0.9, 0.52, 0.85)
	flash.pixel_size = radius * 1.3 / float(TEXTURE_SIZE)
	flash.no_depth_test = true
	parent.add_child(flash)
	flash.global_position = point
	var fade := flash.create_tween()
	fade.tween_property(flash, "modulate:a", 0.0, 0.22)
	fade.tween_callback(flash.queue_free)


static func _emit(parent: Node3D, point: Vector3, texture: Texture2D, count: int, color: Color, spread: float, size: float) -> void:
	var particles := CPUParticles3D.new()
	particles.name = "HoneyDroplets"
	particles.emitting = false
	particles.one_shot = true
	particles.amount = count
	particles.lifetime = LIFE
	particles.explosiveness = 1.0
	particles.direction = Vector3.UP
	particles.spread = 180.0
	particles.initial_velocity_min = spread * 1.3
	particles.initial_velocity_max = spread * 2.5
	particles.gravity = Vector3(0.0, -2.5, 0.0)
	particles.damping_min = 0.8
	particles.damping_max = 1.6
	particles.scale_amount_min = 0.45
	particles.scale_amount_max = 1.15
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.albedo_texture = texture
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.vertex_color_use_as_albedo = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * size
	quad.material = material
	particles.mesh = quad
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(particles)
	particles.global_position = point
	particles.restart()
	particles.emitting = true
	parent.get_tree().create_timer(LIFE + 0.2).timeout.connect(particles.queue_free)


static func _drop_texture() -> ImageTexture:
	var image := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	for y in TEXTURE_SIZE:
		for x in TEXTURE_SIZE:
			var px := (float(x) + 0.5) / float(TEXTURE_SIZE) * 2.0 - 1.0
			var py := (float(y) + 0.5) / float(TEXTURE_SIZE) * 2.0 - 1.0
			var taper := 1.0 + 0.38 * py
			var distance := sqrt(pow(px / taper, 2.0) + pow((py + 0.08) / 0.92, 2.0))
			var alpha := 1.0 - smoothstep(0.48, 1.0, distance)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)
