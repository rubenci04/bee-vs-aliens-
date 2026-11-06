extends RefCounted
## Mejora visual · cámara del Nivel 1. Todo lo de la cámara "con vida" sale de acá.
## MODO:  &"lateral"   = la cámara de siempre (respaldo; es también la que usan los tests y bots en modo headless).
##        &"dinamica"  = 2.5D: el juego sigue en el plano X/Y, pero la cámara mira hacia adelante, sigue a Bee y cambia de
##                       ángulo por zona y con los jefes (estilo shooter arcade con cámara dinámica).
## Para volver a la lateral: DEFAULT_MODE = &"lateral".
## Solo cambia lo que se DIBUJA: los límites de vuelo de Bee no cambian.

const DEFAULT_MODE := &"dinamica"
static var mode: StringName = DEFAULT_MODE

## Nada de esto corre sin ventana (los tests miden la cámara lateral).
const ACTIVE_IN_HEADLESS := false

## Ángulos por zona: [X del nivel, giro (grados, + = mira adelante), inclinación extra (grados), altura del centro de la vista
## (m sobre el centro normal), apertura (multiplicador del FOV), retroceso del centro (m hacia atrás: conserva el borde izquierdo)].
## Cada fila está elegida para que toda la zona de vuelo quede dentro de la pantalla (lo verifica validate_bee_camera_rig).
const KEYFRAMES := [
	[0.0, 14.0, 0.0, 0.4, 1.02, 0.6],    # Césped: entrada tranquila.
	[64.0, 16.0, 0.0, 0.4, 1.06, 0.8],   # Macizo: un poco más de giro.
	[130.0, 20.0, 0.0, 0.4, 1.12, 1.5],  # Nube: se abre antes de la primera zona de combate.
	[185.0, 12.0, 0.0, 0.4, 1.0, 0.6],   # Huerta: más frontal, se leen los surcos.
	[250.0, 12.0, 0.0, 0.4, 1.0, 0.6],
	[262.0, 22.0, 0.0, 0.4, 1.16, 2.1],  # Sombra: la más dramática, antes del robot.
	[284.0, 22.0, 0.0, 0.4, 1.16, 2.1],
	[294.0, 8.0, 0.0, 0.5, 1.04, 0.3],  # Robot: más frontal para leer su ataque.
	[325.0, 8.0, 0.0, 0.5, 1.04, 0.3],
	[338.0, 12.0, 0.0, 0.4, 1.04, 0.6],  # Tarántula.
]

const BEE_FOLLOW_Y := 0.09 ## Cuánto sigue la vista a la altura de Bee (0 = nada). Da paralaje sin mover los límites.
const BEE_FOLLOW_MAX := 0.25 ## Tope en metros de ese seguimiento.
const BEE_YAW_FROM_X := 0.45 ## Grados de giro extra según Bee esté a la derecha o izquierda de la pantalla.
const ROLL_FROM_VY := 0.3 ## Grados de alabeo por m/s de subida/bajada de Bee.
const ROLL_MAX := 1.4 ## Tope del alabeo (grados).
const BREATH_YAW := 0.25 ## Respiración lenta de la cámara (grados).
const BREATH_Y := 0.03 ## Respiración vertical (m).
const BREATH_SPEED := 0.35 ## Velocidad de la respiración.
const SMOOTH_SECONDS := 0.35 ## Suavizado del seguimiento.
const BOSS_ENTRY_YAW := 3.0 ## Grados extra de giro mientras entra un jefe (se abre el plano).
const BOSS_ENTRY_SECONDS := 2.2 ## Cuánto dura ese giro extra.
const BOSS_ENTRY_FROM_X := 294.0 ## Antes de acá no entra ningún jefe.
const VIEW_MARGIN := 0.98 ## Toda la zona de vuelo tiene que quedar dentro de esta fracción de la pantalla (lo mide el test).

## Prototipo "desde atrás": solo lo usa dev/mejora_visual/camera_compare.gd para sacar la foto comparativa (no es un modo de juego).
const BACK_DISTANCE := 5.2
const BACK_HEIGHT := 1.7
const BACK_SIDE := 1.6
const BACK_FOV := 62.0
