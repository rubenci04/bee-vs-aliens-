extends GiantHumanCrossingHazard

const SAFE_HALF_WIDTH := 1.2
@onready var skeleton: Skeleton3D = $VisualRoot/Hipster/Rig/Skeleton3D

# Keep the level's generous central route independent of the Run stride.
# The old static boxes swept empty space instead of following the feet.
# Clip each animated lower-leg envelope to the outside of the safe corridor.
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if current_phase != Phase.CROSSING:
		return
	for side in ["L", "R"]:
		var foot := to_local(skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("foot_" + side)).origin)
		var calf := to_local(skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("calf_" + side)).origin)
		var collider: CollisionShape3D = $ContactHitbox.get_node("LeftLeg" if side == "L" else "RightLeg")
		var left := minf(foot.x, calf.x) - 0.45
		var right := maxf(foot.x, calf.x) + 0.45
		if foot.x < 0.0:
			right = minf(right, -SAFE_HALF_WIDTH)
		else:
			left = maxf(left, SAFE_HALF_WIDTH)
		collider.set_deferred("disabled", right <= left)
		if right <= left:
			continue
		var shape := collider.shape as BoxShape3D
		shape.size = Vector3(right - left, 2.9, 3.0)
		collider.position = Vector3((left + right) * 0.5, 1.45, 0)

# The reused Hipster model has bright white SoleL/SoleR slabs. At 6x scale
# they read as rectangular plates beneath the boots. Boots already reach Y=0,
# so hide only these level-instance slabs; keep GLB, rig, Run and hitboxes intact.
func _ready() -> void:
	super._ready()
	# Each shape is resized separately as its own animated leg moves.
	for part in ["LeftLeg", "RightLeg"]:
		var collider: CollisionShape3D = $ContactHitbox.get_node(part)
		collider.shape = collider.shape.duplicate()
	for name in ["SoleL", "SoleR"]:
		var sole := get_node_or_null("VisualRoot/Hipster/Rig/Skeleton3D/" + name) as MeshInstance3D
		if sole == null:
			push_error("Level 01 human sole missing: " + name)
			continue
		sole.hide()
