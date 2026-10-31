extends MeshInstance3D
## Tanda S · C — sombra suave en el suelo debajo de Bee, siempre visible: marca dónde está aunque haya mucho lío en pantalla.
## Solo dibujo (sin colisión). Más chica y fuerte cerca del suelo, más grande y tenue en lo alto.
const HERO := preload("res://scripts/game/bee_hero_look_settings.gd")
const TEXTURE_SIZE := 64

var bee: BeePlayer
var ground_y := 0.0
var _material: StandardMaterial3D


static func attach(stage: Node3D, player: BeePlayer, ground: float) -> MeshInstance3D:
	if not HERO.HERO_LOOK_ENABLED or player == null:
		return null
	var shadow := (load("res://scripts/vfx/bee_hero_shadow.gd") as GDScript).new() as MeshInstance3D
	shadow.name = "BeeHeroShadow"
	shadow.set("bee", player)
	shadow.set("ground_y", ground)
	stage.add_child(shadow)
	return shadow


func _ready() -> void:
	var quad := PlaneMesh.new()
	quad.size = Vector2.ONE * 2.0
	mesh = quad
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_texture = _soft_disc()
	_material.albedo_color = Color(0.08, 0.05, 0.03, HERO.SHADOW_ALPHA_LOW)
	_material.disable_receive_shadows = true
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_follow()


func _process(_delta: float) -> void:
	_follow()


func _follow() -> void:
	if not is_instance_valid(bee):
		queue_free()
		return
	visible = not bee.is_defeated
	var height := clampf((bee.global_position.y - ground_y) / HERO.SHADOW_HIGH_Y, 0.0, 1.0)
	global_position = Vector3(bee.global_position.x, ground_y + HERO.SHADOW_LIFT, bee.global_position.z)
	var radius := lerpf(HERO.SHADOW_RADIUS, HERO.SHADOW_RADIUS_HIGH, height)
	scale = Vector3(radius, 1.0, radius * 0.6) # Elipse aplastada: se lee como sombra vista casi de costado.
	_material.albedo_color.a = lerpf(HERO.SHADOW_ALPHA_LOW, HERO.SHADOW_ALPHA_HIGH, height)


func _soft_disc() -> Texture2D:
	var image := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	for y in TEXTURE_SIZE:
		for x in TEXTURE_SIZE:
			var r := Vector2((x + 0.5) / TEXTURE_SIZE * 2.0 - 1.0, (y + 0.5) / TEXTURE_SIZE * 2.0 - 1.0).length()
			image.set_pixel(x, y, Color(1, 1, 1, pow(clampf(1.0 - r, 0.0, 1.0), 1.5)))
	return ImageTexture.create_from_image(image)
