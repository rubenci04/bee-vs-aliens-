extends SceneTree
const S := preload("res://scripts/vfx/bee_boss_effect_settings.gd")
const SIZE := Vector2i(1154,648)
var stage: BeeShmupStage
var actor: Node3D
var caption: Label
var laser_mode := -1
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
 for i in n: await process_frame
func clear_case() -> void:
 if is_instance_valid(actor):
  actor._clear_warnings()
  actor.free()
 actor = null
 for node in stage.get_children():
  if node.name.begins_with("BriefGroundScorch"): node.free()
func setup(kind: int, version: int) -> void:
 clear_case()
 S.enabled = version >= 0
 S.mode = maxi(version,0)
 if kind <= 1:
  var robot := preload("res://scenes/levels/walker_miniboss.tscn").instantiate() as WalkerMiniboss
  stage.add_child(robot)
  actor = robot
  robot.global_position = Vector3(stage.camera.global_position.x+3,0,0)
  robot.activate(stage.bee)
  robot.set_physics_process(false)
  if kind == 0:
   robot._begin_laser()
   robot._clear_warnings()
   robot._step = &"laser_sweep"
   robot._beam.show()
   robot._place_beam(PI+.48)
  else:
   robot._begin_jump()
   robot._left = .2
 else:
  var boss := preload("res://scenes/levels/tarantula_boss_01.tscn").instantiate() as TarantulaBoss01
  stage.add_child(boss)
  actor = boss
  boss.begin(stage.camera,stage.bee)
  boss.global_position = Vector3(stage.camera.global_position.x+3,-.1,0)
  boss._apply_pose()
  if kind == 2: boss._begin_charge()
  else:
   boss.mode = &"ceiling"
   boss.global_position.y = boss._ceiling_y()
   boss._apply_pose()
   boss._begin_jump(false)
  boss.set_physics_process(false)
 await frames(3)
func take(result: Image, x: int, y: int, text: String) -> void:
 caption.text = text
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 picture.convert(Image.FORMAT_RGBA8)
 result.blit_rect(picture,Rect2i(Vector2i.ZERO,SIZE),Vector2i(x*SIZE.x,y*SIZE.y))
func sample(seconds: float) -> float:
 var start := Time.get_ticks_usec()
 var count := 0
 while Time.get_ticks_usec()-start < seconds*1000000:
  if actor is WalkerMiniboss and actor._step == &"laser_sweep":
   var sweep := fmod(float(Time.get_ticks_usec()-start)/1000000.0,WalkerMiniboss.LASER_SWEEP)/WalkerMiniboss.LASER_SWEEP
   actor._place_beam(lerpf(PI+.22,PI+.65,sweep))
  await process_frame
  count += 1
 return count*1000000.0/(Time.get_ticks_usec()-start)
func run() -> void:
 root.size = SIZE
 Engine.max_fps = 0
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 stage = preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
 root.add_child(stage)
 current_scene = stage
 await frames(5)
 stage.set_physics_process(false)
 stage.wave.set_physics_process(false)
 stage.bee.set_physics_process(false)
 stage.bee.health.damage_blocked = true
 stage.get_node("CheckpointQoL").set_process(false)
 stage.get_node("LightProgression").set_process(false)
 stage.distance = 110
 stage._update_camera_and_bounds()
 stage.bee.global_position = Vector3(stage.camera.global_position.x-3,4,0)
 var layer := CanvasLayer.new()
 layer.layer = 45
 stage.add_child(layer)
 caption = Label.new()
 caption.position = Vector2(270,112)
 caption.add_theme_font_size_override("font_size",25)
 caption.add_theme_constant_override("outline_size",5)
 layer.add_child(caption)
 var laser := Image.create(SIZE.x*3,SIZE.y*2,false,Image.FORMAT_RGBA8)
 var marks := Image.create(SIZE.x*2,SIZE.y*6,false,Image.FORMAT_RGBA8)
 for dark in [false,true]:
  stage.get_node("LightProgression").apply_distance(310 if dark else 80)
  var row := 1 if dark else 0
  for version in [-1,0,1]:
   await setup(0,version)
   await frames(12)
   await take(laser,version+1,row,"%s · Láser %s" % ["NOCHE" if dark else "DÍA",["ANTES T3h","A · núcleo + halo + ruido","B · pulsos de energía"][version+1]])
  for kind in [1,2,3]:
   for version in [-1,0]:
    await setup(kind,version)
    await create_timer(.6).timeout
    await take(marks,version+1,row*3+kind-1,"%s · %s · %s" % ["NOCHE" if dark else "DÍA",["Salto Robot","Carga Tarántula","Diagonal Tarántula"][kind-1],"ANTES" if version < 0 else "AHORA"])
 assert(laser.save_png("res://docs/laser_antes_despues.png") == OK)
 assert(marks.save_png("res://docs/marcas_jefes_antes_despues.png") == OK)
 print("T3K_CAPTURE_OK")
 var results := []
 for pass_index in 2:
  for version in ([-1,0,1] if pass_index == 0 else [1,0,-1]):
   await setup(0,version)
   await sample(.8)
   var fps := await sample(2.5)
   results.append({"pass":pass_index,"version":version,"fps":fps})
   print("T3K_FPS ",results.back())
 FileAccess.open("res://dev/t3k_fps.json",FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
 S.enabled = true
 S.mode = S.DEFAULT_MODE
 quit()
