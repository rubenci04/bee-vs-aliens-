extends "res://tests/art/validate_future_biomes_v09.gd"
var world: Node3D
func target(team: StringName) -> Node3D:
	var entity := Node3D.new()
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	entity.add_child(health)
	var hurtbox = load("res://scenes/components/hurtbox_3d.tscn").instantiate() as DamageHurtbox3D
	hurtbox.team_id = team
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = .35
	shape.shape = sphere
	hurtbox.add_child(shape)
	entity.add_child(hurtbox)
	world.add_child(entity)
	return entity
func physics_frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame
func verify_shot(alien: bool, friendly: bool) -> void:
	var team := &"alien" if alien else &"bee"
	var entity := target(team if friendly else (&"bee" if alien else &"alien"))
	var health := entity.get_node("HealthComponent") as HealthComponent
	var shot = load("res://scenes/projectiles/toon/"+("alien" if alien else "bee")+"_bolt.tscn").instantiate()
	shot.speed = 6
	shot.lifetime = .6
	world.add_child(shot)
	shot.position = Vector3(1.2 if alien else -1.2,0,0)
	shot.launch(Vector3(-1 if alien else 1,0,2),world)
	await settle()
	check(shot.travel_direction.z==0,"Shot escaped the XY gameplay plane")
	var nose: Vector3 = -shot.get_node("Visual").transform.basis.x.normalized()
	check(nose.dot(shot.travel_direction)>.999,"Bolt silhouette points against its trajectory")
	var trail := shot.get_node("ShortTrail") as CPUParticles3D
	var source := trail.mesh.surface_get_material(0) as StandardMaterial3D
	check(source.emission_enabled==alien,"Trail emission belongs to wrong allegiance")
	check(source.albedo_color.h>.42 if alien else source.albedo_color.h<.2,"Trail palette mismatch")
	var count := 0
	for mesh: MeshInstance3D in shot.get_node("Visual").find_children("*","MeshInstance3D",true,false):
		for s in mesh.mesh.get_surface_count():
			count += mesh.mesh.surface_get_array_index_len(s)/3
	check(count==864,"Bolt GLB triangle count changed")
	var hit_events: Array[int] = []
	shot.hitbox.hit_confirmed.connect(func(_hurtbox: DamageHurtbox3D, damage: int): hit_events.append(damage))
	for i in 60:
		await physics_frames(1)
		if not is_instance_valid(shot):
			break
	check(not is_instance_valid(shot),"Hit/lifetime did not clean up projectile")
	var damage := 8 if alien else 10
	check(health.current_health==(100 if friendly else 100-damage),"Team filtering or damage failed")
	check(hit_events.is_empty() if friendly else hit_events==[damage],"Projectile damaged twice or skipped hit signal")
	entity.queue_free()
	await settle()
func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	for alien in [false,true]:
		await verify_shot(alien,false)
		await verify_shot(alien,true)
		for size in ["impact","explosion"]:
			var effect = load("res://scenes/vfx/toon/"+("alien" if alien else "bee")+"_"+size+".tscn").instantiate() as BeeToonBurstVisual
			effect.autoplay = false
			world.add_child(effect)
			await settle()
			for mesh: MeshInstance3D in effect.find_children("*","MeshInstance3D",true,false):
				var material := mesh.get_surface_override_material(0) as ShaderMaterial
				check(is_equal_approx(float(material.get_shader_parameter("emission_energy")),.65 if alien else 0.0),"Impact/explosion energy mismatch")
			var events: Array[int] = []
			effect.finished.connect(func(): events.append(1))
			effect.play()
			effect._process(effect.duration+.001)
			await settle()
			check(events==[1] and not is_instance_valid(effect),"Effect finalization/cleanup failed")
	world.queue_free()
	await settle()
	print("TOON_PROJECTILES_VALIDATION: ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
