class_name BeeLevel01Controller
extends Node3D

signal wave_completed
## Enemy-free director set pieces ("opening_can", "human_aftermath", ...; "last_silence" before the UFO).
signal director_moment(id: StringName)
## LOTE 11: a unit was destroyed or freed (score / combo / hit stop, see BeeLevel01Juice) and an enemy took a hit (keeps the combo alive).
signal unit_downed(unit: Node3D, liberated: bool)
signal enemy_hit

const WASP = preload("res://scenes/bee_prototype/wasp_enemy.tscn")
const PROBE = preload("res://scenes/bee_prototype/alien_probe_ranged.tscn")
const EYE = preload("res://scenes/bee_prototype/eye_drone_enemy.tscn")
const TURRET = preload("res://scenes/bee_prototype/ground_turret_enemy.tscn")
const SPEEDER = preload("res://scenes/bee_prototype/speeder_enemy.tscn")
const ORGANIC = preload("res://scenes/bee_prototype/organic_alien_enemy.tscn")
const WALKER = preload("res://scenes/bee_prototype/ground_walker_enemy.tscn")
const UFO_BOSS = preload("res://scenes/levels/ufo_boss_01.tscn")
const POWERUP_PICKUP = preload("res://scenes/bee_prototype/bee_powerup_pickup.tscn")
const DRAGONFLY = preload("res://scenes/levels/controlled_dragonfly.tscn")
const SWARM = preload("res://scenes/levels/popcorn_drone.tscn")
const TURTLE = preload("res://scenes/levels/garden_turtle.tscn") # LOTE 12: garden turtle tank (BeeGardenTurtle).
## LOTE 12 · ETAPA 3: the walking robot as mini-boss (event "miniboss") and the tarantula, final boss of Level 1 (roster only).
const WALKER_MINIBOSS = preload("res://scenes/levels/walker_miniboss.tscn")
const TARANTULA = preload("res://scenes/levels/tarantula_boss_01.tscn")
## Mini-boss robot HP (Normal; EASY scales it). Target fight: 25-40 s with Base (validate_bee_walker_miniboss_v01).
const MINIBOSS_HP := 600
## Breather between the robot and the tarantula's entrance (arena locked, supplies when needed).
const TARANTULA_BREATHER := 2.6
## LOTE 13 · ETAPA 2: rule "every enemy starts attacking within ~1 s of entering the screen": rest before the first attack of a fauna unit (s).
const FIRST_ATTACK_REST := 0.25
## ...and the longest allowed time from entering the screen to the first warning (tests measure it).
const FIRST_ATTACK_MAX_DELAY := 1.0
## Damage scale of the flies the tarantula summons (their ram is 11 on the route scale of 1).
const TARANTULA_MINION_DAMAGE_SCALE := 1.0 # LOTE 14: common bullets now do 3 (were 7), so the summons keep more of their damage (was 0.3)
## After the tarantula walks away the sector ends this far ahead (the garden geometry runs to X=360; no 30 s empty run-out).
const TARANTULA_RUN_OUT := 10.0
## LOTE 6 — Codex GLB fauna (scripts/levels/asset_fauna.gd): family name -> scene.
const ASSET_FAUNA := {
	"Mosquito": preload("res://scenes/levels/asset_fauna/mosquito.tscn"), "Ladybird": preload("res://scenes/levels/asset_fauna/ladybird.tscn"),
	"WaveDragonfly": preload("res://scenes/levels/asset_fauna/dragonfly.tscn"), "Moth": preload("res://scenes/levels/asset_fauna/moth.tscn"),
	"Ant": preload("res://scenes/levels/asset_fauna/ant.tscn"), "StagBeetle": preload("res://scenes/levels/asset_fauna/stag_beetle.tscn"),
	"Snail": preload("res://scenes/levels/asset_fauna/snail.tscn"), "MushroomCannon": preload("res://scenes/levels/asset_fauna/mushroom.tscn"),
	"SeedCarrier": preload("res://scenes/levels/asset_fauna/seed_carrier.tscn"),
	# LOTE 12 · ETAPA 2: the Level 1 roster species.
	"FlyCommon": preload("res://scenes/levels/asset_fauna/fly_common.tscn"), "FlyGreen": preload("res://scenes/levels/asset_fauna/fly_green.tscn"),
	"FlyCloud": preload("res://scenes/levels/asset_fauna/fly_cloud.tscn"), "WormA": preload("res://scenes/levels/asset_fauna/worm_rose.tscn"),
	"WormB": preload("res://scenes/levels/asset_fauna/worm_compost.tscn"),
	"AlienFighter": preload("res://scenes/levels/asset_fauna/fighter.tscn"), # NOCHE 01 · ETAPA 2: Codex interceptor (dusk).
}
## NOCHE 01 — animals (freed, never killed) counted for "LIBERADOS n/N"; everything else is technology and explodes.
const ANIMAL_FAMILIES := ["Wasp", "Dragonfly", "Spider", "Mosquito", "Ladybird", "WaveDragonfly", "Moth", "Ant", "StagBeetle", "Snail",
		"FlyCommon", "FlyGreen", "FlyCloud", "WormA", "WormB", "Turtle"]
## NOCHE 01 · ETAPA 2: Level 01 enemies fire the Codex toon alien bolt (same AlienEnemyProjectile rules, new look).
const TOON_HEALING := preload("res://scenes/items/toon/pollen_cluster.tscn") # LOTE 13: pollen cluster (was the honey jar).
const BOSS_HEAL_BELOW := 0.7 # Fraction of max HP under which the honey jar appears before the UFO.
const TOON_ALIEN_BOLT := preload("res://scenes/projectiles/toon/alien_bolt.tscn")
const ASSET_AIR := ["Mosquito", "Ladybird", "WaveDragonfly", "Moth", "SeedCarrier", "AlienFighter", "FlyCommon", "FlyGreen", "FlyCloud"]
## GARDEN IDENTITY 04: alien-controlled garden spider, a VERTICAL LANE THREAT (3 appearances: acts 2, 3, 4).
const SPIDER = preload("res://scenes/levels/controlled_spider.tscn")
## Camera-relative X where a spider drops in from above the top edge when the event gives none (inside the screen).
const SPIDER_ENTRY_X := 1.2
## One-off hint the first time controlled fauna appears: the animal is not the enemy, the implant is.
const FAUNA_HINT := "DESTRUÍ EL IMPLANTE"
## Breather between the last encounter and the UFO approach (arena already locked): "the last silence"
## (light dips, a hum rises, the UFO shadow sweeps the garden), then the unchanged reveal. Was 1.6 s.
const BOSS_BREATHER := 2.6
## LOTE 10: non-popcorn route caps rise 4 -> 5 -> 6 at the existing intensity thresholds.
const THREE_AT_ONCE_FROM := 96.0
const FOUR_AT_ONCE_FROM := 240.0
## Popcorn drones alive at once (their own budget, outside the threat cap).
const MAX_SWARM_ALIVE := 6
## Popcorn paths by name (index = PopcornDrone.PathKind).
const SWARM_PATHS := ["sine", "arc_top", "arc_bottom", "dive", "straight", "kamikaze"]
## LOTE 9 — enemies alive at once, popcorn INCLUDED: MAX_ON_SCREEN on the route, MAX_ON_SCREEN_ARENA in a combat zone
## (the threat cap above still limits the non-popcorn threats). Boss minions are outside this budget (MAX_BOSS_MINIONS).
## LOTE 11: non-popcorn threats alive at once at the end of the route (was MAX_ON_SCREEN = 6).
const MAX_ROUTE_THREATS := 6
const MAX_ON_SCREEN := 7 # LOTE 11: 6 -> 7 (the extra slot is popcorn: threat caps below are unchanged).
const MAX_ON_SCREEN_ARENA := 10 # LOTE 11: 8 -> 10 in combat zones.
## Live hostile shots before Level 01 units hold their fire (see BeeShmupFairness.live_shot_ceiling).
const LIVE_SHOT_CEILING := 16
## Denser route volleys trade burst damage for more dodge decisions; UFO damage is unchanged.
const ROUTE_DAMAGE_SCALE := 1.0 # LOTE 14: the LOTE 13 chip-damage hack (0.15) is gone; common bullets are calibrated to 3-5 instead (shot_damage / SHOT_DAMAGE).
## Smallest gap between two authored entries of the same encounter (never the same frame).
const MIN_FORMATION_GAP := 0.2
## REBUILD 03: Wasp implant sting / overload are introduced progressively (see `_spawn`).
const STING_FROM_X := 40.0
const OVERLOAD_FROM_X := 150.0
## Camera-relative X where a cinematic depth entry reaches the flight plane (inside the right half of the screen).
const DEPTH_TARGET_X := 3.4
## Scroll speed while a showcase Walker ("hold") is alive: it walks with Bee instead of being left behind.
const HOLD_SCROLL := 1.0
## LOTE 7 — PACING: cruise scroll of Level 01 in m/s (was 2.0). Every place that resumed the scroll uses it.
## LOTE 9: 1.5 -> 1.25 m/s. With 69 units (was 137) the bot reached the UFO at 295 s; the slower cruise, ARENA_MIN_SECONDS
## and a longer breather bring it back to the 5.5-6.5 min target.
const LEVEL_SCROLL := 1.25
## NOCHE 01 · ETAPA 2: the Giant Human is switched off (code, scene and tests kept). Tests that cover it set
## `giant_human_enabled = true` before loading the level.
const GIANT_HUMAN_ENABLED := false
static var giant_human_enabled := GIANT_HUMAN_ENABLED
## Short roll to the sector end after the UFO (unchanged 2.0).
const POST_BOSS_SCROLL := 2.0
## LOTE 7 — "time on camera": minimum seconds a unit of each family stays in play (enters, settles, attacks) before the
## director retires it (it never leaves on its own earlier: its own pass/attack counters are raised in LEVEL_TUNING).
## Families not listed use soft_pressure_seconds. Popcorn (Swarm) is a crossing pattern by design and keeps its paths.
const CAMERA_TIME := {"Wasp": 12.0, "Probe": 13.0, "EyeDrone": 13.0, "Speeder": 10.0, "OrganicAlien": 13.0, "Walker": 16.0,
		"Turret": 14.0, "Dragonfly": 14.0, "Spider": 12.0, "Mosquito": 10.0, "Ladybird": 15.0, "WaveDragonfly": 12.0, "Moth": 13.0,
		"Ant": 12.0, "StagBeetle": 14.0, "Snail": 15.0, "MushroomCannon": 13.0, "SeedCarrier": 22.0, "AlienFighter": 12.0,
		"FlyCommon": 10.0, "FlyGreen": 11.0, "FlyCloud": 11.0, "WormA": 11.0, "WormB": 10.0, "Turtle": 24.0}
## LOTE 7 — COMBAT ZONES ("arena" key in EVENTS): the scroll creeps at ARENA_SCROLL while the zone plays its waves one after
## another (next wave when the field has been clear ARENA_WAVE_GAP s, or after ARENA_WAVE_MAX s), then a breather of
## BREATHER_SECONDS with no new encounters lets the landscape scroll by. ARENA_MAX_SECONDS is a safety cap.
const ARENA_SCROLL := 0.3
const ARENA_WAVE_GAP := 1.2
const ARENA_WAVE_CADENCE := 6.0
const ARENA_WAVE_MAX := 9.0
const ARENA_MAX_SECONDS := 36.0
## LOTE 9: with 2 waves a zone could end in ~14 s: it now lasts at least this long (the scroll keeps creeping).
const ARENA_MIN_SECONDS := 28.0
## LOTE 13 · ETAPA 2: the roster zones are denser: 6 waves, a new one every 4 s once the field is clear (6 s at most), 28-36 s per zone.
const ROSTER_ARENA_CADENCE := 3.0
const ROSTER_ARENA_WAVE_MAX := 5.0
## LOTE 14: the first wave of a roster zone follows its host event after this long (the host units are spaced by their own delays).
const ROSTER_FIRST_WAVE_DELAY := 1.8
const ROSTER_ARENA_MAX_SECONDS := 36.0
const ROSTER_ARENA_MIN_SECONDS := 28.0
const BREATHER_SECONDS := 1.0 # LOTE 10: short transition; route patrols maintain pressure.

## LOTE 14 · ETAPA 2: GRADUAL INTRODUCTION. An event (or a combat zone) with a "debut" key introduces a new species: it waits for a clear field
## (at most DEBUT_CLEAR_MAX s: the remaining units are then sent away) and, for DEBUT_SOLO_SECONDS, nothing else is launched. The first
## spawn of every species shows its name for SPECIES_NAME_SECONDS in small letters.
const DEBUT_SOLO_SECONDS := 8.0
const DEBUT_CLEAR_MAX := 0.8
const SPECIES_NAME_SECONDS := 1.5
## LOTE 14 · ETAPA 2.3: with real damage (scale 1.0) the dense table is lethal, so the roster attacks less often: this multiplies the rests between attacks
## (idle / recovery / restalk of every unit and the implant cooldown). Warnings, projectile speed and damage are untouched.
const ROSTER_FIRE_SLOWDOWN := 2.79
## LOTE 14: the rests start shorter (ROSTER_FIRE_SLOWDOWN_FROM at X=0: the first minutes already bite a little) and ramp up to ROSTER_FIRE_SLOWDOWN by X=ROSTER_FIRE_RAMP_X.
const ROSTER_FIRE_SLOWDOWN_FROM := 1.2
const ROSTER_FIRE_RAMP_X := 200.0
const ROSTER_REST_KEYS := ["idle_time", "recovery_time", "arcade_recovery", "restalk_time"]
## Slower enemy shots on the roster (dodgeable, longer on screen). Applies to every shot a roster unit fires through BeeEnemyPatterns.
const ROSTER_SHOT_SPEED_SCALE := 0.8
const SPECIES_NAMES := {"FlyCommon": "MOSCA", "Ant": "HORMIGA", "Ladybird": "MARIQUITA", "Wasp": "AVISPA", "FlyGreen": "MOSCA VERDE", "FlyCloud": "NUBE DE MOSCAS",
		"WormA": "GUSANO ROSA", "Snail": "CARACOL", "StagBeetle": "ESCARABAJO", "WormB": "GUSANO DE COMPOST", "Spider": "ARAÑA COLGANTE", "MushroomCannon": "HONGO CAÑÓN"}
