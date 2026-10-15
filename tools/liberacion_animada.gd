extends SceneTree
const S := preload("res://scripts/game/bee_release_settings.gd")
const SIZE := Vector2i(1154,648)
var stage: BeeShmupStage
var caption: Label
var actors: Array[Node3D] = []
var benchmark := false
var clock := 0.0
func _initialize(): call_deferred("run")
func frames(n: int):
 for i in n: await physics_frame
func spawn(kind: String, at: Vector3) -> AssetFauna:
 var actor: AssetFauna=(load("res://scenes/levels/asset_fauna/%s.tscn"%kind) as PackedScene).instantiate()
 stage.add_child(actor)
 actor.global_position=at
 actor.activate(stage.bee)
 actor.set_physics_process(false)
 actors.append(actor)
 return actor
func clear():
 for actor in actors:
  if is_instance_valid(actor): actor.queue_free()
 actors.clear()
 for group in [&"bee_combat_vfx",&"bee_release_sparks",&"bee_liberated_text"]:
  for node in get_nodes_in_group(group): node.queue_free()
 for node in stage.find_children("PollenBurst","CPUParticles3D",true,false): node.queue_free()
func batch():
 clear()
 for i in 6:
  spawn("fly_cloud",Vector3(108+(i%3)*2,1.5+(i/3)*2,0))
 for actor in actors: actor.health.take_damage(10000)
func _process(delta: float):
 if benchmark:
  clock-=delta
  if clock<=0:
   batch()
   clock=1
 return false
func sample(seconds: float) -> float:
 var start := Time.get_ticks_usec()
 var count := 0
 while Time.get_ticks_usec()-start<seconds*1000000:
  await process_frame
  count+=1
 return count*1000000.0/(Time.get_ticks_usec()-start)
func take(result: Image, i: int, title: String):
 caption.text=title
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 picture.convert(Image.FORMAT_RGBA8)
 result.blit_rect(picture,Rect2i(Vector2i.ZERO,SIZE),Vector2i(i%3,i/3)*SIZE)
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
 stage.get_node("Juice").set_physics_process(false)
 stage.get_node("LightProgression").set_process(false)
 stage.distance=110
 stage._update_camera_and_bounds()
 stage.get_node("LightProgression").apply_distance(80)
 stage.bee.global_position=Vector3(106,3,0)
 stage.bee.set_physics_process(false)
 stage.bee.health.damage_blocked=true
 for layer in stage.find_children("*","CanvasLayer",true,false): layer.hide()
 var canvas := CanvasLayer.new()
 canvas.layer=50
 stage.add_child(canvas)
 caption=Label.new()
 caption.position=Vector2(22,112)
 caption.add_theme_font_size_override("font_size",26)
 caption.add_theme_constant_override("outline_size",6)
 canvas.add_child(caption)
 spawn("fly_common",Vector3(109,4,0))
 spawn("ladybird",Vector3(112,3.4,0))
 spawn("ant",Vector3(114,.4,0))
 # Compile the fade variants before timing the captured sequence.
 for actor in actors: actor.health.take_damage(10000)
 await sample(1.2)
 clear()
 await frames(3)
 # Warm-up liberations must not leak into the displayed T1b counter.
 var notices=preload("res://scripts/ui/bee_hud_notices.gd").for_host(stage)
 notices.hide()
 notices.queue_free()
 await frames(2)
 spawn("fly_common",Vector3(109,4,0))
 spawn("ladybird",Vector3(112,3.4,0))
 spawn("ant",Vector3(114,.4,0))
 var result := Image.create(SIZE.x*3,SIZE.y*2,false,Image.FORMAT_RGBA8)
 await frames(5)
 await take(result,0,"Controlados · mosca / mariquita / hormiga")
 for actor in actors: actor.health.take_damage(10000)
 var elapsed := 0.0
 var animation=actors[0].get_children().filter(func(node): return node.get_script()==preload("res://scripts/vfx/bee_release_animation.gd"))[0]
 var targets := [.04,.20,.45,.70,.84]
 for i in targets.size():
  while elapsed<targets[i]:
   await process_frame
   elapsed=animation.elapsed if is_instance_valid(animation) else S.SECONDS+.05
  await take(result,i+1,"Liberación · %.2f s · chispa / giro / fondo / fundido"%elapsed)
 assert(result.save_png("res://docs/liberacion_animada.png")==OK)
 print("T4F_CAPTURE_OK")
 if "--capture-only" in OS.get_cmdline_user_args(): quit(); return
 clear()
 var results := []
 for pass_index in 2:
  for old in ([true,false] if pass_index==0 else [false,true]):
   S.legacy_review=old
   clock=0
   benchmark=true
   await sample(3)
   var fps := await sample(4)
   benchmark=false
   clear()
   results.append({"pass":pass_index,"old":old,"fps":fps})
   print("T4F_FPS ",results.back())
 S.legacy_review=false
 FileAccess.open("res://dev/t4f_fps.json",FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
 quit()
