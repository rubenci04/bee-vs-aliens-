extends RefCounted
## T3k presentation only. Review tools can display the previous T3h appearance.
const KEY := KEY_K
const DEFAULT_MODE := 0
const BEAM_WIDTH := 0.3
const CORE_FRACTION := 0.25
const WARNING_SECONDS := 0.3
const WARNING_ALPHA := 0.18
const CHARGE_MIN := 0.10
const CHARGE_MAX := 0.48
const MARK_ALPHA := 0.30
const ARROW_ALPHA := 0.40
const FINAL_ALPHA := 0.60
const MARK_HEIGHT := 0.80
const SPARK_AMOUNT := 12
const BURN_SECONDS := 0.45
static var enabled := true
static var mode := DEFAULT_MODE
static var beam_shader: Shader
static var mark_shader: Shader
static func ground_band(parent: Node, left: float, right: float, seconds: float) -> MeshInstance3D:
 var mark := marker(parent,Vector3((left+right)*.5,.22,-.4),right-left,.45,seconds,true)
 return mark
static func beam_material() -> ShaderMaterial:
 if beam_shader == null:
  beam_shader = Shader.new()
  beam_shader.code = BEAM_CODE
 var material := ShaderMaterial.new()
 material.shader = beam_shader
 material.set_shader_parameter("core_fraction",CORE_FRACTION)
 material.set_shader_parameter("variant",float(mode))
 return material
static func marker(parent: Node, centre: Vector3, width: float, height: float, seconds: float, arrows := false, direction := 1.0, final_flash := true) -> MeshInstance3D:
 var node := MeshInstance3D.new()
 node.name = "BossImpactArrows" if arrows else "BossImpactRing"
 var mesh := QuadMesh.new()
 mesh.size = Vector2(width,height)
 node.mesh = mesh
 node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 if mark_shader == null:
  mark_shader = Shader.new()
  mark_shader.code = MARK_CODE
 var material := ShaderMaterial.new()
 material.shader = mark_shader
 material.set_shader_parameter("opacity",ARROW_ALPHA if arrows else MARK_ALPHA)
 material.set_shader_parameter("arrows",arrows)
 material.set_shader_parameter("direction",direction)
 material.set_shader_parameter("width",width)
 node.material_override = material
 parent.add_child(node)
 node.global_position = centre
 node.set_meta("t3k_marker",true)
 if final_flash:
  var tween := node.create_tween()
  tween.tween_interval(maxf(0,seconds-WARNING_SECONDS))
  tween.tween_callback(func(): if is_instance_valid(node): material.set_shader_parameter("opacity",FINAL_ALPHA))
 return node
static func dust(parent: Node3D, width: float) -> CPUParticles3D:
 var p := CPUParticles3D.new()
 p.name = "LightDust"
 p.amount = 10
 p.lifetime = .65
 p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
 p.emission_box_extents = Vector3(width*.45,.03,.1)
 p.direction = Vector3.UP
 p.spread = 20
 p.gravity = Vector3(0,-.15,0)
 p.initial_velocity_min = .08
 p.initial_velocity_max = .25
 p.scale_amount_min = .02
 p.scale_amount_max = .045
 var mesh := SphereMesh.new()
 mesh.radius = .1
 mesh.height = .2
 mesh.radial_segments = 4
 mesh.rings = 2
 mesh.material = BeeAttackVisuals.material(Color(.85,.72,.55,.25))
 p.mesh = mesh
 parent.add_child(p)
 p.position.y = -MARK_HEIGHT*.35
 return p
const BEAM_CODE := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform float variant = 0.0;
uniform float core_fraction = 0.25;
uniform float mode = 4.0;
void fragment(){
 float across = abs(UV.y-.5)*2.0;
 float scroll = UV.x*85.0-TIME*18.0;
 float noise_wave = .72+.16*sin(scroll+sin(UV.x*143.0-TIME*7.0))+.12*sin(scroll*2.3);
 float flicker = .92+.08*sin(TIME*29.0);
 float halo = pow(max(0.0,1.0-across),1.7);
 float core = 1.0-smoothstep(core_fraction*.84,core_fraction,across);
 float pulse = variant < .5 ? 1.0 : smoothstep(.08,.22,fract(UV.x*19.0-TIME*9.0))*(1.0-smoothstep(.65,.94,fract(UV.x*19.0-TIME*9.0)));
 vec3 cyan = vec3(.05,.65,1.0);
 ALBEDO = mix(cyan,vec3(1.0,.99,.96),core);
 EMISSION = ALBEDO*(1.1+core*.7)*noise_wave*flicker;
 ALPHA = max(halo*(variant<.5?.72:.45),core*.95)*pulse*noise_wave*flicker;
}
"""
const MARK_CODE := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float opacity = .3;
uniform bool arrows = false;
uniform float direction = 1.0;
uniform float width = 2.2;
uniform vec4 tint : source_color = vec4(1.0,.56,.29,1.0);
void fragment(){
 vec2 p=UV*2.0-1.0;
 float ring=1.0-smoothstep(.045,.10,abs(length(vec2(p.x,p.y*1.55))-.90));
 float lift=pow(max(0.0,1.0-abs(p.x)),3.0)*pow(max(0.0,UV.y),3.0)*.16;
 float ink=max(ring,lift);
 if(arrows){
  float x=fract(UV.x*width*1.2-TIME*direction*.85);
  float chevron=abs((x-.35)*direction-abs((UV.y-.64)*2.0));
  ink=(1.0-smoothstep(.035,.09,chevron))*smoothstep(.18,.35,UV.y)*(1.0-smoothstep(.80,.92,UV.y));
 }
 ALBEDO=tint.rgb;
 EMISSION=ALBEDO*.35;
 ALPHA=ink*opacity;
}
"""
