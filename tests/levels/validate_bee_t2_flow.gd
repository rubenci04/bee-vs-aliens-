extends SceneTree
const S := preload("res://scripts/game/bee_flow_settings.gd")
var failed := false
func _initialize(): call_deferred("run")
func check(ok: bool, message: String):
 if not ok: failed=true; push_error(message)
func frames(n: int):
 for i in n: await physics_frame
func run():
 root.size=Vector2i(1154,648)
 var title := preload("res://scenes/game/bee_title_screen.tscn").instantiate()
 root.add_child(title)
 current_scene=title
 await frames(20)
 check(title.debug_menu_enabled()==preload("res://scripts/game/bee_readability_settings.gd").development_enabled(),"Menu debug shares export-safe development gate")
 var tagline: Control=title.get_node("Tagline")
 var panel: Control=title.get_node("MenuPanel")
 var logo: Control=title.get_node("Logo")
 check(not tagline.get_global_rect().intersects(panel.get_global_rect()) and not tagline.get_global_rect().intersects(logo.get_global_rect()),"Subtitle has its own space below logo and above menu")
 check(ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color")==Color.BLACK,"Default clear is black")
 title.queue_free()
 await frames(2)
 var intro := preload("res://scenes/game/bee_intro_screen.tscn").instantiate()
 root.add_child(intro)
 current_scene=intro
 intro.set_process(false)
 for i in 5:
  intro._set_slide(i)
  var typing := BeeGameSettings.INTRO_TYPEWRITER_DELAY+float(intro.caption.get_total_character_count())/BeeGameSettings.INTRO_TYPEWRITER_CHARS_PER_SECOND
  check(intro.current_duration>=typing+S.INTRO_READ_HOLD-.001,"Every subtitle has time to finish and be read")
  intro._process(intro.current_duration-.02)
  check(intro.caption.visible_characters==intro.caption.get_total_character_count(),"Subtitle complete before image transition")
 intro.queue_free()
 await frames(2)
 var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
 root.add_child(stage)
 current_scene=stage
 await frames(20)
 stage.set_physics_process(false)
 stage.wave.set_physics_process(false)
 stage.get_node("Juice").score=135040
 stage.get_node("Juice").best_combo=185
 stage.wave.liberated_count=326
 stage.wave.animals_total=454
 stage.sector_complete=true
 stage._physics_process(.016)
 var result := stage.get_node("ResultsScreen")
 check(result.released==326 and result.score==135040 and result.combo==185,"Result scene snapshots actual final data")
 check(not stage.bee.visible and not stage.get_node("CanvasLayer").visible and not stage.clear_banner.visible,"World Bee and old HUD/closing texts hidden")
 check(S.rank_for(326,454,135040)=="A","Observed run gets A by both thresholds")
 check(S.rank_for(85,100,100000)=="S" and S.rank_for(85,100,99999)=="A","S requires percentage and score, inclusive thresholds")
 check(S.rank_for(40,100,25000)=="B" and S.rank_for(0,0,100000)=="C","B/C and zero totals handled")
 var event := InputEventAction.new()
 event.action="ui_accept"
 event.pressed=true
 result._input(event)
 await frames(40)
 check(current_scene.scene_file_path==BeeGameSettings.LEVEL_01,"Enter/A replays level directly, without intro")
 current_scene.set_physics_process(false)
 current_scene.wave.set_physics_process(false)
 current_scene.sector_complete=true
 current_scene._physics_process(.016)
 result=current_scene.get_node("ResultsScreen")
 event.action="ui_cancel"
 result._input(event)
 await frames(40)
 check(current_scene.scene_file_path==BeeGameSettings.TITLE_SCENE and not paused,"Esc/B returns to menu without pausing")
 check(not preload("res://scripts/game/bee_readability_settings.gd").development_for(false,true,true),"Standalone debug export hides development controls too")
 print("T2_FLOW_OK failed=",failed)
 quit(1 if failed else 0)
