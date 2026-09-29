# Bee Mission 01
Escena independiente heredada de Garden, 30 m, mismo escenario y actores.
Flujo local: INTRO → POLLEN → WASP → POLLEN → ANOMALY → PROBE → REVEAL → COMPLETE.
Tres pickups originales: contador y curación de 20 HP coexisten.
La Wasp se activa con el segundo polen. La anomalía exige 3/3 y Wasp derrotada.
La Probe aparece al terminar el aviso de señal, desde su posición superior/lateral.
Mensajes de 2 s: señal desconocida, origen desconocido, transmisión interrumpida,
pregunta final. Tres luces cian distantes aparecen durante la revelación.
HUD: HP, objetivo, polen y controles. Final único: MISIÓN 01 COMPLETA.
Cámara BeeArcadeCamera y balance originales. Sin checkpoint ni progresión global.
Implante de Bee intacto: se eligió parpadeo cian del mensaje, sin alterar BeeVisual.

Abrir scenes/bee_prototype/bee_mission_01.tscn y F6.
WASD/flechas: vuelo; Z: melee; X: disparo; R tras derrota reinicia todo.
Test: tests/bee_prototype/validate_bee_mission_01.gd. Usa vuelo y disparo por input,
recoge pickups por colisión, mata enemigos con proyectiles y recarga con R.
La derrota se fuerza por daño en el test después de completar la misión.

Duración objetivo: 3–5 min para primera experiencia. Aún no acreditada.
Recorrido automatizado eficiente headless: aproximadamente 12 s hasta completar.
El disparo actual permite resolver ambos enemigos muy rápido; no se cambió.
Esta V01 acredita el loop completo, pero requiere playtest humano cronometrado
para evaluar duración, comprensión y legibilidad. Sin espera artificial,
assets nuevos, cinemáticas ni audio. Decoración generada al ejecutar como Garden.

Cierre técnico: test específico headless y con render aprobados, arranque directo
de escena código 0, suite 41/41 sin regresiones. Captura mission_complete.png.
Recorrido gráfico automatizado completo: 12–13 s, sin inyectar HP a enemigos.
No se acredita aún el objetivo de duración 3–5 min: requiere evaluar y diseñar
el ritmo jugable antes de considerar aprobada esa parte de Mission 01.
