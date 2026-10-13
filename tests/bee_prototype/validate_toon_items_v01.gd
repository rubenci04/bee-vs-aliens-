extends "res://tests/art/validate_future_biomes_v09.gd"
var bee: BeePlayer
var world: Node3D
func item(id: String) -> Area3D:
	var pickup = load("res://scenes/items/toon/"+id+".tscn").instantiate()
	world.add_child(pickup)
	return pickup
func physics_settle() -> void:
	for i in 4:
		await physics_frame
		await process_frame
func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	bee = load("res://scenes/bee_prototype/bee_player.tscn").instantiate()
	world.add_child(bee)
	bee.set_physics_process(false)
	bee.position = Vector3(100,100,0)
	await settle()
	var stranger := Node3D.new()
	root.add_child(stranger)
	var spread := item("spread") as BeePowerupPickup
	await settle()
	check(not spread.collect(stranger),"Non-Bee can consume Spread")
	bee.is_defeated = true
	check(not spread.collect(bee),"Defeated Bee can consume Spread")
	bee.is_defeated = false
	check(spread.collect(bee) and is_equal_approx(bee.spread_ammo, BeeGameSettings.SPREAD_DURATION_SEC),"Spread didn't refill existing weapon")
	check(not spread.collect(bee),"Spread consumed twice")
	for effect in world.get_children():
		if effect.get_script()==preload("res://scripts/art/toon_burst_visual.gd"):
			check(not effect.alien,"Bee pickup spawned alien-coloured feedback")
			for mesh: MeshInstance3D in effect.find_children("*","MeshInstance3D",true,false):
				var material := mesh.get_surface_override_material(0) as ShaderMaterial
				check(float(material.get_shader_parameter("emission_energy"))==0,"Bee pickup effect must remain warm and non-emissive")
	await settle()
	var bomb := item("bomb") as BeePowerupPickup
	await settle()
	bee.bomb_charges = bee.max_bomb_charges
	check(not bomb.collect(bee) and not bomb.was_collected,"Full bomb capacity consumed pickup")
	bee.bomb_charges -= 1
	check(bomb.collect(bee) and bee.bomb_charges==bee.max_bomb_charges,"Bomb didn't add exactly one charge")
	await settle()
	var healing := item("healing") as BeePollenPickup
	await settle()
	check(not healing.collect(bee) and not healing.was_collected,"Full HP consumed healing")
	bee.health.take_damage(15)
	bee.is_defeated = true
	check(not healing.collect(bee),"Healing revived defeated Bee")
	bee.is_defeated = false
	var healing_events: Array[int] = []
	healing.collected.connect(func(_pickup: BeePollenPickup, restored: int): healing_events.append(restored))
	check(healing.collect(bee),"Healing rejected wounded Bee")
	check(bee.health.current_health==bee.health.max_health and healing_events==[15],"Healing must clamp and report restored HP")
	await settle()
	bee.health.take_damage(40)
	var pollen := item("pollen") as BeePollenPickup
	await settle()
	var pollen_events: Array[int] = []
	pollen.collected.connect(func(_pickup: BeePollenPickup, restored: int): pollen_events.append(restored))
	bee.position = pollen.position
	await physics_settle()
	check(not is_instance_valid(pollen),"Physical trigger didn't collect pollen")
	check(bee.health.current_health==80 and pollen_events==[20],"Pollen healing/signal contract changed")
	bee.position = Vector3(100,100,0)
	var charged := load("res://scenes/items/toon/spread.tscn").instantiate() as BeePowerupPickup
	charged.overcharge = true
	world.add_child(charged)
	await settle()
	var halo := charged.get_node("Halo") as MeshInstance3D
	var material := halo.get_surface_override_material(0) as ShaderMaterial
	var energy: Variant = material.get_shader_parameter("emission_energy")
	check(energy==null or float(energy)==0,"Bee overcharge halo must not use alien glow")
	var spread_before := bee.spread_ammo
	check(charged.collect(bee) and is_equal_approx(bee.spread_ammo, minf(BeeGameSettings.SPREAD_MAX_DURATION_SEC, spread_before + BeeGameSettings.SPREAD_EXTEND_SEC)),"Spread capsule must extend duration")
	await settle()
	stranger.queue_free()
	bee.queue_free()
	await settle()
	world.queue_free()
	await settle()
	print("TOON_ITEMS_VALIDATION: ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
