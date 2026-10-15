extends Node3D
## Visual companion; reads the real laser phase, never changes attack timers/physics.
const S := preload("res://scripts/vfx/bee_boss_effect_settings.gd")
var robot: WalkerMiniboss
var charge: MeshInstance3D
var sparks: CPUParticles3D
var beam_material: ShaderMaterial
var burn_left := 0.0
var burn: MeshInstance3D
func _ready() -> void:
 charge = MeshInstance3D.new()
 charge.name = "LaserChargeSphere"
 var ball := SphereMesh.new()
 ball.radius = 1
 ball.height = 2
 ball.radial_segments = 12
 ball.rings = 6
 var glow := BeeAttackVisuals.material(Color(.18,.8,1,.65)).duplicate() as StandardMaterial3D
 glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
 glow.emission_enabled = true
 glow.emission = Color(.05,.65,1)
 glow.emission_energy_multiplier = 1.6
 ball.material = glow
 charge.mesh = ball
 add_child(charge)
 charge.top_level = true
 sparks = CPUParticles3D.new()
 sparks.name = "LaserContactSparks"
 sparks.amount = S.SPARK_AMOUNT
 sparks.lifetime = .16
 sparks.direction = Vector3.UP
 sparks.spread = 65
 sparks.gravity = Vector3(0,-2,0)
 sparks.initial_velocity_min = .5
 sparks.initial_velocity_max = 1.4
 sparks.scale_amount_min = .4
 sparks.scale_amount_max = .8
 var dot := SphereMesh.new()
 dot.radius = .025
 dot.height = .05
 dot.radial_segments = 4
 dot.rings = 2
 dot.material = BeeAttackVisuals.material(Color(.7,.95,1,.8))
 sparks.mesh = dot
 add_child(sparks)
 sparks.top_level = true
 sparks.emitting = false
func dress_beam() -> void:
 var quad := QuadMesh.new()
 quad.size = Vector2(WalkerMiniboss.LASER_LENGTH,S.BEAM_WIDTH)
 robot._beam.mesh = quad
 robot._beam.scale = Vector3.ONE
 robot._beam.set_meta("boss_visual_only",true)
 beam_material = S.beam_material()
 robot._beam.material_override = beam_material
 for child in robot._beam.get_children():
  if child is MeshInstance3D: child.hide()
func _process(delta: float) -> void:
 if not is_instance_valid(robot): return
 charge.visible = robot._step == &"laser_tele" and robot.current_state != robot.State.DEAD
 if charge.visible:
  charge.global_position = robot.laser_origin
  charge.scale = Vector3.ONE*lerpf(S.CHARGE_MIN,S.CHARGE_MAX,clampf(1.0-robot._left/robot.LASER_WARNING,0,1))
  for warning in robot._warnings:
   warning.visible = robot._left <= S.WARNING_SECONDS
 # The DEV readability pass may duplicate this material for its outline.
 # Always update the material actually displayed, rather than an old copy.
 beam_material = robot._beam.material_override as ShaderMaterial
 if beam_material != null: beam_material.set_shader_parameter("variant",float(S.mode))
 var active := robot._step == &"laser_sweep" and robot._beam.visible
 sparks.emitting = active
 if active:
  var direction := robot._beam_pivot.global_basis.x
  var origin := robot.laser_origin
  var length := robot.LASER_LENGTH
  var ground := false
  if direction.y < -.001:
   var distance := (.03-origin.y)/direction.y
   if distance >= 0 and distance <= length:
    length = distance
    ground = true
  var tip := origin+direction*length
  sparks.global_position = tip
  if ground and burn_left <= 0:
   burn_left = S.BURN_SECONDS
   burn = S.marker(get_parent(),tip+Vector3(0,0,.08),.65,.18,S.BURN_SECONDS,false,1.0,false)
   burn.name = "BriefGroundScorch"
   burn.material_override.set_shader_parameter("opacity",.3)
   burn.material_override.set_shader_parameter("tint",Color(.12,.08,.06,1))
   burn.create_tween().tween_property(burn.material_override,"shader_parameter/opacity",0.0,S.BURN_SECONDS)
   get_tree().create_timer(S.BURN_SECONDS).timeout.connect(burn.queue_free)
 burn_left = maxf(0,burn_left-delta)
func _exit_tree() -> void:
 if is_instance_valid(burn): burn.queue_free()
