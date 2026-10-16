extends RefCounted
## T3j: presentation only. Disabled only by comparison tools, never by gameplay.
static var enabled := true
const SECONDS := 0.5
const MAX_SCALE := 1.12
const RING_ALPHA := 0.35
const ENERGY := 2.2
const RING_THICKNESS := 0.045
const ANT_CROUCH_TILT := -0.37
static func color_for(species: StringName) -> Color:
	species = StringName(str(species).to_snake_case())
	if species == &"robot":
		return Color(1.0, 0.45, 0.15) # T7d: the walking robot pulses hot orange (cyan is for parasitic implants)
	var style: StringName = {&"ant": &"pebble", &"ladybird": &"seed", &"stag_beetle": &"stone", &"worm_b": &"mud", &"fly_common": &"pellet", &"fly_cloud": &"pellet", &"snail": &"bubble", &"fly_green": &"acid", &"wasp": &"stinger", &"spider": &"web", &"mushroom_cannon": &"spore", &"turtle": &"bile"}.get(species, &"")
	if BeeShotStyles.FACETED.COLORS.has(style):
		return BeeShotStyles.FACETED.COLORS[style]
	if BeeShotStyles.STYLES.has(style):
		return BeeShotStyles.STYLES[style].rim
	return Color(0.35, 1.0, 1.0)

## Geometry handles remain for targeting/bots; only their render layers disappear.
static func suppress(node: Node3D) -> void:
	if not enabled: return
	if node is GeometryInstance3D:
		if not node.has_meta("t3j_original_layers"):
			node.set_meta("t3j_original_layers", node.layers)
		node.layers = 0
	for child in node.get_children():
		if child is Node3D: suppress(child)

static func restore(node: Node3D) -> void:
	if node is GeometryInstance3D and node.has_meta("t3j_original_layers"):
		node.layers = int(node.get_meta("t3j_original_layers"))
	for child in node.get_children():
		if child is Node3D: restore(child)

static func ring(parent: Node, at: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var result := BeeAttackVisuals.ring(parent, at, radius, RING_THICKNESS, Color(color, RING_ALPHA))
	if enabled:
		result.material_override = BeeAttackVisuals.material(Color(color, RING_ALPHA))
		result.rotation.x = 0.0 # Ground impact ring lies on XZ, never a standing dome.
		for child in result.get_children():
			if child is Node3D: suppress(child)
	return result

static func _restore(entries: Array) -> void:
	for entry in entries:
		if not is_instance_valid(entry.mesh): continue
		if entry.surface < 0:
			entry.mesh.material_override = entry.original
		else:
			entry.mesh.set_surface_override_material(entry.surface, entry.original)

static func cancel(pose: Node3D) -> void:
	var node: Node = pose
	while node != null:
		if node.has_meta("t3j_cue"):
			var cue: Dictionary = node.get_meta("t3j_cue")
			if cue.tween.is_valid(): cue.tween.kill()
			node.scale = cue.base
			_restore(cue.meshes)
			node.remove_meta("t3j_cue")
			return
		node = node.get_parent()

static func begin(enemy: Node3D, species: StringName, pose: Node3D, seconds := SECONDS) -> void:
	if not enabled or not is_instance_valid(pose): return
	# Concurrent body/implant warnings share one pulse; no stacked scales or extra draw passes.
	var previous: Variant = pose.get_meta("t3j_cue") if pose.has_meta("t3j_cue") else null
	if previous is Dictionary:
		if previous.tween.is_valid(): previous.tween.kill()
		pose.scale = previous.base
		_restore(previous.meshes)
	var base := pose.scale
	var color := color_for(species)
	var meshes: Array[Dictionary] = []
	var sources := pose.find_children("*", "MeshInstance3D", true, false)
	if pose is MeshInstance3D: sources.append(pose)
	for mesh: MeshInstance3D in sources:
		if mesh.mesh == null: continue
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.get_active_material(surface)
			if source == null: continue
			if source is ShaderMaterial and source.get_shader_parameter("emission_energy") == null: continue
			if not (source is ShaderMaterial or source is BaseMaterial3D): continue
			var index := -1 if mesh.material_override != null else surface
			var original := mesh.material_override if index < 0 else mesh.get_surface_override_material(surface)
			var cache: Dictionary = mesh.get_meta("t3j_material_cache", {})
			var cache_key := str(surface) + ":" + str(source.get_instance_id())
			var own: Material = cache.get(cache_key)
			if own == null:
				own = source.duplicate() as Material
				cache[cache_key] = own
				mesh.set_meta("t3j_material_cache", cache)
			var old_energy := 0.0
			var old_color := Color.BLACK
			if source is ShaderMaterial:
				old_energy = float(source.get_shader_parameter("emission_energy"))
				old_color = source.get_shader_parameter("emission")
			else:
				old_energy = source.emission_energy_multiplier if source.emission_enabled else 0.0
				old_color = source.emission
			meshes.append({"mesh": mesh,"surface":index,"original":original,"own":own,"energy":old_energy,"color":old_color})
			if index < 0:
				mesh.material_override = own
				break
			else:
				mesh.set_surface_override_material(surface, own)
	var tween := enemy.create_tween()
	pose.set_meta("t3j_cue", {"base":base,"meshes":meshes,"tween":tween})
	var duration := minf(seconds, SECONDS)
	var squash := species in [&"Ant", &"ant"]
	tween.tween_method(func(p: float):
		if not is_instance_valid(pose): return
		var swell := sin(p * PI)
		var growth := (MAX_SCALE-1.0)*swell
		pose.scale = base * (Vector3(1.0+growth,1.0-growth,1.0+growth) if squash else Vector3.ONE*(1.0+growth))
		for entry in meshes:
			if entry.own is ShaderMaterial:
				entry.own.set_shader_parameter("emission",entry.color.lerp(color,swell))
				entry.own.set_shader_parameter("emission_energy",entry.energy + ENERGY*swell)
			else:
				entry.own.emission_enabled = true
				entry.own.emission = entry.color.lerp(color,swell)
				entry.own.emission_energy_multiplier = entry.energy + ENERGY*swell,
		0.0,1.0,duration)
	tween.tween_callback(func():
		if not is_instance_valid(pose): return
		pose.scale = base
		pose.remove_meta("t3j_cue")
		_restore(meshes))
