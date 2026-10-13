extends SceneTree

# LOTE 7 — FREE AIM. Bee fires in any direction of the X/Y plane with the mouse (or set_aim_point), left click fires,
# and without aiming input the usual auto-aim is back. Checks:
	#   8 directions   a shot every 45 deg flies through its aim point from the model muzzle
#   mouse          a mouse motion puts the aim under the cursor (flight plane z = 0); a left click fires there
#   auto-aim       without aiming input (or after AIM_HOLD_SECONDS) shots lock onto the enemy as before
#   HUD            crosshair only while aiming; the controls hint mentions click + mouse
# With a rendering window it saves res://dev/visual_target/lote7_crosshair.png.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const OUT := "res://dev/visual_target/"

var stage: BeeShmupStage
var wave: BeeLevel01Controller
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

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "lote7_" + label + ".png"))

func run() -> void:
	create_timer(300.0, true, false, true).timeout.connect(func(): quit(1))
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(5)
	stage = current_scene as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	stage.scroll_speed = 0.0
	stage.distance = 60.0
	stage._update_camera_and_bounds()
	wave.set_physics_process(false)
	bee.health.damage_blocked = true
	bee.global_position = Vector3(stage.camera.global_position.x - 1.0, 3.6, 0)
	await frames(2)
	var bee_visual := bee.get_node("VisualRoot/BeeVisual") as Node3D

	# --- 8 directions ---
	var directions := 0
	for i in 8:
		var angle := deg_to_rad(45.0 * i)
		var wanted := Vector3(cos(angle), sin(angle), 0.0)
		var target_point := bee.global_position + wanted * 4.0
		bee.set_aim_point(target_point)
		var shot := bee.fire()
		check(shot != null, "No shot at %d deg" % (45 * i))
		var muzzle_to_target := (target_point - shot.global_position).normalized()
		check(rad_to_deg(shot.travel_direction.angle_to(muzzle_to_target)) < 1.0, "Shot at %d deg misses its aim point from muzzle: %s" % [45 * i, shot.travel_direction])
		check(shot.global_position.distance_to(bee_visual.call("firing_origin", bee.global_position)) < 0.001, "Shot at %d deg did not start at the model muzzle" % (45 * i))
		directions += 1
	check(directions >= 8, "Fewer than 8 directions")

	# --- mouse ---
	var camera := stage.camera
	var target := bee.global_position + Vector3(-2.5, 1.5, 0.0) # Up-left: behind Bee, impossible for the old auto-aim.
	var motion := InputEventMouseMotion.new()
	motion.position = camera.unproject_position(target)
	bee._unhandled_input(motion)
	check(bee.is_free_aiming() and bee.aim_point.distance_to(target) < 0.15, "Mouse aim must land under the cursor (%s vs %s)" % [bee.aim_point, target])
	var before := bee.shots_fired
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = motion.position
	bee._unhandled_input(click)
	check(bee.shots_fired == before + 1, "Left click must fire")
	await frames(1)
	var crosshair := stage.get_node("CanvasLayer/Crosshair") as BeeLevel01Crosshair
	await process_frame
	check(crosshair != null and crosshair.visible, "Crosshair must show while aiming")
	check(crosshair.aim_screen_point().distance_to(motion.position) < 2.0, "Crosshair must sit on the aim point")
	await capture("crosshair")
	check(bee.facing_x < 0.0, "Bee must turn to where it aims (left)")

	# --- back to auto-aim ---
	await frames(int(BeePlayer.AIM_HOLD_SECONDS * 60.0) + 10)
	await process_frame
	check(not bee.is_free_aiming() and not crosshair.visible, "Without aiming input the crosshair goes and auto-aim is back")
	bee.global_position = Vector3(stage.camera.global_position.x - 2.0, 3.6, 0)
	bee.facing_x = 1.0
	wave._spawn({"family": "Wasp", "slot": 0, "event": 0, "hard": false, "y": 4.6})
	var wasp := wave.active_units.back() as Node3D
	wasp.set_physics_process(false)
	wasp.global_position = Vector3(stage.camera.global_position.x + 2.0, 4.6, 0)
	await frames(2)
	bee.refresh_auto_aim()
	check(bee.current_auto_target == wasp, "Auto-aim must still lock the Wasp")
	var auto_shot := bee.fire()
	var hurt := wasp.get_node("Hurtbox3D") as Node3D
	var expected: Vector3 = (hurt.global_position - bee_visual.call("firing_origin", bee.global_position)).normalized()
	check(rad_to_deg(auto_shot.travel_direction.angle_to(Vector3(expected.x, expected.y, 0).normalized())) < 1.5, "Auto-aim shot must fly at the Wasp")

	# --- HUD ---
	var controls := str(stage.get_node("CanvasLayer/WeaponsHUD").call("control_text"))
	check("CLIC" in controls, "HUD controls must mention click: " + controls)
	print("FREE_AIM directions=%d mouse=OK click=OK crosshair=OK auto_aim=OK controls='%s'" % [directions, controls])
	print("BEE_FREE_AIM_V01_OK")
	quit(0)
