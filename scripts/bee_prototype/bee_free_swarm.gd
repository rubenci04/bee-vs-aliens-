extends Node3D
## Tanda V · ENJAMBRE LIBRE — el movimiento firma de Bee. Cada insecto liberado suma 1 a la barra de Liberación; con la
## barra llena, la acción bee_swarm (E / cruceta arriba) llama SWARM_ALLIES insectos liberados (moscas y mariquitas con su
## color natural, sin implante) que orbitan a Bee SWARM_SECONDS y disparan agujas doradas al enemigo más cercano.
## Contra jefes: nunca durante su entrada (no están activos) y a la mitad de daño (DamageHurtbox3D, meta "swarm_shot").
const S := preload("res://scripts/game/bee_free_swarm_settings.gd")

signal activated
signal ended

var bee: BeePlayer
var charge := 0
var active_left := 0.0
var uses := 0 # Veces que se llamó (entrenamiento, tests, informe).
var shots := 0
var allies: Array[Node3D] = []
var _clocks: Array[float] = []
var _age := 0.0


static func attach(stage: Node, player: BeePlayer) -> Node3D:
	if not S.FREE_SWARM_ENABLED or player == null:
		return null
	ensure_action()
	var swarm := (load("res://scripts/bee_prototype/bee_free_swarm.gd") as GDScript).new() as Node3D
	swarm.name = "FreeSwarm"
	swarm.set("bee", player)
	stage.add_child(swarm)
	return swarm


## La acción existe aunque el autoload de entrada no haya corrido (tests sueltos).
static func ensure_action() -> void:
	if InputMap.has_action(S.ACTION):
		return
	InputMap.add_action(S.ACTION)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	InputMap.action_add_event(S.ACTION, key)
	var pad := InputEventJoypadButton.new()
	pad.device = -1
	pad.button_index = JOY_BUTTON_DPAD_UP
	InputMap.action_add_event(S.ACTION, pad)


func _ready() -> void:
	add_to_group("bee_free_swarm")


func is_ready() -> bool:
	return charge >= S.SWARM_CHARGE_NEEDED and active_left <= 0.0


func is_active() -> bool:
	return active_left > 0.0


func ratio() -> float:
	return clampf(float(charge) / float(S.SWARM_CHARGE_NEEDED), 0.0, 1.0)


## Un insecto liberado: +1 (no carga mientras el enjambre está afuera).
func add_charge(amount := 1) -> void:
	if active_left <= 0.0:
		charge = mini(S.SWARM_CHARGE_NEEDED, charge + amount)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(S.ACTION) and not get_tree().paused:
		activate()


## Llama al enjambre si la barra está llena. Devuelve si salió.
func activate() -> bool:
	if not is_ready() or not is_instance_valid(bee) or bee.is_defeated:
		return false
	charge = 0
	uses += 1
	active_left = S.SWARM_SECONDS
	_age = 0.0
	for i in S.SWARM_ALLIES:
		var ally := _make_ally(i)
		allies.append(ally)
		_clocks.append(S.SWARM_SHOT_EVERY * (0.3 + float(i) / float(S.SWARM_ALLIES))) # Desfasados: no disparan todos juntos.
	BeeAudio.play(get_parent(), &"liberate", bee.global_position, 1.2)
	activated.emit()
	return true


func _make_ally(index: int) -> Node3D:
	var holder := Node3D.new()
	holder.name = "SwarmAlly%d" % index
	var model := (load(S.ALLY_MODELS[index % S.ALLY_MODELS.size()]) as PackedScene).instantiate() as Node3D
	model.scale = Vector3.ONE * S.ALLY_SCALE
	holder.add_child(model)
	for node in model.find_children("*", "Node3D", true, false):
		if "implant" in str(node.name).to_lower():
			(node as Node3D).hide() # Liberados: sin implante.
	BeeLiberation.warm_colours(model) # Color natural, sin brillo alien.
	for player: AnimationPlayer in model.find_children("*", "AnimationPlayer", true, false):
		var clips := player.get_animation_list()
		if not clips.is_empty():
			player.play(clips[0])
	add_child(holder)
	holder.global_position = bee.global_position + Vector3(-1.5, 0.0, 0.0)
	return holder


func _physics_process(delta: float) -> void:
	if active_left <= 0.0:
		return
	if not is_instance_valid(bee) or bee.is_defeated:
		_dismiss()
		return
	active_left -= delta
	_age += delta
	var arrive := clampf(_age / S.ARRIVE_SECONDS, 0.0, 1.0)
	for i in allies.size():
		var ally := allies[i]
		if not is_instance_valid(ally):
			continue
		var angle := _age * S.ORBIT_SPEED + TAU * float(i) / float(allies.size())
		var orbit := bee.global_position + Vector3(cos(angle) * S.ORBIT_RADIUS, sin(angle) * S.ORBIT_RADIUS * S.ORBIT_SQUASH, 0.35 * sin(angle))
		var before := ally.global_position
		ally.global_position = before.lerp(orbit, arrive if arrive < 1.0 else minf(1.0, delta * 12.0))
		if absf(ally.global_position.x - before.x) > 0.001:
			ally.rotation.y = -PI * 0.5 if ally.global_position.x > before.x else PI * 0.5 # Mira hacia donde va.
		_clocks[i] -= delta
		if _clocks[i] <= 0.0 and arrive >= 1.0:
			_clocks[i] = S.SWARM_SHOT_EVERY
			var target := nearest_target(ally.global_position)
			if target != null:
				_fire(ally.global_position, target)
	if active_left <= 0.0:
		_dismiss()


## El enemigo vivo más cercano en pantalla; los jefes solo cuando ya están activos (nunca en su entrada).
func nearest_target(from: Vector3) -> Node3D:
	var best: Node3D
	var best_distance := S.SWARM_RANGE
	var camera := get_viewport().get_camera_3d()
	for node in get_tree().get_nodes_in_group("bee_auto_aim_targets"):
		var unit := node as Node3D
		if unit == null or not unit.is_visible_in_tree() or bool(unit.get_meta("teleporting", false)):
			continue
		if unit.has_method("is_active") and not bool(unit.call("is_active")):
			continue
		if unit.has_method("is_defeated") and bool(unit.call("is_defeated")):
			continue
		if camera != null and (camera.is_position_behind(unit.global_position) or not get_viewport().get_visible_rect().has_point(camera.unproject_position(unit.global_position))):
			continue
		var distance := unit.global_position.distance_to(bee.global_position)
		if distance < best_distance:
			best_distance = distance
			best = unit
	return best


func _fire(from: Vector3, target: Node3D) -> void:
	if bee.projectile_scene == null:
		return
	var shot := bee.projectile_scene.instantiate() as BeeEnergyProjectile
	shot.damage = S.SWARM_SHOT_DAMAGE
	shot.configured_weapon_damage = true # Sin el piso de daño de los enemigos chicos: 2 es 2.
	shot.set_meta("swarm_shot", true)
	bee.get_parent().add_child(shot)
	shot.global_position = Vector3(from.x, from.y, bee.global_position.z)
	shot.launch((target.global_position - shot.global_position).normalized(), bee)
	shots += 1


func _dismiss() -> void:
	active_left = 0.0
	for ally in allies:
		if is_instance_valid(ally):
			var away := ally.create_tween()
			away.tween_property(ally, "global_position", ally.global_position + Vector3(-3.0, 3.0, -2.0), 0.6)
			away.tween_callback(ally.queue_free)
	allies.clear()
	_clocks.clear()
	ended.emit()
