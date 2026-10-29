extends RefCounted
## One cartridge applies every enabled entry. Add another entry and its handler to extend the effect set.
const HEAL_AMOUNT := 25
const SHIELD_SECONDS := 2.5
const POLLEN_DOUBLE_SECONDS := 4.0
const POLLEN_DOUBLE_MAX_SECONDS := 12.0
const POWERS := [
	{"id": &"heal", "amount": HEAL_AMOUNT},
	{"id": &"shield", "seconds": SHIELD_SECONDS},
	{"id": &"double_shot", "seconds": POLLEN_DOUBLE_SECONDS, "max_seconds": POLLEN_DOUBLE_MAX_SECONDS},
]

static func apply(bee: Node, juice: Node) -> int:
	var healed := 0
	for power in POWERS:
		match power.id:
			&"heal":
				var before: int = bee.health.current_health
				bee.health.restore_health(int(power.amount))
				healed += bee.health.current_health - before
			&"shield":
				juice.nova_protection_left = float(power.seconds)
				bee.health.pollen_protected = true
			&"double_shot":
				bee.add_pollen_double(float(power.seconds), float(power.max_seconds))
	return healed
