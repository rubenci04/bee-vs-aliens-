extends RefCounted
## Mejora visual · el mundo del Nivel 1 por zonas. WORLD_ENABLED = false vuelve al jardín anterior.
## Solo presentación: nada de esto tiene colisión ni toca la jugabilidad. Sin ventana (tests y bots) no se construye,
## salvo que un test ponga force_in_headless = true para revisarlo.

const WORLD_ENABLED := true
static var force_in_headless := false

static func world_active() -> bool:
	return WORLD_ENABLED and (force_in_headless or DisplayServer.get_name() != "headless")

## Zonas del jardín: dónde terminan (X) y cómo se tiñen sus hojas (multiplica el color de pasto y tallos).
const EDGE_LAWN := 64.0 # Césped -> macizo de flores.
const EDGE_BED := 185.0 # Macizo -> huerta.
const EDGE_PATCH := 262.0 # Huerta -> sombra bajo las hojas.
const EDGE_SHADE := 294.0 # Sombra -> patio.
const ZONE_NAMES := [&"cesped", &"macizo", &"huerta", &"sombra", &"patio"]
## Cartel corto al entrar a cada zona: se ve que el viaje avanza.
const ZONE_TITLES := ["", "EL MACIZO DE FLORES", "LA HUERTA", "BAJO LAS HOJAS", "EL PATIO"]
const ZONE_TITLE_SECONDS := 2.4
const ZONE_TITLE_TOP := 0.2 # Fracción del alto de pantalla.
const ZONE_TITLE_FONT := 40
const ZONE_TINT := [Color(1.04, 1.12, 0.96), Color(0.98, 1.1, 1.0), Color(1.2, 1.1, 0.78), Color(0.66, 0.96, 0.92), Color(0.92, 0.84, 0.96)]
## El decorado cerca del plano de vuelo: saturación y aclarado, para que los colores fuertes sean de Bee, los enemigos y los ítems.
const DECOR_SATURATION := 0.6
const DECOR_LIFT := 0.1

static func zone_at(x: float) -> int:
	if x < EDGE_LAWN:
		return 0
	if x < EDGE_BED:
		return 1
	if x < EDGE_PATCH:
		return 2
	if x < EDGE_SHADE:
		return 3
	return 4

