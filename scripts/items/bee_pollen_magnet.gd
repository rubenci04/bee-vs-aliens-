extends RefCounted
const S := preload("res://scripts/game/bee_pollen_settings.gd")
static func radius(pickup: BeePollenPickup) -> float:
 var shape := pickup.get_node("CollisionShape3D") as CollisionShape3D
 return (shape.shape as SphereShape3D).radius*S.ATTRACTION_FACTOR
static func blocked(pickup: BeePollenPickup, bee: BeePlayer) -> bool:
 var query := PhysicsRayQueryParameters3D.create(pickup.global_position,bee.global_position,2)
 query.collide_with_bodies = false
 query.collide_with_areas = true
 query.hit_from_inside = true
 var excluded: Array[RID] = [bee.hurtbox.get_rid()]
 for i in 12:
  query.exclude = excluded
  var hit := pickup.get_world_3d().direct_space_state.intersect_ray(query)
  if hit.is_empty(): return false
  var area = hit.collider
  if area is DamageHurtbox3D:
   var owner: Node = area.owner_entity
   if owner == bee or (is_instance_valid(owner) and owner.has_method("is_defeated") and owner.call("is_defeated")):
    excluded.append(area.get_rid())
    continue
  return true # Never pull through a live enemy/obstacle area.
 return true
static func step(pickup: BeePollenPickup, bee: BeePlayer, delta: float) -> bool:
 var camera := pickup.get_viewport().get_camera_3d()
 if camera != null:
  var half := BeeShmupFairness.visible_half_width(camera,pickup.global_position,BeeLevel01Framing.view_aspect(pickup.get_viewport()))
  if pickup.global_position.x < camera.global_position.x-half-S.SCREEN_RETIRE_MARGIN:
   pickup.queue_free() # Missed pickups behind the camera; future authored pickups stay.
   return false
  var rect := pickup.get_viewport().get_visible_rect().grow(S.SCREEN_MARGIN_PX)
  if camera.is_position_behind(pickup.global_position) or not rect.has_point(camera.unproject_position(pickup.global_position)):
   pickup.set_meta("pollen_pull_speed",0.0)
   return false
 var offset := bee.global_position-pickup.global_position
 offset.z = 0
 var distance := offset.length()
 var reach := radius(pickup)*(S.ROLL_RADIUS_FACTOR if bee.is_rolling else 1.0)
 if distance > reach or distance < S.ARRIVAL_DISTANCE or blocked(pickup,bee):
  pickup.set_meta("pollen_pull_speed",0.0)
  return false
 var speed := minf(S.MAX_SPEED,maxf(S.START_SPEED,float(pickup.get_meta("pollen_pull_speed",0.0)))+S.ACCELERATION*delta)
 pickup.set_meta("pollen_pull_speed",speed)
 pickup.global_position += offset/distance*minf(speed*delta,distance)
 return true
