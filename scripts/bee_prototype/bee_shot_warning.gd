class_name BeeShotWarning
extends RefCounted

static var last_sound: Dictionary = {}

## Each projectile of a burst gets its own 0.35-second anticipation; a fan shares one cue.
static func volley(enemy: Node3D, species: StringName, pose: Node3D, first_shot_in: float, count := 1, gap := 0.0) -> void:
	var enemy_ref: WeakRef = weakref(enemy)
	var pose_ref: WeakRef = weakref(pose) if pose != null else null
	var token := int(enemy.get_meta("shot_warning_token", 0)) + 1
	enemy.set_meta("shot_warning_token", token)
	for i in count:
		var delay := maxf(0.0, first_shot_in + i * gap - BeeGameSettings.SHOT_WARNING_SECONDS)
		enemy.get_tree().create_timer(delay, false).timeout.connect(func():
			var unit := enemy_ref.get_ref() as Node3D
			var body := pose_ref.get_ref() as Node3D if pose_ref != null else null
			if is_instance_valid(unit) and int(unit.get_meta("shot_warning_token", 0)) == token and unit.is_inside_tree() and (not unit.has_method("is_active") or bool(unit.call("is_active"))):
				begin(unit, species, body))

static func begin(enemy: Node3D, species: StringName, pose: Node3D = null) -> void:
	if BeeGameSettings.SHOT_WARNING_VISUAL_ENABLED and is_instance_valid(pose):
		var base := pose.scale
		var angle := pose.rotation.z
		var shift := pose.position
		var tween := enemy.create_tween().set_parallel(true)
		var duration := BeeGameSettings.SHOT_WARNING_SECONDS
		match species:
			&"wasp", &"ant", &"worm":
				tween.tween_property(pose, "rotation:z", angle + BeeGameSettings.SHOT_WARNING_TILT, duration * 0.5)
				tween.chain().tween_property(pose, "rotation:z", angle, duration * 0.5)
			&"spider":
				tween.tween_property(pose, "position:x", shift.x + BeeGameSettings.SHOT_WARNING_SHAKE, duration * 0.25)
				tween.chain().tween_property(pose, "position:x", shift.x - BeeGameSettings.SHOT_WARNING_SHAKE, duration * 0.25)
				tween.chain().tween_property(pose, "position:x", shift.x, duration * 0.5)
			_:
				tween.tween_property(pose, "scale", base * (1.0 + BeeGameSettings.SHOT_WARNING_SWELL), duration * 0.5)
				tween.chain().tween_property(pose, "scale", base, duration * 0.5)
	if BeeGameSettings.SHOT_WARNING_AUDIO_ENABLED:
		var now := Time.get_ticks_msec() / 1000.0
		if now - float(last_sound.get(species, -INF)) >= BeeGameSettings.SHOT_WARNING_SOUND_GAP_SEC:
			last_sound[species] = now
			var voice := BeeAudio.play(enemy.get_parent(), &"tech_hit", enemy.global_position, float(BeeGameSettings.SHOT_WARNING_PITCH.get(species, 1.0)))
			if is_instance_valid(voice):
				voice.set("volume_db", float(voice.get("volume_db")) + BeeGameSettings.SHOT_WARNING_SOUND_DB)
				var voice_ref: WeakRef = weakref(voice)
				enemy.get_tree().create_timer(BeeGameSettings.SHOT_WARNING_SOUND_SECONDS).timeout.connect(func():
					var playing: Node = voice_ref.get_ref()
					if is_instance_valid(playing):
						playing.call("stop")
						playing.queue_free())
	if BeeGameSettings.SHOT_WARNING_EDGE_ENABLED:
		var camera := enemy.get_viewport().get_camera_3d()
		if camera == null:
			return
		var rect := enemy.get_viewport().get_visible_rect()
		var point := camera.unproject_position(enemy.global_position)
		if rect.has_point(point) and not camera.is_position_behind(enemy.global_position):
			return
		var layer := CanvasLayer.new()
		enemy.add_child(layer)
		var arrow := Polygon2D.new()
		var size := BeeGameSettings.SHOT_WARNING_EDGE_SIZE
		arrow.polygon = PackedVector2Array([Vector2(size, 0), Vector2(-size, -size), Vector2(-size, size)])
		arrow.color = BeeGameSettings.HOSTILE_CYAN
		var margin := BeeGameSettings.SHOT_WARNING_EDGE_MARGIN
		arrow.position = point.clamp(Vector2.ONE * margin, rect.size - Vector2.ONE * margin)
		arrow.rotation = (point - rect.get_center()).angle()
		layer.add_child(arrow)
		var pulse := enemy.create_tween()
		pulse.tween_property(arrow, "scale", Vector2.ONE * 1.3, BeeGameSettings.SHOT_WARNING_SECONDS * 0.5)
		pulse.tween_property(arrow, "modulate:a", 0.0, BeeGameSettings.SHOT_WARNING_SECONDS * 0.5)
		pulse.tween_callback(layer.queue_free)
