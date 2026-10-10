# CAMERA FP SPIKE — ¿lateral, persecución o primera persona?

Rama `camera-fp-spike`. Experimento aislado en `dev/camera_fp_spike/`: no toca Level 01 ni ningún script suyo
(solo reutiliza `BeeLevel01VisualTarget`, los visuales de abeja/avispa/sonda/eye drone y `BeeLevel01Framing` en lectura).

## Cómo probarlo
- Abrir `res://dev/camera_fp_spike/camera_fp_spike.tscn` y F6. **1/2/3** = vista A / B / C. WASD o flechas mueven, **X** dispara (auto-apuntado).
- Avance automático a 6 m/s sobre el Visual Target (mismo sol, niebla, suelo, tallos, flores; decoración duplicada en espejo para tener tallos a ambos lados).
- 3 enemigos reales en estilo C (avispa, sonda, eye drone) con IA apagada y comportamiento mínimo (avispa se lanza en picada, sonda/drone se quedan a 9-12 m y disparan orbes magenta).
- Capturas (mismo momento, t = 6,0 s de un vuelo con input guionado): `A_lateral.png`, `B_persecucion.png`, `C_primera_persona.png`.
  Regenerar: `godot --path . --resolution 1152x648 --script res://dev/camera_fp_spike/capture_views.gd -- 6`
- **Limitación honesta:** juzgo por las capturas y por correr la simulación; no pude jugarlo con teclado. El "cómo se siente" es lectura visual, no playtest. El playtest del dueño manda.

## Cómo se ve y juega cada vista
- **A lateral (preset D, referencia):** abeja grande y legible (silueta + rim del estilo C), enemigos identificables de un vistazo, hierba/tallos gigantes dan la escala "bicho en jardín enorme". Todo ocurre en un plano: se esquiva leyendo X/Y.
- **B persecución:** se ve la abeja de espaldas con alabeo/cabeceo y la retícula adelantada; los tallos forman un corredor que da sensación de velocidad y profundidad real. Costos: la abeja se ve ~3x más chica, los enemigos son puntitos a 12-30 m (a 12 m una sonda ocupa ~35 px), y el suelo naranja domina la mitad inferior de la imagen. Sin auto-apuntado sería injugable; con él funciona.
- **C primera persona:** máxima inmersión (balanceo al moverse, retícula, bracket de auto-apuntado). Pero se pierde el personaje: la abeja con implante, que es el gancho, deja de verse. Enemigos aún más chicos; los orbes vienen "a la cara" y son difíciles de leer. Riesgo de mareo con balanceo + FOV 78°.
- Niebla (14-55 m) y tamaño de enemigos están afinados para ~10 m de profundidad visible: en B/C habría que re-afinar ambos.

## Qué se gana / qué se pierde
- Gana: profundidad real, amenazas de frente, jefe que "crece" hacia el jugador, patrones tipo Star Fox, sensación de velocidad.
- Pierde: composición lateral "abeja minúscula vs mundo gigante" (humano cruzando, escala de tallos), silueta del personaje, lectura de formaciones horizontales, aguijón (Z) con sentido, amenazas de suelo (torreta, caminante), araña vertical.
- Hallazgo del experimento: la decoración actual está hecha para UNA cámara. Las cabezas de flor son discos planos orientados a +Z (de frente se ven como lajas crema), las hojas de primer plano y los montículos están colocados para el encuadre lateral.

## Qué habría que rehacer para B y C
| Sistema | Qué cambia | Esfuerzo |
|---|---|---|
| Movimiento/límites (`bee_player.gd`, 290 l) | plano z=0 y ventana en X relativa a la cámara → ventana Y/Z, inclinación | medio |
| Apuntado y disparos | auto-aim 2D (12 m), proyectiles ±X, hitboxes finos en Z → apuntado 3D, retícula, hitboxes con profundidad | medio |
| Spawns y patrones (`bee_level_01_controller.gd` 600 l, 7 familias + dragonfly/swarm/spider, `cinematic_depth_entry`) | todo nace por el borde derecho, en alturas Y, formaciones en X → reescribir entradas y patrones en profundidad (el director por distancia sí sirve) | grande |
| Jefe UFO (599 l) | patrones y telegraphs laterales | grande |
| Humano gigante (en pausa) | cruce lateral y close-up diseñados para el plano | grande |
| Decoración (`visual_target` 454 l + domestic/living garden) | segundo pase: flores orientadas, corredor, sin truco de "primer plano bajo la pantalla" | medio-grande |
| HUD | retícula, bracket, dirección del daño, barra de jefe; armas/bombas | chico-medio |
| Checkpoint | ya es por distancia X (190 m) → casi intacto | chico |
| Framing + tests | `BeeLevel01Framing` (99 l) lo usan 17 scripts; 25 de las 40 suites asumen X/Y/cámara lateral → adaptar ~15 | medio |
| Arte | en C la abeja no se ve (arte hecho para no usarse); enemigos de frente necesitan lectura frontal | medio |

**Esfuerzo total:** B = **grande** (varias de las tareas anteriores juntas). C = **grande+** (B + perder el personaje + antimareo).
Un tramo B aislado (bonus / sección en rieles reutilizando el spike) = **medio**.

## Riesgos
- Alcance: contradice la fase actual (cierre del core + dirección de arte); reabre 7 familias, jefe y 25 suites ya estables.
- Identidad: el gancho es ver a la abeja pequeña frente a la guerra gigante; C lo oculta, B lo diluye.
- Legibilidad: enemigos y proyectiles pequeños en profundidad; exige escalarlos o acortar distancias.
- Rendimiento: más geometría y fog lejano visibles a la vez (no medí FPS; Compatibility). Mareo en C.

## Recomendación
**Quedarse en la vista lateral para el juego principal.** No cambiaría el juego a primera persona: el costo es el de rehacer casi todo
y lo que se gana (profundidad) compite con lo que hoy define al juego. **C no vale la pena** ni como modo.
Si el dueño quiere probar profundidad, **hacerlo como modo/tramo aparte con la vista B** (p. ej. un tramo en rieles antes del jefe o un nivel
corto), reutilizando este spike como base. Condición: que el playtest de `camera_fp_spike.tscn` confirme que B se siente bien con enemigos más grandes y la niebla re-afinada.
