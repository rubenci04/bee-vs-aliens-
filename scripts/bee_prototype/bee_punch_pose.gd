extends RefCounted
## Animates the imported front leg meshes without changing their hierarchy or assets.
const S := preload("res://scripts/game/bee_punch_settings.gd")
const DASH := preload("res://scripts/game/bee_sting_settings.gd")
var parts: Array[Dictionary] = []
var extension := 0.0
var angle := 0.0

func bind(model: Node3D) -> void:
	parts.clear()
	for side in ["L", "R"]:
		for part_name in ["Leg_%s_0_Upper" % side, "Leg_%s_0_Lower" % side, "LegJoint_%s_0" % side, "Foot_%s_0" % side]:
			var node := model.find_child(part_name, true, false) as MeshInstance3D
			if node == null: continue
			var gold := StandardMaterial3D.new()
			gold.albedo_color = S.FIST_GOLD
			gold.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			parts.append({"node": node, "rest": node.transform, "fist": part_name.begins_with("Foot_"), "material": node.material_override, "gold": gold})

func update(dash: Node) -> void:
	angle = 0.0
	extension = 0.0
	if dash != null and dash.active:
		if dash.phase == dash.Phase.OUT:
			var elapsed: float = DASH.DASH_SECONDS - dash.left
			var start := DASH.DASH_SECONDS - S.PREPARE_SECONDS - S.STRIKE_SECONDS
			if elapsed >= start and elapsed < start + S.PREPARE_SECONDS:
				angle = lerpf(0.0, S.DRAW_BACK_ANGLE, clampf((elapsed - start) / S.PREPARE_SECONDS, 0, 1))
			elif elapsed >= start + S.PREPARE_SECONDS:
				extension = clampf((elapsed - start - S.PREPARE_SECONDS) / S.STRIKE_SECONDS, 0, 1)
				angle = lerpf(S.DRAW_BACK_ANGLE, S.CONTACT_ANGLE, extension)
		elif dash.phase == dash.Phase.IMPACT:
			angle = S.CONTACT_ANGLE
			extension = 1.0
		else:
			extension = clampf(dash.left / S.RECOVER_SECONDS, 0, 1)
			angle = S.CONTACT_ANGLE * extension
	for part in parts:
		var node: MeshInstance3D = part.node
		if not is_instance_valid(node): continue
		var rest: Transform3D = part.rest
		if angle == 0.0:
			node.transform = rest
			node.material_override = part.material
			continue
		var pivot := Vector3(rest.origin.x, S.SHOULDER_Y, S.SHOULDER_Z)
		var turn := Basis(Vector3.RIGHT, angle)
		var stretch := lerpf(1.0, S.EXTENSION_SCALE, extension)
		node.transform = Transform3D((turn * rest.basis).scaled(Vector3.ONE * stretch), pivot + turn * (rest.origin - pivot) * stretch)
		if part.fist:
			node.scale *= lerpf(1.0, S.FIST_SCALE, extension)
			node.material_override = part.gold
