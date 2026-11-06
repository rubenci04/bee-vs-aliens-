class_name BeeCameraRig
extends Node
## Mejora visual: la cámara del Nivel 1 con vida. Lo que se dibuja cambia; los límites de vuelo, no.
## Cómo: el nodo Camera3D sigue en la X/Y/Z de siempre (muchos scripts leen camera.global_position). El giro va en la rotación
## del nodo y el desplazamiento del dibujo va en h_offset / v_offset, que Godot aplica solo al renderizar. Así el centro de la
## vista cae donde queremos sin mover la posición lógica.
## Con la cámara girada se ve MÁS mundo a la derecha y un poco menos a la izquierda. Para que "estar en pantalla" siga siendo
## lo que el jugador ve, BeeShmupFairness usa los bordes reales (logic_left / logic_right) y las apariciones nacen más lejos
## (BeeLevel01Framing.render_right_extra).
const S := preload("res://scripts/game/bee_camera_settings.gd")

## Activo = hay rig dinámico. Lo leen BeeShmupFairness y BeeLevel01Framing.
static var logic_active := false
## Bordes visibles sobre el plano de vuelo, en metros desde la X de la cámara (izquierda negativa).
static var logic_left := 0.0
static var logic_right := 0.0

var stage: Node
var yaw_now := 0.0
var _follow_y := 0.0
var _roll := 0.0
var _time := 0.0
var _boss_entry_left := 0.0
var _boss_seen := {}
var _started := false


static func enabled() -> bool:
	return S.mode != &"lateral" and (S.ACTIVE_IN_HEADLESS or DisplayServer.get_name() != "headless")


static func attach(parent: Node) -> BeeCameraRig:
	if not enabled():
		return null
	var rig := BeeCameraRig.new()
	rig.name = "CameraRig"
	rig.stage = parent
	rig.process_priority = 100 # Después de todo lo demás: es lo último antes de dibujar.
	rig.process_mode = Node.PROCESS_MODE_ALWAYS # Sigue encuadrando durante la pausa y las escenas cortas.
	parent.add_child(rig)
	logic_active = true
	var aspect := BeeLevel01Framing.DESIGN_ASPECT
	var viewport := parent.get_viewport()
	if viewport != null:
		aspect = BeeLevel01Framing.view_aspect(viewport)
	BeeLevel01Framing.render_right_extra = maxf(0.0, widest_right(aspect) - BeeLevel01Framing.half_width_max(aspect))
	var edges := visible_edges(framing_at(0.0), aspect)
	logic_left = edges.x
	logic_right = edges.y
	return rig


func _exit_tree() -> void:
	logic_active = false
	BeeLevel01Framing.render_right_extra = 0.0


## Interpola la tabla de zonas: [giro, inclinación, altura, FOV, retroceso].
static func framing_at(x: float) -> Array:
	var table: Array = S.KEYFRAMES
	if x <= float(table[0][0]):
		return table[0].slice(1)
	for i in range(1, table.size()):
		if x <= float(table[i][0]):
			var t := smoothstep(float(table[i - 1][0]), float(table[i][0]), x)
			var out := []
			for k in range(1, table[i].size()):
				out.append(lerpf(float(table[i - 1][k]), float(table[i][k]), t))
			return out
	return table[table.size() - 1].slice(1)


## Lo más a la derecha que llega a verse en todo el nivel (para que nada aparezca a la vista).
static func widest_right(aspect: float) -> float:
	var widest := 0.0
	for row: Array in S.KEYFRAMES:
		widest = maxf(widest, visible_edges(row.slice(1), aspect, S.BOSS_ENTRY_YAW if float(row[0]) >= S.BOSS_ENTRY_FROM_X else 0.0).y)
	return widest


## Bordes izquierdo y derecho visibles en el plano de vuelo para un encuadre, relativos a la X de la cámara.
static func visible_edges(framing: Array, aspect: float, extra_yaw := 0.0) -> Vector2:
	var basis := view_basis(float(framing[0]) + extra_yaw, BeeLevel01Framing.CAMERA_PITCH_DEGREES + float(framing[1]), 0.0)
	var origin := view_origin(basis, Vector3(-float(framing[4]), center_y_on_plane() + float(framing[2]), 0.0))
	var half := tan(deg_to_rad(BeeLevel01Framing.effective_fov() * float(framing[3])) * 0.5) * aspect
	var out := Vector2.ZERO
	for side in [-1.0, 1.0]:
		var ray: Vector3 = (-basis.z + basis.x * half * side).normalized()
		var hit: float = origin.x + ray.x * (-origin.z / ray.z)
		if side < 0.0:
			out.x = hit
		else:
			out.y = hit
	return out


## Dónde cae en pantalla (-1 a 1 en cada eje) un punto del plano de vuelo con un encuadre, relativo a la X de la cámara.
static func screen_point(point: Vector3, framing: Array, aspect: float, extra_yaw := 0.0, roll := 0.0) -> Vector2:
	var basis := view_basis(float(framing[0]) + extra_yaw, BeeLevel01Framing.CAMERA_PITCH_DEGREES + float(framing[1]), roll)
	var origin := view_origin(basis, Vector3(-float(framing[4]), center_y_on_plane() + float(framing[2]), 0.0))
	var rel := point - origin
	var depth := rel.dot(-basis.z)
	var tan_half := tan(deg_to_rad(BeeLevel01Framing.effective_fov() * float(framing[3])) * 0.5)
	return Vector2(rel.dot(basis.x) / (depth * tan_half * aspect), rel.dot(basis.y) / (depth * tan_half))


