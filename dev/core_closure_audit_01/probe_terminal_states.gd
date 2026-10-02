extends SceneTree

# Audit-only fixture. Never attached to a gameplay scene or added to the suite.
# Reach the existing completion branch, then inspect its response to a real shot.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var level = load("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	for i in 4:
		await process_frame
	level.set_physics_process(false)
	level.wave.set_physics_process(false)
	level.bee.set_physics_process(false)
	level.wave._complete = true
	level.distance = 360.0
	level._on_wave_completed()
	level.distance = level._clear_at
	level._physics_process(0.0)
	print("AUDIT_FIXTURE completed=", level.sector_complete, " text=", level.status.text)
	var hp_before: int = level.bee.health.current_health
	var shot = load("res://scenes/bee_prototype/alien_enemy_projectile.tscn").instantiate()
	level.add_child(shot)
	shot.global_position = level.bee.global_position + Vector3(1.5, 0, 0)
	shot.launch(Vector3.LEFT, level)
	for i in 90:
		await physics_frame
		if level.bee.health.current_health < hp_before:
			break
	print("AUDIT_POST_COMPLETE_PROJECTILE hp_before=", hp_before, " hp_after=", level.bee.health.current_health, " complete=", level.sector_complete)
	level.bee.health.take_damage(9999)
	print("AUDIT_POST_COMPLETE_DEFEAT defeated=", level.bee.is_defeated, " complete=", level.sector_complete, " text=", level.status.text)
	var accepted: bool = level.get_node("Pollen/PollenA").collect(level.bee)
	print("AUDIT_DEAD_POLLEN accepted=", accepted, " hp=", level.bee.health.current_health, " defeated=", level.bee.is_defeated, " pollen=", level.pollen_count)
	quit(0)
