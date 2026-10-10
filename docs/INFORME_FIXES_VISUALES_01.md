# INFORME FIXES VISUALES 01

Rama `ufo-boss-01` (incluye también el trabajo del jefe NODO ALIEN, ver `docs/INFORME_UFO_BOSS_01.md`). Remoto `origin` = https://github.com/rubenci04/bee-vs-aliens-.git.

**Calibración tiempo → x:** el scroll es 2 m/s, pero se detiene en puertas duras y durante el humano gigante, así que x ≈ segundos×2 solo vale hasta ~x=140; después el video va "atrasado". Identifiqué cada anomalía por lo que hay en esa zona del nivel, no solo por el número.

## a) "Papelito dorado/plateado" flotando (x≈20, x≈124)
- **Qué era:** las **mariposas** de `bee_level_01_living_garden.gd` (en x=30 naranja y x=132 crema = "dorado" y "plateado"). Eran dos rectángulos planos de color liso batiendo: de lado parecían un papel doblado en el aire. No eran los envoltorios del suelo (esos tienen colores vivos y están apoyados).
- **Fix:** mariposa real: cuerpo oscuro, cabeza, dos antenas y dos alas con forma (lóbulo delantero + trasero) con borde oscuro, en V casi vertical para que la cámara lateral las vea de frente; sin sombreado (siempre color pleno). Siguen volando (es una mariposa); ya no se leen como papel.
- Capturas: `fixbefore_x20.png`, `fixbefore_x124.png` (antes; la mariposa queda fuera de cuadro, ver after) / `fixafter_x27.png`, `fixafter_x129.png` (después).

## b) "Catarata de partículas negras" (x≈56, 102, 176)
- **Qué era:** las **nubes de mosquitos** (`GNATS`: x=58, 112, 164) — `CPUParticles3D` con puntitos oscuros. Tenían la **gravedad por defecto (0, -9.8, 0)**: todos los mosquitos caían en columna. No tiene que ver con el humano gigante.
- **Fix:** gravedad 0, amortiguación y vida 1,6 s: ahora es una nube compacta que revolotea alrededor de la flor.
- Capturas: `fixbefore_x56.png` / `fixafter_x56.png` (la nube del "después" se ve como puntos agrupados junto a la flor; en el "antes" el cuadro congelado aún no mostraba la caída, que ocurre al correr el tiempo).

## c) Bicho verde sin forma de derecha a izquierda (x≈168)
- **Qué era:** no es un enemigo: es el **escarabajo "AftermathBeetle"** del momento `human_aftermath` (tras el humano, `bee_level_01_moments.gd`): una mancha verde oscuro a 2,6x que cruza el suelo a la izquierda. Sin colisión ni daño.
- **Fix:** rediseñado como **tortuga alienígena** (`build_alien_turtle`, por código, sin assets): caparazón gris-verdoso en domo con placas oscuras, cabeza más clara, patas cortas, ojo cian y antena con punta cian; estilo toon + contorno; patas con paso alternado y balanceo del cuerpo; sigue siendo inofensiva (el test existente sigue exigiendo cero `Area3D`).
- Capturas: `fixbefore_beetle_x150.png` / `fixafter_turtle_x150.png`.

## d) Walker flotando
- **Qué era:** el modelo estaba montado con `ModelPivot` a y=1,07 (x escala 1,4 = 1,5 m) → los pies quedaban **~1,2-1,5 m sobre el suelo** (medido con una regla de 1 m al lado en `ruler_walker_x120.png`) y el robot se veía de ~1,3 m.
- **Fix:** `ModelPivot` y=0 (pies sobre el piso, y=-0,2 del nodo) y `VisualRoot` escala 1,4 → **2,8**, que devuelve el tamaño de ~3 m para el que estaban hechos la hitbox (cápsula 3,1) y el cañón. Muzzle 3,0→2,8 m y adelante 1,05→1,5 (el cañón del modelo apoyado), `AimCharge` acorde. Hurtbox y colisión no cambiaron y ahora quedan dentro del robot visible. La animación "Walk" ya existía y se reproduce al caminar.
- Capturas: `fixbefore_walker_x120.png`, `ruler_walker_x120.png` / `fixafter_walker_x120.png`.

## Tarea 3 — Jefe demasiado fácil
- **F9:** ahora deja a Bee con **arma Base (Spread 0) y 2 bombas**, 100 HP (antes Spread x20; el usuario vio x47 porque recogió la S+ de x=334 en el salto).
- **Valores cambiados** (`ufo_boss_01.gd`): HP **400 → 500**; ciclo de ataque (pausa entre ráfagas) F1 1,45→**1,05**, F2 1,3→**1,1**, F3 1,0→**0,85**; aviso dirigido F1 0,6→0,5; período de oscilación F1 5,4→4,6, F2 4,6→4,4; movimiento lateral F1/F2/F3 0,7/1,1/1,4 → **1,1/1,3/1,5**; velocidad de proyectil dirigido (nuevo `AIMED_SPEED_BY_PHASE`) F1/F2/F3 **6,8/7,2/7,6** (antes 6,2); ráfaga dirigida F3 de 3 → **4** tiros (`AIMED_SHOTS_BY_PHASE`); drones F2 recarga 11→**9 s**, F3 13→**12 s**.
- **Cómo se diferencian las fases:** F1 = solo ráfagas dirigidas más rápidas; F2 = abanicos de 5 + 2 Eye Drone que se renuevan; F3 = rayo tractor con marca + ráfagas de 4 + una Probe.
- **Justicia:** se mantienen telegraphs ≥0,45 s, huecos de abanico >0,8 m, daño 8/12/15, el rayo es esquivable (columna fija 1 s antes). Picos de proyectiles medidos: 13 (límite del test 15).
- Con solo Base (33 dps) 500 HP ≈ 15 s de fuego continuo, ~25 s jugando. **No hubo playtest humano**: los números salen de los tests; ajustar con las constantes de la tabla del informe del jefe.

## Otros ajustes de tests
- `validate_bee_level01_challenge_balance_v01`: offsets del test de pellets laterales escalados al jefe 2x más grande.
- Pickup de bomba del jefe ahora es hijo del nivel (no de `Powerups`), para no romper los tests que cuentan/recogen los powerups fijos.
- HP del jefe 500 actualizado en 9 suites.

## Archivos de captura / herramientas dev
`dev/visual_target/`: `capture_fixes.gd` (frames del nivel), `capture_walker.gd`, `capture_turtle.gd`, `capture_beetle_before.gd`, `capture_lineup.gd`, `probe_walker.gd` (mide huesos del Walker).

**Resultado de la suite final:** 41/41 PASS (headless, `SCRIPT ERROR` contado como fallo).
