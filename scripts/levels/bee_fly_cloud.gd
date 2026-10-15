extends AssetFauna
## Only this administrator has a movement callback. Members have passive damage/target descriptors.
const S := preload("res://scripts/game/bee_fly_cloud_settings.gd")
const BATCH := preload("res://scripts/vfx/bee_fly_cloud_mesh.gd")
enum Flight { FORMATION, WARN, DIVE, RETURN, RELEASE, EMPTY }

class FlyTarget extends Node3D:
	var cloud: Node3D
	var health: HealthComponent
	var alive := false
	func is_active() -> bool:
		return alive and not health.damage_blocked and cloud.is_active() and not bool(cloud.get_meta("level_retreat",false))
	func is_defeated() -> bool: return not alive

class Member:
	var node: FlyTarget
	var hp: HealthComponent
	var hurt: DamageHurtbox3D
	var attack: DamageHitbox3D
	var mode := Flight.EMPTY
	var left := 0.0
	var delay := 0.0
	var phase := 0.0
	var direction := Vector3.ZERO
	var collision_active := false
	var attack_active := false
	var warning_started := 0.0
	var cue_scale := 1.0
	var cue_flash := 0.0

var members: Array[Member] = []
var instances: MultiMesh
var reserve := 0
var population := 0
var visible_limit := S.VISIBLE_LIMIT
var dives_started := 0
var _next_dive := S.FIRST_DIVE_SECONDS
var _seed := 0.0
var _last_batch := 0

func _ready() -> void:
	kind = &"fly_cloud"
	config = KINDS[kind]
	damage = S.DIVE_DAMAGE
	add_to_group("asset_fauna")
	add_to_group("controlled_fauna")
	rig = Node3D.new()
	rig.name = "Rig"
	add_child(rig)
	var batch := MultiMeshInstance3D.new()
	batch.name = "CloudInstances"
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instances = MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_custom_data = true
	instances.mesh = BATCH.get_mesh()
	batch.multimesh = instances
	rig.add_child(batch)
	visual = batch
	health = HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = int(BeeGameSettings.ENEMY_HEALTH.COMMON_HP["FlyCloud"])
	add_child(health)
	health.died.connect(_on_died)
	_seed = float(get_instance_id()%997)*0.13
	configure_population(health.max_health)
	hide()
	set_physics_process(false)

func configure_population(count: int, stress_visible := 0) -> void:
	# Only the development benchmark may raise the visible limit; exported builds stay at 24.
	visible_limit = S.VISIBLE_LIMIT
	if stress_visible > 0 and OS.is_debug_build() and not OS.has_feature("standalone"):
		visible_limit = clampi(stress_visible,1,60)
	population = maxi(1,count)
	health.max_health = population
	health.current_health = population
	reserve = population
	while members.size() < mini(visible_limit,population): _make_member(members.size())
	instances.instance_count = members.size()
	for i in members.size():
		members[i].mode = Flight.EMPTY
		members[i].node.alive = false
		members[i].node.remove_from_group("bee_auto_aim_targets")
		members[i].node.hide()
		_set_collision(members[i],false)
		if reserve > 0 and i < visible_limit: _spawn_member(i)
	_sync_instances()

func _make_member(index: int) -> void:
	var fly := Member.new()
	fly.node = FlyTarget.new()
	fly.node.cloud = self
	fly.node.name = "Fly_%02d"%index
	add_child(fly.node)
	fly.hp = HealthComponent.new()
	fly.hp.name = "HealthComponent"
	fly.hp.max_health = S.FLY_HP
	fly.hp.damage_blocked = true
	fly.node.add_child(fly.hp)
	fly.node.health = fly.hp
	fly.hurt = HURTBOX_SCENE.instantiate()
	fly.hurt.name = "Hurtbox3D"
	fly.hurt.health_component_path = ^"../HealthComponent"
	fly.hurt.owner_entity_path = ^".."
	fly.hurt.team_id = &"alien"
	fly.hurt.collision_layer = 0
	fly.hurt.monitorable = false
	fly.node.add_child(fly.hurt)
	var sphere := SphereShape3D.new()
	sphere.radius = S.HIT_RADIUS
	for area in [fly.hurt]:
		var shape := CollisionShape3D.new()
		shape.shape = sphere
		shape.disabled = true
		area.add_child(shape)
	fly.attack = HITBOX_SCENE.instantiate()
	fly.attack.name = "DiveHitbox"
	fly.attack.team_id = &"alien"
	fly.attack.attacker_path = ^"../.."
	fly.attack.damage = S.DIVE_DAMAGE
	var attack_shape := CollisionShape3D.new()
	attack_shape.shape = sphere
	attack_shape.disabled = true
	fly.attack.add_child(attack_shape)
	fly.node.add_child(fly.attack)
	fly.hp.died.connect(_on_member_died.bind(index))
	fly.attack.hit_confirmed.connect(_on_dive_hit.bind(index))
	fly.phase = float(index)*2.399963 + _seed
	members.append(fly)
	if index == 0:
		hurtbox = fly.hurt
		body_hurtbox = fly.hurt

