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
