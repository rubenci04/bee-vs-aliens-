@tool
extends "res://scripts/art/future_asset_visual.gd"
## A comparison kit has four removable devices, unlike an individual host.
func _sync_control() -> void:
	for device: Node3D in find_children("AlienControlDevice*","Node3D",true,false):
		if device is MeshInstance3D:
			continue
		device.visible = controlled
