extends RefCounted
const SETTINGS := preload("res://scripts/game/bee_shooting_settings.gd")

static func eligible(bee: Node3D, target: Node3D) -> bool:
	if not bee._is_valid_target(target):
		return false
	var health := target.get_node_or_null("HealthComponent") as HealthComponent
	if health != null and (health.damage_blocked or health.invulnerable or health.current_health <= 0):
		return false
	if target.has_method("is_vulnerable") and not target.call("is_vulnerable"):
		return false
	var camera := bee.get_viewport().get_camera_3d()
	if camera == null or camera.is_position_behind(target.global_position):
		return false
	return bee.get_viewport().get_visible_rect().has_point(camera.unproject_position(target.global_position))

static func weak_point(target: Node3D) -> Node3D:
	for area in target.find_children("*", "Area3D", true, false):
		if area is DamageHurtbox3D and area.monitorable and area.health_component != null:
			if area.health_component.damage_blocked or area.health_component.invulnerable:
				continue
			if is_instance_valid(area.weak_point):
				return area.weak_point
			if area.damage_multiplier > 1.0:
				return area
	return null

static func point(bee: Node3D, target: Node3D) -> Vector3:
	var weak := weak_point(target)
	return weak.global_position if weak != null else bee._target_point(target)

static func choose(bee: Node3D, origin: Vector3, intended: Vector3) -> Node3D:
	var best: Node3D
	var best_distance := INF
	var best_weak := false
	for node in bee.get_tree().get_nodes_in_group("bee_auto_aim_targets"):
		var target := node as Node3D
		if not eligible(bee, target):
			continue
		var delta := point(bee, target) - origin
		var camera := bee.get_viewport().get_camera_3d()
		if not bee.get_viewport().get_visible_rect().has_point(camera.unproject_position(point(bee, target))):
			continue # A visible body must not pull the shot towards an off-screen implant.
		delta.z = 0.0
		var distance := delta.length()
		if distance < 0.05 or distance > SETTINGS.AIM_ASSIST_RANGE:
			continue
		if rad_to_deg(intended.angle_to(delta)) > SETTINGS.AIM_ASSIST_ANGLE:
			continue
		var weak := weak_point(target) != null
		if best == null or (weak and not best_weak) or (weak == best_weak and distance < best_distance):
			best = target
			best_distance = distance
			best_weak = weak
	return best
