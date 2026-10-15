extends Node
const S := preload("res://scripts/game/bee_release_settings.gd")
var remaining := 0.0
var cooldown := 0.0
var saved: Array[Dictionary] = []
var paused_tweens: Array[Tween] = []
static func for_host(from: Node) -> Node:
 var host := from.get_tree().current_scene
 if host == null: host=from.get_tree().root
 var found := host.get_node_or_null("LocalHitStop")
 if found != null: return found
 var controller := new()
 controller.name="LocalHitStop"
 host.add_child(controller)
 return controller
func freeze(node: Node):
 if not is_instance_valid(node) or node.is_queued_for_deletion(): return
 if saved.any(func(data): return data.node == node): return
 saved.append({"node":node,"physics":node.is_physics_processing(),"process":node.is_processing()})
 node.set_physics_process(false)
 node.set_process(false) # Keep collision objects, warnings, audio and child timers alive.
func trigger(from: Node3D, event: StringName, target: Node3D, direction: Vector2) -> bool:
 if not S.enabled or not BeeJuice.hit_stop_enabled or cooldown>0 or get_tree().paused: return false
 if event not in [&"sting",&"roll_shot",&"boss_armour"]: return false
 cooldown=S.STOP_COOLDOWN
 remaining=S.STOP_SECONDS
 var bee := from if from is BeePlayer else get_tree().get_first_node_in_group("bee_player")
 freeze(bee)
 if bee is BeePlayer:
  for tween in [bee._roll_tween,bee._turn_tween,bee._stinger_flash]:
   if tween!=null and tween.is_valid() and tween.is_running():
    tween.pause()
    paused_tweens.append(tween)
 freeze(target)
 if is_instance_valid(target):
  for child in target.get_children():
   if child.get_script()==preload("res://scripts/vfx/bee_release_animation.gd"): freeze(child)
 var center := target.global_position if is_instance_valid(target) else from.global_position
 var shots := 0
 for group in [&"alien_projectiles",&"bee_projectiles"]:
  for shot in get_tree().get_nodes_in_group(group):
   if shot is Node3D and shot.global_position.distance_to(center)<=S.STOP_RADIUS and shots<S.STOP_MAX_SHOTS:
    freeze(shot)
    shots+=1
 BeeJuice.hit_stops+=1
 BeeCameraShake.kick(from,S.SHAKE_AMPLITUDE,S.SHAKE_SECONDS,direction)
 return true
func restore():
 for data in saved:
  if is_instance_valid(data.node) and not data.node.is_queued_for_deletion():
   if data.node.has_method("is_defeated") and data.node.call("is_defeated"): continue
   data.node.set_physics_process(data.physics)
   data.node.set_process(data.process)
 saved.clear()
 for tween in paused_tweens:
  if tween!=null and tween.is_valid(): tween.play()
 paused_tweens.clear()
 remaining=0
func _process(delta: float):
 cooldown=maxf(0,cooldown-delta)
 if remaining>0:
  remaining-=delta
  if remaining<=0: restore()
func _exit_tree(): restore()
