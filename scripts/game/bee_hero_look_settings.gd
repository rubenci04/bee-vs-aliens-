extends RefCounted
## Tanda S — "se ve a Bee": que en cualquier fotograma del Nivel 1 el ojo encuentre a Bee primero.
## Todo lo visual de la tanda sale de acá. HERO_LOOK_ENABLED = false vuelve al look de la Tanda R (vida, daño, hitbox y
## velocidades nunca cambian: solo escala visual, materiales, avisos y el margen de vuelo).

static var HERO_LOOK_ENABLED := true

## A. Tamaño: Bee se dibuja 20 % más grande que antes (mariquita 1.15, hormiga 1.1). La hurtbox NO cambia.
const BEE_VISUAL_SCALE := 1.2

## B. Firma de Bee: contorno marrón-negro más grueso (fracción del alto de pantalla: 0.0044 ≈ 3 px a 720p) y brillo de borde
## blanco-cálido siempre encendido. Las rayas siguen amarillas.
const OUTLINE_WIDTH := 0.0044
const RIM_MIN := 0.95 # Piso del brillo de borde (antes 0.75).
const RIM_COLOR := Color(1.0, 0.96, 0.86) # Blanco cálido.
## Los props amarillos grandes (regadera, latas) pierden saturación para no competir con Bee; el sol también, y su halo baja.
const YELLOW_PROP_SATURATION := 0.5 # 1 = color original.
const SUN_SATURATION := 0.35
const SUN_HALO_SCALE := 0.45

## C. Sombra suave en el suelo debajo de Bee, siempre visible (más chica y fuerte cerca del suelo).
const SHADOW_RADIUS := 0.55 # m, con Bee al ras del suelo.
const SHADOW_RADIUS_HIGH := 0.9 # m, con Bee en lo más alto.
const SHADOW_ALPHA_LOW := 0.62
const SHADOW_ALPHA_HIGH := 0.34 # Nunca desaparece.
const SHADOW_HIGH_Y := 7.0
const SHADOW_LIFT := 0.03 # Apenas sobre el suelo, para no parpadear con él.

## D. Balas de Bee: aguja dorada fina y alargada, con 60 % del brillo de antes. Daño, velocidad y hitbox iguales.
const SHOT_THICKNESS := 0.5 # Grosor del plasma respecto del de antes.
const SHOT_LENGTH := 2.6 # Estiramiento a lo largo del vuelo (antes 1.65).
const SHOT_GLOW := 0.6 # Brillo del halo y de la emisión respecto de antes.
const SHOT_REVEAL_DISTANCE := 0.45 # m: la bala se dibuja recién cuando ya salió de la silueta de Bee.

## E. Teletransporte: columna de 1/3 de alto, más fina y menos opaca; la nube de píxeles cian, menos densa.
const BEAM_HEIGHT_FRACTION := 1.0 / 3.0
const BEAM_RADIUS_SCALE := 0.5
const BEAM_ALPHA_SCALE := 0.5
const TELEPORT_PIXEL_DENSITY := 0.55 # Fracción de píxeles que llegan a dibujarse durante la materialización.

## F. Pasillo limpio: decorado que tapa a Bee o a un enemigo queda 40 % transparente mientras haya algo detrás.
const CORRIDOR_ALPHA := 0.6
const CORRIDOR_FADE_SECONDS := 0.15
const CORRIDOR_CHECK_SECONDS := 0.1
const CORRIDOR_PAD_PX := 28.0 # Margen alrededor del centro de cada actor en pantalla.
const CORRIDOR_OWNERS := ["DomesticGarden01", "VisualTarget01", "GardenMushrooms", "AssetDressing"] # Hijos del nivel que se revisan.
const CORRIDOR_MIN_Z := -1.0 # Solo lo que está en el plano de vuelo o delante.

## G. Carteles: un solo "LIBERADO" flotante a la vez; el banner de liberados solo en hitos; el resto es un contador del HUD.
const MAX_LIBERATION_SIGNS := 1
const LIBERATION_MILESTONES := [10, 25, 50, 100, 150, 200, 250, 300, 350]
const MILESTONE_TEXT := "¡%d LIBERADOS!"
const RING_THICKNESS_SCALE := 0.55 # Anillos amarillos de aviso, más finos.

## H. Bordes: el centro de Bee nunca a menos de este 6 % del ancho de la pantalla (antes 2,5 %).
const BEE_SCREEN_MARGIN := 0.06


static func bee_visual_scale() -> float:
	return BEE_VISUAL_SCALE if HERO_LOOK_ENABLED else BeeGameSettings.BEE_VISUAL_SCALE


## Fracción del ancho visible que puede recorrer el centro de Bee.
static func playable_width_fraction() -> float:
	return 1.0 - 2.0 * BEE_SCREEN_MARGIN if HERO_LOOK_ENABLED else BeeLevel01Framing.PLAYABLE_WIDTH_FRACTION


## Le baja la saturación a los colores amarillo-naranja saturados de un modelo (copias propias de material: nada compartido).
static func tone_down_yellow(model: Node, saturation := YELLOW_PROP_SATURATION) -> void:
	if not HERO_LOOK_ENABLED or model == null:
		return
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface)
			if material is ShaderMaterial:
				var albedo: Variant = (material as ShaderMaterial).get_shader_parameter("albedo")
				var textured: bool = (material as ShaderMaterial).get_shader_parameter("use_texture") == true # El color vive en la textura: se baja igual.
				if textured or (albedo is Color and _is_loud_yellow(albedo)):
					var own := material.duplicate() as ShaderMaterial
					own.set_shader_parameter("dev_saturation", saturation)
					mesh.set_surface_override_material(surface, own)
			elif material is BaseMaterial3D and _is_loud_yellow((material as BaseMaterial3D).albedo_color):
				var own := material.duplicate() as BaseMaterial3D
				var color := own.albedo_color
				own.albedo_color = Color.from_hsv(color.h, color.s * saturation, color.v, color.a)
				mesh.set_surface_override_material(surface, own)


static func _is_loud_yellow(color: Color) -> bool:
	return color.h >= 0.08 and color.h <= 0.19 and color.s >= 0.45 and color.v >= 0.45
