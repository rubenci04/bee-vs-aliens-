extends SceneTree
## DEV (noche 01): captures the game title screen and checks the menu (res://dev/visual_target/noche_title*.png).
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1152, 648)
	var title := (load("res://scenes/game/bee_title_screen.tscn") as PackedScene).instantiate()
	root.add_child(title)
	current_scene = title
	for i in 20:
		await process_frame
	var names := []
	for b: Button in title.find_children("*", "Button", true, false):
		names.append(b.text)
	print("TITLE_BUTTONS ", names)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://dev/visual_target/noche_title.png"))
	quit()
