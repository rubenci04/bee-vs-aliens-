# Playtest Polish Pass 01

Feedback manual del usuario; baseline al retomar: **Organic Alien POC y suite Bee 14/14**, sin regresiones. Esta pasada no altera balance, auto-aim ni sistemas de combate.

| Tema observado | Resolución |
| --- | --- |
| Organic Alien miraba al lado contrario de Bee | **Corregido.** El GLB se presenta con yaw `facing_x × 45°` en VisualRoot (antes `−facing_x × 45°`), sin tocar el archivo fuente. HOVER/STALK siguen a Bee en X; WINDUP/LUNGE conservan la orientación comprometida. Idle, Walk, Bite_Front y Death siguen en el mismo rig. |
| Rombo de auto-aim grande/grueso; tapaba enemigos | **Corregido en** `bee_player.tscn`, sin tocar la selección: `font_size` 58→28, `outline_size` 8→3, `pixel_size` 0,004→0,0024, alfa 0,92→0,72. Posición local Y +0,2 sobre el indicador que ya sigue al objetivo. Se retiraron overrides redundantes de cuatro POC para usar un marcador compartido. Revisado sobre Probe, EyeDrone, Organic Alien y GroundTurret. |
| Tronco hueco se comportaba como bloque sólido | **Corregido sólo en Ground Threat.** `bee_shmup_ground_threat_poc.tscn` conserva `log_large.glb` a X≈25, eje de túnel X, y desactiva el `BoxShape3D` heredado de 3,8×1,7×1,6. Cuatro `BoxShape3D` simples forman techo, piso y paredes de Z±0,67; el centro queda libre. Bee atravesó entrada, interior y salida con física real, sin movimiento Z ni atasco. Air + Ground continúa ocultando/desactivando ese tronco. |
| Jardín algo vacío; se prefieren más flores y vegetación | **Aplicado sólo a Organic Alien y Ground Threat.** 13 instancias decorativas nuevas de `flower_purpleA` aprobado (7/6) y 4 `Fern_1` (2/2). Están mayormente en Z≈−4 a −5, a ras de suelo, con variación moderada de escala y orientación; no tienen collider ni se ubican delante de los encuentros. |
| Giant Human: caminar tosco, quizá demasiado pequeño; posible ruta segura entre piernas | **Implementado en Giant Human Polish Pass 01.** Escala visual 5×→6×, `Run` más lento, cruces a 2,6/2,4 m/s y hitbox única con dos piernas y torso que deja corredor central de 1,75 m. Ver `BEE_SHMUP_WORLD_SCALE_HUMAN_POC.md`; la lectura y el ritmo finales requieren playtest humano. |

Capturas de verificación: `dev/organic_alien_review/alien_runtime.png`, `alien_windup.png`, `alien_lunge.png`; `dev/playtest_polish_01/probe_reticle.png`, `bee_in_hollow_log.png` y `dev/ground_threat_review/turret_windup.png`. Los valores anteriores del enemigo (HP 35, windup 0,65 s, lunge 7,2 m/s por 0,38 s, daño 13, recovery 0,75 s) permanecen intactos.

**Validación:** Organic Alien específico en headless y con render, tronco específico en ambos modos, Ground Threat y Air Variety con render, carga directa headless de los dos POC afectados y carga directa gráfica de Organic Alien: código 0, sin errores relevantes. Suite Bee completa: **15/15**, incluido el nuevo test del túnel; ninguna regresión observada. La percepción de ritmo, legibilidad durante juego continuo y comodidad del túnel siguen requiriendo playtest humano.
