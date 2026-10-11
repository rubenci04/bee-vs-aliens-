class_name BeeLiberation
extends RefCounted
## NOCHE 01 · ETAPA 1 — the shared "the animal is FREED, not killed" language, used by every controlled animal (wasp,
## mosquito, ladybird, dragonflies, moth, ant, stag beetle, snail, spider, turtle):
##   implant   sparks + a mini cyan blast where the device was, then the device is hidden
##   colours   the body goes warm (alien tint and every glow removed): own material copies, nothing shared is touched
##   feedback  soft golden sparkles, a short floating "LIBERADO" and a gentle chime (the approved pollen chime, pitched up)
## The caller stops its attacks / hitboxes and moves the animal away (flying or walking); this only does the look and sound.
## Technology (probes, eyes, speeders, turrets, walkers, the seed carrier, the UFO...) keeps its explosion: see `explode_tech`.

const WARM := Color(1.0, 0.82, 0.5)
const WARM_AMOUNT := 0.28 # How far each body colour moves towards WARM.
const TEXT := "LIBERADO"
const TEXT_SECONDS := 1.3
const TEXT_RISE := 0.9
const TEXT_COLOR := Color(1.0, 0.9, 0.45)
const CHIME_PITCH := 1.45


## Runs the whole liberation look. `implant` (optional) is hidden after its blast; `at` is where the implant was.
static func free_animal(host: Node, visual: Node3D, implant: Node3D, at: Vector3) -> void:
	if host == null or not is_instance_valid(host):
		return
	BeeCombatVFX.spawn(host, at, &"tech_hit", Vector3.UP, 0.55) # Sparks...
	BeeCombatVFX.spawn(host, at, &"tech_death", Vector3.UP, 0.4) # ...and a mini cyan blast: only the device breaks.
	if implant != null and is_instance_valid(implant):
		implant.hide()
	if visual != null and is_instance_valid(visual):
		warm_colours(visual)
	BeeCombatVFX.spawn(host, at + Vector3(0, 0.3, 0), &"pollen", Vector3.UP, 1.0)
	BeeAudio.play(host, &"liberate", at, CHIME_PITCH)
	float_text(host, at + Vector3(0, 0.6, 0.2))


## Warm, natural colours and no alien glow. Every surface gets its own material copy first.
static func warm_colours(visual: Node3D) -> void:
	for mesh: MeshInstance3D in visual.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface)
			if material == null:
				continue
			var own := material.duplicate() as Material
			if own is ShaderMaterial:
				var shader := own as ShaderMaterial
				var albedo: Variant = shader.get_shader_parameter("albedo")
				if albedo is Color:
					shader.set_shader_parameter("albedo", (albedo as Color).lerp(WARM, WARM_AMOUNT))
				var energy: Variant = shader.get_shader_parameter("emission_energy")
				if energy != null:
					shader.set_shader_parameter("emission_energy", 0.0)
			elif own is BaseMaterial3D:
				var base := own as BaseMaterial3D
				base.albedo_color = base.albedo_color.lerp(WARM, WARM_AMOUNT)
				base.emission_enabled = false
			mesh.set_surface_override_material(surface, own)


## A short "LIBERADO" that rises and fades (billboard, always readable, no depth test).
static func float_text(host: Node, at: Vector3) -> Label3D:
	var label := Label3D.new()
	label.name = "LiberatedText"
	label.text = TEXT
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 44
	label.outline_size = 12
	label.pixel_size = 0.0075
	label.modulate = TEXT_COLOR
	label.outline_modulate = Color(0.16, 0.09, 0.03)
	label.add_to_group("bee_liberated_text")
	host.add_child(label)
	label.global_position = at
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", at + Vector3(0, TEXT_RISE, 0), TEXT_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, TEXT_SECONDS * 0.45).set_delay(TEXT_SECONDS * 0.55)
	tween.tween_property(label, "outline_modulate:a", 0.0, TEXT_SECONDS * 0.45).set_delay(TEXT_SECONDS * 0.55)
	tween.chain().tween_callback(label.queue_free)
	return label


## Technology does not get freed: it explodes (cyan blast + the usual tech death sound).
static func explode_tech(host: Node, at: Vector3, size := 1.0) -> void:
	BeeCombatVFX.spawn(host, at, &"tech_death", Vector3.UP, size)

	BeeAudio.play(host, &"tech_death", at)
