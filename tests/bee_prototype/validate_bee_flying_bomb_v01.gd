extends SceneTree
const PLAYER := preload("res://scenes/bee_prototype/bee_player.tscn")
var world: Node3D
var bee: BeePlayer

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	bee = PLAYER.instantiate() as BeePlayer
	world.add_child(bee)
	bee.set_physics_process(false)
	bee.global_position = Vector3(0, 4, 0)
	bee.bomb_charges = 5
	bee.set_aim_point(Vector3(12, 10, 0))
	var hp := bee.health.current_health
	var bomb := bee.use_bomb()
	check(bomb != null and bee.bomb_charges == 4, "Launch consumes one bomb")
	await frames(15)
	check(bomb.global_position.x > 1.0 and bomb.global_position.y > 4.5 and not bomb.discharge_done, "Bomb must fly towards the mouse before exploding")
	var spot := bomb.global_position
	check(bee.use_bomb() == bomb and bee.bomb_charges == 4, "Second C detonates the same bomb without consuming stock")
	check(bomb.get_node("Pulse").scale.is_equal_approx(Vector3.ONE * bee.bomb_radius), "Warning must show the exact blast radius")
	await frames(5)
	check(not bomb.discharge_done and bomb.global_position.is_equal_approx(spot), "Warning must precede stationary discharge")
	await frames(15)
	check(bomb.discharge_done and bee.active_bomb == null and bee.health.current_health == hp, "Remote discharge clears flight state and never damages Bee")
	await frames(30)
	bee.set_aim_point(Vector3(40, 4, 0))
	bomb = bee.use_bomb()
	await frames(74)
	check(bomb.warning_left >= 0.0 and not bomb.discharge_done, "Range end must warn before exploding")
	check(absf(bomb.travelled - BeeAlienBomb.MAX_RANGE) < 0.02 and absf(bomb.global_position.x - 14.0) < 0.02, "Bomb range must be 14 m in about 1.2 s")
	await frames(20)
	check(bee.active_bomb == null, "Range discharge must clear active bomb")
	# Swept collision: a narrow solid must stop the bomb, rather than tunnel through it.
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.1, 2, 2)
	shape.shape = box
	wall.add_child(shape)
	world.add_child(wall)
	wall.position = Vector3(3, 4, 0)
	await frames(2)
	bomb = bee.use_bomb()
	await frames(18)
	check(bomb.warning_left >= 0.0 and bomb.global_position.x < 3.1, "Contact with a solid must stop and trigger the warning")
	await frames(20)
	check(bee.active_bomb == null and bee.bomb_charges == 2, "Only launches consume stock")
	print("BEE_FLYING_BOMB_V01_OK mouse remote range solid warning stock self_damage=0")
	quit(0)
