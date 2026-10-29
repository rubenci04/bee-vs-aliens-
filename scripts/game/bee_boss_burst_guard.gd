extends RefCounted
## Presupuesto de daño recibido de la tarántula y sus ayudantes en una ventana móvil.

var _hits: Array[Vector2] = []

static func is_tarantula_source(source: Node) -> bool:
	if not is_instance_valid(source):
		return false
	return (source.get_script() != null and source.get_script().resource_path == "res://scripts/levels/tarantula_boss_01.gd") or str(source.get_meta("boss_helper", "")) in ["Spider", "Wasp"]

func allowed(amount: int) -> int:
	if not BeeGameSettings.BOSS_BURST_CAP_ENABLED or amount <= 0:
		return amount
	var now := float(Engine.get_physics_frames()) / float(Engine.physics_ticks_per_second)
	while not _hits.is_empty() and now - _hits[0].x >= BeeGameSettings.BOSS_BURST_WINDOW_SECONDS:
		_hits.pop_front()
	var spent := 0
	for hit in _hits:
		spent += int(hit.y)
	return mini(amount, maxi(0, BeeGameSettings.BOSS_BURST_CAP_DAMAGE - spent))

func record(applied: int) -> void:
	if BeeGameSettings.BOSS_BURST_CAP_ENABLED and applied > 0:
		_hits.append(Vector2(float(Engine.get_physics_frames()) / float(Engine.physics_ticks_per_second), applied))