## Luz y cielo a lo largo del nivel. Entre filas se mezcla con suavidad; dos filas iguales arman una meseta.
## El color de la niebla debe parecerse al horizonte del cielo: así el fondo se funde con él.
const MORNING := {
	"sun_color": Color(1.0, 0.95, 0.82), "sun_energy": 1.3, "sun_rotation": Vector3(-42, -28, 0),
	"ambient_color": Color(0.82, 0.9, 1.0), "ambient_energy": 0.56,
	"fog_color": Color(0.74, 0.87, 0.94), "fog_density": 0.5,
	"sky_top": Color(0.16, 0.48, 0.92), "sky_horizon": Color(0.76, 0.9, 0.98), "cloud_light": Color(1.0, 1.0, 0.98), "cloud_shadow": Color(0.72, 0.84, 0.95),
	"cloud_amount": 0.46, "stars": 0.0, "sun_dir": Vector3(0.45, 0.34, -1.0), "sun_disc": Color(1.0, 0.97, 0.8),
	"glow": 0.5, "contrast": 1.03, "saturation": 1.04, "shaft": 0.08, "vignette": 0.16, "bee_rim": 0.0, "outline_tint": Color(0.3, 0.14, 0.04),
}
const BED := {
	"sun_color": Color(1.0, 0.88, 0.68), "sun_energy": 1.36, "sun_rotation": Vector3(-56, -20, 0),
	"ambient_color": Color(1.0, 0.82, 0.86), "ambient_energy": 0.58,
	"fog_color": Color(0.96, 0.82, 0.78), "fog_density": 0.55,
	"sky_top": Color(0.24, 0.46, 0.88), "sky_horizon": Color(1.0, 0.86, 0.78), "cloud_light": Color(1.0, 0.97, 0.92), "cloud_shadow": Color(0.94, 0.74, 0.8),
	"cloud_amount": 0.6, "stars": 0.0, "sun_dir": Vector3(0.3, 0.6, -1.0), "sun_disc": Color(1.0, 0.95, 0.72),
	"glow": 0.55, "contrast": 1.03, "saturation": 1.04, "shaft": 0.10, "vignette": 0.18, "bee_rim": 0.0, "outline_tint": Color(0.34, 0.14, 0.1),
}
const PATCH := {
	"sun_color": Color(1.0, 0.74, 0.4), "sun_energy": 1.42, "sun_rotation": Vector3(-33, -42, 0),
	"ambient_color": Color(0.92, 0.72, 0.68), "ambient_energy": 0.54,
	"fog_color": Color(0.98, 0.76, 0.5), "fog_density": 0.62,
	"sky_top": Color(0.3, 0.46, 0.76), "sky_horizon": Color(1.0, 0.78, 0.46), "cloud_light": Color(1.0, 0.9, 0.68), "cloud_shadow": Color(0.92, 0.6, 0.46),
	"cloud_amount": 0.5, "stars": 0.0, "sun_dir": Vector3(0.7, 0.22, -1.0), "sun_disc": Color(1.0, 0.86, 0.5),
	"glow": 0.65, "contrast": 1.03, "saturation": 1.04, "shaft": 0.20, "vignette": 0.22, "bee_rim": 0.3, "outline_tint": Color(0.34, 0.16, 0.03),
}
const SHADE := {
	"sun_color": Color(0.9, 1.0, 0.8), "sun_energy": 0.95, "sun_rotation": Vector3(-72, -10, 0),
	"ambient_color": Color(0.56, 0.8, 0.8), "ambient_energy": 0.98,
	"fog_color": Color(0.32, 0.54, 0.46), "fog_density": 0.82,
	"sky_top": Color(0.08, 0.24, 0.28), "sky_horizon": Color(0.36, 0.58, 0.48), "cloud_light": Color(0.56, 0.76, 0.6), "cloud_shadow": Color(0.26, 0.46, 0.42),
	"cloud_amount": 0.22, "stars": 0.0, "sun_dir": Vector3(0.1, 0.9, -0.6), "sun_disc": Color(0.9, 1.0, 0.76),
	"glow": 0.8, "contrast": 1.03, "saturation": 1.04, "shaft": 0.62, "vignette": 0.32, "bee_rim": 0.7, "outline_tint": Color(0.06, 0.16, 0.14),
}
const DUSK := {
	"sun_color": Color(1.0, 0.5, 0.32), "sun_energy": 1.16, "sun_rotation": Vector3(-16, -66, 0),
	"ambient_color": Color(0.64, 0.5, 0.88), "ambient_energy": 0.72,
	"fog_color": Color(0.74, 0.42, 0.56), "fog_density": 0.7,
	"sky_top": Color(0.14, 0.1, 0.42), "sky_horizon": Color(1.0, 0.5, 0.36), "cloud_light": Color(1.0, 0.62, 0.5), "cloud_shadow": Color(0.5, 0.26, 0.5),
	"cloud_amount": 0.58, "stars": 0.5, "sun_dir": Vector3(0.9, 0.08, -1.0), "sun_disc": Color(1.0, 0.72, 0.44),
	"glow": 0.95, "contrast": 1.03, "saturation": 1.04, "shaft": 0.20, "vignette": 0.3, "bee_rim": 1.0, "outline_tint": Color(0.26, 0.1, 0.42),
}
## La tarántula pelea de noche, con luna: la escena más distinta del nivel.
const NIGHT := {
	"sun_color": Color(0.62, 0.7, 1.0), "sun_energy": 0.86, "sun_rotation": Vector3(-46, -30, 0),
	"ambient_color": Color(0.36, 0.36, 0.72), "ambient_energy": 0.92,
	"fog_color": Color(0.16, 0.14, 0.36), "fog_density": 0.78,
	"sky_top": Color(0.03, 0.03, 0.15), "sky_horizon": Color(0.26, 0.17, 0.42), "cloud_light": Color(0.42, 0.4, 0.66), "cloud_shadow": Color(0.14, 0.13, 0.3),
	"cloud_amount": 0.3, "stars": 1.0, "sun_dir": Vector3(0.0, -1.0, 0.0), "sun_disc": Color(0.0, 0.0, 0.0),
	"glow": 1.1, "contrast": 1.03, "saturation": 1.04, "shaft": 0.22, "vignette": 0.46, "bee_rim": 1.0, "outline_tint": Color(0.05, 0.04, 0.16),
}
const LIGHT_TABLE := [[0.0, MORNING], [50.0, MORNING], [92.0, BED], [170.0, BED], [205.0, PATCH], [250.0, PATCH], [268.0, SHADE], [288.0, SHADE],
		[304.0, DUSK], [326.0, DUSK], [340.0, NIGHT], [400.0, NIGHT]]

