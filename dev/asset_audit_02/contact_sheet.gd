extends SceneTree
## DEV ONLY (ASSET LIBRARY DEEP AUDIT 02). Contact sheets of library candidates, rendered in a
## SubViewport. Every model is loaded at runtime from its absolute path (GLTFDocument / FBXDocument /
## obj_loader.gd): NOTHING is imported into the project and the library is only read.
##   godot --path . --resolution 640x360 --script res://dev/asset_audit_02/contact_sheet.gd -- sheet=humans [style=raw]
## style=toon (default) applies Style C (BeeToonStyle: toon bands + rim + outline). style=raw keeps source materials.
## Writes dev/asset_audit_02/sheets/<sheet>_<style>.png (dev PNGs are git-ignored; folder has .gdignore).

const LIB := "D:/proyectos/V_Asset_Library/01_Extracted/"
const OUT := "res://dev/asset_audit_02/sheets/"
const ObjLoader := preload("res://dev/asset_audit_02/obj_loader.gd")
const QE := LIB + "quaternius/Easy Animated Enemy Pack - Jan 2019-20260929T144515Z-1-001/Easy Animated Enemy Pack - Jan 2019/FBX/"
const UPP := LIB + "nuevos/Ultimate Platformer Pack by Quaternius/Ultimate Platformer Pack - Dec 2021/"
const KK := LIB + "nuevos/KayKit_Adventurers_2.0_FREE/KayKit_Adventurers_2.0_FREE/"
const KK_RIG := KK + "Animations/gltf/Rig_Medium/Rig_Medium_MovementBasic.glb"
const KF := LIB + "nuevos/KayKit_Forest_Nature_Pack_1.0_FREE/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/"
const TT := LIB + "nuevos/Tiny_Treats_House_Plants_1.0_FREE/Tiny_Treats_House_Plants_1.0_FREE/Assets/gltf/"
const FW := LIB + "nuevos/Free Wild Animal 3D Models/fbx/unity/"
const FW_TEX := LIB + "nuevos/Free Wild Animal 3D Models/texture/wild_animals_map.png"
const DW := LIB + "nuevos/LowPoly_Pixel_RPG_Assets_devilsworkshop_v02/LowPoly_Pixel_RPG_Assets_devilsworkshop_v02/3D/FBX/"
const MT := LIB + "nuevos/modular_terrain_collection/modular_terrain_collection/"
const KN := LIB + "kenney/kenney_nature-kit/Models/GLTF format/"
const KFD := LIB + "kenney/kenney_food-kit/Models/GLB format/"
const KS := LIB + "kenney/kenney_space-kit/Models/GLTF format/"
const KB := LIB + "kenney/kenney_blaster-kit_2.1/Models/GLB format/"
const QN := LIB + "quaternius/Stylized Nature MegaKit[Standard]/glTF/"
const QS := LIB + "quaternius/Sci-Fi Essentials Kit[Standard]/glTF/"
const QM := LIB + "quaternius/Modular SciFi MegaKit[Standard]/Modular SciFi MegaKit[Standard]/glTF/"
const EX := LIB + "extras/"
const NV := LIB + "nuevos/"

