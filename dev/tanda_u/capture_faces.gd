extends SceneTree
## Tanda U: una captura por cara (con ventana), con la cámara cerca de Bee. Además una a tamaño de juego (contenta).
const S := preload("res://scripts/game/bee_expression_settings.gd")
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://dev/tanda_u/caras/" + name + ".png")
func run() -> void:
	DisplayServer.window_set_size(Vector2i(960, 540))
	var stage = load("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	for i in 8: await process_frame
	stage.wave.set_physics_process(false)
	stage.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.bee.health.damage_blocked = true
	stage.bee.global_position = Vector3(12.0, 3.5, 0.0)
	S.EXPRESSIONS_ENABLED = false # La cara la fija el script, no el juego.
	var visual = stage.bee.get_node("VisualRoot/BeeVisual")
	var camera: Camera3D = stage.camera
	stage.set_process(false)
	for face in [&"neutral", &"focused", &"surprised", &"happy", &"tired"]:
		visual.expressions.set_face_now(face)
		var head: Vector3 = (visual.expressions.parts["Eye_L"]["node"] as Node3D).global_position
		camera.global_position = head + Vector3(1.1, 0.15, 0.9)
		camera.look_at(head)
		camera.fov = 32.0
		await shot(str(face))
	quit(0)
