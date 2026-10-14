extends RefCounted
## T6a: one source for Level 01 HP. Model length / Bee v02 at art scale 1,
## independent of the development-only visual comparator. No damage tuning here.
const BEE_MODEL_LENGTH := 1.166667
const ANT_CRUISE_SPEED := 2.6
const SLOW_SPEED_RATIO := 0.5
const SLOW_TIME_SCALE := 0.7
const CLASS_TIME := [Vector2(0.25,0.4),Vector2(0.5,0.8),Vector2(1.0,1.5),Vector2(2.0,3.0)]
const CLASS_MAX_RATIO := [0.4,0.7,1.2]
const COMMON_HP := {
	"FlyCommon": 42, "FlyGreen": 45, "FlyCloud": 75, "Wasp": 45,
	"Ant": 42, "Ladybird": 45, "WormA": 60, "WormB": 60,
	"StagBeetle": 60, "Snail": 60, "Spider": 90, "MushroomCannon": 60,
}
## [model length (m), normal movement (m/s)]. Peak attack speeds are not cruise speeds.
const MEASUREMENTS := {
	"FlyCommon": [0.9834,3.6], "FlyGreen": [1.101408,5.0], "FlyCloud": [2.289561,3.4],
	"Wasp": [1.265,2.6], "Ant": [1.298,2.6], "Ladybird": [1.062,2.2],
	"WormA": [2.55816,0.12], "WormB": [1.94616,0.12], "StagBeetle": [1.77,1.4],
	"Snail": [1.534,0.7], "Spider": [1.650779,3.2], "MushroomCannon": [1.52,0.0],
}
## Explicit developer decision: beetles count as slow even though cruise 1.4
## is slightly above half the ant's 2.6 (1.3). Movement itself is unchanged.
const SLOW_OVERRIDE := ["StagBeetle"]
## Reserved/legacy HP remain unchanged; bosses have their own constants.
const LEGACY_HP := {"Wasp":36,"Probe":70,"EyeDrone":50,"Turret":70,"Speeder":40,
	"OrganicAlien":100,"Walker":100,"Dragonfly":110,"Swarm":10,"Spider":80,
	"Mosquito":36,"Ladybird":70,"WaveDragonfly":64,"Moth":70,"Ant":64,
	"StagBeetle":120,"Snail":120,"MushroomCannon":70,"SeedCarrier":220,"AlienFighter":70,
	"FlyCommon":30,"FlyGreen":40,"FlyCloud":24,"WormA":70,"WormB":60,"Turtle":220}

static func target_time(family: String) -> Vector2:
	var measurement: Array = MEASUREMENTS[family]
	var ratio := float(measurement[0])/BEE_MODEL_LENGTH
	var index := 0
	while index < CLASS_MAX_RATIO.size() and ratio > CLASS_MAX_RATIO[index]: index += 1
	var slow := float(measurement[1]) < ANT_CRUISE_SPEED*SLOW_SPEED_RATIO or family in SLOW_OVERRIDE
	return CLASS_TIME[index] * (SLOW_TIME_SCALE if slow else 1.0)