func _spawn_member(index: int) -> void:
	var fly := members[index]
	reserve -= 1
	fly.mode = Flight.FORMATION
	fly.node.alive = true
	fly.hp.damage_blocked = true # Collision activation explicitly unblocks only readable/near members.
	fly.hp.restore_health(S.FLY_HP)
	fly.node.position = _formation(index)
	fly.node.show()
	fly.node.add_to_group("bee_auto_aim_targets")

func _formation(index: int) -> Vector3:
	var fly := members[index]
	var radius := sqrt((index+0.5)/float(members.size()))
	return Vector3(cos(fly.phase)*radius*S.SPREAD.x+0.10*sin(_clock*3+fly.phase),sin(fly.phase)*radius*S.SPREAD.y+0.12*cos(_clock*4+fly.phase),0)

func _physics_process(delta: float) -> void:
	_clock += delta
	if state == State.DONE: return
	if is_instance_valid(target) and not liberated:
		if target.is_defeated:
			state = State.EXIT
			global_position.x -= 6.0*delta
		else:
			var goal := Vector3(target.global_position.x+S.HOVER_OFFSET+0.65*sin(_seed),clampf(target.global_position.y+0.5*sin(_seed),1.7,5.3),0)
			global_position = global_position.move_toward(goal,S.HOVER_SPEED*delta)
			_next_dive -= delta
			if _next_dive <= 0: _start_telegraph()
	var camera := get_viewport().get_camera_3d()
	for i in members.size():
		var fly := members[i]
		match fly.mode:
			Flight.FORMATION:
				fly.node.position = _formation(i)
			Flight.WARN:
				if fly.delay > 0:
					fly.delay -= delta
					fly.warning_started = _clock
				else:
					fly.left -= delta
					fly.node.position = _formation(i)+Vector3(0,0.35,0)
					if fly.left <= 0:
						telegraphs.append(_clock-fly.warning_started)
						fly.direction = (target.global_position-fly.node.global_position).normalized()
						fly.mode = Flight.DIVE
						fly.left = S.DIVE_SECONDS
						dives_started += 1
			Flight.DIVE:
				fly.node.global_position += fly.direction*S.DIVE_SPEED*delta
				fly.left -= delta
				if fly.left <= 0: fly.mode = Flight.RETURN
			Flight.RETURN:
				fly.node.position = fly.node.position.move_toward(_formation(i),S.RETURN_SPEED*delta)
				if fly.node.position.distance_to(_formation(i))<0.08: fly.mode = Flight.FORMATION
			Flight.RELEASE:
				fly.left -= delta
				fly.node.position += Vector3(-0.5,1.6,-1.0)*delta
				if fly.left <= 0:
					fly.mode = Flight.EMPTY
					fly.node.hide()
					if reserve > 0 and not liberated: _spawn_member(i)
		var near := is_instance_valid(target) and fly.node.global_position.distance_squared_to(target.global_position)<=S.NEAR_RADIUS*S.NEAR_RADIUS
		var screen := camera == null or (not camera.is_position_behind(fly.node.global_position) and get_viewport().get_visible_rect().has_point(camera.unproject_position(fly.node.global_position)))
		var live := fly.node.alive and not liberated and state != State.EXIT
		_set_collision(fly,live and (near or screen))
		var attacking := live and fly.collision_active and fly.mode == Flight.DIVE
		_set_attack(fly,attacking)
	_sync_instances()
	if liberated and members.all(func(fly): return fly.mode == Flight.EMPTY): _finish()

func _set_collision(fly: Member, enabled: bool) -> void:
	if fly.collision_active == enabled: return
	fly.collision_active = enabled
	fly.hp.damage_blocked = not enabled
	fly.hurt.set_deferred("collision_layer",2 if enabled else 0)
	fly.hurt.set_deferred("monitorable",enabled)
	for shape in fly.hurt.get_children():
		if shape is CollisionShape3D: shape.set_deferred("disabled",not enabled)
	if not enabled: _set_attack(fly,false)

