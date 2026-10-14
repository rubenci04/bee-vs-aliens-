extends Node
## Development-only reversible presentation controls. Never touches combat nodes/shapes.
const SETTINGS := preload("res://scripts/game/bee_readability_settings.gd")
const BLOOM_SHADER := """
shader_type canvas_item;
render_mode unshaded, blend_add;
uniform sampler2D emissive_mask : filter_linear;
uniform vec2 pixel_size;
uniform float radius = 2.5;
uniform float gain = 0.4;
void fragment() {
	vec3 sum = vec3(0.0);
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			float weight = exp(-float(x*x+y*y) * 0.6);
			sum += texture(emissive_mask, UV + vec2(float(x),float(y)) * pixel_size * radius).rgb * weight;
		}
	}
	COLOR = vec4(sum * gain / 5.0, 1.0);
}
"""
var bee_index := SETTINGS.DEFAULT_BEE
var outline_level := SETTINGS.DEFAULT_OUTLINE
var background_level := SETTINGS.DEFAULT_BACKGROUND
var neon_level := SETTINGS.DEFAULT_NEON
var stage: BeeShmupStage
var panel: Label
var actor_materials: Array[Dictionary] = []
var background_materials: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var mask_view: SubViewport
var mask_camera: Camera3D
var bloom: ColorRect
var bloom_material: ShaderMaterial
var _actors := {}
var _timer := 0.0
var _model: Node3D
var _model_scale := Vector3.ONE
var enabled := false
var _viewport_size := Vector2.ZERO
var _original_glow := false

func _ready() -> void:
	stage = get_parent() as BeeShmupStage
	enabled = SETTINGS.development_enabled()
	if not enabled:
		set_process(false)
		set_process_unhandled_key_input(false)
		return
	var layer := CanvasLayer.new()
	layer.layer = 21
	add_child(layer)
	panel = Label.new()
	panel.add_theme_font_size_override("font_size", SETTINGS.PANEL_FONT_SIZE)
	panel.add_theme_color_override("font_outline_color", Color.BLACK)
	panel.add_theme_constant_override("outline_size", 3)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	_collect_background()
	_original_glow = (stage.get_node("WorldEnvironment") as WorldEnvironment).environment.glow_enabled
	if DisplayServer.get_name() != "headless":
		_build_bloom()
	get_tree().node_added.connect(_consider_shot, CONNECT_DEFERRED)
	for node in stage.find_children("*", "Node3D", true, false):
		_consider_shot(node)
	apply_modes()

func _build_bloom() -> void:
	mask_view = SubViewport.new()
	mask_view.world_3d = stage.get_viewport().world_3d
	mask_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(mask_view)
	mask_camera = Camera3D.new()
	mask_camera.cull_mask = SETTINGS.BLOOM_LAYER
	mask_camera.environment = Environment.new()
	mask_camera.environment.background_mode = Environment.BG_COLOR
	mask_camera.environment.background_color = Color.BLACK
	mask_camera.environment.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	mask_view.add_child(mask_camera)
	mask_camera.current = true
	stage.camera.cull_mask &= ~SETTINGS.BLOOM_LAYER
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	bloom = ColorRect.new()
	bloom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bloom.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = BLOOM_SHADER
	bloom_material = ShaderMaterial.new()
	bloom_material.shader = shader
	bloom_material.set_shader_parameter("emissive_mask", mask_view.get_texture())
	bloom.material = bloom_material
	layer.add_child(bloom)

func _unhandled_key_input(event: InputEvent) -> void:
	if not enabled or not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: int = event.keycode if event.keycode != 0 else event.physical_keycode
	match key:
		KEY_F5: bee_index = (bee_index + 1) % SETTINGS.BEE_SCALES.size()
		KEY_F6: outline_level = (outline_level + 1) % 3
		KEY_F7: background_level = (background_level + 1) % 3
		KEY_F8: neon_level = (neon_level + 1) % 3
		_: return
	apply_modes()
	get_viewport().set_input_as_handled()

func set_modes(bee_scale_index: int, outline: int, background: int, neon: int) -> void:
	bee_index = clampi(bee_scale_index, 0, 2)
	outline_level = clampi(outline, 0, 2)
	background_level = clampi(background, 0, 2)
	neon_level = clampi(neon, 0, 2)
	if enabled:
		apply_modes()

func _collect_background() -> void:
	for root_name in ["VisualTarget01", "AssetDressing", "DomesticGarden", "Scenery"]:
		var branch := stage.get_node_or_null(root_name)
		if branch == null:
			continue
		for mesh: MeshInstance3D in branch.find_children("*", "MeshInstance3D", true, false):
			if mesh.mesh == null:
				continue
			var center := mesh.to_global(mesh.get_aabb().get_center())
			if center.z > SETTINGS.BACKGROUND_MIN_DEPTH and not "far_" in str(mesh.name):
				continue
			for surface in mesh.mesh.get_surface_count():
				if mesh.material_override != null and surface > 0:
					continue
				var original := mesh.get_active_material(surface) as ShaderMaterial
				if original == null or original.shader not in [BeeToonStyle.TOON, BeeToonStyle.TOON_DOUBLE, BeeToonStyle.TOON_CUTOUT]:
					continue
				var own := original.duplicate() as ShaderMaterial
				if mesh.material_override != null:
					mesh.material_override = own
				else:
					mesh.set_surface_override_material(surface, own)
				background_materials.append({"own": own, "source": original, "mesh": weakref(mesh), "surface": surface})

