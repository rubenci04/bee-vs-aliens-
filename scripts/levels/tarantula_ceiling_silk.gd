extends Node3D
## Tanda T — la tarántula en el techo no flota: mientras camina boca abajo (mode &"ceiling") cuelga de hilos de seda que
## suben desde sus patas hasta arriba del borde de la pantalla. Solo dibujo:
## sin colisión ni daño. Aparece y se va con un fundido corto cuando sube o baja del techo.
const FIX := preload("res://scripts/game/bee_flow_fix_settings.gd")

var boss: TarantulaBoss01
var strands: Array[MeshInstance3D] = []
var alpha := 0.0


static func attach(tarantula: TarantulaBoss01) -> Node3D:
	if not FIX.ENABLED or not FIX.CEILING_SILK_ENABLED or tarantula == null:
		return null
	var silk := (load("res://scripts/levels/tarantula_ceiling_silk.gd") as GDScript).new() as Node3D
	silk.name = "CeilingSilk"
	silk.set("boss", tarantula)
	tarantula.add_child(silk)
	return silk


func _ready() -> void:
	for i in FIX.CEILING_SILK_LEG_X.size():
		strands.append(_strand(FIX.CEILING_SILK_WIDTH))
	_set_alpha(0.0)


func _strand(width: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.0, width, 0.03)
	var material := StandardMaterial3D.new() # Material propio: el fundido no toca los materiales compartidos de BeeAttackVisuals.
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = FIX.CEILING_SILK_COLOR
	box.material = material
	node.mesh = box
	node.top_level = true
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node


func _process(delta: float) -> void:
	if not is_instance_valid(boss) or boss.visual_root == null:
		return
	var on_ceiling := boss.mode == &"ceiling" and not boss.is_defeated()
	alpha = move_toward(alpha, 1.0 if on_ceiling else 0.0, delta / FIX.CEILING_SILK_FADE_SECONDS)
	_set_alpha(alpha)
	if alpha <= 0.0:
		return
	var top := BeeLevel01Framing.top_y() + FIX.CEILING_SILK_ABOVE_SCREEN
	for i in strands.size():
		# Puntas de las patas (boca abajo quedan arriba del cuerpo): de ahí sube cada hilo, un poco abierto hacia afuera.
		var foot := boss._world(Vector2(float(FIX.CEILING_SILK_LEG_X[i]), TarantulaBoss01.LEGS_CENTRE.y))
		var anchor := Vector3(foot.x + float(FIX.CEILING_SILK_LEG_X[i]) * FIX.CEILING_SILK_SPREAD, top, foot.z)
		BeeAttackVisuals.place_line(strands[i], foot, anchor)


func _set_alpha(value: float) -> void:
	for node: MeshInstance3D in strands:
		if node == null: continue
		node.visible = value > 0.01
		((node.mesh as BoxMesh).material as StandardMaterial3D).albedo_color.a = FIX.CEILING_SILK_COLOR.a * value
