# Auditoría de contexto (T0)

Solo lectura: no se ejecutó el juego ni los tests; todo sale de leer código y escenas (rama `lote-16-titulo-intro`). Clasificación: **A** bug confirmado · **B** problema observado · **C** mejora de diseño · **D** validar a mano en Godot. "Calculado" = cuenta con las constantes, no medida.

## 1. Mapa de sistemas

| Sistema | Dónde |
|---|---|
| Nivel / director | `scenes/levels/bee_level_01_vertical_slice.tscn`, `scripts/levels/bee_level_01_vertical_slice.gd` (base `bee_prototype/bee_shmup_core_poc.gd`), `bee_level_01_controller.gd` |
| HUD | `scenes/bee_prototype/bee_weapons_hud.tscn` + `scripts/bee_prototype/bee_weapons_hud.gd` (se dibuja en `_draw`); medidas `HUD_*` en `scripts/game/bee_game_settings.gd:138-176`; zona/avisos: `CanvasLayer/Section`, `controller._announce_species` (:769), `bee_liberation.gd:70` ("LIBERADO") |
| Cámara y límites | `bee_level_01_framing.gd` (preset F), `vertical_slice.gd:94-104`, `core_poc.gd:51-54` → `bee.flight_min/max`. Solo sigue el scroll en X |
| Spawns / oleadas | `controller.gd`: `EVENTS_ROSTER` (:373) por `stage.distance`, `_spawn` (:869), arenas (:710); topes 7 / 10 en arena / 6 swarm (:72-80) |
| Daño, curación, invulnerabilidad | `scripts/components/{health_component,hurtbox_3d,hitbox_3d}.gd`, `bee_player.gd` |
| Combo y frenesí | `scripts/levels/bee_level_01_juice.gd` |
| Polen y bombas | `juice.gd:220-265`, `pollen_pickup.gd`, `bee_player.gd:288-315`, `bee_alien_bomb.gd`, `scripts/items/*` |
| Robot | `scenes/levels/walker_miniboss.tscn` + `scripts/levels/walker_miniboss.gd` (barra :568) |
| Tarántula | `scenes/levels/tarantula_boss_01.tscn` + `tarantula_boss_01.gd` (barra :1341), `tarantula_web_net.gd`; se crea en `controller._start_tarantula` (:1251) |
| Input y cursor | autoload `scripts/game/bee_input_devices.gd`; apuntado `bee_player.gd:541-625`; retícula/cursor `scripts/levels/bee_level_01_crosshair.gd` |
| Título / intro / resultados | `scripts/game/bee_title_screen.gd`, `bee_intro_screen.gd` (+ `assets/ui/intro/intro_texts.json`); resultados = `Label`s del nivel (`vertical_slice.gd:115-130`, `_show_clear_banner` :218), no hay escena propia |
| Audio | autoload `scripts/audio/music_manager.gd`, `bee_music.gd`, `bee_audio.gd`, `default_bus_layout.tres`; `docs/AUDIO_MAP.md` |

## 2. Dudas

**H-02 · A.** El texto cian es un `Label` estático `State` con `text = "BASE · BOMB x1 · C BOMB"` en `bee_weapons_hud.tscn:7-17`, en (18,56), dentro del panel (20,48). Ningún script lo actualiza ni oculta (`_sync_text_debug`, `bee_weapons_hud.gd:57`, no lo toca); es resto de una versión vieja. El "BASE"/"SPREAD n s" es legítimo (`:153-154`, x=442 del panel) y "AGUIJÓN Y/RB" se dibuja desde x=402 (`:152,200`, ~100 px de ancho): solape calculado.

**H-03 · A.** Solo `bee_level_01_crosshair.gd:98-107` toca `mouse_mode`: lo oculta mientras `is_free_aiming()` y lo vuelve visible al dejar de apuntar. Con mando, `bee_player.gd:582-592` llama `clear_aim()` al soltar el stick, así que el cursor reaparece y queda quieto. No hay ocultado global en gameplay.

**H-08 · D (hipótesis).** Hecho: la intro termina en negro y hace `change_scene_to_file` síncrono (`bee_intro_screen.gd:217-224`), sin carga previa ni fundido de entrada en el nivel, que construye mucho en `_ready`; y `project.godot` no define `default_clear_color` (gris por defecto de Godot). Hipótesis sin probar: el gris es ese fondo hasta el primer cuadro con cámara y cielo. Prueba: poner el clear color en magenta.

**H-15 · D (candidatos).** Naranja `(1.0, 0.55, 0.15, 0.8)` = línea fina de apuntado del enemigo a Bee que la sigue y se bloquea antes del disparo (`asset_fauna.gd:23,565-573`; gusanos `worm_behavior.gd:39,228`). Es la más probable en el tramo diurno. Otras naranjas: carril del `speeder_enemy.gd:165`, morteros del robot (`walker_miniboss.gd:354`), hilos de la tarántula. Las líneas de velocidad son blancas y solo salen en pirueta.

**H-17 columna azul · B, causa probable.** Casi seguro el evento de la regadera (`bee_level_01_watering_event.gd`): columnas azules translúcidas de 1,1 m de ancho y alto 8,5 (más que la pantalla), aviso 1 s, activas 0,5 s, **5 de daño**, en X=128 (`controller.gd:408`). A 1,25 m/s (`LEVEL_SCROLL`) cae hacia 2:20-2:30 del vídeo (estimación). Falta confirmarlo jugando (D).

