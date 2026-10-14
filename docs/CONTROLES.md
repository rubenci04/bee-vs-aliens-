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
| Tamaño visual de Bee (desarrollo) | F5: ×1 / ×1,25 / ×1,4 | — |
| Contorno de Bee y enemigos (desarrollo) | F6: apagado / fino / grueso | — |
| Atenuar fondo lejano (desarrollo) | F7: 0 / 1 / 2 | — |
| Neón de disparos (desarrollo) | F8: 0 / 1 / 2; nivel 2 agranda solo el dibujo 30 % | — |

Zona muerta de ambos sticks: 0,2. El autoapuntado elige el enemigo hostil más cercano dentro del cono frontal y del rango; sin blanco apunta hacia adelante. Mouse conserva puntería libre al moverse. Los dispositivos se escuchan sin restringir su índice y admiten reconexión: aparece «Mando detectado: nombre» por 3 s. Vibración breve al recibir daño; interruptor `BeeGameSettings.vibration_enabled` (botón en título).

El HUD actualiza los nombres de disparo, bomba y pirueta al último teclado/mouse o mando usado.

F5–F8 funcionan con el foco dentro del juego ejecutado desde Godot; en el editor F5/F6 conservan sus atajos de ejecutar proyecto/escena. Los comparadores arrancan en ×1,25 / fino / fondo 1 / neón 1 y muestran sus valores abajo. No están disponibles en exportaciones release; una exportación debug requiere `-- --debug-readability`. Constantes en `scripts/game/bee_readability_settings.gd`.

Mantener fuego dispara continuamente: Base, doble (Frenesí) y triple/Spread cada 0,08333 s (12 descargas/s); tocar usa el mismo daño por proyectil. Spread conserva siempre tres tiros, sin cambiar a un abanico más lento al mantener. Soltar corta de inmediato. La retícula permanece visible, tenue sin apuntado manual, y marca la dirección real corregida. Un aro dorado pequeño sobre el objetivo elegido aparece también con F4 apagado. La ayuda suave actúa dentro de 12° y prioriza implantes vulnerables; no selecciona enemigos fuera de pantalla ni invulnerables. Ajustes en `scripts/game/bee_shooting_settings.gd`.

Pirueta: 0,35 s de invulnerabilidad, rompe proyectiles comunes y redes en vuelo; no destruye ondas ni rayos. Impulso de 3 m si se está moviendo; espera 1,2 s. Aguijón: siempre disponible con intervalo de animación de 0,35 s, daño 30. Una red que ya atrapó a Bee mantiene su restricción de movimiento y habilidades; disparar / pulsar movimiento la rompe.
