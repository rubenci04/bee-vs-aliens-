extends RefCounted
## Tanda B: all arrival / recovery presentation and reach values live here.
const MARK_SECONDS := 0.5
const RETURN_MARK_SECONDS := 0.6
const MATERIALIZE_SECONDS := 0.45
const BEAM_FADE_SECONDS := 0.15
const WARNING_SCALE := 1.12
const GROUND_Y := -0.12
const BEAM_TOP := 8.5
const BEAM_RADIUS := 0.75
const RETURN_MARGIN := 0.9
const RESCUE_SECONDS := 12.0
const RESCUE_MAX_ENEMIES := 3
const REACH := 8.0 # E1: arrivals land in the right third (>= 4.5 m ahead of Bee), so "near" must cover them
const ARRIVAL_OFFSET := 4.5
const ARRIVAL_MIN_FROM_CAMERA := 2.8
const ARRIVAL_RIGHT_MARGIN := 1.0
const BEAM_ONE_IN := 3 # E1: of the eligible route units, every 3rd still arrives by beam
const NATURAL_ENTRY_FAMILIES := ["Ant","Snail","StagBeetle","FlyCommon","FlyGreen","Wasp","Mosquito","Ladybird"]
const EXTRA_ARRIVAL_SECONDS := 30.0
const REINFORCE_BELOW := 2 # Tanda E: a zone reinforcement only when fewer than this many enemies are alive
const REINFORCE_RECHECK_SECONDS := 4.0 # ...checked again this often until the condition holds
const MAX_FLY_GROUPS := 2
const FINAL_GROUP_FROM_X := 240.0
const FINAL_GROUP_SIZE := 9

const APPROACH_EPSILON := 0.25
