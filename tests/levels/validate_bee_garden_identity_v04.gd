extends SceneTree
## GARDEN IDENTITY & AUDIO PASS 04 contract (Level 01).
##   garden     DomesticGarden01: 6-10 compositions (>= 4 scale compositions), every act dressed, natural -> human
##              progression (act 1 one isolated human object, act 3 the most), no collision / gameplay nodes
##   readable   every prop behind the flight plane (z <= -3), nothing taller than 0.35 m in |z| < 2.5, foreground
##              accents projected under the playfield (same rules as the Visual Target)
##   style C    profiles: foliage double sided WITHOUT outline, props toon + prop outline, cutout keeps alpha
##   licenses   every model comes from an approved pack with its License.txt and is listed in ASSET_PROVENANCE.md
##   human      sneakers + denim polish: sole / toe-cap shells share the boot skin, the boot keeps its exact vertex
##              positions, the damage parts still sample the same bones
##   audio      new cues mapped to real files, telegraph > impact > ambience in the mix, per-play variation, dusk layer
##   godot --headless --path . --script res://tests/levels/validate_bee_garden_identity_v04.gd

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const HIPSTER := preload("res://assets/models/_unassigned/human/hipster_poc.glb")
const FERN := preload("res://assets/external/approved/nature/quaternius/Stylized Nature MegaKit[Standard]/glTF/Fern_1.gltf")
const HUMAN_OBJECTS := ["pot_A", "pot_C", "pots_stacked", "saucer", "can_yellow", "can_grey", "shovel", "apple", "cup", "wrapper", "stick"]
var failed := false


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok and not failed:
		failed = true
		push_error(message)
		print("GARDEN_V04_FAIL ", message)
		quit(1)


func frames(count: int) -> void:
	for i in count:
		await physics_frame


func world_vertices(node: Node3D) -> PackedVector3Array:
	var points := PackedVector3Array()
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			for v: Vector3 in mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				points.append(mesh.global_transform * v)
	return points


