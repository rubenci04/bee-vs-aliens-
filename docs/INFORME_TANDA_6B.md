# T6b — Reducción pareja de vida de enemigos comunes

Fecha: 15/10/2026. Rama: `lote-16-titulo-intro`. Pedido: bajar la resistencia de todo el elenco común ajustado en T6a, sin cambiar daño, jefes ni Aguijón.

## Auditoría y cambio

Primero se creó [VIDA_ANTES_DESPUES.md](VIDA_ANTES_DESPUES.md) con las 12 familias de `COMMON_HP`, sus vidas de T6a, daño Base real de 3, impactos y TTK a 36 DPS, antes de modificar gameplay. Después se completaron las columnas nuevas. Se usa `HP / 36` para el límite de TTK pedido; no se confunde con el tiempo discreto desde el primer impacto inmediato.

`scripts/game/bee_enemy_health_settings.gd` sigue siendo la única fuente de HP en gameplay. Once familias pierden exactamente tres impactos de Base (9 HP). Araña: 90 HP / 30 impactos → regla de reducción 81 / 27 → tope de grande **72 HP / 24 impactos / 2,00 s**. Esta reducción adicional cumple el máximo solicitado; no se aumentó el daño de Bee. Todas las familias actuales tenían seis impactos o más; la rama `max(1, ceil(impactos * 0.55))` no tiene destinatarios en ese elenco.

Nuevos HP: mosca común/hormiga 33; mosca verde/avispa/mariquita 36; nube 66; gusanos/escarabajo/caracol/hongo 51; araña 72. Los no grandes quedan en 0,917–1,000 s; los grandes, en 1,417–2,000 s. Ninguno tiene vida cero ni muere con cero impactos. La vida al iniciar es fija, no se vuelve a reducir en cada spawn.

Los topes configurables `COMMON_MAX_TTK = 1.5` y `LARGE_MAX_TTK = 2.0` viven en la misma configuración. `target_time()` conserva la clasificación por tamaño de T6a, pero sus rangos empiezan en cero y terminan en el máximo nuevo: ya no exige un tiempo mínimo de supervivencia ni multiplica el objetivo por lentitud. Medidas, velocidades y comportamientos permanecen iguales.

Las cinco claves existentes de `BeeGameSettings.SMALL_ENEMY_HP` siguen siendo alias de `COMMON_HP`: ruta y escoltas reciben las mismas vidas sin multiplicadores nuevos. `LEGACY_HP` permanece intacta; las familias reservadas de otros niveles no se incorporan a N1 ni se balancean en esta tanda. Robot minijefe 600 HP, Tarántula/UFO 1200 y los demás jefes conservan sus datos. Aguijón sigue en 30 de daño y conserva su lógica T4b.

## Prueba ajustada y resultados dirigidos

Se amplió `tests/levels/validate_bee_t6a_health.gd` para comprobar la reducción contra una fixture histórica T6a, el tope continuo a 36 DPS por clase, impactos enteros positivos, menos impactos que antes, HP reales de fábrica en ruta/escoltas y daño de Aguijón 30. Mantiene los impactos reales a cuerpo con Base/Spread y los bancos de nueve nubes quietas y móviles. La fixture del test no se consulta desde gameplay ni es otra fuente de HP.

Se ejecutaron las mismas once pruebas **antes y después** del cambio. En ambas pasadas: **7 aprobadas y 4 fallidas; ningún fallo dirigido nuevo**.

| Prueba | Antes | Después | Alcance / diagnóstico |
|---|---|---|---|
| `validate_bee_t6a_health` | Pasa | Pasa | Las 12 familias, vidas de fábrica, fórmula/tope T6b y daño real; nubes quietas/móviles. |
| `validate_bee_tanda4c_weapons` | Pasa | Pasa | Perfiles y DPS de armas sin cambios. |
| `validate_bee_lote15_hits_v01` | Pasa | Pasa | Proyectil → hitbox → cuerpo → salud. |
| `validate_bee_t4d` | Pasa | Pasa | Gusanos: fábrica, entradas y ataques conservados. |
| `validate_bee_lote14_controls_v01` | Pasa | Pasa | Controles y alcance conservados. |
| `validate_bee_t4b` | Pasa | Pasa | Embestida, contacto físico, invulnerabilidad y espera con pirueta. |
| `validate_bee_weapons_powerups_v01` | Pasa | Pasa | Armas y power-ups conservados. |
| `validate_bee_audio_basic_v01` | Falla | Falla | Aserción previa `Impact audio/damage mismatch tech_hit`. |
| `validate_bee_combat_vfx_v01` | Falla | Falla | Aserciones previas `Muzzle not at spawn` y `Projectile gameplay altered`. |
| `validate_bee_tarantula_boss_v01` | Falla | Falla | Accesos previos a escenario nulo (`wave`, `scroll_speed`, `boss`) y fallo de inicio de fase 1. |
| `validate_bee_walker_miniboss_v01` | Falla | Falla | Accesos previos a escenario nulo (`wave`, `distance`, `health`) y fallo de aparición del Robot. |

