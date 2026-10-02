extends SceneTree

# POLISH-02 props contract: solid rocks rest on the ground and still fill their (unchanged)
# colliders; crates became garden litter with the same HP/hitbox; both use the toon style.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

## World-space bounds of every MeshInstance3D under node.
func bounds_of(node: Node) -> AABB:
	var result := AABB()
	var first := true
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		var box := mesh.global_transform * mesh.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result

func run() -> void:
	create_timer(60.0, true, false, true).timeout.connect(func(): quit(1))
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 3:
		await process_frame
	var scenery := stage.get_node("Scenery")

	# Rocks: every one rests on the ground; solid ones keep their collider and are filled by the mesh.
	var solid := 0
	var backdrop := 0
	for child in scenery.get_children():
		var label := str(child.name)
		if child is StaticBody3D and label.begins_with("FlightRock"):
			solid += 1
			var collider := child.get_node("CollisionShape3D") as CollisionShape3D
			var box := (collider.shape as BoxShape3D).size
			var rock := child.get_node(label + "Mesh") as MeshInstance3D
			var rock_bounds := rock.global_transform * rock.get_aabb()
			var collider_bottom := collider.global_position.y - box.y * 0.5
			var collider_top := collider.global_position.y + box.y * 0.5
			check(child.collision_layer == 1 and child.collision_mask == 0, "Rock layers changed: " + label)
			check(rock_bounds.position.y <= 0.0, "Rock floats above the ground: %s (base y=%.2f)" % [label, rock_bounds.position.y])
			check(rock_bounds.position.y >= -0.2, "Rock sunk too deep: " + label)
			check(rock_bounds.end.y >= collider_top - 0.2, "Rock mesh does not reach its collider top: " + label)
			check(rock_bounds.size.x >= box.x * 0.85 and rock_bounds.size.z >= box.z * 0.8, "Rock mesh smaller than its collider: " + label)
			check(collider_bottom <= 0.25, "Rock collider floats: " + label)
			check(rock.mesh.surface_get_material(0) != null and rock.get_surface_override_material(0) is ShaderMaterial, "Rock without toon: " + label)
		elif label.begins_with("BackdropRock") and child is MeshInstance3D:
			backdrop += 1
			var box_b := (child as MeshInstance3D).global_transform * (child as MeshInstance3D).get_aabb()
			check(box_b.position.y <= 0.0 and box_b.position.y >= -0.2, "Backdrop rock floats: " + label)
	check(solid == 8 and backdrop == 10, "Rock count changed (%d solid, %d backdrop)" % [solid, backdrop])

	# Crates: litter instead of wood, same HP and hitbox, three distinct kinds.
	var kinds := {}
	var crates := 0
	for crate: DestructibleObstacle3D in stage.get_node("Destructibles").get_children():
		crates += 1
		kinds[crate.item_kind] = true
		var shape := crate.collider.shape as BoxShape3D
		check(shape.size.is_equal_approx(Vector3(1.5, 2.5, 1.2)) and crate.collider.position.is_equal_approx(Vector3(0, 1.25, 0)), "Crate collider changed: " + str(crate.name))
		check((crate.hurtbox.get_node("CollisionShape3D") as CollisionShape3D).shape == shape, "Crate hurtbox changed: " + str(crate.name))
		check(crate.health.max_health == 24, "Crate HP changed: " + str(crate.name))
		var parts: Array = crate.visual_root.find_children("*", "MeshInstance3D", true, false)
		check(parts.size() >= 3, "Crate has no litter visual: " + str(crate.name))
		var box_c := bounds_of(crate.visual_root)
		var half_x := 0.78 * absf(crate.scale.x) + 0.1
		check(box_c.position.y >= -0.1 and box_c.position.y <= 0.2, "Litter does not rest on the ground: " + str(crate.name))
		check(box_c.end.y <= 2.6 * crate.scale.y and box_c.end.y >= 2.0 * crate.scale.y, "Litter height does not match the collider: %s (%.2f)" % [crate.name, box_c.end.y])
		check(absf(box_c.position.x - crate.global_position.x) <= half_x and absf(box_c.end.x - crate.global_position.x) <= half_x, "Litter wider than the collider: " + str(crate.name))
		for mesh: MeshInstance3D in parts:
			var material := mesh.get_surface_override_material(0)
			check(material is ShaderMaterial, "Litter without toon style: " + str(mesh.name))
			var source := mesh.mesh.surface_get_material(0) as StandardMaterial3D
			check(source != null and source.albedo_texture == null, "Litter must be flat colour: " + str(mesh.name))
			var c := source.albedo_color
			check(not (c.h > 0.42 and c.h < 0.56 and c.s > 0.35), "Cyan is reserved for alien tech: " + str(mesh.name))
	check(crates == 8 and kinds.size() == 3, "Expected 8 crates in 3 kinds (%d, %d)" % [crates, kinds.size()])
	# Destroying one still hides it and frees its collider.
	var victim: DestructibleObstacle3D = stage.get_node("Destructibles/GardenCrate")
	victim.health.take_damage(24)
	await process_frame
	check(victim.is_destroyed and not victim.visual_root.visible, "Destroyed litter stays visible")
	print("POLISH_PROPS_OK rocks=", solid + backdrop, " crates=", crates, " kinds=", kinds.size())
	quit(0)
