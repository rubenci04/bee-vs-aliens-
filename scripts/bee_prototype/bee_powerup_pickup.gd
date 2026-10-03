class_name BeePowerupPickup
extends Area3D

enum Kind { SPREAD, BOMB }
@export var kind: Kind = Kind.SPREAD
## ARCADE REBUILD 02: the guaranteed pre-boss weapon power (Spread only). Base -> overcharged Spread; with Spread ->
## refill + extend (never a downgrade). Bigger, labelled "S+", with a turning halo so it reads as special.
@export var overcharge := false
var was_collected := false

const OVERCHARGE_SCALE := 1.35
static var _halo_mesh: TorusMesh

func _ready() -> void:
	$SpreadVisual.visible = kind == Kind.SPREAD
	$BombVisual.visible = kind == Kind.BOMB
	$Label.text = "S" if kind == Kind.SPREAD else "B"
	if overcharge and kind == Kind.SPREAD:
		$Label.text = "S+"
		scale = Vector3.ONE * OVERCHARGE_SCALE
		_add_halo()
	body_entered.connect(collect)

func collect(body: Node3D) -> bool:
	var bee := body as BeePlayer
	if was_collected or bee == null or bee.is_defeated:
		return false
	var accepted: bool
	if kind == Kind.SPREAD:
		accepted = bee.collect_spread_overcharge() if overcharge else bee.collect_spread()
	else:
		accepted = bee.collect_bomb()
	if not accepted:
		return false # Bomb at the cap stays available for later.
	was_collected = true
	BeeAudio.play(get_parent(), &"spread_pickup" if kind == Kind.SPREAD else &"bomb_pickup", global_position)
	BeeCombatVFX.spawn(get_parent(), global_position, &"pickup" if kind == Kind.SPREAD else &"pickup_bomb")
	hide()
	set_deferred("monitoring", false)
	queue_free()
	return true

func _add_halo() -> void:
	if _halo_mesh == null:
		_halo_mesh = TorusMesh.new()
		_halo_mesh.inner_radius = 0.5
		_halo_mesh.outer_radius = 0.57
		_halo_mesh.rings = 24
		_halo_mesh.ring_segments = 4
		var glow := StandardMaterial3D.new()
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.albedo_color = BeeAlienPalette.CYAN
		glow.emission_enabled = true
		glow.emission = BeeAlienPalette.CYAN
		glow.emission_energy_multiplier = BeeAlienPalette.MAX_EMISSION
		_halo_mesh.material = glow
	var halo := MeshInstance3D.new()
	halo.name = "Halo"
	halo.mesh = _halo_mesh
	halo.rotation.x = PI * 0.5
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(halo)
	var spin := halo.create_tween().set_loops()
	spin.tween_property(halo, "rotation:y", TAU, 2.4).from(0.0)
