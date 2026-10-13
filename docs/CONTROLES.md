# Controles

| Acción | Teclado / mouse | Xbox 360 |
|---|---|---|
| Mover | WASD / flechas | Stick izquierdo |
| Apuntar | Mouse; tras 1,5 s quieto vuelve el autoapuntado | Stick derecho; al soltar vuelve autoapuntado |
| Disparar / mantener ráfagas | X / clic izquierdo | A / RT (umbral 0,3) |
| Bomba / detonar | C | X |
| Pirueta | Shift | B / LB |
| Aguijón 360° | Z | Y / RB |
| Pausa | Esc | Start |
| Navegar menú / ajustar volumen | Flechas | Cruceta / stick izquierdo |
| Aceptar / volver de pausa | Enter / Esc | A / B |
| Reiniciar tras derrota | R; Shift+R reinicio total | Y |

Zona muerta de ambos sticks: 0,2. El autoapuntado elige el enemigo hostil más cercano dentro del cono frontal y del rango; sin blanco apunta hacia adelante. Mouse conserva puntería libre al moverse. Los dispositivos se escuchan sin restringir su índice y admiten reconexión: aparece «Mando detectado: nombre» por 3 s. Vibración breve al recibir daño; interruptor `BeeGameSettings.vibration_enabled` (botón en título).

El HUD actualiza los nombres de disparo, bomba y pirueta al último teclado/mouse o mando usado.

Pirueta: 0,35 s de invulnerabilidad, rompe proyectiles comunes y redes en vuelo; no destruye ondas ni rayos. Impulso de 3 m si se está moviendo; espera 1,2 s. Aguijón: siempre disponible con intervalo de animación de 0,35 s, daño 30. Una red que ya atrapó a Bee mantiene su restricción de movimiento y habilidades; disparar / pulsar movimiento la rompe.
