extends SceneTree
const S := preload("res://scripts/game/bee_release_settings.gd")
const A := preload("res://scripts/vfx/bee_release_animation.gd")
var failed := false
func _initialize(): call_deferred("run")
func check(ok: bool, text: String):
 if not ok: failed=true; push_error(text)
func frames(n: int):
 for i in n: await physics_frame
func run():
 var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
 root.add_child(stage)
 current_scene=stage
 await frames(5)
 stage.set_physics_process(false)
 stage.wave.set_physics_process(false)
 stage.get_node("CheckpointQoL").set_process(false)
 stage.get_node("Juice").set_physics_process(false)
 stage.distance=110
 stage._update_camera_and_bounds()
 var bee: BeePlayer=stage.bee
 bee.global_position=Vector3(108,3,0)
 bee.set_physics_process(false)
 var actors: Array[AssetFauna]=[]
 var done := [0]
 for i in 14:
  var actor := preload("res://scenes/levels/asset_fauna/fly_common.tscn").instantiate()
  stage.add_child(actor)
  actor.global_position=Vector3(112,3,0)
  actor.activate(bee)
  actor.defeated.connect(func(_actor): done[0]+=1)
  actors.append(actor)
  actor.health.take_damage(10000)
 check(get_nodes_in_group("bee_release_full").size()==12,"Full departures capped at 12")
 check(get_nodes_in_group("bee_release_sparks").size()<=S.SPARK_LIMIT,"Spark emitters bounded")
 check(get_nodes_in_group("bee_liberated_text").size()<=2,"T1b individual label limit kept")
 var first := actors[0]
 var start := first.position
 var simple_start := actors[13].position
 await frames(12)
 check(first.position.z < start.z and absf(first.rotation.y)>.01,"Freed insect turns and retreats in Z")
 check(actors[13].position==simple_start,"Over limit only spark/fade; no extra animated flight")
 for actor in actors:
  check(not actor.is_active(),"Released enemies no longer attack")
  for area in actor.find_children("*","Area3D",true,false):
   check(area.collision_layer==0 and area.collision_mask==0 and not area.monitoring and not area.monitorable,"No collision or damage throughout release")
 var animations := first.get_children().filter(func(n): return n.get_script()==A)
 check(animations.size()==1,"Uses shared release controller")
 var controller=animations[0]
 check(controller.materials.size()>0,"Body and outline materials prepared for fade")
 for mat in controller.materials:
  if mat is ShaderMaterial:
   check(mat.get_shader_parameter("liberation_alpha")!=null,"Fade also applies to outline shader")
 await frames(39)
 check(done[0]==14 and not first.visible and not actors[13].visible,"All departures finish within 0.8 s plus frame resolution")
 check(get_nodes_in_group("bee_release_full").is_empty(),"Full animation slots returned")
 check(get_nodes_in_group("bee_release_sparks").is_empty(),"Short spark emitters retire instead of accumulating")
 var stop=preload("res://scripts/vfx/bee_local_hit_stop.gd").for_host(bee)
 var shot: BeeEnergyProjectile=bee._spawn_projectile(Vector3.RIGHT)
 shot.global_position=bee.global_position+Vector3(.8,0,0)
 var far: BeeEnergyProjectile=bee._spawn_projectile(Vector3.RIGHT)
 far.global_position=bee.global_position+Vector3(5,0,0)
 var origin := shot.global_position
 var health := bee.health.current_health
 var timer := Timer.new()
 timer.wait_time=.025
 timer.one_shot=true
 stage.add_child(timer)
 var timer_done := [false]
 timer.timeout.connect(func(): timer_done[0]=true)
 timer.start()
 check(not BeeJuice.key_event(bee,&"regular_hit"),"No stop on bullets, liberations or ordinary damage")
 check(BeeJuice.key_event(bee,&"roll_shot"),"Roll shot event accepted")
 check(not shot.is_physics_processing() and far.is_physics_processing(),"Only nearby projectiles stopped")
 check(Engine.time_scale==1 and not paused,"No global time or pause changes")
 check(not BeeJuice.key_event(bee,&"sting"),"Shared cooldown blocks another event")
 await frames(2)
 check(shot.global_position==origin,"Nearby projectile remains still during stop")
 await frames(5)
 check(timer_done[0],"Warning timers outside the local actors continue normally")
 check(stop.saved.is_empty() and shot.is_physics_processing(),"Movement processing restored after 0.05 s")
 check(not bee.is_physics_processing(),"Originally disabled processing remains disabled")
 check(bee.health.current_health==health,"No damage/health changes from presentation")
 await frames(28)
 S.enabled=false
 check(not BeeJuice.key_event(bee,&"boss_armour"),"Development toggle disables stop")
 S.enabled=true
 check(BeeJuice.key_event(bee,&"boss_armour"),"Boss armour event accepted after cooldown")
 await frames(5)
 var old := BeeJuice.hit_stops
 var robot := preload("res://scenes/levels/walker_miniboss.tscn").instantiate()
 stage.add_child(robot)
 robot.activate(bee)
 robot.set_physics_process(false)
 await frames(30)
 robot._break_cannon()
 check(BeeJuice.hit_stops==old+1,"Actual Robot cannon rupture hooks approved event")
 await frames(5)
 check(not robot.is_physics_processing(),"Restore never activates a fixture that was already frozen")
 await frames(30)
 bee._roll_cooldown_left=0
 bee.start_roll()
 var roll_count := BeeJuice.hit_stops
 bee.absorb_shot()
 check(BeeJuice.hit_stops==roll_count+1,"Actual roll projectile-break callback hooks approved event")
 await frames(6)
 check(bee._roll_tween==null or bee._roll_tween.is_running(),"Roll visual tween resumes after microfreeze")
 stage.get_node("CanvasLayer/WeaponsHUD").debug_visible = true # Tanda A: comparators require F3.
 var live=stage.get_node("LiveReadability") if stage.has_node("LiveReadability") else null
 var event := InputEventKey.new()
 event.keycode=S.HIT_STOP_KEY
 event.pressed=true
 var development := preload("res://scripts/game/bee_readability_settings.gd").development_enabled()
 var previous := S.enabled
 live._unhandled_key_input(event)
 check(S.enabled == (not previous if development else previous),"Key toggles only in development")
 live.enabled=false
 var before_key := S.enabled
 live._unhandled_key_input(event)
 check(S.enabled==before_key,"Export/non-development handler ignores key")
 live.enabled=development
 S.enabled=true
 check(S.HIT_STOP_KEY==KEY_O,"Development key O, no F keys")
 var map_conflict := false
 for action in InputMap.get_actions():
  for binding in InputMap.action_get_events(action):
   if binding is InputEventKey and not binding.ctrl_pressed and not binding.alt_pressed and not binding.shift_pressed:
    if binding.keycode==S.HIT_STOP_KEY or binding.physical_keycode==S.HIT_STOP_KEY: map_conflict=true
 check(not map_conflict,"O is free in Input Map")
 var warnings_done := [false]
 var warning_timer := Timer.new()
 warning_timer.wait_time=.03
 warning_timer.one_shot=true
 robot.add_child(warning_timer)
 warning_timer.timeout.connect(func(): warnings_done[0]=true)
 await frames(31)
 warning_timer.start()
 check(BeeJuice.key_event(bee,&"sting",robot),"Targeted local event accepted")
 await frames(6)
 check(warnings_done[0],"Even a timer inside the target continues during local motion freeze")
 await frames(31)
 bee.is_rolling=false
 bee.sting_dash.active=true
 var stings := BeeJuice.hit_stops
 bee._on_melee_impact(robot.cannon_hurtbox,1)
 check(BeeJuice.hit_stops==stings+1,"Actual successful sting callback hooks local event")
 bee.sting_dash.active=false
 await frames(6)
 var tarantula := preload("res://scenes/levels/tarantula_boss_01.tscn").instantiate()
 stage.add_child(tarantula)
 tarantula.begin(stage.camera,bee)
 tarantula.set_physics_process(false)
 var boss_finished := [0]
 tarantula.defeated.connect(func(_boss): boss_finished[0]+=1)
 tarantula._free_tarantula()
 await frames(51)
 check(boss_finished[0]==1 and not is_instance_valid(tarantula),"Boss liberation completes its original finish callback exactly once after the short departure")
 print("T4F_OK failed=",failed)
 quit(1 if failed else 0)
