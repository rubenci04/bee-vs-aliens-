extends Node3D
## Tanda X — los momentos de los actos 2 y 3, con la regadera (bee_level_01_watering_event.gd) como modelo: los dispara el
## director (`director_moment`), juegan una sola vez, avisan antes de pegar y no traen enemigos (el director respira).
##   dew_drops   10 s: gotas de rocío cuelgan brillando de las hojas (aviso) y caen rectas; daño chico
##   lawnmower    8 s: una cortadora de césped cruza al fondo, sacude la pantalla y tira pasto cortado por abajo:
##                hay que volar por encima de MOMENT_MOWER_SAFE_Y
const S := preload("res://scripts/game/bee_moment_settings.gd")

signal drop_warned(x: float)
signal moment_finished(id: StringName)

var stage: BeeShmupStage
var played: Dictionary = {}
var running: StringName = &""
var drops_spawned := 0
var mower_pulses := 0
var mower: Node3D
var _time := 0.0
var _next := 0.0
var _rng := RandomNumberGenerator.new()
var _band: MeshInstance3D
var _band_hitbox: DamageHitbox3D
var _drops: Array[Dictionary] = [] # {"node", "hitbox", "warn_left", "x"}


static func attach(level: BeeShmupStage) -> Node3D:
	var pieces := (load("res://scripts/levels/bee_level_01_set_pieces.gd") as GDScript).new() as Node3D
	pieces.name = "SetPieces"
	pieces.set("stage", level)
	level.add_child(pieces)
	return pieces


func _ready() -> void:
	_rng.seed = 2611
	var wave := stage.get_node_or_null("WaveController")
	if wave != null and wave.has_signal("director_moment"):
		wave.director_moment.connect(play)


func play(id: StringName) -> bool:
	if played.has(id) or running != &"":
		return false
	if id == &"dew_drops" and not S.MOMENT_DEW_ENABLED: return false
	if id == &"lawnmower" and not S.MOMENT_MOWER_ENABLED: return false
	if id not in [&"dew_drops", &"lawnmower"]:
		return false
	played[id] = true
	running = id
	_time = 0.0
	_next = 0.3
	if id == &"lawnmower":
		_begin_mower()
	return true


func _physics_process(delta: float) -> void:
	_update_drops(delta)
	if running == &"":
		return
	_time += delta
	if running == &"dew_drops":
		if _time >= _next and _time < S.MOMENT_DEW_SECONDS - S.MOMENT_DEW_WARNING:
			_next = _time + S.MOMENT_DEW_EVERY
			_spawn_drop()
		if _time >= S.MOMENT_DEW_SECONDS:
			_finish()
	elif running == &"lawnmower":
		_update_mower(delta)
		if _time >= S.MOMENT_MOWER_SECONDS:
			_finish()


func _finish() -> void:
	var id := running
	running = &""
	if is_instance_valid(mower):
		var away := mower.create_tween()
		away.tween_property(mower, "scale", Vector3.ONE * 0.01, 0.4)
		away.tween_callback(mower.queue_free)
	if is_instance_valid(_band):
		_band.queue_free()
	_band_hitbox = null
	moment_finished.emit(id)


# --- gotas de rocío --------------------------------------------------------------------------------------------