Estos cuatro tests ya fallaban en la pasada previa de esta misma tanda; no se repararon sus fixtures, código de juego ni expectativas. Cada `SCRIPT ERROR` cuenta como fallo aunque la salida del motor sea cero. Logs y resultados completos locales, fuera del commit: `dev/t6b_before_*.log`, `dev/t6b_after_*.log`, `dev/t6b_before_results.json` y `dev/t6b_after_results.json`.

Banco físico de nueve nubes con Base sostenida: quietas **19,25 → 17,08 s**; con entrada/movimiento reales **16,35 → 14,27 s**. Ambos casos conservan el límite de 20 s del test. Son tiempos simulados del banco automatizado, con Bee protegida y apuntado dirigido al cuerpo; no miden errores de un jugador ni duración de una arena completa.

## Validación final e integridad

La suite completa se ejecutó **una sola vez: 87/131 aprobadas y 44 fallidas**, incluida la prueba de salud ampliada aprobada. Ningún fallo nuevo por nombre frente al registro T9 (86/131 aprobadas, 45 fallidas): los 44 casos siguientes ya figuraban fallidos allí. No se declara verde el repositorio ni se reparan esos tests en esta tanda.

Ejecución headless con Godot 4.7.2, hasta tres procesos independientes y `APPDATA` escribible aislado por test bajo `dev/`. Se conserva la excepción histórica sin `--fixed-fps` de `validate_toon_items_v01` y `validate_wasp_visual`. Los casos que emitieron `SCRIPT ERROR` y seguían abiertos se cerraron tras dos segundos: **27 cierres por error de script**, todos contados como fallidos; **cero timeouts**. No se repitió la suite completa. Esta metodología obtiene el estado de regresión, no una medición de rendimiento.

`validate_bee_lote14_music_v01` pasa en esta ejecución con entorno de usuario aislado; en T9 fallaba la expectativa del volumen inicial del bus Music. No se modificó audio, buses ni el test, ni se atribuye ese resultado a la reducción de HP. Logs y resumen locales: `dev/t6b_full_*.log`, `dev/t6b_full_results.json` y `dev/t6b_full_summary.log`.

Casos fallidos, conservados sin arreglos ajenos al pedido:

```text
validate_alien_probe_visual
validate_bee_audio_basic_v01
validate_bee_combat_poc
validate_bee_combat_vfx_v01
validate_bee_flight_poc
validate_bee_mission_01
validate_bee_shmup_air_ground_poc
validate_bee_shmup_ground_threat_poc
validate_bee_shmup_organic_alien_poc
validate_wasp_visual
validate_bee_arcade_combat_patterns_v02
validate_bee_arcade_pressure_world_interaction_v01
validate_bee_arcade_rebuild_v02
validate_bee_asset_fauna_v01
validate_bee_assets_cleanup_v02
validate_bee_balance_liberation_v04
validate_bee_boss_fight_v04
validate_bee_checkpoint_qol_v01
validate_bee_combat_variety_v01
validate_bee_controlled_fauna_v01
validate_bee_fauna_facing_v01
validate_bee_free_aim_v01
validate_bee_garden_toad_v01
validate_bee_items_shots_v04
validate_bee_level01_arcade_director_v01
validate_bee_level01_challenge_balance_v01
validate_bee_level01_roster_v01
validate_bee_level01_transformation_v01
validate_bee_level_01_vertical_slice
validate_bee_liberation_v01
validate_bee_lote11_density_v01
validate_bee_lote11_juice_v01
validate_bee_lote13_combat_v01
validate_bee_lote15_gameplay_v01
validate_bee_pacing_v01
validate_bee_readability_v03
validate_bee_second_checkpoint_v01
validate_bee_tarantula_boss_v01
validate_bee_threat_camera_boss_v03
validate_bee_ufo_boss_01
validate_bee_ufo_boss_nodo_v02
validate_bee_ufo_overload_v01
validate_bee_visual_polish_v02
validate_bee_walker_miniboss_v01
```

Se compararon hashes antes/después de `project.godot`, jugador, helper/configuración del Aguijón, configuración de disparos, controlador y scripts de Robot/Tarántula/UFO: todos intactos. `project.godot` ya tenía un reordenamiento local del bloque de rendering al empezar, que se conserva y no se incluye en el commit. Los archivos locales sin seguimiento ajenos a T6b tampoco se incluyen. No hubo cambios de assets, cantidades, calendarios, colisiones ni daño enemigo.

## Cómo probar

Abrir `D:\proyectos\bee_alien_3d` con Godot 4.7.2. En Normal, abrir `scenes/levels/bee_level_01_vertical_slice.tscn` y pulsar F6. Mantener X/clic/RT con Base sobre el cuerpo de moscas, avispa, hormiga y mariquita: deben requerir tres impactos menos que en T6a. Repetir con nube, gusanos, caracol, escarabajo y hongo; la araña requiere seis menos por el tope. Sin contar implante/Frenesí, los impactos esperados están en la tabla de auditoría.

Probar Z cerca de un enemigo y comparar la embestida/retroceso con T4b; el daño sigue siendo 30. En Robot/Tarántula, comprobar que sus barras no arrancan más bajas. Repetir con mando y ratón. Los TTK son nominales con todos los impactos acertados; la entrada, movimiento y fallos de puntería pueden hacer que un enemigo siga llegando al borde izquierdo. Queda pendiente el playtest humano para confirmar la sensación solicitada; no se cambió la puntería para esconder ese riesgo.
