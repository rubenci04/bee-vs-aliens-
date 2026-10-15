class_name BeeJuice
extends RefCounted
## Shared hit feedback. T4f reserves local microfreeze/shake for sting, roll-shot and boss-armour events.

const HIT_FLASH_SECONDS := preload("res://scripts/game/bee_feedback_settings.gd").FLASH_SECONDS
const HIT_FLASH_COLOR := preload("res://scripts/game/bee_feedback_settings.gd").FLASH_COLOR
## Legacy constants remain available to old review tools; live events never change Engine.time_scale.
const HIT_STOP_SECONDS := preload("res://scripts/game/bee_release_settings.gd").STOP_SECONDS
const HIT_STOP_TIME_SCALE := 0.02
## Previous kill classification, kept for external tools; it no longer triggers hit stop.
const BIG_HP := 90
const POLLEN_BURST_AMOUNT := 26
const POLLEN_BURST_COLOR := Color(1.0, 0.82, 0.25)

const FLASH_SCENE := preload("res://scenes/components/hit_flash_3d.tscn")

## Off in tests that need exact game time (they switch it on to test the hit stop itself).
static var hit_stop_enabled := true
static var hit_stops := 0


## Makes `unit` flash white for HIT_FLASH_SECONDS whenever it takes damage. Re-uses an existing HitFlash3D.
static func attach_hit_flash(unit: Node) -> HitFlash3D:
	var flash := unit.get_node_or_null("HitFlash3D") as HitFlash3D
	if flash == null:
		if unit.get_node_or_null("HealthComponent") == null:
			return null
		var root_path := ^""
		for candidate in ["VisualRoot", "Rig"]:
			if unit.get_node_or_null(candidate) != null:
				root_path = NodePath("../" + candidate)
				break
		if root_path.is_empty():
			return null
		flash = FLASH_SCENE.instantiate() as HitFlash3D
		flash.name = "HitFlash3D"
		flash.visual_root_path = root_path
		flash.duration = HIT_FLASH_SECONDS
		flash.flash_color = HIT_FLASH_COLOR
		unit.add_child(flash)
		return flash
	flash.duration = HIT_FLASH_SECONDS
	flash.flash_color = HIT_FLASH_COLOR
	flash.set_flash_color(HIT_FLASH_COLOR)
	return flash


## Legacy entry point kept for old tools: ordinary kills never stop time now.
static func hit_stop(_tree: SceneTree, _seconds := HIT_STOP_SECONDS) -> void:
	pass

static func key_event(from: Node3D, event: StringName, target: Node3D = null, direction := Vector2.RIGHT) -> bool:
	if from == null or not from.is_inside_tree(): return false
	return preload("res://scripts/vfx/bee_local_hit_stop.gd").for_host(from).trigger(from,event,target,direction)


## Warm pollen cloud where an animal was freed (one-shot CPU particles, frees itself).
static func pollen_burst(parent: Node, point: Vector3) -> CPUParticles3D:
	if parent == null or not parent.is_inside_tree():
		return null
	var particles := CPUParticles3D.new()
	particles.name = "PollenBurst"
	particles.emitting = false
	particles.one_shot = true
	particles.amount = POLLEN_BURST_AMOUNT
	particles.lifetime = 0.9
	particles.explosiveness = 1.0
	particles.direction = Vector3.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 1.2
	particles.initial_velocity_max = 3.2
	particles.gravity = Vector3(0.0, -1.6, 0.0)
	particles.damping_min = 1.0
	particles.damping_max = 2.0
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.1
	var mesh := SphereMesh.new()
	mesh.radius = 0.07
	mesh.height = 0.14
	mesh.radial_segments = 6
	mesh.rings = 3
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = POLLEN_BURST_COLOR
	mesh.material = material
	particles.mesh = mesh
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(particles)
	particles.global_position = point
	particles.restart()
	particles.emitting = true
	parent.get_tree().create_timer(particles.lifetime + 0.3, true, false, true).timeout.connect(particles.queue_free)
	return particles
