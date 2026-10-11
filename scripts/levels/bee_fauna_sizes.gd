class_name BeeFaunaSizes
extends RefCounted
## NOCHE 01 — sizes of the Level 01 animals RELATIVE TO BEE (Bee's body length = 1.0). One table, easy to tune; every animal
## computes its model scale from its own measured length, so hitboxes built from the model bounds follow automatically.

## Bee's visual body length in metres (bee_alien_visual at VISUAL_SCALE 1.2, measured; validate_bee_liberation_v01 checks it).
const BEE_LENGTH := 1.18
## Body length of each animal / Bee's length.
const SIZE := {
	&"mosquito": 0.7, &"firefly": 0.6, &"ladybird": 0.9, &"ant": 1.1, &"stag_beetle": 1.5, &"snail": 1.3,
	&"spider": 1.4, &"moth": 1.4, &"dragonfly": 2.0,
	&"strider": 1.3, &"nymph": 1.2, &"perch": 2.2, # NOCHE 01 · ETAPA 4: lake prototype.
}


## Metres an animal of `kind` should measure along its body (X).
static func target_length(kind: StringName) -> float:
	return float(SIZE.get(kind, 1.0)) * BEE_LENGTH
