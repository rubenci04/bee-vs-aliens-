extends Node3D
## Presentation only. The actor owns facing, squash, telegraph and combat.
@export var wing_frequency := 19.0
@export var wing_amplitude := 0.62
@onready var actor: WaspEnemy = get_parent().get_parent() as WaspEnemy
var wings: Array[Node3D] = []
var rest_angles: Array[Vector3] = []
var elapsed := 0.0

func _ready() -> void:
	_apply_alien_palette()
	for wing_name in ["Wing_L", "Wing_R"]:
		var wing := find_child(wing_name, true, false) as Node3D
		assert(wing != null, "Wasp visual requires independent wings")
		wings.append(wing)
		rest_angles.append(wing.rotation)
	if actor != null:
		get_parent().rotation.y = -actor.facing_x * PI * 0.5

func _process(delta: float) -> void:
	if actor != null and (actor.is_defeated() or not actor.is_active()):
		return
	elapsed += delta
	for i in wings.size():
		wings[i].rotation = rest_angles[i] + Vector3(0, 0, sin(elapsed * TAU * wing_frequency) * wing_amplitude * (-1.0 if i == 0 else 1.0))


# Readability: the wasp must not read as the (golden) player bee. Materials only; the GLB,
# scale and behavior are untouched. Cyan eyes = alien-controlled (cyan is the alien-tech colour).
const PALETTE := {
	"Ochre": Color(0.46, 0.045, 0.04), # Stripes: dark red.
	"Chitin": Color(0.13, 0.03, 0.03), # Thorax: near black red.
	"Dark": Color(0.035, 0.02, 0.02), # Waist, legs, stinger: near black.
}
const EYE_CYAN := Color(0.1, 0.9, 0.85)

func _apply_alien_palette() -> void:
	for mesh: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
			if source == null:
				continue
			var key := source.resource_name
			if key == "Eye":
				var eye := source.duplicate() as StandardMaterial3D
				eye.albedo_color = EYE_CYAN
				eye.emission_enabled = true
				eye.emission = EYE_CYAN
				eye.emission_energy_multiplier = 2.0
				mesh.set_surface_override_material(surface, eye)
			elif PALETTE.has(key):
				var tinted := source.duplicate() as StandardMaterial3D
				tinted.albedo_color = PALETTE[key]
				mesh.set_surface_override_material(surface, tinted)
