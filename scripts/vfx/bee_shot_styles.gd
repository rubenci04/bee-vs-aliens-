class_name BeeShotStyles
extends RefCounted
## Tanda 3: pale core, saturated cyan/magenta body and a near-black silhouette.
## Family identity comes from shape; colours and visual sizes do not alter the tuned collision radii.
## See docs/INFORME_TANDA_3.md for the enemy -> shape/colour/size table.

const CORE_COLOR := BeeGameSettings.DANGER_CORE
const PLASMA_NAME := "StyledShot"
## The styled body is drawn a little larger than the plain orb so the shape reads at screen scale (the hitbox is `hit_radius`).
const VISUAL_SCALE := 1.3
const DART_RADIUS := 0.16
const NEEDLE_RADIUS := 0.14
const FLY_GLOB_RADIUS := 0.20
const GROUND_GLOB_RADIUS := 0.26
const SNAIL_ORB_RADIUS := 0.32

## rim: body colour · trail: trail colour · shape: body builder · hit_radius: hitbox sphere radius (m) · spin: rad/s tumble.
const STYLES := {
	&"stinger": {"rim": BeeGameSettings.DANGER_MAGENTA, "trail": BeeGameSettings.DANGER_MAGENTA, "shape": &"needle", "hit_radius": 0.12, "spin": 0.0},
	&"acid": {"rim": BeeGameSettings.DANGER_MAGENTA, "trail": BeeGameSettings.DANGER_MAGENTA, "shape": &"drop", "hit_radius": 0.13, "spin": 0.0},
	&"web": {"rim": BeeGameSettings.DANGER_CYAN, "trail": BeeGameSettings.DANGER_CYAN, "shape": &"web", "hit_radius": 0.16, "spin": 4.0},
	&"pebble": {"rim": BeeGameSettings.DANGER_CYAN, "trail": BeeGameSettings.DANGER_CYAN, "shape": &"dart", "hit_radius": 0.14, "spin": 7.0},
	&"bubble": {"rim": BeeGameSettings.DANGER_CYAN, "trail": BeeGameSettings.DANGER_CYAN, "shape": &"bubble", "hit_radius": 0.24, "spin": 0.0},
	&"spore": {"rim": BeeGameSettings.DANGER_MAGENTA, "trail": BeeGameSettings.DANGER_MAGENTA, "shape": &"spiky", "hit_radius": 0.15, "spin": 3.0},
	&"pellet": {"rim": BeeGameSettings.DANGER_CYAN, "trail": BeeGameSettings.DANGER_CYAN, "shape": &"ball", "hit_radius": 0.1, "spin": 0.0},
	&"seed": {"rim": BeeGameSettings.DANGER_MAGENTA, "trail": BeeGameSettings.DANGER_MAGENTA, "shape": &"oval", "hit_radius": 0.12, "spin": 0.0},
	&"stone": {"rim": BeeGameSettings.DANGER_MAGENTA, "trail": BeeGameSettings.DANGER_MAGENTA, "shape": &"rock", "hit_radius": 0.18, "spin": 5.0},
	&"mud": {"rim": BeeGameSettings.DANGER_CYAN, "trail": BeeGameSettings.DANGER_CYAN, "shape": &"glob", "hit_radius": 0.15, "spin": 0.0},
	&"bile": {"rim": BeeGameSettings.DANGER_MAGENTA, "trail": BeeGameSettings.DANGER_MAGENTA, "shape": &"glob", "hit_radius": 0.16, "spin": 0.0}, # The turtle's spit.
}

static var _materials := {}


static func has_style(style: StringName) -> bool:
	return STYLES.has(style)


static func _material(key: String, color: Color, transparent := false, priority := 0) -> StandardMaterial3D:
	var cache_key := "%s|%s|%s" % [key, color.to_html(), transparent]
	if _materials.has(cache_key):
		return _materials[cache_key]
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.disable_fog = true
	material.albedo_color = color
	material.render_priority = priority
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_materials[cache_key] = material
	return material


static func _mesh(parent: Node3D, mesh: Mesh, color: Color, label: String, transparent := false, priority := 0) -> MeshInstance3D:
	if mesh is PrimitiveMesh:
		(mesh as PrimitiveMesh).material = _material(label, color, transparent, priority)
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node


