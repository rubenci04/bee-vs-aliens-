# Controles

| Acción | Teclado / mouse | Xbox 360 |
|---|---|---|
| Mover | WASD / flechas | Stick izquierdo |
| Apuntar | Mouse; tras 1,5 s quieto vuelve el autoapuntado | Stick derecho; al soltar vuelve autoapuntado |
| Disparar / mantener fuego automático | X / clic izquierdo | A / RT (umbral 0,3) |
| Bomba / detonar | C | X |
| Pirueta | Shift | B / LB |
| Aguijón 360° | Z | Y / RB |
| Pausa | Esc | Start |
| Navegar menú / ajustar volumen | Flechas | Cruceta / stick izquierdo |
| Aceptar / volver de pausa | Enter / Esc | A / B |
| Reiniciar tras derrota | R; Shift+R reinicio total | Y |
| Cono de ayuda / objetivo elegido (debug) | F4, apagado al iniciar | — |

Zona muerta de ambos sticks: 0,2. El autoapuntado elige el enemigo hostil más cercano dentro del cono frontal y del rango; sin blanco apunta hacia adelante. Mouse conserva puntería libre al moverse. Los dispositivos se escuchan sin restringir su índice y admiten reconexión: aparece «Mando detectado: nombre» por 3 s. Vibración breve al recibir daño; interruptor `BeeGameSettings.vibration_enabled` (botón en título).

El HUD actualiza los nombres de disparo, bomba y pirueta al último teclado/mouse o mando usado.

Mantener fuego ahora dispara continuamente: Base cada 0,1333 s y el abanico Spread cada 0,4 s; soltar corta sin completar ráfagas. La retícula permanece visible, tenue sin apuntado manual, y marca la dirección real corregida. La ayuda suave actúa dentro de 12° y prioriza implantes vulnerables; no selecciona enemigos fuera de pantalla ni invulnerables. Ajustes de esta tanda en `scripts/game/bee_shooting_settings.gd`.

Pirueta: 0,35 s de invulnerabilidad, rompe proyectiles comunes y redes en vuelo; no destruye ondas ni rayos. Impulso de 3 m si se está moviendo; espera 1,2 s. Aguijón: siempre disponible con intervalo de animación de 0,35 s, daño 30. Una red que ya atrapó a Bee mantiene su restricción de movimiento y habilidades; disparar / pulsar movimiento la rompe.
