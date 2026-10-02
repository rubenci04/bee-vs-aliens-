# Bee Combat Feedback + VFX V01

Visual-only pass para `res://scenes/levels/bee_level_01_vertical_slice.tscn`. Sin modelos/texturas nuevas, cambio de jardín, IA, daño, cadencia, munición, radio, encounters, humano o cámara.

| Acción | Feedback | Duración visual |
| --- | --- | --- |
| Base X | Muzzle cian/blanco en spawn real, pequeño núcleo blanco del proyectil | Flash 0,07 s |
| Proyectil | Trail de 10 partículas pequeñas, coordenadas de mundo | Vida 0,18 s; ~2,5 m a 14 m/s |
| Spread X | Muzzle más ancho, trail de 14 partículas más finas | Misma vida 0,18 s; tres trayectorias conservadas |
| Impacto | Burst corto cian; crema suave en targets orgánicos | 0,24 s |
| Daño | HitFlash3D existente, sin duplicación o ajuste | 0,10 s |
| Melee conectado | Anillo oval blanco/cian y burst en hurtbox | 0,18 s |
| Bomb C | Flash blanco, onda cian y 24 partículas | Flash 0,07 s; onda 0,26 s + fade 0,29 s |
| Muerte tech | 14 fragmentos cian/neutrales + pulse | 0,50 s |
| Muerte orgánica | 12 partículas redondeadas crema/ocre, sin gore | 0,50 s |
| Caja rota | 12 pequeños fragmentos marrones, sin física | 0,45 s |
| Spread pickup | Pulse + 8 partículas cian | 0,30 s |
| Bomb pickup | Pulse mayor + 14 partículas cian | 0,40 s |
| Polen | Sólo 5 motas amarillas; curación intacta | 0,25 s |

Bomb comunica radio **3 m** (radio exterior del Torus), no diámetro 3 m. El daño sigue siendo una consulta instantánea y única de 32 HP; la onda sólo informa, no daña progresivamente. El componente de daño conserva su liberación a 0,4 s; el VFX independiente termina después del fade. No shake/flash global: la cámara actual no ofrece infraestructura de shake y se mantiene su composición estable.

## Integración y cleanup

Una escena reutilizable: `res://scenes/vfx/combat_feedback_vfx.tscn`, script `scripts/vfx/bee_combat_vfx.gd`. Pequeño vocabulario configurable de efectos, con primitivas y CPUParticles3D compatibles con Compatibility. No framework de armas/VFX ni autoload.

El helper coloca los efectos en un contenedor CombatVFX del escenario, fuera del actor/pickup. No alteran counts de polen, powerups, enemigos o cajas, ni se cortan al liberar al emisor. La posición se asigna antes de entrar al árbol; bursts usan coordenadas locales y restart explícito para nacer en el lugar correcto. Cada instancia se libera a duración + 0,08 s. Contenedor vacío reutilizado, sin nodos acumulados. Trails son hijos del proyectil y desaparecen con él; no hay trails huérfanos.

Materiales y mallas de partículas/esferas/ondas se comparten entre instancias; el trail reutiliza una sola malla/material. Cache pequeño y limitado al vocabulario fijo, sin nodos persistentes por efecto. Transparencia y escala animadas pertenecen a cada MeshInstance, sin mutar recursos compartidos. Este cambio respondió a picos medidos al recrear recursos en Spread/bursts, no a un refactor de gameplay.

Componente `scripts/vfx/bee_enemy_feedback.gd` conectado a Health.died: Wasp y Organic Alien orgánicos; Probe, EyeDrone, Speeder, Turret y Walker tech. Emite una vez desde la hurtbox. No modifica muerte/IA; Walker y Organic Alien continúan reproduciendo Death. Enemy damage mantiene HitFlash. Melee escucha hit_confirmed: nada aparece si no conecta. Impacto usa posición real del proyectil al confirmar hit.

Cajas desactivan colisión inmediatamente mediante el comportamiento existente. Bursts no contienen cuerpos/colliders. Pickups emiten sólo tras aceptación y mantienen guard de colección; Bomb a máximo permanece disponible. Hints/munición/cargas intactos. Polen recibió sólo el pequeño burst que faltaba.

## Revisión y validación

Test nuevo: `res://tests/bee_prototype/validate_bee_combat_vfx_v01.gd`. Verifica instancias, muzzle en spawn, trail, impacto real, daño/radio/collider, Spread, melee, expansión a 3 m, Death en reproducción, collider de caja libre, pickup único y cleanup completo. Tests no evalúan belleza.

Review: `dev/combat_vfx_review/`. Diez capturas principales numeradas y dos frames adicionales de Bomb (temprano/intermedio), sin sistema de vídeo. Render OpenGL Compatibility / Intel Arc B580. Capturas muestran la cámara real y escenografía actual, sin rediseño; foliage puede ocultar fragmentos pequeños, especialmente cerca del suelo.

Baseline anterior Weapons: ~100 FPS. Muestra local de 240 frames renderizados por condición, sin otros tests concurrentes: reposo 99,99 FPS / peor frame 10,277 ms / pico 1076 nodos; estrés con Spread, tres Probes iniciales activos, Bomb y varias muertes 99,11 FPS / peor frame 37,845 ms / pico 1276 nodos. Hubo un frame >33,3 ms; los últimos 120 frames dieron 99,98 FPS, sin caída sostenida. Es una muestra de ~2,4 s, no un benchmark largo.

Antes de compartir recursos: 91,94 FPS, peor frame 68,131 ms, seis frames >33,3 ms y tramo final 91,03 FPS. Logs previos conservados en vfx_render_cold.log, vfx_render_repeat.log y vfx_render_before_resource_reuse.log. No se oculta el pico final de 37,845 ms: requiere observación en playtest humano. Resultado de suite final: logs del mismo directorio.

Limitaciones: efectos funcionales V01, sin bloom real en Compatibility, audio, hit-stop, knockback o partículas físicas. La medición es corta y local; requiere playtest humano de lectura en movimiento, ruido en grupos y stutters de primera aparición. Esta tarea no resuelve la dirección artística global del jardín. No se inicia Audio.

## Cierre

Test VFX headless/render aprobado, Weapons aprobado, Level 01 integrado aprobado y suite final **19/19** (baseline 18 + nuevo VFX test), sobre la versión que comparte recursos. Sin errores/advertencias del motor ni regresiones. Level mantiene 24 eventos, 38 enemigos, máximo tres, 350 colocaciones, cuatro pickups y restart. Corredor humano seguro durante 473 frames en el test integrado. Capturas revisadas: diez principales + dos fases extra de Bomb. Conclusión: **BEE COMBAT FEEDBACK + VFX V01 APTO**.

Cambios propios: dos scripts VFX y sus UID, escena VFX reutilizable, test y documento nuevos; hooks visuales en BeePlayer, proyectil, Bomb, powerups, polen, cajas y siete escenas enemigas. Documento Weapons actualizado. Sin modificación de escenas Level, flora, cámara, Health/HitFlash, IA o parámetros de combate. Git status final en `dev/combat_vfx_review/git_status_final.txt`; cambios previos preservados, sin commit/push/reset/clean/stash.

Prueba manual: abrir Level 01 y F6. X dispara Base/Spread, Z conecta melee, C usa Bomb y R reinicia tras derrota. Observar muzzle/trail, impactos y muertes; probar cajas y pickups. Siguiente paso mínimo: playtest humano corto de estas señales y de los picos de primera aparición, sin comenzar Audio.
