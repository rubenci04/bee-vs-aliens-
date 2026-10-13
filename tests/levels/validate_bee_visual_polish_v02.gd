extends SceneTree

# VISUAL POLISH 02 (lote 5): one cel-shaded look for the whole level, GPU particle ambience without gravity, depth layers,
# a larger Bee silhouette with unchanged hitboxes.
#   look      every solid visible surface of Level 01 uses a style C toon shader (only unshaded glow rings are exempt)
#   outline   the outline colour follows the light of the level: warm by day, violet at sunset
#   particles AmbientFx: GPUParticles3D only, zero gravity, small budgets, process material present
#   depth     veil blades + seed stalks exist and never move the approved decoration sequences (same stem / flower counts)
#   bee       v02 authored at 1.4 m, BEE_VISUAL_SCALE=1.0, body / hurtbox / melee shapes unchanged

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const EXEMPT := ["Halo", "SoftHalo"] # Emissive rings and the warm sun halo are intentionally unshaded.
## LOTE 9: item beacons, plasma shots and the hostile cyan core are glows by design (unshaded, no toon).
const EXEMPT_PARENTS := ["ItemBeacon", "PlasmaBall", "HostileGlow"]
const BEE_VISUAL_SCALE: float = preload("res://scripts/bee_prototype/bee_visual.gd").VISUAL_SCALE

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(func(): quit(1))
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	for i in 6:
		await process_frame
	# --- look ------------------------------------------------------------------------------------------------
	var toon := 0
	var offenders: Array[String] = []
	for node: MeshInstance3D in stage.find_children("*", "MeshInstance3D", true, false):
		if node.mesh == null or not node.is_visible_in_tree() or str(node.name) in EXEMPT or str(node.get_parent().name) in EXEMPT_PARENTS:
			continue
		for surface in node.mesh.get_surface_count():
			var material: Material = node.get_surface_override_material(surface)
			if material == null:
				material = node.material_override
			if material == null:
				material = node.mesh.surface_get_material(surface)
			if material is ShaderMaterial and (material as ShaderMaterial).shader.resource_path.contains("toon_"):
				toon += 1
			else:
				offenders.append(str(node.get_parent().name) + "/" + str(node.name))
	check(offenders.is_empty(), "Surfaces outside the toon look: %s" % str(offenders.slice(0, 6)))
	check(toon > 200, "Too few toon surfaces (%d)" % toon)
	# --- outline follows the light ----------------------------------------------------------------------------
	var light := stage.get_node("LightProgression") as BeeLevel01LightProgression
	stage.distance = 20.0
	light._apply(20.0)
	var morning := BeeToonStyle.outline_color
	stage.distance = 340.0
	light._apply(340.0)
	var sunset := BeeToonStyle.outline_color
	check(morning.r > morning.b + 0.02, "Day outline must be warm (%s)" % str(morning))
	check(sunset.b > sunset.r + 0.005 and sunset.b > morning.b + 0.02, "Sunset outline must be violet (%s)" % str(sunset))
	var sample := BeeToonStyle.shared_outline(BeeToonStyle.OUTLINE_PROP)
	check((sample.get_shader_parameter("outline_color") as Color).is_equal_approx(sunset), "Shared outline material not tinted")
	light._apply(20.0)
	# --- particles --------------------------------------------------------------------------------------------
	var fx := stage.get_node("AmbientFx") as BeeLevel01AmbientFx
	check(fx != null and fx.dust != null and fx.dew != null and fx.haze != null and (BeeLevel01Controller.roster_only or not fx.spark_systems.is_empty()), "AmbientFx systems missing") # LOTE 13: no alien pylons (spark sources) in the garden-only level.
	var budget := 0
	for particles: GPUParticles3D in fx.find_children("*", "GPUParticles3D", true, false):
		var pm := particles.process_material as ParticleProcessMaterial
		check(pm != null and pm.gravity == Vector3.ZERO, "%s must have zero gravity" % particles.name)
		check(particles.draw_pass_1 != null and particles.amount <= 24, "%s budget" % particles.name)
		budget += particles.amount
	check(budget <= 8 * 30 + 60, "Particle budget too large (%d)" % budget)
	check(fx.find_children("*", "CPUParticles3D", true, false).is_empty(), "AmbientFx must use GPUParticles3D")
	var falling := stage.find_children("*", "CPUParticles3D", true, false).filter(func(p): return p.gravity.y < -1.0).map(func(p): return str(p.get_parent().name) + "/" + str(p.name))
	check(falling.filter(func(n: String): return not n.ends_with("WateringCanDrips")).is_empty(), "A CPU particle system falls with strong gravity: %s" % str(falling)) # The watering can drips are real drops, on purpose.
	# Dust only while Bee is low; sparks only near the camera.
	stage.bee.global_position.y = 4.0
	await process_frame
	await process_frame
	check(not fx.dust.emitting, "Dust while flying high")
	stage.bee.global_position.y = 1.0
	await process_frame
	await process_frame
	check(fx.dust.emitting, "No dust while flying low")
	# --- depth layers -----------------------------------------------------------------------------------------
	var decoration := stage.get_node("VisualTarget01") as BeeLevel01VisualTarget
	var veil := decoration.batches.filter(func(b: MeshInstance3D): return str(b.name).contains("_veil"))
	var seeds := decoration.batches.filter(func(b: MeshInstance3D): return str(b.name).contains("_seed"))
	check(veil.size() >= 8 and seeds.size() >= 8, "Depth layers missing (veil %d, seeds %d)" % [veil.size(), seeds.size()])
	check(decoration.flower_head_count > 20, "Flower heads missing")
	# --- Bee ---------------------------------------------------------------------------------------------------
	var bee := stage.bee
	check(BeeGameSettings.BEE_MODEL_VERSION == "v02" and is_equal_approx(BEE_VISUAL_SCALE, 1.0) and is_equal_approx(bee.get_node("VisualRoot").scale.x, 1.0), "Bee v02 must use authored scale (no legacy 1.2 multiplier)")
	check(is_equal_approx(((bee.get_node("CollisionShape3D") as CollisionShape3D).shape as SphereShape3D).radius, 0.28), "Bee body shape changed")
	check(is_equal_approx(((bee.get_node("Hurtbox3D/CollisionShape3D") as CollisionShape3D).shape as SphereShape3D).radius, 0.2), "Bee hurtbox changed")
	print("BEE_VISUAL_POLISH_V02_OK toon_surfaces=%d veil=%d seeds=%d particles=%d outline_day=%s outline_sunset=%s" % [toon, veil.size(), seeds.size(), budget, str(morning), str(sunset)])
	quit(0)