static func _sphere(radius: float, segments := 12, rings := 6) -> SphereMesh:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = segments
	sphere.rings = rings
	return sphere


static func _cone(bottom_radius: float, height: float) -> CylinderMesh:
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = bottom_radius
	cone.height = height
	return cone


## Builds the body of `style` under a new root (centred on the shot, pointing along +X = the travel direction).
static func build(style: StringName) -> Node3D:
	var spec: Dictionary = STYLES[style]
	var rim: Color = spec["rim"]
	var root := Node3D.new()
	root.name = PLASMA_NAME
	var body := Node3D.new() # The tumbling part (the core stays put).
	body.name = "Body"
	root.add_child(body)
	match spec["shape"]:
		&"needle", &"dart":
			var needle := CapsuleMesh.new()
			needle.radius = DART_RADIUS if spec["shape"] == &"dart" else NEEDLE_RADIUS
			needle.height = 0.62
			_mesh(body, needle, rim, "Needle").rotation.z = PI * 0.5
			var tip := _mesh(body, _cone(0.08, 0.2), rim.lightened(0.35), "Tip")
			tip.rotation.z = -PI * 0.5
			tip.position.x = 0.38
		&"drop":
			_mesh(body, _sphere(FLY_GLOB_RADIUS), rim, "Drop")
			var tail := _mesh(body, _cone(0.1, 0.34), rim, "Tail")
			tail.rotation.z = PI * 0.5 # Points backwards (-X): the drop's tail.
			tail.position.x = -0.22
			_mesh(body, _sphere(0.2), Color(rim, 0.28), "Glow", true, 1)
		&"web":
			# A fuzzy white knot of threads (never a ring: the crosshair is a ring): translucent ball + three crossed threads.
			_mesh(body, _sphere(0.22), Color(rim, 0.35), "Fluff", true, 1)
			for i in 3:
				var thread := BoxMesh.new()
				thread.size = Vector3(0.62, 0.035, 0.035)
				_mesh(body, thread, rim, "Thread%d" % i).rotation.z = PI * float(i) / 3.0
		&"rock":
			var chunk := _mesh(body, _sphere(BeeGameSettings.DANGER_MIN_RADIUS, 5, 3), rim, "Rock") # Few facets: a rock.
			chunk.scale = Vector3(1.1, 0.85, 0.95)
			_mesh(body, _sphere(0.11, 5, 3), rim.darkened(0.35), "Chip").position = Vector3(0.1, 0.07, 0.08)
		&"bubble":
			_mesh(body, _sphere(SNAIL_ORB_RADIUS), rim, "Bubble", false, 2)
			_mesh(body, _sphere(0.07, 8, 4), Color(1, 1, 1, 0.8), "Highlight", true, 3).position = Vector3(-0.1, 0.12, 0.25)
		&"spiky":
			_mesh(body, _sphere(BeeGameSettings.DANGER_MIN_RADIUS), rim, "Spore")
			for i in 6:
				var angle := TAU * float(i) / 6.0
				var spike := _mesh(body, _cone(0.04, 0.16), rim.lightened(0.25), "Spike%d" % i)
				spike.position = Vector3(cos(angle) * 0.16, sin(angle) * 0.16, 0.0)
				spike.rotation.z = angle - PI * 0.5
		&"ball":
			_mesh(body, _sphere(BeeGameSettings.DANGER_MIN_RADIUS), rim, "Pellet")
			_mesh(body, _sphere(0.14), Color(0.6, 0.6, 0.6, 0.35), "Dust", true, 1)
		&"oval":
			_mesh(body, _sphere(BeeGameSettings.DANGER_MIN_RADIUS), rim, "Seed").scale = Vector3(1.5, 1.0, 1.0)
			_mesh(body, _sphere(0.045, 6, 3), Color(0.05, 0.03, 0.03), "Spot", false, 1).position = Vector3(0.0, 0.1, 0.1)
		&"glob":
			_mesh(body, _sphere(GROUND_GLOB_RADIUS, 8, 4), rim, "Glob").scale = Vector3(1.2, 0.9, 1.0)
			_mesh(body, _sphere(0.09, 6, 3), rim.lightened(0.15), "Lump").position = Vector3(-0.12, 0.08, 0.06)
	# The hostile cyan core, in front of everything (a small dot on a spiky or flat body, bigger inside a bubble).
	# Dark back-facing shell around each opaque silhouette: no glow can obscure the core.
	for part: MeshInstance3D in body.get_children():
		var source := (part.mesh as PrimitiveMesh).material as StandardMaterial3D
		if source == null or source.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			continue
		var edge := MeshInstance3D.new()
		edge.name = "DangerBorder"
		edge.mesh = part.mesh
		edge.transform = part.transform
		edge.scale *= BeeGameSettings.DANGER_BORDER_SCALE
		var dark := _material("danger_border", BeeGameSettings.DANGER_BORDER).duplicate() as StandardMaterial3D
		dark.cull_mode = BaseMaterial3D.CULL_FRONT
		edge.material_override = dark
		edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(edge)
	var core_radius := 0.12 if spec["shape"] == &"bubble" else 0.09
	var core := _mesh(root, _sphere(core_radius, 10, 5), CORE_COLOR, "Core", false, 5)
	core.position = Vector3(0.0, 0.0, 0.35)
	var halo := _mesh(root, _sphere(core_radius * 1.9, 10, 5), Color(CORE_COLOR, 0.22), "CoreHalo", true, 4)
	halo.position = core.position
	root.scale = Vector3.ONE * VISUAL_SCALE
	return root