## BOSS V2: never more than this many minions alive; they fly out of the saucer in MINION_LAUNCH_SECONDS.
const MAX_BOSS_MINIONS := 2
const MINION_LAUNCH_SECONDS := 0.7

# Level-only HP; reusable enemy scenes and attacks are unchanged.
## THREAT, CAMERA & BOSS REBUILD 03 — HP by ROLE (not by tradition). Reasonable Base fire ~27-33 DPS (3 taps/s, 10 HP,
## auto-aim). Target time-to-kill: POPCORN 0.1-0.8 s, LIGHT 1-2 s, MEDIUM 2.5-4.5 s, HEAVY 4-7 s, SHOWCASE 5-8 s.
##   POPCORN  Swarm 10
##   LIGHT    Wasp 36->44, EyeDrone 28->40, Speeder 30
##   MEDIUM   Probe 38->80, Turret 46->70, OrganicAlien 47->100
##   HEAVY    Walker 72->120 (a showcase Walker gets SHOWCASE_HP 150)
## "Dragonfly" is the HP of its alien IMPLANT (special fauna, unchanged).
## LOTE 9 — TIME TO LIBERATE / DESTROY with Base and normal aim (reference fire: 3 taps/s of 10 HP; on an animal the
## taps go body, implant (2x), body, miss = 30 effective DPS; on technology every tap hits at 1x = 30 DPS):
##   ~0.7 s   Mosquito, Wasp 36                                 (firefly: decoration, not an enemy)
##   1.5-2 s  Ladybird, Moth, MushroomCannon 70 · Ant, WaveDragonfly 64 · Spider 80 (~2.0 s) · Dragonfly 110: it comes
##            head-on and its big implant sphere covers head + thorax, so its taps go implant, implant, implant, miss
##   3-4 s    StagBeetle, Snail 120
##   6-8 s    SeedCarrier 220
##   tech     Speeder 40 (~1.0 s) · EyeDrone 50 (~1.3 s) · Probe, Turret, AlienFighter 70 (~2.0 s) · Walker 100 (~3.0 s),
##            showcase Walker 130 (~4.0 s). Verified by tests/levels/validate_bee_balance_liberation_v04.gd.
## BEFORE: Wasp 44, Probe 80, EyeDrone 40, Speeder 30, Walker 120 (showcase 150), Dragonfly 60, Spider 90, Ladybird 130,
## WaveDragonfly 56, Moth 60, Ant 44, StagBeetle 110, Snail 100, MushroomCannon 60, SeedCarrier 240, AlienFighter 60.
const LEVEL_HP = {"Wasp": 36, "Probe": 70, "EyeDrone": 50, "Turret": 70, "Speeder": 40, "OrganicAlien": 100, "Walker": 100, "Dragonfly": 110, "Swarm": 10, "Spider": 80,
		"Mosquito": 36, "Ladybird": 70, "WaveDragonfly": 64, "Moth": 70, "Ant": 64, "StagBeetle": 120, "Snail": 120, "MushroomCannon": 70, "SeedCarrier": 220, "AlienFighter": 70,
		"FlyCommon": 30, "FlyGreen": 40, "FlyCloud": 24, "WormA": 70, "WormB": 60, "Turtle": 220} # LOTE 12: roster species (fly cloud <= 32: the bomb clears it)
const SHOWCASE_HP := 130
## LOTE 13 · ETAPA 2: the dense roster keeps its enemies on screen longer (more of them visible at once): HP multiplier per family, roster only.
const ROSTER_HP_SCALE := {"FlyCommon": 1.4, "FlyGreen": 1.3, "Wasp": 1.3, "Ladybird": 1.15, "Ant": 1.2, "WormA": 1.15, "WormB": 1.2, "Spider": 1.1}
## LOTE 14 · ETAPA 2: the gradual table spawns fewer units, so each one stays a bit longer (3+ enemies visible from minute 2): extra HP multiplier of the roster species.
const ROSTER_HP_EXTRA := 1.2
const ROSTER_HP_EXTRA_FAMILIES := ["FlyCommon", "FlyGreen", "Wasp", "Ladybird", "Ant", "WormA", "WormB", "Snail", "StagBeetle", "Spider"]
## LOTE 13 · ETAPA 2: tuning that only applies while Level 1 plays its roster (merged over LEVEL_TUNING). Spider: it drops in and warns within ~1 s.
const ROSTER_TUNING := {
	"Spider": {"hang_seconds": 0.15, "enter_seconds": 0.6, "strike_damage": 5, "contact_damage": 2, "reposition_seconds": 1.2}, # LOTE 14: real damage: the thread strike hits for 8, touching the body for 4.
	"Wasp": {"sting_speed": 4.4, "sting_damage": 3, "overload_damage": 5, "attack_damage": 4}, # Slower needles (dodgeable, longer on screen) that do 3; the kamikaze overload 5 and the dive 4 (LOTE 14).
}
const ROLES := {"Swarm": &"POPCORN", "Wasp": &"LIGHT", "EyeDrone": &"LIGHT", "Speeder": &"LIGHT", "Probe": &"MEDIUM",
		"Turret": &"MEDIUM", "OrganicAlien": &"MEDIUM", "Walker": &"HEAVY", "Dragonfly": &"SPECIAL", "Spider": &"MEDIUM",
		"Mosquito": &"LIGHT", "Ladybird": &"HEAVY", "WaveDragonfly": &"LIGHT", "Moth": &"MEDIUM", "Ant": &"LIGHT", "StagBeetle": &"HEAVY", "Snail": &"MEDIUM", "MushroomCannon": &"MEDIUM", "SeedCarrier": &"SHOWCASE", "AlienFighter": &"MEDIUM",
		"FlyCommon": &"LIGHT", "FlyGreen": &"LIGHT", "FlyCloud": &"POPCORN", "WormA": &"MEDIUM", "WormB": &"MEDIUM", "Turtle": &"HEAVY"}
