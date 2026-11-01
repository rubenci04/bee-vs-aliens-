extends RefCounted
## Tanda U — un solo lugar donde el juego avisa "pasó algo" a la cara de Bee (bee_visual) y a sus frases (bee_barks).
## Si no hay nivel, visual o frases (tests sueltos, otros niveles) no hace nada.

static func liberated(tree: SceneTree) -> void:
	if tree == null: return
	for visual in tree.get_nodes_in_group("bee_visual_instances"):
		if visual.has_method("feel_happy"): visual.call("feel_happy")
	_say(tree, "first_liberation", true)
	for swarm in tree.get_nodes_in_group("bee_free_swarm"): # Tanda V: cada liberado carga el Enjambre libre.
		swarm.call("add_charge", 1)


static func zone_clear(tree: SceneTree) -> void:
	if tree == null: return
	for visual in tree.get_nodes_in_group("bee_visual_instances"):
		if visual.has_method("celebrate"): visual.call("celebrate")
	_say(tree, "zone_clear")


static func boss(tree: SceneTree, moment: String) -> void:
	if preload("res://scripts/game/bee_story_settings.gd").STORY_BEATS_ENABLED:
		return # Tanda W: la escena corta del jefe ya trae su frase.
	_say(tree, moment, true)


static func _say(tree: SceneTree, moment: String, once := false) -> void:
	if tree == null: return
	for barks in tree.get_nodes_in_group("bee_barks"):
		barks.call("say", moment, once)
