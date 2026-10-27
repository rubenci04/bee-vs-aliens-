extends CanvasLayer
const S := preload("res://scripts/game/bee_flow_settings.gd")
var shade: ColorRect
var leaving := false
var animation: Tween
func _ready():
 name="SceneFade"
 layer=100
 process_mode=Node.PROCESS_MODE_ALWAYS
 shade=ColorRect.new()
 shade.color=Color.BLACK
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shade.mouse_filter=Control.MOUSE_FILTER_STOP
 add_child(shade)
static func enter(from: Node):
 var root := from.get_tree().root
 if root.has_node("SceneFade"): return
 var cover := new()
 root.add_child(cover)
 cover.animation=cover.create_tween()
 cover.animation.tween_property(cover.shade,"color:a",0.0,S.FADE_SECONDS)
 cover.animation.tween_callback(func():
  if not cover.leaving: cover.queue_free())
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
 await get_tree().process_frame # Present a black frame before synchronous loading.
 if path == BeeGameSettings.LEVEL_01: BeeGameSettings.level_intro_pending = true
 var error := get_tree().change_scene_to_file(path)
 if error!=OK: push_error("Scene transition failed: "+path)
 await get_tree().process_frame
 await get_tree().process_frame
 var tween := create_tween()
 tween.tween_property(shade,"color:a",0.0,S.FADE_SECONDS)
 tween.tween_callback(queue_free)
