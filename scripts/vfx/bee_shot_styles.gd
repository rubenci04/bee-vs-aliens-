class_name BeeShotStyles
extends RefCounted
## Tanda 3d: six selected B appearances dispatch to FACETED below.
## STYLES retains the historical data and tuned hit radii/spin/pattern roles;
## selected visual colours/sizes live in bee_facet_shot_styles.gd.
## LOTE 13 · ETAPA 2 — every Level 1 family fires a shot you can tell apart at a glance. The CORE is always cyan (hostile); the rim
## colour, the shape and the trail belong to the family. They all contrast with Bee's golden shot (warm halo, white-hot core, short
## warm trail): cold or dark rims, odd shapes, and the cyan dot in the middle.
##   stinger  Wasp            long violet needle, violet streak
##   acid     Green fly       lime teardrop, dripping lime trail
##   web      Spider          fuzzy white knot of crossed threads, white thread trail (never a ring: the crosshair is a ring)
##   pebble   Ant             faceted burnt-orange pebble, tumbling, lobbed in an arc
##   bubble   Snail           big translucent slime bubble that wobbles, lobbed slowly
##   spore    Cannon mushroom magenta spiky spore, magenta puffs
##   pellet   Common fly      small black pellet, grey dust
##   seed     Ladybird        red oval seed with a black spot
##   stone    Stag beetle     grey-brown faceted stone, lobbed in an arc
##   mud      Worm B          dark mud glob, brown trail
## Presentation only: the hitbox, damage and speed of the shot are untouched except for `hit_radius` (so a big bubble reads as big).

const CORE_COLOR := Color(0.25, 0.97, 1.0)
const FACETED := preload("res://scripts/vfx/bee_facet_shot_styles.gd")
const PLASMA_NAME := "StyledShot"
## The styled body is drawn a little larger than the plain orb so the shape reads at screen scale (the hitbox is `hit_radius`).
const VISUAL_SCALE := 1.3

