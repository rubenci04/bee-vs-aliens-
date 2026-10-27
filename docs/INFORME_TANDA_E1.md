# Tanda E1 — Aguijón taladro estético, cierre Post-Robot → Tarántula, Polen unificado, spawns a la derecha

Rama `lote-16-titulo-intro`. Sin commit (pendiente de pedido explícito).

## 1. Aguijón taladro metálico (solo estético)
- **Causa**: la Tanda 4g (`707b5a4`) quitó el ataque del aguijón y, de paso, `bee_visual.gd` ocultaba el nodo `Stinger` del modelo (`old_stinger.hide()`). El taladro (`stinger_drill` + `stinger_tip`) es hijo de ese nodo, así que desapareció con él.
- **Arreglo** ([bee_visual.gd](../scripts/bee_prototype/bee_visual.gd)): el nodo `Stinger` se muestra siempre. No se reactivó nada del ataque viejo: sin hitbox (el nodo no tiene `Area3D`), `bee.stinger` sigue `null`, sin cono cromado ni estela. El cuerpo a cuerpo es solo el Puñetazo (Z / Y-RB).
- Tests: `validate_bee_hero_integration_v01` y `validate_bee_t4g_punch` ahora exigen que sea visible y sin hitbox.

## 2. Cierre al vencer al Robot / rumbo a la Tarántula
- **`quit()` en producción**: solo hay dos, ambos en el botón «Salir» del título (`bee_title_screen.gd`, `title_screen_v01.gd`). Ningún autoload ni helper cierra el juego solo.
- **Causa de los tests rotos (escenario nulo)**: `validate_bee_walker_miniboss_v01` y `validate_bee_tarantula_boss_v01` tomaban el último hijo de `root` como escena y eso ya no es el nivel. Ahora instancian y castean directo.
- **Blindajes** (no pude reproducir un crash real en el nivel; son defensivos):
  - [bee_enemy_teleport.gd](../scripts/vfx/bee_enemy_teleport.gd): `begin()` rechaza unidades sin padre; `_ready`/`_physics_process` comprueban `is_instance_valid(passenger)`, `passenger.is_inside_tree()` y `is_inside_tree()`; el acceso a `get_parent().get_parent()` ya no revienta si se desancló; `_restore()` sale si el pasajero se liberó.
  - [walker_miniboss.gd](../scripts/levels/walker_miniboss.gd) y [tarantula_boss_01.gd](../scripts/levels/tarantula_boss_01.gd): `_physics_process` sale si el jefe no está en el árbol o no tiene padre; los temporizadores de hitbox/aviso comprueban `is_instance_valid(self)`.
  - [bee_level_01_controller.gd](../scripts/levels/bee_level_01_controller.gd): `_post_robot_supplies()` y `_start_tarantula()` salen si falta el árbol, Bee, el stage o `../Enemies`.
- **Test nuevo** `validate_bee_tanda_e1_post_robot_to_tarantula`: nivel real, el Robot cae, aparecen y se recogen bomba + Spread, la cámara avanza, entra la Tarántula, pasa las 4 fases, se libera y sale la pantalla de resultados. Cuenta errores del motor con un `Logger` (verificado que detecta `push_error`) y exige 0, más el taladro visible al inicio y a mitad del combate. **Resultado: OK, 0 errores.**
- Otros arreglos de contrato en los tests de jefes (no son del juego): la banda 30-45 s del Robot pasó a 45-130 s (Tanda D exige ≥ 45 s), el láser se espera hasta 30 s tras romper el cañón, «SECTOR DESPEJADO» → pantalla de resultados (T2) y la altura del implante en el techo (T7b bajó el techo).

