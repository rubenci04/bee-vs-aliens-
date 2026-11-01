extends CanvasLayer
const S := preload("res://scripts/game/bee_flow_settings.gd")
const FADE := preload("res://scripts/game/bee_scene_fade.gd")
var released := 0
var total := 0
var score := 0
var combo := 0
var seconds := 0.0 # Tanda X: tiempo de la partida.
var bombs := 0
var swarms := 0
var hits := 0
var _bee_model: Node3D
var closing := false
func _ready():
 var screen := Control.new()
 screen.name="Results"
 screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(screen)
 var base := ColorRect.new()
 base.color=Color("090f19")
 base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 screen.add_child(base)
 if ResourceLoader.exists(BeeGameSettings.TITLE_BACKGROUND_PATH):
  var background := TextureRect.new()
  background.texture=load(BeeGameSettings.TITLE_BACKGROUND_PATH)
  background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
  background.modulate=Color(.22,.22,.25,1)
  screen.add_child(background)
 var center := CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 screen.add_child(center)
 var panel := PanelContainer.new()
 panel.custom_minimum_size=Vector2(620,0)
 var style := StyleBoxFlat.new()
 style.bg_color=Color(.02,.035,.055,.96)
 style.border_color=Color("c99e4d")
 style.set_border_width_all(2)
 style.set_corner_radius_all(18)
 style.content_margin_left=38
 style.content_margin_right=38
 style.content_margin_top=26
 style.content_margin_bottom=26
 panel.add_theme_stylebox_override("panel",style)
 center.add_child(panel)
 var box := VBoxContainer.new()
 box.add_theme_constant_override("separation",16)
 panel.add_child(box)
 text(box,"NIVEL 1 COMPLETADO",32)
 box.add_child(_bee_view()) # Tanda X: Bee contenta girando.
 # Tanda X: las estadísticas aparecen de a una y el rango llega último, con un golpe de sonido.
 var stats: Array[Label] = []
 stats.append(text(box,"TIEMPO  %d:%02d"%[int(seconds)/60,int(seconds)%60],24))
 stats.append(text(box,"LIBERADOS  %d / %d"%[released,total],24))
 stats.append(text(box,"PUNTAJE  %d"%score,24))
 stats.append(text(box,"MEJOR COMBO  ×%d"%combo,24))
 stats.append(text(box,"BOMBAS  %d  ·  ENJAMBRES  %d"%[bombs,swarms],24))
 stats.append(text(box,"GOLPES RECIBIDOS  %d"%hits,24))
 var rank := text(box,"RANGO  "+S.rank_for(released,total,score),44)
 rank.add_theme_color_override("font_color",Color("ffda76"))
 rank.pivot_offset=Vector2(310,26)
 for label in stats+[rank]: label.modulate.a=0.0
 var reveal := create_tween()
 for label in stats:
  reveal.tween_interval(S.RESULTS_STAT_GAP)
  reveal.tween_property(label,"modulate:a",1.0,0.2)
 reveal.tween_interval(S.RESULTS_STAT_GAP*1.5)
 reveal.tween_callback(func():
  rank.modulate.a=1.0
  rank.scale=Vector2.ONE*1.6
  BeeAudio.play(self,&"bomb")
  var punch := rank.create_tween()
  punch.tween_property(rank,"scale",Vector2.ONE,0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
 var again := Button.new()
 again.text="Jugar de nuevo · R / Enter / A"
 again.custom_minimum_size.y=48
 again.add_theme_font_size_override("font_size",22)
 again.pressed.connect(restart)
 box.add_child(again)
 var menu := Button.new()
 menu.text="Volver al menú · Esc / B"
 menu.set_meta("results_menu",true)
 menu.custom_minimum_size.y=48
 menu.add_theme_font_size_override("font_size",22)
 menu.pressed.connect(to_menu)
 box.add_child(menu)
 again.grab_focus.call_deferred()
func text(parent: Node, value: String, size: int) -> Label:
 var label := Label.new()
 label.text=value
 label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 label.add_theme_font_size_override("font_size",size)
 parent.add_child(label)
 return label
func restart():
 if closing: return
 closing=true
 BeeGameSettings.intro_return_to_title=false
 FADE.go(self,BeeGameSettings.LEVEL_01)
func to_menu():
 if closing: return
 closing=true
 BeeGameSettings.from_title=false
 FADE.go(self,BeeGameSettings.TITLE_SCENE)
func _input(event: InputEvent):
 if event.is_echo(): return
 if event.is_action_pressed("restart") or event.is_action_pressed("ui_accept"):
  get_viewport().set_input_as_handled()
  if event.is_action_pressed("restart") or (event is InputEventKey and event.keycode in [KEY_ENTER,KEY_KP_ENTER]): restart()
  else: accept_focused()
 elif event.is_action_pressed("ui_cancel"):
  get_viewport().set_input_as_handled()
  to_menu()
func _process(delta: float):
 if is_instance_valid(_bee_model): _bee_model.rotation.y+=delta*S.RESULTS_BEE_SPIN # Tanda X: Bee gira.
 if Input.is_action_just_pressed("restart"): restart()
 elif Input.is_action_just_pressed("ui_accept"): accept_focused()
 elif Input.is_action_just_pressed("ui_cancel"): to_menu()
func accept_focused():
 var focus := get_viewport().gui_get_focus_owner()
 if focus!=null and focus.get_meta("results_menu",false): to_menu()
 else: restart()
## Tanda X: Bee girando con cara contenta, en su propio mundo 3D chiquito (no toca el nivel).
func _bee_view() -> Control:
 var holder := SubViewportContainer.new()
 holder.name="BeeView"
 holder.custom_minimum_size=S.RESULTS_BEE_SIZE
 holder.stretch=true
 holder.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
 var view := SubViewport.new()
 view.own_world_3d=true
 view.transparent_bg=true
 view.size=Vector2i(S.RESULTS_BEE_SIZE)
 holder.add_child(view)
 var camera := Camera3D.new()
 camera.position=Vector3(0,0.15,1.9)
 camera.fov=32.0
 view.add_child(camera)
 var light := DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-35,30,0)
 view.add_child(light)
 var scene := load("res://assets/models/shared/bee_hero/shared_hero_bee_v02.glb") as PackedScene
 if scene != null:
  _bee_model=scene.instantiate() as Node3D
  view.add_child(_bee_model)
  BeeToonStyle.apply(_bee_model,true,BeeToonStyle.OUTLINE_BEE)
  var faces := preload("res://scripts/bee_prototype/bee_expressions.gd").new()
  faces.bind(_bee_model)
  if faces.is_bound(): faces.set_face_now(&"happy")
  for player: AnimationPlayer in _bee_model.find_children("*","AnimationPlayer",true,false):
   if player.has_animation(&"wingbeat"):
    player.get_animation(&"wingbeat").loop_mode=Animation.LOOP_LINEAR
    player.play(&"wingbeat")
 return holder
