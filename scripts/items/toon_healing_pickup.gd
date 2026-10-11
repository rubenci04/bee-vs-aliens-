extends BeePollenPickup
## Inherits the existing healing/collection signal and feedback, without consuming at full HP.
func collect(body: Node) -> bool:
	var health := body.get_node_or_null("HealthComponent") as HealthComponent
	if health==null or heal_amount<=0 or health.current_health>=health.max_health:
		return false
	return super.collect(body)
