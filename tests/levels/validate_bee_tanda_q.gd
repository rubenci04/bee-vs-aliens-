extends "res://tests/levels/bee_t7b_fixture.gd"

const HEALTH := preload("res://scripts/game/bee_enemy_health_settings.gd")
const HONEY_BURST := preload("res://scripts/vfx/bee_honey_bomb_burst.gd")
const BOMB_SCENE := preload("res://scenes/bee_prototype/bee_alien_bomb.tscn")
const EXPECTED_HP := { # Vida de los insectos que G redujo.
	"FlyCommon": 27, "FlyGreen": 30, "Wasp": 30, "Ant": 27,
	"Ladybird": 30, "WormA": 45, "WormB": 45, "StagBeetle": 45,
	"Snail": 45, "Spider": 66, "MushroomCannon": 45,
}
const EXPECTED_VOLLEY_COUNT := 5 # Disparos de las ráfagas nuevas.
const EXPECTED_LADYBIRD_DAMAGE := 2 # Daño por disparito de mariquita.
const EXPECTED_SECOND_SPIDERS := 3 # Arañas de la segunda tanda.
const BOMB_TARGET_OFFSET := Vector3(4.0, 1.0, 0.0) # Blanco cercano para comprobar guiado.
const BOMB_STEP_SECONDS := 0.1 # Paso de vuelo para observar el giro.

func run() -> void:
	var stage := await fixture()
	var wave := stage.wave as BeeLevel01Controller
	for family in EXPECTED_HP:
		check(int(HEALTH.COMMON_HP[family]) == int(EXPECTED_HP[family]) and BeeLevel01Controller.level_hp(family) == int(EXPECTED_HP[family]), "G1: vida reducida de " + family)
	check(AssetFauna.LADYBIRD_VOLLEY_COUNT == EXPECTED_VOLLEY_COUNT and AssetFauna.LADYBIRD_VOLLEY_DAMAGE == EXPECTED_LADYBIRD_DAMAGE, "G2: mariquita dispara cinco proyectiles de daño dos")
	check(BeeEnemyPatterns.fan_directions(Vector3.RIGHT, AssetFauna.LADYBIRD_VOLLEY_COUNT, AssetFauna.LADYBIRD_VOLLEY_STEP_DEGREES).size() == EXPECTED_VOLLEY_COUNT, "G2: abanico genera cinco direcciones")
	check(WalkerMiniboss.AIR_VOLLEY_SHOTS == EXPECTED_VOLLEY_COUNT and &"air_volley" in WalkerMiniboss.PATTERN and &"air_volley" in WalkerMiniboss.PATTERN_NO_CANNON, "G7: robot tiene ráfaga aérea con y sin cañón")
	check(BeeLevel01Controller.SPIDER_SECOND_WAVE.size() == EXPECTED_SECOND_SPIDERS and BeeLevel01Controller.SPIDER_SECOND_WAVE.all(func(unit): return unit == "Spider"), "G8: segunda tanda tiene tres arañas")
	var spider_wave_found := false
	for event in wave.events_table():
		if str(event.get("debut", "")) != "Spider":
			continue
		for inner in event.get("arena", []):
			if bool(inner.get("after_spiders_clear", false)) and inner.get("units", []) == BeeLevel01Controller.SPIDER_SECOND_WAVE:
				spider_wave_found = true
	check(spider_wave_found, "G8: la segunda tanda espera a que caigan las primeras")
	var bomb := BOMB_SCENE.instantiate() as BeeAlienBomb
	stage.add_child(bomb)
	bomb.set_physics_process(false)
	bomb.source_player = stage.bee
	bomb.global_position = stage.bee.global_position
	bomb.direction = Vector3.RIGHT
	var target := Node3D.new()
	target.add_to_group("bee_auto_aim_targets")
	stage.add_child(target)
	target.global_position = bomb.global_position + BOMB_TARGET_OFFSET
	check(bomb._choose_target() == target, "G6: bomba elige un blanco hacia adelante")
	bomb.homing_target = target
	bomb._physics_process(BOMB_STEP_SECONDS)
	check(bomb.direction.y > 0.0, "G6: bomba gira hacia el blanco")
	var burst_host := Node3D.new()
	stage.add_child(burst_host)
	HONEY_BURST.spawn(burst_host, bomb.global_position, bomb.radius)
	var droplets := burst_host.get_children().filter(func(node): return node is CPUParticles3D)
	check(burst_host.has_node("HoneyFlash") and droplets.size() == 2, "G6: explosión visual de miel y polen")
	check(bomb.HONEY_BURST == HONEY_BURST, "G6: bomba usa el efecto de miel")
	print("TANDA_Q failures=", failures)
	done()