# Level-only tuning (reusable scenes and the family POCs keep their values). Damage, projectile speed and telegraph
# (windup) are never touched; HP is global-unchanged. BEFORE (Arcade Pressure pass 01) -> AFTER (Combat Pattern pass 02):
#   Wasp      2 passes, recovery 0.9 s            -> 3 passes, recovery 1.1 s, stalk 2.2/2.9/3.6 s on lanes (no simultaneous attacks)
#   Probe     burst of 2, cooldown 1.6 s          -> AIMED burst of 3 (0.2 s) -> short recovery 0.8 s -> burst of 3 -> cooldown 2.0 s
#                                                    with advance + vertical reposition
#   EyeDrone  burst of 2, cooldown 1.7 s          -> alternates AIMED burst of 3 and a FAN of 5 (12-18 deg), cooldown 2.0 s
#   Turret    cooldown 1.45 s, single shot        -> fan of 3 (14 deg) centred on Bee, cooldown 1.55 s
#   Walker    recovery 0.9 s, single shot         -> slow burst of 3 (0.35 s apart), recovery 0.9 s
# ARCADE REBUILD 02 (first attack sooner, more presence; windups/damage/shot speed still untouched):
#   Probe     holds and fires from 8.0 m (was 7.5) and never from outside the screen (`stay_on_screen`)
#   EyeDrone  hovers at 3.0-5.0 m (was 2.5-4.0), on screen: attacks from mid range instead of diving into Bee
#   Walker    walks 2.4 m/s, repositions 2.4 m, sees Bee from 10 m: keeps pace with the scroll and stays on screen
#   Cadence   shorter rests between attacks: Probe recovery 0.8->0.55 / cooldown 2.0->1.6, Eye cooldown 2.0->1.5,
#             Turret 1.55->1.3, Walker recovery 0.9->0.7 (telegraphs unchanged, so every attack stays readable)
#   Bursts    Probe / EyeDrone / Walker aimed bursts 3 -> 4 shots (same gap; every shot re-aims and flies straight)
#   Organic   alternates its stalk height above / below Bee after every lunge, recovery 0.75 -> 0.6 s (HP still 47)
# THREAT, CAMERA & BOSS REBUILD 03 (roles; see ROLES / LEVEL_HP):
#   Probe     moves 2.2 -> 3.0 m/s, holds at 8.5 m: telegraphs within ~1 s of being fully on screen
#   Wasp      implant sting (2 aimed bolts while stalking) on some Wasps; OVERLOAD (kamikaze dash from the implant)
#             from mid level - both assigned per spawn in `_spawn`
#   Organic   ranged bio-orbs (fan of 3) -> reposition -> lunge -> recovery (never both at once)
#   Walker    alternates its aimed burst with a high-to-low SWEEP of 5 (violet charge) that forces a height change
#   Speeder   lane telegraph across the screen before its straight dash (fast crossing threat)
#   Cadence   combat-only pressure: Probe cooldown 1.6->1.3 / recovery 0.55->0.45, Eye 1.5->1.2, Turret 1.3->1.1,
#             Walker recovery 0.7->0.6 (telegraphs, damage and shot speed unchanged)
# GARDEN IDENTITY 04 micro-pass (playtest: "a bit more challenge", no rebuild; measured with threat_analysis_04.gd):
#   Wasp      rest between passes (restalk) 1.0 -> 0.85 s
#   EyeDrone  cooldown 1.2 -> 1.1 s
#   Popcorn   the two act-4 rows at X=222 / 245: 3 shooters instead of 2 (one more slow aimed shot each)
#   Spider    new MEDIUM family (90 HP, 3 appearances) - the main new demand: change height on its column
# COMBAT VARIETY 01 — one attack language per family (see docs/INFORME_LOTE_4.md): Wasp short fan of 3, EyeDrone vertical
# laser sweep, Speeder ram, Turret mortar + puddle, Walker low horizontal burst, Probe split orb.
const LEVEL_TUNING = {
	"Wasp": {"arcade_mode": true, "max_passes": 99, "arcade_recovery": 1.1, "restalk_time": 0.85, "drift_amplitude": 0.8},
	"Probe": {"cooldown_time": 1.3, "burst_shots": 1, "split_orb": true, "burst_gap": 0.2, "short_recovery": 0.45, "bursts_per_cycle": 2, "move_speed": 3.0,
			"advance_speed": 0.5, "reposition_speed": 1.2, "maximum_range": 8.5, "stay_on_screen": true},
	"EyeDrone": {"cooldown_time": 1.1, "burst_shots": 3, "burst_gap": 0.2, "fan_every": 0, "laser_every": 1, "fan_count": 5, "fan_min_distance": 3.0, "fan_windup": 0.6,
			"minimum_range": 3.0, "maximum_range": 5.0, "stay_on_screen": true},
	"Turret": {"cooldown_time": 1.3, "fan_count": 3, "fan_step_degrees": 14.0, "mortar_mode": true},
	"OrganicAlien": {"vary_height": true, "recovery_time": 0.6, "ranged_enabled": true},
	"Speeder": {"lane_telegraph": true, "ram_mode": true},
	# LOTE 7: Wasp passes 3 -> 99, Dragonfly passes 3 -> 99, Spider attacks 2 -> 99: they keep working the screen until
	# their CAMERA_TIME instead of leaving after a fixed count (the director retires them).
	"Dragonfly": {"max_passes": 99},
	"Spider": {"attacks": 99},
	# LOTE 12: roster species attack more often (shorter rests; windups and shot speed untouched).
	"FlyCommon": {"idle_time": 0.5, "recovery_time": 0.45},
	"FlyGreen": {"idle_time": 1.3, "recovery_time": 1.0},
	"FlyCloud": {"idle_time": 0.7, "recovery_time": 0.6},
	"WormA": {"idle_time": 0.8, "recovery_time": 0.9},
	"WormB": {"idle_time": 0.6, "recovery_time": 0.6},
	"Walker": {"recovery_time": 0.6, "burst_shots": 3, "burst_gap": 0.35, "walk_speed": 2.4, "reposition_distance": 2.4, "detection_range": 10.0, "stay_on_screen": true, "sweep_every": 2, "low_burst": true},
}
# ARCADE CONTENT & SPECTACLE REBUILD 02 — EVENTS V3 (on top of the Transformation Pass EVENTS V2).
# Playtest verdict: "still empty, not challenging, too static". V3 layers each stretch instead of enemy -> kill -> wait:
# popcorn swarms (rhythm, one-shot kills) between medium threats, Walker x5 (clean presentation, showcase, escort, two
# late gates), OrganicAlien x3 (presentation, crossfire, late gate), cinematic depth entries, two showcase set pieces,
# the frog scale event and a guaranteed pre-boss weapon power moment. The five internal acts are unchanged.
# Optional per-event keys (all plain data):
#   "act"        1..5                      "formation"  readable name of the entry shape (dev/tests)
#   "delays"     seconds per unit (asc.)   "y"          spawn height per unit (formations; ground units ignore it)
#   "x"          extra spawn X per unit    "moment"     id emitted through `director_moment` (visual/interactive set piece)
#   "path"       Swarm path: sine | arc_top | arc_bottom | dive
#   "shooters"   unit indexes (Swarm only) that fire one slow aimed shot
#   "hard"/"human" as before.
const ACT_STARTS := [0.0, 68.0, 140.0, 198.0, 340.0] # ACT 1 AWAKENING, 2 CONTROLLED GARDEN, 3 HUMAN TERRITORY, 4 ALIEN ESCALATION, 5 FIRST CONTACT
## EyeDrone fans are introduced from here on (before: aimed bursts only).
const FAN_FROM_X := 96.0
## LOTE 11 B: +42 popcorn units (149 total, +39 %), same families, no fireflies: V, sine wave, pincer from both sides, entry from
## behind (`sides`, `speed`, `amplitude`) and kamikaze popcorn (0.5 s warning). They fill every stretch that was empty for >5 s.
## LOTE 10 B: 107 units, no new families. Small route patrols at <=8m intervals plus three mixed waves
## in each zone; moments and the gates at X=254/296/340 and checkpoints X=190/281 remain.
## LOTE 12: the pre-roster table (Lote 11 and before) is kept intact; LEVEL01_ROSTER_ONLY selects which one plays.
const EVENTS_LEGACY = [
	# ACT 1 — AWAKENING (intensity 1 -> 2)
	{"at": 1.5, "act": 1, "label": "POPCORN · OLA SENOIDAL", "units": ["Swarm", "Swarm", "Swarm"], "formation": "snake", "path":"sine","amplitude": 1.3, "delays": [0.0, 0.4, 0.8], "y": [4.2, 4.2, 4.2]},
	{"at": 4.0, "act": 1, "label": "DESPERTAR · LATA GIGANTE", "units": [], "moment": "opening_can"},
	{"at": 5.0, "act": 1, "label": "JARDÍN · PRIMERA AVISPA", "units": ["Wasp"]},
	{"at": 8.0, "act": 1, "label": "POPCORN · V", "units": ["Swarm", "Swarm", "Swarm", "Swarm", "Swarm"], "formation": "v", "path": "straight", "delays": [0.0, 0.2, 0.4, 0.6, 0.8], "y": [4.0, 4.8, 3.2, 5.6, 2.4]},
	{"at": 13.0, "act": 1, "label": "PATRULLA · JARDÍN", "units": ["Mosquito", "Probe"], "delays": [0.0, 0.8], "y": [4.2, 2.6]},
	{"at": 14.0, "act": 1, "label": "POPCORN · FILA ONDULANTE", "units": ["Swarm", "Swarm", "Swarm"], "formation": "snake", "path": "sine", "delays": [0.0, 0.4, 0.8], "y": [4.2, 4.2, 4.2]},
	{"at": 22.0, "act": 1, "label": "JARDÍN · PAREJA DESFASADA", "units": ["Wasp", "Wasp"], "formation": "pair", "delays": [0.0, 1.2], "y": [4.8, 2.8]},
	{"at": 30.0, "act": 1, "label": "PATRULLA · JARDÍN", "units": ["Wasp", "Probe"], "delays": [0.0, 0.8], "y": [2.6, 2.6]},
	{"at": 36.0, "act": 1, "label": "FORMACIÓN A · PRIMERA SONDA", "units": ["Probe"], "y": [4.6]},
	{"at": 44.0, "act": 1, "label": "PATRULLA · JARDÍN", "units": ["Probe", "Probe"], "delays": [0.0, 0.8], "y": [5.2, 2.6]},
	{"at": 46.0, "act": 1, "label": "TRONCO · SONDA Y OJO", "units": ["Probe", "EyeDrone"], "formation": "staggered", "delays": [0.0, 1.0], "y": [5.0, 2.2]},
	# LOTE 6 — Codex GLB fauna (see docs/INFORME_LOTE_6.md): one new family per slot, never stacked on the heavy gates.
	{"at": 51.0, "act": 1, "label": "MOSQUITO · PRIMER ERRÁTICO", "units": ["Mosquito"], "y": [4.2]},
	{"at": 56.0, "act": 1, "label": "PROFUNDIDAD · SONDA", "units": ["Probe"], "y": [4.6], "depth": true},
	# ACT 2 — CONTROLLED GARDEN (2 -> 3)
	{"at": 64.0, "act": 1, "label": "PATRULLA · JARDÍN", "units": ["Ladybird", "Probe"], "delays": [0.0, 0.8], "y": [4.2, 2.6]},
	{"at": 68.0, "act": 2, "label": "PROFUNDIDAD · PAREJA DE OJOS", "units": ["EyeDrone", "EyeDrone"], "formation": "v", "delays": [0.0, 0.3], "y": [5.6, 3.0], "x": [0.0, 1.0], "depth": true},
	{"at": 76.0, "act": 2, "label": "CARRIL · SPEEDER", "units": ["Speeder"], "y": [5.2]},
	# NOCHE 01: the one-eyed purple organism left the normal events (it is now a UFO minion in phases 2-3).
	{"at": 80.0, "act": 2, "label": "MARIQUITA · PRESENTACIÓN", "units": ["Ladybird"], "y": [4.0]},
	# GARDEN IDENTITY 04 — the spider is presented alone (clean read of the column, the ring and the lock).
	{"at": 83.0, "act": 2, "label": "POPCORN · PINZA", "units": ["Swarm", "Swarm", "Swarm", "Swarm"], "formation": "pincer", "path": "straight", "sides": ["right", "left", "right", "left"], "delays": [0.0, 0.2, 0.9, 1.1], "y": [5.2, 1.8, 3.8, 2.6]},
	{"at": 88.0, "act": 2, "label": "PATRULLA · JARDÍN", "units": ["Moth", "Probe"], "delays": [0.0, 0.8], "y": [2.6, 2.6]},
	{"at": 91.0, "act": 2, "label": "ARAÑA · PRESENTACIÓN (CARRIL VERTICAL)", "units": ["Spider"], "x": [1.2]},
	{"at": 99.0, "act": 2, "label": "PATRULLA · JARDÍN", "units": ["WaveDragonfly", "Probe"], "delays": [0.0, 0.8], "y": [5.2, 2.6]},
	{"at": 101.0, "act": 2, "label": "HORMIGA · SUELO", "units": ["Ant"]},
	{"at": 105.0, "act": 2, "label": "WALKER · PRESENTACIÓN", "units": ["Walker"], "hold": true},
	# LOTE 7 — COMBAT ZONE 1 (act 2): the host pair opens it, then (LOTE 9) 2 waves of known families.
	{"at": 112.0, "act": 2, "label": "CONTACTO · SONDA Y OJO", "units": ["Probe", "EyeDrone"], "delays": [0.0, 0.8], "y": [5.4, 2.6],
			"arena_label": "ZONA DE COMBATE · CLARO DEL JARDÍN", "arena": [
		{"units": ["Mosquito", "Wasp"], "delays": [0.0, 0.8], "y": [5.2, 3.0]},
		{"units": ["Swarm", "Swarm", "Swarm", "WaveDragonfly"], "path": "arc_top", "shooters": [1], "delays": [0.0, 0.35, 0.7, 1.4], "y": [5.6, 5.6, 5.6, 3.2]},
		{"units": ["Ant", "EyeDrone", "Wasp"], "delays": [0.0, 0.7, 1.4], "y": [3.0, 5.0, 2.4]},
	]},
	{"at": 120.0, "act": 2, "label": "PATRULLA · JARDÍN", "units": ["Mosquito"], "y": [4.2]},
	{"at": 124.0, "act": 2, "label": "FAUNA · PRIMERA LIBÉLULA CONTROLADA", "units": ["Dragonfly"]},
	# LOTE 11 C5: the giant watering can empties over the garden (3 waves of 2 water columns, 1 s warning). Enemy-free moment.
	{"at": 128.0, "act": 2, "label": "REGADERA · COLUMNAS DE AGUA", "units": [], "moment": "watering_can"},
	{"at": 132.0, "act": 2, "label": "PATRULLA · JARDÍN", "units": ["Wasp"], "y": [2.6]},
	{"at": 138.0, "act": 2, "label": "PATRULLA · CRUCE", "units": ["Mosquito"], "y": [4.6]},
	{"at": 140.0, "act": 3, "label": "ALERTA · HUMANO GIGANTE", "units": [], "human": true},
	# ACT 3 — HUMAN TERRITORY (2 -> 4 -> 2)
	{"at": 141.0, "act": 3, "label": "POPCORN · POR ATRÁS", "units": ["Swarm", "Swarm", "Swarm"], "formation": "from_behind", "path": "straight", "speed": 5.0, "sides": ["left", "left", "left"], "delays": [0.0, 0.5, 1.0], "y": [4.6, 3.4, 2.2]},
	{"at": 146.0, "act": 3, "label": "SECUELA · EL MUNDO SIGUE VIVO", "units": ["Wasp"], "moment": "human_aftermath"},
	{"at": 152.0, "act": 3, "label": "CARRILES · DOS SPEEDERS", "units": ["Speeder", "Speeder"], "formation": "pair", "delays": [0.0, 0.9], "y": [5.6, 2.0]},
	{"at": 158.0, "act": 3, "label": "TENAZA · TORRETA Y AVISPA", "units": ["Turret", "Wasp"], "formation": "top_bottom", "delays": [0.0, 1.2], "y": [-0.2, 4.6]},
	# GARDEN IDENTITY 04 — the vertical column of the spider, now alone (LOTE 9).
	{"at": 166.0, "act": 3, "label": "ARAÑA · COLUMNA", "units": ["Spider"], "x": [0.6]},
	# LOTE 7 — COMBAT ZONE 2 (act 3, human territory).
	{"at": 172.0, "act": 3, "label": "FORMACIÓN B · OJO Y SONDA", "units": ["EyeDrone", "Probe"], "formation": "top_bottom", "delays": [0.0, 0.8], "y": [5.8, 2.6],
			"arena_label": "ZONA DE COMBATE · HUELLAS DEL GIGANTE", "arena": [
		{"units": ["StagBeetle", "Mosquito"], "delays": [0.0, 0.8], "y": [0.0, 5.0]},
		{"units": ["Moth", "Swarm", "Swarm", "Swarm"], "path": "dive", "shooters": [0, 2], "delays": [0.0, 0.8, 1.1, 1.4], "y": [4.4, 5.6, 4.4, 5.6]},
		{"units": ["Turret", "Ladybird", "Wasp"], "delays": [0.0, 0.7, 1.4], "y": [3.0, 5.0, 2.4]},
	]},
	{"at": 180.0, "act": 3, "label": "SET PIECE A · WALKER BAJO EL ENJAMBRE", "units": ["Walker", "Swarm", "Swarm", "Swarm"], "formation": "showcase", "path": "dive", "delays": [0.0, 1.2, 1.5, 1.8], "y": [0.0, 5.6, 5.6, 5.6], "shooters": [1, 3], "moment": "walker_showcase", "hold": true},
	{"at": 188.0, "act": 3, "label": "ESCALA · LA RANA", "units": [], "moment": "scale_event"},
	# ACT 4 — ALIEN ESCALATION (3 -> 4 with valleys): 4a tech, 4b invasion, 4c last defence
	{"at": 189.0, "act": 3, "label": "KAMIKAZE · TRES AVISOS", "units": ["Swarm", "Swarm", "Swarm"], "formation": "kamikaze", "path": "kamikaze", "delays": [0.0, 0.9, 1.8], "y": [4.6, 2.6, 4.0]},
	{"at": 194.0, "act": 3, "label": "PATRULLA · JARDÍN", "units": ["Probe"], "y": [5.2]},
	{"at": 202.0, "act": 4, "label": "PATRULLA · JARDÍN", "units": ["Ladybird"], "y": [4.2]},
	{"at": 206.0, "act": 4, "label": "ROCA · TORRETA DETRÁS DE LA PIEDRA", "units": ["Turret"], "formation": "rock_turret", "y": [-0.2]},
	{"at": 214.0, "act": 4, "label": "SET PIECE B · LIBÉLULA EN FUEGO CRUZADO", "units": ["WaveDragonfly", "EyeDrone"], "formation": "crossfire", "delays": [0.0, 0.8], "y": [3.6, 5.8]},
	# LOTE 7 — COMBAT ZONE 3 (act 4, alien escalation).
	{"at": 222.0, "act": 4, "label": "PATRULLA · JARDÍN", "units": ["Moth"], "y": [2.6]},
	{"at": 226.0, "act": 4, "label": "POPCORN · OLA SENOIDAL", "units": ["Swarm", "Swarm", "Swarm"], "formation": "snake", "path": "sine", "amplitude": 1.3, "delays": [0.0, 0.4, 0.8], "y": [4.2, 4.2, 4.2]},
	{"at": 230.0, "act": 4, "label": "PATRULLA · JARDÍN", "units": ["WaveDragonfly"], "y": [5.2]},
	{"at": 233.0, "act": 4, "label": "CARACOL · ESCUPITAJO LENTO", "units": ["Snail"],
			"arena_label": "ZONA DE COMBATE · DEFENSA ALIEN", "arena": [
		{"units": ["Walker", "EyeDrone"], "delays": [0.0, 1.2], "y": [0.0, 5.2]},
		{"units": ["MushroomCannon", "Probe"], "delays": [0.0, 1.0], "y": [0.0, 5.4]},
		{"units": ["Moth", "Mosquito", "EyeDrone"], "delays": [0.0, 0.7, 1.4], "y": [3.0, 5.0, 2.4]},
	]},
	{"at": 241.0, "act": 4, "label": "PATRULLA · JARDÍN", "units": ["Mosquito"], "y": [4.2]},
	{"at": 245.0, "act": 4, "label": "POPCORN · ARCO BAJO", "units": ["Swarm", "Swarm", "Swarm"], "formation": "arc", "path": "arc_bottom", "delays": [0.0, 0.35, 0.7], "y": [1.6, 1.6, 1.6], "shooters": [0, 1, 2]},
	{"at": 249.0, "act": 4, "label": "POPCORN · POR ATRÁS", "units": ["Swarm", "Swarm", "Swarm"], "formation": "from_behind", "path": "straight", "speed": 5.0, "sides": ["left", "left", "left"], "delays": [0.0, 0.5, 1.0], "y": [2.6, 3.6, 4.6]},
	{"at": 253.0, "act": 4, "label": "PATRULLA · JARDÍN", "units": ["Wasp"], "y": [2.6]},
	{"at": 254.0, "act": 4, "label": "MARIQUITA BLINDADA · SONDA", "units": ["Ladybird", "Probe"], "hard": true, "delays": [0.0, 1.0]},
	{"at": 258.0, "act": 4, "label": "POPCORN · V", "units": ["Swarm", "Swarm", "Swarm", "Swarm", "Swarm"], "formation": "v", "path": "straight", "delays": [0.0, 0.2, 0.4, 0.6, 0.8], "y": [3.4, 4.2, 2.6, 5.0, 1.8]},
	{"at": 260.0, "act": 4, "label": "PATRULLA · CONTAMINACIÓN", "units": ["Mosquito"], "y": [3.6]},
	{"at": 262.0, "act": 4, "label": "JARDÍN CONTAMINADO · LIBÉLULA", "units": ["Dragonfly"], "delays": [2.0], "moment": "contaminated_garden"},
	{"at": 270.0, "act": 4, "label": "PATRULLA · JARDÍN", "units": ["Probe"], "y": [5.2]},
	{"at": 278.0, "act": 4, "label": "POPCORN · PICADA", "units": ["Swarm", "Swarm", "Swarm"], "formation": "dive", "path": "dive", "delays": [0.0, 0.3, 0.6], "y": [5.6, 4.4, 5.6], "shooters": [0, 1, 2]},
	{"at": 282.0, "act": 4, "label": "KAMIKAZE · TRES AVISOS", "units": ["Swarm", "Swarm", "Swarm"], "formation": "kamikaze", "path": "kamikaze", "delays": [0.0, 0.9, 1.8], "y": [3.0, 5.0, 4.0]},
	{"at": 286.0, "act": 4, "label": "PATRULLA · JARDÍN", "units": ["Ladybird"], "y": [4.2]},
	{"at": 289.0, "act": 4, "label": "ATARDECER · CAZA ALIEN", "units": ["AlienFighter"], "y": [5.4]},
	{"at": 296.0, "act": 4, "label": "FORMACIÓN C · WALKER Y AVISPA", "units": ["Walker", "Wasp"], "formation": "escort", "hard": true, "delays": [0.0, 1.2]},
	{"at": 299.0, "act": 4, "label": "POPCORN · PINZA", "units": ["Swarm", "Swarm", "Swarm", "Swarm"], "formation": "pincer", "path": "straight", "sides": ["left", "right", "left", "right"], "delays": [0.0, 0.2, 0.9, 1.1], "y": [1.8, 5.2, 2.6, 3.8]},
	{"at": 302.0, "act": 4, "label": "RECOMPENSA · BOMBA", "units": ["Mosquito"], "moment": "bomb_reward"},
	# GARDEN IDENTITY 04 — late, optional pressure: the last web of the spider.
	{"at": 306.0, "act": 4, "label": "POPCORN · OLA SENOIDAL", "units": ["Swarm", "Swarm", "Swarm"], "formation": "snake", "path": "sine", "amplitude": 1.3, "delays": [0.0, 0.4, 0.8], "y": [3.4, 3.4, 3.4]},
	{"at": 310.0, "act": 4, "label": "PATRULLA · JARDÍN", "units": ["Moth"], "y": [2.6]},
	{"at": 315.0, "act": 4, "label": "ARAÑA · ÚLTIMA TELARAÑA", "units": ["Spider"], "x": [1.6]},
	# Optional mini-boss: not a hard gate, it leaves on its own like any soft unit (soft_pressure_seconds).
	{"at": 319.5, "act": 4, "label": "SEMILLERO ALIEN · MINIJEFE OPCIONAL", "units": ["SeedCarrier"], "y": [4.4]},
	{"at": 327.5, "act": 4, "label": "PATRULLA · JARDÍN", "units": ["WaveDragonfly"], "y": [5.2]},
	{"at": 330.0, "act": 4, "label": "POTENCIA · PREPARATE", "units": [], "moment": "preboss_power"},
	{"at": 334.0, "act": 4, "label": "POPCORN · POR ATRÁS", "units": ["Swarm", "Swarm", "Swarm"], "formation": "from_behind", "path": "straight", "speed": 5.0, "sides": ["left", "left", "left"], "delays": [0.0, 0.5, 1.0], "y": [4.6, 3.4, 2.2]},
	{"at": 338.0, "act": 4, "label": "PATRULLA · JARDÍN", "units": ["Mosquito"], "y": [4.2]},
	{"at": 340.0, "act": 4, "label": "ÚLTIMA DEFENSA · WALKER, SONDA Y AVISPA", "units": ["Walker", "Probe", "Wasp"], "hard": true, "delays": [0.0, 0.8, 2.2]},
]

