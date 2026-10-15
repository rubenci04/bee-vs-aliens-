extends SceneTree
const S := preload("res://scripts/vfx/bee_boss_effect_settings.gd")
var failed := false
func _initialize(): call_deferred("run")
func check(ok: bool, text: String):
 if not ok: failed = true; push_error(text)
func frames(n: int):
 for i in n: await physics_frame
func run():
 var stage = preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
 root.add_child(stage)
 current_scene = stage
 await frames(4)
 stage.set_physics_process(false)
 stage.wave.set_physics_process(false)
 stage.bee.set_physics_process(false)
 stage.get_node("CheckpointQoL").set_process(false)
 var robot = preload("res://scenes/levels/walker_miniboss.tscn").instantiate()
 stage.add_child(robot)
 robot.activate(stage.bee)
 robot.set_physics_process(false)
 robot._begin_laser()
 check(robot.LASER_WARNING == .85 and robot.LASER_SWEEP == .7,"Warning/sweep times unchanged")
 check(robot._beam_box.get_child(0).shape.size == Vector3(16,.3,1.2) and robot._beam_box.damage == robot.LASER_DAMAGE,"Same beam damage width and volume")
 check(robot._beam.mesh is QuadMesh and robot._beam.mesh.size == Vector2(16,.3),"Visual beam matches damage width")
 check(S.mode == 0 and S.CORE_FRACTION == .25,"A default, fine white core")
 check(robot._warnings.size() == 2,"Same sector reference lines")
 await frames(2)
 check(robot.laser_effect.charge.visible,"Charge visible for full warning")
 check(robot._warnings.all(func(node):return not node.visible),"No trajectory line before final .3 seconds")
 robot._left = .25
 await frames(2)
 check(robot._warnings.all(func(node):return node.visible and node.material_override.get_shader_parameter("opacity") <= .2),"Only faint dotted late lines")
 for variant in [0,1]:
  S.mode = variant
  robot.laser_effect._process(0)
  await frames(2)
  check(robot._beam.material_override.get_shader_parameter("variant") == variant,"Both shader versions apply live")
 robot._step = &"laser_sweep"
 robot._beam.show()
 robot._place_beam(PI+.7)
 await frames(2)
 check(robot.laser_effect.sparks.emitting,"Contact sparks during beam")
 check(is_instance_valid(robot.laser_effect.burn),"Ground intersection leaves brief burn")
 robot._clear_warnings()
 robot._begin_jump()
 check(robot._left == robot.JUMP_TELEGRAPH and robot._warnings.size() == 1,"Jump timing unchanged, one impact mark")
 var mark=robot._warnings[0]
 check(mark.mesh is QuadMesh and is_equal_approx(mark.mesh.size.x,2.2) and mark.get_meta("t3k_marker"),"Jump uses ring with original damage footprint width")
 check(mark.find_children("*","Area3D",true,false).is_empty(),"Marker has no damage/collision")
 check(mark.material_override.get_shader_parameter("opacity") == S.MARK_ALPHA,"Initial ring opacity")
 await create_timer(robot.JUMP_TELEGRAPH-.25).timeout
 check(mark.material_override.get_shader_parameter("opacity") == S.FINAL_ALPHA,"Ring brightens in last .3 seconds")
 robot._land()
 check(robot._land_box.get_child(0).shape.size == Vector3(2.2,2.8,1.2) and robot._land_box.damage == robot.JUMP_DAMAGE,"Landing damage/area unchanged")
 var spider=preload("res://scenes/levels/tarantula_boss_01.tscn").instantiate()
 stage.add_child(spider)
 spider.begin(stage.camera,stage.bee)
 spider.set_physics_process(false)
 spider._begin_charge()
 check(spider._left == spider.CHARGE_TELEGRAPH and spider._warnings.size() == 2,"Tarantula same charge timing, arrows + endpoint ring")
 check(spider._warnings[0].global_position.z < 0 and spider._warnings[0].material_override.get_shader_parameter("opacity") <= .4,"Arrows behind body with max .4 initial opacity")
 var original_shape=spider._charge_box.get_child(0).shape.size
 spider._clear_warnings()
 spider._begin_jump(false)
 check(spider._warnings.size() == 1 and spider._charge_box.get_child(0).shape.size == original_shape,"Diagonal has one local marker, no attack geometry changes")
 for action in InputMap.get_actions():
  for event in InputMap.action_get_events(action):
   if event is InputEventKey: check(event.keycode != S.KEY and event.physical_keycode != S.KEY,"K is free in InputMap")
 var gate=preload("res://scripts/game/bee_readability_settings.gd")
 check(not gate.development_for(false,true,true),"Export cannot switch variants")
 var controls=stage.get_node("LiveReadability")
 var event=InputEventKey.new()
 event.keycode=S.KEY
 event.pressed=true
 S.mode=0
 controls._unhandled_key_input(event)
 check(S.mode == (1 if controls.enabled else 0),"Real K handler switches only when development is enabled")
 controls.enabled=false
 controls._unhandled_key_input(event)
 check(S.mode == (1 if gate.development_enabled() else 0),"Disabled/export handler cannot respond")
 S.mode=0
 print("T3K_OK failed=",failed)
 quit(1 if failed else 0)