## Giro hacia +X = rotación Y negativa en Godot. Inclinación positiva = mira hacia arriba, igual que la cámara lateral.
static func view_basis(yaw_deg: float, pitch_deg: float, roll_deg: float) -> Basis:
	return Basis.from_euler(Vector3(deg_to_rad(pitch_deg), -deg_to_rad(yaw_deg), deg_to_rad(roll_deg)))


static func view_origin(basis: Basis, center: Vector3) -> Vector3:
	var cam := Vector3(0.0, BeeLevel01Framing.effective_height(), BeeLevel01Framing.CAMERA_DISTANCE)
	var to := center - cam
	return cam + basis.x * to.dot(basis.x) + basis.y * to.dot(basis.y)


func _process(delta: float) -> void:
	if stage == null:
		return
	var camera := stage.get("camera") as Camera3D
	var bee := stage.get("bee") as Node3D
	if camera == null or bee == null:
		return
	_time += delta
	apply_dynamic(camera, bee, delta)


func apply_dynamic(camera: Camera3D, bee: Node3D, delta: float) -> void:
	var x: float = camera.global_position.x
	var framing := framing_at(x)
	var aspect := BeeLevel01Framing.view_aspect(camera.get_viewport())
	var half: float = BeeLevel01Framing.half_width_min(aspect)
	var smooth := 1.0 - exp(-delta / maxf(S.SMOOTH_SECONDS, 0.01))
	if not _started: # El primer cuadro entra directo, sin barrido desde cero.
		_started = true
		smooth = 1.0
	# Seguimiento suave de Bee: su altura mueve un poco la vista y su lugar en la pantalla, el giro.
	var center_y := center_y_on_plane()
	_follow_y = lerpf(_follow_y, clampf((bee.global_position.y - center_y) * S.BEE_FOLLOW_Y, -S.BEE_FOLLOW_MAX, S.BEE_FOLLOW_MAX), smooth)
	var side := clampf((bee.global_position.x - x) / maxf(half, 0.1), -1.0, 1.0)
	var velocity := Vector3.ZERO
	if bee is CharacterBody3D:
		velocity = (bee as CharacterBody3D).velocity
	_roll = lerpf(_roll, clampf(velocity.y * S.ROLL_FROM_VY, -S.ROLL_MAX, S.ROLL_MAX), smooth)
	_update_boss_entry(delta)
	var boss_yaw := S.BOSS_ENTRY_YAW * smoothstep(0.0, 0.5, _boss_entry_left / S.BOSS_ENTRY_SECONDS)
	yaw_now = lerpf(yaw_now, float(framing[0]) + side * S.BEE_YAW_FROM_X + boss_yaw, smooth)
	var yaw := yaw_now + sin(_time * S.BREATH_SPEED) * S.BREATH_YAW
	var pitch: float = BeeLevel01Framing.CAMERA_PITCH_DEGREES + float(framing[1])
	var center := Vector3(x - float(framing[4]), center_y + float(framing[2]) + _follow_y + sin(_time * S.BREATH_SPEED * 1.7) * S.BREATH_Y, 0.0)
	# Durante una escena corta el juego está en pausa y la escena maneja su propio FOV.
	var fov := camera.fov if get_tree().paused else BeeLevel01Framing.effective_fov() * float(framing[3]) * float(stage.get("melee_fov_factor"))
	aim(camera, yaw, pitch, _roll, center, fov)
	var edges := visible_edges([yaw_now, framing[1], framing[2], framing[3], framing[4]], aspect)
	logic_left = edges.x
	logic_right = edges.y
	var live := stage.get_node_or_null("LiveReadability")
	if live != null:
		live.call("sync_mask_camera")


## El centro de la vista sobre el plano de vuelo con la cámara lateral (el que hay que conservar).
static func center_y_on_plane() -> float:
	return (BeeLevel01Framing.top_y() + BeeLevel01Framing.bottom_y()) * 0.5


## Orienta la cámara y deja el centro de la vista sobre `target` usando solo offsets de dibujo (más la sacudida vigente).
static func aim(camera: Camera3D, yaw_deg: float, pitch_deg: float, roll_deg: float, target: Vector3, fov: float) -> void:
	camera.rotation = Vector3(deg_to_rad(pitch_deg), -deg_to_rad(yaw_deg), deg_to_rad(roll_deg))
	var basis := camera.global_transform.basis.orthonormalized()
	var to_target := target - camera.global_position
	var base := Vector2(to_target.dot(basis.x), to_target.dot(basis.y))
	camera.set_meta("rig_offset", base)
	var shake: Vector2 = camera.get_meta("shake_offset", Vector2.ZERO)
	camera.h_offset = base.x + shake.x
	camera.v_offset = base.y + shake.y
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
