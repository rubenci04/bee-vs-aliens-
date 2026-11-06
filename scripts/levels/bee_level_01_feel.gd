class_name BeeLevel01Feel
extends Node
## Mejora visual: la sensación de golpe del Nivel 1. Escucha lo que ya pasa en el juego y le agrega efectos, sin cambiar reglas.
## Liberar da confeti, las máquinas explotan, el golpe a Bee se siente en toda la pantalla y el jefe vencido frena el tiempo un instante.
## Interruptor: FEEL_ENABLED. Sin ventana no corre.
const W := preload("res://scripts/game/bee_world_settings.gd")
const IMPACT := preload("res://scripts/vfx/bee_impact.gd")

const FEEL_ENABLED := true
const HURT_SHAKE := 0.2 ## Sacudida cuando golpean a Bee.
const HURT_SECONDS := 0.28
const HURT_FLASH_ALPHA := 0.42 ## Borde rojo de pantalla.
const HURT_FLASH_SECONDS := 0.4
const HURT_RUMBLE := 0.65 ## Vibración del mando.
const FREE_BIG_SHAKE := 0.12
const BLAST_SHAKE := 0.18
const BOSS_SHAKE := 0.32
const BOSS_SLOW_SCALE := 0.28 ## Velocidad del juego al vencer a un jefe.
const BOSS_SLOW_SECONDS := 0.85 ## Segundos reales que dura esa cámara lenta.
const BOSS_FLASH_ALPHA := 0.75
const BOSS_BLASTS := 7 ## Explosiones en cadena del robot.
const FRENZY_TINT := Color(1.0, 0.72, 0.2, 0.2)
const TRAIL_AMOUNT := 26 ## Estela de los propulsores.
const TRAIL_LIFETIME := 0.55
const TRAIL_OFFSET := Vector3(-0.55, 0.05, 0.0) ## Detrás de Bee (se espeja al girar).
const TRAIL_CORE := Color(1.0, 0.92, 0.58, 0.8)
const TRAIL_END := Color(1.0, 0.46, 0.14, 0.0)
const COMBO_POP_SCALE := 1.28 ## Golpecito de escala del combo.
const COMBO_POP_SECONDS := 0.16

var stage: Node
var bee: BeePlayer
var wave: BeeLevel01Controller
var trail: CPUParticles3D
var hurt_rect: ColorRect
var flash_rect: ColorRect
var _last_health := -1
var _boss_done := {}


static func attach(parent: Node) -> BeeLevel01Feel:
	if not FEEL_ENABLED or not W.world_active():
		return null
	var feel := BeeLevel01Feel.new()
	feel.name = "Feel"
	feel.stage = parent
	feel.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(feel)
	return feel


func _ready() -> void:
	BeeFx.enabled = true
	bee = stage.get("bee") as BeePlayer
	wave = stage.get("wave") as BeeLevel01Controller
	wave.unit_downed.connect(_on_unit_downed)
	bee.health.health_changed.connect(_on_bee_health)
	_last_health = bee.health.current_health
	_build_trail()
	_build_overlay()
	var juice := stage.get_node_or_null("Juice")
	if juice != null and juice.has_signal("combo_changed"):
		juice.connect("combo_changed", _on_combo)


func _exit_tree() -> void:
	BeeFx.enabled = false
	Engine.time_scale = 1.0 # Nunca queda lento al salir.


func _build_trail() -> void:
	trail = CPUParticles3D.new()
	trail.name = "BeeJetTrail"
	trail.amount = TRAIL_AMOUNT
	trail.lifetime = TRAIL_LIFETIME
	trail.local_coords = false
	trail.gravity = Vector3(0, -0.5, 0)
	trail.direction = Vector3.LEFT
	trail.spread = 16.0
	trail.initial_velocity_min = 0.4
	trail.initial_velocity_max = 1.2
	trail.scale_amount_min = 0.7
	trail.scale_amount_max = 1.3
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([TRAIL_CORE, TRAIL_END])
	trail.color_ramp = ramp
	var quad := QuadMesh.new()
	quad.size = Vector2(0.26, 0.26)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	var disc := GradientTexture2D.new()
	disc.fill = GradientTexture2D.FILL_RADIAL
	disc.fill_from = Vector2(0.5, 0.5)
	disc.fill_to = Vector2(1.0, 0.5)
	disc.width = 32
	disc.height = 32
	var disc_ramp := Gradient.new()
	disc_ramp.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	disc.gradient = disc_ramp
	material.albedo_texture = disc
	quad.material = material
	trail.mesh = quad
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stage.add_child(trail)


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "FeelOverlay"
	layer.layer = W.OVERLAY_LAYER + 1
	add_child(layer)
	hurt_rect = _full_rect(layer, Color(0.95, 0.08, 0.06, 0.0))
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec2 c = (UV - 0.5) * vec2(1.0, 0.8);\n\tCOLOR.a *= smoothstep(0.22, 0.72, length(c));\n}\n"
	var edge := ShaderMaterial.new()
	edge.shader = shader
	hurt_rect.material = edge
	flash_rect = _full_rect(layer, Color(1.0, 0.96, 0.82, 0.0))