# [path, label, options]. options: clip (keyword list), tex (external albedo texture), anim_lib (glTF with clips for the same rig), yaw.
var SHEETS := {
	"humans": {"cols": 5, "items": [
		["res://assets/models/human_reuse/hipster_poc.glb", "ACTUAL Hipster (propio)", {"clip": ["run"]}],
		[UPP + "Character/glTF/Character.gltf", "UPP Character CC0", {"clip": ["run"]}],
		[KK + "Characters/gltf/Rogue.glb", "KayKit Rogue CC0", {"anim_lib": KK_RIG, "clip": ["running_a"]}],
		[KK + "Characters/gltf/Ranger.glb", "KayKit Ranger CC0", {"anim_lib": KK_RIG, "clip": ["running_a"]}],
		[KK + "Characters/gltf/Barbarian.glb", "KayKit Barbarian CC0", {"anim_lib": KK_RIG, "clip": ["walking_a"]}],
		[KK + "Characters/gltf/Knight.glb", "KayKit Knight CC0", {"anim_lib": KK_RIG, "clip": ["walking_a"]}],
		[KK + "Characters/gltf/Mage.glb", "KayKit Mage CC0", {"anim_lib": KK_RIG, "clip": ["walking_b"]}],
		[LIB + "kenney/kenney_mini-forest_1.0/Models/GLB format/character-archer.glb", "Kenney archer CC0", {"clip": ["sprint"]}],
		[KS + "astronautA.glb", "Kenney astronautA CC0", {}],
		[NV + "male_casual/male_casual.fbx", "male_casual SIN LICENCIA", {"tex": NV + "male_casual/man_tex.png"}],
		[DW + "char01.fbx", "Devil's char01 VERIFICAR", {}],
		[DW + "player1.fbx", "Devil's player1 VERIFICAR", {}],
		[LIB + "kenney/kenney_prototype-kit/Models/GLB format/figurine-large.glb", "Kenney figurine CC0", {"clip": ["walk"]}],
		[EX + "Alien Jetpack Go! by Damon Pidhajecky - 7VJiMcRcn6d/model.obj", "Alien Jetpack CC-BY(web)", {}],
		[EX + "Alien by jeremy - 3SD07SGSMNy/Alien_01.obj", "Alien jeremy CC-BY(web)", {}],
	]},
	"fauna": {"cols": 6, "items": [
		[QE + "Frog.fbx", "Frog CC0 (en uso)", {"clip": ["idle"]}],
		[QE + "Rat.fbx", "Rat CC0", {"clip": ["run"]}],
		[QE + "Snake.fbx", "Snake CC0", {"clip": ["walk"]}],
		[QE + "Snake_angry.fbx", "Snake angry CC0", {"clip": ["attack"]}],
		[QE + "Spider.fbx", "Spider CC0", {"clip": ["walk"]}],
		[QE + "Wasp.fbx", "Wasp Quaternius CC0", {"clip": ["flying"]}],
		[UPP + "Enemies/glTF/Bee.gltf", "UPP Bee CC0", {"clip": ["flying"]}],
		[UPP + "Enemies/glTF/Crab.gltf", "UPP Crab CC0", {"clip": ["walk"]}],
		[UPP + "Enemies/glTF/Enemy.gltf", "UPP Enemy CC0", {"clip": ["walk"]}],
		[UPP + "Enemies/glTF/Skull.gltf", "UPP Skull CC0", {"clip": ["idle"]}],
		[EX + "Tree Blob by Quaternius - 0X3fUj0uUF.glb", "Tree Blob CC0(web)", {}],
		[EX + "Alien by Quaternius - sUTLXji0aL.glb", "Alien Quaternius (en uso)", {"clip": ["walk"]}],
		[FW + "owl.fbx", "Owl VERIFICAR craftpix", {"tex": FW_TEX}],
		[FW + "squirrel.fbx", "Squirrel VERIFICAR", {"tex": FW_TEX}],
		[FW + "rabbit.fbx", "Rabbit VERIFICAR", {"tex": FW_TEX}],
		[FW + "hedhog.fbx", "Hedgehog VERIFICAR", {"tex": FW_TEX}],
		[FW + "fox.fbx", "Fox VERIFICAR", {"tex": FW_TEX}],
		[FW + "boar.fbx", "Boar VERIFICAR", {"tex": FW_TEX}],
		[FW + "deer_1.fbx", "Deer VERIFICAR", {"tex": FW_TEX}],
		[FW + "wolf.fbx", "Wolf VERIFICAR", {"tex": FW_TEX}],
		[FW + "bear.fbx", "Bear VERIFICAR", {"tex": FW_TEX}],
		[LIB + "kenney/kenney_prototype-kit/Models/GLB format/animal-dog.glb", "Kenney proto dog CC0", {"clip": ["run"]}],
		[EX + "Bee by apelab - f0lW38lzjd4/model.obj", "Bee apelab CC-BY(web)", {}],
		[EX + "Wasp by Poly by Google - e-maR6CzcKc/wasp.obj", "Wasp Poly CC-BY(web)", {}],
	]},
	"alien_safe": {"cols": 6, "items": [
		[QM + "Aliens/Alien_Cyclop.gltf", "Alien Cyclop CC0", {"clip": ["idle"]}],
		[QM + "Aliens/Alien_Oculichrysalis.gltf", "Oculichrysalis CC0", {"clip": ["idle"]}],
		[QM + "Aliens/Alien_Scolitex.gltf", "Scolitex CC0", {"clip": ["idle"]}],
		[QS + "Enemy_EyeDrone.gltf", "EyeDrone CC0 (en uso)", {"clip": ["idle"]}],
		[QS + "Enemy_QuadShell.gltf", "QuadShell CC0", {"clip": ["walk"]}],
		[QS + "Enemy_Trilobite.gltf", "Trilobite CC0", {"clip": ["walk"]}],
		[QS + "Prop_SatelliteDish.gltf", "SatelliteDish CC0", {}],
		[QS + "Prop_Mine.gltf", "Mine CC0", {}],
		[KS + "alien.glb", "Kenney alien CC0", {}],
		[KS + "craft_cargoA.glb", "craft_cargoA CC0", {}],
		[KS + "craft_cargoB.glb", "craft_cargoB CC0", {}],
		[KS + "craft_miner.glb", "craft_miner CC0", {}],
		[KS + "craft_racer.glb", "craft_racer CC0", {}],
		[KS + "craft_speederB.glb", "craft_speederB CC0", {}],
		[KS + "craft_speederD.glb", "craft_speederD CC0", {}],
		[KS + "turret_double.glb", "turret_double CC0", {}],
		[KS + "satelliteDish_large.glb", "satDish_large CC0", {}],
		[KS + "machine_wireless.glb", "machine_wireless CC0", {}],
		[KS + "rock_crystalsLargeA.glb", "crystalsLargeA CC0", {}],
		[KS + "hangar_roundGlass.glb", "hangar_roundGlass CC0", {}],
		[UPP + "Level and Mechanics/glTF/Hazard_Saw.gltf", "UPP Saw CC0", {}],
		[UPP + "Level and Mechanics/glTF/SpikyBall.gltf", "UPP SpikyBall CC0", {}],
		[UPP + "Level and Mechanics/glTF/Cannon.gltf", "UPP Cannon CC0", {}],
		[EX + "Robot Enemy Legs Gun by Quaternius - lFZfDh2hzP/Enemy_2Legs_Gun.fbx", "Walker (en uso)", {"clip": ["walk"]}],
	]},
	"alien_doubtful": {"cols": 6, "items": [
		[EX + "Flying saucer by Poly by Google - fojR5i3h_nh/flying sacuer.obj", "Saucer fojR CC-BY(web)", {}],
		[EX + "Flying saucer by Poly by Google - b0N_HeT_Ttb/1352 Flying Saucer.obj", "Saucer b0N CC-BY(web)", {}],
		[EX + "UFO by marcusnikira - 4nCAC4jP0a/UFO.fbx", "UFO marcusnikira CC-BY(web)", {}],
		[EX + "Ufo by hat_my_guy - NgURFR5T9m/ufo.fbx", "Ufo hat_my_guy CC0(web)", {}],
		[EX + "ricks ufo by eeee - q6vNUoHZXr/source/RAM.fbx", "ricks ufo CC-BY(web)", {}],
		[EX + "UFO TIME by Martin Calviello - 89hlsI17Ulw/model.obj", "UFO TIME CC-BY(web)", {}],
		[EX + "spaceship Goodnews by Justin Scifres - aeLvaKN3cYh/model.obj", "Goodnews CC-BY(web)", {}],
		[EX + "Owz by sirkitree - 5vbeGRwzuQl/model.obj", "Owz CC-BY(web)", {}],
		[EX + "1 by Eric Finn - 05X3xYCrpya/model.obj", "'1' Eric Finn CC-BY(web)", {}],
		[EX + "Mars Rover by Anna M - 2qciL4mkmTz/model.obj", "Mars Rover CC-BY(web)", {}],
		[NV + "Low Poly UFO Scene By EdwinRC.fbx", "UFO Scene EdwinRC DUDOSO", {}],
		[NV + "UFO_Wavefront.obj", "UFO_Wavefront DUDOSO", {}],
		[NV + "Arachnodroid/Package/Arachnoid.obj", "Arachnodroid SIN LIC", {}],
		[NV + "Companion-bot/Package/Companion-bot.obj", "Companion-bot SIN LIC", {}],
		[NV + "FieldFighter/Package/FieldFighter.obj", "FieldFighter SIN LIC", {}],
		[NV + "MechGolem/Package/MechaGolem.obj", "MechGolem SIN LIC", {}],
		[NV + "Mecha01/Package/Mecha01.obj", "Mecha01 SIN LIC", {}],
		[NV + "MechaTrooper/Package/MechaTrooper.obj", "MechaTrooper SIN LIC", {}],
		[NV + "MobileStorageBot/Package/MobileStorageBot.obj", "MobileStorageBot SIN LIC", {}],
		[NV + "QuadrupedTank/Package/QuadrupedTank.obj", "QuadrupedTank SIN LIC", {}],
		[NV + "ReconBot/Package/ReconBot.obj", "ReconBot SIN LIC", {}],
	]},
	"props": {"cols": 8, "items": [
		[KFD + "soda-can.glb", "soda-can", {}], [KFD + "soda-can-crushed.glb", "can crushed", {}],
		[KFD + "can-open.glb", "can-open", {}], [KFD + "bottle-ketchup.glb", "ketchup", {}],
		[KFD + "carton.glb", "carton", {}], [KFD + "cup-coffee.glb", "cup-coffee", {}],
		[KFD + "mug.glb", "mug", {}], [KFD + "candy-bar-wrapper.glb", "candy wrapper", {}],
		[KFD + "chocolate-wrapper.glb", "choco wrapper", {}], [KFD + "pizza-box.glb", "pizza-box", {}],
		[KFD + "bag.glb", "bag", {}], [KFD + "apple-half.glb", "apple-half", {}],
		[KFD + "watermelon.glb", "watermelon", {}], [KFD + "banana.glb", "banana", {}],
		[KFD + "cookie.glb", "cookie", {}], [KFD + "popsicle-stick.glb", "popsicle-stick", {}],
		[KFD + "plate-broken.glb", "plate-broken", {}], [KFD + "styrofoam.glb", "styrofoam", {}],
		[KFD + "fries-empty.glb", "fries-empty", {}], [KFD + "utensil-fork.glb", "fork", {}],
		[TT + "watering_can_A.gltf", "TT watering can A", {}], [TT + "watering_can_B.gltf", "TT watering can B", {}],
		[TT + "shovel.gltf", "TT shovel", {}], [TT + "pot_A_large.gltf", "TT pot A", {}],
		[TT + "pots_stacked.gltf", "TT pots stacked", {}], [TT + "saucer_A_large.gltf", "TT saucer", {}],
		[TT + "monstera_plant_large_potted.gltf", "TT monstera potted", {}], [TT + "succulent_plant_pot_large.gltf", "TT succulent pot", {}],
		[KB + "crate-medium.glb", "blaster crate", {}], [KB + "target-large.glb", "blaster target", {}],
		[KB + "blaster-a.glb", "toy blaster", {}], [KB + "bullet-foam.glb", "foam dart", {}],
		[KN + "pot_large.glb", "nature pot_large", {}], [KN + "fence_simple.glb", "fence_simple", {}],
		[KN + "sign.glb", "sign", {}], [UPP + "Level and Mechanics/glTF/Pipe_Straight.gltf", "UPP pipe", {}],
		[UPP + "Level and Mechanics/glTF/Chest.gltf", "UPP chest", {}], [DW + "boxCardboard.fbx", "Devil's box VERIFICAR", {}],
		[DW + "suitCase.fbx", "Devil's suitcase VERIF", {}], [DW + "scissor.fbx", "Devil's scissor VERIF", {}],
	]},
	"nature": {"cols": 8, "items": [
		[KF + "Tree_1_A_Color1.gltf", "KF Tree_1", {}], [KF + "Tree_2_A_Color1.gltf", "KF Tree_2", {}],
		[KF + "Tree_Bare_1_A_Color1.gltf", "KF Tree_Bare", {}], [KF + "Bush_1_A_Color1.gltf", "KF Bush_1", {}],
		[KF + "Bush_4_A_Color1.gltf", "KF Bush_4", {}], [KF + "Grass_1_A_Color1.gltf", "KF Grass_1", {}],
		[KF + "Grass_2_A_Color1.gltf", "KF Grass_2", {}], [KF + "Rock_1_A_Color1.gltf", "KF Rock_1", {}],
		[QN + "Flower_3_Group.gltf", "QN Flower_3", {}], [QN + "Flower_4_Group.gltf", "QN Flower_4", {}],
		[QN + "Clover_1.gltf", "QN Clover", {}], [QN + "Grass_Common_Tall.gltf", "QN Grass tall", {}],
		[QN + "Mushroom_Common.gltf", "QN Mushroom", {}], [QN + "Mushroom_Laetiporus.gltf", "QN Laetiporus", {}],
		[QN + "Petal_1.gltf", "QN Petal", {}], [QN + "Plant_7_Big.gltf", "QN Plant_7_Big", {}],
		[QN + "Bush_Common_Flowers.gltf", "QN Bush flowers", {}], [QN + "Pebble_Round_1.gltf", "QN Pebble", {}],
		[KN + "mushroom_redGroup.glb", "KN mushroom group", {}], [KN + "plant_bushDetailed.glb", "KN bush detailed", {}],
		[KN + "grass_leafsLarge.glb", "KN grass leafs", {}], [KN + "flower_redB.glb", "KN flower_redB", {}],
		[KN + "stump_roundDetailed.glb", "KN stump", {}], [KN + "log_stack.glb", "KN log_stack", {}],
		[UPP + "Nature/glTF/Bush_Fruit.gltf", "UPP Bush_Fruit", {}], [UPP + "Nature/glTF/Tree_Fruit.gltf", "UPP Tree_Fruit", {}],
		[UPP + "Nature/glTF/Plant_Large.gltf", "UPP Plant_Large", {}], [UPP + "Nature/glTF/Cloud_1.gltf", "UPP Cloud", {}],
		[TT + "monstera_leaf_large_A.gltf", "TT monstera leaf", {}], [TT + "sansevieria_leaf_large_A.gltf", "TT sansevieria leaf", {}],
		[TT + "yucca_plant_large.gltf", "TT yucca", {}], [TT + "pothos_vine_large_A.gltf", "TT pothos vine", {}],
	]},
	"water": {"cols": 6, "items": [
		[KN + "lily_large.glb", "KN lily_large CC0", {}], [KN + "lily_small.glb", "KN lily_small CC0", {}],
		[KN + "ground_riverStraight.glb", "KN riverStraight CC0", {}], [KN + "ground_riverBendBank.glb", "KN riverBendBank CC0", {}],
		[KN + "canoe.glb", "KN canoe CC0", {}], [KN + "canoe_paddle.glb", "KN paddle CC0", {}],
		[KN + "cliff_waterfall_rock.glb", "KN waterfall CC0", {}], [KN + "platform_beach.glb", "KN platform_beach CC0", {}],
		[QE + "Frog.fbx", "Frog CC0", {"clip": ["jump"]}], [QE + "Snake.fbx", "Snake CC0", {"clip": ["walk"]}],
		[UPP + "Enemies/glTF/Crab.gltf", "UPP Crab CC0", {"clip": ["bite"]}], [KN + "plant_flatTall.glb", "KN plant_flatTall CC0", {}],
		[LIB + "flores/gal-b-water-lily-4370.glb", "water lily DUDOSO", {}], [MT + "Hilly_Prop_Cattail_1.obj", "Cattail VERIFICAR", {}],
		[MT + "Hilly_Prop_Cattail_2.obj", "Cattail 2 VERIFICAR", {}], [MT + "Hilly_Terrain_Water_Flat.obj", "Water flat VERIFICAR", {}],
		[MT + "Beach_Prop_Shell_1.obj", "Shell VERIFICAR", {}], [MT + "Hilly_Prop_Stepping_Stones_1.obj", "Stepping stones VERIF", {}],
	]},
	"doubtful_misc": {"cols": 6, "items": [
		[LIB + "flores/quaternius_cc0-flower-1014.glb", "flores q-1014 DUDOSO", {}], [LIB + "flores/quaternius_cc0-flowers-1020.glb", "flores q-1020 DUDOSO", {}],
		[LIB + "flores/quaternius_cc0-sakura-flower-901.glb", "flores sakura DUDOSO", {}], [LIB + "flores/tilixia-summer-tulip-4376.glb", "tulip tilixia DUDOSO", {}],
		[LIB + "flores/mohamed_hassan-sunflower-4398.glb", "sunflower DUDOSO", {}], [LIB + "flores/plaggy_cc0-plant-pot-573.glb", "plant pot DUDOSO", {}],
		[MT + "Hilly_Prop_Flower_Daisy.obj", "MT daisy VERIFICAR", {}], [MT + "Hilly_Prop_Flower_Sunflower.obj", "MT sunflower VERIF", {}],
		[MT + "Hilly_Prop_Hollow_Trunk.obj", "MT hollow trunk VERIF", {}], [MT + "Hilly_Prop_Mushroom_1.obj", "MT mushroom VERIF", {}],
		[MT + "Hilly_Prop_Tree_Oak_1.obj", "MT oak VERIF", {}], [MT + "Hilly_Prop_Fence_Boards_1.obj", "MT fence VERIF", {}],
		[NV + "LowPoly Environment Pack/Tree_1.fbx", "LP Env tree SIN LIC", {}], [NV + "LowPoly Environment Pack/Plant_3.fbx", "LP Env plant SIN LIC", {}],
		[NV + "LowPoly Environment Pack/Bush_1.fbx", "LP Env bush SIN LIC", {}], [DW + "pot01.fbx", "Devil's pot VERIF", {}],
		[DW + "woodenBarrel.fbx", "Devil's barrel VERIF", {}], [DW + "player3.fbx", "Devil's player3 VERIF", {}],
	]},
}

