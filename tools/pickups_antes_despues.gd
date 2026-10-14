extends SceneTree
const MED := preload("res://scripts/items/bee_pickup_medallion.gd")
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const OLD := preload("res://scenes/bee_prototype/bee_powerup_pickup.tscn")
const SOURCES := [
	["Spread nuevo", "res://scenes/items/toon/spread.tscn", 0, false],
	["Bomba nueva", "res://scenes/items/toon/bomb.tscn", 1, false],
	["Polen suelto", "res://scenes/items/toon/pollen.tscn", 0, false],
	["Racimo ×10", "res://scenes/items/toon/pollen_cluster.tscn", 0, false],
	["Spread dinámico", "res://scenes/bee_prototype/bee_powerup_pickup.tscn", 0, false],
	["Bomba dinámica", "res://scenes/bee_prototype/bee_powerup_pickup.tscn", 1, false],
	["Spread S+ viejo", "res://scenes/bee_prototype/bee_powerup_pickup.tscn", 0, true],
	["Spread S+ nuevo", "res://scenes/items/toon/spread.tscn", 0, true],
]
const CELL := Vector2i(190, 180)
const ROW := Vector2i(1520, 260)
var stage: BeeShmupStage
var samples := [[], []]
var heading: Label

func _initialize() -> void:
	call_deferred("run")

func layers(node: Node, mask: int) -> void:
	if node is MeshInstance3D or node is Label3D:
		node.layers = mask
	for child in node.get_children(): layers(child, mask)

func text(parent: Node, value: String, at: Vector2, size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label

func run() -> void:
	root.size = ROW
	stage = LEVEL.instantiate()
	root.add_child(stage)
	current_scene = stage
	stage.process_mode = Node.PROCESS_MODE_DISABLED
	stage.camera.clear_current()
	node_added.disconnect(stage._on_node_added_lote9)
	for child in stage.get_children():
		if child is CanvasLayer: child.hide()
		elif child is Node3D and child.name not in ["Scenery", "VisualTarget01", "Sun", "Ground", "GroundExtension", "AssetDressing", "DomesticGarden", "LiveGarden"]: child.hide()
	for layer in stage.find_children("*", "CanvasLayer", true, false): layer.hide()
	var canvas := CanvasLayer.new()
	root.add_child(canvas)
	var backdrop := ColorRect.new()
	backdrop.size = Vector2(ROW)
	backdrop.color = Color("101722")
	canvas.add_child(backdrop)
	heading = text(backdrop, "", Vector2(12, 8), 22)
	for i in SOURCES.size():
		text(backdrop, SOURCES[i][0], Vector2(i * CELL.x + 8, 48), 17)
		var viewport := SubViewport.new()
		viewport.size = CELL
		viewport.world_3d = root.world_3d
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var camera := Camera3D.new()
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 2.8
		camera.position = Vector3(80, 3.8, 17)
		camera.cull_mask = 1 | (1 << (20 + i))
		viewport.add_child(camera)
		camera.current = true
		var picture := TextureRect.new()
		picture.texture = viewport.get_texture()
		picture.position = Vector2(i * CELL.x, 75)
		picture.size = Vector2(CELL)
		backdrop.add_child(picture)
		for after in 2:
			var item := (load(SOURCES[i][1]) as PackedScene).instantiate() as Node3D
			if item is BeePowerupPickup:
				item.kind = SOURCES[i][2]
				item.overcharge = SOURCES[i][3]
			root.add_child(item)
			item.global_position = Vector3(80, 3.8, 0)
			if item is Area3D: item.set_deferred("monitoring", false)
			if after == 1 and item is BeePowerupPickup: MED.dress_old(item)
			BeeItemBeacon.attach(item)
			item.process_mode = Node.PROCESS_MODE_DISABLED
			layers(item, 1 << (20 + i))
			samples[after].append(item)
	var result := Image.create(ROW.x, ROW.y * 4, false, Image.FORMAT_RGBA8)
	for row in 4:
		var dark := row >= 2
		var after := row % 2
		stage.get_node("LightProgression").apply_distance(310.0 if dark else 80.0)
		heading.text = "%s · %s · pickups reales; solo los dinámicos antiguos cambian" % ["DESPUÉS" if after == 1 else "ANTES", "NOCHE" if dark else "DÍA"]
		for group in 2:
			for item in samples[group]: item.visible = group == after
		for frame in 5: await process_frame
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		picture.convert(Image.FORMAT_RGBA8)
		result.blit_rect(picture, Rect2i(Vector2i.ZERO, ROW), Vector2i(0, row * ROW.y))
	assert(result.save_png("res://docs/pickups_antes_despues.png") == OK)
	print("PICKUPS_COMPARACION_OK")
	quit()
