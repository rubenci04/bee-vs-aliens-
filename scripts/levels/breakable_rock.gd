class_name BreakableRock
extends StaticBody3D
## ARCADE PRESSURE + WORLD INTERACTION PASS 01. A garden rock of Level 01 that Bee's weapons
## (Base, Spread, Bomb) can break. It reuses the existing destructible vocabulary: HealthComponent,
## Hurtbox3D, HitFlash3D, the "crate" cue and combat VFX; no new system, no drops.
## The scenery builds the body, the collider and the mesh (unchanged geometry); `arm()` adds the rest.
## A structural rock has so much HP that it never breaks, but still takes hits (flash, dust, impact),
## so shots never vanish silently against a visible surface.
## Enemy fire and attacks share the "alien" team on purpose: they neither damage a rock nor use it as cover.

signal destroyed(rock: BreakableRock)

const HEALTH_SCENE := preload("res://scenes/components/health_component.tscn")
const HURTBOX_SCENE := preload("res://scenes/components/hurtbox_3d.tscn")
const FLASH_SCENE := preload("res://scenes/components/hit_flash_3d.tscn")
const STRUCTURAL_HP := 100000

var health: HealthComponent
var hurtbox: DamageHurtbox3D
var collider: CollisionShape3D
var is_destroyed := false
var structural := false


func arm(max_hp: int, is_structural: bool) -> void:
	structural = is_structural
	collider = get_node("CollisionShape3D") as CollisionShape3D
	health = HEALTH_SCENE.instantiate() as HealthComponent
	health.name = "HealthComponent"
	health.max_health = STRUCTURAL_HP if is_structural else max_hp
	add_child(health)
	var flash := FLASH_SCENE.instantiate() as HitFlash3D
	flash.name = "HitFlash3D"
	flash.visual_root_path = ^".."
	add_child(flash)
	hurtbox = HURTBOX_SCENE.instantiate() as DamageHurtbox3D
	hurtbox.name = "Hurtbox3D"
	hurtbox.team_id = &"alien"
	var area_shape := CollisionShape3D.new()
	area_shape.name = "CollisionShape3D"
	area_shape.shape = collider.shape
	hurtbox.add_child(area_shape)
	add_child(hurtbox)
	hurtbox.position = collider.position
	add_to_group("breakable_rocks")
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)


func _on_health_changed(current: int, _maximum: int, change: int) -> void:
	if change < 0 and current > 0:
		BeeCombatVFX.spawn(get_parent(), _centre(), &"rock_hit", Vector3.UP, _size())


func _on_died() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	BeeAudio.play(get_parent(), &"crate", _centre())
	BeeCombatVFX.spawn(get_parent(), _centre(), &"rock_break", Vector3.UP, _size())
	_remove()
	destroyed.emit(self)


## Checkpoint respawn: a rock broken before the checkpoint stays broken, without replaying VFX or audio.
func restore_broken() -> void:
	is_destroyed = true
	health.current_health = 0
	_remove()


func _remove() -> void:
	for mesh: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		mesh.hide()
	collision_layer = 0
	collider.set_deferred("disabled", true)
	hurtbox.set_deferred("monitorable", false)


func _centre() -> Vector3:
	return collider.global_position


func _size() -> float:
	var box := collider.shape as BoxShape3D
	return maxf(box.size.x, box.size.y) if box != null else 1.0
