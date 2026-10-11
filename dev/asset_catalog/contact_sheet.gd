extends SceneTree
## Contact sheet of dev/asset_catalog/renders/*.png (run WITHOUT --headless): saves dev/asset_catalog/contact_sheet.png
func _init() -> void:
	var dir := DirAccess.open("res://dev/asset_catalog/renders")
	var names: Array[String] = []
	for f in dir.get_files():
		if f.ends_with(".png"):
			names.append(f.get_basename())
	names.sort()
	var cols := 7
	var tile := 280
	var rows := ceili(names.size() / float(cols))
	var vp := SubViewport.new()
	vp.size = Vector2i(cols * tile, rows * (tile + 18))
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color(0.2, 0.2, 0.22)
	bg.size = Vector2(vp.size)
	vp.add_child(bg)
	for i in names.size():
		var img := Image.load_from_file(ProjectSettings.globalize_path("res://dev/asset_catalog/renders/%s.png" % names[i]))
		var rect := TextureRect.new()
		rect.texture = ImageTexture.create_from_image(img)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.size = Vector2(tile - 4, tile - 4)
		rect.position = Vector2((i % cols) * tile + 2, (i / cols) * (tile + 18) + 2)
		vp.add_child(rect)
		var label := Label.new()
		label.text = names[i]
		label.add_theme_font_size_override("font_size", 13)
		label.position = rect.position + Vector2(2, tile - 2)
		vp.add_child(label)
	for _i in 4:
		await process_frame
	vp.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://dev/asset_catalog/contact_sheet.png"))
	print("CONTACT_SHEET_OK ", names.size())
	quit()