func _spawn_drop() -> void:
	var half := BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(get_viewport()))
	var x := stage.camera.global_position.x + _rng.randf_range(-0.85, 0.85) * half
	if _rng.randf() < 0.35 and is_instance_valid(stage.bee):
		x = stage.bee.global_position.x + _rng.randf_range(-0.6, 0.6) # Algunas apuntan a donde está Bee.
	var top := BeeLevel01Framing.top_y() - 0.4
	var drop := MeshInstance3D.new()
	drop.name = "DewDrop"
	var sphere := SphereMesh.new()
	sphere.radius = S.MOMENT_DEW_RADIUS
	sphere.height = S.MOMENT_DEW_RADIUS * 2.6 # Alargada: forma de gota.
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = S.MOMENT_DEW_COLOR
	sphere.material = material
	drop.mesh = sphere
	drop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(drop)
	drop.global_position = Vector3(x, top, 0.0)
	var shape := SphereShape3D.new()
	shape.radius = S.MOMENT_DEW_RADIUS
	var hitbox := BeeAttackVisuals.hazard_area(self, self, S.MOMENT_DEW_DAMAGE, shape)
	hitbox.global_position = drop.global_position
	hitbox.set_enabled(false) # Mientras avisa no lastima.
	_drops.append({"node": drop, "hitbox": hitbox, "warn_left": S.MOMENT_DEW_WARNING, "x": x})
	drops_spawned += 1
	drop_warned.emit(x)


func _update_drops(delta: float) -> void:
	for i in range(_drops.size() - 1, -1, -1):
		var entry: Dictionary = _drops[i]
		var drop: MeshInstance3D = entry["node"]
		var hitbox: DamageHitbox3D = entry["hitbox"]
		if not is_instance_valid(drop):
			_drops.remove_at(i)
			continue
		if float(entry["warn_left"]) > 0.0:
			entry["warn_left"] = float(entry["warn_left"]) - delta
			drop.scale = Vector3.ONE * (0.6 + 0.4 * absf(sin(float(entry["warn_left"]) * 18.0))) # Titila colgada.
			if float(entry["warn_left"]) <= 0.0:
				drop.scale = Vector3.ONE
				if is_instance_valid(hitbox): hitbox.set_enabled(true)
			continue
		drop.global_position.y -= S.MOMENT_DEW_SPEED * delta
		if is_instance_valid(hitbox):
			hitbox.global_position = drop.global_position
		if drop.global_position.y < BeeLevel01Framing.bottom_y():
			BeeCombatVFX.spawn(self, Vector3(drop.global_position.x, 0.05, 0.0), &"impact_organic", Vector3.UP, 0.5) # Salpica.
			if is_instance_valid(hitbox): hitbox.queue_free()
			drop.queue_free()
			_drops.remove_at(i)


# --- cortadora de césped -----------------------------------------------------------------------------------------

func _begin_mower() -> void:
	mower = _build_mower()
	add_child(mower)
	var half := BeeLevel01Framing.half_width_max(BeeLevel01Framing.view_aspect(get_viewport()))
	mower.global_position = Vector3(stage.camera.global_position.x + half + 6.0, 0.0, S.MOMENT_MOWER_Z)
	# Franja de peligro (el pasto cortado vuela por abajo): primero se ve como aviso, después lastima a pulsos.
	_band = MeshInstance3D.new()
	_band.name = "MowerBand"
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, S.MOMENT_MOWER_SAFE_Y)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.55, 0.85, 0.25, 0.18)
	quad.material = material
	_band.mesh = quad
	_band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_band)
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, S.MOMENT_MOWER_SAFE_Y, 2.0)
	_band_hitbox = BeeAttackVisuals.hazard_area(self, self, S.MOMENT_MOWER_DAMAGE, box)
	_band_hitbox.set_enabled(false)
	preload("res://scripts/ui/bee_hud_notices.gd").for_host(stage).show_notice("¡VOLÁ ALTO! · CORTADORA", S.MOMENT_MOWER_WARNING + 1.0, "moment")