func _collect_actors() -> bool:
	var bee_added := false
	var changed := false
	var actors: Array = get_tree().get_nodes_in_group("bee_auto_aim_targets")
	actors.append(stage.bee)
	for actor: Node3D in actors:
		if not is_instance_valid(actor) or _actors.has(actor.get_instance_id()):
			continue
		_actors[actor.get_instance_id()] = weakref(actor)
		changed = true
		bee_added = bee_added or actor == stage.bee
		for mesh: MeshInstance3D in actor.find_children("*", "MeshInstance3D", true, false):
			if mesh.mesh == null:
				continue
			for surface in mesh.mesh.get_surface_count():
				if mesh.material_override != null and surface > 0:
					continue
				var original := mesh.get_active_material(surface)
				if original == null:
					continue
				if original is ShaderMaterial and original.shader == BeeToonStyle.WING:
					continue
				if original is BaseMaterial3D and (original.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or original.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED):
					continue # Transparent wings, implant halos and warnings are FX, not actor hulls.
				var own := original.duplicate() as Material
				var override := mesh.material_override != null
				if override:
					mesh.material_override = own
				else:
					mesh.set_surface_override_material(surface, own)
				actor_materials.append({"mesh": weakref(mesh), "own": own, "surface": surface, "override": override})
	if not bee_added:
		return changed
	var visual := stage.bee.get_node("VisualRoot/BeeVisual")
	visual.call("_own_rim_materials")
	# The Bee helper duplicates body materials: use their active copies for the outline pass.
	for record in actor_materials:
		var mesh: MeshInstance3D = record["mesh"].get_ref()
		if is_instance_valid(mesh) and stage.bee.is_ancestor_of(mesh):
			record["own"] = mesh.get_active_material(record["surface"])
	return changed

func _consider_shot(node) -> void:
	# A deferred node_added notification may arrive after a short-lived node is freed.
	# Keep the argument untyped so validity can be checked before converting to Node.
	if not enabled or not is_instance_valid(node):
		return
	if not (node is BeeEnergyProjectile or node is AlienEnemyProjectile or node is AlienMortarShell or node is TarantulaWebNet or node is UfoBossMine):
		return
	for existing in shots:
		if existing["node"].get_ref() == node:
			return
	var record := {"node": weakref(node), "roots": [], "materials": [], "mask": []}
	for child in node.get_children():
		if child is Node3D and not child is DamageHitbox3D and not child is CollisionShape3D:
			record["roots"].append({"node": weakref(child), "scale": child.scale})
	var visuals: Array = node.find_children("*", "MeshInstance3D", true, false)
	for particles: CPUParticles3D in node.find_children("*", "CPUParticles3D", true, false):
		if particles.mesh is PrimitiveMesh and particles.mesh.material is BaseMaterial3D:
			var source := particles.mesh.material as BaseMaterial3D
			particles.mesh = particles.mesh.duplicate()
			var own := source.duplicate() as BaseMaterial3D
			particles.mesh.material = own
			record["materials"].append({"own": own, "source": source})
	for mesh: MeshInstance3D in visuals:
		if mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			if mesh.material_override != null and surface > 0:
				continue
			var original := mesh.get_active_material(surface) as BaseMaterial3D
			if original == null:
				continue
			var own := original.duplicate() as BaseMaterial3D
			if mesh.material_override != null:
				mesh.material_override = own
			else:
				mesh.set_surface_override_material(surface, own)
			record["materials"].append({"own": own, "source": original})
			if mask_view != null:
				var mask := MeshInstance3D.new()
				mask.mesh = mesh.mesh
				mask.layers = SETTINGS.BLOOM_LAYER
				mask.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var material := StandardMaterial3D.new()
				material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				material.albedo_color = Color(original.emission if original.emission_enabled else original.albedo_color, original.albedo_color.a)
				if original.albedo_color.a < 1.0:
					material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mask.material_override = material
				add_child(mask)
				record["mask"].append({"node": mask, "source": weakref(mesh), "emissive": own})
	shots.append(record)
	_apply_shot(record)

