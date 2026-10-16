# Tanda D — T7c + T7d: Robot y Tarántula con más presión

16/10/2026. Rama `lote-16-titulo-intro`, base `62cdb11` (Tanda C). No se tocaron daño por golpe de Bee, HP de enemigos comunes ni los HP de los jefes (Robot 600, Tarántula 1200): la duración de ambos jefes la fija el presupuesto de DPS sostenido (`BODY_DPS_RATIO` / `HULL_DPS_RATIO`), no la vida (ver «Duraciones»).

## 1. Auditoría previa (qué había antes)

| Tema | Hallazgo |
|---|---|
| «Olas terrestres celestes en forma de gota» | Son `BeeGroundShockwave` (la onda del pisotón y del aterrizaje del salto; la comparten Robot y Tarántula): una media esfera lisa **celeste** (`Color(0.3, 0.95, 1.0)`). Además los **morteros** del Robot usaban el celeste de `AlienMortarShell`. |
| Ataques «nuevos» del Robot | **Ya existían** una ráfaga de 3 proyectiles (cañón dorsal, con anticipación de 0,5 s) y un salto con onda al aterrizar (`jump`, 0,75 s de anticipación). Dependían del cañón (la ráfaga desaparecía al romperlo) y el salto es largo. Se agregaron dos ataques **distintos** (ver abajo) en lugar de duplicarlos. |
| Escoltas del Robot | Segunda llamada al 60 % de vida (o a los 14 s): 3 insectos (avispa + mosca verde + mosca). |
| Duración del Robot | `BODY_DPS_RATIO = 0.032` → mínimo teórico a DPS base ≈ 31 s (objetivo previo 30–45 s). |
| Power-ups tras el Robot | `_post_robot_supplies` usaba la escena **vieja** `bee_powerup_pickup.tscn` (cápsula del prototipo, vestida después con un medallón oscuro con corona/bombita). El resto del juego usa `scenes/items/toon/spread.tscn` y `bomb.tscn` (hexágono con aro de color e icono propio; el nivel convierte los viejos fijos a esos). Se ve en `docs/pickups_antes_despues.png`: «Spread/Bomba dinámicos» ≠ «Spread/Bomba nuevos». La cura era el racimo de polen (ya moderno). Mismo caso para la bomba del jefe (`_spawn_boss_supplies`). |
| Cartel «PATAS BLINDADAS…» | `TarantulaBoss01._armour_legs()` llamaba `_boss_hint(...)` al entrar en fase 2. |
| Ayudantes de la Tarántula | Arañitas de caída (`TarantulaDropSpider`) en todas las fases; moscas (2) en fase 2; sin avispas. |
| Red | `TEARS_NEEDED = 4` (Normal), 8 tirones de teclas, gracia 1,5 s, la pirueta no la rompía (con la red puesta la pirueta se ignoraba). Redes: 6 apariciones por 4 fases. |
| Fase 4 (Furia) | El presupuesto `HULL_DPS_RATIO = 0.0095` (11,4 HP/s) gasta los 240 HP (20 %) en ~20 s a DPS base, y un implante expuesto paga la mitad, así que podía durar menos. |

## 2. Robot caminante

- **Plasma (T7c).** `BeeGroundShockwave` pasa a una cúpula de **plasma**: naranja en la base y magenta en la corona (colores por vértice), borde **irregular** y crestas (malla procedural determinista) y un **anillo de impacto chico** (r 0,7 m) que se desvanece donde nace la onda. Los morteros del Robot salen naranja (`AlienMortarShell.color`; la torreta conserva su celeste). El celeste queda para implantes, láser del ojo y cañón (sin cambio). La Tarántula hereda la onda nueva.
- **Dos ataques nuevos (T7d), cada uno con su anticipación de 0,5 s** (pulso de escala 1,0–1,12 con brillo naranja caliente: `BeeShotWarning`/`COMMON_CUE` con la especie `robot`):
  - `burst`: 3 proyectiles lentos (6,5 m/s, daño 4, separados 0,22 s) y **cada uno apunta a Bee al salir**; funciona también con el cañón roto.
  - `hop`: salto **corto** (0,5 s, 1,5 m de altura, aterriza a 2,5–4,5 m, siempre dentro del encuadre) con **onda más pequeña** al caer (daño 6, altura 0,9 m, 6 m/s) y golpe breve en el punto de aterrizaje.
  Entran en ambos patrones (`PATTERN`, `PATTERN_NO_CANNON`) sin quitar nada.
- **Escoltas.** La segunda llamada pasa a **50 %** de vida (respaldo por tiempo 24 s) y trae **2** avispas (una tiradora y una kamikaze, por la alternancia de Tanda C). *Interpretación anotada:* el pedido dice «drones»; en el Nivel 1 el contrato del roster es solo insectos, así que los 2 escoltas son avispas. Cambiar a EyeDrone/Probe es editar `escort_wave` en `EVENTS_ROSTER`.
- **Máximo 2 ataques simultáneos.** El Robot toma un cupo de `BeeCommonSlots` para cada ataque (espera 0,35 s si no hay); sus escoltas usan los mismos cupos.
- **Duración (T7d.3).** `BODY_DPS_RATIO` 0,032 → **0,0195**. Medido a DPS base (36 HP/s, todos los disparos al cuerpo, ninguno desperdiciado, el fastest-possible): **50,0 s** (≥ 45 s). Vida **sin cambio** (600): variarla no cambia la duración, la define el presupuesto.
- **Recompensas (T7e).** `_post_robot_supplies` y la bomba del jefe usan `scenes/items/toon/bomb.tscn` y `spread.tscn` (los mismos medallones hexagonales con aro e icono propio por tipo que el resto del nivel; la cura sigue siendo el racimo hexagonal de T3i). Se conservan las colisiones y cantidades (+3 bombas, Spread 20 s).