## LOTE 12 · ETAPA 2 — LEVEL 1 ROSTER ONLY (docs/art/LEVEL_01_ROSTER.md). Garden animals and insects and a single technology enemy (the
## walking robot). LOTE 13: DENSE and action-packed - no breathing valley (the checkpoint-1 stretch is the WORM ENTRANCE), no turtle (parked
## until Rubén delivers a new model). Arc: lawn -> flower bed (zone 1) -> worm entrance at checkpoint 1 -> vegetable patch (zone 2) -> shade
## under the leaves (zone 3) -> checkpoint 2 -> the walking robot mini-boss with insect escorts -> the tarantula. Garden mushrooms and flowers:
## BeeLevel01GardenMushrooms. Species roles (patterns and shots: BeeShotStyles): common fly = ram + pellet spit; green fly = zigzag + acid burst;
## fly cloud = chases Bee as a block (the bomb clears it); wasp = needle fan + dive; ladybird = shell-open sweep + seed fan; ant = lunge + pebble
## lob (comes out of an anthill); snail = slime bubble lob; worm A = erupts from a marked spot; worm B = low crawling lunge; stag beetle =
## charge + stone lob; hanging spider = vertical thread lane + web fan; cannon mushroom = spore fan.
const EVENTS_ROSTER = [
	# LOTE 14 · ETAPA 2 — GRADUAL table (generated by dev/lote14/_gen_events.gd, seed 1414): flies only at first, then one new species at a time, each
	# debuting alone ("debut" key); <= 2 species mixed until minute 2, <= 3 until minute 4, <= 4 afterwards.
	{"at": 1.5, "act": 1, "label": "CÉSPED · MOSCA", "units": ["FlyCommon"], "y": [3.0]},
	{"at": 4.0, "act": 1, "label": "DESPERTAR · LATA GIGANTE", "units": [], "moment": "opening_can"},
	{"at": 6.5, "act": 1, "label": "CÉSPED · MOSCA", "units": ["FlyCommon"], "y": [4.6]},
	{"at": 11.5, "act": 1, "label": "CÉSPED · MOSCA", "units": ["FlyCommon", "FlyCommon"], "delays": [0.0, 0.9], "y": [5.0, 4.4]},
	{"at": 16.5, "act": 1, "label": "CÉSPED · MOSCA", "units": ["FlyCommon", "FlyCommon"], "delays": [0.0, 0.6], "y": [4.4, 4.6]},
	{"at": 22.0, "act": 1, "label": "CÉSPED · MOSCA", "units": ["FlyCommon"], "y": [5.2]},
	{"at": 26.0, "act": 1, "label": "CÉSPED · HORMIGA", "units": ["Ant"], "anthill": true, "debut": "Ant"},
	{"at": 29.3, "act": 1, "label": "CÉSPED · HORMIGA", "units": ["Ant"], "anthill": true},
	{"at": 32.7, "act": 1, "label": "CÉSPED · HORMIGA", "units": ["Ant", "Ant"], "delays": [0.0, 0.8], "y": [0.0, 0.0], "anthill": true},
	{"at": 41.0, "act": 1, "label": "CÉSPED · MOSCA Y HORMIGA", "units": ["FlyCommon", "Ant"], "delays": [0.0, 0.9], "y": [3.0, 0.0], "anthill": true},
	{"at": 44.6, "act": 1, "label": "CÉSPED · MOSCA Y HORMIGA", "units": ["FlyCommon", "Ant", "FlyCommon"], "delays": [0.0, 0.9, 1.4], "y": [5.2, 0.0, 5.2], "anthill": true},
	{"at": 48.2, "act": 1, "label": "CÉSPED · MOSCA Y HORMIGA", "units": ["FlyCommon", "Ant"], "delays": [0.0, 0.9], "y": [5.0, 0.0], "anthill": true},
	{"at": 52.0, "act": 1, "label": "CÉSPED · MARIQUITA", "units": ["Ladybird"], "y": [3.4], "debut": "Ladybird"},
	{"at": 55.3, "act": 1, "label": "CÉSPED · MARIQUITA", "units": ["Ladybird"], "y": [5.0]},
	{"at": 58.7, "act": 1, "label": "CÉSPED · MARIQUITA", "units": ["Ladybird"], "y": [2.8]},
	{"at": 65.0, "act": 2, "label": "MACIZO · HORMIGA Y MARIQUITA", "units": ["Ant", "Ladybird", "Ladybird"], "delays": [0.0, 0.8, 1.4], "y": [0.0, 3.0, 4.6], "anthill": true},
	{"at": 68.6, "act": 2, "label": "MACIZO · HORMIGA", "units": ["Ant"], "anthill": true},
	{"at": 72.2, "act": 2, "label": "MACIZO · HORMIGA Y MARIQUITA", "units": ["Ant", "Ladybird", "Ladybird"], "delays": [0.0, 0.7, 1.4], "y": [0.0, 4.6, 5.2], "anthill": true},
	{"at": 76.0, "act": 2, "label": "MACIZO · AVISPA", "units": ["Wasp"], "y": [3.4], "debut": "Wasp"},
	{"at": 79.3, "act": 2, "label": "MACIZO · AVISPA", "units": ["Wasp"], "y": [5.2]},
	{"at": 82.7, "act": 2, "label": "MACIZO · AVISPA", "units": ["Wasp", "Wasp"], "delays": [0.0, 0.7], "y": [4.6, 5.0]},
	{"at": 89.0, "act": 2, "label": "MACIZO · AVISPA Y HORMIGA", "units": ["Wasp", "Ant"], "delays": [0.0, 0.7], "y": [3.0, 0.0], "anthill": true},
	{"at": 92.6, "act": 2, "label": "MACIZO · HORMIGA Y AVISPA", "units": ["Ant", "Wasp", "Ant"], "delays": [0.0, 0.8, 1.4], "y": [0.0, 5.0, 0.0], "anthill": true},
	{"at": 96.2, "act": 2, "label": "MACIZO · AVISPA Y HORMIGA", "units": ["Wasp", "Ant"], "delays": [0.0, 0.6], "y": [3.0, 0.0], "anthill": true},
	{"at": 100.0, "act": 2, "label": "MACIZO · MOSCA VERDE", "units": ["FlyGreen"], "y": [4.6], "debut": "FlyGreen"},
	{"at": 103.3, "act": 2, "label": "MACIZO · MOSCA VERDE", "units": ["FlyGreen"], "y": [2.8]},
	{"at": 106.7, "act": 2, "label": "MACIZO · MOSCA VERDE", "units": ["FlyGreen", "FlyGreen"], "delays": [0.0, 0.8], "y": [5.2, 4.0]},
	{"at": 113.0, "act": 2, "label": "MACIZO · HORMIGA Y MOSCA VERDE", "units": ["Ant", "FlyGreen"], "delays": [0.0, 0.7], "y": [0.0, 3.0], "anthill": true},
	{"at": 115.8, "act": 2, "label": "MACIZO · MOSCA VERDE Y HORMIGA", "units": ["FlyGreen", "Ant", "FlyGreen"], "delays": [0.0, 0.7, 1.5], "y": [2.8, 0.0, 5.0], "anthill": true},
	{"at": 118.6, "act": 2, "label": "MACIZO · MOSCA VERDE Y HORMIGA", "units": ["FlyGreen", "Ant"], "delays": [0.0, 0.7], "y": [5.2, 0.0], "anthill": true},
	{"at": 121.4, "act": 2, "label": "MACIZO · MOSCA VERDE Y HORMIGA", "units": ["FlyGreen", "Ant"], "delays": [0.0, 0.8], "y": [2.8, 0.0], "anthill": true},
	{"at": 124.2, "act": 3, "label": "MACIZO · HORMIGA Y MOSCA VERDE", "units": ["Ant", "FlyGreen", "FlyGreen"], "delays": [0.0, 0.7, 1.5], "y": [0.0, 4.4, 2.8], "anthill": true},
	{"at": 128.0, "act": 2, "label": "REGADERA · COLUMNAS DE AGUA", "units": [], "moment": "watering_can"},
	{"at": 138.0, "act": 3, "label": "ZONA · INICIO · NUBE", "units": ["FlyCloud", "FlyCloud", "FlyCloud"], "delays": [0.0, 0.8, 1.5], "y": [3.0, 4.6, 2.8],
			"debut": "FlyCloud", "arena_label": "ZONA DE COMBATE · MACIZO DE FLORES", "arena": [
			{"units": ["FlyCloud", "FlyCloud", "FlyCloud"], "delays": [0.0, 0.7, 1.4], "y": [5.2, 4.6, 5.0]},
			{"units": ["FlyCloud", "FlyCloud", "FlyCloud"], "delays": [0.0, 0.7, 1.4], "y": [4.4, 3.0, 5.0]},
			{"units": ["Ant", "FlyCloud", "Ant"], "delays": [0.0, 0.7, 1.4], "y": [0.0, 3.4, 0.0], "anthill": true},
			{"units": ["Ant", "Ant", "FlyCloud"], "delays": [0.0, 0.7, 1.4], "y": [0.0, 0.0, 4.4], "anthill": true},
			{"units": ["FlyCloud", "Ant", "FlyCloud"], "delays": [0.0, 0.7, 1.4], "y": [5.0, 0.0, 3.4], "anthill": true},
			{"units": ["FlyCloud", "Ant", "FlyCloud"], "delays": [0.0, 0.7, 1.4], "y": [4.6, 0.0, 5.0], "anthill": true},
			{"units": ["FlyCloud", "Ant", "Ant"], "delays": [0.0, 0.7, 1.4], "y": [2.8, 0.0, 0.0], "anthill": true},
		]},
	{"at": 149.0, "act": 3, "label": "MACIZO · AVISPA", "units": ["Wasp"], "y": [5.2]},
	{"at": 151.2, "act": 3, "label": "MACIZO · HORMIGA Y AVISPA Y NUBE", "units": ["Ant", "Wasp", "FlyCloud"], "delays": [0.0, 0.7, 1.4], "y": [0.0, 3.4, 4.0], "anthill": true},
	{"at": 153.4, "act": 3, "label": "MACIZO · NUBE Y HORMIGA", "units": ["FlyCloud", "Ant"], "delays": [0.0, 0.9], "y": [3.4, 0.0], "anthill": true},
	{"at": 156.0, "act": 3, "label": "MACIZO · GUSANO ROSA", "units": ["WormA", "WormA", "WormA", "WormA"], "delays": [0.0, 0.7, 1.5, 2.1], "y": [0.0, 0.0, 0.0, 0.0], "debut": "WormA"},
	{"at": 159.3, "act": 3, "label": "MACIZO · GUSANO ROSA", "units": ["WormA", "WormA", "WormA"], "delays": [0.0, 0.9, 1.5], "y": [0.0, 0.0, 0.0]},
	{"at": 162.7, "act": 3, "label": "MACIZO · GUSANO ROSA", "units": ["WormA", "WormA", "WormA"], "delays": [0.0, 0.7, 1.4], "y": [0.0, 0.0, 0.0]},
	{"at": 169.0, "act": 3, "label": "MACIZO · GUSANO ROSA Y MOSCA", "units": ["WormA", "FlyCommon"], "delays": [0.0, 0.7], "y": [0.0, 4.6]},
	{"at": 171.2, "act": 3, "label": "MACIZO · MARIQUITA Y GUSANO ROSA", "units": ["Ladybird", "WormA"], "delays": [0.0, 0.7], "y": [5.2, 0.0]},
	{"at": 173.4, "act": 3, "label": "MACIZO · MOSCA Y GUSANO ROSA Y MARIQUITA", "units": ["FlyCommon", "WormA", "Ladybird"], "delays": [0.0, 0.6, 1.4], "y": [4.0, 0.0, 3.4]},
	{"at": 175.6, "act": 3, "label": "MACIZO · MOSCA Y GUSANO ROSA", "units": ["FlyCommon", "WormA", "FlyCommon"], "delays": [0.0, 0.8, 1.6], "y": [4.0, 0.0, 3.0]},
	{"at": 177.8, "act": 3, "label": "MACIZO · GUSANO ROSA", "units": ["WormA"]},
	{"at": 180.0, "act": 3, "label": "MACIZO · MARIQUITA Y GUSANO ROSA", "units": ["Ladybird", "WormA", "WormA"], "delays": [0.0, 0.6, 1.3], "y": [5.2, 0.0, 0.0]},
	{"at": 182.2, "act": 4, "label": "MACIZO · GUSANO ROSA Y MARIQUITA", "units": ["WormA", "Ladybird"], "delays": [0.0, 0.8], "y": [0.0, 5.2]},
	{"at": 185.0, "act": 4, "label": "ENTRADA DE GUSANOS · CARACOL", "units": ["Snail", "Snail", "Snail"], "delays": [0.0, 0.6, 1.4], "y": [0.0, 0.0, 0.0], "debut": "Snail"},
	{"at": 188.3, "act": 4, "label": "ENTRADA DE GUSANOS · CARACOL", "units": ["Snail", "Snail"], "delays": [0.0, 0.9], "y": [0.0, 0.0]},
	{"at": 191.7, "act": 4, "label": "ENTRADA DE GUSANOS · CARACOL", "units": ["Snail", "Snail"], "delays": [0.0, 0.9], "y": [0.0, 0.0]},
	{"at": 198.0, "act": 4, "label": "HUERTA · MOSCA VERDE Y CARACOL", "units": ["FlyGreen", "Snail", "FlyGreen"], "delays": [0.0, 0.7, 1.4], "y": [5.2, 0.0, 4.0]},
	{"at": 200.2, "act": 4, "label": "HUERTA · MOSCA VERDE", "units": ["FlyGreen"], "y": [5.2]},
	{"at": 202.4, "act": 4, "label": "HUERTA · MOSCA VERDE Y GUSANO ROSA", "units": ["FlyGreen", "WormA", "FlyGreen"], "delays": [0.0, 0.7, 1.3], "y": [5.0, 0.0, 5.0]},
	{"at": 204.6, "act": 4, "label": "HUERTA · MOSCA VERDE Y CARACOL", "units": ["FlyGreen", "FlyGreen", "Snail"], "delays": [0.0, 0.9, 1.4], "y": [4.6, 4.0, 0.0]},
	{"at": 206.8, "act": 4, "label": "HUERTA · MOSCA VERDE", "units": ["FlyGreen"], "y": [4.4]},
	{"at": 209.0, "act": 4, "label": "HUERTA · MOSCA VERDE Y CARACOL", "units": ["FlyGreen", "FlyGreen", "Snail"], "delays": [0.0, 0.7, 1.4], "y": [3.0, 5.0, 0.0]},
	{"at": 214.0, "act": 4, "label": "ZONA · INICIO · ESCARABAJO", "units": ["StagBeetle", "StagBeetle"], "delays": [0.0, 0.7], "y": [0.0, 0.0],
			"debut": "StagBeetle", "arena_label": "ZONA DE COMBATE · HUERTA", "arena": [
			{"units": ["StagBeetle", "StagBeetle", "StagBeetle"], "delays": [0.0, 0.7, 1.4], "y": [0.0, 0.0, 0.0]},
			{"units": ["StagBeetle", "StagBeetle"], "delays": [0.0, 0.7], "y": [0.0, 0.0]},
			{"units": ["Wasp", "WormA", "Wasp"], "delays": [0.0, 0.7, 1.4], "y": [4.4, 0.0, 3.4]},
			{"units": ["Wasp", "WormA", "Wasp"], "delays": [0.0, 0.7, 1.4], "y": [2.8, 0.0, 4.6]},
			{"units": ["WormA", "Wasp", "Wasp"], "delays": [0.0, 0.7, 1.4], "y": [0.0, 5.2, 5.2]},
			{"units": ["Wasp", "WormA", "StagBeetle"], "delays": [0.0, 0.7, 1.4], "y": [5.0, 0.0, 0.0]},
			{"units": ["WormA", "WormA", "Wasp"], "delays": [0.0, 0.7, 1.4], "y": [0.0, 0.0, 4.6]},
		]},
	{"at": 227.0, "act": 4, "label": "HUERTA · GUSANO ROSA Y AVISPA", "units": ["WormA", "Wasp"], "delays": [0.0, 0.9], "y": [0.0, 4.0]},
	{"at": 229.2, "act": 4, "label": "HUERTA · AVISPA Y GUSANO ROSA", "units": ["Wasp", "Wasp", "WormA"], "delays": [0.0, 0.7, 1.3], "y": [5.2, 4.0, 0.0]},
	{"at": 231.4, "act": 4, "label": "HUERTA · AVISPA Y GUSANO ROSA", "units": ["Wasp", "WormA"], "delays": [0.0, 0.7], "y": [4.6, 0.0]},
	{"at": 235.0, "act": 4, "label": "HUERTA · GUSANO DE COMPOST", "units": ["WormB", "WormB", "WormB"], "delays": [0.0, 0.6, 1.5], "y": [0.0, 0.0, 0.0], "debut": "WormB"},
	{"at": 238.3, "act": 4, "label": "HUERTA · GUSANO DE COMPOST", "units": ["WormB", "WormB"], "delays": [0.0, 0.7], "y": [0.0, 0.0]},
	{"at": 241.7, "act": 4, "label": "HUERTA · GUSANO DE COMPOST", "units": ["WormB", "WormB"], "delays": [0.0, 0.9], "y": [0.0, 0.0]},
	{"at": 248.0, "act": 4, "label": "HUERTA · MOSCA Y GUSANO DE COMPOST Y MOSCA VERDE", "units": ["FlyCommon", "WormB", "FlyGreen"], "delays": [0.0, 0.7, 1.4], "y": [5.0, 0.0, 4.0]},
	{"at": 250.2, "act": 4, "label": "HUERTA · MOSCA", "units": ["FlyCommon"], "y": [5.0]},
	{"at": 252.4, "act": 4, "label": "HUERTA · MOSCA VERDE Y GUSANO DE COMPOST", "units": ["FlyGreen", "WormB"], "delays": [0.0, 0.8], "y": [5.0, 0.0]},
	{"at": 254.6, "act": 4, "label": "HUERTA · MOSCA Y GUSANO DE COMPOST", "units": ["FlyCommon", "WormB", "FlyCommon"], "delays": [0.0, 0.8, 1.5], "y": [4.0, 0.0, 4.4]},
	{"at": 256.8, "act": 4, "label": "HUERTA · MOSCA Y GUSANO DE COMPOST", "units": ["FlyCommon", "WormB", "WormB"], "delays": [0.0, 0.9, 1.6], "y": [4.4, 0.0, 0.0]},
	{"at": 259.0, "act": 4, "label": "HUERTA · MOSCA VERDE Y GUSANO DE COMPOST", "units": ["FlyGreen", "WormB"], "delays": [0.0, 0.7], "y": [3.0, 0.0]},
	{"at": 262.0, "act": 4, "label": "ZONA · INICIO · ARAÑA", "units": ["Spider"], "y": [5.2], "x": [1.2],
			"debut": "Spider", "arena_label": "ZONA DE COMBATE · SOMBRA BAJO LAS HOJAS", "arena": [
			{"units": ["Spider"], "delays": [0.0], "y": [4.0], "x": [0.6]},
			{"units": ["Spider"], "delays": [0.0], "y": [3.4], "x": [0.6]},
			{"units": ["Wasp", "Ant", "Ant"], "delays": [0.0, 0.7, 1.4], "y": [3.4, 0.0, 0.0], "anthill": true},
			{"units": ["Wasp", "Ant", "Ant"], "delays": [0.0, 0.7, 1.4], "y": [4.0, 0.0, 0.0], "anthill": true},
			{"units": ["Ant", "Wasp", "StagBeetle"], "delays": [0.0, 0.7, 1.4], "y": [0.0, 4.4, 0.0], "anthill": true},
			{"units": ["Wasp", "Ant", "Wasp"], "delays": [0.0, 0.7, 1.4], "y": [2.8, 0.0, 3.0], "anthill": true},
			{"units": ["Ant", "Wasp", "StagBeetle"], "delays": [0.0, 0.7, 1.4], "y": [0.0, 3.4, 0.0], "anthill": true},
		]},
	{"at": 276.0, "act": 4, "label": "SOMBRA · AVISPA", "units": ["Wasp"], "y": [3.4]},
	{"at": 278.2, "act": 4, "label": "SOMBRA · AVISPA Y HORMIGA", "units": ["Wasp", "Ant"], "delays": [0.0, 0.9], "y": [3.4, 0.0], "anthill": true},
	{"at": 280.4, "act": 4, "label": "SOMBRA · ESCARABAJO Y AVISPA", "units": ["StagBeetle", "StagBeetle", "Wasp"], "delays": [0.0, 0.7, 1.4], "y": [0.0, 0.0, 5.2]},
	{"at": 283.0, "act": 4, "label": "POTENCIA · PREPARATE", "units": [], "moment": "preboss_power"},
	{"at": 284.5, "act": 4, "label": "SOMBRA · AVISPA Y HORMIGA", "units": ["Wasp", "Wasp", "Ant"], "delays": [0.0, 0.8, 1.3], "y": [3.4, 5.0, 0.0], "anthill": true},
	{"at": 286.7, "act": 4, "label": "SOMBRA · AVISPA", "units": ["Wasp"], "y": [4.4]},
	{"at": 288.9, "act": 4, "label": "SOMBRA · AVISPA Y HORMIGA", "units": ["Wasp", "Ant"], "delays": [0.0, 0.8], "y": [3.0, 0.0], "anthill": true},
	{"at": 291.1, "act": 4, "label": "SOMBRA · AVISPA Y HORMIGA", "units": ["Wasp", "Wasp", "Ant"], "delays": [0.0, 0.8, 1.6], "y": [2.8, 4.0, 0.0], "anthill": true},
	{"at": 294.0, "act": 4, "label": "ROBOT CAMINANTE · MINIJEFE CON ESCOLTA", "units": ["Walker", "Wasp", "FlyCommon", "FlyCommon"], "hard": true, "miniboss": true,
			"delays": [0.0, 1.2, 2.4, 3.4], "y": [0.0, 4.6, 5.4, 3.0],
			"escort_wave": {"units": ["Wasp", "FlyGreen", "FlyCommon"], "delays": [0.0, 0.9, 1.8], "y": [5.0, 3.4, 4.4]}},
]