func _update_mower(delta: float) -> void:
	var camera_x := stage.camera.global_position.x
	var half := BeeLevel01Framing.half_width_max(BeeLevel01Framing.view_aspect(get_viewport()))
	var travel := (2.0 * half + 12.0) / S.MOMENT_MOWER_SECONDS # Cruza toda la pantalla en lo que dura el momento.
	if is_instance_valid(mower):
		mower.global_position.x = camera_x + half + 6.0 - travel * _time
		mower.rotation.z = 0.03 * sin(_time * 30.0) # Vibra.
	var floor_y := BeeLevel01Framing.bottom_y()
	if is_instance_valid(_band):
		var band_material := (_band.mesh as QuadMesh).material as StandardMaterial3D
		var hot := _time >= S.MOMENT_MOWER_WARNING
		band_material.albedo_color.a = (0.32 + 0.12 * sin(_time * 12.0)) if hot else (0.12 + 0.12 * absf(sin(_time * 8.0)))
		_band.global_position = Vector3(camera_x, floor_y + S.MOMENT_MOWER_SAFE_Y * 0.5, 0.2)
		_band.scale = Vector3(2.0 * half + 2.0, 1.0, 1.0)
	if _band_hitbox != null and is_instance_valid(_band_hitbox):
		_band_hitbox.global_position = Vector3(camera_x, floor_y + S.MOMENT_MOWER_SAFE_Y * 0.5, 0.0)
		if _time >= S.MOMENT_MOWER_WARNING:
			var pulse := int((_time - S.MOMENT_MOWER_WARNING) / S.MOMENT_MOWER_PULSE)
			if pulse >= mower_pulses:
				mower_pulses = pulse + 1
				_band_hitbox.set_enabled(true) # Re-armado: cada ráfaga puede volver a pegar una vez...
				for area in (_band_hitbox.get_overlapping_areas() if _band_hitbox.monitoring else []): # ...también a quien ya estaba adentro (la primera vez la detecta al entrar).
					var hurtbox := area as DamageHurtbox3D
					if hurtbox != null and _band_hitbox.can_damage(hurtbox):
						_band_hitbox._hit_targets[hurtbox.get_instance_id()] = true
						hurtbox.receive_hit(_band_hitbox)
				BeeCameraShake.kick(stage.bee, S.MOMENT_MOWER_SHAKE, 0.25, Vector2.UP)
				BeeCombatVFX.spawn(self, Vector3(camera_x + _rng.randf_range(-half, half), floor_y + 0.6, 0.0), &"impact_organic", Vector3.UP, 1.2)


func _build_mower() -> Node3D:
	var root := Node3D.new()
	root.name = "Lawnmower"
	root.scale = Vector3.ONE * S.MOMENT_MOWER_SCALE
	var parts := [
		[Vector3(1.6, 0.55, 1.1), Vector3(0, 0.55, 0), Color(0.78, 0.16, 0.12)], # Carcasa roja.
		[Vector3(1.2, 0.18, 0.9), Vector3(0, 0.92, 0), Color(0.2, 0.2, 0.22)], # Motor.
		[Vector3(0.08, 1.4, 0.08), Vector3(0.9, 1.4, 0.35), Color(0.3, 0.3, 0.32)], # Manija.
		[Vector3(0.08, 1.4, 0.08), Vector3(0.9, 1.4, -0.35), Color(0.3, 0.3, 0.32)],
	]
	for part in parts:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = part[0]
		mesh.mesh = box
		mesh.position = part[1]
		var material := ShaderMaterial.new()
		material.shader = BeeToonStyle.TOON
		material.set_shader_parameter("albedo", part[2])
		material.next_pass = BeeToonStyle.shared_outline(BeeToonStyle.OUTLINE_PROP)
		mesh.material_override = material
		root.add_child(mesh)
	for wheel_x in [-0.55, 0.55]:
		for wheel_z in [-0.55, 0.55]:
			var wheel := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.25
			cylinder.bottom_radius = 0.25
			cylinder.height = 0.14
			wheel.mesh = cylinder
			wheel.rotation.x = PI * 0.5
			wheel.position = Vector3(wheel_x, 0.25, wheel_z)
			var tyre := ShaderMaterial.new()
			tyre.shader = BeeToonStyle.TOON
			tyre.set_shader_parameter("albedo", Color(0.08, 0.08, 0.08))
			wheel.material_override = tyre
			root.add_child(wheel)
	return root