func _full_rect(layer: CanvasLayer, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = color
	layer.add_child(rect)
	return rect


func _process(_delta: float) -> void:
	if not is_instance_valid(bee):
		return
	var facing := float(bee.get("facing_x"))
	trail.global_position = bee.global_position + Vector3(TRAIL_OFFSET.x * facing, TRAIL_OFFSET.y, TRAIL_OFFSET.z)
	trail.direction = Vector3(-facing, 0, 0)
	trail.emitting = bee.visible and not bee.is_defeated
	var frenzy := float(bee.get("honey_left")) > 0.0 or float(bee.get("pollen_double_left")) > 0.0
	trail.scale_amount_max = 2.0 if frenzy else 1.3


func _on_unit_downed(unit: Node3D, liberated: bool) -> void:
	if not is_instance_valid(unit):
		return
	var at := unit.global_position + Vector3(0, 0.3, 0)
	if unit is WalkerMiniboss or unit is TarantulaBoss01:
		_boss_down(unit, at, liberated)
		return
	if liberated:
		var big: bool = IMPACT.is_big(unit)
		BeeFx.liberation(stage, at, big)
		if big:
			BeeCameraShake.kick(stage, FREE_BIG_SHAKE, 0.2, Vector2.UP)
	else:
		BeeFx.explosion(stage, at, 0.8)
		BeeCameraShake.kick(stage, BLAST_SHAKE, 0.28, Vector2(0.6, 1.0))


func _boss_down(unit: Node3D, at: Vector3, liberated: bool) -> void:
	if _boss_done.has(unit.get_instance_id()):
		return
	_boss_done[unit.get_instance_id()] = true
	_big_moment()
	if liberated:
		for i in 5:
			var offset := Vector3(randf_range(-1.6, 1.6), randf_range(0.0, 2.4), 0.0)
			get_tree().create_timer(0.12 * i, true, false, true).timeout.connect(func(): BeeFx.liberation(stage, at + offset, true))
	else:
		for i in BOSS_BLASTS:
			var offset := Vector3(randf_range(-1.8, 1.8), randf_range(0.0, 3.0), 0.0)
			get_tree().create_timer(0.11 * i, true, false, true).timeout.connect(func():
				BeeFx.explosion(stage, at + offset, 1.2 + 0.15 * float(i))
				BeeCameraShake.kick(stage, BOSS_SHAKE * 0.6, 0.3, Vector2(0.7, 1.0)))


## Cámara lenta corta, destello y sacudida fuerte: que se sienta que ganaste.
func _big_moment() -> void:
	BeeCameraShake.kick(stage, BOSS_SHAKE, 0.5, Vector2(0.5, 1.0))
	_rumble(1.0, 0.7)
	flash_rect.color.a = BOSS_FLASH_ALPHA
	var fade := create_tween().set_ignore_time_scale()
	fade.tween_property(flash_rect, "color:a", 0.0, 0.5)
	Engine.time_scale = BOSS_SLOW_SCALE
	var restore := create_tween().set_ignore_time_scale()
	restore.tween_interval(BOSS_SLOW_SECONDS)
	restore.tween_method(func(v: float): Engine.time_scale = v, BOSS_SLOW_SCALE, 1.0, 0.25)


func _on_bee_health(current: int, _maximum: int, _change: int) -> void:
	var lost := current < _last_health
	_last_health = current
	if not lost:
		return
	BeeCameraShake.kick(stage, HURT_SHAKE, HURT_SECONDS, Vector2(1.0, 0.6))
	_rumble(HURT_RUMBLE, 0.22)
	hurt_rect.color.a = HURT_FLASH_ALPHA
	var fade := create_tween()
	fade.tween_property(hurt_rect, "color:a", 0.0, HURT_FLASH_SECONDS)


func _rumble(strength: float, seconds: float) -> void:
	if BeeGameSettings.last_input_joypad:
		Input.start_joy_vibration(BeeGameSettings.last_joypad_device, strength * 0.5, strength, seconds)


func _on_combo(combo: int) -> void:
	if combo < 2:
		return
	var label := stage.get_node_or_null("CanvasLayer/WeaponsHUD/ComboValue") as Control
	if label == null:
		return
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2.ONE * COMBO_POP_SCALE
	var pop := create_tween()
	pop.tween_property(label, "scale", Vector2.ONE, COMBO_POP_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