## LOTE 12 · ETAPA 2: Level 1 plays only its roster (docs/art/LEVEL_01_ROSTER.md). false restores the old table, with the alien enemies,
## the frog scale event, the fireflies and the UFO (all their code is intact; the UFO belongs to Level 7, the frog to Level 2).
const LEVEL01_ROSTER_ONLY := true
const EVENTS = EVENTS_ROSTER if LEVEL01_ROSTER_ONLY else EVENTS_LEGACY
## Runtime switch (tests of the legacy flow set it to false before loading the level, like `giant_human_enabled`).
static var roster_only := LEVEL01_ROSTER_ONLY

## The table that plays now (EVENTS is the default one, for static references).
static func events_table() -> Array:
	return EVENTS_ROSTER if roster_only else EVENTS_LEGACY


@export var show_debug_labels := false # Internal event names ("JARDÍN · AVISPA"...) only for development.
@export var group_delay := 0.8
@export var soft_pressure_seconds := 14.0
@export var retreat_speed := 10.0
@onready var stage: BeeShmupStage = get_parent() as BeeShmupStage
@onready var bee: BeePlayer = stage.get_node("BeePlayer")
@onready var human: GiantHumanCrossingHazard = stage.get_node("GiantHuman")
@onready var warning: Label = stage.get_node("CanvasLayer/HumanWarning")

var event_index := 0 # Next threshold, not the number of killed encounters.
var max_active_seen := 0
var max_alive_route := 0 # LOTE 9: most enemies alive at once (popcorn included) outside / inside the combat zones.
var max_alive_arena := 0
var spawned_by_family: Dictionary = {}
var active_units: Array[Node3D] = []
var encounter_label := "JARDÍN · APRENDÉ A VOLAR"
var player_label := "" # What the HUD shows: only important messages unless show_debug_labels.
var escaped_count := 0
var spawn_history: Array[Dictionary] = []
var _pending: Array[Dictionary] = []
var swarm_units: Array[Node3D] = [] # Popcorn alive (outside the threat cap).
var _swarm_pending: Array[Dictionary] = []
var _clock := 0.0
var _hard_gate := false
var _waiting_for_human := false
var _complete := false
var _frozen := false
var boss: UfoBoss01
var boss_defeated := false
var minion_gate_index := 0 # COMBAT VARIETY 01: next minion entry point (top, left, right).
var minion_gates_used: Array[int] = []
var _boss_breather_left := -1.0
var current_act := 1 # Internal act (1-5) of the last launched event; 5 = FIRST CONTACT.
var depth_entries := 0 # Cinematic depth entries started (dev/tests).
var _holding := false
var fauna_hint_shown := false
var _arena: Dictionary = {} # LOTE 7: the combat zone in progress (empty = none).
var _breather_until := 0.0
var arenas_completed := 0
var arena_log: Array[Dictionary] = [] # {event, seconds, waves} per finished zone (tests / report).
var _label_token := 0
var debut_log: Array[Dictionary] = [] ## LOTE 14: {family, time, distance, forced} per species debut (tests / report).
var species_seen: Dictionary = {} ## family -> game time of its first spawn.
var species_label: Label
var _solo_family := ""
var _solo_until := -1.0
var _debut_wait := 0.0
var _species_token := 0
var animals_total := 0 # NOCHE 01: controlled animals that appeared (incl. the turtle, see register_extra_animal).
var liberated_count := 0
## LOTE 12 · ETAPA 3
var miniboss: WalkerMiniboss
var miniboss_seconds := -1.0 # Fight length of the robot (activation to fall); -1 = not finished.
var escort_waves := 0
var tarantula: TarantulaBoss01
var tarantula_freed := false
var _tarantula_breather_left := -1.0

