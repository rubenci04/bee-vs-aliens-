extends BeePowerupPickup
## Reuses weapon collection rules; overcharge halo stays in the warm Bee palette.
const WARM_BURST := preload("res://scenes/vfx/bee_toon_burst.tscn")
func collect(body: Node3D) -> bool:
	var bee := body as BeePlayer
	if was_collected or bee==null or bee.is_defeated:
		return false
	var accepted := (bee.collect_spread_overcharge() if overcharge else bee.collect_spread()) if kind==Kind.SPREAD else bee.collect_bomb()
	if not accepted:
		return false
	was_collected = true
	BeeAudio.play(get_parent(),&"spread_pickup" if kind==Kind.SPREAD else &"bomb_pickup",global_position)
	var burst := WARM_BURST.instantiate() as Node3D
	get_parent().add_child(burst)
	burst.global_position = global_position
	burst.scale = Vector3.ONE*.35
	hide()
	set_deferred("monitoring",false)
	queue_free()
	return true
func _add_halo() -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = .50
	mesh.outer_radius = .55
	mesh.rings = 24
	mesh.ring_segments = 6
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("efbb46")
	material.roughness = .95
	mesh.material = material
	var halo := MeshInstance3D.new()
	halo.name = "Halo"
	halo.mesh = mesh
	halo.rotation.x = PI/2
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(halo)
	BeeToonStyle.apply(halo,true,BeeToonStyle.OUTLINE_PROP)
