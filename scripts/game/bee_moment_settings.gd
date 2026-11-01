extends RefCounted
## Tanda X — un momento especial por acto (el acto 1 ya tiene la regadera). Cada uno tiene su interruptor; durante el
## momento el director no lanza enemigos (usa el mismo "respiro" que después de una zona). No cambia vida ni daño de jefes.

## Acto 2 (macizo): 10 s esquivando gotas de rocío que caen de las hojas, con aviso.
static var MOMENT_DEW_ENABLED := true
const MOMENT_DEW_X := 165.0 # En la tabla del director, entre los gusanos rosas del macizo.
const MOMENT_DEW_SECONDS := 10.0
const MOMENT_DEW_EVERY := 0.55 # s entre gotas.
const MOMENT_DEW_WARNING := 0.6 # La gota brilla colgada de la hoja antes de caer (aviso >= 0,4 s).
const MOMENT_DEW_SPEED := 9.0 # m/s al caer.
const MOMENT_DEW_DAMAGE := 3
const MOMENT_DEW_RADIUS := 0.22
const MOMENT_DEW_COLOR := Color(0.7, 0.92, 1.0, 0.85)

## Acto 3 (huerta): 8 s, una cortadora de césped pasa al fondo, sacude la pantalla y tira pasto cortado por abajo:
## Bee tiene que volar alto.
static var MOMENT_MOWER_ENABLED := true
const MOMENT_MOWER_X := 244.5 # En la tabla, después de los gusanos de compost.
const MOMENT_MOWER_SECONDS := 8.0
const MOMENT_MOWER_WARNING := 1.2 # Cartel "¡VOLÁ ALTO!" y franja marcada antes del primer golpe.
const MOMENT_MOWER_SAFE_Y := 2.6 # Por encima de esto no llega el pasto cortado.
const MOMENT_MOWER_DAMAGE := 4
const MOMENT_MOWER_PULSE := 0.7 # s entre ráfagas de pasto.
const MOMENT_MOWER_SHAKE := 0.035
const MOMENT_MOWER_Z := -7.5 # Pasa al fondo, detrás del plano de vuelo.
const MOMENT_MOWER_SCALE := 3.2