func _ready() -> void:
	human.crossing_exited.connect(_on_human_exited)
	if not giant_human_enabled:
		call_deferred("_switch_off_human") # The human node is ready after this one.
	stage.scroll_speed = LEVEL_SCROLL # LOTE 7: the scene keeps 2.0 for the POCs that share it.
	BeeShmupFairness.live_shot_ceiling = LIVE_SHOT_CEILING
	BeeShmupFairness.screen_bound_combat = true
	BeeAttackTokens.enabled = true # REBUILD 03: one heavy pattern at a time.
	BeeAttackTokens.reset()

func _exit_tree() -> void:
	BeeShmupFairness.live_shot_ceiling = 0 # Static: never leak the Level 01 rules into POCs or other scenes.
	BeeShmupFairness.screen_bound_combat = false
	BeeAttackTokens.enabled = false

func _physics_process(delta: float) -> void:
	if _frozen or _complete:
		return
	_clock += delta
	_retire_soft_units(delta)
	_update_hold()
	if _waiting_for_human:
		return
	if _hard_gate:
		if active_units.is_empty() and _pending.is_empty():
			_hard_gate = false
			stage.scroll_speed = LEVEL_SCROLL
		else:
			_spawn_pending()
			return
	_spawn_pending()
	if boss != null and is_instance_valid(boss):
		boss.minions_alive = boss_minions().size() # BOSS V2: the saucer only summons when the field allows it.
	if tarantula != null and is_instance_valid(tarantula):
		tarantula.minions_alive = boss_minions().size()
	if not _arena.is_empty():
		_update_arena(delta)
		return
	if _clock < _breather_until:
		return # LOTE 7: breather after a combat zone - landscape, no new encounter.
	if event_index >= events_table().size():
		if active_units.is_empty() and _pending.is_empty() and swarm_units.is_empty() and _swarm_pending.is_empty():
			_advance_boss(delta) # Level complete only after the UFO is destroyed.
		return
	var event: Dictionary = events_table()[event_index]
	if stage.distance < float(event["at"]) or not _pending.is_empty():
		return
	if _event_blocked_by_solo(event["units"]):
		return # LOTE 14: a new species is debuting alone.
	if (event.has("debut") or bool(event.get("clear", false))) and not _debut_ready(delta):
		return # LOTE 14: a debut (or a pool change, key "clear") waits for a clear field.
	if bool(event.get("human", false)) and not giant_human_enabled:
		# NOCHE 01 · ETAPA 2: the Giant Human is switched off (GIANT_HUMAN_ENABLED); its event is skipped, nothing waits.
		event_index += 1
		current_act = int(event.get("act", current_act))
		return
	# Hard gates/human never overlap surviving soft actors.
	if (bool(event.get("hard", false)) or bool(event.get("human", false))) and not active_units.is_empty():
		stage.scroll_speed = 0.0
		return
	encounter_label = str(event["label"])
	player_label = encounter_label if show_debug_labels or bool(event.get("human", false)) else ""
	var launched_index := event_index
	event_index += 1
	if event.has("debut"):
		_begin_debut(str(event["debut"]))
	else:
		_debut_wait = 0.0
	current_act = int(event.get("act", current_act))
	if event.has("moment"):
		director_moment.emit(StringName(event["moment"]))
	if bool(event.get("human", false)):
		stage.scroll_speed = 0.0
		_waiting_for_human = true
		warning.show()
		if not human.begin_crossing(stage.camera):
			push_error("Level 01 giant human could not start")
		return
	_hard_gate = bool(event.get("hard", false))
	if _hard_gate:
		stage.scroll_speed = 0.0
	_queue_units(event, launched_index, 0)
	if event.has("arena"):
		_begin_arena(event, launched_index)

## Queues the units of an event (or of an arena wave). `slot_base` > 0 for arena waves: their slots never collide with
## the host event's formation slots (tests read the planned height of slot N from the event).
func _queue_units(event: Dictionary, launched_index: int, slot_base: int) -> void:
	var units: Array = event["units"]
	var depth := bool(event.get("depth", false))
	var hold := bool(event.get("hold", false))
	var anchor := _depth_anchor(event) if depth else Vector2.ZERO
	for i in units.size():
		var delays: Array = event.get("delays", [])
		var due: float = float(delays[i]) if i < delays.size() else float(i) * group_delay
		var request := {"family": str(units[i]), "slot": slot_base + i, "event": launched_index, "due": _clock + due, "hard": _hard_gate}
		for key in ["y", "x"]: # Formation data, optional per unit.
			var values: Array = event.get(key, [])
			if i < values.size():
				request[key] = float(values[i])
		if depth:
			request["depth"] = true # Cinematic 2.5D entry from the background (formations open up on arrival).
			request["anchor"] = anchor
		if hold:
			request["hold"] = true
		if bool(event.get("anthill", false)) and str(units[i]) == "Ant":
			request["anthill"] = true # LOTE 13: the ant comes out of an anthill on screen (BeeLevel01Anthills).
		if bool(event.get("miniboss", false)) and str(units[i]) == "Walker":
			request["miniboss"] = true
			request["escort_wave"] = event.get("escort_wave", {})
		if str(units[i]) == "Swarm":
			request["path"] = str(event.get("path", "sine"))
			request["shooter"] = i in event.get("shooters", [])
			# LOTE 11: popcorn formations - `sides` (right | left = enters from behind), `speed`, `amplitude` and `phases` per event.
			var sides: Array = event.get("sides", [])
			request["side"] = str(sides[i]) if i < sides.size() else "right"
			for key in ["speed", "amplitude"]:
				if event.has(key):
					request[key] = float(event[key])
			var phases: Array = event.get("phases", [])
			if i < phases.size():
				request["phase"] = float(phases[i])
			_swarm_pending.append(request) # Popcorn has its own queue: never waits behind (or blocks) threats.
		else:
			_pending.append(request)
	_spawn_pending()

# --- LOTE 7: combat zones ------------------------------------------------------------------------------------------

func _begin_arena(event: Dictionary, launched_index: int) -> void:
	_arena = {"waves": event["arena"], "next": 0, "event": launched_index, "wave_clock": maxf(arena_cadence() - ROSTER_FIRST_WAVE_DELAY, 0.0) if roster_only else 0.0, "clear_for": 0.0, "started": _clock,
			"label": str(event.get("arena_label", "ZONA DE COMBATE"))}
	stage.scroll_speed = ARENA_SCROLL
	_show_label(str(_arena["label"]), 2.2)

func in_arena() -> bool:
	return not _arena.is_empty()

func _update_arena(delta: float) -> void:
	var waves: Array = _arena["waves"]
	var field_clear := _pending.is_empty() and active_units.is_empty() and _swarm_pending.is_empty()
	_arena["wave_clock"] = float(_arena["wave_clock"]) + delta
	_arena["clear_for"] = float(_arena["clear_for"]) + delta if field_clear else 0.0
	var next := int(_arena["next"])
	var timed_out := _clock - float(_arena["started"]) >= arena_max_seconds()
	if next < waves.size() and not timed_out:
		# LOTE 14: the roster zones launch a wave every arena_cadence() seconds even if the previous one is still alive (it keeps 3+ enemies on screen).
		var wave_due := float(_arena["wave_clock"]) >= arena_cadence() if roster_only else (float(_arena["clear_for"]) >= ARENA_WAVE_GAP and float(_arena["wave_clock"]) >= arena_cadence()) or float(_arena["wave_clock"]) >= arena_wave_max()
		if wave_due:
			if _event_blocked_by_solo(waves[next]["units"]):
				return # LOTE 14: the species debuting in this zone is still alone.
			_queue_units(waves[next], int(_arena["event"]), 100 + next * 10)
			_arena["next"] = next + 1
			_arena["wave_clock"] = 0.0
			_arena["clear_for"] = 0.0
			if next > 0:
				_show_label("%s · %d/%d" % [_arena["label"], next + 1, waves.size()], 1.4)
		return
	# Never carry an arena-sized pack into the smaller route budget on a timeout.
	if timed_out and alive_count() > MAX_ON_SCREEN:
		return
	if (field_clear and _clock - float(_arena["started"]) >= arena_min_seconds()) or timed_out:
		arena_log.append({"event": _arena["event"], "seconds": _clock - float(_arena["started"]), "waves": waves.size()})
		_arena = {}
		arenas_completed += 1
		stage.scroll_speed = LEVEL_SCROLL
		_breather_until = _clock + BREATHER_SECONDS
		_show_label("ZONA DESPEJADA", 1.6)

## LOTE 14: true while a species debuts alone and `units` holds another family.
func _event_blocked_by_solo(units: Array) -> bool:
	if _clock >= _solo_until:
		return false
	for family in units:
		if str(family) != _solo_family:
			return true
	return false

## LOTE 14: a debut needs a clear field; after DEBUT_CLEAR_MAX s the leftovers are sent away (they leave at once).
func _debut_ready(delta: float) -> bool:
	if active_units.is_empty():
		return true
	_debut_wait += delta
	if _debut_wait < DEBUT_CLEAR_MAX:
		return false
	for unit in active_units:
		if not bool(unit.get_meta("level_hard", false)):
			unit.set_meta("level_born", -1000.0) # Past its camera time: `_retire_soft_units` sends it away.
	return active_units.all(func(u): return bool(u.get_meta("level_retreat", false)) or bool(u.get_meta("level_hard", false)))

func _begin_debut(family: String) -> void:
	debut_log.append({"family": family, "time": _clock, "distance": stage.distance, "forced": _debut_wait >= DEBUT_CLEAR_MAX})
	_solo_family = family
	_solo_until = _clock + DEBUT_SOLO_SECONDS
	_debut_wait = 0.0

## Small name of a species the first time it appears (SPECIES_NAME_SECONDS).
func _announce_species(family: String) -> void:
	if not roster_only or species_seen.has(family):
		return
	species_seen[family] = _clock
	if not SPECIES_NAMES.has(family) or stage == null:
		return
	if species_label == null:
		species_label = Label.new()
		species_label.name = "SpeciesName"
		species_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
		species_label.offset_left = -200.0
		species_label.offset_right = 200.0
		species_label.offset_top = 50.0
		species_label.offset_bottom = 74.0
		species_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		species_label.add_theme_font_size_override("font_size", 15)
		species_label.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
		species_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		species_label.add_theme_constant_override("shadow_offset_x", 1)
		species_label.add_theme_constant_override("shadow_offset_y", 1)
		species_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		species_label.visible = false
		stage.get_node("CanvasLayer").add_child(species_label)
	species_label.text = str(SPECIES_NAMES[family])
	species_label.visible = true
	_species_token += 1
	get_tree().create_timer(SPECIES_NAME_SECONDS, false).timeout.connect(_hide_species_label.bind(_species_token))

func _hide_species_label(token: int) -> void:
	if token == _species_token and species_label != null and is_instance_valid(species_label):
		species_label.visible = false

func _show_label(text: String, seconds: float) -> void:
	player_label = text
	_label_token += 1
	get_tree().create_timer(seconds, false).timeout.connect(_clear_label.bind(_label_token)) # Bound method: dropped on reload.

func _clear_label(token: int) -> void:
	if token == _label_token and player_label != FAUNA_HINT:
		player_label = ""

## Seconds a unit of `family` stays in play before the director retires it (LOTE 7, CAMERA_TIME).
func camera_time(family: String) -> float:
	return float(CAMERA_TIME.get(family, soft_pressure_seconds))

## Threats alive at once at this point of the route (popcorn excluded).
## LOTE 14: the gradual roster table keeps up to ROSTER_ROUTE_THREATS enemies alive on the route from X=96 (and the old caps before it).
const ROSTER_ROUTE_THREATS := 7
## Rest multiplier of a roster unit spawned at `distance`.
static func fire_slowdown(distance: float) -> float:
	return lerpf(ROSTER_FIRE_SLOWDOWN_FROM, ROSTER_FIRE_SLOWDOWN, clampf(distance / ROSTER_FIRE_RAMP_X, 0.0, 1.0))

static func threat_cap(distance: float) -> int:
	if roster_only and distance >= THREE_AT_ONCE_FROM:
		return ROSTER_ROUTE_THREATS
	if distance >= FOUR_AT_ONCE_FROM:
		return MAX_ROUTE_THREATS
	return 5 if distance >= THREE_AT_ONCE_FROM else 4

## LOTE 9: enemies alive at once, popcorn included (MAX_ON_SCREEN / MAX_ON_SCREEN_ARENA).
func on_screen_cap() -> int:
	return MAX_ON_SCREEN_ARENA if in_arena() else MAX_ON_SCREEN

func alive_count() -> int:
	return active_units.size() + swarm_units.size()

func _spawn_swarm_pending() -> void:
	for unit in swarm_units.duplicate():
		if not is_instance_valid(unit):
			swarm_units.erase(unit)
		elif bool(unit.get("escaped")):
			swarm_units.erase(unit)
			escaped_count += 1
			unit.queue_free()
	while not _swarm_pending.is_empty() and _clock >= float(_swarm_pending[0]["due"]) and swarm_units.size() < MAX_SWARM_ALIVE \
			and alive_count() < on_screen_cap():
		_spawn(_swarm_pending.pop_front())

func _spawn_pending() -> void:
	_spawn_swarm_pending()
	var cap := MAX_ON_SCREEN_ARENA if in_arena() else threat_cap(stage.distance)
	while not _pending.is_empty() and active_units.size() < cap and alive_count() < on_screen_cap():
		if _clock < float(_pending[0]["due"]):
			return
		var request: Dictionary = _pending.pop_front()
		var late := _clock - float(request["due"]) > 0.1
		_spawn(request)
		# A full cap can delay several requests past their original due time.
		# Still separate actual entries instead of releasing them in one frame.
		# REBUILD 02: on-time requests keep their authored spacing (formations such as a V arrive together, never in the
		# same frame: at least MIN_FORMATION_GAP); only a backlog is spread by `group_delay`.
		if not _pending.is_empty():
			var gap := group_delay if late else MIN_FORMATION_GAP
			_pending[0]["due"] = maxf(float(_pending[0]["due"]), _clock + gap)
		return

