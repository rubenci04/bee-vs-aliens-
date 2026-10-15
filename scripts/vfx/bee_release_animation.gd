extends Node
const S := preload("res://scripts/game/bee_release_settings.gd")
const TOON_INCLUDE := preload("res://assets/style/toon_common.gdshaderinc")
static var shaders := {}
var actor: Node3D
var visual: Node3D
var finished: Callable
var materials: Array[Material] = []
var elapsed := 0.0
var start: Vector3
var rotation_start: Vector3
var full := false
static func start_release(unit: Node3D, model: Node3D, done: Callable) -> Node:
 if S.legacy_review:
  unit.set_physics_process(false)
  var away := unit.create_tween()
  away.tween_property(unit,"position",unit.position+Vector3(-6,3.2,0),3.0)
  away.tween_callback(done)
  return unit
 var animation := new()
 animation.actor=unit
 animation.visual=model
 animation.finished=done
 unit.add_child(animation)
 return animation
static func spark(host: Node, at: Vector3, simple: bool):
 if host.get_tree().get_nodes_in_group("bee_release_sparks").size()>=S.SPARK_LIMIT: return
 var particles := CPUParticles3D.new()
 particles.name="ImplantSparks"
 particles.add_to_group("bee_release_sparks")
 particles.emitting=false
 particles.one_shot=true
 particles.amount=S.SIMPLE_SPARKS if simple else S.SPARKS
 particles.lifetime=S.SPARK_SECONDS
 particles.explosiveness=1
 particles.direction=Vector3.UP
 particles.spread=180
 particles.initial_velocity_min=1.3
 particles.initial_velocity_max=2.8
 particles.gravity=Vector3.ZERO
 particles.scale_amount_min=.7
 particles.scale_amount_max=1.0
 var mesh := SphereMesh.new()
 mesh.radius=S.SPARK_RADIUS
 mesh.height=S.SPARK_RADIUS*2
 mesh.radial_segments=4
 mesh.rings=2
 var mat := StandardMaterial3D.new()
 mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 mat.albedo_color=S.SPARK_COLOR
 mesh.material=mat
 particles.mesh=mesh
 particles.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 host.add_child(particles)
 particles.global_position=at
 particles.restart()
 particles.emitting=true
 particles.finished.connect(particles.queue_free)
func fade_material(source: Material) -> Material:
 if source==null: return null
 var own := source.duplicate() as Material
 if own is ShaderMaterial:
  var key: int = own.shader.get_instance_id()
  if not shaders.has(key):
   var shader := Shader.new()
   var code: String=own.shader.code.replace('#include "res://assets/style/toon_common.gdshaderinc"',TOON_INCLUDE.code)
   var alpha := RegEx.new()
   alpha.compile("ALPHA\\s*=\\s*([^;]+);")
   code=alpha.sub(code,"ALPHA = liberation_alpha * ($1);",true)
   code=code.replace("void fragment() {","uniform float liberation_alpha = 1.0;\nvoid fragment() {\n ALPHA = liberation_alpha;")
   shader.code=code
   shaders[key]=shader
  own.shader=shaders[key]
 elif own is BaseMaterial3D:
  own.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 materials.append(own)
 own.next_pass=fade_material(source.next_pass)
 return own
func _ready():
 full=get_tree().get_nodes_in_group("bee_release_full").size()<S.FULL_LIMIT
 if full: add_to_group("bee_release_full")
 actor.set_physics_process(false)
 actor.set_process(false)
 actor.remove_from_group("bee_auto_aim_targets")
 for glow in actor.find_children("HostileGlow","Node3D",true,false): glow.hide()
 var flash := actor.get_node_or_null("HitFlash3D")
 if flash!=null: flash.cancel()
 for area in actor.find_children("*","CollisionObject3D",true,false):
  area.set_deferred("collision_layer",0)
  area.set_deferred("collision_mask",0)
  if area is DamageHitbox3D: area.set_enabled(false)
  if area is Area3D:
   area.set_deferred("monitoring",false)
   area.set_deferred("monitorable",false)
 if actor is CollisionObject3D:
  actor.set_deferred("collision_layer",0)
  actor.set_deferred("collision_mask",0)
 start=actor.position
 rotation_start=actor.rotation
 for mesh in visual.find_children("*","MeshInstance3D",true,false):
  mesh.material_overlay=null
  if mesh.material_override!=null:
   mesh.material_override=fade_material(mesh.material_override)
  else:
   for surface in mesh.mesh.get_surface_count():
    mesh.set_surface_override_material(surface,fade_material(mesh.get_active_material(surface)))
func _process(delta: float):
 elapsed+=delta
 var t := clampf(elapsed/S.SECONDS,0,1)
 if full:
  actor.position=start+S.DEPARTURE*t*t
  actor.rotation=rotation_start+Vector3(0,sin(t*PI)*S.TURN,sin(t*PI)*S.TURN*.5)
 var alpha := 1.0-clampf((elapsed-S.FADE_START)/(S.SECONDS-S.FADE_START),0,1)
 for mat in materials:
  if mat is ShaderMaterial: mat.set_shader_parameter("liberation_alpha",alpha)
  elif mat is BaseMaterial3D:
   var c: Color=mat.albedo_color
   c.a=alpha
   mat.albedo_color=c
 if t>=1:
  actor.hide()
  remove_from_group("bee_release_full")
  finished.call()
  queue_free()
