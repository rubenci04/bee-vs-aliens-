class_name BeeCommonSlots
extends RefCounted
## T6e: shared pool of attack slots for the common enemies of Level 01. At most MAX_ATTACKERS of them commit to an attack
## (warning included) at the same time; the rest keep walking / hovering and try again a moment later.
const MAX_ATTACKERS := 2
const GROUP := &"bee_common_attackers"


## True when `unit` holds a slot (it already had one, or one was free). Defeated / inactive holders do not count.
static func try_take(unit: Node) -> bool:
	if unit.is_in_group(GROUP):
		return true
	var live := 0
	for other in unit.get_tree().get_nodes_in_group(GROUP):
		if other == unit or not is_instance_valid(other):
			continue
		if other.has_method("is_active") and not bool(other.call("is_active")):
			continue
		live += 1
	if live >= MAX_ATTACKERS:
		return false
	unit.add_to_group(GROUP)
	return true


static func release(unit: Node) -> void:
	if is_instance_valid(unit) and unit.is_in_group(GROUP):
		unit.remove_from_group(GROUP)


static func held(unit: Node) -> bool:
	return is_instance_valid(unit) and unit.is_in_group(GROUP)
