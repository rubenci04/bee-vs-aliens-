extends SceneTree
const M := preload("res://scripts/items/bee_pollen_magnet.gd")
var failed := false
func _initialize(): call_deferred("run")
func check(ok: bool, text: String):
	if not ok: failed=true; push_error(text)
func frames(n: int):
	for i in n: await physics_frame
func run():
	var stage=preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
	root.add_child(stage)
	current_scene=stage
	await frames(5)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.get_node("Juice").set_physics_process(false)
	stage.distance=110
	stage._update_camera_and_bounds()
	var bee=stage.bee
	bee.set_physics_process(false)
	bee.global_position=Vector3(110,3,0)
	var juice=stage.get_node("Juice")
	var combo=juice.combo
	var best=juice.best_combo
	for authored in stage.get_node("Pollen").get_children():
		check(authored.heal_amount == 0 and authored.pollen_value == 1,"Authored Level 1 pollen still fills the bar without direct healing")
	var pollen=preload("res://scenes/items/toon/pollen.tscn").instantiate()
	stage.add_child(pollen)
	pollen.global_position=bee.global_position+Vector3(1.1,0,0)
	await frames(3)
	check(is_equal_approx(M.radius(pollen),1.2) and pollen.get_node("CollisionShape3D").shape.radius < .481,"Existing collection radius; attraction 2.5 times")
	check(pollen.pollen_value == 1 and pollen.heal_amount == 20,"Reusable pickup value/direct healing unchanged")
	check(pollen.has_node("PollenGrains") and not pollen.get_node("Visual").visible,"Three grains replace drawing while original is retained")
	check(pollen.get_node("PollenGrains/Grain0").mesh is SphereMesh and not pollen.get_node("ItemBeacon").visible,"Round grains, no old beacon")
	var grains := pollen.get_node("PollenGrains")
	check(grains.get_child_count() == 4 and grains.get_node("Grain1").mesh is SphereMesh and grains.get_node("Grain2").mesh is SphereMesh, "Three round grains plus a small sparkle")
	var bounds := AssetFauna._bounds(grains, pollen)
	check(bounds.size.x < 0.85 * 0.41 and bounds.size.y < 0.85 * 0.41, "T3m visual is approximately 40 percent of the former diameter")
	var start=pollen.global_position
	check(M.step(pollen,bee,1.0/60),"Soft attraction starts")
	var first=start.distance_to(pollen.global_position)
	var next=pollen.global_position
	M.step(pollen,bee,1.0/60)
	check(first < .02 and next.distance_to(pollen.global_position)>first,"Speed grows gently instead of snapping")
	pollen.global_position=bee.global_position+Vector3(1.4,0,0)
	check(not M.step(pollen,bee,.016),"Outside ordinary radius stays still")
	bee.is_rolling=true
	check(M.step(pollen,bee,.016),"Nearby roll attracts within 1.5 m")
	bee.is_rolling=false
	var foe=preload("res://scenes/levels/asset_fauna/fly_common.tscn").instantiate()
	stage.add_child(foe)
	foe.activate(bee)
	foe.set_physics_process(false)
	foe.global_position=bee.global_position+Vector3(.55,-.3,0)
	pollen.global_position=bee.global_position+Vector3(1.1,0,0)
	await frames(3)
	check(M.blocked(pollen,bee),"Enemy blocks the path of attraction")
	start=pollen.global_position
	M.step(pollen,bee,.1)
	check(start == pollen.global_position,"Pollen does not pass through enemy")
	foe.queue_free()
	await frames(3)
	juice._register_pickup(pollen)
	var before=juice.pollen_total
	for i in 120:
		if not is_instance_valid(pollen): break
		M.step(pollen,bee,1.0/60)
		await physics_frame
	check(not is_instance_valid(pollen) and juice.pollen_total == before+1,"Collected once, same pollen value")
	check(juice.combo == combo and juice.best_combo == best,"Collection changes no combo data")
	var past=preload("res://scenes/items/toon/pollen.tscn").instantiate()
	stage.add_child(past)
	past.global_position=Vector3(80,3,0)
	M.step(past,bee,.016)
	check(past.is_queued_for_deletion(),"Missed offscreen pollen retires behind the camera")
	var future=preload("res://scenes/items/toon/pollen.tscn").instantiate()
	stage.add_child(future)
	future.global_position=Vector3(140,3,0)
	start=future.global_position
	M.step(future,bee,.016)
	check(not future.is_queued_for_deletion() and future.global_position == start,"Future authored pollen is retained, not pulled from offscreen")
	var saved_bee=bee.global_position
	var half=BeeShmupFairness.visible_half_width(stage.camera,bee.global_position,BeeLevel01Framing.view_aspect(root))
	bee.global_position.x=stage.camera.global_position.x-half+.2
	future.global_position=Vector3(stage.camera.global_position.x-half-.5,3,0)
	start=future.global_position
	check(not M.step(future,bee,.1) and future.global_position == start and not future.is_queued_for_deletion(),"No pull from just outside the screen, even inside attraction range")
	bee.global_position=saved_bee
	var cluster=preload("res://scenes/items/toon/pollen_cluster.tscn").instantiate()
	stage.add_child(cluster)
	check(cluster.pollen_value == 10 and is_equal_approx(M.radius(cluster),1.75),"Cluster value/radius maintained")
	print("T3I_OK failed=",failed)
	quit(1 if failed else 0)
