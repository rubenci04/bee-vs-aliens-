extends RefCounted
## Tanda V · parte 1 — golpes con peso. Reusa el congelado local (bee_local_hit_stop.gd), la sacudida (BeeCameraShake)
## y el juice que ya existían. IMPACT_ENABLED = false vuelve a como estaba. Respeta la opción "temblor de pantalla".

static var IMPACT_ENABLED := true

## A. Liberar: congelado local (Bee, el liberado y las balas cercanas) y un estallido dorado chico.
const FREE_SMALL_STOP := 0.04 # s, enemigos comunes.
const FREE_BIG_STOP := 0.07 # s, grandes (escarabajo, araña).
const FREE_BIG_SHAKE := 0.08
const FREE_BIG_KINDS := ["beetle", "spider"] # Se reconocen por el nombre del nodo o del script.
const FREE_BURST_SCALE := 0.6 # Tamaño del estallido dorado.

## B. Puñetazo / aguijón que conectan: congelado y un zoom corto de la cámara.
const MELEE_STOP := 0.06
const MELEE_ZOOM := 0.03 # 3 % más cerca.
const MELEE_ZOOM_SECONDS := 0.15

## C. Bomba: destello blanco-dorado de pantalla, sacudida y onda que muestra el radio real.
const BOMB_FLASH_SECONDS := 0.12
const BOMB_FLASH_COLOR := Color(1.0, 0.93, 0.7, 0.55)
const BOMB_SHAKE := 0.26 # Mejora visual: antes 0.08, casi no se sentía.
const BOMB_FX_SIZE := 1.5 # Tamaño de la explosión de la bomba.
const BOMB_WAVE_SECONDS := 0.35
const BOMB_WAVE_COLOR := Color(1.0, 0.86, 0.4, 0.8)
const BOMB_WAVE_THICKNESS := 0.12
## Cada zona de combate empieza con al menos estas bombas, y el HUD las ilumina un momento.
const BOMBS_AT_ZONE_START := 2
const BOMB_HUD_HIGHLIGHT_SECONDS := 1.0

## D. Sacudidas: nunca dos grandes (>= BIG_SHAKE) en menos de SHAKE_GAP_SECONDS.
const BIG_SHAKE := 0.04
const SHAKE_GAP_SECONDS := 0.25
