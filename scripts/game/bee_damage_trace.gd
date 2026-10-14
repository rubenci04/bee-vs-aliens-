extends RefCounted
const SETTINGS := preload("res://scripts/game/bee_readability_settings.gd")
const STING := preload("res://scripts/game/bee_sting_settings.gd")
static var records: Array[Dictionary] = []
static func record(bee: Node, hitbox: DamageHitbox3D, amount: int) -> void:
	if not SETTINGS.development_enabled() or amount <= 0: return
	var source := str(hitbox.attacker.name) if is_instance_valid(hitbox.attacker) else "emisor ya liberado"
	var projectile := str(hitbox.get_parent().name)
	var entry := {"source":source,"projectile":projectile,"amount":amount,"seconds":Time.get_ticks_msec()/1000.0,"bee":str(bee.name)}
	records.append(entry)
	if records.size() > STING.DAMAGE_LOG_MAX: records.pop_front()
	print("BEE_DAMAGE ",JSON.stringify(entry))
