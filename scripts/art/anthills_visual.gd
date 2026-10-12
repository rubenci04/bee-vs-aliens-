@tool
extends Node3D
const OUTLINE := BeeToonStyle.OUTLINE_PROP
func _ready() -> void:
	BeeToonStyle.apply(self, true, OUTLINE)
