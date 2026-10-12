extends "res://scripts/art/future_asset_visual.gd"
## Visual-only reusable sky animal. No combat, collision or autonomous movement.
enum FlightPose { FLAP, GLIDE, DIVE }
@export var animate_wings := true
@export var flight_pose: FlightPose = FlightPose.FLAP
var phase := 0.0
var wing_pivots: Array[Node3D] = []
var wing_rest: Array[Vector3] = []

func _ready() -> void:
	super._ready()
	for side in [-1, 1]:
		var wing := find_child("EagleWing_"+str(side), true, false) as Node3D
		if wing != null:
			wing_pivots.append(wing)
			wing_rest.append(wing.rotation)
	seek(0.0)

func _process(delta: float) -> void:
	if animate_wings:
		seek(phase+delta)

func seek(seconds: float) -> void:
	phase = maxf(0.0, seconds)
	for i in wing_pivots.size():
		var side := -1.0 if i == 0 else 1.0
		var angle := sin(phase*TAU*1.15)*0.42 if flight_pose == FlightPose.FLAP else 0.0
		var offset := Vector3(side*angle,0,0)
		if flight_pose == FlightPose.DIVE:
			# Sweep both wings toward the tail, rather than merely raising them.
			offset = Vector3(side*0.10,-side*0.90,0)
		wing_pivots[i].rotation = wing_rest[i]+offset

func set_flight_pose(value: FlightPose) -> void:
	flight_pose = value
	seek(phase)
