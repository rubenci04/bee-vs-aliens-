# Bee SHMUP Air + Ground Combat POC

POC aislado para observar amenazas aéreas y terrestres simultáneas con Bee. Escena: `res://scenes/bee_prototype/bee_shmup_air_ground_poc.tscn`. Reutiliza Bee, cámara, auto-aim, polen y los cuatro enemigos aprobados; no cambia sus scripts, valores ni assets.

Sector de **95 m** a **2,0 m/s** (47,5 s de scroll teórico). Cada wave comienza al alcanzar su umbral y después de resolver la anterior. Los enemigos aéreos entran desde la derecha; el segundo integrante se escalona. Nunca hay más de **dos amenazas activas/entrando**.

| Wave | Umbral | Amenazas | Entrada escalonada |
| --- | ---: | --- | --- |
| 1 | 6 m | Probe + Turret (X 15 m) | Turret 1,4 s después |
| 2 | 24 m | EyeDrone + Turret (X 33 m) | Turret 1,8 s después |
| 3 | 43 m | Speeder + Turret (X 52 m) | Turret 2,3 s después |
| 4 | 62 m | EyeDrone + Speeder | Speeder 1,7 s después |
| 5 | 80 m | Turret (X 88 m) + Probe | Probe 1,5 s después |

Las torretas se resuelven destruyéndolas o dejándolas atrás del borde izquierdo; el bypass las desactiva y elimina del auto-aim. Los enemigos aéreos se resuelven al derrotarlos. Al resolver los diez integrantes y alcanzar el final aparece `SECTOR DESPEJADO`. La derrota y R recargan escena, HP, scroll, waves, torretas y polen.

Hay **cinco polen opcionales** aproximadamente en X 10/29/48/69/89 m, alternando alturas. Se conservan decoraciones aprobadas; los dos obstáculos heredados y sus representaciones se ocultan/desactivan en este POC, por lo que hay **cero obstáculos con colisión**. El marcador de auto-aim existente se muestra encima del target; no se modificó su algoritmo. Probe, EyeDrone, Speeder y Turret mantienen sus telegraphs y daño originales. Los avisos naranjas de Speeder y Turret se distinguen por su posición aérea/terrestre en las capturas, sin cambio cromático.

Test dedicado: `res://tests/bee_prototype/validate_bee_shmup_air_ground_poc.gd`. Comprueba cinco waves, activación por scroll, máximo dos, auto-aim aire→suelo→aire, muerte, bypass, cierre, polen y restart. Capturas runtime: `res://dev/air_ground_review/wave_1_probe_turret.png`, `wave_2_eye_turret.png`, `wave_3_speeder_turret.png`. Ejecutar la escena desde Godot o con `--path D:\proyectos\bee_alien_3d --scene res://scenes/bee_prototype/bee_shmup_air_ground_poc.tscn`.

Validación final: test dedicado en headless y con render, apertura directa en ambos modos y suite Bee completa **12/12**; código 0, sin errores ni advertencias relevantes.

Limitaciones: no se ha hecho playtest humano de ritmo, dificultad o diversión. La espera de cada wave requiere derrotar su amenaza aérea; las torretas sí admiten bypass. El decorado y las paletas de modelos importados siguen provisionales. No hay scoring, audio ni progresión de campaña.
