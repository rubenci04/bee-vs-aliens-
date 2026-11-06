extends RefCounted
## Mejora visual · cámara del Nivel 1. Todo lo de la cámara "con vida" sale de acá.
## MODO:  &"lateral"   = la cámara de siempre (respaldo; también la usan los tests y bots en modo headless).
##        &"dinamica"  = 2.5D: el juego sigue en el plano X/Y, pero la cámara mira un poco hacia adelante, sigue a Bee y
##                       cambia de ángulo por zona y con los jefes (estilo shooter arcade con cámara dinámica).
##        &"atras"     = prototipo desde atrás, solo para comparar (no es jugable como modo final, ver docs/informe_sesion.md).
## Solo cambia lo que se DIBUJA: los límites de vuelo, las apariciones y la lógica de "está en pantalla" no cambian.

const DEFAULT_MODE := &"dinamica"
static var mode: StringName = DEFAULT_MODE

## Nada de esto corre sin ventana (los tests miden la cámara lateral).
const ACTIVE_IN_HEADLESS := false

## Tabla de ángulos por zona: [X del nivel, giro (grados, + = mira adelante), inclinación extra (grados, + = mira más arriba),
## altura del centro de la vista (metros sobre la altura normal), apertura (multiplicador del FOV)].
const KEYFRAMES := [
	[0.0, 9.0, 0.0, 0.0, 1.05],      # Césped: entrada tranquila.
	[64.0, 11.0, -0.5, 0.0, 1.06],   # Macizo: un poco más de giro.
	[130.0, 13.0, -1.0, 0.0, 1.07],  # Antes de la nube.
	[185.0, 8.0, 1.0, 0.0, 1.05],    # Huerta: más frontal, se ven los surcos.
	[262.0, 15.0, -1.5, 0.0, 1.08],  # Sombra: la más dramática antes del robot.
	[294.0, 11.0, -0.5, 0.0, 1.06],  # Robot.
	[320.0, 10.0, 0.0, 0.0, 1.06],   # Respiro.
	[338.0, 13.0, 0.5, 0.0, 1.07],   # Tarántula.
]

const LOOK_SHIFT_FACTOR := 0.075 ## m hacia atrás por cada grado de giro: mantiene el borde izquierdo a la vista.
const BEE_FOLLOW_Y := 0.09 ## Cuánto sigue la vista a la altura de Bee (0 = nada). Da paralaje sin mover los límites.
const BEE_FOLLOW_MAX := 0.32 ## Tope en metros de ese seguimiento.
const BEE_YAW_FROM_X := 0.45 ## Grados de giro extra según Bee esté a la derecha o izquierda de la pantalla.
const ROLL_FROM_VY := 0.35 ## Grados de alabeo por m/s de subida/bajada de Bee.
const ROLL_MAX := 1.6 ## Tope del alabeo (grados).
const BREATH_YAW := 0.25 ## Respiración lenta de la cámara (grados).
const BREATH_Y := 0.03 ## Respiración vertical (m).
const BREATH_SPEED := 0.35 ## Velocidad de la respiración.
const SMOOTH_SECONDS := 0.35 ## Suavizado del seguimiento.
const BOSS_ENTRY_YAW := 4.0 ## Grados extra de giro mientras entra un jefe (se abre el plano).
const BOSS_ENTRY_SECONDS := 2.2 ## Cuánto dura ese giro extra.

## Prototipo "desde atrás": detrás y arriba de Bee, sobre su hombro (por eso el plano se ve de canto).
const BACK_DISTANCE := 5.2
const BACK_HEIGHT := 1.7
const BACK_SIDE := 1.6
const BACK_FOV := 62.0
