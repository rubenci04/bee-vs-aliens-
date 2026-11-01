extends RefCounted
## Tanda W — "el mundo responde": tres escenas cortas dentro del Nivel 1 y los carteles de entrada de los jefes.
## Las escenas pausan el juego, tienen barras negras arriba y abajo y se saltean con cualquier botón. Cada una sale una sola
## vez por partida: un reintento desde checkpoint no la repite; un reinicio total o volver a jugar desde el título, sí.

static var STORY_BEATS_ENABLED := true
static var BOSS_CARDS_ENABLED := true

const BAR_HEIGHT := 0.11 # Fracción del alto de pantalla de cada barra negra.
const BAR_IN_SECONDS := 0.25
const SKIP_GRACE_SECONDS := 0.2 # Un botón apretado justo al empezar no la saltea (era el disparo de antes).

## 1. Al empezar: el implante chispea, Bee sacude la cabeza y pasa de neutra a concentrada.
const START_SECONDS := 2.4
const START_SHAKES := 3 # Sacudidas de cabeza.
const START_SHAKE_DEGREES := 18.0
## 2. Antes del robot: la cámara se abre un poco, el robot se ve enorme, Bee traga saliva (sorpresa) y dice "Uh...".
const ROBOT_SECONDS := 2.6
const ROBOT_FOV_OPEN := 1.12 # El FOV crece un 12 % (la cámara "se abre").
const GULP_SQUASH := 0.9
## 3. Antes de la tarántula: Bee mira para arriba, a las telarañas, y dice "¡Arañas no!".
const SPIDER_SECONDS := 2.6
const LOOK_UP_DEGREES := 22.0
## Cuándo se dispara cada escena: el jefe ya está a esta distancia del centro de la pantalla (m).
const BOSS_ON_SCREEN := 5.5

## Cartel de entrada de los jefes: nombre y una línea, 1,5 s, sin tapar la barra de vida (arriba).
const CARD_SECONDS := 1.5
const CARD_TOP := 0.30 # Fracción del alto de pantalla.
const CARDS := {
	&"robot": ["ROBOT CAMINANTE", "Minijefe · rompé su cañón y liberá a su escolta"],
	&"spider": ["LA TARÁNTULA", "Jefa final · apuntale al implante cuando brilla"],
}
