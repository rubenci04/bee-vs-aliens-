class_name DestructibleObstacle3D
extends Node3D

signal destroyed(obstacle: DestructibleObstacle3D)

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: DamageHurtbox3D = $Hurtbox3D
@onready var body: StaticBody3D = $StaticBody3D
@onready var collider: CollisionShape3D = $StaticBody3D/CollisionShape3D
@onready var visual_root: Node3D = $VisualRoot

## Garden litter that replaces the old wooden crate: 0 crushed can, 1 giant matchbox, 2 snack bag.
## Uses the existing collider, hurtbox and HP; low banana peels are nonblocking decoration.
## NOCHE 01 · ETAPA 2: 3 open tuna tin, 4 banana peel (Codex models) replace the matchbox and the red/cream snack bag;
## their collider and hurtbox are fitted to the new, lower model (the old ones keep the crate box).
@export_enum("Crushed can", "Matchbox", "Snack bag", "Tuna tin", "Banana peel") var item_kind := 0
const CODEX_ITEMS := {3: ["res://scenes/art_labs/ground_litter_v02/open_tuna_tin.tscn", 0.9, 0.36], 4: ["res://scenes/art_labs/ground_litter_v02/banana_peel.tscn", 0.72, 0.03]}

var is_destroyed := false

func _ready() -> void:
	health.died.connect(_on_died)
	if item_kind == 4: # Low peel: decoration, never a projectile sponge or flight obstacle.
		body.collision_layer = 0
		collider.set_deferred("disabled", true)
		hurtbox.set_deferred("collision_layer", 0)
		hurtbox.set_deferred("monitorable", false)
	if CODEX_ITEMS.has(item_kind):
		_build_codex_item()
	else:
		GardenProps.build_item(item_kind, visual_root)
		BeeToonStyle.apply(visual_root, true)

func _on_died() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	BeeAudio.play(get_parent(), &"crate", global_position + Vector3(0, 1.1, 0))
	BeeCombatVFX.spawn(get_parent(), global_position + Vector3(0, 1.1, 0), &"crate")
	visual_root.hide()
	body.collision_layer = 0
	collider.set_deferred("disabled", true)
	hurtbox.set_deferred("collision_layer", 0)
	hurtbox.set_deferred("monitorable", false)
	destroyed.emit(self)


## [scene, scale, lift]: the wrapper already applies the toon look. The collision box hugs the model (own shape copies).
func _build_codex_item() -> void:
	var spec: Array = CODEX_ITEMS[item_kind]
	var item := (load(str(spec[0])) as PackedScene).instantiate() as Node3D
	item.name = "CodexItem"
	item.scale = Vector3.ONE * float(spec[1])
	item.position.y = float(spec[2])
	visual_root.add_child(item)
	if item_kind == 4:
		preload("res://scripts/levels/bee_grounded_prop.gd").settle.call_deferred(item)
	var first := true
	var box := AABB()
	for mesh: MeshInstance3D in item.find_children("*", "MeshInstance3D", true, false):
		var local: AABB = (global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
		box = local if first else box.merge(local)
		first = false
	var height := clampf(box.end.y, 0.6, 2.5)
	for shape_node: CollisionShape3D in [collider]: # Only the solid body shrinks; the hurtbox stays generous (easy to shoot).
		var shape := (shape_node.shape as BoxShape3D).duplicate() as BoxShape3D
		shape.size = Vector3(clampf(box.size.x, 0.8, 1.5), height, 1.2)
		shape_node.shape = shape
		shape_node.position = Vector3(0.0, height * 0.5, 0.0)
