extends RefCounted
## Tanda T — arranque y ritmo jugable (pedido de Rubén tras jugar la Tanda S). Cada arreglo tiene su interruptor;
## ENABLED = false apaga todos. No cambia vida ni daño de nada.

static var ENABLED := true

## 1. Sólidos invisibles: la botella (X=41) y el tronco hueco (X=55) tenían colisión en el plano de vuelo, pero su dibujo
## está 3-4 m más atrás. Bee chocaba contra "nada" abajo y tenía que subir. Se apagan sus colisiones.
const REMOVE_INVISIBLE_SOLIDS := true
const INVISIBLE_SOLIDS := ["BottleObstacle", "LogObstacle"]

## 2. Bombas: la barra arranca llena (antes 1 de 5).
const START_BOMBS_FULL := true

## 3. Potenciadores, ubicados según lo que viene (X en metros del nivel):
##    - triple (Spread) apenas arranca, para las moscas de los primeros 20 s (antes en X=22, cuando ya habían pasado);
##    - triple antes de las moscas verdes de X=100 (nuevo) y antes de la serie de X=198 (antes en X=200, en el medio);
##    - la primera bomba en X=88, antes del macizo (antes en X=166);
##    - antes de la tarántula una sola recarga de bombas: se saca la de PreBossSupply (X=285,5) y queda BombRecharge (X=306).
const PICKUP_X := {"SpreadFirst": 8.0, "BombFirst": 88.0, "SpreadRecharge": 192.0}
const EXTRA_SPREADS := {"SpreadBeforeGreenFlies": 94.0}
const EXTRA_PICKUP_Y := 3.8
const REMOVE_DUPLICATE_PREBOSS_BOMB := true

## 4. Polen: además de la campanilla naranja, margaritas violetas y rojas hechas en código (mismo dibujo que las margaritas
## altas del fondo). Probé las flores de Kenney: escaladas al alto de la campanilla se veían como bloques oscuros.
const POLLEN_FLOWER_CYCLE := [&"bellflower", &"flower_purple", &"flower_red"] # Se reparten en este orden por la ruta.
const FLOWER_STEM_COLOR := Color(0.24, 0.42, 0.16) # Verde de tallo del jardín.
const DAISY_HEIGHT := 3.0 # m del tallo antes de SIZE_SCALE (queda ~2,4 m, casi el alto de la campanilla).
const DAISY_RADIUS := 0.65 # m de la corola.
const DAISY_STEM_RADIUS := 0.07
const DAISY_CORE_COLOR := Color(0.62, 0.36, 0.1) # Centro marrón-naranja, como las del fondo.

## 5. Tarántula en el techo: cuelga de hilos que suben desde sus patas hasta arriba del borde de la pantalla.
const CEILING_SILK_ENABLED := true
const CEILING_SILK_LEG_X := [-2.3, 0.3, 2.6] # Patas de donde sale cada hilo (X del modelo, a escala 1).
const CEILING_SILK_SPREAD := 0.12 # Cuánto se abre cada hilo hacia afuera al subir.
const CEILING_SILK_ABOVE_SCREEN := 0.6 # m por encima del borde superior visible.
const CEILING_SILK_WIDTH := 0.035
const CEILING_SILK_COLOR := Color(0.95, 0.95, 0.9, 0.7)
const CEILING_SILK_FADE_SECONDS := 0.35

## 6. Música sincronizada: tema de "acción fuerte" en cada zona de combate; vuelve al tema del nivel al despejarla y
## después de vencer al robot (antes seguía la música del minijefe hasta la tarántula).
const MUSIC_SYNC := true
