extends RefCounted
## Isolate weapon/pattern tests after arrival. The real timed sequence has its own integration test.
static func finish(unit: Node) -> void:
	for effect in unit.get_parent().get_children():
		if effect.get_script() == preload("res://scripts/vfx/bee_enemy_teleport.gd") and effect.passenger == unit:
			effect._physics_process(2.0)