## 3. Tarántula

- **Cartel borrado.** Se quitó la llamada en `_armour_legs()`; el texto ya no existe en el jefe (el implante celeste indica dónde disparar). La función genérica `_boss_hint` se conserva (la usa el HUD y su test).
- **Arañas negras (T7f).** En **fases 2 y 4** la araña colgante grande del Nivel 1 (`ControlledSpider` en modo telaraña de Tanda C) baja por hilo desde arriba del borde, repartida por la arena: **3** por oleada en fase 2 y **5** en fase 4 (tope total 5 vivas). Cada una avisa su telaraña 0,5 s; el cupo compartido deja **máx. 2 atacando a la vez**. Reemplazan a las arañitas de caída en esas fases (fases 1 y 3 las conservan). Una oleada espera a que no queden arañas de la fase (o a una fase nueva), cada 18 s; se liberan con el jefe.
- **Avispas (T7g).** En **fase 3** entran **2–3 avispas kamikaze desde la derecha cada 15 s** (primera 2 s después de empezar la fase; tope 3 vivas, así que si no se matan la siguiente llamada trae las que falten). Son kamikaze (aviso 0,5 s + embestida bloqueada), con el cupo compartido.
- **Lluvia de telarañas (T7h).** Nuevo ataque `rain` en la Furia (dos veces por ciclo del patrón): **3 puntos de impacto** en el suelo (columna de Bee y uno a cada lado), cada uno marcado con un **anillo chico** 0,6 s y luego cae un grumo de tela (r 0,8 m, daño 6; charco 3 durante 0,5 s). Dos puntos caen juntos y el tercero espera a que aterricen: **nunca más de 2 vivos** (medido 2).
- **Redes (T7i).** Más redes en los patrones (fase 2: 2, fase 3: 3, fase 4: 3 por ciclo; antes 1, 2, 1), gracia tras liberarse 1,5 → **1,0 s**, y liberación rápida: **3** disparos (Easy: 2) **o una pirueta** (rompe la red al instante; antes la pirueta se ignoraba atrapada) o las pulsaciones de teclas de siempre.
- **Fase 4 ≥ 60 s (T7h.10).** En Furia el presupuesto baja a `FURY_HULL_DPS_RATIO = 0.0027` y el implante expuesto **no recibe descuento**. Medido a DPS base **con todos los disparos al implante expuesto (peor caso): 64,8 s**. La vida (1200) no cambia. Las bombas (8 % de la vida cada una) siguen fuera del presupuesto, como siempre: 3 bombas pueden saltarse parte de la fase; el requisito se mide a DPS base.

## 4. Pruebas

Nuevas (aprobadas): `validate_bee_tanda_d_robot` (plasma, ráfaga y salto con anticipación, onda del salto, 2 escoltas a mitad, tope de 2 atacantes, 50,0 s a DPS base), `validate_bee_tanda_d_rewards` (medallones toon con un icono por tipo, cantidades intactas) y `validate_bee_tanda_d_tarantula` (cartel ausente, 3 arañas en fase 2 por hilo desde arriba, avispas kamikaze desde la derecha cada 15,0 s, red rota por pirueta o 3 disparos, 5 arañas y lluvia en Furia con ≤ 2 vivos y anillos chicos, Furia de 64,8 s).

**Suite completa (una pasada, cierre 2 s tras `SCRIPT ERROR`): 108 aprobadas / 44 fallidas de 152** (149 previas + 3 nuevas). Los 44 fallos son exactamente los mismos nombres de la base de Tanda B y C: **cero regresiones y ningún fallo histórico reparado**; entre ellos siguen `validate_bee_walker_miniboss_v01` y `validate_bee_tarantula_boss_v01` (sus fixtures dan accesos a escenario nulo desde antes), por eso la duración se mide con las pruebas nuevas y no con esos bots. La suite no está verde. Resultados locales (sin commit): `dev/dfull_results.txt` y `dev/dfull_log_*.log`.

## 5. Cómo probar

F6 sobre `scenes/levels/bee_level_01_vertical_slice.tscn`. Robot (X≈294): ondas naranja-magenta con borde irregular y anillo chico, ráfaga de 3 que sigue a Bee, salto corto con onda, 2 avispas escolta a mitad de la pelea; al caer, los medallones de bomba/Spread/cura son los del resto del nivel. Tarántula: sin cartel al armarse las patas; arañas negras bajando por hilo en fases 2 y 4; avispas kamikaze por la derecha en fase 3; lluvia de telaraña con anillos chicos en Furia; redes más seguidas que se rompen con la pirueta o 3 disparos. Playtest humano pendiente (los tests no miden diversión ni si 64 s de Furia se siente justo).

## 6. Archivos

`scripts/levels/bee_ground_shockwave.gd`, `walker_miniboss.gd`, `tarantula_boss_01.gd`, `tarantula_web_net.gd`, `bee_level_01_controller.gd`, `scripts/bee_prototype/alien_mortar_shell.gd`, `bee_player.gd`, `scripts/vfx/bee_common_attack_cue.gd`, tres pruebas nuevas e informe. Sin cambios de modelos, assets ni daños de Bee. Quedan sin tocar los cambios locales ajenos del repositorio.
