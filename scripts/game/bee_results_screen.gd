extends CanvasLayer
const S := preload("res://scripts/game/bee_flow_settings.gd")
const FADE := preload("res://scripts/game/bee_scene_fade.gd")
var released := 0
var total := 0
var score := 0
var combo := 0
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
 var rank := text(box,"RANGO  "+S.rank_for(released,total,score),44)
 rank.add_theme_color_override("font_color",Color("ffda76"))
 text(box,"LIBERADOS  %d / %d"%[released,total],25)
 text(box,"PUNTAJE  %d"%score,25)
 text(box,"MEJOR COMBO  ×%d"%combo,25)
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
func _process(_delta: float):
 if Input.is_action_just_pressed("restart"): restart()
 elif Input.is_action_just_pressed("ui_accept"): accept_focused()
 elif Input.is_action_just_pressed("ui_cancel"): to_menu()
func accept_focused():
 var focus := get_viewport().gui_get_focus_owner()
 if focus!=null and focus.get_meta("results_menu",false): to_menu()
 else: restart()
