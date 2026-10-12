class_name BeeCameraShake
extends RefCounted
## ARCADE REBUILD 02 — micro shake, only for heavy moments (Bomb, heavy enemy death, large set-piece impacts).
## Never for regular bullets. Uses Camera3D h_offset / v_offset, which the stage camera never writes, so the
## framing (Camera D) and every gameplay bound stay exactly the same. A new kick never shortens a stronger one.

const MAX_AMPLITUDE := 0.09 ## metres at the flight plane: barely visible, felt more than seen


static func kick(from: Node, amplitude := 0.05, duration := 0.2) -> void:
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
	for i in steps:
		var falloff := 1.0 - float(i) / float(steps)
		var sign_x := 1.0 if i % 2 == 0 else -1.0
		tween.tween_property(camera, "h_offset", sign_x * amplitude * falloff, duration / float(steps + 1))
		tween.parallel().tween_property(camera, "v_offset", -sign_x * amplitude * 0.6 * falloff, duration / float(steps + 1))
	tween.tween_property(camera, "h_offset", 0.0, duration / float(steps + 1))
	tween.parallel().tween_property(camera, "v_offset", 0.0, duration / float(steps + 1))
	camera.set_meta("shake_tween", tween)
