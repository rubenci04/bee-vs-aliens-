extends SceneTree
const S := preload("res://scripts/game/bee_feedback_settings.gd")
const SIZE := Vector2i(1154,648)
var stage: BeeShmupStage
var robot: WalkerMiniboss
var caption: Label
var firing := false
var sample_clock := 0.0
func _initialize(): call_deferred("run")
func frames(n: int):
 for i in n: await physics_frame
func setup(old: bool):
 S.legacy_flash=old
 if is_instance_valid(robot): robot.free()
 for node in stage.get_children():
  if node is BeeEnergyProjectile: node.free()
 robot=preload("res://scenes/levels/walker_miniboss.tscn").instantiate()
 stage.add_child(robot)
 robot.global_position=Vector3(stage.camera.global_position.x+2,0,0)
 robot.health.max_health=BeeLevel01Controller.MINIBOSS_HP
 robot.health.current_health=robot.health.max_health
 robot.activate(stage.bee)
 robot._step=&"rest"
 robot._left=10000
 BeeJuice.attach_hit_flash(robot)
 stage.bee.global_position=Vector3(stage.camera.global_position.x-2.5,1.1,0)
 stage.bee.set_aim_point(robot.hurtbox.get_node("CollisionShape3D").global_position)
 stage.bee.spread_ammo=20
 stage.bee.honey_left=0
 stage.bee.set_physics_process(true)
 await frames(5)
func take(result: Image, index: Vector2i, text: String):
 caption.text=text
 await RenderingServer.frame_post_draw
 var picture=root.get_texture().get_image()
 picture.convert(Image.FORMAT_RGBA8)
 result.blit_rect(picture,Rect2i(Vector2i.ZERO,SIZE),index*SIZE)
func sample(seconds: float) -> float:
 var start=Time.get_ticks_usec()
 var count=0
 while Time.get_ticks_usec()-start < seconds*1000000:
  await process_frame
  count+=1
 return count*1000000.0/(Time.get_ticks_usec()-start)
func run():
 root.size=SIZE
 Engine.max_fps=0
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 stage=preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
 root.add_child(stage)
 current_scene=stage
 await frames(5)
 stage.set_physics_process(false)
 stage.wave.set_physics_process(false)
 stage.get_node("CheckpointQoL").set_process(false)
 stage.distance=110
 stage._update_camera_and_bounds()
 stage.bee.health.damage_blocked=true
 var layer=CanvasLayer.new()
 layer.layer=50
 stage.add_child(layer)
 caption=Label.new()
 caption.position=Vector2(245,118)
 caption.add_theme_font_size_override("font_size",25)
 caption.add_theme_constant_override("outline_size",5)
 layer.add_child(caption)
 var flash_image=Image.create(SIZE.x*3,SIZE.y*2,false,Image.FORMAT_RGBA8)
 for old in [true,false]:
  await setup(old)
  Input.action_press("throw_orange")
  var max_run=0
  var run=0
  var picture_index=0
  for tick in 180:
   await physics_frame
   var flash=robot.get_node("HitFlash3D")
   run=run+1 if flash.is_flashing() else 0
   max_run=maxi(run,max_run)
   if picture_index < 3 and tick >= [42,102,162][picture_index] and flash.is_flashing():
    await take(flash_image,Vector2i(picture_index,0 if old else 1),"%s · Spread continuo · %.2f s" % ["ANTES" if old else "AHORA",float(tick+1)/60])
    picture_index+=1
  Input.action_release("throw_orange")
  assert(picture_index == 3)
  print("T4E_REAL_FIRE old=",old," max_flash_frames=",max_run," activations=",robot.get_node("HitFlash3D").activation_count," hp=",robot.health.current_health)
 assert(flash_image.save_png("res://docs/destello_antes_despues.png")==OK)
 robot.queue_free()
 await frames(2)
 stage.bee.set_physics_process(false)
 for node in stage.get_children():
  if node is BeeEnergyProjectile: node.queue_free()
 for effect in get_nodes_in_group("bee_combat_vfx"): effect.queue_free()
 await frames(2)
 var visual=stage.bee.get_node("VisualRoot/BeeVisual")
 visual.set_process(false)
 stage.bee.global_position=Vector3(stage.camera.global_position.x,3.5,0)
 var tilt=Image.create(SIZE.x*2,SIZE.y*2,false,Image.FORMAT_RGBA8)
 var speeds=[Vector3(0,stage.bee.vertical_speed,0),Vector3(0,-stage.bee.vertical_speed,0),Vector3(-stage.bee.horizontal_speed,0,0),Vector3.ZERO]
 S.tilt_enabled=true
 for i in 4:
  stage.bee.velocity=speeds[i]
  visual._update_flight_tilt(1)
  await take(tilt,Vector2i(i%2,i/2),["Subiendo · cabeceo +15°","Bajando · cabeceo −15°","Retrocediendo · alabeo +20°","Quieta · retorno neutro"][i])
 assert(tilt.save_png("res://docs/inclinacion_bee.png")==OK)
 visual.set_process(true)
 print("T4E_CAPTURE_OK")
 var results=[]
 for pass_index in 2:
  for old in ([true,false] if pass_index==0 else [false,true]):
   S.tilt_enabled=not old
   await setup(old)
   Input.action_press("throw_orange")
   await sample(.8)
   var fps=await sample(2.5)
   Input.action_release("throw_orange")
   results.append({"pass":pass_index,"old":old,"fps":fps})
   print("T4E_FPS ",results.back())
 FileAccess.open("res://dev/t4e_fps.json",FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
 S.legacy_flash=false
 S.tilt_enabled=true
 quit()
