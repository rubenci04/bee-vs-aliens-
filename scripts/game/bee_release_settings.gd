extends RefCounted
const SECONDS := 0.8
const FULL_LIMIT := 12
const TURN := 0.65
const DEPARTURE := Vector3(-1.2,0.8,-4.0)
const FADE_START := 0.18
const SPARKS := 5
const SIMPLE_SPARKS := 2
const SPARK_LIMIT := 16
const SPARK_SECONDS := 0.18
const SPARK_COLOR := Color(0.2,0.6,1.0)
const SPARK_RADIUS := 0.08
const STOP_SECONDS := 0.05
const STOP_COOLDOWN := 0.5
const STOP_RADIUS := 3.0
const STOP_MAX_SHOTS := 32
const SHAKE_AMPLITUDE := 0.035
const SHAKE_SECONDS := 0.12
const HIT_STOP_KEY := KEY_O
static var enabled := true
static var legacy_review := false # Render/benchmark only; never enabled by the game.
## Tanda W — liberación visible: el insecto, ya con su color, da una vuelta alrededor de Bee (sin estorbar ni dañar:
## sus colisiones ya están apagadas) y recién después se va volando al fondo. Uno de cada POLLEN_DROP_EVERY deja polen.
static var LAP_ENABLED := true
## Mejora de claridad: pedido de Rubén. El liberado ya no da la vuelta ni sube desvaneciéndose (se veía como un alma y llenaba la pantalla):
## se encoge enseguida y listo. false vuelve a la vuelta y la salida al fondo.
static var QUICK_RELEASE := true
const QUICK_SECONDS := 0.12
const LAP_SECONDS := 0.6 # La vuelta alrededor de Bee.
const LAP_RADIUS := 1.5 # m alrededor de Bee.
const LAP_HEIGHT := 0.4 # La órbita queda un poco por encima de Bee.
const LEAVE_SECONDS := 0.6 # Después se va al fondo y se desvanece.
const LEAVE_TO := Vector3(-2.0, 2.5, -6.0) # Hacia dónde se va, relativo a donde terminó la vuelta.
const POLLEN_DROP_EVERY := 4
const IMPLANT_POP_SCALE := 0.35 # El implante salta y explota chiquito.
## El contador LIBERADOS del HUD es el único aviso: sin carteles "LIBERADO" flotantes.
static var FLOATING_TEXT := false
