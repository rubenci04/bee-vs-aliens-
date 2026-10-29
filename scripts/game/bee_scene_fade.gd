extends CanvasLayer
const S := preload("res://scripts/game/bee_flow_settings.gd")
var shade: ColorRect
var leaving := false
var animation: Tween
var loading_label: Label
func _ready():
 name="SceneFade"
 layer=100
 process_mode=Node.PROCESS_MODE_ALWAYS
 shade=ColorRect.new()
 shade.color=Color.BLACK
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shade.mouse_filter=Control.MOUSE_FILTER_STOP
 add_child(shade)
 if BeeGameSettings.LOADING_LABEL_ENABLED:
  loading_label=Label.new()
  loading_label.text=BeeGameSettings.LOADING_LABEL_TEXT
  loading_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
  loading_label.offset_left=-BeeGameSettings.LOADING_LABEL_SIZE.x*0.5
  loading_label.offset_right=BeeGameSettings.LOADING_LABEL_SIZE.x*0.5
  loading_label.offset_top=-BeeGameSettings.LOADING_LABEL_SIZE.y*0.5
  loading_label.offset_bottom=BeeGameSettings.LOADING_LABEL_SIZE.y*0.5
  loading_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  loading_label.add_theme_font_size_override("font_size",BeeGameSettings.LOADING_LABEL_FONT_SIZE)
  loading_label.hide()
  add_child(loading_label)
static func enter(from: Node):
 var root := from.get_tree().root
 if root.has_node("SceneFade"): return
 var cover := new()
 cover.ready.connect(cover._start_enter_animation, CONNECT_ONE_SHOT)
 root.add_child.call_deferred(cover)
func _start_enter_animation():
 animation=create_tween()
 animation.tween_property(shade,"color:a",0.0,S.FADE_SECONDS)
 animation.tween_callback(func():
  if not leaving: queue_free())
static func go(from: Node, path: String):
 var tree := from.get_tree()
 var cover=tree.root.get_node_or_null("SceneFade")
 if cover!=null and cover.leaving: return
 if cover==null:
  cover=new()
  tree.root.add_child(cover)
  cover.shade.color.a=0
 cover.leaving=true
 if cover.animation!=null and cover.animation.is_valid(): cover.animation.kill()
 var tween := cover.create_tween()
 tween.tween_property(cover.shade,"color:a",1.0,S.FADE_SECONDS)
 tween.tween_callback(func(): cover.change(path))
func change(path: String):
 get_tree().paused=false
 if loading_label!=null: loading_label.show()
 await get_tree().process_frame
 await get_tree().process_frame # El aviso alcanza a dibujarse antes de la carga síncrona.
 if path == BeeGameSettings.LEVEL_01: BeeGameSettings.level_intro_pending = true
 var error := get_tree().change_scene_to_file(path)
 if error!=OK: push_error("Scene transition failed: "+path)
 await get_tree().process_frame
 await get_tree().process_frame
 if loading_label!=null: loading_label.hide()
 var tween := create_tween()
 tween.tween_property(shade,"color:a",0.0,S.FADE_SECONDS)
 tween.tween_callback(queue_free)
