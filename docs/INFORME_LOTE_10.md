# Informe Lote 10

## A. Nivel 01 — fauna, utilería, ciclo solar y vuelo

- Luciérnagas reservadas para un futuro bosque mediante `FIREFLIES_ENABLED`; Nivel 01 ya no instancia sus modelos ni partículas. Se conservaron las escenas y el movimiento.
- El modelo Kenney `log_large.glb` de X≈55 se ocultó y el tronco hueco marrón existente se colocó después de la botella verde y antes del árbol. El collider original del tramo permanece.
- La paleta compartida de las rocas cambió de gris cálido a oliva gris apagado. Corrige el hexágono claro junto a la manzana y la roca beige junto al momento de la rana sin alterar geometría ni colisiones.
- Se conectó el sol toon existente al avance del nivel, con halo cálido suave: bajo por la mañana, alto al mediodía y oscurecido al salir la luna. Está en la zona superior derecha, fuera del HUD.
- Bee puede recorrer el 95% del ancho visible, con márgenes horizontales iguales del 2,5%; los márgenes verticales siguen iguales. La validación cubre 16:9 y 16:10. El encuadre previo del prototipo de lago se conserva.

Pruebas dirigidas: `validate_bee_level_01_framing_v01`, `validate_bee_threat_camera_boss_v03`, `validate_bee_asset_fauna_v01`, `validate_bee_visual_target_01`, `validate_bee_polish_props_v01` y `validate_bee_level02_lake_proto`. Suite completa: **78/78 PASS** (Godot 4.7.2, `--headless`; sin errores de script).

## B. Nivel 01 — presión, disparos, destructibles y bomba en vuelo

- **107 unidades / 59 eventos**, mismas familias, sin luciérnagas. Patrullas de 1–3 unidades, tres oleadas mixtas por zona; topes de 6 en ruta y 8 en zonas. Se conservaron gates X=254/296/340, checkpoints X=190/281 y HP/tiempos de liberación del Lote 9.
- Se reutilizaron orbes divisibles, morteros, láser y abanicos. Mosquito, hormiga, mariquita, escarabajo, ambas libélulas, araña y speeder incorporan un arma de implante: apuntado o alternancia apuntado/abanico de tres, aviso de 0,6 s y disparo solo dentro de pantalla. Ráfagas de Eye/Walker: tres tiros. `ROUTE_DAMAGE_SCALE=0.22` equilibra la mayor densidad; no se aplica al jefe ni a sus refuerzos. Los proyectiles conservan el ajuste aunque desaparezca su emisor.
- Rocas grandes y tronco con HP finito, partículas y liberación de colisiones; algunos obstáculos dejan polen o curación. Las cáscaras pequeñas son decoración sin colisión. Romper el tronco oculta su modelo y elimina todas sus paredes; el checkpoint conserva ese estado sin repetir premios.
- **C** lanza el modelo toon de bomba existente hacia el mouse: 14 m / 1,2 s, una en vuelo. Contacto, alcance o segundo C detonan tras mostrar el radio durante 0,24 s. HUD: **C — DETONAR**. Stock máximo 5, área 32 de daño / 3 m, jefe 8%, Bee sin daño propio.

Medición reproducible: `validate_bee_pacing_v01.gd`, Normal, arma Base a 3 tiros/s, movimiento y esquiva simples, sin invulnerabilidad antes del jefe. Se cuentan drones pequeños y amenazas visibles en ambos ejes; se excluyen el epílogo y los refuerzos del jefe del recorrido.

| Métrica | Resultado |
| --- | --- |
| Entrada al jefe | 363,9 s — 6,1 min |
| Unidades del recorrido | 107 |
| Máximos simultáneos ruta / zonas | 5 / 5; límites comprobados 6 / 8 |
| Mayor hueco sin amenaza visible | 6,3 s |
| Tiempo acumulado sin amenaza | 136 s (antes: 198 s, con otro criterio de visibilidad) |
| Daño acumulado antes del jefe | 37 HP |
| HP al entrar al jefe tras curaciones | 97/100 |
| Retiradas antes del tiempo mínimo | 0 |

Cambios principales: `bee_level_01_controller.gd`, nuevos `bee_implant_shooter.gd` / `bee_obstacle_drops.gd`, `bee_alien_bomb.gd`, `bee_player.gd`, `bee_weapons_hud.gd`, hitbox/hurtbox compartidos, obstáculos/rocas/superficies, momentos y checkpoint. Tests de conteos/patrones actualizados; nuevas validaciones `validate_bee_flying_bomb_v01` y `validate_bee_lote10_pressure_v01` cubren vuelo, segundo C, aviso, alcance/contacto, daño persistente, topes, rotura y checkpoint.

Verificación final: **80/80 validaciones verdes**, revisión renderizada Compatibility en `dev/lote10_b_review/`. Se hizo una única pasada completa (75 PASS, 5 fallos) y se repitieron solamente las cinco afectadas: las expectativas de audio, checkpoint y acompañamiento de la libélula se actualizaron al comportamiento pedido; ítems toon y alas de avispa pasaron sin FPS fijo, que alteraba la sincronización entre física y presentación de esos fixtures. Las cinco repeticiones terminaron con salida 0 y sin `SCRIPT ERROR`. Logs: `dev/lote10_b_full_suite.log`, `dev/lote10_final_retest_*.log` y `dev/lote10_b_final_retests_result.log`.

Comando por test: Godot 4.7.2 `--headless --fixed-fps 60 --path . --script res://tests/...gd`; para `validate_toon_items_v01` y `validate_wasp_visual`, omitir `--fixed-fps 60`. El bot usa el paso fijo para reproducir sus métricas. Permanecen los avisos conocidos del renderer dummy sobre materiales/recursos; se controlaron por separado los errores de script y los códigos de salida.