## 3. Polen: una sola pulsación = curar + escudo
([bee_pollen_nova_settings.gd](../scripts/game/bee_pollen_nova_settings.gd), [bee_level_01_juice.gd](../scripts/levels/bee_level_01_juice.gd), nuevo [bee_pollen_shield.gd](../scripts/vfx/bee_pollen_shield.gd))
- Q / LT-L2 por pulsación (flanco; mantener no repite): gasta 1 cartucho (7 granos) y **siempre**: cura +25 HP con texto flotante `+25 VIDA` y destello; burbuja dorada semitransparente que sigue a Bee 2,5 s (pulso y parpadeo los últimos 0,4 s); invulnerabilidad 2,5 s; destruye proyectiles enemigos que la tocan; pulso inicial radio 3,5 m (9 comunes / 6 jefes). Cooldown 3,0 s. Con 100/100 igual gasta el cartucho y da escudo.
- Textos: leyenda HUD `Q: CURAR + ESCUDO` / `LT/L2: CURAR + ESCUDO`, línea de controles del HUD, banner `Escudo y Cura de polen listos: Q|LT/L2`, ayuda de Pausa y pantalla Controles del título.
- Tests actualizados: `validate_bee_tanda_a_pollen` (reescrito), `validate_bee_t3m_pollen_nova`.

## 4. Spawns desde la derecha
([bee_encounter_settings.gd](../scripts/game/bee_encounter_settings.gd), controlador)
- `_arrival_point`: x entre `cámara+2,8` y `borde derecho−1,0`, y ≥ 4,5 m a la derecha de Bee cuando hay espacio. Vale para oleada inicial, refuerzos de arena, rescate de 12 s y retornos.
- `_walks_in_naturally`: en la ruta (no arena, no puerta dura, no hormiguero, no profundidad, evento > 0) hormiga, caracol, escarabajo, moscas, avispa, mosquito y mariquita entran caminando/volando por el borde derecho; 1 de cada 3 (por slot) sigue por rayo. La primera oleada, las arenas y los retornos siguen con rayo.
- `REACH` pasó de 4,5 a 8,0 m: las llegadas ya caen más lejos de Bee y, con 4,5, el rescate las daba por «lejos».
- `validate_bee_tanda_b` actualizado con comprobaciones de posición y de entrada natural.

## Resultados de pruebas (headless)
| Prueba | Resultado |
|---|---|
| `validate_bee_tanda_e1_post_robot_to_tarantula` | OK, 0 errores |
| `validate_bee_tanda_a_pollen`, `validate_bee_t3m_pollen_nova`, `validate_bee_tanda_b` | OK |
| `validate_bee_hero_integration_v01`, `validate_bee_t4g_punch`, `validate_bee_lote14_controls_v01`, `..._pollen_v01`, `..._screen_v01`, `validate_bee_lote17_hud_v01` | OK |
| `validate_bee_walker_miniboss_v01` (estructura + 4 bots expertos, `dev/lote15/walker.sh expert`) | OK: 107,7 / 86,6 / 82,5 / 67,5 s |
| `validate_bee_tarantula_boss_v01` | **Falla** solo en los bots de pelea (ver abajo); estructura, regla de pirueta, trampa de red y movimientos ya pasan sin escenario nulo |

## Pendiente / no verificado
- **Bots de la Tarántula** (`validate_bee_tarantula_boss_v01`): el bot experto no logra derrotarla en 300 s (daño 671-778, duración `inf`) con el balance actual de la Tanda D; la banda 80-110 s y el daño 55-80 son del Lote 15. Recalibrar el bot es una tarea aparte (ver `dev/lote15/tarantula.sh`); no toqué HP ni daño del jefe.
- `validate_bee_lote11_juice_v01` tiene el mismo patrón de escenario nulo y se cuelga; no lo toqué (fuera de alcance).
- No corrí la suite completa de ~150 pruebas; la base de la Tanda D ya tenía 44 fallos históricos (varios por el mismo texto «SECTOR DESPEJADO»).
- El crash del playtest humano no se reprodujo; los blindajes son preventivos. Falta playtest: ver el taladro en pose de vuelo, la burbuja de polen y las entradas por la derecha.
- Los `*.import`/`*.uid` sin seguimiento y el cambio de `project.godot` ya estaban antes de esta tanda.
