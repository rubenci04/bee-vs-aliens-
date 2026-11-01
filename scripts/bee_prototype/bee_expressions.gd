extends RefCounted
## Tanda U — caras de Bee con las piezas sueltas del modelo v02 (sin Blender ni animaciones nuevas).
## bee_visual.gd la crea, le pasa el modelo y cada cuadro le dice qué cara toca (choose()); los valores se mezclan en
## TRANSITION_SECONDS. Cada pieza gira o crece alrededor del centro de su propia caja, no del origen del modelo.
const S := preload("res://scripts/game/bee_expression_settings.gd")

var parts: Dictionary = {} # nombre -> {"node", "rest", "pivot"}
var current: Dictionary = S.FACES[&"neutral"].duplicate()
var face: StringName = &"neutral"


func bind(model: Node3D) -> void:
	parts.clear()
	current = S.FACES[&"neutral"].duplicate()
	face = &"neutral"
	if model == null:
		return
	for part_name in ["Brow_L", "Brow_R", "Eye_L", "Eye_R", "EyeGlint_L", "EyeGlint_R", "Mandible_L", "Mandible_R", "AntennaTip_L", "AntennaTip_R"]:
		var node := model.find_child(part_name, true, false) as MeshInstance3D
		if node != null:
			parts[part_name] = {"node": node, "rest": node.transform, "pivot": node.get_aabb().get_center()}


func is_bound() -> bool:
	return parts.size() >= 8


## La cara que gana según la prioridad (sorpresa > contenta > cansada > concentrada > neutra).
static func choose(surprised: bool, happy: bool, tired: bool, focused: bool) -> StringName:
	var active := {&"surprised": surprised, &"happy": happy, &"tired": tired, &"focused": focused, &"neutral": true}
	for candidate in S.PRIORITY:
		if bool(active[candidate]):
			return candidate
	return &"neutral"


func update(wanted: StringName, delta: float) -> void:
	face = wanted
	var target: Dictionary = S.FACES.get(wanted, S.FACES[&"neutral"])
	var blend := clampf(delta / maxf(S.TRANSITION_SECONDS, 0.001), 0.0, 1.0)
	for key in current:
		current[key] = lerpf(float(current[key]), float(target[key]), blend)
	apply()


## Aplica `current` a las piezas (también sirve para fijar una cara al instante en tests y capturas).
func apply() -> void:
	for side in ["L", "R"]:
		var mirror := -1.0 if side == "L" else 1.0 # Cada ceja gira hacia su lado: con tilt > 0 las puntas de adentro bajan (ceño).
		_pose("Brow_" + side, Basis(Vector3.BACK, deg_to_rad(float(current["brow_tilt"]) * mirror)), Vector3.ONE, Vector3(0.0, float(current["brow_y"]), 0.0))
		var eye := Vector3(float(current["eye"]), float(current["eye"]) * float(current["squint"]), float(current["eye"]))
		_pose("Eye_" + side, Basis.IDENTITY, eye, Vector3.ZERO)
		_pose("EyeGlint_" + side, Basis.IDENTITY, eye, Vector3.ZERO)
		_pose("Mandible_" + side, Basis(Vector3.BACK, deg_to_rad(float(current["smile"]) * mirror)), Vector3.ONE, Vector3(0.0, -float(current["mouth"]), 0.0)) # 180° = cada mitad da vuelta: la boca sonríe.
		_pose("AntennaTip_" + side, Basis.IDENTITY, Vector3.ONE, Vector3(0.0, -float(current["droop"]), float(current["droop"]) * 0.5))


func set_face_now(wanted: StringName) -> void:
	face = wanted
	current = (S.FACES.get(wanted, S.FACES[&"neutral"]) as Dictionary).duplicate()
	apply()


func _pose(part_name: String, turn: Basis, size: Vector3, offset: Vector3) -> void:
	if not parts.has(part_name):
		return
	var entry: Dictionary = parts[part_name]
	var node: MeshInstance3D = entry["node"]
	if not is_instance_valid(node):
		return
	var pivot: Vector3 = entry["pivot"]
	var local := Transform3D(Basis.IDENTITY, pivot) * Transform3D(turn.scaled(size), Vector3.ZERO) * Transform3D(Basis.IDENTITY, -pivot)
	var rest: Transform3D = entry["rest"]
	node.transform = Transform3D(rest.basis, rest.origin + offset) * local
