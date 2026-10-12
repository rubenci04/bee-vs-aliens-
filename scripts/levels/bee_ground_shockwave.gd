class_name BeeGroundShockwave
extends Node3D
## LOTE 12 · ETAPA 3 — a stomp wave that runs along the ground (walking robot and tarantula). It is NOT a projectile: the Lote 11
## roll never destroys it (the roll only makes Bee invulnerable for its 0.35 s); the only clean answer is to fly above it.
## The owner draws the warning line first (see `warning_band`) and spawns the wave when the warning is over.

const COLOR := Color(0.3, 0.95, 1.0, 0.55)
const WARNING_COLOR := Color(1.0, 0.62, 0.2, 0.28)
const GROUND_Y := 0.0

var direction := -1.0
var speed := 7.5
var height := 1.3
var width := 0.9
var stop_x := 0.0 # World X where the wave ends (a screen edge).
var hitbox: DamageHitbox3D
var _visual: MeshInstance3D
var _dust_left := 0.0


## Spawns a wave on `parent` at world X `from_x`, running towards `stop_x`.
static func launch(parent: Node, attacker: Node, from_x: float, stop: float, damage: int, wave_speed: float, wave_height: float) -> BeeGroundShockwave:
	var wave := BeeGroundShockwave.new()
	wave.name = "GroundShockwave"
	wave.direction = signf(stop - from_x) if stop != from_x else -1.0
	wave.speed = wave_speed
	wave.height = wave_height
	wave.stop_x = stop
	wave.top_level = true
	parent.add_child(wave)
	wave.global_position = Vector3(from_x, GROUND_Y, 0.0)
	var shape := BoxShape3D.new()
	shape.size = Vector3(wave.width, wave_height, 1.2)
	wave.hitbox = BeeAttackVisuals.hazard_area(wave, attacker, damage, shape)
	wave.hitbox.position = Vector3(0.0, wave_height * 0.5, 0.0)
	wave.hitbox.set_enabled(true)
	wave._build()
	return wave


## The warning: a flat band on the ground line from `from_x` to `to_x`, `band_height` tall (caller frees it).
static func warning_band(parent: Node, from_x: float, to_x: float, band_height: float) -> MeshInstance3D:
	var band := BeeAttackVisuals.line(parent, Vector3(from_x, GROUND_Y + band_height * 0.5, 0.0), Vector3(to_x, GROUND_Y + band_height * 0.5, 0.0), 1.0, WARNING_COLOR)
	band.scale.y = band_height
	return band


func _build() -> void:
	_visual = MeshInstance3D.new()
	var mesh := SphereMesh.new() # A low dome of dust and energy.
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.is_hemisphere = true
	mesh.radial_segments = 14
	mesh.rings = 5
	mesh.material = BeeAttackVisuals.material(COLOR)
	_visual.mesh = mesh
	_visual.scale = Vector3(width * 1.1, height, 0.9)
	_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_visual)


func _physics_process(delta: float) -> void:
	global_position.x += direction * speed * delta
	_dust_left -= delta
	if _dust_left <= 0.0:
		_dust_left = 0.12
		BeeCombatVFX.spawn(get_parent(), global_position + Vector3(0.0, 0.15, 0.3), &"rock_break", Vector3.UP, 0.45)
	if (direction < 0.0 and global_position.x <= stop_x) or (direction > 0.0 and global_position.x >= stop_x):
		stop()


func stop() -> void:
	if hitbox != null:
		hitbox.set_enabled(false)
	queue_free()
