extends "res://scripts/bee_prototype/bee_garden_poc.gd"

enum MissionState { INTRO, POLLEN, WASP, ANOMALY, PROBE, COMBINED, REVEAL, COMPLETE }
@export var message_seconds := 2.0
const SIGNAL_POSITION := Vector3(-3.0, 7.0, 0.0)
const SIGNAL_RADIUS := 0.85
var mission_state := MissionState.INTRO
var state_left := 0.0
var reveal_step := 0
var completion_count := 0
var down := false
var final_wasp_started := false
var mission_started_msec := 0

func _ready() -> void:
	_build_garden()
	mission_started_msec = Time.get_ticks_msec()
	state_left = message_seconds
	for pickup in $Pollen.get_children():
		pickup.collected.connect(_on_mission_pollen)
	$Enemies/Wasp.defeated.connect(_on_wasp_down)
	$Enemies/Probe.defeated.connect(_on_probe_down)
	$Enemies/WaspFinal.defeated.connect(_on_final_wasp_down)
	$Enemies/Probe/HealthComponent.health_changed.connect(_on_probe_health_changed)
	bee.defeated.connect(_on_bee_down)
	$Presence.hide()
	$ObjectiveMarker.hide()
	_update_objective_marker()
	_update_hud()
	$CanvasLayer/Narrative.text = "ENTRE LAS FLORES"

func _process(delta: float) -> void:
	if down:
		if Input.is_action_just_pressed("restart"): get_tree().reload_current_scene()
		return
	match mission_state:
		MissionState.INTRO:
			state_left -= delta
			if state_left <= 0:
				mission_state = MissionState.POLLEN
				$CanvasLayer/Narrative.text = ""
				_maybe_activate_wasp()
		MissionState.WASP:
			state_left -= delta
			if state_left <= 0: $CanvasLayer/Narrative.text = ""
		MissionState.ANOMALY:
			if bee.global_position.distance_to(SIGNAL_POSITION) <= SIGNAL_RADIUS:
				mission_state = MissionState.PROBE
				$Enemies/Probe.activate(bee)
				$CanvasLayer/Narrative.text = "ORIGEN DESCONOCIDO"
				state_left = message_seconds
				_update_objective_marker()
		MissionState.PROBE, MissionState.COMBINED:
			state_left -= delta
			if state_left <= 0: $CanvasLayer/Narrative.text = ""
		MissionState.REVEAL:
			state_left -= delta
			if state_left <= 0:
				if reveal_step == 0:
					reveal_step = 1
					state_left = message_seconds
					$CanvasLayer/Narrative.text = "¿QUIÉN ESTABA OBSERVANDO?"
					$Presence.position = $BeeCamera.global_position + Vector3(8,9.5,-25)
					$Presence.show()
				else:
					mission_state = MissionState.COMPLETE
					completion_count += 1
					$CanvasLayer/Narrative.text = "MISIÓN 01 COMPLETA"
					print("MISSION 01 REAL TIME: %.1f s" % (float(Time.get_ticks_msec() - mission_started_msec) / 1000.0))
	_update_hud()

func _on_mission_pollen(_pickup: BeePollenPickup, _heal: int) -> void:
	if down or mission_state == MissionState.COMPLETE: return
	pollen_count += 1
	_maybe_activate_wasp()
	_try_anomaly()
	_update_objective_marker()

func _maybe_activate_wasp() -> void:
	if pollen_count >= 2 and mission_state != MissionState.INTRO and not $Enemies/Wasp.is_active() and not $Enemies/Wasp.is_defeated():
		mission_state = MissionState.WASP
		$Enemies/Wasp.activate(bee)
		$CanvasLayer/Narrative.text = "AVISPA TERRITORIAL"
		state_left = message_seconds
func _on_wasp_down(_enemy: WaspEnemy) -> void:
	if down: return
	mission_state = MissionState.POLLEN
	$CanvasLayer/Narrative.text = ""
	_try_anomaly()
	_update_objective_marker()

func _try_anomaly() -> void:
	if down or pollen_count < 3 or not $Enemies/Wasp.is_defeated(): return
	if mission_state != MissionState.POLLEN and mission_state != MissionState.WASP: return
	mission_state = MissionState.ANOMALY
	$CanvasLayer/Narrative.text = "SEÑAL EXTRAÑA DETECTADA"
	_update_objective_marker()

func _on_probe_health_changed(current: int, maximum: int, change: int) -> void:
	if down or change >= 0 or final_wasp_started: return
	if mission_state != MissionState.PROBE and mission_state != MissionState.COMBINED: return
	if current > maximum / 2.0: return
	final_wasp_started = true
	$Enemies/WaspFinal.activate(bee)
	mission_state = MissionState.COMBINED
	$CanvasLayer/Narrative.text = "SOBREVIVÍ"
	state_left = message_seconds

func _on_probe_down(_enemy: AlienProbeRanged) -> void:
	if down or mission_state == MissionState.COMPLETE: return
	_try_reveal()

func _on_final_wasp_down(_enemy: WaspEnemy) -> void:
	if down or mission_state == MissionState.COMPLETE: return
	_try_reveal()

func _try_reveal() -> void:
	if not $Enemies/Probe.is_defeated() or not $Enemies/WaspFinal.is_defeated(): return
	if mission_state == MissionState.REVEAL or mission_state == MissionState.COMPLETE: return
	mission_state = MissionState.REVEAL
	reveal_step = 0
	state_left = message_seconds
	$CanvasLayer/Narrative.text = "TRANSMISIÓN INTERRUMPIDA"
	_update_objective_marker()

func _on_bee_down() -> void:
	down = true
	$CanvasLayer/Narrative.text = "PLAYER DOWN — R — REINTENTAR"
	$ObjectiveMarker.hide()
	for enemy in $Enemies.get_children(): enemy.set_physics_process(false)
	_update_hud()

func _update_objective_marker() -> void:
	var marker: Node3D = $ObjectiveMarker
	marker.hide()
	if down or mission_state == MissionState.COMPLETE: return
	if mission_state == MissionState.ANOMALY:
		marker.position = SIGNAL_POSITION
		$ObjectiveMarker/PollenVisual.hide()
		$ObjectiveMarker/SignalVisual.show()
		marker.show()
	elif pollen_count < 3:
		for pickup in $Pollen.get_children():
			if not pickup.was_collected and not pickup.is_queued_for_deletion():
				marker.position = pickup.position + Vector3(0, 0.7, 0)
				$ObjectiveMarker/SignalVisual.hide()
				$ObjectiveMarker/PollenVisual.show()
				marker.show()
				break

func _update_hud() -> void:
	var objective := "RECOLECTÁ POLEN %d/3" % pollen_count
	match mission_state:
		MissionState.WASP: objective = "DEFENDÉ LA ZONA · POLEN %d/3" % pollen_count
		MissionState.POLLEN:
			if $Enemies/Wasp.is_defeated(): objective = "COMPLETÁ LA RECOLECCIÓN %d/3" % pollen_count
		MissionState.ANOMALY: objective = "INVESTIGÁ LA SEÑAL"
		MissionState.PROBE: objective = "DESTRUÍ LA SONDA"
		MissionState.COMBINED: objective = "SOBREVIVÍ · SONDA Y AVISPA"
		MissionState.REVEAL: objective = "OBSERVÁ EL CIELO"
		MissionState.COMPLETE: objective = "MISIÓN 01 COMPLETA"
	$CanvasLayer/Status.text = "HP %d/100 · POLEN %d/3\nOBJETIVO: %s\nWASD/flechas: volar · Z: melee · X: disparo" % [bee.health.current_health,pollen_count,objective]

