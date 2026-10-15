extends SceneTree
const SIZE := Vector2i(1154,648)
func _initialize(): call_deferred("run")
func frames(n: int):
 for i in n: await physics_frame
func take(result: Image, index: int):
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 picture.convert(Image.FORMAT_RGBA8)
 result.blit_rect(picture,Rect2i(Vector2i.ZERO,SIZE),Vector2i(index%2,index/2)*SIZE)
func run():
 root.size=SIZE
 var result := Image.create(SIZE.x*2,SIZE.y*2,false,Image.FORMAT_RGBA8)
 var title := preload("res://scenes/game/bee_title_screen.tscn").instantiate()
 root.add_child(title)
 current_scene=title
 await frames(75)
 # Export-facing menu: same scene, hide the development-only lake control for this panel.
 for button in title.find_children("*","Button",true,false):
  if button.text.begins_with("Laguna"): button.hide()
 await frames(2)
 await take(result,0)
 title._toggle_options()
 await frames(3)
 await take(result,1)
 title.queue_free()
 await frames(2)
 var intro := preload("res://scenes/game/bee_intro_screen.tscn").instantiate()
 root.add_child(intro)
 current_scene=intro
 intro.set_process(false)
 intro._set_slide(1)
 intro.caption.visible_characters=-1
 await frames(30)
 await take(result,2)
 intro.queue_free()
 await frames(2)
 var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
 root.add_child(stage)
 current_scene=stage
 await frames(30)
 stage.set_physics_process(false)
 stage.wave.set_physics_process(false)
 stage.get_node("Juice").score=135040
 stage.get_node("Juice").best_combo=185
 stage.wave.liberated_count=326
 stage.wave.animals_total=454
 stage.sector_complete=true
 stage._physics_process(.016)
 await frames(5)
 await take(result,3)
 assert(result.save_png("res://docs/menu_y_resultados.png")==OK)
 print("T2_CAPTURE_OK")
 quit()
