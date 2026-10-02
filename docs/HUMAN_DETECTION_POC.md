# Human Detection POC

Escena aislada: `res://scenes/bee_prototype/human_detection_poc.tscn` (F6). No integración con Mission 01. Bee usa su controlador actual, con escala uniforme 0,45 sólo en esta escena para leer al humano proxy de 1,75 m como gigante. Un árbol, helecho y botella provienen exclusivamente de los assets ya aprobados.

| Estado | Sospecha | Feedback |
|---|---:|---|
| IDLE | 0–34 | ropa azul grisácea |
| NOTICE | 35–69 | `?`, color ocre |
| ALERT | 70–99 | `!`, color naranja; mira a Bee |
| HOSTILE | 100 | `!`, rojo; hostilidad permanente hasta reiniciar |

Visión: 10 m, cono horizontal de 90° sobre el plano de vuelo, comprobación de línea de visión con raycast contra Bee y obstáculos sólidos. El muro del POC permite demostrar oclusión. Bee visible: +15 sospecha/s; fuera de visión: −10/s. Disparo X aceptado y visible: +25; melee Z aceptado y visible: +8. Acciones sólo cuentan si el observador puede ver a Bee. El contador se muestra únicamente al detectar o mantener sospecha. `show_vision_debug` permite ocultar el cono amarillo semitransparente.

HOSTILE: manotazo de corto alcance (2,3 m), anticipación visual roja 0,65 s, hitbox activa 0,18 s, recuperación 0,9 s, daño 20 HP. El humano no tiene Health/Hurtbox ni es objetivo de auto-aim: X/Z de Bee y proyectiles de Probe no pueden dañarlo. Probe se activa al avanzar hasta X≥3. Derrota de Bee: R recarga toda la escena y restaura humano, Probe y HP.

Limitaciones: proxy sin arte/animación final, visión frontal simple sin memoria global, sin interacción entre Probe y humano, sin integración en Mission 01. El POC sirve para comprobar si el combate bajo observación resulta interesante, no para decidir todavía balance de sigilo. Test específico y suite Bee: 8/8. Captura de referencia: `dev/human_detection/poc_view.png`.
