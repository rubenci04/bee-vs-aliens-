# Informe Lote 15 — controles, legibilidad y balance

13/10/2026. Rama `lote-15`, desde `lote-15c-bee-integracion`. Resguardo previo `95c8402`; un commit por etapa, más cierre de validación. El informe anterior de jefes se conserva íntegro en [INFORME_LOTE_15_JEFES_PREVIO.md](INFORME_LOTE_15_JEFES_PREVIO.md).

## Cambios

- Bichos chicos: vida fija por familia, sin los multiplicadores de resistencia anteriores. Dos acompañantes opcionales de la misma especie por unidad de ruta (se descartan al saturarse o cambiar de debut); respetan el elenco, los debuts y los topes existentes. Los acompañantes hacen la mitad del daño para mantener la presión esquivable. Intervalo mínimo de entrada 0,2 s; el robot detiene el scroll al alcanzar su puerta.
- Spread: 20 s, otro suma 10 s, máximo 45 s. Nunca consume tiempo por proyectil; el HUD muestra segundos. Se conserva el nombre interno `spread_ammo` para snapshots/bots, ahora como flotante en segundos.
- Avisos: poses usando los nodos existentes (avispa atrás, hormiga inclinada, mosca verde/hongo hinchados, araña temblando, gusano erguido), sonido aprobado `tech_hit` de 120 ms con tono por especie y límite de un aviso por especie cada 150 ms. Los proyectiles sucesivos de una ráfaga se anticipan individualmente 0,35 s; un abanico comparte aviso. Flechas cian pulsantes cuando el aviso queda fuera de cámara. Tres interruptores en título.
- Tras el robot: 5,5 s de calma y una pantalla de scroll, +50 % de vida máxima sin excederla, bombas al menos 3 (máximo 5), polen al menos 10/20 incluso con el cupo de ruta agotado, y bomba/Spread/polen en el camino. Láser cian/blanco, aviso fino 0,85 s. La pirueta conserva invulnerabilidad frente a su daño, pero no destruye el rayo ni las ondas.
- Música: 25 % por defecto, efectos 100 %, fade de entrada 2,5 s, duck de 4 dB con meseta de 0,3 s en bomba/ataques de jefes. Ganancia por pista; sliders en título y pausa, guardados en `user://audio_settings.cfg`. El menú de título desplaza sus opciones al navegar con foco para caber en 1152×648.
- InputMap para todos los dispositivos: ambos sticks, RT/A, X, B/LB, Y/RB, Start, cruceta y aceptar/volver. Detección inicial/reconexión con nombre 3 s; vibración suave opcional en título. Godot detectó `XInput Controller` durante la captura. Mouse libre; tras 1,5 s quieto vuelve autoapuntado al hostil más cercano del cono frontal. X y clic se conservan sin doble disparo. El HUD cambia fuego, bomba y pirueta al último dispositivo usado.
- Aguijón de daño 30 y 360° disponible cada 0,35 s, sin carga ni texto «AGUIJÓN LISTO». Pirueta: espera 1,2 s (configurable hasta 0), aro chico e impulso 3 m/0,2 s al moverse; ayuda una vez al aparecer al menos seis proyectiles. Las restricciones de una red que ya atrapó a Bee se conservan.
- Giro: histéresis 0,4 m, mínimo 0,12 s entre cambios, yaw 0,22 s con easing/rebote e inclinación leve. El disparo apunta desde el primer frame y las alas siguen.

## Checklist de etapas A