var sheet := "humans"
var style := "toon"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("sheet="):
			sheet = arg.substr(6)
		elif arg.begins_with("style="):
			style = arg.substr(6)
	call_deferred("run")


func load_model(path: String) -> Node3D:
	if path.begins_with("res://"):
		return (load(path) as PackedScene).instantiate() as Node3D
	if path.to_lower().ends_with(".obj"):
		return ObjLoader.new().load_obj(path)
	var state: GLTFState = FBXState.new() if path.to_lower().ends_with(".fbx") else GLTFState.new()
	var document: GLTFDocument = FBXDocument.new() if path.to_lower().ends_with(".fbx") else GLTFDocument.new()
	if document.append_from_file(path, state) != OK:
		push_error("Could not read " + path)
		return null
	return document.generate_scene(state) as Node3D


func apply_texture(model: Node3D, texture_path: String) -> void:
	var image := Image.load_from_file(texture_path)
	if image == null:
		return
	var texture := ImageTexture.create_from_image(image)
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for s in mesh.mesh.get_surface_count():
			var material := StandardMaterial3D.new()
			material.albedo_texture = texture
			mesh.set_surface_override_material(s, material)


func attach_library(model: Node3D, lib_path: String) -> AnimationPlayer:
	var donor := load_model(lib_path)
	if donor == null:
		return null
	var donor_player := donor.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var player := AnimationPlayer.new()
	model.add_child(player)
	player.root_node = NodePath("..")
	var library := AnimationLibrary.new()
	for clip in donor_player.get_animation_list():
		library.add_animation(clip, donor_player.get_animation(clip).duplicate())
	player.add_animation_library("", library)
	donor.free()
	return player


