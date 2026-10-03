class_name ToonStyledVisual
extends Node
## Applies BeeToonStyle (style C) to a visual subtree when the scene starts. Presentation only.

@export var target: NodePath = ^"../VisualRoot"
@export var outline := true
@export var outline_width := BeeToonStyle.OUTLINE_ACTOR # Scenes using this are actors (enemies); props pass OUTLINE_PROP.


func _ready() -> void:
	var root := get_node_or_null(target)
	assert(root != null, "ToonStyledVisual target missing")
	BeeToonStyle.apply(root, outline, outline_width)
