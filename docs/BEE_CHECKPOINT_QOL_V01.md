# Bee Checkpoint + Quality of Life V01

Escena: `res://scenes/levels/bee_level_01_vertical_slice.tscn`, Godot 4.7.2.

- Un checkpoint por sesión, **X=190 m**: después del humano de X=140 y del bloque X=184, antes del siguiente evento X=198. Activación por progreso de scroll una sola vez, sin detener el juego.
- Baliza cian primitiva, anillo y rótulo; `CHECKPOINT` durante 1,4 s y cue positivo `spread_pickup` existente. No asset/audio nuevo.
- HP sube solamente hasta un mínimo del 60% (60/100); si ya es mayor, se conserva. Sin full heal.
- Snapshot mínimo: progreso/cámara, spawn seguro `(190, 5.4, 0)`, HP, ammo Spread (Base si cero), cargas Bomb reales, contador de polen, disponibilidad de pickups/polen, cajas anteriores destruidas, tiempo transcurrido y hints ya enseñados.
- R tras derrota recarga limpiamente la escena: antes del checkpoint empieza desde cero; después consume un handoff único en memoria del SceneTree. Sin save file, autoload ni serialización del árbol. Shift+R descarta el checkpoint y reinicia todo, también durante la partida o pausa.
- En respawn se omiten los 13 eventos anteriores; el humano queda EXITED. Los 11 eventos desde X=198 vuelven al estado inicial, sin actores duplicados. Los eventos soft anteriores se consideran consumidos incluso si aún estaban saliendo al activar la baliza.
- Polen/pickups anteriores quedan archivados, incluidos los no recogidos. Los posteriores vuelven al estado guardado al activar: recogerlos después y morir no acumula polen ni Bomb entre intentos. No se regala munición ni carga. Los posteriores que ya se hubiesen recogido al activar no se duplican.
- Cajas anteriores destruidas continúan sin collider; las intactas siguen intactas. Todas las posteriores se reinician. La restauración no emite break/audio/recompensas otra vez.
- La recarga elimina ambos bandos de proyectiles, Bomb, audio y VFX temporales. Auto-aim arranca sin target; luego se reconstruye normalmente. Damage audio/HitFlash y hints de pickups existentes se conservan.
- Protección **1,25 s** con blink del VisualRoot: Health rechaza daño mientras tanto; movimiento/disparo siguen disponibles. El spawn no intersecta colisión del mundo y deja 8 m (~4 s de scroll) antes del siguiente umbral.
- UI de derrota: `PLAYER DOWN — PRESS R TO RESTART` / `PLAYER DOWN — PRESS R TO RESPAWN`. Hint inicial 5 s: X FIRE, Z STING, C BOMB, Esc PAUSE, Shift+R FULL RESTART. Esc pausa SceneTree y muestra `PAUSED`; Esc reanuda. Timers de protección/QoL se congelan durante pausa.

## Probar

Abrir la escena y F6. WASD/flechas volar; X Base/Spread; Z melee; C Bomb. Llegar a X=190, morir y R: regreso a la baliza con inventario guardado. Esc pausa/reanuda; Shift+R vuelve al inicio.

Test específico: `res://tests/levels/validate_bee_checkpoint_qol_v01.gd`, headless y render. Usa progresión real acelerada y bajas controladas como fixture, no valida habilidad humana. Comprueba reinicios reales, snapshot, antiexploit, humano/eventos, colisiones, limpieza, protección, movimiento/disparo, pausa y final. El test Level 01 conserva su recorrido y usa Shift+R para comprobar reset total.

Capturas y logs: `dev/checkpoint_qol_review/`. Ocho PNG revisados: baliza, activación, derrota antes/después, spawn visible, blink, pausa y final. Específico headless/render aprobado; cargas jugables directas headless/render código 0, sin errores. Suite completa **22/22** (baseline 21 + checkpoint), incluyendo Audio V02, Weapons, VFX y recorrido integrado Level 01: 24 eventos, 38 enemigos, máximo tres amenazas, final y reset total conservados. Sin regresiones ni errores/advertencias del motor.

Muestra render local de 180 frames por condición, mismo tramo restaurado quieto: sin procesamiento QoL 100,00 FPS, peor frame 10,625 ms; con QoL 99,99 FPS, peor frame 10,340 ms; 1057 nodos en ambos. Sin diferencia apreciable en esta muestra; no es benchmark de combate completo ni hardware diverso.

## Límites

Un solo checkpoint y posición segura específica de Level 01; nada persiste al cerrar o reiniciar completamente. No restaura enemigos parcialmente dañados: reconstruye la segunda mitad. El contador de polen vuelve al snapshot, no es scoring persistente. La baliza es temporal, sin art pass. Las validaciones automatizadas no sustituyen playtest humano de dificultad, comodidad y percepción audiovisual. No hay Level 02, vidas ni continue.

## Git

Checkpoint/QoL: nuevo `scripts/levels/bee_checkpoint_qol.gd`, test específico, este documento y review; cambios pequeños en `project.godot`, `HealthComponent`, escena/root/controller Level 01, test Level 01 y su documento. UID/imports generados por Godot son auxiliares.

Previous Changes: assets, flora, escenas/scripts Bee, Audio V01/V02, Weapons, VFX, documentos y tests que ya estaban modificados/no trackeados al inicio. Inventario inicial preservado en `dev/checkpoint_qol_review/git_status_before.txt`; no commit, push, reset, clean ni stash.
