extends RefCounted
## Tanda V · parte 2 — ENJAMBRE LIBRE, el movimiento firma de Bee: los insectos que liberó vuelven a pelear a su lado.
## FREE_SWARM_ENABLED = false lo apaga entero (barra, tecla y HUD). Nunca cambia la vida ni el daño por golpe de los jefes.

static var FREE_SWARM_ENABLED := true
const ACTION := &"bee_swarm" # Teclado E, mando cruceta arriba (bee_input_devices.gd).

## Cada insecto liberado suma 1; con la barra llena se puede llamar.
const SWARM_CHARGE_NEEDED := 25
const SWARM_SECONDS := 6.0
const SWARM_ALLIES := 6
const SWARM_SHOT_DAMAGE := 2
const SWARM_SHOT_EVERY := 0.6 # s entre disparos de cada aliado (desfasados entre sí).
const SWARM_RANGE := 11.0 # m: solo apuntan a enemigos en pantalla y a esta distancia de Bee.
const SWARM_BOSS_FACTOR := 0.5 # Contra jefes hacen la mitad (2 -> 1).

## Órbita alrededor de Bee.
const ORBIT_RADIUS := 1.25
const ORBIT_SPEED := 2.4 # rad/s
const ORBIT_SQUASH := 0.6 # Elipse: más ancha que alta, para no tapar a Bee.
const ALLY_SCALE := 0.42
const ALLY_MODELS := ["res://scenes/art_labs/fly_trio_v01/common.tscn", "res://scenes/art_labs/fly_trio_v01/green.tscn", "res://scenes/art_labs/assets_v03/controlled_flying_ladybird.tscn"]
const ARRIVE_SECONDS := 0.35 # Entran volando desde atrás de Bee.

## HUD: tira debajo de LIBERADOS.
const HUD_COLOR := Color(1.0, 0.78, 0.25)
const HUD_READY_PULSE_HZ := 2.0