func _spawn(request: Dictionary) -> void:
	var family := str(request["family"])
	var scene: PackedScene
	match family:
		"Wasp": scene = WASP
		"Probe": scene = PROBE
		"EyeDrone": scene = EYE
		"Turret": scene = TURRET
		"Speeder": scene = SPEEDER
		"OrganicAlien": scene = ORGANIC
		"Walker": scene = WALKER_MINIBOSS if bool(request.get("miniboss", false)) else WALKER
		"Dragonfly": scene = DRAGONFLY
		"Swarm": scene = SWARM
		"Turtle": scene = TURTLE
		"Spider": scene = SPIDER
		"Mosquito", "Ladybird", "WaveDragonfly", "Moth", "Ant", "StagBeetle", "Snail", "MushroomCannon", "SeedCarrier", "AlienFighter", \
		"FlyCommon", "FlyGreen", "FlyCloud", "WormA", "WormB": scene = ASSET_FAUNA[family]
		_: return
	var unit := scene.instantiate() as Node3D
	unit.name = "%s_%d_%d" % [family, int(request["event"]), int(request["slot"])]
	get_node("../Enemies").add_child(unit)
	var air := family in ["Wasp", "Probe", "EyeDrone", "Speeder", "OrganicAlien", "Dragonfly", "Swarm"] or family in ASSET_AIR
	var height: float = [4.6, 2.6, 6.0][int(request["slot"]) % 3] if air else -0.2
	if air and request.has("y"):
		height = float(request["y"]) # Formation height.
	if air:
		height = minf(height, BeeLevel01Framing.max_entity_y()) # Never above the visible top edge - margin.
	# Moving enemies are born just past the right visible edge; the static turret stays on screen
	# (a hard gate must always be clearable).
	var spawn_offset := BeeLevel01Framing.ONSCREEN_SPAWN_X if family == "Turret" or family == "MushroomCannon" \
			else BeeLevel01Framing.spawn_offset_x(BeeLevel01Framing.view_aspect(get_viewport()))
	unit.global_position = Vector3(stage.camera.global_position.x + spawn_offset + float(request.get("x", 0.0)), height, 0)
	if family == "Spider":
		# Drops in from above the top edge INSIDE the screen (its thread is seen first); `x` is camera-relative here.
		unit.global_position = Vector3(stage.camera.global_position.x + float(request.get("x", SPIDER_ENTRY_X)), BeeLevel01Framing.top_y() + 1.6, 0)
	if not bool(request.get("minion", false)):
		_scale_bee_damage(unit, ROUTE_DAMAGE_SCALE)
	unit.set_meta("level_hard", bool(request["hard"]))
	if roster_only:
		unit.set_meta("shot_speed_scale", ROSTER_SHOT_SPEED_SCALE)
	unit.set_meta("level_born", _clock)
	unit.set_meta("level_retreat", false)
	unit.connect("defeated", _on_unit_defeated)
	if unit.has_signal("liberated_now"):
		unit.connect("liberated_now", _on_unit_liberated) # A freed animal stops counting as a threat at once.
	if family == "Swarm":
		swarm_units.append(unit)
		unit.set("path", SWARM_PATHS.find(str(request.get("path", "sine"))))
		unit.set("shooter", bool(request.get("shooter", false)))
		for key in ["speed", "amplitude", "phase"]:
			if request.has(key):
				unit.set(key, float(request[key]))
		if str(request.get("side", "right")) == "left": # LOTE 11: enters from behind the player and travels right.
			unit.set("from_left", true)
			unit.set("shooter", false)
			unit.global_position.x = stage.camera.global_position.x - spawn_offset - float(request.get("x", 0.0))
	else:
		active_units.append(unit)
	spawned_by_family[family] = int(spawned_by_family.get(family, 0)) + 1
	_announce_species(family)
	BeeHostileGlow.ensure.call_deferred(unit) # LOTE 9: every enemy shows a cyan glow (EyeDrone had none).
	if family in ANIMAL_FAMILIES:
		animals_total += 1
	spawn_history.append({"event": request["event"], "family": family, "time": _clock, "distance": stage.distance, "boss_minion": bool(request.get("minion", false))})
	var health := unit.get_node("HealthComponent") as HealthComponent
	health.max_health = BeeGameSettings.scaled_hp(level_hp(family, not bool(request["hard"]))) # NOCHE 01: EASY lowers enemy HP.
	health.current_health = health.max_health
	BeeJuice.attach_hit_flash(unit) # LOTE 11: 0.06 s white flash on every hit.
	health.health_changed.connect(func(_current, _maximum, change): if change < 0: enemy_hit.emit())
	if unit.get("projectile_scene") is PackedScene:
		unit.set("projectile_scene", TOON_ALIEN_BOLT)
	var tuning: Dictionary = LEVEL_TUNING.get(family, {})
	for key in tuning:
		unit.set(key, tuning[key])
	if roster_only:
		var roster_tuning: Dictionary = ROSTER_TUNING.get(family, {})
		for key in roster_tuning:
			unit.set(key, roster_tuning[key])
		if roster_tuning.has("attack_damage") and unit.get("attack_hitbox") is DamageHitbox3D:
			(unit.get("attack_hitbox") as DamageHitbox3D).damage = int(roster_tuning["attack_damage"]) # The hitbox read its damage in _ready.
		for key in (ROSTER_REST_KEYS if not bool(request["hard"]) else []): # The robot gate (and its escorts) keeps its own rhythm (mini-boss test).
			var rest: Variant = unit.get(key)
			if rest is float and not roster_tuning.has(key + "_fixed"):
				unit.set(key, float(rest) * fire_slowdown(stage.distance))
	if family in ["Mosquito", "Ladybird", "WaveDragonfly", "Ant", "StagBeetle", "Dragonfly", "Spider", "Speeder"]:
		var gun := BeeImplantShooter.new()
		gun.family = family
		gun.cooldown_scale = fire_slowdown(stage.distance) if roster_only and not bool(request["hard"]) else 1.0
		gun.target = bee
		unit.add_child(gun)
	if unit is AssetFauna:
		(unit as AssetFauna).max_cycles = 99 # LOTE 7: stays until its CAMERA_TIME (was 3-5 attacks and away).
		(unit as AssetFauna).first_idle_time = FIRST_ATTACK_REST # LOTE 13: first warning soon after arriving
	var slot := int(request["slot"])
	if family == "Wasp":
		# Different presence per Wasp and different hover lines, so two Wasps never attack in lockstep.
		unit.set("stalk_time", 2.2 + 0.7 * float(slot % 3))
		unit.set("stalk_lane", [0.0, 1.1, -1.1][slot % 3])
		# REBUILD 03, introduced progressively: implant sting on the second Wasp of a group from X=40 and on every
		# Wasp from X=150; OVERLOAD on the first Wasp of a group from X=150 and on every Wasp from X=240.
		# COMBAT VARIETY 01: every Wasp from STING_FROM_X stings with ONE short fan of 3 (was 2 aimed bolts on some Wasps).
		if stage.distance >= STING_FROM_X:
			unit.set("sting_shots", 1)
			unit.set("sting_fan_count", 3)
		if stage.distance >= OVERLOAD_FROM_X and (slot % 2 == 0 or stage.distance >= 240.0):
			unit.set("overload_enabled", true)
	elif family == "Probe" or family == "EyeDrone":
		unit.set("initial_delay", 0.35 * float(slot % 3)) # Never the same first-shot frame as a neighbour.
	if family == "EyeDrone" and stage.distance < FAN_FROM_X:
		unit.set("laser_every", 0) # COMBAT VARIETY 01: aimed bursts first; the laser (was: fans) only from FAN_FROM_X.
	if family == "Dragonfly" and not fauna_hint_shown:
		fauna_hint_shown = true
		player_label = FAUNA_HINT
		get_tree().create_timer(3.5, false).timeout.connect(_clear_fauna_hint) # Bound method: dropped if the level reloads.
	if unit is WalkerMiniboss:
		_setup_miniboss(unit as WalkerMiniboss, request)
	if bool(request.get("hold", false)) and family == "Walker":
		unit.set_meta("level_hold", true) # Showcase: the scroll slows while it lives, so it stays on screen.
		health.max_health = BeeGameSettings.scaled_hp(SHOWCASE_HP) # REBUILD 03: SHOWCASE role (5-8 s of reasonable fire).
		health.current_health = health.max_health
	max_active_seen = maxi(max_active_seen, active_units.size())
	if not bool(request.get("minion", false)):
		if in_arena():
			max_alive_arena = maxi(max_alive_arena, alive_count())
		else:
			max_alive_route = maxi(max_alive_route, alive_count())
	if bool(request.get("minion", false)):
		unit.set_meta("boss_minion", true)
		CinematicDepthEntry.begin_from(unit, request["launch_from"], request["launch_slot"], _on_depth_arrived.bind(unit.get_instance_id()), MINION_LAUNCH_SECONDS)
		return
	if bool(request.get("anthill", false)):
		var anthills := stage.get_node_or_null("Anthills") as BeeLevel01Anthills
		var hill := anthills.pick(stage.camera.global_position.x) if anthills != null else {}
		if not hill.is_empty():
			anthills.emerge(unit, hill, _on_depth_arrived.bind(unit.get_instance_id()))
			return # Activated when it has hopped out of the mound.
	if bool(request.get("depth", false)):
		var slot_point := Vector2(DEPTH_TARGET_X + float(request.get("x", 0.0)), height)
		CinematicDepthEntry.begin(unit, slot_point, request.get("anchor", slot_point), _on_depth_arrived.bind(unit.get_instance_id()))
		depth_entries += 1
		return # Activated on arrival at the flight plane (no AI, shots, collision or auto-aim before).
	if not unit.call("activate", bee):
		push_error("Level 01 failed to activate %s" % family)

func _scale_bee_damage(unit: Node3D, scale: float) -> void:
	unit.set_meta("incoming_bee_damage_scale", scale)
	for area in unit.find_children("*", "Area3D", true, false):
		if area is DamageHitbox3D:
			area.bee_damage_scale = scale

## Shared start point of a depth formation: the middle of its slots (camera-relative X, absolute Y).
func _depth_anchor(event: Dictionary) -> Vector2:
	var xs: Array = event.get("x", [])
	var ys: Array = event.get("y", [])
	var mean_x := 0.0
	var mean_y := 4.4
	if not xs.is_empty():
		mean_x = xs.reduce(func(a, b): return float(a) + float(b), 0.0) / float(xs.size())
	if not ys.is_empty():
		mean_y = ys.reduce(func(a, b): return float(a) + float(b), 0.0) / float(ys.size())
	return Vector2(DEPTH_TARGET_X + mean_x, mean_y)

func _on_depth_arrived(id: int) -> void:
	var unit := instance_from_id(id) as Node3D
	if unit == null or not is_instance_valid(unit) or _frozen or not active_units.has(unit):
		return
	unit.set_meta("level_born", _clock) # Its soft lifetime starts on the flight plane.
	if not unit.call("activate", bee):
		push_error("Level 01 failed to activate %s after its depth entry" % unit.name)

func _retire_soft_units(delta: float) -> void:
	for unit in active_units.duplicate():
		if bool(unit.get_meta("level_hard")):
			continue
		# REBUILD 02: a ground unit left behind the left edge is out of play at once (it can never come back on its
		# own and would hold the next gate with an empty screen).
		var left_behind: bool = (unit is GroundWalkerEnemy or unit is GroundTurretEnemy or (unit.has_method("is_ground") and bool(unit.call("is_ground")))) \
				and unit.global_position.x < stage.camera.global_position.x - BeeLevel01Framing.half_width_min(BeeLevel01Framing.DESIGN_ASPECT) - 0.8
		if left_behind or _clock - float(unit.get_meta("level_born")) >= camera_time(str(unit.name).get_slice("_", 0)):
			if not bool(unit.get_meta("level_retreat")):
				unit.set_meta("level_retreat", true)
				unit.set_physics_process(false)
				unit.remove_from_group("bee_auto_aim_targets")
				for area: Area3D in unit.find_children("*", "Area3D", true, false):
					if area is DamageHitbox3D:
						(area as DamageHitbox3D).set_enabled(false)
					area.set_deferred("monitoring", false)
					area.set_deferred("monitorable", false)
			unit.global_position.x -= retreat_speed * delta
		if unit.global_position.x < stage.camera.global_position.x - 8.0:
			active_units.erase(unit)
			escaped_count += 1
			unit.queue_free()

func _on_unit_defeated(unit: Node3D) -> void:
	if not bool(unit.get_meta("juice_downed", false)): # A freed animal already counted when it was liberated.
		unit.set_meta("juice_downed", true)
		unit_downed.emit(unit, false)
	active_units.erase(unit)
	swarm_units.erase(unit)
	# Keep the existing death feedback briefly, then release its subtree.
	get_tree().create_timer(1.0).timeout.connect(_release_unit.bind(unit.get_instance_id())) # Bound method + id: safe across reloads.

func _on_human_exited() -> void:
	if not _waiting_for_human or _frozen:
		return
	_waiting_for_human = false
	warning.hide()
	stage.scroll_speed = LEVEL_SCROLL
	encounter_label = "RUTA DESPEJADA · AVANZÁ →"
	player_label = encounter_label

## LOTE 7: the Level 01 cruise scroll (m/s); see LEVEL_SCROLL.
func level_scroll() -> float:
	return LEVEL_SCROLL

func is_complete() -> bool:
	return _complete

func resume_after_checkpoint(progress: float) -> void:
	# New scene: no actors/pending shots to serialize. Earlier events are consumed.
	event_index = 0
	while event_index < events_table().size() and float(events_table()[event_index]["at"]) < progress:
		event_index += 1
	current_act = 1
	for index in ACT_STARTS.size():
		if progress >= float(ACT_STARTS[index]):
			current_act = index + 1
	for event: Dictionary in events_table():
		if "Dragonfly" in event["units"] and float(event["at"]) < progress:
			fauna_hint_shown = true # Already learnt before the checkpoint.
	encounter_label = "CHECKPOINT · SEGUNDA MITAD"
	player_label = encounter_label if show_debug_labels else "CHECKPOINT"
	if progress > 140.0:
		human.freeze()
		human.current_phase = GiantHumanCrossingHazard.Phase.EXITED
		human.crossings_started = 1
		human.crossings_exited = 1

