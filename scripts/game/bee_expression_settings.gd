extends RefCounted
## Tanda U — "Bee siente": caras, reacción al golpe, vida baja, festejo y frases. Todo con interruptor.
## Las caras mueven piezas que el modelo v02 ya trae sueltas (Brow, Eye, EyeGlint, Mandible, AntennaTip): sin Blender.
## Medidas en metros del modelo (la cabeza mide ~0,4 m); ángulos en grados.

static var EXPRESSIONS_ENABLED := true
const TRANSITION_SECONDS := 0.08 # Pasaje de una cara a otra.

## Duraciones de las caras que vienen de un hecho.
const SURPRISE_SECONDS := 0.5 # Al recibir un golpe.
const HAPPY_SECONDS := 0.8 # Al liberar o despejar una zona.
const FOCUS_HOLD_SECONDS := 0.6 # Concentrada mientras dispara y un ratito después.
const LOW_HP_RATIO := 0.3 # Con menos de esto, cara cansada e implante que chisporrotea.

## Cada cara: cejas (subida y giro), ojos (escala y aplastado vertical), mandíbulas (apertura) y antenas (caída).
##   brow_y   m que suben (+) o bajan (-) las cejas     brow_tilt  giro de la ceja (+ = ceño fruncido)
##   eye      escala del ojo                            squint     alto del ojo (1 = normal, 0,5 = entrecerrado)
##   mouth    m que baja la boca (boca abierta)          smile      grados que gira cada mitad de la boca (180 = sonrisa)
##   droop    m que caen las puntas de las antenas
const FACES := {
	&"neutral": {"brow_y": 0.0, "brow_tilt": 0.0, "eye": 1.0, "squint": 1.0, "mouth": 0.0, "smile": 0.0, "droop": 0.0},
	&"focused": {"brow_y": -0.018, "brow_tilt": 12.0, "eye": 0.95, "squint": 0.8, "mouth": 0.0, "smile": 0.0, "droop": 0.0},
	&"surprised": {"brow_y": 0.035, "brow_tilt": -18.0, "eye": 1.35, "squint": 1.1, "mouth": 0.018, "smile": 0.0, "droop": 0.0},
	&"happy": {"brow_y": 0.02, "brow_tilt": -10.0, "eye": 1.05, "squint": 0.45, "mouth": 0.0, "smile": 180.0, "droop": 0.0},
	&"tired": {"brow_y": -0.012, "brow_tilt": -14.0, "eye": 0.95, "squint": 0.55, "mouth": 0.0, "smile": 0.0, "droop": 0.05},
}
## De mayor a menor: la primera cara activa gana.
const PRIORITY := [&"surprised", &"happy", &"tired", &"focused", &"neutral"]

## Golpe recibido (solo Nivel 1). La vida y el daño de cada golpe no cambian.
static var HIT_REACTION_ENABLED := true
const HIT_INVULN_SECONDS := 0.35 # Después de cualquier golpe, nada más daña a Bee este tiempo.
const KNOCKBACK_DISTANCE := 0.25 # m, alejándose de lo que le pegó.
const KNOCKBACK_SECONDS := 0.1
const HIT_SPARK_SCALE := 0.5 # Chispa cian del implante.

## Vida baja: el implante chisporrotea (sin alarma sonora).
const LOW_HP_SPARK_EVERY := 1.2
const LOW_HP_SPARK_SCALE := 0.35

## Festejo al aparecer ZONA DESPEJADA: una vuelta corta del dibujo (sin invulnerabilidad extra).
const CELEBRATE_SECONDS := 0.45

## Globitos de frases.
static var BARKS_ENABLED := true # También se cambia desde la pausa.
const BARKS_FILE := "res://assets/ui/bee_barks.json"
const BARK_MIN_GAP_SECONDS := 20.0 # Nunca dos frases más seguido que esto.
const BARK_SECONDS := 1.6 # Cuánto queda en pantalla.
const BARK_HEIGHT := 1.15 # m sobre Bee.
const BARK_FONT := 40
const BARK_COLOR := Color(1.0, 0.98, 0.9)
const BARK_OUTLINE := Color(0.12, 0.07, 0.03)