const SHADOW_DISTANCE := 34.0 ## m: hasta dónde hay sombras nítidas (la cámara está a 11 m del plano de vuelo).
const SHADOW_CAST_MIN_Z := -9.0 ## Lo que esté más atrás no proyecta sombra.
const FOG_BEGIN := 12.5 ## Mejora de claridad: m. La niebla arranca apenas detrás del plano de vuelo (la cámara está a 11 m): el fondo se aparta de la acción.
const FOG_END := 90.0 ## m: acá el fondo es del color de la niebla.
const FOG_CURVE := 0.72

static func light_at(x: float) -> Dictionary:
	var table: Array = LIGHT_TABLE
	if x <= float(table[0][0]):
		return table[0][1]
	for i in range(1, table.size()):
		if x <= float(table[i][0]):
			var from: Dictionary = table[i - 1][1]
			var to: Dictionary = table[i][1]
			if from == to:
				return from
			var t := smoothstep(float(table[i - 1][0]), float(table[i][0]), x)
			var out := {}
			for key: String in from:
				var a: Variant = from[key]
				out[key] = a.lerp(to[key], t) if (a is Color or a is Vector3) else lerpf(a, to[key], t)
			return out
	return table[table.size() - 1][1]

## Pasto bajo por zona: [matas por m², alto mínimo, alto máximo, color A, color B].
const TUFT_DENSITY := [
	[1.5, 0.34, 0.72, Color(0.42, 0.6, 0.26), Color(0.58, 0.72, 0.32)],
	[0.55, 0.3, 0.62, Color(0.3, 0.5, 0.26), Color(0.42, 0.58, 0.3)],
	[0.22, 0.22, 0.46, Color(0.56, 0.58, 0.26), Color(0.46, 0.54, 0.24)],
	[0.7, 0.24, 0.54, Color(0.22, 0.46, 0.36), Color(0.3, 0.54, 0.36)],
	[0.1, 0.2, 0.4, Color(0.34, 0.42, 0.3), Color(0.42, 0.46, 0.34)],
]
const TUFT_CHUNK := 32.0 ## m por grupo de pasto (se recorta por tramo, cuesta 1 draw call por grupo).
const TUFT_Z := Vector2(-20.0, 5.5) ## Banda de profundidad con pasto.
const TUFT_LOW_FROM_Z := 2.5 ## Más cerca de la cámara que esto, el pasto es bajo y no tapa el juego.
const TUFT_LOW_SCALE := 0.55
const LIFE_CHUNK := 40.0 ## m por tramo de decorado horneado.

## Polvo y partículas de ambiente por zona: cuántas (fracción del máximo) y de qué color.
const AIR_AMOUNT := 16
const AIR_CALM_RATIO := 1.0
const AIR_COMBAT_RATIO := 0.15
const AIR_ZONE := [[0.7, Color(1.0, 1.0, 0.94)], [1.0, Color(1.0, 0.93, 0.86)], [0.7, Color(0.92, 0.62, 0.22)], [0.9, Color(0.82, 0.96, 0.84)], [0.5, Color(1.0, 0.76, 0.6)]]

const SHAFT_COUNT := 5 ## Rayos de luz sobre el fondo.
const SHAFT_COMBAT_SCALE := 0.4 ## En combate los rayos bajan: la acción primero.
const COMBAT_FOG_EXTRA := 0.12 ## Más niebla en combate: el fondo se aparta todavía más.
const OVERLAY_LAYER := -2 ## Viñeta: por encima del 3D y por debajo del HUD.
