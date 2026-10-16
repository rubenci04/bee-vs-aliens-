extends Node3D
## Sibling of the passenger: its whole subtree is inert until the beam finishes.
const S := preload("res://scripts/game/bee_encounter_settings.gd")
const CODE := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float reveal = 0.0;
uniform float flash = 0.0;
void fragment() {
 vec2 cell = mod(floor(FRAGCOORD.xy), 4.0);
 float threshold = ((mod(cell.x,2.0)*2.0+mod(cell.y,2.0))*4.0+floor(cell.x/2.0)*2.0+floor(cell.y/2.0)) / 16.0;
 if (reveal <= threshold) discard;
 ALBEDO = mix(vec3(0.08,0.65,0.8),vec3(0.8,1.0,1.0),flash);
 EMISSION = vec3(0.2,0.8,1.0) * (0.3 + flash);
}
"""
var passenger: Node3D
var destination: Vector3
var on_arrive: Callable
var returning := false
var elapsed := 0.0
var mark_seconds := S.MARK_SECONDS
var material: ShaderMaterial
var mark: MeshInstance3D
var beam: MeshInstance3D
var saved_meshes: Array[Dictionary] = []
var saved_areas: Array[Dictionary] = []
var saved_health: Array[Dictionary] = []
var saved_targets: Array[Node] = []
var base_scale := Vector3.ONE
var old_mode := Node.PROCESS_MODE_INHERIT
var was_visible := false
var arrived := false

static func begin(unit: Node3D, at: Vector3, callback: Callable, is_return := false) -> Node3D:
	var effect := load("res://scripts/vfx/bee_enemy_teleport.gd").new() as Node3D
	effect.passenger = unit
	effect.destination = at
	effect.on_arrive = callback
	effect.returning = is_return
	unit.get_parent().add_child(effect)
	return effect

func _ready() -> void:
	name = "EnemyTeleport"
	mark_seconds = S.RETURN_MARK_SECONDS if returning else S.MARK_SECONDS
	base_scale = passenger.scale
	old_mode = passenger.process_mode
	was_visible = passenger.visible
	passenger.set_meta("teleporting", true)
	# Cancel a committed strike before moving it to another place.
	if returning and passenger.has_method("_cancel_attack"):
		passenger.call("_cancel_attack")
	if returning:
		for child in passenger.get_children():
			if child is BeeImplantShooter:
				child._cancel()
				child.clock = child.FIRST_DELAY
	passenger.process_mode = Node.PROCESS_MODE_DISABLED
	var nodes: Array[Node] = [passenger]
	nodes.append_array(passenger.find_children("*", "", true, false))
	var shader := Shader.new()
	shader.code = CODE
	material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("reveal", 1.0 if returning else 0.0)
	for node in nodes:
		if node.is_in_group("bee_auto_aim_targets"):
			saved_targets.append(node)
			node.remove_from_group("bee_auto_aim_targets")
		if node is GeometryInstance3D:
			saved_meshes.append({"node":node,"material":node.material_override})
			node.material_override = material
		if node is HealthComponent:
			saved_health.append({"node":node,"blocked":node.damage_blocked})
			node.damage_blocked = true
		if node is Area3D:
			saved_areas.append({"node":node,"layer":node.collision_layer,"mask":node.collision_mask,"monitorable":node.monitorable,"monitoring":node.monitoring})
			node.set_deferred("collision_layer",0)
			node.set_deferred("collision_mask",0)
			node.set_deferred("monitorable",false)
			node.set_deferred("monitoring",false)
	if not returning: passenger.hide()
	mark = _mesh("ArrivalMark", true)
	mark.global_position = Vector3(destination.x,S.GROUND_Y,destination.z)
	beam = _mesh("ArrivalBeam", false)
	beam.global_position = Vector3(destination.x,(S.BEAM_TOP+S.GROUND_Y)*0.5,destination.z)
	beam.hide()

func _mesh(label: String, ground: bool) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = S.BEAM_RADIUS
	cylinder.bottom_radius = S.BEAM_RADIUS
	cylinder.height = 0.035 if ground else S.BEAM_TOP-S.GROUND_Y
	cylinder.radial_segments = 16
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.15,0.8,1.0,0.22 if not ground else 0.75)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cylinder.material = mat
	node.mesh = cylinder
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node

func _physics_process(delta: float) -> void:
	if not is_instance_valid(passenger):
		queue_free()
		return
	# Frozen director (defeat/victory) must never activate a late arrival.
	var stage := get_parent().get_parent()
	var director := stage.get_node_or_null("WaveController")
	if director != null and bool(director.get("_frozen")): return
	elapsed += delta
	var pulse := sin(PI*clampf(elapsed/mark_seconds,0,1))
	mark.scale = Vector3.ONE * (0.9+0.12*pulse)
	material.set_shader_parameter("flash",0.5+0.5*sin(elapsed*TAU*4))
	if elapsed < mark_seconds:
		if returning: passenger.scale = base_scale*lerpf(1.0,S.WARNING_SCALE,pulse)
		return
	if not arrived:
		arrived = true
		passenger.global_position = destination
		passenger.scale = base_scale
		passenger.show()
		beam.show()
	var progress := clampf((elapsed-mark_seconds)/S.MATERIALIZE_SECONDS,0,1)
	material.set_shader_parameter("reveal",progress)
	if progress < 1.0: return
	beam.scale.x = maxf(0.01,1.0-(elapsed-mark_seconds-S.MATERIALIZE_SECONDS)/S.BEAM_FADE_SECONDS)
	beam.scale.z = beam.scale.x
	if elapsed < mark_seconds+S.MATERIALIZE_SECONDS+S.BEAM_FADE_SECONDS: return
	_restore()
	if on_arrive.is_valid(): on_arrive.call()
	queue_free()

func _restore() -> void:
	for entry in saved_meshes:
		if is_instance_valid(entry.node): entry.node.material_override = entry.material
	for entry in saved_health:
		if is_instance_valid(entry.node): entry.node.damage_blocked = entry.blocked
	for entry in saved_areas:
		if not is_instance_valid(entry.node): continue
		for key in ["collision_layer","collision_mask","monitorable","monitoring"]:
			var source: String = {"collision_layer":"layer","collision_mask":"mask"}.get(key,key)
			entry.node.set_deferred(key,entry[source])
	for node in saved_targets:
		if is_instance_valid(node): node.add_to_group("bee_auto_aim_targets")
	passenger.process_mode = old_mode
	passenger.set_meta("teleporting",false)
	passenger.scale = base_scale
