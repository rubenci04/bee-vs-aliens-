extends SceneTree
const S := preload("res://scripts/game/bee_feedback_settings.gd")
var failed := false
func _initialize(): call_deferred("run")
func check(ok: bool, text: String):
 if not ok: failed=true; push_error(text)
func frames(n: int):
 for i in n: await physics_frame
func run():
 var stage=preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
 root.add_child(stage)
 current_scene=stage
 await frames(5)
 stage.set_physics_process(false)
 stage.wave.set_physics_process(false)
 stage.bee.set_physics_process(false)
 stage.get_node("CheckpointQoL").set_process(false)
 var bee=stage.bee
 bee.global_position=Vector3(310,3,0) # Late-level coordinates also keep the compensated muzzle stable.
 var visual=bee.get_node("VisualRoot/BeeVisual")
 visual.set_process(false)
 var initial_shape=bee.get_node("CollisionShape3D").shape
 var initial_hurt=bee.get_node("Hurtbox3D/CollisionShape3D").shape
 for version in ["v01","v02"]:
  visual.apply_model_version(version)
  for facing in [-1.0,1.0]:
   bee.facing_x=facing
   bee.visual_root.rotation.y=-facing*PI*.5
   S.tilt_enabled=false
   visual._update_flight_tilt(10)
   var origin=visual.firing_origin(bee.global_position)
   var root_transform=bee.transform
   var aim=bee.aim_direction()
   var reference=bee._spawn_projectile(aim)
   var projectile_origin=reference.global_position
   reference.queue_free()
   for velocity in [Vector3(0,bee.vertical_speed,0),Vector3(0,-bee.vertical_speed,0),Vector3(-bee.horizontal_speed,0,0),Vector3(bee.horizontal_speed,0,0)]:
    bee.velocity=velocity
    S.tilt_enabled=true
    visual._update_flight_tilt(1)
    check(absf(visual._flight_tilt.x) <= deg_to_rad(15)+.0001 and absf(visual._flight_tilt.y) <= deg_to_rad(20)+.0001,"Tilt limits")
    check(visual.firing_origin(bee.global_position).distance_to(origin) < .0001,"Neutral muzzle fixed for both versions and facings")
    check(bee.transform == root_transform and bee.aim_direction().distance_to(aim)<.00001,"Root and aim unchanged")
    var shot=bee._spawn_projectile(aim)
    check(shot.global_position.distance_to(projectile_origin)<.0001 and shot.travel_direction.distance_to(aim)<.00001,"Real projectile origin and aim unchanged while tilted")
    shot.queue_free()
   bee.velocity=Vector3.ZERO
   visual._update_flight_tilt(1)
   check(visual._flight_tilt.length()<.001,"Returns neutral when stopped")
 check(bee.get_node("CollisionShape3D").shape == initial_shape and bee.get_node("Hurtbox3D/CollisionShape3D").shape == initial_hurt,"No collider replacements")
 visual.apply_model_version("v02")
 var robot=preload("res://scenes/levels/walker_miniboss.tscn").instantiate()
 stage.add_child(robot)
 robot.activate(bee)
 robot.set_physics_process(false)
 var flash=BeeJuice.attach_hit_flash(robot)
 var mesh: MeshInstance3D
 for candidate in robot.visual_root.find_children("*","MeshInstance3D",true,false):
  if candidate.get_active_material(0).next_pass != null:
   mesh=candidate
   break
 check(mesh != null,"Robot has outlined model")
 var source=mesh.get_active_material(0)
 var outline=source.next_pass
 flash.flash()
 check(mesh.material_overlay.next_pass != null and mesh.material_overlay.next_pass.shader == outline.shader,"Outline remains after warm overlay")
 check(mesh.material_overlay.next_pass.get_shader_parameter("width") == outline.get_shader_parameter("width") and mesh.material_overlay.next_pass.get_shader_parameter("outline_color") == outline.get_shader_parameter("outline_color"),"Exact outline width and color preserved")
 check(source.next_pass == outline and is_equal_approx(mesh.material_overlay.albedo_color.a,.55),"Source outline untouched; 55 percent warm white")
 var activations=flash.activation_count
 for i in 3:
  flash.flash()
  await physics_frame
 check(flash.activation_count == activations,"Impacts cannot restart active flash")
 await frames(3)
 check(not flash.is_flashing(),"Flash ends despite continuous impacts")
 flash.flash()
 check(flash.activation_count == activations,"Cannot restart during lockout")
 await frames(14)
 flash.flash()
 check(flash.activation_count == activations+1,"Can restart after .2 seconds after finish")
 await frames(20)
 # Dense every-frame damage requests cannot keep the flash running indefinitely.
 var max_run:=0
 var run:=0
 var start=flash.activation_count
 for i in 180:
  flash.flash()
  await physics_frame
  run = run+1 if flash.is_flashing() else 0
  max_run=maxi(run,max_run)
 check(max_run <= 5 and flash.activation_count-start <= 12,"Bounded flash runs during three seconds of dense impacts")
 print("T4E_FLASH max_run_frames=",max_run," activations=",flash.activation_count-start)
 var boss=preload("res://scenes/levels/tarantula_boss_01.tscn").instantiate()
 stage.add_child(boss)
 boss.set_physics_process(false)
 check(is_equal_approx(boss.hit_flash.duration,.06) and boss.hit_flash.flash_color == S.FLASH_COLOR,"Tarantula shares the brief warm 55-percent flash")
 stage.get_node("CanvasLayer/WeaponsHUD").debug_visible = true # Tanda A: comparators require F3.
 var controls=stage.get_node("LiveReadability")
 var event=InputEventKey.new()
 event.keycode=S.TILT_KEY
 event.pressed=true
 S.tilt_enabled=true
 controls._unhandled_key_input(event)
 check(S.tilt_enabled != controls.enabled,"U toggles only in development")
 controls.enabled=false
 var enabled=S.tilt_enabled
 controls._unhandled_key_input(event)
 check(enabled == S.tilt_enabled,"Export-disabled UI cannot toggle")
 for action in InputMap.get_actions():
  for key in InputMap.action_get_events(action):
   if key is InputEventKey and not (key.ctrl_pressed or key.alt_pressed or key.shift_pressed or key.meta_pressed):
    check(key.keycode != S.TILT_KEY and key.physical_keycode != S.TILT_KEY,"Unmodified U free in InputMap")
 S.tilt_enabled=true
 print("T4E_OK failed=",failed)
 quit(1 if failed else 0)