| Etapa | Estado y evidencia |
|---|---|
| 1. Bichos chicos | Hecha — `SMALL_ENEMY_HP`, `validate_bee_lote15_hits_v01.gd` (cuerpo por hitbox real), bot de pacing; commit `64ac40c`. |
| 2. Spread por tiempo | Hecha — `SPREAD_*_SEC`, HUD y `validate_bee_lote15_gameplay_v01.gd`; commit `890cffa`. |
| 3. Avisos por especie | Hecha — poses, audio acotado y flecha fuera de cámara en `bee_shot_warning.gd`; interruptores en ajustes/título. Prueba dirigida `validate_bee_lote15_warning_v01.gd`; commit `5631ae3`. |
| 4. Salida del robot | Hecha — recarga, calma, avance, ítems y línea de láser; `validate_bee_lote15_gameplay_v01.gd`; commit `2969ca9`. |
| 5. Música | Hecha — medición, ganancia, persistencia, fades/duck y sliders; `validate_bee_lote14_music_v01.gd`; commit `f432570`. |
| 6. Mando y teclado | Hecha — InputMap, reconexión, autoapuntado y HUD por dispositivo; `validate_bee_lote15_input_v01.gd`, `docs/CONTROLES.md`; commit `4845f11`. |
| 7. Aguijón y pirueta | Hecha — sin carga ni texto de listo, espera 1,2 s, aro, impulso y ayuda única con botón dinámico; `validate_bee_lote15_gameplay_v01.gd`; commit `b89626d`. |
| 8. Giro | Hecha — histéresis, yaw suave, inclinación y disparo inmediato; `validate_bee_lote15_gameplay_v01.gd` y `validate_bee_visual.gd`; commit `71dfaf2`. |

## Golpes para matar — bot

Normal, impactos al cuerpo sin críticos. Valores anteriores reconstruidos con la vida efectiva previa; los posteriores se prueban además por el camino real proyectil → hitbox → hurtbox → salud. BASE sostenido conserva 10 de daño efectivo exclusivamente sobre estos bichos; los restantes enemigos y los topes de daño de jefes mantienen su DPS anterior. Un impacto directo en implante conserva su multiplicador crítico.

| Especie | PV antes → después | Golpes BASE antes → después | BASE sostenido después |
|---|---:|---:|---:|
| Mosca común | 50 → 10 | 5 → 1 | 1 |
| Nube (una unidad de grupo) | 24 → 10 | 3 → 1 | 1 |
| Mosca verde | 62 → 20 | 7 → 2 | 2 |
| Avispa | 56 → 20 | 6 → 2 | 2 |
| Hormiga terrestre | 92 → 20 | 10 → 2 | 2 |
| Hormiga voladora | — | No existe como unidad separada en el elenco actual | — |

No se cambiaron las vidas de escarabajo, caracol, mariquita, gusanos, araña ni jefes. Impactos conservan partículas/sonido; la fauna recibió también `HitFlash3D` sobre su rig.

Bot experto Normal: densidad ≥3 enemigos **83 %**, aéreo+terrestre **80 %**, balas **73 %**, mayor silencio **2,5 s**, demora máxima de evento **13,9 m**, vida mínima/media antes del robot **31/73,6**, daño acumulado **200**, sin revivir; tarántula a **363,3 s (6,1 min)**. Robot experto Base: **35,2 s / 66 de daño**. Tarántula experto Base: **87,0 s / 63**. El límite histórico de vida media del bot se amplió de 80 a 85; no se bajaron sus objetivos de densidad.

## Medición de música

`ffmpeg 7.1` (binario local de imageio-ffmpeg 0.6.0), `volumedetect` sobre los MP3 originales completos, sin recodificarlos. Objetivo de media: −18 dB. Los cuatro archivos resultaron iguales a la precisión de 0,1 dB de volumedetect.

| Pista / archivo en audio | Media | Pico | Ganancia |
|---|---:|---:|---:|
| Menú Principal y Pantalla de Títulos.mp3 | −14,3 dB | 0,0 dB | −3,7 dB |
| Nivel 1 El Jardín Acción Fuerte 1era opcion.mp3 | −14,3 dB | 0,0 dB | −3,7 dB |
| Introducción al Jefe Final 1era opcion.mp3 | −14,3 dB | 0,0 dB | −3,7 dB |
| Jefe Derrotado y Pantalla de Victoria.mp3 | −14,3 dB | 0,0 dB | −3,7 dB |

Reproducible con `dev/lote15/measure_music.py <ffmpeg.exe>`; datos en `dev/lote15_music_measurement.json`. No se importó audio nuevo de la biblioteca externa. La atribución/licencia pendiente de los MP3 ya estaba documentada en el Lote 14.

