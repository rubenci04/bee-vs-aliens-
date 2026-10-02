extends SceneTree
const LAB := preload("res://dev/alien_air_review/alien_air_review_lab.tscn")
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	var scene := LAB.instantiate()
	root.add_child(scene)
	current_scene = scene
	for i in 20: await process_frame
	var image := root.get_viewport().get_texture().get_image()
	var error := image.save_png("res://dev/alien_air_review/alien_air_review.png")
	print("ALIEN_AIR_LAB_CAPTURE ",error," size=",image.get_size())
	quit(0 if error == OK else 1)
