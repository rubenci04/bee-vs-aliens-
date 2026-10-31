extends SceneTree
## Tanda R: a hit whose shooter was freed before impact still damages Bee (no SCRIPT ERROR, no lost hit).
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 4: await physics_frame
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	var bee := stage.bee
	bee.health.damage_blocked = false
	bee.health.invulnerable = false
	var shooter := Node3D.new()
	stage.add_child(shooter)
	var shape := SphereShape3D.new()
	shape.radius = 0.2
	var hitbox := BeeAttackVisuals.hazard_area(stage, shooter, 7, shape)
	hitbox.set_enabled(true)
	shooter.free() # The enemy dies while its shot is still flying.
	var before := bee.health.current_health
	var applied := bee.hurtbox.receive_hit(hitbox)
	check(applied > 0 and bee.health.current_health < before, "A shot from a freed shooter still hurts Bee (%d -> %d)" % [before, bee.health.current_health])
	# A living shooter keeps working the same way.
	var shooter2 := Node3D.new()
	stage.add_child(shooter2)
	var hitbox2 := BeeAttackVisuals.hazard_area(stage, shooter2, 5, shape)
	hitbox2.set_enabled(true)
	var mid := bee.health.current_health
	bee.hurtbox.receive_hit(hitbox2)
	check(bee.health.current_health < mid, "A shot from a living shooter hurts Bee")
	print("TANDA_R failures=", failures, " hp ", before, "->", bee.health.current_health)
	quit(1 if failures else 0)