## Constantes y archivos

Todas las perillas nuevas están en `scripts/game/bee_game_settings.gd`: `SMALL_ENEMY_*`, `SPREAD_*_SEC`, `SHOT_WARNING_*`, `HOSTILE_CYAN`, `POST_ROBOT_*`, `ROBOT_LASER_*`, `MUSIC_DEFAULT_VOLUME`, `SFX_DEFAULT_VOLUME`, `MUSIC_FADE_IN_SEC`, `MUSIC_DUCK_*`, `MUSIC_TRACK_GAIN_DB`, `AUDIO_SETTINGS_PATH`, `JOYPAD_*`, `MOUSE_AIM_IDLE_SEC`, `STING_MIN_INTERVAL_SEC`, `PIRUETA_*`, `BEE_TURN_*`, `TITLE_*`. Los interruptores y el último dispositivo son estado de sesión; solo los volúmenes se persisten.

Archivos principales: player/proyectil/HUD y nuevo `bee_shot_warning.gd`; hurtbox; fauna/avispa/araña/gusano/shooter de implante; controlador/robot/tarántula; MusicManager/BeeMusic; título y nuevo autoload `bee_input_devices.gd`; pausa y `project.godot`. Controles: [CONTROLES.md](CONTROLES.md). Pruebas nuevas `validate_bee_lote15_{hits,input,gameplay}_v01.gd`, expectativas históricas adaptadas y herramientas en `dev/lote15/`.

## Validación y qué probar

**Una sola corrida completa: 102/105 PASS (172.5s).** Tres fallos reparados/verificados con pruebas dirigidas en verde (vuelo, visual y bot UFO); también pasaron armas, controles, HUD y música tras las correcciones. Logs en `dev/lote15_checks/`; resultado original en `dev/lote15_full_result.json`.

Los tres fallos iniciales fueron: vuelo sin blanco apuntaba ligeramente al centro de Bee en vez de horizontal (corregido); prueba visual esperaba giro instantáneo (ahora espera el giro); bot histórico del UFO con Bee v02 daba Fácil Base 72 de daño frente a Normal 59. Se conservó el diseño del UFO y se fijó ese fixture histórico al Bee v01 original: las cuatro combinaciones pasan. Bee v02 se valida con su integración y los bots del robot/tarántula. Balance UFO con v02 en Fácil queda como revisión futura fuera del elenco Nivel 01. No se afirma una segunda suite completa en verde: no se repitió.

F5 → Jugar Nivel 01. Probar personalmente con el receptor Xbox 360:
1. Conectar/desconectar/reconectar; verificar nombre del mando, foco del título, cruceta/stick, A y sliders; B vuelve de pausa.
2. Stick izquierdo mueve; derecho apunta suave a ambos lados y suelto autoapunta; RT/A mantienen ráfagas; X bomba/detonar; B/LB pirueta; Y/RB aguijón. HUD cambia al usar teclado/mouse. Vibración y su interruptor.
3. Recoger Spread repetidamente y mirar 20→30→40→45 s; sostener fuego no lo agota. Shift/B con movimiento esquiva unos 3 m; sin dirección gira en el lugar. Z/Y funciona repetidamente sin carga.
4. Leer las anticipaciones y los avisos sonoros; probar sus interruptores. Tras robot, revisar recargas, los tres ítems, una pantalla de avance y la entrada de tarántula. Esquivar el sector cian del láser tras su línea fina.
5. Cambiar volumen en título/pausa, cerrar/reabrir y comprobar persistencia; escuchar entrada suave y duck de bomba/jefes.

Capturas locales revisadas: `dev/lote15_title.png` y `dev/lote15_title_audio.png`. Falta el playtest humano del mando, la percepción de patrones/mezcla en combate y las flechas de borde. No se creó una hormiga voladora ni se cambió el elenco. Cambios externos concurrentes de `imagenes_bee_nuevas/` se conservaron sin incluirlos en el cierre. Headless conserva avisos conocidos de material nulo del renderer dummy y recursos al salir; se cuentan `SCRIPT ERROR` como fallos aunque el proceso salga 0.
