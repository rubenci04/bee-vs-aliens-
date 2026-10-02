# Bee Weapons + Powerups V01

Escena: `res://scenes/levels/bee_level_01_vertical_slice.tscn`. Kit temporal arcade, sin inventario ni persistencia.

| Ataque | Input | Parámetros |
| --- | --- | --- |
| Base | X | Proyectil existente: 10 HP, 14 m/s, vida 1,4 s. Una pulsación = un disparo; cadencia intacta. |
| Spread | X | Tres proyectiles existentes, central con auto-aim actual y laterales ±14° sobre esa dirección. 6 HP cada uno (60%). Trayectoria fija, sin homing. |
| Alien Bomb | C / `bee_bomb` | Descarga centrada en Bee, radio 3 m, 32 HP. Máximo 3 cargas; Level 01 empieza con 1. No usa auto-aim. |

Spread dura 24 pulsaciones (no 24 proyectiles). El último disparo sigue siendo triple y el siguiente vuelve a Base. Recoger otra cápsula recarga a 24, sin acumulación. Los valores están exportados en BeePlayer; el daño Spread deriva del daño real del proyectil base.

Pickup reutilizable `bee_powerup_pickup.tscn`: cian alien, prisma con S para Spread, esfera con B para Bomb; diferentes del polen amarillo. El polen conserva su función de curación. Bomb suma una carga; si ya hay tres, el pickup permanece disponible.

## Daño y feedback

Bomb usa DamageHitbox3D / DamageHurtbox3D / Health existentes. Hace una sola consulta física al activarse y deduplica por Health, incluso con varias hurtboxes en una entidad. Sólo admite enemigos activos/vivos del grupo de targeting y DestructibleObstacle3D. No afecta Bee, enemigos inactivos, humano, rocas, tronco ni decoración. La esfera de alcance considera intersección con hurtboxes; no requiere que su centro esté dentro. No necesita línea de visión.

Cajas: 24 HP, por lo que una Bomb de 32 las destruye y libera sus colliders. Walker no muere de una sola Bomb. No se cambiaron HP, ataques o encuentros. Consulta limitada a 128 resultados: ampliamente por encima del máximo actual de tres amenazas y obstáculos próximos.

Feedback provisional: aro cian/blanco que se expande durante 0,22 s y desaparece durante 0,18 s. El daño es instantáneo; el aro no vuelve a causar daño ni empuja enemigos. Spread mantiene los tres proyectiles visibles, sin VFX adicional.

HUD aditivo cerca del HP: BASE o SPREAD xN, BOMB xN y C BOMB. Se actualiza por señal, sin polling. Primer pickup de cada tipo muestra durante tres segundos `SPREAD SHOT · X — FIRE` o `ALIEN BOMB · C — USE`. La derrota oculta el hint y bloquea ambos ataques/recogida; R recarga la escena y restaura Base, 0 Spread, 1 Bomb, cuatro pickups y HUD.

## Colocación Level 01

| Pickup | X / Y / Z (m) | Uso inmediato |
| --- | --- | --- |
| Spread inicial | 22 / 3,8 / 0 | Antes del par de Wasps en X=26. |
| Bomb inicial | 166 / 3 / 0 | Antes de EyeDrone + Turret en X=170. |
| Spread recarga | 222 / 3,8 / 0 | Antes de dos Wasps en X=226. |
| Bomb recarga | 318 / 3,8 / 0 | Antes de las tres amenazas en X=324. |

Conservados: 360 m, scroll 2 m/s, 24 eventos, 38 enemigos, 17 polen, 8 cajas, 8 rocas, humano, tronco y 350 colocaciones decorativas. Sólo Level 01 configura una carga inicial; las escenas Bee anteriores mantienen cero por defecto.

## Validación

Test específico: `res://tests/bee_prototype/validate_bee_weapons_powerups_v01.gd`. Cubre Base, recogida física, auto-aim Spread, ángulos/daño real, agotamiento/recarga, C, carga máxima, siete familias de enemigos, varios targets/hurtboxes, cajas, exclusiones, derrota y reload real con R. El integrado de Level 01 conserva progresión/colisiones y comprueba los cuatro pickups y su restauración.

Capturas y logs: `dev/weapons_powerups_review/`; ocho PNG numerados con pickup/kit/triple shot/Bomb/grupo/HUD. Muestra local OpenGL Compatibility, Intel Arc B580, 180 frames renderizados por condición: tres Probes inicialmente activos con IA, primero sin especiales y luego Spread periódico + Bomb. Baseline 100,00 FPS, peor frame 10,452 ms, pico 1172 nodos; especiales 100,00 FPS, peor frame 10,652 ms, pico 1232 nodos. Muestreo por process_frame, sin limitarlo a los ticks físicos. Medición limitada por presentación local; no benchmark de hardware ni prueba de dificultad. Los enemigos pueden recibir daño durante la muestra especial.

Cierre: test específico headless y render aprobados; Level 01 integrado aprobado (24 eventos, 38 enemigos, máximo tres, recogida/restart OK, humano sin regresión); cargas jugables directas headless/render código 0; suite Bee **18/18** (baseline 17/17 + nuevo test). Sin SCRIPT ERROR, recursos faltantes ni errores del motor. Logs conservados en la carpeta de review.

Ejecución manual: abrir Level 01 y F6. WASD/flechas volar, X Base/Spread, Z melee, C Bomb, R tras derrota. Recoger S/B, observar HUD, gastar Spread para volver a Base y usar C cerca de grupos/cajas. No se cambió el main_scene del proyecto.

Limitaciones: feedback/HUD provisionales, sin cuarta arma, persistencia, upgrades, VFX final ni audio. Los tests aíslan daño y automatizan progresión; falta playtest humano para evaluar cobertura Spread, utilidad Bomb, lectura y dificultad. No se inicia otra tarea.

Integración Combat Feedback + VFX V01: muzzle Base/Spread, núcleo y trail corto, impactos y Bomb compuesta se añadieron como feedback visual. Spread conserva 3×6 HP, ±14° y 24 pulsaciones; Bomb conserva 3 m/32 HP/cargas. Pickups emiten pulse/burst tras aceptación, manteniendo hints y límites. Ver BEE_COMBAT_VFX_V01.md; no cambios al kit ni al HUD.
