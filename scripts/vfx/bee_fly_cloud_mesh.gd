extends RefCounted
## Batch the existing Fly_00 geometry/UVs/palette; no model or .blend is replaced.
const MODEL := preload("res://assets/models/levels/level_01_garden/enemies/lvl01_enemy_fly_swarm_v01.glb")
const SHADER_CODE := """
shader_type spatial;
render_mode specular_disabled, cull_disabled;
uniform vec4 tint : source_color = vec4(1.0);
uniform sampler2D palette : source_color;
uniform bool use_palette = false;
uniform vec3 glow : source_color = vec3(0.0);
uniform float energy = 0.0;
varying float released;
varying float warning;
void vertex() {
 released = INSTANCE_CUSTOM.b;
 warning = INSTANCE_CUSTOM.a;
 // Vertex colour alpha is wing metadata, never transparency.
 if (COLOR.a > 0.5) VERTEX.y += abs(VERTEX.z) * sin(INSTANCE_CUSTOM.g * 88.0 + INSTANCE_CUSTOM.r * 6.283185) * 0.55;
}
void fragment() {
 vec3 base = tint.rgb;
 if (use_palette) base *= texture(palette, UV).rgb;
 base = mix(base, mix(base, vec3(0.72,0.46,0.15),0.45), released);
 ALBEDO = base;
 EMISSION = glow * energy * (1.0-released) + vec3(0.3,0.85,0.95)*warning*(1.0-released);
 ROUGHNESS = 1.0;
}
void light() {
 float shade = mix(0.24,0.62,step(0.15,dot(NORMAL,LIGHT)));
 shade = mix(shade,1.0,step(0.62,dot(NORMAL,LIGHT)));
 DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION * shade / 3.141593;
}
"""
static var cached: ArrayMesh
static var center := Vector3.ZERO

static func get_mesh() -> ArrayMesh:
	if cached != null: return cached
	var source := MODEL.instantiate()
	var fly := source.find_child("Fly_00",true,false) as Node3D
	var batches := {}
	var materials := {}
	# Keep the original fly's model scale/orientation; only its formation offset is replaced.
	var fly_basis := Transform3D(fly.transform.basis,Vector3.ZERO)
	for child in fly.get_children(): _append(child,fly_basis,batches,materials)
	cached = ArrayMesh.new()
	var shader := Shader.new()
	shader.code = SHADER_CODE
	for key in batches:
		var tool: SurfaceTool = batches[key]
		var original: BaseMaterial3D = materials[key]
		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("tint",original.albedo_color)
		material.set_shader_parameter("use_palette",original.albedo_texture != null)
		if original.albedo_texture != null: material.set_shader_parameter("palette",original.albedo_texture)
		material.set_shader_parameter("glow",Vector3(original.emission.r,original.emission.g,original.emission.b))
		material.set_shader_parameter("energy",0.65 if original.emission_enabled else 0.0)
		tool.set_material(material)
		tool.commit(cached)
	center = cached.get_aabb().get_center()
	source.free()
	return cached

static func _append(node: Node, parent: Transform3D, batches: Dictionary, materials: Dictionary) -> void:
	var transform: Transform3D = parent * (node as Node3D).transform if node is Node3D else parent
	if node is MeshInstance3D and node.mesh != null:
		for surface in node.mesh.get_surface_count():
			var material := node.get_active_material(surface) as BaseMaterial3D
			var key := material.get_instance_id()
			if not batches.has(key):
				var tool := SurfaceTool.new()
				tool.begin(Mesh.PRIMITIVE_TRIANGLES)
				batches[key] = tool
				materials[key] = material
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var colours := PackedColorArray()
			colours.resize((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
			colours.fill(Color(1,1,1,1 if str(node.name).to_lower().contains("wing") else 0))
			arrays[Mesh.ARRAY_COLOR] = colours
			var marked := ArrayMesh.new()
			marked.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			(batches[key] as SurfaceTool).append_from(marked,0,transform)
	for child in node.get_children(): _append(child,transform,batches,materials)
