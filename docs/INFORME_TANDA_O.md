# Tanda O — tope de ráfaga de la tarántula

- Base: `tanda-n-ritmo-combo` (`296192f`); rama: `tanda-o-tarantula-fase4`.
- `dev/tanda_o/measure_burst.gd` reproduce una superposición fija de Furia contra Bee quieta por hitbox → hurtbox → salud, con golpes entre 0,0 y 0,7 s.
- Medición antes: 8+10+8+8+3+8+6 = **51 de daño máximo en cualquier ventana de 1 s**; Bee quedó en 49/100.
- Medición después: 8+10+6+0+0+0+0 = **24 de daño máximo en 1 s**; Bee quedó en 76/100. Es una simulación reproducible, no una medición del video.
- Cinco golpes simultáneos de 8+10+8+8+3 pasan de 37 a 24 recibidos.
- `BeeBossBurstGuard` limita solo golpes de la tarántula y ayudantes marcados como araña o avispa, incluida la explosión directa de la avispa. `HealthComponent` no cambió.
- Lo absorbido sigue disparando flash, sonido y sacudida. Pirueta, escudo de polen, robot, OVNI y enemigos comunes mantienen su camino de daño.
- Constantes en `BeeGameSettings`: `BOSS_BURST_CAP_ENABLED=true`, `BOSS_BURST_WINDOW_SECONDS=1,0`, `BOSS_BURST_CAP_DAMAGE=24`.
- Señal de golpe absorbido: `BOSS_BURST_FEEDBACK_SHAKE_AMPLITUDE=0,045` y `BOSS_BURST_FEEDBACK_SHAKE_SECONDS=0,2`.
- No se cambió la vida ni el daño por golpe de ningún jefe. La prueba de Tanda D midió **64,8 s de Furia a Base** (mínimo pedido: 60 s).
- Prueba manual: abrí Godot 4.7.2, F5, Jugar; llegá a la tarántula jugando o con F9 y disparale hasta FASE 4/4 FURIA.
- Quedate cerca de sus ondas y arañas; los golpes se deben ver y oír, pero la vida no debe bajar más de 24 por una ráfaga de 1 s. Probá también pirueta y escudo de polen.
- Pasaron `validate_bee_tanda_o`, `validate_bee_boot_order`, `validate_bee_tanda_e1_post_robot_to_tarantula` (cuatro fases) y `validate_bee_t1b_hud`.
- `validate_bee_tanda_d_tarantula` falló solo por el intervalo de avispas: 15,47 s frente a 15±0,3; con Bee protegida en ese test, el tope no intervino. Furia sí dio 64,8 s.
- También fallaron dos expectativas ajenas al cambio: `validate_bee_t7b_combo` aún espera Frenesí en x8/x16 (Tanda N lo dejó en x15) y `validate_bee_lote15_gameplay_v01` espera volver a Base al vencer Spread.
- No se corrieron las 156 suites ni los dos recorridos largos excluidos. Godot avisó que no pudo escribir `user://logs/godot.log` y de recursos retenidos al salir.
