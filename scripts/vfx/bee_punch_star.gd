extends Node3D
const S := preload("res://scripts/game/bee_punch_settings.gd")
var elapsed := 0.0

func _ready() -> void:
	name = "PunchContactStar"
	for core in [false, true]:
		var radius := S.STAR_RADIUS * (S.STAR_CORE_FACTOR if core else 1.0)
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in 8:
			surface.add_vertex(Vector3.ZERO)
			for index in [i, i + 1]:
				var length := radius * (1.0 if index % 2 == 0 else S.STAR_INNER_FACTOR)
				surface.add_vertex(Vector3(cos(index * TAU / 8.0) * length, sin(index * TAU / 8.0) * length, 0))
		var visual := MeshInstance3D.new()
		visual.mesh = surface.commit()
		visual.position.z = 0.002 if core else 0.0
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.render_priority = 1 if core else 0
		material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		material.no_depth_test = true # Brief contact mark must read over the overlapping fist/target.
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.albedo_color = S.STAR_WHITE if core else S.STAR_GOLD
		visual.material_override = material
		add_child(visual)

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= S.STAR_SECONDS: queue_free()