func _set_attack(fly: Member, enabled: bool) -> void:
	if fly.attack_active == enabled: return
	fly.attack_active = enabled
	fly.attack.set_enabled(enabled)
	for shape in fly.attack.get_children():
		if shape is CollisionShape3D: shape.set_deferred("disabled",not enabled)

func _start_telegraph() -> void:
	if liberated or not is_instance_valid(target) or target.is_defeated: return
	var candidates: Array[int] = []
	var camera := get_viewport().get_camera_3d()
	for offset in members.size():
		var index := (_last_batch+offset)%members.size()
		var fly := members[index]
		if fly.mode != Flight.FORMATION or not fly.collision_active: continue
		if camera != null and (camera.is_position_behind(fly.node.global_position) or not get_viewport().get_visible_rect().has_point(camera.unproject_position(fly.node.global_position))): continue
		candidates.append(index)
	if candidates.is_empty():
		_next_dive = S.TOKEN_RETRY_SECONDS
		return
	if not BeeAttackTokens.try_claim(self,S.WARNING_SECONDS+S.DIVE_SECONDS+S.WARNING_STAGGER*S.DIVE_MAX):
		_next_dive = S.TOKEN_RETRY_SECONDS
		return
	var count := S.DIVE_MIN + (attacks_started% (S.DIVE_MAX-S.DIVE_MIN+1))
	var selected := 0
	for index in candidates:
		var fly := members[index]
		fly.mode = Flight.WARN
		fly.left = S.WARNING_SECONDS
		fly.delay = selected*S.WARNING_STAGGER
		fly.warning_started = _clock
		selected += 1
		if selected == count:
			_last_batch = (index+1)%members.size()
			break
	if selected > 0: attacks_started += 1
	_next_dive = S.DIVE_INTERVAL if selected > 0 else S.TOKEN_RETRY_SECONDS

func _sync_instances() -> void:
	for i in members.size():
		var fly := members[i]
		var scale_factor := S.VISUAL_SCALE
		var flash := 0.0
		if fly.mode == Flight.EMPTY: scale_factor = 0
		elif fly.mode == Flight.RELEASE: scale_factor *= maxf(fly.left/S.RELEASE_SECONDS,0)
		elif fly.mode == Flight.WARN and fly.delay <= 0:
			var t := clampf(1.0-fly.left/S.WARNING_SECONDS,0,1)
			scale_factor *= lerpf(1.0,S.WARNING_SCALE,sin(PI*t))
			flash = 0.5+0.5*sin(t*TAU*2)
		var angle := atan2(fly.direction.y,-fly.direction.x) if fly.mode == Flight.DIVE else 0.0
		fly.cue_scale = scale_factor/S.VISUAL_SCALE
		fly.cue_flash = flash
		var basis := Basis(Vector3.FORWARD,angle).scaled(Vector3.ONE*scale_factor)
		instances.set_instance_transform(i,Transform3D(basis,fly.node.position-basis*BATCH.center))
		instances.set_instance_custom_data(i,Color(fly.phase,_clock,1 if fly.mode == Flight.RELEASE else 0,flash))

func _on_member_died(index: int) -> void:
	var fly := members[index]
	if not fly.node.alive: return
	fly.node.alive = false
	fly.node.remove_from_group("bee_auto_aim_targets")
	fly.mode = Flight.RELEASE
	fly.left = S.RELEASE_SECONDS
	_set_collision(fly,false)
	health.take_damage(1)

func _on_dive_hit(_hurt: DamageHurtbox3D, _amount: int, index: int) -> void:
	members[index].mode = Flight.RETURN
	_set_attack(members[index],false)

func _on_died() -> void:
	if liberated: return
	liberated = true
	state = State.LIBERATED
	set_physics_process(true) # Cleanup must also finish if the director/tool froze the actor before freeing it.
	reserve = 0
	BeeAttackTokens.release(self)
	for fly in members:
		fly.node.alive = false
		fly.node.remove_from_group("bee_auto_aim_targets")
		_set_collision(fly,false)
		if fly.mode != Flight.EMPTY:
			fly.mode = Flight.RELEASE
			fly.left = S.RELEASE_SECONDS
	liberated_now.emit(self)
	BeeLiberation.free_animal(get_parent(),null,null,global_position)

func _exit_tree() -> void:
	BeeAttackTokens.release(self)
