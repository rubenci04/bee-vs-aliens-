class_name BeetleGrenade
extends Node3D
## Tanda E: the stag beetle's two heavy grenades (it lobs them, slow reload; see BeetleCannon). Both fly a fixed parabola and never home.
##   QUAKE  lands on the soil at Bee's X and explodes with a BIG shockwave: two BeeGroundShockwave waves (2.2 m tall, one each way)
##          in brown / burnt orange. The answer is to fly above it.
##   FAN    bursts in the air in front of Bee and sheds 3 aimed BeetleShard shots in a thin fan.
## Dark core + burnt-orange shell: unlike Bee's gold shots, unlike the cyan implants.
const KIND_QUAKE := &"quake"
const KIND_FAN := &"fan"
const SHELL_RADIUS := 0.3
const SHELL_COLOR := Color(0.72, 0.3, 0.06)
const CORE_COLOR := Color(0.1, 0.06, 0.04)
const WAVE_FOOT := Color(0.8, 0.33, 0.07, 0.78)
const WAVE_CROWN := Color(0.2, 0.1, 0.05, 0.82)
const WAVE_DAMAGE := 8
const WAVE_HEIGHT := 2.2
const WAVE_WIDTH := 1.5
const WAVE_SPEED := 6.5
const FAN_SHOTS := 3
const FAN_HALF_ANGLE_DEG := 9.0
const FAN_SPEED := 6.0
const FAN_DAMAGE := 4
const FLIGHT_TIME := 1.1
const APEX := 3.2
const GROUND_Y := 0.0
var kind := KIND_QUAKE
var attacker: Node
var target: Node3D
var flight_time := FLIGHT_TIME
var apex := APEX
var landed := false
var waves: Array[BeeGroundShockwave] = []
var shards: Array[BeetleShard] = []
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _t := 0.0
var _shell: MeshInstance3D


func launch(from: Vector3, to: Vector3) -> void:
	add_to_group("alien_projectiles")
	_from = Vector3(from.x, from.y, 0.0)
	_to = Vector3(to.x, GROUND_Y if kind == KIND_QUAKE else to.y, 0.0)
	_shell = BeeAttackVisuals.sphere(self, _from, SHELL_RADIUS, SHELL_COLOR)
	var core := BeeAttackVisuals.sphere(_shell, _from, SHELL_RADIUS * 0.55, CORE_COLOR, false)
	core.position = Vector3(0.0, 0.0, 0.05)
	BeeAudio.play(get_parent(), &"organic_charge", _from, 0.6)

func shell_position() -> Vector3:
	var t := clampf(_t / flight_time, 0.0, 1.0)
	var p := _from.lerp(_to, t)
	p.y += 4.0 * apex * t * (1.0 - t)
	return p

func _physics_process(delta: float) -> void:
	if landed:
		return
	_t += delta
	_shell.global_position = shell_position()
	_shell.rotation.z += 6.0 * delta
	if _t >= flight_time:
		_explode()

func _explode() -> void:
	landed = true
	_shell.hide()
	var parent := get_parent()
	BeeAudio.play(parent, &"wasp_overload", _to, 0.8)
	if kind == KIND_QUAKE:
		_quake(parent)
	else:
		_fan(parent)
	get_tree().create_timer(0.5, false).timeout.connect(queue_free)

func _flash(parent: Node, radius: float) -> void:
	var flash := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 1.0
	ball.height = 2.0
	flash.mesh = ball
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(SHELL_COLOR, 0.6)
	flash.material_override = material
	parent.add_child(flash)
	flash.global_position = _to
	flash.scale = Vector3.ONE * 0.2
	var tween := flash.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector3.ONE * radius, 0.2)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.32)
	tween.chain().tween_callback(flash.queue_free)
	BeeCombatVFX.spawn(parent, _to, &"rock_break", Vector3.UP, 1.2)

func _quake(parent: Node) -> void:
	_flash(parent, 1.8)
	BeeCameraShake.kick(self, 0.05, 0.25)
	var cam_x := _to.x
	var half := 8.0
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		cam_x = camera.global_position.x
		half = BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(get_viewport()))
	for side: float in [-1.0, 1.0]:
		var stop: float = cam_x + side * (half + 1.0)
		var wave := BeeGroundShockwave.launch(parent, attacker, _to.x, stop, WAVE_DAMAGE, WAVE_SPEED, WAVE_HEIGHT, WAVE_FOOT, WAVE_CROWN, WAVE_WIDTH)
		waves.append(wave)

func _fan(parent: Node) -> void:
	_flash(parent, 1.1)
	var aim := Vector3.LEFT
	if is_instance_valid(target):
		aim = (target.global_position - _to)
		aim.z = 0.0
		aim = aim.normalized() if aim.length() > 0.1 else Vector3.LEFT
	var base := atan2(aim.y, aim.x)
	for i in FAN_SHOTS:
		var offset := deg_to_rad(FAN_HALF_ANGLE_DEG) * float(i - 1) # -a, 0, +a
		var shard := BeetleShard.new()
		shard.attacker = attacker
		shard.damage = FAN_DAMAGE
		shard.velocity = Vector3(cos(base + offset), sin(base + offset), 0.0) * FAN_SPEED * float(attacker.get_meta("shot_speed_scale", 1.0) if is_instance_valid(attacker) else 1.0)
		parent.add_child(shard)
		shard.global_position = _to
		shards.append(shard)
