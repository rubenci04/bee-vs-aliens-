class_name BeeGroundShockwave
extends Node3D
## LOTE 12 · ETAPA 3 — a stomp wave that runs along the ground (walking robot and tarantula). It is NOT a projectile: the Lote 11
## roll never destroys it (the roll only makes Bee invulnerable for its 0.35 s); the only clean answer is to fly above it.
## The owner draws the warning line first (see `warning_band`) and spawns the wave when the warning is over.

## T7c (Tanda D): hot PLASMA (orange at the foot, magenta at the crown) with a jagged edge. Cyan is reserved for the parasitic implants.
const COLOR := Color(1.0, 0.42, 0.12, 0.62)
const CROWN := Color(1.0, 0.18, 0.55, 0.62)
const IMPACT_RING_RADIUS := 0.7 ## small ring where the wave is born
const JAGGED := 0.32
const SEGMENTS := 14
const RINGS := 5
const WARNING_COLOR := Color(1.0, 0.62, 0.2, 0.28)
const GROUND_Y := 0.0

var direction := -1.0
var speed := 7.5
var height := 1.3
var width := 0.9
var stop_x := 0.0 # World X where the wave ends (a screen edge).
var foot_color := COLOR ## Tanda E: the stag beetle's quake wave is brown / burnt orange (defaults = the robot's plasma)
var crown_color := CROWN
var hitbox: DamageHitbox3D
var _visual: MeshInstance3D
var _dust_left := 0.0


## Spawns a wave on `parent` at world X `from_x`, running towards `stop_x`.
static func launch(parent: Node, attacker: Node, from_x: float, stop: float, damage: int, wave_speed: float, wave_height: float, foot := COLOR, crown := CROWN, wave_width := 0.9) -> BeeGroundShockwave:
	var wave := BeeGroundShockwave.new()
	wave.name = "GroundShockwave"
	wave.direction = signf(stop - from_x) if stop != from_x else -1.0
	wave.speed = wave_speed
	wave.height = wave_height
	wave.width = wave_width
	wave.foot_color = foot
	wave.crown_color = crown
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
	wave._impact_ring()
	return wave


## The warning: a flat band on the ground line from `from_x` to `to_x`, `band_height` tall (caller frees it).
static func warning_band(parent: Node, from_x: float, to_x: float, band_height: float, seconds := 0.75) -> MeshInstance3D:
	var band := BeeAttackVisuals.line(parent, Vector3(from_x, GROUND_Y + band_height * 0.5, 0.0), Vector3(to_x, GROUND_Y + band_height * 0.5, 0.0), 1.0, WARNING_COLOR)
	band.scale.y = band_height
	BeeAttackVisuals.WARNING_STYLE.dress(band, WARNING_COLOR, 0.0, seconds)
	return band


func _build() -> void:
	_visual = MeshInstance3D.new()
	_visual.mesh = _plasma_mesh(foot_color, crown_color)
	_visual.scale = Vector3(width * 1.1, height, 0.9)
	_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_visual)


## A low jagged dome of plasma: a hemisphere whose rim and rings are pushed in and out by a fixed hash (irregular, identical every time).
static func _plasma_mesh(foot := COLOR, crown := CROWN) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grid: Array = []
	for ring in RINGS + 1:
		var lat := float(ring) / float(RINGS) * PI * 0.5
		var row: Array = []
		for seg in SEGMENTS:
			var lon := float(seg) / float(SEGMENTS) * TAU
			var jag := 1.0 + JAGGED * (_hash(ring, seg) - 0.5) * (0.6 + 0.4 * float(ring) / float(RINGS))
			if ring == RINGS:
				jag = 1.0 + JAGGED * 1.2 * _hash(ring, seg) # spiky crown
			var r := 0.5 * cos(lat) * jag
			row.append(Vector3(r * cos(lon), 0.5 * sin(lat) * jag, r * sin(lon)))
		grid.append(row)
	for ring in RINGS:
		for seg in SEGMENTS:
			var next := (seg + 1) % SEGMENTS
			var a: Vector3 = grid[ring][seg]
			var b: Vector3 = grid[ring][next]
			var c: Vector3 = grid[ring + 1][next]
			var d: Vector3 = grid[ring + 1][seg]
			var low := foot.lerp(crown, float(ring) / float(RINGS))
			var high := foot.lerp(crown, float(ring + 1) / float(RINGS))
			for corner in [[a, low], [b, low], [c, high], [a, low], [c, high], [d, high]]:
				tool.set_color(corner[1])
				tool.add_vertex(corner[0])
	var mesh := tool.commit()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.render_priority = 40
	mesh.surface_set_material(0, material)
	return mesh


static func _hash(a: int, b: int) -> float:
	return fposmod(sin(float(a) * 12.9898 + float(b) * 78.233) * 43758.5453, 1.0)


## Small hot ring on the soil where the wave is born (fades out).
func _impact_ring() -> void:
	var ring := BeeAttackVisuals.ring(get_parent(), Vector3(global_position.x, GROUND_Y + 0.05, 0.0), IMPACT_RING_RADIUS, 0.18, Color(foot_color, 0.8))
	ring.rotation.x = 0.0
	var fade := ring.create_tween()
	fade.tween_property(ring, "scale", Vector3.ONE * 1.8, 0.35)
	fade.tween_callback(ring.queue_free)



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