func run() -> void:
	create_timer(240.0, true, false, true).timeout.connect(func(): print("GARDEN_V04_FAIL timeout"); quit(1))
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(4)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	var garden := stage.get_node_or_null("DomesticGarden01") as BeeLevel01DomesticGarden
	check(garden != null, "DomesticGarden01 missing")
	if failed:
		return
	# --- compositions and progression ----------------------------------------------------------------------------
	var ids: Array = garden.compositions.keys()
	check(ids.size() >= 6 and ids.size() <= 10, "Expected 6-10 compositions, got %d" % ids.size())
	var scale_compositions := ids.filter(func(id): return str(id) in ["A1_fallen_pot", "A2_leaf_tunnel", "A2_watering_can", "A3_trowel", "A3_picnic", "A3_pots"])
	check(scale_compositions.size() >= 4, "Expected at least 4 scale compositions")
	var per_act := [0, 0, 0, 0, 0]
	var human_per_act := [0, 0, 0, 0, 0]
	for entry in BeeLevel01DomesticGarden.PLACEMENTS:
		var act := BeeLevel01DomesticGarden.act_at(float(entry[1]))
		per_act[act - 1] += 1
		if str(entry[0]) in HUMAN_OBJECTS:
			human_per_act[act - 1] += 1
	check(not per_act.has(0), "An act has no garden dressing: %s" % str(per_act))
	check(human_per_act[0] == 1 and human_per_act[2] >= 4 and human_per_act[2] > human_per_act[1] and human_per_act[1] >= human_per_act[0], "Natural -> human progression broken: %s" % str(human_per_act))
	check(garden.drips != null and garden.compositions.has("A4_alien_pot") and (garden.compositions["A4_alien_pot"] as Array).size() >= 3, "Animated moment / alien contamination missing")
	check(garden.find_children("*", "CollisionObject3D", true, false).is_empty() and garden.find_children("*", "Area3D", true, false).is_empty(), "Garden props must have no collision / gameplay nodes")
	# --- readability rules -----------------------------------------------------------------------------------------
	for prop in garden.props:
		for p in world_vertices(prop):
			check(p.z <= BeeLevel01DomesticGarden.BEHIND_Z + 0.01, "%s reaches the flight plane (z=%.2f)" % [prop.name, p.z])
			if absf(p.z) < BeeLevel01VisualTarget.MIDGROUND_CLEAR_Z:
				check(p.y <= 0.35, "%s is tall in the midground" % prop.name)
			if failed:
				return
	check(garden.foreground_nodes.size() >= 4, "Foreground accents missing")
	for node in garden.foreground_nodes:
		for p in world_vertices(node):
			check(p.y <= BeeLevel01VisualTarget.foreground_height_limit(p.z) + 0.001, "%s covers the playfield" % node.name)
			if failed:
				return
	# --- Style C profiles ------------------------------------------------------------------------------------------
	var foliage_seen := 0
	var prop_seen := 0
	for node in garden.props + garden.foreground_nodes:
		var key := str(node.name).rsplit("_", true, 1)[0]
		for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
			var material := mesh.get_surface_override_material(0) as ShaderMaterial
			check(material != null, "%s has no Style C material" % node.name)
			if failed:
				return
			if key in BeeLevel01DomesticGarden.FOLIAGE:
				foliage_seen += 1
				check(material.shader == BeeToonStyle.TOON_DOUBLE and material.next_pass == null, "%s: foliage must be double sided without outline" % node.name)
			else:
				prop_seen += 1
				check(material.next_pass != null and is_equal_approx(float((material.next_pass as ShaderMaterial).get_shader_parameter("width")), BeeToonStyle.OUTLINE_PROP), "%s: prop must use the thin prop outline" % node.name)
	check(foliage_seen > 0 and prop_seen > 0, "Profiles not exercised")
	var fern := FERN.instantiate() as Node3D
	root.add_child(fern)
	BeeToonStyle.apply_profile(fern, &"cutout")
	var cut := (fern.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial
	check(cut != null and cut.shader == BeeToonStyle.TOON_CUTOUT and cut.next_pass == null and bool(cut.get_shader_parameter("use_texture")), "Cutout profile must keep the alpha texture, without outline")
	fern.queue_free()
	# --- licenses / provenance --------------------------------------------------------------------------------------
	var provenance := FileAccess.get_file_as_string("res://assets/external/ASSET_PROVENANCE.md")
	for key in BeeLevel01DomesticGarden.MODELS:
		var path: String = BeeLevel01DomesticGarden.MODELS[key]
		var pack := path.get_base_dir()
		while pack != "res://assets/external/approved" and not FileAccess.file_exists(pack + "/License.txt"):
			pack = pack.get_base_dir()
		check(FileAccess.file_exists(pack + "/License.txt"), "No License.txt for " + path)
		check(path.get_file() in provenance, "Not registered in ASSET_PROVENANCE.md: " + path.get_file())
	check(FileAccess.get_file_as_string("res://assets/external/approved/garden/tiny_treats/House Plants 1.0/License.txt").contains("Creative Commons Zero, CC0")
			and FileAccess.get_file_as_string("res://assets/external/approved/nature/kaykit/Forest Nature Pack 1.0/License.txt").contains("Creative Commons Zero, CC0"), "Pack licenses are not CC0")
	# --- human close-up polish -------------------------------------------------------------------------------------
	var human := stage.get_node("GiantHuman")
	var shells: Array = human.get("close_up_meshes")
	check(shells.size() == 4, "Expected sole + toe cap on both sneakers")
	var reference := HIPSTER.instantiate() as Node3D
	root.add_child(reference)
	for side in ["L", "R"]:
		var boot := human.find_child("Boot" + side, true, false) as MeshInstance3D
		var original := reference.find_child("Boot" + side, true, false) as MeshInstance3D
		var a: PackedVector3Array = boot.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var b: PackedVector3Array = original.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var set_a := {}
		for v in a:
			set_a[v.snapped(Vector3.ONE * 0.0001)] = true
		var same := true
		for v in b:
			same = same and set_a.has(v.snapped(Vector3.ONE * 0.0001))
		check(same and boot.get_aabb().is_equal_approx(original.get_aabb()), "Boot%s vertex positions changed" % side)
		for shell: MeshInstance3D in shells:
			if str(shell.name).begins_with("Boot" + side):
				check(shell.skin == boot.skin and shell.skeleton == boot.skeleton and shell.has_meta("close_up_polish"), "Shell does not follow the boot skin")
	reference.free()
	var jean := human.find_child("JeansCalfL", true, false) as MeshInstance3D
	check((jean.get_surface_override_material(0) as ShaderMaterial).shader == GiantHumanCloseUp.FABRIC, "Denim polish missing")
	var parts: Dictionary = human.get("_samples")
	check(parts.has("LeftFoot") and parts.has("RightFoot") and parts.has("Torso") and (parts["LeftFoot"] as Array).size() > 0, "Damage hull samples missing")
	# --- audio -------------------------------------------------------------------------------------------------------
	for cue in [&"organic_death", &"wasp_overload", &"walker_charge", &"organic_charge", &"spider_telegraph", &"spider_drop", &"spider_retract"]:
		check(cue in BeeAudio.REAL_CUES and BeeAudio.stream_for(cue).resource_path == "res://audio/sfx/real/%s.wav" % cue, "Cue not mapped: " + str(cue))
	var telegraphs := [&"wasp_overload", &"walker_charge", &"organic_charge", &"spider_telegraph"]
	for t in telegraphs:
		for impact in [&"tech_death", &"organic_death", &"tech_hit", &"organic_hit"]:
			check(float(BeeAudio.CUES[t][1]) > float(BeeAudio.CUES[impact][1]) and int(BeeAudio.CUES[t][2]) > int(BeeAudio.CUES[impact][2]), "Mix hierarchy: %s must sit over %s" % [t, impact])
	check(float(BeeAudio.CUES[&"bee_damage"][1]) > float(BeeAudio.CUES[&"wasp_overload"][1]), "Player danger must stay over the telegraphs")
	var pitches := {}
	for i in 12:
		var voice := BeeAudio.play(stage, &"tech_death", Vector3.ZERO)
		if voice != null:
			pitches[snappedf(float(voice.get("pitch_scale")), 0.001)] = true
			check(absf(float(voice.get("pitch_scale")) - 1.0) <= 0.051, "Death pitch variation too wide")
	check(pitches.size() >= 3, "Death cue never varies")
	var ambience := stage.get_node("GardenAmbience") as BeeAmbience
	check(ambience.dusk_player != null and ambience.dusk_player.bus == &"Ambience" and (ambience.dusk_player.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "Dusk layer missing")
	stage.distance = 150.0
	ambience._process(0.0)
	check(ambience.dusk_player.volume_db <= -59.0, "Dusk layer must be silent before the sunset")
	stage.distance = 300.0
	ambience._process(0.0)
	check(is_equal_approx(ambience.dusk_player.volume_db, ambience.dusk_target_db) and ambience.dusk_target_db < ambience.target_db, "Dusk layer must reach its target, under the meadow")
	check(ResourceLoader.exists(BeeLevel01AlienEscalation.APPROACH_STREAM), "UFO approach stream missing")
	if not failed:
		print("GARDEN_IDENTITY_V04_OK compositions=%d acts=%s human=%s foreground=%d profiles=%d/%d licenses=OK human_polish=OK audio=OK" % [ids.size(), str(per_act), str(human_per_act), garden.foreground_nodes.size(), foliage_seen, prop_seen])
		quit(0)