func _apply_shot(record: Dictionary) -> void:
	for root in record["roots"]:
		var node: Node3D = root["node"].get_ref()
		if is_instance_valid(node):
			node.scale = root["scale"] * SETTINGS.NEON_VISUAL_SCALE[neon_level]
	for data in record["materials"]:
		var original := data["source"] as BaseMaterial3D
		var own := data["own"] as BaseMaterial3D
		var boost := neon_level > 0 and original.albedo_color.a >= 0.5
		own.emission_enabled = true if boost else original.emission_enabled
		own.emission = original.emission if original.emission_enabled else original.albedo_color
		own.emission_energy_multiplier = maxf(SETTINGS.NEON_ENERGY[neon_level], original.emission_energy_multiplier) if boost else original.emission_energy_multiplier

func apply_modes() -> void:
	var visual := stage.bee.get_node("VisualRoot/BeeVisual")
	var model := visual.get("model") as Node3D
	if model != _model:
		_model = model
		_model_scale = model.scale
	if is_instance_valid(model):
		model.scale = _model_scale * SETTINGS.BEE_SCALES[bee_index]
		model.set_meta("dev_readability_scale", SETTINGS.BEE_SCALES[bee_index])
	_collect_actors()
	var outline := ShaderMaterial.new()
	outline.shader = BeeToonStyle.OUTLINE
	outline.set_shader_parameter("outline_color", SETTINGS.OUTLINE_COLOR)
	outline.set_shader_parameter("width", 2.0 * SETTINGS.OUTLINE_PIXELS[outline_level] / maxf(stage.get_viewport().get_visible_rect().size.y, 1.0))
	for record in actor_materials:
		var own := record["own"] as Material
		own.next_pass = outline if outline_level > 0 else null
	_update_background()
	for shot in shots:
		_apply_shot(shot)
	if bloom != null:
		# Bloom is masked to shots, rather than bright non-emissive scenery.
		(stage.get_node("WorldEnvironment") as WorldEnvironment).environment.glow_enabled = _original_glow if neon_level == 0 else false
		bloom.visible = neon_level > 0
		mask_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS if neon_level > 0 else SubViewport.UPDATE_DISABLED
		bloom_material.set_shader_parameter("radius", SETTINGS.BLOOM_RADIUS[neon_level])
		bloom_material.set_shader_parameter("gain", SETTINGS.BLOOM_GAIN[neon_level])
	panel.text = "DEV  F5 Bee ×%.2f  F6 contorno %d  F7 fondo %d  F8 neón %d" % [SETTINGS.BEE_SCALES[bee_index], outline_level, background_level, neon_level]

func _update_background() -> void:
	for data in background_materials:
		var own := data["own"] as ShaderMaterial
		var color: Variant = data["source"].get_shader_parameter("albedo")
		if own.get_shader_parameter("albedo") != color:
			own.set_shader_parameter("albedo", color)
		if own.get_shader_parameter("dev_saturation") != SETTINGS.BACKGROUND_SATURATION[background_level]:
			own.set_shader_parameter("dev_saturation", SETTINGS.BACKGROUND_SATURATION[background_level])
		if own.get_shader_parameter("dev_contrast") != SETTINGS.BACKGROUND_CONTRAST[background_level]:
			own.set_shader_parameter("dev_contrast", SETTINGS.BACKGROUND_CONTRAST[background_level])

func _process(delta: float) -> void:
	var view_size := stage.get_viewport().get_visible_rect().size
	if view_size != _viewport_size:
		_viewport_size = view_size
		apply_modes() # Clip-space outline width stays constant in pixels on resize.
	panel.position = Vector2(SETTINGS.PANEL_POSITION.x, stage.get_viewport().get_visible_rect().size.y + SETTINGS.PANEL_POSITION.y)
	_timer -= delta
	if _timer <= 0.0:
		_timer = SETTINGS.REFRESH_INTERVAL
		for id in _actors.keys():
			if _actors[id].get_ref() == null:
				_actors.erase(id)
		for record in actor_materials.duplicate():
			if record["mesh"].get_ref() == null:
				actor_materials.erase(record)
		if _collect_actors():
			apply_modes()
	_update_background()
	for record in shots.duplicate():
		if record["node"].get_ref() == null:
			for mask in record["mask"]:
				mask["node"].queue_free()
			shots.erase(record)
			continue
		for mask in record["mask"]:
			var source: MeshInstance3D = mask["source"].get_ref()
			if is_instance_valid(source):
				mask["node"].global_transform = source.global_transform
				mask["node"].visible = neon_level > 0 and source.is_visible_in_tree() and mask["emissive"].emission_enabled and mask["emissive"].emission_energy_multiplier > 1.0
	if mask_view != null:
		mask_view.size = Vector2i(stage.get_viewport().get_visible_rect().size) / SETTINGS.BLOOM_RESOLUTION_DIVISOR
		mask_camera.global_transform = stage.camera.global_transform
		mask_camera.projection = stage.camera.projection
		mask_camera.fov = stage.camera.fov
		mask_camera.size = stage.camera.size
		mask_camera.keep_aspect = stage.camera.keep_aspect
		bloom_material.set_shader_parameter("pixel_size", Vector2.ONE / Vector2(mask_view.size))
