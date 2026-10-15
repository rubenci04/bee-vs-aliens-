extends Node3D
const S := preload("res://scripts/game/bee_pollen_settings.gd")
var elapsed := 0.0
var radius := .425
func _ready() -> void:
 for part in [["Border",1.0,S.BORDER,0.0],["Gold",1.0-S.BORDER_FRACTION,S.GOLD,S.THICKNESS*.2],["HoneyCell",S.INNER_RADIUS_FRACTION,S.BORDER,S.THICKNESS*.4],["Glow",S.GLOW_RADIUS_FACTOR,Color(S.GOLD,S.GLOW_ALPHA),-S.THICKNESS*.5]]:
  var shape := CylinderMesh.new()
  shape.top_radius = radius*float(part[1])
  shape.bottom_radius = shape.top_radius
  shape.height = S.THICKNESS
  shape.radial_segments = 6
  var mesh := MeshInstance3D.new()
  mesh.name = part[0]
  mesh.mesh = shape
  mesh.rotation.x = PI*.5
  mesh.position.z = part[3]
  mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  var material := StandardMaterial3D.new()
  material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  material.albedo_color = part[2]
  if part[0] in ["Gold","Glow"]:
   material.emission_enabled = true
   material.emission = S.GOLD
   material.emission_energy_multiplier = S.EMISSION
  if part[0] == "Glow": material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  mesh.material_override = material
  add_child(mesh)
func _process(delta: float) -> void:
 elapsed += delta
 rotation.z = elapsed*S.ROTATION_SPEED
 position.y = sin(elapsed*S.BOB_RATE)*S.BOB_HEIGHT
