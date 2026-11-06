extends RefCounted
const FADE_SECONDS := 0.22
const INTRO_READ_HOLD := 2.0
const TAGLINE_TOP := 0.235 # Mejora visual: pegada al logo, que ahora se ve grande.
const MENU_TOP := 0.40
const TITLE_LOGO_HEIGHT := 134.0
const RANKS := [
 {"rank":"S","released":.85,"score":100000},
 {"rank":"A","released":.65,"score":60000},
 {"rank":"B","released":.40,"score":25000},
 {"rank":"C","released":.0,"score":0}
]
static func rank_for(released: int, total: int, score: int) -> String:
 var fraction := float(released)/maxi(total,1)
 for row in RANKS:
  if fraction>=row.released and score>=row.score: return row.rank
 return "C"
## Tanda X: pantalla de resultados.
const RESULTS_STAT_GAP := 0.35 # s entre una estadística y la siguiente.
const RESULTS_BEE_SIZE := Vector2(260, 190) # Ventanita con Bee girando.
const RESULTS_BEE_SPIN := 1.2 # rad/s.
## Tanda X: Bee volando en el título (un ocho lento abajo, sin tapar la abeja pintada del fondo).
const TITLE_BEE_SCALE := 0.8
const TITLE_BEE_AMBIENT := 0.85 # Luz ambiente de la Bee del título.
const TITLE_BEE_CENTER := Vector3(-0.15, -1.05, 0.0) # Abajo, entre el menú y las hormigas pintadas (la cámara mira desde z = 6).
const TITLE_BEE_RANGE := Vector2(0.9, 0.25)
const TITLE_BEE_SPEED := 0.6 # Vueltas por segundo del ocho (en radianes / s).