## rim: body colour · trail: trail colour · shape: body builder · hit_radius: hitbox sphere radius (m) · spin: rad/s tumble.
const STYLES := {
	&"stinger": {"rim": Color(0.6, 0.2, 0.95), "trail": Color(0.72, 0.35, 1.0), "shape": &"needle", "hit_radius": 0.12, "spin": 0.0},
	&"acid": {"rim": Color(0.55, 0.95, 0.1), "trail": Color(0.6, 1.0, 0.2), "shape": &"drop", "hit_radius": 0.13, "spin": 0.0},
	&"web": {"rim": Color(0.97, 0.97, 0.92), "trail": Color(1.0, 1.0, 0.96), "shape": &"web", "hit_radius": 0.16, "spin": 4.0},
	&"pebble": {"rim": Color(0.88, 0.36, 0.08), "trail": Color(0.6, 0.35, 0.15), "shape": &"rock", "hit_radius": 0.14, "spin": 7.0},
	&"bubble": {"rim": Color(0.75, 1.0, 0.85), "trail": Color(0.8, 1.0, 0.9), "shape": &"bubble", "hit_radius": 0.24, "spin": 0.0},
	&"spore": {"rim": Color(0.92, 0.18, 0.78), "trail": Color(0.95, 0.35, 0.85), "shape": &"spiky", "hit_radius": 0.15, "spin": 3.0},
	&"pellet": {"rim": Color(0.1, 0.08, 0.07), "trail": Color(0.5, 0.5, 0.5), "shape": &"ball", "hit_radius": 0.1, "spin": 0.0},
	&"seed": {"rim": Color(0.85, 0.08, 0.1), "trail": Color(0.9, 0.3, 0.25), "shape": &"oval", "hit_radius": 0.12, "spin": 0.0},
	&"stone": {"rim": Color(0.5, 0.44, 0.36), "trail": Color(0.55, 0.5, 0.42), "shape": &"rock", "hit_radius": 0.18, "spin": 5.0},
	&"mud": {"rim": Color(0.3, 0.19, 0.1), "trail": Color(0.45, 0.3, 0.16), "shape": &"glob", "hit_radius": 0.15, "spin": 0.0},
	&"bile": {"rim": Color(0.3, 0.55, 0.18), "trail": Color(0.45, 0.7, 0.25), "shape": &"glob", "hit_radius": 0.16, "spin": 0.0}, # The turtle's spit.
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
	if FACETED.has_style(style):
		return FACETED.build(style)
	return build_original(style)


## Historical factory retained for the A/B comparison tool and unselected families.
static func build_original(style: StringName) -> Node3D:
	var spec: Dictionary = STYLES[style]
	var rim: Color = spec["rim"]
	var root := Node3D.new()
	root.name = PLASMA_NAME
	var body := Node3D.new() # The tumbling part (the core stays put).
	body.name = "Body"
	root.add_child(body)
	match spec["shape"]:
		&"needle":
			var needle := CapsuleMesh.new()
			needle.radius = 0.07
			needle.height = 0.62
			_mesh(body, needle, rim, "Needle").rotation.z = PI * 0.5
			var tip := _mesh(body, _cone(0.08, 0.2), rim.lightened(0.35), "Tip")
			tip.rotation.z = -PI * 0.5
			tip.position.x = 0.38
		&"drop":
			_mesh(body, _sphere(0.14), rim, "Drop")
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
			var chunk := _mesh(body, _sphere(0.17 if style == &"stone" else 0.15, 5, 3), rim, "Rock") # Few facets: a rock.
			chunk.scale = Vector3(1.1, 0.85, 0.95)
			_mesh(body, _sphere(0.11, 5, 3), rim.darkened(0.35), "Chip").position = Vector3(0.1, 0.07, 0.08)
		&"bubble":
			_mesh(body, _sphere(0.3), Color(rim, 0.34), "Bubble", true, 2)
			_mesh(body, _sphere(0.07, 8, 4), Color(1, 1, 1, 0.8), "Highlight", true, 3).position = Vector3(-0.1, 0.12, 0.25)
		&"spiky":
			_mesh(body, _sphere(0.13), rim, "Spore")
			for i in 6:
				var angle := TAU * float(i) / 6.0
				var spike := _mesh(body, _cone(0.04, 0.16), rim.lightened(0.25), "Spike%d" % i)
				spike.position = Vector3(cos(angle) * 0.16, sin(angle) * 0.16, 0.0)
				spike.rotation.z = angle - PI * 0.5
		&"ball":
			_mesh(body, _sphere(0.1), rim, "Pellet")
			_mesh(body, _sphere(0.14), Color(0.6, 0.6, 0.6, 0.35), "Dust", true, 1)
		&"oval":
			_mesh(body, _sphere(0.12), rim, "Seed").scale = Vector3(1.5, 1.0, 1.0)
			_mesh(body, _sphere(0.045, 6, 3), Color(0.05, 0.03, 0.03), "Spot", false, 1).position = Vector3(0.0, 0.1, 0.1)
		&"glob":
			_mesh(body, _sphere(0.16, 8, 4), rim, "Glob").scale = Vector3(1.2, 0.9, 1.0)
			_mesh(body, _sphere(0.09, 6, 3), rim.lightened(0.15), "Lump").position = Vector3(-0.12, 0.08, 0.06)
	# The hostile cyan core, in front of everything (a small dot on a spiky or flat body, bigger inside a bubble).
	var core_radius := 0.11 if spec["shape"] == &"bubble" else 0.075
	var core := _mesh(root, _sphere(core_radius, 10, 5), CORE_COLOR, "Core", false, 5)
	core.position = Vector3(0.0, 0.0, 0.03)
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
	if spec["shape"] == &"needle":
		radius = 0.05
	elif spec["shape"] == &"bubble":
		radius = 0.12
	particles.mesh = _sphere(radius, 6, 3)
	(particles.mesh as PrimitiveMesh).material = FACETED.trail_material(style) if FACETED.has_style(style) else _material("trail", Color(colour, 0.6), true, 0)
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
