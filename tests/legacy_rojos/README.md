# Suites en rojo apartadas (Tanda R)

Estas suites se **movieron** aquí (no se borraron) porque comprueban números o comportamientos de un diseño ya superado.
Cada arreglo destapaba otra expectativa vieja. Siguen corriendo con su ruta nueva (`res://tests/legacy_rojos/...`), pero
no forman parte de `docs/SUITES_NUCLEO.md`. Para recuperar una, reescribila contra el diseño actual en una tanda propia.

| Suite | Primera falla hoy | Causa | Decisión |
| --- | --- | --- | --- |
| validate_bee_arcade_combat_patterns_v02 | La avispa debe salir tras su última pasada | Desde la Tanda B las avispas son persistentes | Legado |
| validate_bee_arcade_pressure_world_interaction_v01 | La avispa hace exactamente tres pasadas (5) | Igual: avispa persistente | Legado |
| validate_bee_arcade_rebuild_v02 | Pocos disparos Base destruyen un dron popcorn | Disparo Base de 3 y drones del flujo viejo con OVNI | Legado |
| validate_bee_balance_liberation_v04 | El mosquito se libera en 20 s, no en 0,5–0,9 s | Vida y disparo rebalanceados (Lote 14, Tanda G) | Legado |
| validate_bee_checkpoint_qol_v01 | El avance en tiempo real no llega al destino | El harness empuja el nivel sin limpiar las zonas bloqueantes (Tanda B) | Legado, reescribir: cubre los checkpoints |
| validate_bee_controlled_fauna_v01 | Fuego Base razonable no libera a la libélula en 8 s | Disparo Base de 3 | Legado |
| validate_bee_fauna_facing_v01 | El mosquito debe mirar hacia donde se va (-X) | Los comunes ya no se retiran (Tanda B) | Legado |
| validate_bee_garden_toad_v01 | Liberación precisa en 6–8 s: 9 s | El sapo es del Nivel 2; balance viejo | Legado |
| validate_bee_level01_challenge_balance_v01 | El reinicio completo no restaura los pickups | Pickups nuevos de la Tanda K y flujo viejo | Legado |
| validate_bee_level01_roster_v01 | Un solo hurtbox para toda la nube | La nube cambió en la Tanda E2 | Legado, reescribir: cubre el elenco |
| validate_bee_level_01_vertical_slice | La destrucción con X dejó un colisionador invisible | Cadena de expectativas viejas (aguijón sin objetivo no daña, pickups, polen) | Legado, reescribir: es la prueba general del nivel |
| validate_bee_liberation_v01 | La avispa debe dejar de contar como amenaza al instante | Liberación y avispas cambiaron (Tandas B y D) | Legado |
| validate_bee_lote11_juice_v01 | No se emite enemy_hit | Señales de combo reemplazadas (T7b) | Legado |
| validate_bee_lote13_combat_v01 | La nube nunca avisó | Nube de la Tanda E2 | Legado |
| validate_bee_mission_01 | Llama is_active sobre un proyectil | Escena POC vieja | Legado |
| validate_bee_pacing_v01 | El bot normal muere a los ~200 s | Bot del Lote 14, anterior a las zonas bloqueantes | Legado (los .sh de dev/lote13 y dev/lote14 ya apuntan aquí) |
| validate_bee_t3k | Chispas de contacto durante el rayo | Efectos del rayo rehechos | Legado |
| validate_toon_projectiles_v01 | El proyectil se libera antes del chequeo | El bolt pega y desaparece antes que la comprobación vieja | Legado |

Recorridos largos que **no terminan** en 180 s y quedan en su lugar (no forman parte del núcleo):
`validate_bee_boss_fight_v04`, `validate_bee_level01_arcade_director_v01`, `validate_bee_level01_transformation_v01`,
`validate_bee_tarantula_boss_v01`, `validate_bee_walker_miniboss_v01`.
