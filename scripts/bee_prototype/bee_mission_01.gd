extends "res://scripts/bee_prototype/bee_garden_poc.gd"

enum MissionState { INTRO, POLLEN, WASP, ANOMALY, PROBE, REVEAL, COMPLETE }
@export var message_seconds := 2.0
var mission_state := MissionState.INTRO
var state_left := 0.0
var reveal_step := 0
var completion_count := 0
var down := false

func _ready() -> void:
	_build_garden()
	state_left = message_seconds
	for pickup in $Pollen.get_children():
		pickup.collected.connect(_on_mission_pollen)
	$Enemies/Wasp.defeated.connect(_on_wasp_down)
	$Enemies/Probe.defeated.connect(_on_probe_down)
	bee.defeated.connect(_on_bee_down)
	$Presence.hide()
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
		MissionState.WASP:
			state_left -= delta
			if state_left <= 0: $CanvasLayer/Narrative.text = ""
		MissionState.ANOMALY:
			state_left -= delta
			$CanvasLayer/Narrative.modulate = Color(0.15,0.9,0.85,0.6+0.4*absf(sin(state_left*9)))
			if state_left <= 0:
				mission_state = MissionState.PROBE
				$Enemies/Probe.activate(bee)
				$CanvasLayer/Narrative.text = "ORIGEN DESCONOCIDO"
				$CanvasLayer/Narrative.modulate = Color.WHITE
				state_left = message_seconds
		MissionState.PROBE:
			state_left -= delta
			if state_left <= 0: $CanvasLayer/Narrative.text = ""
		MissionState.REVEAL:
			state_left -= delta
			if state_left <= 0:
				if reveal_step == 0:
					reveal_step = 1
					state_left = message_seconds
					$CanvasLayer/Narrative.text = "¿QUIÉN ESTABA OBSERVANDO?"
					# Distant sky lights only; follow neither actor nor camera afterward.
					$Presence.position = $BeeCamera.global_position + Vector3(8,9.5,-25)
					$Presence.show()
				else:
					mission_state = MissionState.COMPLETE
					completion_count += 1
					$CanvasLayer/Narrative.text = "MISIÓN 01 COMPLETA"
	_update_hud()

func _on_mission_pollen(_pickup: BeePollenPickup, _heal: int) -> void:
	pollen_count += 1
	if pollen_count >= 2 and not $Enemies/Wasp.is_active() and not $Enemies/Wasp.is_defeated():
		mission_state = MissionState.WASP
		$Enemies/Wasp.activate(bee)
		$CanvasLayer/Narrative.text = "DEFENDÉ LA ZONA"
		state_left = message_seconds
	_try_anomaly()

func _on_wasp_down(_enemy: WaspEnemy) -> void:
	if down: return
	mission_state = MissionState.POLLEN
	$CanvasLayer/Narrative.text = ""
	_try_anomaly()

func _try_anomaly() -> void:
	if down or pollen_count < 3 or not $Enemies/Wasp.is_defeated(): return
	if mission_state != MissionState.POLLEN and mission_state != MissionState.WASP: return
	mission_state = MissionState.ANOMALY
	state_left = message_seconds
	$CanvasLayer/Narrative.text = "SEÑAL DESCONOCIDA DETECTADA"

func _on_probe_down(_enemy: AlienProbeRanged) -> void:
	if down or mission_state != MissionState.PROBE: return
	mission_state = MissionState.REVEAL
	reveal_step = 0
	state_left = message_seconds
	$CanvasLayer/Narrative.text = "TRANSMISIÓN INTERRUMPIDA"

func _on_bee_down() -> void:
	down = true
	$CanvasLayer/Narrative.text = "PLAYER DOWN — R — REINTENTAR"
	for enemy in $Enemies.get_children(): enemy.set_physics_process(false)
	_update_hud()

func _update_hud() -> void:
	var objective := "RECOLECTÁ POLEN %d/3" % pollen_count
	match mission_state:
		MissionState.WASP: objective = "DEFENDÉ LA ZONA · DERROTÁ LA AVISPA"
		MissionState.ANOMALY: objective = "INVESTIGÁ LA SEÑAL"
		MissionState.PROBE: objective = "DERROTÁ LA SONDA"
		MissionState.REVEAL: objective = "OBSERVÁ EL CIELO"
		MissionState.COMPLETE: objective = "MISIÓN 01 COMPLETA"
	$CanvasLayer/Status.text = "HP %d/100 · POLEN %d/3\nOBJETIVO: %s\nWASD/flechas: volar · Z: melee · X: disparo" % [bee.health.current_health,pollen_count,objective]



