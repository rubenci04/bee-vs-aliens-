extends SceneTree
## Rendered review of the actual pickups and Bee shots; no replacement art.
const S := preload("res://scripts/game/bee_pollen_settings.gd")
const M := preload("res://scripts/items/bee_pollen_magnet.gd")
const SIZE := Vector2i(1154,648)
var stage: BeeShmupStage
var caption: Label
var samples: Array[Node3D] = []
var labels: Array[Label] = []
var measuring := false
func _initialize(): call_deferred("run")
func frames(n: int):
 for i in n: await physics_frame
func label(value: String, position: Vector2, size := 24) -> Label:
 var node := Label.new()
 node.text=value
 node.position=position
 node.add_theme_font_size_override("font_size",size)
 node.add_theme_constant_override("outline_size",5)
 caption.get_parent().add_child(node)
 return node
func clear_samples():
 for node in samples:
  if is_instance_valid(node): node.free()
 samples.clear()
 for node in labels: node.free()
 labels.clear()
func pollen(at: Vector3, cluster := false) -> BeePollenPickup:
 var item: BeePollenPickup = (load("res://scenes/items/toon/pollen_cluster.tscn" if cluster else "res://scenes/items/toon/pollen.tscn") as PackedScene).instantiate()
 item.heal_amount=0 # Level 1 contract, not the reusable scene's direct heal.
 stage.add_child(item)
 item.global_position=at
 item.set_deferred("monitoring",false) # Keep samples in view; no collection in this review.
 samples.append(item)
 return item
func _process(delta: float):
 if not measuring or not is_instance_valid(stage): return false
 var bee := stage.bee
 for i in samples.size():
  var item := samples[i] as BeePollenPickup
  if not is_instance_valid(item): continue
  if item.global_position.distance_to(bee.global_position)<.5:
   item.global_position=bee.global_position+Vector3(cos(i)*1.1,sin(i)*1.1,0)
   item.set_meta("pollen_pull_speed",0.0)
  if S.legacy_review:
   var offset := bee.global_position-item.global_position
   var distance := offset.length()
   var speed := BeeLevel01Juice.MAGNET_SPEED*(2-distance/BeeLevel01Juice.MAGNET_RADIUS)
   item.global_position+=offset.normalized()*minf(speed*delta,distance)
  else: M.step(item,bee,delta)
 return false
func sample(seconds: float) -> float:
 var start := Time.get_ticks_usec()
 var count := 0
 while Time.get_ticks_usec()-start<seconds*1000000:
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
 stage.get_node("Juice").set_physics_process(false)
 stage.get_node("LightProgression").set_process(false)
 stage.distance=110
 stage._update_camera_and_bounds()
 stage.bee.set_physics_process(false)
 stage.bee.health.damage_blocked=true
 stage.bee.global_position=Vector3(107,3,0)
 for layer in stage.find_children("*","CanvasLayer",true,false): layer.hide()
 var canvas := CanvasLayer.new()
 canvas.layer=50
 stage.add_child(canvas)
 caption=Label.new()
 caption.position=Vector2(24,22)
 caption.add_theme_font_size_override("font_size",26)
 caption.add_theme_constant_override("outline_size",6)
 canvas.add_child(caption)
 for dark in [false,true]:
  clear_samples()
  stage.get_node("LightProgression").apply_distance(310.0 if dark else 80.0)
  var x := stage.camera.global_position.x
  pollen(Vector3(x-1.8,3.0,0))
  pollen(Vector3(x-1.8,1.2,0),true)
  for y in [3.0,1.2]:
   var shot := stage.bee._spawn_projectile(Vector3.RIGHT)
   shot.global_position=Vector3(x+2, y,0)
   shot.set_physics_process(false)
   samples.append(shot)
  for entry in [["Polen ×1 · hexágono",Vector3(x-3.0,3.8,0)],["Racimo ×10 · mismo valor",Vector3(x-3.0,.45,0)],["Disparos reales de Bee\nsin cambios",Vector3(x+.5,4.05,0)]]:
   labels.append(label(entry[0],stage.camera.unproject_position(entry[1]),22))
  caption.text="%s · COLOR · polen y disparos a escala de juego" % ("NOCHE" if dark else "DÍA")
  await frames(8)
  await RenderingServer.frame_post_draw
  var color := root.get_texture().get_image()
  color.convert(Image.FORMAT_RGBA8)
  caption.text="%s · ESCALA DE GRISES · comparar siluetas" % ("NOCHE" if dark else "DÍA")
  await RenderingServer.frame_post_draw
  var gray := root.get_texture().get_image()
  gray.convert(Image.FORMAT_RGBA8)
  for yy in SIZE.y:
   for xx in SIZE.x:
    var pixel := gray.get_pixel(xx,yy)
    var luminance := pixel.r*.2126+pixel.g*.7152+pixel.b*.0722
    gray.set_pixel(xx,yy,Color(luminance,luminance,luminance,1))
  var result := Image.create(SIZE.x*2,SIZE.y,false,Image.FORMAT_RGBA8)
  result.blit_rect(color,Rect2i(Vector2i.ZERO,SIZE),Vector2i.ZERO)
  result.blit_rect(gray,Rect2i(Vector2i.ZERO,SIZE),Vector2i(SIZE.x,0))
  assert(result.save_png("res://docs/polen_vs_disparos_%s.png" % ("noche" if dark else "dia"))==OK)
 clear_samples()
 if "--capture-only" in OS.get_cmdline_user_args():
  print("T3I_CAPTURE_OK")
  quit()
  return
 stage.get_node("LightProgression").apply_distance(80)
 for i in 6:
  var cloud := preload("res://scenes/levels/asset_fauna/fly_cloud.tscn").instantiate()
  stage.add_child(cloud)
  cloud.global_position=Vector3(110+float(i%3)*2,1.2+float(i/3)*2,0)
  cloud.activate(stage.bee)
  cloud.health.damage_blocked=true # Keep the six clouds present throughout the benchmark.
  cloud.set_physics_process(false) # Same swarm layout in all four measurements.
 stage.bee.global_position=Vector3(106,3,0)
 stage.bee.set_physics_process(true)
 Input.action_press("throw_orange")
 var results := []
 for pass_index in 2:
  for old in ([true,false] if pass_index==0 else [false,true]):
   clear_samples()
   S.legacy_review=old
   for i in 24: pollen(stage.bee.global_position+Vector3(cos(i)*1.1,sin(i)*1.1,0))
   measuring=true
   caption.text="Enjambre · 6 nubes · 24 polen · fuego continuo · %s" % ("ANTES" if old else "AHORA")
   await sample(3.0)
   var fps := await sample(3.0)
   results.append({"pass":pass_index,"old":old,"fps":fps})
   print("T3I_FPS ",results.back())
   measuring=false
 Input.action_release("throw_orange")
 S.legacy_review=false
 FileAccess.open("res://dev/t3i_fps.json",FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
 print("T3I_CAPTURE_OK")
 quit()
