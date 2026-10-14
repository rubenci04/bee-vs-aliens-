extends Node
const S := preload("res://scripts/game/bee_sting_settings.gd")
enum Phase { OUT, IMPACT, RECOIL }
var bee: BeePlayer
var active := false
var phase := Phase.OUT
var left := 0.0
var direction := Vector3.RIGHT
var dash_velocity := Vector3.ZERO
var prior_invulnerable := false
var queued_roll := false
var queued_sting := false

func begin() -> bool:
	if active: return false
	if bee.is_rolling:
		queued_sting = true
		return false
	bee.melee_target = bee.nearest_melee_target()
	direction = bee.aim_direction().normalized()
	var travel := S.EMPTY_DISTANCE
	if is_instance_valid(bee.melee_target):
		var to_target := bee._target_point(bee.melee_target) - bee.global_position
		to_target.z = 0
		direction = to_target.normalized() if to_target.length() > .01 else direction
		travel = maxf(0,to_target.length()-S.STOP_DISTANCE)
		bee.melee_lunge_count += 1
	active = true
	phase = Phase.OUT
	left = S.DASH_SECONDS
	dash_velocity = direction * travel / S.DASH_SECONDS
	prior_invulnerable = bee.health.invulnerable
	bee.health.invulnerable = true
	bee.melee_hitbox.set_enabled(false)
	bee.melee_count += 1
	if bee._turn_tween != null: bee._turn_tween.kill()
	if bee._roll_tween != null: bee._roll_tween.kill()
	if absf(direction.x) > .01: bee.facing_x = signf(direction.x)
	bee.visual_root.rotation = Vector3(0,-bee.facing_x*PI*.5,atan2(direction.y,direction.x)-(PI if bee.facing_x < 0 else 0.0))
	bee._show_stinger(direction)
	bee.get_node("VisualRoot/BeeVisual").start_drill_attack()
	bee.melee_started.emit()
	return true

func step(delta: float) -> void:
	if not active: return
	var used := minf(delta,maxf(left,0))
	if phase in [Phase.OUT,Phase.RECOIL]:
		bee.velocity = dash_velocity
		# Use CharacterBody movement and existing bounds, never teleport the hitbox to the target.
		bee.velocity *= used/maxf(delta,.00001)
		bee.move_and_slide()
		bee.position.x = clampf(bee.position.x,bee.flight_min.x,bee.flight_max.x)
		bee.position.y = clampf(bee.position.y,bee.flight_min.y,bee.flight_max.y)
		bee.position.z = 0
	bee.melee_hitbox.global_position = bee.global_position + direction*S.STOP_DISTANCE
	left -= delta
	if left > 0: return
	if phase == Phase.OUT:
		phase = Phase.IMPACT
		left = S.IMPACT_SECONDS
		bee.velocity = Vector3.ZERO
		if is_instance_valid(bee.melee_target) and bee.global_position.distance_to(bee._target_point(bee.melee_target)) <= S.STOP_DISTANCE+S.CONTACT_ALLOWANCE:
			bee.melee_hitbox.damage = bee.melee_damage
			bee.melee_hitbox.set_enabled(true)
	elif phase == Phase.IMPACT:
		bee.melee_hitbox.set_enabled(false)
		phase = Phase.RECOIL
		left = S.RECOIL_SECONDS
		dash_velocity = -direction*S.RECOIL_DISTANCE/S.RECOIL_SECONDS
	else:
		finish()

func finish() -> void:
	active = false
	bee.velocity = Vector3.ZERO
	bee.melee_hitbox.set_enabled(false)
	bee.melee_target = null
	bee._hide_stinger()
	bee.visual_root.rotation.z = 0
	bee.health.invulnerable = prior_invulnerable
	bee._place_melee_hitbox()
	if queued_roll and bee.start_roll():
		queued_roll = false
