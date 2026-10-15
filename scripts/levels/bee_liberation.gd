class_name BeeLiberation
extends RefCounted
const COMMON_CUE := preload("res://scripts/vfx/bee_common_attack_cue.gd")
const HUD_NOTICES := preload("res://scripts/ui/bee_hud_notices.gd")
const HUD_TEXT := preload("res://scripts/game/bee_hud_text_settings.gd")
## NOCHE 01 · ETAPA 1 — the shared "the animal is FREED, not killed" language, used by every controlled animal (wasp,
## mosquito, ladybird, dragonflies, moth, ant, stag beetle, snail, spider, turtle):
##   implant   sparks + a mini cyan blast where the device was, then the device is hidden
##   colours   the body goes warm (alien tint and every glow removed): own material copies, nothing shared is touched
##   feedback  soft golden sparkles, a short floating "LIBERADO" and a gentle chime (the approved pollen chime, pitched up)
## The caller stops attacks, then BeeReleaseAnimation handles its short, harmless departure.
## Technology (probes, eyes, speeders, turrets, walkers, the seed carrier, the UFO...) keeps its explosion: see `explode_tech`.

const WARM := Color(1.0, 0.82, 0.5)
const WARM_AMOUNT := 0.28 # How far each body colour moves towards WARM.
const TEXT := "LIBERADO"
const TEXT_SECONDS := 1.3
const TEXT_RISE := 0.9
const TEXT_COLOR := Color(1.0, 0.9, 0.45)
## LOTE 14 · ETAPA 3.3: never more than MAX_TEXTS "LIBERADO" signs at once; further liberations merge into ONE "+N LIBERADOS" sign.
const MAX_TEXTS := 2
const GROUP_TEXT := "+%d LIBERADOS"
const CHIME_PITCH := 1.45
## LOTE 9 — every hit on a controlled animal (body, shell, wings, legs) damages its implant at BODY_MULTIPLIER; a
## direct hit on the implant / weak point does IMPLANT_MULTIPLIER. Area damage (the bomb) is always 1x.
const IMPLANT_MULTIPLIER := 2.0
const BODY_MULTIPLIER := 1.0
## Wasp / spider (one hit area): a shot whose line passes this close to the implant (X/Y, m) is a direct implant hit.
const WEAK_POINT_RADIUS := 0.32


## Runs the whole liberation look. `implant` (optional) is hidden after its blast; `at` is where the implant was.
static func free_animal(host: Node, visual: Node3D, implant: Node3D, at: Vector3) -> void:
	if host == null or not is_instance_valid(host):
		return
	var release := preload("res://scripts/vfx/bee_release_animation.gd")
	var settings := preload("res://scripts/game/bee_release_settings.gd")
	if settings.legacy_review:
		BeeCombatVFX.spawn(host,at,&"tech_hit",Vector3.UP,.55)
		BeeCombatVFX.spawn(host,at,&"tech_death",Vector3.UP,.4)
		BeeCombatVFX.spawn(host,at+Vector3(0,.3,0),&"pollen",Vector3.UP,1.0)
		BeeJuice.pollen_burst(host,at)
	else:
		release.spark(host,at,host.get_tree().get_nodes_in_group("bee_release_full").size()>=settings.FULL_LIMIT)
	if implant != null and is_instance_valid(implant):
		implant.hide()
	if visual != null and is_instance_valid(visual):
		COMMON_CUE.cancel(visual)
		warm_colours(visual)
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
					shader.set_shader_parameter("albedo", WARM.darkened(0.18) if BeeToonStyle.is_cyan(albedo) else (albedo as Color).lerp(WARM, WARM_AMOUNT))
				var energy: Variant = shader.get_shader_parameter("emission_energy")
				if energy != null:
					shader.set_shader_parameter("emission_energy", 0.0)
			elif own is BaseMaterial3D:
				var base := own as BaseMaterial3D
				base.albedo_color = WARM.darkened(0.18) if BeeToonStyle.is_cyan(base.albedo_color) else base.albedo_color.lerp(WARM, WARM_AMOUNT)
				base.emission_enabled = false
			if mesh.material_override != null:
				mesh.material_override = own
			else:
				mesh.set_surface_override_material(surface, own)


## A short "LIBERADO" that rises and fades (billboard, always readable, no depth test). With MAX_TEXTS signs alive, the new ones merge into "+N LIBERADOS".
static func float_text(host: Node, at: Vector3) -> Label3D:
	HUD_NOTICES.for_host(host).note_liberated()
	var singles := 0
	var group: Label3D
	for node in host.get_tree().get_nodes_in_group("bee_liberated_text"):
		if not is_instance_valid(node) or (node as Node).is_queued_for_deletion():
			continue
		if (node as Node).has_meta("liberated_group"):
			group = node as Label3D
		else:
			singles += 1
	if singles >= MAX_TEXTS or group != null:
		return null # No extra world labels; every liberation is counted above.
	var label := Label3D.new()
	label.name = "LiberatedText"
	label.text = TEXT
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = HUD_TEXT.INDIVIDUAL_FONT
	label.outline_size = 12
	label.pixel_size = 0.0075
	label.modulate = Color(TEXT_COLOR, HUD_TEXT.INDIVIDUAL_ALPHA)
	label.outline_modulate = Color(0.16, 0.09, 0.03, HUD_TEXT.INDIVIDUAL_ALPHA)
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


## LOTE 14: the merged sign. One Label3D counts the liberations that did not get a sign of their own; every new one refreshes its text and its lifetime.
static func _group_text(host: Node, at: Vector3, group: Label3D) -> Label3D:
	if group == null:
		group = Label3D.new()
		group.name = "LiberatedGroupText"
		group.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		group.no_depth_test = true
		group.font_size = 44
		group.outline_size = 12
		group.pixel_size = 0.0075
		group.outline_modulate = Color(0.16, 0.09, 0.03)
		group.add_to_group("bee_liberated_text")
		group.set_meta("liberated_group", true)
		group.set_meta("liberated_count", 0)
		host.add_child(group)
		group.global_position = at
	var count := int(group.get_meta("liberated_count")) + 1
	group.set_meta("liberated_count", count)
	group.text = GROUP_TEXT % count
	group.modulate = TEXT_COLOR
	group.outline_modulate.a = 1.0
	if group.has_meta("liberated_tween"):
		var old := group.get_meta("liberated_tween") as Tween
		if old != null and old.is_valid():
			old.kill()
	var tween := group.create_tween()
	group.set_meta("liberated_tween", tween)
	tween.set_parallel(true)
	tween.tween_property(group, "global_position", group.global_position + Vector3(0, TEXT_RISE * 0.5, 0), TEXT_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(group, "modulate:a", 0.0, TEXT_SECONDS * 0.45).set_delay(TEXT_SECONDS * 0.55)
	tween.tween_property(group, "outline_modulate:a", 0.0, TEXT_SECONDS * 0.45).set_delay(TEXT_SECONDS * 0.55)
	tween.chain().tween_callback(group.queue_free)
	return group
