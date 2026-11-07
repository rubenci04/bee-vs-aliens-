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
	[0.0, 8.0, 0.0, 0.0, 1.12, 0.3],     # Césped: entrada tranquila.
	[64.0, 10.0, 0.0, 0.0, 1.16, 0.4],   # Macizo: un poco más de giro.
	[130.0, 12.0, 0.0, 0.1, 1.2, 0.4],   # Nube: se abre antes de la primera zona de combate.
	[185.0, 7.0, 0.0, 0.0, 1.12, 0.3],   # Huerta: más frontal, se leen los surcos.
	[250.0, 7.0, 0.0, 0.0, 1.12, 0.3],
	[262.0, 13.0, 0.0, 0.1, 1.22, 0.4],  # Sombra: la más dramática, antes del robot.
	[284.0, 13.0, 0.0, 0.1, 1.22, 0.4],
	[294.0, 6.0, 0.0, 0.2, 1.12, 0.2],   # Robot: más frontal para leer su ataque.
	[325.0, 6.0, 0.0, 0.2, 1.12, 0.2],
	[338.0, 9.0, 0.0, 0.0, 1.16, 0.3],   # Tarántula.
]
## Mejora de claridad: la vista ya no sube ni baja con Bee. Antes, al volar alto se iban de cuadro los de abajo y al revés.
## Todo el rango donde puede haber enemigos entra siempre (lo verifica validate_bee_camera_rig).
const ENEMY_FEET_Y := -0.35 ## Lo más bajo que llega un enemigo de suelo.
const ENEMY_TOP_EXTRA := 0.45 ## Lo que sobresale un enemigo volando en su altura máxima.

const BEE_FOLLOW_Y := 0.0 ## Cuánto sigue la vista a la altura de Bee: 0, para que nunca se pierda lo que está del otro lado.
const BEE_FOLLOW_MAX := 0.0 ## Tope en metros de ese seguimiento.
const BEE_YAW_FROM_X := 0.3 ## Grados de giro extra según Bee esté a la derecha o izquierda de la pantalla.
const ROLL_FROM_VY := 0.12 ## Grados de alabeo por m/s de subida/bajada de Bee.
const ROLL_MAX := 0.5 ## Tope del alabeo (grados).
const BREATH_YAW := 0.15 ## Respiración lenta de la cámara (grados).
const BREATH_Y := 0.015 ## Respiración vertical (m).
const BREATH_SPEED := 0.35 ## Velocidad de la respiración.
const SMOOTH_SECONDS := 0.35 ## Suavizado del seguimiento.
const BOSS_ENTRY_YAW := 2.0 ## Grados extra de giro mientras entra un jefe (se abre el plano).
const BOSS_ENTRY_SECONDS := 2.2 ## Cuánto dura ese giro extra.
const BOSS_ENTRY_FROM_X := 294.0 ## Antes de acá no entra ningún jefe.
const VIEW_MARGIN := 1.0 ## Todo el rango de enemigos y de vuelo tiene que quedar dentro de esta fracción de la pantalla (lo mide el test).

## Prototipo "desde atrás": solo lo usa dev/mejora_visual/camera_compare.gd para sacar la foto comparativa (no es un modo de juego).
const BACK_DISTANCE := 5.2
const BACK_HEIGHT := 1.7
const BACK_SIDE := 1.6
const BACK_FOV := 62.0