## A short trail of fading specks in the family colour (world space).
static func trail(style: StringName) -> CPUParticles3D:
	var spec: Dictionary = STYLES[style]
	var colour: Color = spec["trail"]
	var particles := CPUParticles3D.new()
	particles.name = "StyledTrail"
	particles.amount = 12
	particles.lifetime = 0.3
	particles.local_coords = false
	particles.gravity = Vector3.ZERO
	particles.initial_velocity_min = 0.0
	particles.initial_velocity_max = 0.0
	particles.scale_amount_min = 0.7
	particles.scale_amount_max = 1.0
	var radius := 0.07
	if spec["shape"] in [&"needle", &"dart"]:
		radius = 0.05
	elif spec["shape"] == &"bubble":
		radius = 0.12
	particles.mesh = _sphere(radius, 6, 3)
	(particles.mesh as PrimitiveMesh).material = _material("trail", Color(colour, 0.6), true, 0)
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	particles.color_ramp = fade
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.15))
	particles.scale_amount_curve = shrink
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles


## Re-dresses `projectile` as `style`: hides its old look, adds the styled body and trail, resizes the hit sphere and starts the
## tumble / wobble. Safe to call twice (it only does it once).
static func dress(projectile: Node3D, style: StringName) -> void:
	if projectile == null or not is_instance_valid(projectile) or not STYLES.has(style) or projectile.has_node(PLASMA_NAME):
		return
	var spec: Dictionary = STYLES[style]
	for child in projectile.get_children():
		if child is DamageHitbox3D:
			var shape := child.find_child("CollisionShape3D", true, false) as CollisionShape3D
			if shape != null and shape.shape is SphereShape3D:
				(shape.shape as SphereShape3D).radius = float(spec["hit_radius"])
			continue
		if child is Node3D:
			(child as Node3D).visible = false
		if child is CPUParticles3D:
			(child as CPUParticles3D).emitting = false
	var body := build(style)
	projectile.add_child(body)
	var tail := trail(style)
	projectile.add_child(tail)
	tail.emitting = true
	var spin := float(spec["spin"])
	var moving := body.get_node("Body") as Node3D
	if spin > 0.0:
		var tumble := moving.create_tween().set_loops()
		tumble.tween_property(moving, "rotation:z", TAU, TAU / spin).from(0.0)
	elif spec["shape"] == &"bubble":
		var wobble := moving.create_tween().set_loops()
		wobble.tween_property(moving, "scale", Vector3(1.12, 0.9, 1.0), 0.28).set_trans(Tween.TRANS_SINE)
		wobble.tween_property(moving, "scale", Vector3(0.92, 1.1, 1.0), 0.28).set_trans(Tween.TRANS_SINE)
