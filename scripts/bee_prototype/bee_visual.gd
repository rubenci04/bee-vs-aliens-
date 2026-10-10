extends Node3D
## Presentation only: never writes the CharacterBody transform or combat state.
@export var wing_frequency := 16.0
@export var wing_amplitude := 0.55
@onready var actor: BeePlayer = get_parent().get_parent() as BeePlayer
var wings: Array[Node3D] = []
var rest_angles: Array[Vector3] = []
var elapsed := 0.0
var _rim_materials: Array[ShaderMaterial] = []
var _rim_applied := -1.0
const BODY_LIFT := 0.9
## VISUAL POLISH 02: Bee reads a little larger (silhouette) - presentation only, the body / hurtbox / melee boxes are untouched.
const VISUAL_SCALE := 1.2

func _ready() -> void:
	BeeToonStyle.apply(self, true, BeeToonStyle.OUTLINE_BEE)
	_own_rim_materials()
	_setup_buzz()
	for wing_name in ["Wing_L", "Wing_R"]:
		var wing := find_child(wing_name, true, false) as Node3D
		assert(wing != null, "Bee visual requires independent wings")
		wings.append(wing)
		rest_angles.append(wing.rotation)
	# Matches the existing Player facing convention, including its initial pose.
	get_parent().rotation.y = -actor.facing_x * PI * 0.5
	get_parent().scale = Vector3.ONE * VISUAL_SCALE

func _process(delta: float) -> void:
	_update_buzz(delta, actor.is_defeated)
	if actor.is_defeated:
		return
	elapsed += delta
	_update_rim()
	for i in wings.size():
		wings[i].rotation = rest_angles[i] + Vector3(0, 0, sin(elapsed * TAU * wing_frequency) * wing_amplitude * (-1.0 if i == 0 else 1.0))

## Bee keeps her own copies of the toon materials so the sunset rim boost never touches other actors.
func _own_rim_materials() -> void:
	for mesh: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_surface_override_material(surface) as ShaderMaterial
			if material != null and (material.shader == BeeToonStyle.TOON or material.shader == BeeToonStyle.TOON_DOUBLE):
				var own := material.duplicate() as ShaderMaterial
				mesh.set_surface_override_material(surface, own)
				_rim_materials.append(own)

func _update_rim() -> void:
	var boost := BeeToonStyle.bee_rim_boost
	if absf(boost - _rim_applied) < 0.01:
		return
	_rim_applied = boost
	_lift_body(boost)
	for material in _rim_materials:
		material.set_shader_parameter("rim_strength", lerpf(0.3, 1.25, boost))
		material.set_shader_parameter("rim_power", lerpf(3.0, 1.7, boost))
		material.set_shader_parameter("rim_color", Color(1.0, 0.93, 0.8).lerp(Color(1.0, 0.98, 0.9), boost))

## Warm self-light so the golden body stays brighter than the dusk background (non-emissive materials only).
func _lift_body(boost: float) -> void:
	for material in _rim_materials:
		if not material.has_meta("body_albedo"):
			var energy: Variant = material.get_shader_parameter("emission_energy")
			if energy != null and float(energy) > 0.0:
				material.set_meta("body_albedo", Color.TRANSPARENT)
			else:
				material.set_meta("body_albedo", material.get_shader_parameter("albedo"))
		var albedo: Color = material.get_meta("body_albedo")
		if albedo.a > 0.0:
			material.set_shader_parameter("emission", albedo.lightened(0.1))
			material.set_shader_parameter("emission_energy", BODY_LIFT * boost)

# --- wing buzz -------------------------------------------------------------------------------
# Very soft, filtered hum on the SFX bus. Peak level stays ~12 dB under a base shot.
const BUZZ_STREAM := "res://audio/sfx/real/wing_buzz.wav"
const BUZZ_DB := -36.0
var buzz_player: AudioStreamPlayer

func _setup_buzz() -> void:
	var source := load(BUZZ_STREAM) as AudioStreamWAV
	if source == null:
		return
	var stream := source.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2
	buzz_player = AudioStreamPlayer.new()
	buzz_player.name = "WingBuzz"
	buzz_player.stream = stream
	buzz_player.bus = &"SFX"
	buzz_player.volume_db = BUZZ_DB
	add_child(buzz_player)
	if DisplayServer.get_name() != "headless":
		buzz_player.play()

func _update_buzz(delta: float, defeated: bool) -> void:
	if buzz_player == null:
		return
	buzz_player.volume_db = move_toward(buzz_player.volume_db, -80.0 if defeated else BUZZ_DB, 90.0 * delta)
	buzz_player.stream_paused = buzz_player.volume_db <= -79.0
