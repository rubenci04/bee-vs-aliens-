class_name BeeCameraShake
extends RefCounted
## T4f — directional micro shake, requested by the three approved local hit-stop events.
## Legacy calls without a direction do nothing. Uses Camera3D h_offset / v_offset, so the
## framing (Camera D) and every gameplay bound stay exactly the same. A new kick never shortens a stronger one.

const MAX_AMPLITUDE := 0.09 ## metres at the flight plane: barely visible, felt more than seen


static func kick(from: Node, amplitude := 0.05, duration := 0.2, direction := Vector2.ZERO) -> void:
	if direction == Vector2.ZERO:
		return # T4f: legacy bomb/damage/death calls no longer shake; only approved local events do.
	if not BeeGameSettings.screen_shake_enabled:
		return # LOTE 11: switched off from the title menu.
	if from == null or not from.is_inside_tree():
		return
	var camera := from.get_viewport().get_camera_3d()
	if camera == null:
		return
	amplitude = minf(amplitude, MAX_AMPLITUDE)
	var now := Time.get_ticks_msec() / 1000.0
	var until := float(camera.get_meta("shake_until", 0.0))
	var impact := preload("res://scripts/game/bee_impact_settings.gd") # Tanda V: nunca dos sacudidas grandes casi juntas.
	if impact.IMPACT_ENABLED and amplitude >= impact.BIG_SHAKE:
		if now - float(camera.get_meta("last_big_shake", -INF)) < impact.SHAKE_GAP_SECONDS:
			return
		camera.set_meta("last_big_shake", now)
	if now < until and amplitude < float(camera.get_meta("shake_amplitude", 0.0)):
		return
	camera.set_meta("shake_until", now + duration)
	camera.set_meta("shake_amplitude", amplitude)
	if camera.has_meta("shake_tween"):
		var previous = camera.get_meta("shake_tween")
		if previous is Tween and (previous as Tween).is_valid():
			(previous as Tween).kill()
	var tween := camera.create_tween()
	var steps := 5
	var previous_offset: Vector2 = camera.get_meta("shake_offset", Vector2.ZERO)
	var apply := _apply_offset.bind(camera)
	for i in steps:
		var falloff := 1.0 - float(i) / float(steps)
		var sign_x := 1.0 if i % 2 == 0 else -1.0
		var to: Vector2 = direction.normalized() * sign_x * amplitude * falloff
		tween.tween_method(apply, previous_offset, to, duration / float(steps + 1))
		previous_offset = to
	tween.tween_method(apply, previous_offset, Vector2.ZERO, duration / float(steps + 1))
	camera.set_meta("shake_tween", tween)


## Mejora visual: la sacudida se suma al encuadre del rig de cámara (rig_offset); sin rig, ese encuadre es cero.
static func _apply_offset(value: Vector2, camera: Camera3D) -> void:
	if not is_instance_valid(camera):
		return
	camera.set_meta("shake_offset", value)
	var base: Vector2 = camera.get_meta("rig_offset", Vector2.ZERO)
	camera.h_offset = base.x + value.x
	camera.v_offset = base.y + value.y
