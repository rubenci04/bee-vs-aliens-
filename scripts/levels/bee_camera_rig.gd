class_name BeeCameraRig
extends Node
## Mejora visual: la cámara del Nivel 1 con vida. Lo que se dibuja cambia; la lógica del juego, no.
## Cómo: el nodo Camera3D sigue en la X/Y/Z de siempre (45 scripts leen camera.global_position). El giro va en la rotación
## del nodo y el desplazamiento del dibujo va en h_offset / v_offset, que Godot aplica solo al renderizar. Así el centro de la
## vista cae donde queremos sin mover la posición lógica. BeeShmupFairness mira la base y el FOV "lógicos" (ver más abajo).
const S := preload("res://scripts/game/bee_camera_settings.gd")

## Base y FOV lógicos: mientras el rig esté activo, "estar en pantalla" se sigue midiendo como con la cámara lateral.
static var logic_active := false

var stage: Node
var yaw_now := 0.0
var _follow_y := 0.0
var _roll := 0.0
var _time := 0.0
var _boss_entry_left := 0.0
var _boss_seen := {}
## Sacudida vigente (BeeCameraShake la escribe): se suma a los offsets del encuadre.
var shake := Vector2.ZERO


static func enabled() -> bool:
	return S.ACTIVE_IN_HEADLESS or DisplayServer.get_name() != "headless"


static func attach(parent: Node) -> BeeCameraRig:
	if not enabled():
		return null
	var rig := BeeCameraRig.new()
	rig.name = "CameraRig"
	rig.stage = parent
	rig.process_priority = 100 # Después de todo lo demás: es lo último antes de dibujar.
	rig.process_mode = Node.PROCESS_MODE_ALWAYS # Sigue encuadrando durante la pausa y las escenas cortas.
	parent.add_child(rig)
	logic_active = S.mode != &"lateral"
	return rig


func _exit_tree() -> void:
	logic_active = false


## Interpola la tabla de zonas: [giro, inclinación, altura, FOV].
static func framing_at(x: float) -> Array:
	var table: Array = S.KEYFRAMES
	if x <= float(table[0][0]):
		return table[0].slice(1)
	for i in range(1, table.size()):
		if x <= float(table[i][0]):
			var t := smoothstep(float(table[i - 1][0]), float(table[i][0]), x)
			var out := []
			for k in range(1, 5):
				out.append(lerpf(float(table[i - 1][k]), float(table[i][k]), t))
			return out
	return table[table.size() - 1].slice(1)


func _process(delta: float) -> void:
	if stage == null or S.mode == &"lateral":
		return
	var camera := stage.get("camera") as Camera3D
	var bee := stage.get("bee") as Node3D
	if camera == null or bee == null:
		return
	_time += delta
	if S.mode == &"atras":
		return # El prototipo desde atrás lo dibuja BeeCameraBackProto.
	apply_dynamic(camera, bee, delta)


func apply_dynamic(camera: Camera3D, bee: Node3D, delta: float) -> void:
	var x: float = camera.global_position.x
	var framing := framing_at(x)
	var half: float = BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(camera.get_viewport()))
	var smooth := 1.0 - exp(-delta / maxf(S.SMOOTH_SECONDS, 0.01))
	# Seguimiento suave de Bee: su altura mueve un poco la vista y su lugar en la pantalla, el giro.
	var mid_y: float = camera.global_position.y
	_follow_y = lerpf(_follow_y, clampf((bee.global_position.y - mid_y) * S.BEE_FOLLOW_Y, -S.BEE_FOLLOW_MAX, S.BEE_FOLLOW_MAX), smooth)
	var side := clampf((bee.global_position.x - x) / maxf(half, 0.1), -1.0, 1.0)
	var velocity := Vector3.ZERO
	if bee is CharacterBody3D:
		velocity = (bee as CharacterBody3D).velocity
	_roll = lerpf(_roll, clampf(velocity.y * S.ROLL_FROM_VY, -S.ROLL_MAX, S.ROLL_MAX), smooth)
	_update_boss_entry(delta)
	var boss_yaw := S.BOSS_ENTRY_YAW * smoothstep(0.0, 0.5, _boss_entry_left / S.BOSS_ENTRY_SECONDS)
	yaw_now = lerpf(yaw_now, float(framing[0]) + side * S.BEE_YAW_FROM_X + boss_yaw, smooth)
	var breath := sin(_time * S.BREATH_SPEED)
	var yaw := yaw_now + breath * S.BREATH_YAW
	var pitch: float = BeeLevel01Framing.CAMERA_PITCH_DEGREES + float(framing[1])
	aim(camera, yaw, pitch, _roll,
		Vector3(x - yaw * S.LOOK_SHIFT_FACTOR, center_y_on_plane() + float(framing[2]) + _follow_y + sin(_time * S.BREATH_SPEED * 1.7) * S.BREATH_Y, 0.0),
		BeeLevel01Framing.effective_fov() * float(framing[3]), shake)


## El centro de la vista sobre el plano de vuelo con la cámara lateral (el que hay que conservar).
static func center_y_on_plane() -> float:
	return (BeeLevel01Framing.top_y() + BeeLevel01Framing.bottom_y()) * 0.5


## Orienta la cámara y deja el centro de la vista sobre `target` usando solo offsets de dibujo.
static func aim(camera: Camera3D, yaw_deg: float, pitch_deg: float, roll_deg: float, target: Vector3, fov: float, extra := Vector2.ZERO) -> void:
	# Giro hacia +X: en Godot es rotación Y negativa. Inclinación positiva = mira hacia arriba (igual que la lateral).
	camera.rotation = Vector3(deg_to_rad(pitch_deg), -deg_to_rad(yaw_deg), deg_to_rad(roll_deg))
	var basis := camera.global_transform.basis.orthonormalized()
	var to_target := target - camera.global_position
	camera.h_offset = to_target.dot(basis.x) + extra.x
	camera.v_offset = to_target.dot(basis.y) + extra.y
	camera.fov = fov


func _update_boss_entry(delta: float) -> void:
	_boss_entry_left = maxf(0.0, _boss_entry_left - delta)
	var wave = stage.get("wave")
	if wave == null:
		return
	for boss in [wave.get("miniboss"), wave.get("tarantula")]:
		if is_instance_valid(boss) and not _boss_seen.has(boss.get_instance_id()):
			_boss_seen[boss.get_instance_id()] = true
			_boss_entry_left = S.BOSS_ENTRY_SECONDS
