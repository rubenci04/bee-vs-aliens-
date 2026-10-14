extends RefCounted
## Visual-only shader: one draw, no collision nodes or attack timers.
const BASE_ALPHA := 0.25
const FINAL_ALPHA := 0.60
const FINAL_SECONDS := 0.30
const RAY_ALPHA := 0.35
const COLUMN_ALPHA := 0.28
const DOME_ALPHA := 0.25
const GROUND_ALPHA := 0.35
const GROUND_EDGE_ALPHA := 0.40
static var enabled := true # Review tool can compare the old drawing; gameplay defaults on.
const CODE := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color;
uniform float opacity = 0.25;
uniform float mode = 0.0;
uniform float repeats = 24.0;
uniform float ray_alpha = 0.35;
uniform float column_alpha = 0.28;
uniform float dome_alpha = 0.25;
uniform float ground_alpha = 0.35;
uniform vec2 plane_size = vec2(1.0);
uniform bool use_plane = false;
varying vec2 local_plane;
void vertex() { local_plane = VERTEX.xy; }
void fragment() {
 vec2 uv = use_plane ? local_plane / plane_size + vec2(0.5) : UV;
 float a = opacity;
 float border = 0.0;
 if (mode < 0.5) { // filled band with dashed perimeter
  border = step(0.43, abs(uv.y - 0.5));
  float dash = step(0.35, fract(uv.x * repeats));
  a *= mix(1.0, dash, border);
 } else if (mode < 1.5) { // ray: dots, no continuous fill
  a = min(opacity, ray_alpha) * step(0.42, fract(uv.x * repeats));
  border = 0.4;
 } else if (mode < 2.5) { // soft column, no hard outline
  a = min(opacity, column_alpha) * pow(max(0.0, 1.0-abs(uv.y-.5)*2.0), 1.8) * (0.2+0.8*uv.x);
 } else if (mode < 3.5) { // local endpoint only on an existing warning line
  float d = length(vec2((uv.x-.96)*12.0,(uv.y-.5)*2.0));
  a = opacity * (1.0-smoothstep(.65,.9,d));
  border = step(.55,d);
 } else if (mode < 4.5) { // beam: hot cyan center fades into edges
  a = pow(max(0.0,1.0-abs(uv.y-.5)*2.0),1.5);
 } else if (mode < 5.5) { // warning dome/ring: translucent with dotted rim
  border = step(0.65,1.0-abs(dot(normalize(NORMAL),normalize(VIEW))));
  a = min(opacity,dome_alpha) * mix(0.5,step(0.4,fract(uv.x*32.0)),border);
 } else if (mode < 6.5) { // ground impact ellipse, not a trajectory strip
  a = ground_alpha;
 } else { // upright raw column: UV axes are not rotated by place_line()
  a = min(opacity,column_alpha) * pow(max(0.0,1.0-abs(uv.x-.5)*2.0),1.8) * (0.2+0.8*uv.y);
 }
 ALBEDO = mix(tint.rgb, vec3(0.96), border*0.65);
 EMISSION = ALBEDO * (mode > 3.5 ? 1.2 : 0.25);
 ALPHA = a;
}
"""
static var shader: Shader
static func dress(node: MeshInstance3D, color: Color, mode: float, duration := 0.75) -> void:
	if not enabled:
		return
	if shader == null:
		shader = Shader.new()
		shader.code = CODE
	var material := ShaderMaterial.new()
	if not node.has_meta("warning_original_material"):
		node.set_meta("warning_original_material", node.get_active_material(0))
	material.shader = shader
	material.set_shader_parameter("tint", color)
	material.set_shader_parameter("mode", mode)
	material.set_shader_parameter("opacity", BASE_ALPHA)
	material.set_shader_parameter("ray_alpha", RAY_ALPHA)
	material.set_shader_parameter("column_alpha", COLUMN_ALPHA)
	material.set_shader_parameter("dome_alpha", DOME_ALPHA)
	material.set_shader_parameter("ground_alpha", GROUND_ALPHA)
	if node.mesh is BoxMesh:
		material.set_shader_parameter("use_plane", true)
		material.set_shader_parameter("plane_size", Vector2(node.mesh.size.x, node.mesh.size.y))
		material.set_shader_parameter("repeats", maxf(4.0,node.scale.x * node.mesh.size.x * 2.0))
	node.material_override = material
	node.set_meta("warning_style_mode", mode)
	if mode == 3.0 and node.mesh is BoxMesh and not node.has_node("ImpactMarker"):
		var mark := MeshInstance3D.new()
		mark.name = "ImpactMarker"
		var ring := TorusMesh.new()
		ring.inner_radius = 0.38
		ring.outer_radius = 0.44
		ring.rings = 24
		ring.ring_segments = 4
		var ink := StandardMaterial3D.new()
		ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ink.albedo_color = Color(0.95, 0.92, 0.76, 0.7)
		ring.material = ink
		mark.mesh = ring
		mark.rotation.x = PI * 0.5
		node.add_child(mark)
		mark.position = Vector3(0.5, 0, 0.03)
		mark.scale = Vector3(1.0 / maxf(node.scale.x, 0.01), 1, 1)
	for child in node.get_children():
		if child.name in ["ReadabilityEdge", "DangerCore", "WarningBorder", "DarkOuterBorder"]:
			if mode == 6.0 and child is MeshInstance3D:
				var rim := child.get_active_material(0).duplicate() as StandardMaterial3D
				rim.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				rim.albedo_color.a = GROUND_EDGE_ALPHA
				child.material_override = rim
			else:
				child.hide()
	if mode == 0.0:
		var tween := node.create_tween()
		tween.tween_interval(maxf(0.0, duration - FINAL_SECONDS))
		tween.tween_callback(func(): if is_instance_valid(node): material.set_shader_parameter("opacity", FINAL_ALPHA))

static func time_for(parent: Node) -> float:
	var current := parent
	for depth in 4:
		if current == null: break
		for property in ["_left", "attack_left", "_attack_left", "telegraph_seconds"]:
			var value = current.get(property)
			if value is float and value >= 0.5 and value <= 1.0:
				return value
		current = current.get_parent()
	return 0.75