Para probar: abrir Nivel 01 en Normal; mirar el goteo inicial y las tres zonas, esquivar abanicos/avisos, romper rocas/tronco/latas y lanzar C, mover el mouse y volver a pulsar C antes de agotar el alcance. Revisar el HUD y reintentar desde un checkpoint.

## C. Rana de jardín y UFO final

- Se reutilizan el modelo toon, implante, lengua y liberación del sapo del Nivel 02 mediante `BeeGardenToadEncounter`, sin cambiar el combate del lago. Aparece en el evento X=188 (~3:14 con el bot), salta por Z=0, cruza y vuelve; sin dispararle, la prueba registra ocho cruces durante el encuentro. Scroll al 5%; al liberarla o al cumplir 50 s sale saltando y el nivel continúa, sin gate nuevo.
- Lengua horizontal, diagonal ascendente y doble: boca abierta, línea cian de 0,6 s, alcance del 60% del ancho visible. Se toma la posición de Bee al terminar cada aviso y luego la dirección queda fija. Daño configurable: 8. Implante: 210 HP en Normal; impactos precisos de Base a tres tiros/s lo liberan en 6,7 s. Se cancela el ataque, se quita el dispositivo, aparecen colores cálidos y **LIBERADO**.
- El casco del UFO limita el daño sostenido con un presupuesto regenerado: 1,43% del HP máximo/s en Normal y 1,25% en Fácil, con reserva de 14 HP. Se aplica después del multiplicador de ventana del escudo; los nodos mantienen su daño habitual y la bomba queda fuera del límite, al 8% cuando el casco es vulnerable, incluso en una ventana de escudo. La ventana se amplió a 24 s para que este tope no obligue a repetir excesivamente los nodos.
- Balas del UFO: 3 HP; órbita de nodos 1,6 rad/s (antes 0,8). Barrido ancho con dos corredores seguros de 1,7 m, embestida lateral marcada durante 0,8 s, drones Probe con disparos rectos y aviso mínimo de 0,42 s. Fases al 70/40/25/15%; la quinta es **SOBRECARGA**, con núcleo violeta. Un tarro de miel al entrar en fase 3 y otro al entrar en fase 5. Se conservan checkpoint del jefe y cinematográfica final.

Bot reproducible: `validate_bee_boss_fight_v04`, tres tiros/s, 60% de apuntado, esquiva parcial idéntica con ambas armas, `TIME_SCALE=1` y FPS fijo 60: un paso de física por frame como en el juego, sin retrasar los cambios de hitbox con varios pasos en un frame. Spread se mantiene cargada para medir el peor caso de daño sostenido. Capacidad de HP ampliada para finalizar todas las mediciones, sin bloquear daño; se mide daño acumulado, no HP neto después de curaciones. Cada pelea recorrió las cinco fases, abrió el escudo y ejecutó barrido y embestida; mínimo de aviso medido: 0,42 s, daño por contacto sin aviso: 0.

| Dificultad / arma | Pelea, desde fase 1 | Daño recibido |
| --- | --- | --- |
| Normal / Base | 84,5 s | 53 HP |
| Normal / Spread sostenida | 75,6 s | 50 HP |
| Fácil / Base | 90,6 s | 35 HP |
| Fácil / Spread sostenida | 80,4 s | 39 HP |

Recorrido completo actualizado: UFO a 379,9 s (6,3 min), hueco máximo 7,3 s, 107 unidades de tabla más la rana, máximos ruta/zonas 5/5. Daño antes del jefe: 60 HP (16 de lengua, 44 del resto), HP al entrar tras curaciones: 96/100. La patrulla posterior pasa de X=196 a X=194 y la siguiente de X=204 a X=202 para cubrir la transición sin ampliar los intervalos. Las cifras de la sección B describen el lote previo a este encuentro.

Archivos principales: `garden_toad_encounter.gd`, `bee_level_01_scale_event.gd`, `ufo_boss_01.gd`, `ufo_assault.gd`, `ufo_shield_node.gd`, `bee_level_01_controller.gd`, hook de daño en `hurtbox_3d.gd`; dos validaciones nuevas y fixtures/bot actualizados. Capturas Compatibility revisadas en `dev/lote10_c_review/`. Idea del modo desde atrás registrada en diez líneas en `docs/ROADMAP_RAIL_SHOOTER.md`; no implementada.

Verificación final: **82/82 validaciones verdes**. Una pasada completa dio 78 PASS y cuatro fallos; se corrigieron y repitieron solo las afectadas, además del pacing tras ajustar la patrulla. Se actualizaron el reloj del bot, el presupuesto del fixture de geometría congelada, la comparación Base/Spread limitada y la lista de velocidades legales con la rana. La embestida mantiene su posición durante el aviso para que la línea coincida con la trayectoria. Repeticiones con salida 0 y sin `SCRIPT ERROR`. Logs: `dev/lote10_c_full_suite.log`, `dev/lote10_c_full_suite_result.log`, `dev/lote10_c_retest_*.log`, `dev/lote10_c_frog_01.log` y `dev/lote10_c_overload_02.log`. Se mantienen los avisos conocidos del renderer headless sobre materiales/recursos. No se borraron ni reconstruyeron modelos.

Para jugar: abrir Nivel 01 en Normal. A mitad de recorrido, esquivar la lengua verticalmente, probar ambas direcciones del cruce y destruir el implante; también dejarla ir para comprobar el timeout. Contra el UFO, probar Base y Spread, buscar los dos huecos del barrido, salir de la franja de embestida, recoger miel y observar **FASE 5 / 5 · SOBRECARGA**. La bomba C conserva su daño y detonación manual. El balance sigue sujeto al playtest humano; no quedan funciones de este pedido previstas para otro lote.
