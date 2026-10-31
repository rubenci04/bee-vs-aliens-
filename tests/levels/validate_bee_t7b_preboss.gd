extends "res://tests/levels/bee_t7b_fixture.gd"
func run() -> void:
	var stage := await fixture()
	var event: Dictionary
	for entry in BeeLevel01Controller.EVENTS_ROSTER:
		if entry.get("moment", "") == "preboss_power": event = entry
	var item := stage.get_node("Powerups/PrebossPower") as Node3D
	check(item.position.x == event.at and event.at == BeeLevel01Controller.PREBOSS_POWER_X, "The pre-boss event and the real pickup share PREBOSS_POWER_X")
	check(item.position.x > 281.0 and item.position.x < 294.0, "Power stays after checkpoint 2 and before Robot")
	check(item.get("overcharge") and item.get("kind") == BeePowerupPickup.Kind.SPREAD, "S+ pickup identity is unchanged")
	done()
