extends SceneTree
## DEV ONLY. Side-by-side 3x crop of the style comparison captures (before | after).
func _initialize() -> void:
	var out := Image.create(2 * 3 * 420, 3 * 200, false, Image.FORMAT_RGBA8)
	var x := 0
	for name in ["before", "after"]:
		var image := Image.load_from_file("res://dev/level01_transformation_review/style_compare_%s.png" % name)
		var crop := image.get_region(Rect2i(130, 80, 420, 200))
		crop.resize(3 * 420, 3 * 200, Image.INTERPOLATE_NEAREST)
		out.blit_rect(crop, Rect2i(0, 0, crop.get_width(), crop.get_height()), Vector2i(x, 0))
		x += crop.get_width()
	out.save_png("res://dev/level01_transformation_review/style_compare_zoom.png")
	quit(0)
