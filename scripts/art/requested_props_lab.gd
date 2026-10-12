extends "res://scripts/art/asset_catalog_lab.gd"
## Individual small prop catalogs with geometry-centered previews.
func bounds_of(model: Node3D) -> AABB:
	var bounds := AABB()
	var first := true
	for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		var box := mesh.get_aabb()
		for i in 8:
			var point := mesh.global_transform*box.get_endpoint(i)
			if first:
				bounds = AABB(point,Vector3.ZERO)
				first = false
			else:
				bounds = bounds.expand(point)
	return bounds

func centered(id: String, pos: Vector3, factor: float) -> Node3D:
	var model := asset(id,Vector3.ZERO,factor)
	model.position = pos-bounds_of(model).get_center()
	return model

func show_page(_index: int) -> void:
	_clear()
	creature_mode = false
	inspected_id = ""
	camera.size = 10.8
	ui.visible = true
	environment.environment.background_color = Color("777970")
	title.text = catalog_title
	subtitle.text = "Estudio neutro · 1–4: seleccionar · V: lateral / 3⁄4 · H: ficha limpia"
	for i in asset_ids.size():
		var pos := Vector3((i-(asset_ids.size()-1)*0.5)*5.5,0,0)
		if asset_ids.size()==4:
			pos = Vector3(-4 if i%2==0 else 4,1.35 if i<2 else -2.25,0)
		centered(asset_ids[i],pos,factors[i])

func show_single(id: String, liberated := false, three_quarter := false) -> void:
	super.show_single(id,liberated,three_quarter)
	var model := stage.get_child(0) as Node3D
	model.position -= bounds_of(model).get_center()
	var box := bounds_of(model)
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x/maxf(1.0,viewport_size.y)
	camera.size = maxf(2.6,maxf(box.size.y*1.45,box.size.x/aspect*1.5))
