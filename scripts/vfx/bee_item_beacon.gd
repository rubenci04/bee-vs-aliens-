class_name BeeItemBeacon
extends Node3D
## LOTE 9 · ETAPA B — every item reads at a glance, against the ochre soil and under every light of the day, and the four
## kinds read apart: a pulsing saturated HALO, a coloured RING with a WHITE OUTLINE (facing the camera) and a soft COLUMN
## of light rising from the item. Hues chosen far from the ochre ground (~31 deg) and from cyan (151-202 deg, hostile only):
##   pollen   lemon-lime          spread   royal blue        bomb   red        healing   green
## Presentation only (no collision, no gameplay). Added by the Level 01 / Level 02 stages to every item in the level.

const COLORS := {
	&"pollen": Color(0.78, 1.0, 0.22),
	&"spread": Color(0.3, 0.46, 1.0),
	&"bomb": Color(1.0, 0.16, 0.3),
	&"cluster": Color(0.3, 1.0, 0.42), # LOTE 13: pollen cluster: the old healing green (it reads apart from the lime pollen and the ochre soil), bigger.
}
const OUTLINE := Color(1.0, 1.0, 1.0)
## Size per kind (pollen is the small, frequent one).
const SIZES := {&"pollen": 0.72, &"spread": 1.0, &"bomb": 1.0, &"cluster": 1.2}
const RING_RADIUS := 0.5
const HALO_RADIUS := 0.66
const HALO_ALPHA := 0.32
const PULSE_HZ := 1.8
const PULSE_SCALE := 0.14
const COLUMN_HEIGHT := 3.2
const COLUMN_ALPHA := 0.16
const RING_PULSE := 0.06 # The ring breathes with the halo.

static var _materials := {}

var kind: StringName = &"pollen"
var halo: MeshInstance3D
var ring: MeshInstance3D
var outline: MeshInstance3D
var column: MeshInstance3D
var _t := 0.0


static func for_item(item: Node3D) -> StringName:
	var script := item.get_script() as Script
	var path := script.resource_path if script != null else ""
	if path.contains("pollen_cluster") or path.contains("healing"): # The old honey jar reads as a cluster too.
		return &"cluster"
	if item is BeePowerupPickup:
		return &"bomb" if (item as BeePowerupPickup).kind == BeePowerupPickup.Kind.BOMB else &"spread"
	return &"pollen"


## Adds the beacon to an item once (safe to call twice).
static func attach(item: Node3D) -> BeeItemBeacon:
	if item == null or not is_instance_valid(item):
		return null
	var existing := item.get_node_or_null("ItemBeacon") as BeeItemBeacon
	if existing != null:
		if item.has_node("PickupMedallion") or item.has_node("PollenGrains"):
			existing.hide()
			existing.set_process(false)
		return existing
	var beacon := BeeItemBeacon.new()
	beacon.name = "ItemBeacon"
	beacon.kind = for_item(item)
	if item.has_node("PollenGrains"):
		item.add_child(beacon)
		beacon.hide()
		beacon.set_process(false)
		return beacon
	item.add_child(beacon)
	if item.has_node("PickupMedallion"):
		beacon.hide() # The legacy capsule now has its own type ring; avoid stacked halos/columns.
		beacon.set_process(false)
	return beacon


static func _material(key: String, color: Color, transparent: bool, priority: int) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.render_priority = priority
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_materials[key] = material
	return material


func color() -> Color:
	return COLORS[kind]


func _ready() -> void:
	if get_parent().has_node("PollenGrains"):
		return # Three grains supply their own shine, without building a beacon.
	var tint := color()
	var size := float(SIZES[kind])
	scale = Vector3.ONE * size
	# Halo: a translucent disc-like sphere behind the item (far shell only, never hides the model).
	var sphere := SphereMesh.new()
	sphere.radius = HALO_RADIUS
	sphere.height = HALO_RADIUS * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	var halo_material := _material("halo_" + str(kind), Color(tint, HALO_ALPHA), true, -1).duplicate() as StandardMaterial3D
	halo_material.cull_mode = BaseMaterial3D.CULL_FRONT
	sphere.material = halo_material
	halo = _mesh("Halo", sphere)
	# Ring + white outline, facing the side camera (torus axis along Z).
	ring = _mesh("Ring", _torus(RING_RADIUS - 0.06, RING_RADIUS, _material("ring_" + str(kind), tint, false, 0)))
	outline = _mesh("WhiteOutline", _torus(RING_RADIUS, RING_RADIUS + 0.05, _material("outline", OUTLINE, false, 0)))
	for node in [ring, outline]:
		node.rotation.x = PI * 0.5
	# Column of light: a soft vertical beam rising from the item.
	var beam := CylinderMesh.new()
	beam.top_radius = 0.08
	beam.bottom_radius = 0.26
	beam.height = COLUMN_HEIGHT
	beam.radial_segments = 12
	beam.rings = 1
	beam.cap_top = false
	beam.cap_bottom = false
	beam.material = _material("column_" + str(kind), Color(tint.lerp(Color.WHITE, 0.35), COLUMN_ALPHA), true, -2)
	column = _mesh("LightColumn", beam)
	column.position = Vector3(0.0, COLUMN_HEIGHT * 0.5, -0.05)


func _mesh(label: String, mesh: Mesh) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node


static func _torus(inner: float, outer: float, material: Material) -> TorusMesh:
	var torus := TorusMesh.new()
	torus.inner_radius = inner
	torus.outer_radius = outer
	torus.rings = 32
	torus.ring_segments = 6
	torus.material = material
	return torus


func _process(delta: float) -> void:
	_t += delta
	var pulse := 0.5 + 0.5 * sin(_t * TAU * PULSE_HZ)
	halo.scale = Vector3.ONE * (1.0 + PULSE_SCALE * pulse)
	(halo.mesh.surface_get_material(0) as StandardMaterial3D).albedo_color.a = HALO_ALPHA * (0.7 + 0.6 * pulse)
	var breathe := Vector3.ONE * (1.0 + RING_PULSE * pulse)
	ring.scale = breathe
	outline.scale = breathe


## Current halo pulse scale (tests).
func halo_scale() -> float:
	return halo.scale.x