**H-16 · se apunta libremente (C).** Ratón y stick derecho apuntan a cualquier dirección del plano (`bee_player.gd:541-592`); el disparo sale hacia `aim_point` (:599). Tras 1,5 s sin entrada (`MOUSE_AIM_IDLE_SEC`) vuelve al auto-apuntado (cono 80°, 12 m) y sin objetivo dispara recto. La retícula solo existe mientras se apunta (`crosshair.gd:35-36`; con mando, solo mientras se empuja el stick, y a 10 m de Bee): por eso aparece "a ratos y lejos".

**H-20 · A.** `juice.gd:131-134` resta tiempo al combo en cada `_physics_process`, sin mirar enemigos, arena, respiro ni director; a los 3 s (`COMBO_RESET_SECONDS`) se reinicia. Solo lo refrescan `unit_downed` y `enemy_hit`. Además `enemy_hit` se conecta en `_spawn` (`controller.gd:939`): el robot sí, la tarántula no (se crea aparte, :1251), así que golpearla no mantiene el combo (explica H-25 en x0; confirmar jugando).

**H-14 / H-22 · A (mapa), D (curva).** Todo el daño entra por `hurtbox_3d.gd:43-79` → `health_component.gd:22` (balas 3-5, contacto, morteros, láser, agua 5, red). **No hay invulnerabilidad tras un golpe**: solo la pirueta (0,35 s) y el respawn. Feedback actual: sonido, vibración de mando (`bee_player.gd:509-514`) y sacudida de cámara (`juice.gd:326`); no hay destello ni indicador visual sobre Bee. Curación: polen 20 = +10 % (`juice.gd:20-33,247-265`), `pollen_pickup.gd:30`, checkpoints a mínimo 60 % (`bee_checkpoint_qol.gd:224-229`), **+50 % de vida tras el robot** (`controller.gd:1230`, `POST_ROBOT_HEAL_FRACTION`), lo que explica empezar la tarántula recuperado. La caída 80→35 (3:18-3:24) no se puede atribuir desde el código: falta un log de daño por fuente.

**H-24 · D (mecanismo plausible).** El robot hereda `HitFlash3D` (`ground_walker_enemy.tscn:58`), configurado con blanco `(1,1,1,0.9)` durante 0,06 s (`vfx/bee_juice.gd:6-7`). `flash()` pone un overlay sin sombrear en todas las mallas y se reinicia en cada golpe (`hit_flash_3d.gd:27-48,79`): con ráfagas, Spread o Frenesí puede dejarlo blanco casi continuo. No se midió la cadencia de impactos ni se descartó un material faltante.

**H-23 · D (sin perfilar; no se atribuye causa).** Los topes cuentan unidades, no moscas: `FlyCloud` es **una** unidad con un modelo de nube (`asset_fauna.gd:97`), 3 por evento y oleadas de arena cada ~6 s desde X=138 (`controller.gd:409-421`). Las "~30 moscas" encajan con ese bloque (hipótesis). Costes por unidad a perfilar: `BeeHostileGlow`, `HitFlash3D`, recorridos por frame de `get_nodes_in_group("bee_auto_aim_targets")` (`bee_player.gd:210`, `crosshair.gd:47`), ~37 sistemas de partículas, sombra direccional y hierba de primer plano. Bancos reutilizables: `dev/level01_challenge_review/bench_density.gd`, `dev/level_01_review/sample_density02_performance.gd`.

## 3. Otros hallazgos verificados

- **H-01 · B.** Panel 560×200 en (20,48) sobre 1152×648 (sin `stretch`): ~49 % del ancho, ~31 % del alto. Leyenda de controles fija (`bee_weapons_hud.gd:157`).
- **H-05 · A (geometría).** Barras de jefe en `CanvasLayer` 5, `offset_top` 14; la frase de fase de la tarántula (14 pt, `tarantula_boss_01.gd:~1376`) cae sobre el panel y roza el "86/100" (x≈362). Calculado.
- **H-07.** "Laguna (prototipo - debug)" sale solo con `OS.has_feature("editor")` o `--debug-art` (`bee_title_screen.gd:19-20,150`). No hay contador de FPS en el proyecto: es de la captura.
- **H-10 · A.** `"LEVEL 01 COMPLETADO"` en inglés (`vertical_slice.gd:121,126`) y el `WeaponsHUD` no se oculta al ganar.
- **H-17 encuadre · D.** Preset F: plano de vuelo visible de y≈-0,55 a y≈7,67 (calculado); un enemigo de suelo (y≈0) queda ~0,55 m (~7 %) sobre el borde. Medir con captura.
- **H-28 / H-09 · D.** Música por defecto 0,25: bus -8 dB, -6 dB del slider, -3,7 dB de pista y -2 dB en la intro ≈ **-20 dB** (calculado); SFX a 1,0. La intro solo tiene música: baja por diseño actual, además de lo que reste la captura.

## 4. Resumen

| A | B | C | D |
|---|---|---|---|
| H-02, H-03, H-05, H-10, H-14 (sin i-frames ni destello), H-20 | H-01, H-17 (columna) | H-16, H-19, H-21, H-26, H-27 | H-08, H-15, H-17 (encuadre), H-22, H-23, H-24, H-25 (combo), H-28 |