func freeze_enemies() -> void:
	_frozen = true
	human.freeze()
	for unit in active_units + swarm_units:
		unit.set_physics_process(false)
	if boss != null and is_instance_valid(boss):
		boss.freeze()
	if tarantula != null and is_instance_valid(tarantula):
		tarantula.freeze()
	stage.scroll_speed = 0.0

# --- UFO BOSS 01 (FIRST CONTACT) -------------------------------------------------------------
# last encounter -> breather (arena locked) -> UFO approach -> boss -> death -> wave_completed.

func _advance_boss(delta: float) -> void:
	if boss_defeated:
		return
	if roster_only:
		_advance_tarantula(delta) # LOTE 12 · ETAPA 3: no UFO in Level 1; the tarantula closes it (after the robot mini-boss).
		return
	if boss == null:
		if _boss_breather_left < 0.0:
			_boss_breather_left = BOSS_BREATHER
			current_act = 5
			director_moment.emit(&"last_silence")
			stage.scroll_speed = 0.0 # Arena lock: no more scroll, no more encounters.
			encounter_label = "FINAL · CONTACTO"
			player_label = "SEÑAL DESCONOCIDA" # UFO BOSS 01: warning during the last silence and the approach.
			_spawn_boss_supplies()
		_boss_breather_left -= delta
		if _boss_breather_left <= 0.0:
			_start_boss()

func _start_boss() -> void:
	boss = UFO_BOSS.instantiate() as UfoBoss01
	boss.name = "UfoBoss01"
	boss.max_hp = BeeGameSettings.scaled_hp(boss.max_hp) # NOCHE 01: EASY lowers the UFO HP too (before _ready reads it).
	get_node("../Enemies").add_child(boss)
	boss.defeated.connect(_on_boss_defeated)
	boss.phase_changed.connect(_on_boss_phase)
	boss.summon_requested.connect(_on_boss_summon)
	encounter_label = "PRIMER CONTACTO · OVNI"
	player_label = "SEÑAL DESCONOCIDA"
	var checkpoint := stage.get_node_or_null("CheckpointQoL") as BeeCheckpointQoL
	if checkpoint != null:
		checkpoint.activate_boss_checkpoint() # Retry after a defeat respawns at the start of the fight.
	# BOSS v2: first attempt from the right, the retry from the left, and so on. Bee gets the whole width.
	boss.entry_side = 1.0 if checkpoint == null or checkpoint.boss_checkpoint_count % 2 == 1 else -1.0
	stage.set("boss_arena_wide", true)
	boss.begin(stage.camera, bee)

func _on_boss_phase(state: int) -> void:
	if state == UfoBoss01.State.DEATH:
		for minion in boss_minions():
			minion.get_node("HealthComponent").take_damage(99999) # The minions fall with their ship.
	if state == UfoBoss01.State.PHASE_1:
		player_label = "" # The health bar takes over.

func _on_boss_defeated(defeated_boss: UfoBoss01) -> void:
	boss_defeated = true
	unit_downed.emit(defeated_boss, false) # LOTE 11: boss points + hit stop.
	boss = null
	_complete = true
	stage.scroll_speed = POST_BOSS_SCROLL # Short roll to the sector end, then SECTOR DESPEJADO.
	wave_completed.emit()

## LOTE 12: Level 1 without the UFO: the last encounter (the walking robot) is cleared -> the sector completes after a short run-out.
const ROSTER_RUN_OUT_SCROLL := 3.2
var roster_complete := false

func _finish_roster_level() -> void:
	if _complete:
		return
	roster_complete = true
	_complete = true
	stage.scroll_speed = ROSTER_RUN_OUT_SCROLL
	encounter_label = "RUTA DESPEJADA"
	wave_completed.emit()

func boss_active() -> bool:
	return (boss != null and is_instance_valid(boss) and boss.is_active()) or (tarantula != null and is_instance_valid(tarantula) and tarantula.is_active())

# --- LOTE 12 · ETAPA 3: walking robot mini-boss and the tarantula --------------------------------------------------------

func _setup_miniboss(robot: WalkerMiniboss, request: Dictionary) -> void:
	miniboss = robot
	var health := robot.get_node("HealthComponent") as HealthComponent
	health.max_health = BeeGameSettings.scaled_hp(MINIBOSS_HP)
	health.current_health = health.max_health
	robot.set_meta("level_miniboss", true)
	var escort: Dictionary = request.get("escort_wave", {})
	var event_id := int(request["event"])
	robot.escorts_requested.connect(func():
		if not escort.is_empty() and not _frozen:
			escort_waves += 1
			_queue_units(escort, event_id, 200))
	robot.defeated.connect(func(_robot):
		miniboss_seconds = robot.fight_seconds)
	escort_waves = 1 # The first wave comes with it (the event's own escorts).

## After the robot gate: breather (arena locked, supplies), then the tarantula walks in from the right at dusk.
func _advance_tarantula(delta: float) -> void:
	if tarantula_freed:
		return
	if tarantula != null:
		return
	if _tarantula_breather_left < 0.0:
		_tarantula_breather_left = TARANTULA_BREATHER
		current_act = 5
		stage.scroll_speed = 0.0 # Arena lock.
		encounter_label = "FINAL · LA TARÁNTULA"
		player_label = "ALGO SE MUEVE EN LAS TELARAÑAS"
		_spawn_boss_supplies()
	_tarantula_breather_left -= delta
	if _tarantula_breather_left <= 0.0:
		_start_tarantula()

func _start_tarantula() -> void:
	var checkpoint := stage.get_node_or_null("CheckpointQoL") as BeeCheckpointQoL
	if checkpoint != null:
		checkpoint.activate_boss_checkpoint() # Before counting it: a retry counts it again from the snapshot.
	tarantula = TARANTULA.instantiate() as TarantulaBoss01
	tarantula.name = "TarantulaBoss01"
	tarantula.max_hp = BeeGameSettings.scaled_hp(tarantula.max_hp)
	get_node("../Enemies").add_child(tarantula)
	tarantula.defeated.connect(_on_tarantula_gone)
	tarantula.liberated_now.connect(_on_tarantula_freed)
	tarantula.phase_changed.connect(_on_tarantula_phase)
	tarantula.summon_requested.connect(_on_boss_summon)
	animals_total += 1 # An animal: it will be freed, never killed.
	encounter_label = "FINAL · LA TARÁNTULA"
	player_label = "LA TARÁNTULA"
	stage.set("boss_arena_wide", true)
	tarantula.begin(stage.camera, bee)

func tarantula_active() -> bool:
	return tarantula != null and is_instance_valid(tarantula) and tarantula.is_active()

func _on_tarantula_phase(state: int) -> void:
	if state == TarantulaBoss01.State.FREED:
		for minion in boss_minions():
			minion.get_node("HealthComponent").take_damage(99999) # Its flies are freed with it.
	if state == TarantulaBoss01.State.PHASE_1:
		player_label = "" # The health bar takes over.

func _on_tarantula_freed(freed: TarantulaBoss01) -> void:
	liberated_count += 1
	BeeMusic.victory() # LOTE 14: the victory theme plays once, then fades.
	unit_downed.emit(freed, true)
	player_label = ""

## The tarantula has walked away: the level is complete (short run-out, then SECTOR DESPEJADO · LIBERADOS n/N).
func _on_tarantula_gone(_gone: TarantulaBoss01) -> void:
	tarantula_freed = true
	boss_defeated = true
	tarantula = null
	roster_complete = true
	_complete = true
	stage.sector_length = minf(stage.sector_length, stage.distance + TARANTULA_RUN_OUT)
	stage.scroll_speed = POST_BOSS_SCROLL
	wave_completed.emit()

func _clear_fauna_hint() -> void:
	if player_label == FAUNA_HINT:
		player_label = ""

func _on_unit_liberated(unit: Node3D) -> void:
	active_units.erase(unit)
	if not bool(unit.get_meta("juice_downed", false)):
		unit.set_meta("juice_downed", true)
		unit_downed.emit(unit, true)
	if str(unit.name).get_slice("_", 0) in ANIMAL_FAMILIES:
		liberated_count += 1

## NOCHE 01: animals outside the event table (the turtle of the aftermath moment).
func register_extra_animal() -> void:
	animals_total += 1

func note_extra_liberated(unit: Node3D = null) -> void:
	liberated_count += 1
	if unit != null:
		unit_downed.emit(unit, true)

func liberation_text() -> String:
	return "LIBERADOS %d/%d" % [liberated_count, animals_total]

func _release_unit(id: int) -> void:
	var unit := instance_from_id(id) as Node
	if unit != null and is_instance_valid(unit):
		unit.queue_free()

## Showcase hold: while a "hold" unit (showcase Walker) is alive and in play, the scroll slows to HOLD_SCROLL so the
## set piece stays on screen; it never overrides gates, the human or the boss arena (they stop the scroll anyway).
func _update_hold() -> void:
	var hold := false
	for unit in active_units:
		if bool(unit.get_meta("level_hold", false)) and not bool(unit.get_meta("level_retreat", false)):
			hold = true
			break
	if hold and not _holding and is_equal_approx(stage.scroll_speed, LEVEL_SCROLL):
		stage.scroll_speed = HOLD_SCROLL
		_holding = true
	elif not hold and _holding:
		_holding = false
		if is_equal_approx(stage.scroll_speed, HOLD_SCROLL):
			stage.scroll_speed = LEVEL_SCROLL

# --- BOSS CHALLENGE V2 (REBUILD 03): minions ------------------------------------------------------------------

## Live minions launched by the UFO (never more than MAX_BOSS_MINIONS).
func boss_minions() -> Array[Node3D]:
	var list: Array[Node3D] = []
	for unit in active_units:
		if is_instance_valid(unit) and unit.has_meta("boss_minion"):
			list.append(unit)
	return list

## Minions leave the saucer's hatch and fly to their slots (no AI, shots or collision until they arrive), then fight
## as normal Level 01 units that never retreat on their own.
func _on_boss_summon(family: StringName, count: int) -> void:
	if ((boss == null or not is_instance_valid(boss)) and not tarantula_active()) or _frozen:
		return
	# COMBAT VARIETY 01 (boss v2): minions come in from several points - above the screen, the left edge and the right
	# edge - in rotation, each to a slot on its own side (camera-relative). They keep aimed bursts (no laser) under the boss.
	var half := BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(get_viewport()))
	var gates := [[Vector3(-0.8, BeeLevel01Framing.top_y() + 1.4, 0.0), Vector2(-0.8, 5.8)],
			[Vector3(-half - 1.2, 3.8, 0.0), Vector2(-half + 1.6, 4.2)],
			[Vector3(half + 1.2, 2.8, 0.0), Vector2(half - 1.6, 2.6)]]
	for i in count:
		if boss_minions().size() >= MAX_BOSS_MINIONS:
			return
		var gate: Array = gates[minion_gate_index % gates.size()]
		minion_gate_index += 1
		var free_slot: Vector2 = gate[1]
		# LOTE 12 · ETAPA 3: the tarantula's flies are soft (they leave after their CAMERA_TIME); the UFO's minions stay until shot.
		_spawn({"family": str(family), "slot": i, "event": events_table().size() - 1, "hard": not tarantula_active(), "y": free_slot.y, "minion": true,
				"launch_from": gate[0], "launch_slot": free_slot})
		if not active_units.is_empty():
			active_units.back().set("laser_every", 0)
			active_units.back().set("split_orb", false)
			active_units.back().set("burst_shots", 1)
			active_units.back().set("windup_time", UfoBoss01.MIN_TELEGRAPH)
			if tarantula_active(): # LOTE 12 · ETAPA 3: the tarantula's flies are a distraction, not a second damage source.
				_scale_bee_damage(active_units.back(), TARANTULA_MINION_DAMAGE_SCALE)
		minion_gates_used.append(minion_gate_index - 1)

## UFO BOSS 01: a Bomb pickup appears in the arena during the last silence (only when Bee is low on charges, so dying and
## retrying never farms bombs). The level's last pollen (PollenM) sits just before the arena at X=338.4.
func _spawn_boss_supplies() -> void:
	if bee.health.current_health < int(bee.health.max_health * BOSS_HEAL_BELOW):
		# NOCHE 01 · ETAPA 2: the Codex honey jar (healing) before the UFO when Bee is hurt.
		var jar := TOON_HEALING.instantiate() as Node3D
		jar.name = "BossHealing"
		stage.add_child(jar)
		jar.global_position = Vector3(stage.camera.global_position.x - 1.6, 4.4, 0.0)
	if bee.bomb_charges >= 2:
		return
	var pickup := POWERUP_PICKUP.instantiate() as BeePowerupPickup
	pickup.name = "BossBomb"
	pickup.kind = BeePowerupPickup.Kind.BOMB
	stage.add_child(pickup) # Not under "Powerups": that node is the level's fixed pickup set.
	pickup.global_position = Vector3(stage.camera.global_position.x - 0.5, 3.2, 0.0)

## NOCHE 01 · ETAPA 2: the Giant Human is off (GIANT_HUMAN_ENABLED): frozen, hidden, no hitbox, never starts.
func _switch_off_human() -> void:
	if is_instance_valid(human):
		human.freeze()
		human.hide()


# --- LOTE 13 · ETAPA 2: zone timing (denser while Level 1 plays its roster) ----------------------------------------------------

func arena_cadence() -> float:
	return ROSTER_ARENA_CADENCE if roster_only else ARENA_WAVE_CADENCE

func arena_wave_max() -> float:
	return ROSTER_ARENA_WAVE_MAX if roster_only else ARENA_WAVE_MAX

func arena_max_seconds() -> float:
	return ROSTER_ARENA_MAX_SECONDS if roster_only else ARENA_MAX_SECONDS

func arena_min_seconds() -> float:
	return ROSTER_ARENA_MIN_SECONDS if roster_only else ARENA_MIN_SECONDS

## HP of a family in the CURRENT flow (the roster scales some families up, see ROSTER_HP_SCALE; EASY scaling is applied by the caller).
static func level_hp(family: String, roster_extra := true) -> int:
	if roster_only and BeeGameSettings.SMALL_ENEMY_HP.has(family):
		return int(BeeGameSettings.SMALL_ENEMY_HP[family])
	var base := int(LEVEL_HP[family])
	if roster_only and ROSTER_HP_SCALE.has(family):
		base = roundi(float(base) * float(ROSTER_HP_SCALE[family]))
	if roster_only and roster_extra and family in ROSTER_HP_EXTRA_FAMILIES:
		base = roundi(float(base) * ROSTER_HP_EXTRA)
	return base
