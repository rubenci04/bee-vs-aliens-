extends "res://tests/art/validate_future_biomes_v09.gd"
func run() -> void:
	var ids := ["controlled_dragonfly","controlled_bomb_moth","controlled_mushroom_cannon","moth_stationary_bomb"]
	for id in ids:
		var visual := await verify_model(id,"v10")
		if visual == null:
			continue
		match id:
			"controlled_dragonfly", "controlled_bomb_moth":
				check(visual.find_children("FlightWing_*","Node3D",true,false).filter(func(n): return not n is MeshInstance3D).size()==4,"Expected four wings: "+id)
				check(visual.find_children("Leg_*","Node3D",true,false).filter(func(n): return not n is MeshInstance3D).size()==6,"Expected six legs: "+id)
				if id == "controlled_bomb_moth":
					check(visual.find_child("BombDropAnchor",true,false)!=null,"Drop anchor missing")
					check(visual.find_child("AlienControlDevice",true,false).find_child("BombRack",true,false)!=null,"Bomb rack must be removable")
			"controlled_mushroom_cannon":
				check(visual.find_child("NaturalCap",true,false)!=null,"Natural mushroom cap missing")
				check(visual.find_child("MuzzleAnchor",true,false)!=null,"Muzzle anchor missing")
				check(visual.find_child("AlienControlDevice",true,false).find_child("CannonAssembly",true,false)!=null,"Cannon must be removable")
		visual.queue_free()
		await settle()
	var lab = load("res://scenes/art_labs/future_biomes_v10.tscn").instantiate()
	root.add_child(lab)
	lab.animating = false
	await settle()
	var initial: Vector3 = lab.moving_actor.position
	lab.advance_demo(.25)
	check(lab.moving_actor.position.distance_to(initial)>.2,"Dragonfly does not travel")
	check(absf(lab.moving_actor.position.y-initial.y)>.1,"Dragonfly does not undulate")
	lab.show_page(1)
	await settle()
	var mine: Node3D = lab.mines[0]
	var position := mine.global_position
	lab.advance_demo(.50)
	check(mine.global_position.is_equal_approx(position),"Mine follows moving moth")
	lab.advance_demo(1.0)
	check(lab.mines.size()==4,"Moth did not release a mine")
	await settle()
	lab.toggle_control()
	var count: int = lab.mines.size()
	lab.advance_demo(1.5)
	check(lab.mines.size()==count,"Liberated moth still drops mines")
	lab.toggle_control()
	lab.advance_demo(6.0)
	check(lab.mines.size()<=1,"Old mines did not expire")
	await settle()
	for i in 4:
		lab.show_page(i)
		check(lab.stage.get_child_count()>0,"Empty gallery page")
		await settle()
	for id in ids:
		lab.inspect_asset(id,true)
		check(lab.inspected_id==id and lab.angled,"Asset selection mismatch")
		await settle()
		lab.show_single(id,true)
		check(not lab.ui.visible and lab.stage.get_child_count()==1,"Unclean concept sheet")
		await settle()
	lab.queue_free()
	await settle()
	print("FUTURE_BIOMES_V10_VALIDATION: "+str(failures.size())+" failures")
	quit(0 if failures.is_empty() else 1)