func pose(model: Node3D, keywords: Array) -> String:
	for player: AnimationPlayer in model.find_children("*", "AnimationPlayer", true, false):
		var clips := player.get_animation_list()
		for keyword in keywords:
			for clip in clips:
				if str(clip).to_lower().contains(str(keyword)):
					player.play(clip)
					player.seek(player.get_animation(clip).length * 0.3, true)
					player.pause()
					return str(clip).get_slice("|", 1) if str(clip).contains("|") else str(clip)
	return ""


func stats(model: Node3D) -> Vector2i:
	var tris := 0
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh is ArrayMesh:
			for s in mesh.mesh.get_surface_count():
				var n := (mesh.mesh as ArrayMesh).surface_get_array_index_len(s)
				tris += (n if n > 0 else (mesh.mesh as ArrayMesh).surface_get_array_len(s)) / 3
	var clips := 0
	for player: AnimationPlayer in model.find_children("*", "AnimationPlayer", true, false):
		clips += player.get_animation_list().size()
	return Vector2i(tris, clips)


func bounds(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null or not mesh.is_visible_in_tree():
			continue
		var b: AABB = mesh.global_transform * mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func run() -> void:
	var def: Dictionary = SHEETS[sheet]
	var items: Array = def["items"]
	var cols: int = def["cols"]
	var rows := ceili(items.size() / float(cols))
	var cell := 3.2
	var viewport := SubViewport.new()
	viewport.size = Vector2i(cols * 324, rows * 330)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.own_world_3d = true
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.80, 0.85, 0.76)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1, 0.95, 0.85)
	env.environment.ambient_light_energy = 0.6
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.75, 0.55, 0)
	world.add_child(sun)
	for i in items.size():
		var entry: Array = items[i]
		var opts: Dictionary = entry[2]
		var model := load_model(str(entry[0]))
		var col := i % cols
		var row := i / cols
		var center := Vector3((col - (cols - 1) * 0.5) * cell, ((rows - 1) * 0.5 - row) * cell * 1.03, 0)
		var info := "NO CARGA"
		if model != null:
			world.add_child(model)
			if opts.has("tex"):
				apply_texture(model, opts["tex"])
			if opts.has("anim_lib"):
				attach_library(model, opts["anim_lib"])
			var used_clip := pose(model, opts.get("clip", ["idle", "walk", "fly"]))
			await process_frame
			var box := bounds(model)
			var real_size := box.size
			var size := maxf(box.size.y, maxf(box.size.x, box.size.z))
			model.scale *= 2.3 / maxf(size, 0.0001)
			model.rotation.y = opts.get("yaw", -0.6)
			await process_frame
			box = bounds(model)
			model.global_position += center + Vector3(0, -0.95, 0) - Vector3(box.get_center().x, box.position.y, box.get_center().z)
			if style == "toon":
				BeeToonStyle.apply(model, true, BeeToonStyle.OUTLINE_ACTOR)
			var s := stats(model)
			info = "%d tris | %d clips | %.2fx%.2fx%.2f" % [s.x, s.y, real_size.x, real_size.y, real_size.z]
			if used_clip != "":
				info += "\npose: " + used_clip
		var label := Label3D.new()
		label.text = str(entry[1]) + "\n" + info
		label.font_size = 26
		label.outline_size = 0
		label.pixel_size = 0.0042
		label.modulate = Color(0.08, 0.08, 0.08)
		label.position = center + Vector3(0, -1.3, 1.5)
		world.add_child(label)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = rows * cell * 1.03
	camera.position = Vector3(0, 0, 20)
	camera.near = 0.1
	camera.far = 60.0
	world.add_child(camera)
	camera.make_current()
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := OUT + sheet + "_" + style + ".png"
	viewport.get_texture().get_image().save_png(path)
	print("SHEET ", path, " items=", items.size())
	quit(0)
