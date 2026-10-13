# Roadmap de armas (diseño; no implementado)

Diseño de Rubén (Lote 15, etapa 6), con propuesta de teclas y reglas. Solo documento: nada de esto está en el juego salvo el aguijón.

## Qué hay hoy
| Acción | Tecla | Estado |
|---|---|---|
| Disparo Base (tocar = 1 tiro, mantener = ráfagas) | X / clic izquierdo | hecho |
| Aguijón metálico 360° (cuerpo a cuerpo) | Z | hecho (Lote 14, etapa 1) |
| Alien Bomb (lanzada, radio 3 m, máx. 3) | C | hecho |
| Pirueta (0,35 s invulnerable, recarga 2,5 s) | Shift | hecho |
| Spread (potenciador temporal del disparo Base) | pickup | hecho |

## Armas nuevas
- **Escudo explosivo** — 2 cargas por vida/checkpoint. Al activarlo: onda de ~2,5 m que daña (≈ 20) y **destruye las balas comunes** alrededor, y Bee queda protegida **~2 s** (burbuja visible). Las ondas de pisotón, embestidas y láseres **no** se destruyen (misma regla que la pirueta), pero la burbuja sí la protege de ellos.
- **Láser** — se destraba al terminar el Nivel 1. Rayo continuo mientras se mantiene el disparo, poco daño por segundo pero atraviesa enemigos; bueno contra filas y blindajes "de frente".
- **Misiles** — se destraban al terminar el Nivel 2. Pocos, lentos, teledirigidos al objetivo marcado; mucho daño a un solo blanco (jefes, partes rompibles).
- **Tercera arma** — se destraba al terminar el Nivel 3 (a definir; sugerencia: "enjambre" de mini-abejas que orbitan y bloquean balas).
- **Mega disparo** — **pendiente de definir con Rubén**. Dos opciones:
  - A) *Carga*: mantener el **clic derecho** ~1 s y soltar = disparo grande. Va en el clic derecho porque el izquierdo ya usa "mantener = ráfagas".
  - B) *Ligado a FRENESÍ*: al llegar al combo x8, en vez de (o además de) los 6 s de disparo doble, un toque de **F** suelta el mega disparo.
  - Recomendación: B (no agrega otra mecánica de carga y premia jugar bien).

## Llevar hasta 3 armas
- Base siempre está; Bee lleva **hasta 3 armas** equipadas (Base + 2 destrabadas). Se eligen en una pantalla de **equipo** antes de cada nivel.
- Cambio de arma: **1 / 2 / 3** (directo), **Q / E** o **rueda del mouse** (siguiente/anterior). Cambio instantáneo, sin recarga, con el nombre del arma 1 s en el HUD.
- Spread sigue siendo un potenciador del arma **Base** (pickup); no ocupa lugar.

## Convivencia con lo que ya existe
| | Tecla | Rol | Regla |
|---|---|---|---|
| Disparo del arma elegida | X / clic izq. | daño principal | cada arma con su forma de mantener |
| Aguijón | Z | cuerpo a cuerpo, sin munición | igual en todas las armas |
| Alien Bomb | C | ataque de área **lanzado** (ofensivo) | cargas propias (máx. 3) |
| Escudo explosivo | **V** | defensa **alrededor de Bee** (pánico) | 2 cargas; no se usa atrapada en la red |
| Pirueta | Shift | esquive de movimiento | su invulnerabilidad **no se suma** a la del escudo |
| Mega disparo | clic der. o F | ver arriba | — |

- Bomba = "despejar adelante", escudo = "salvarme acá": por eso conviven en lugar de fusionarse. Si en el playtest sobran botones, la alternativa es dejar una sola tecla especial (C) y elegir bomba o escudo en la pantalla de equipo.
- Red de la tarántula: atrapada se puede disparar con cualquier arma (cada disparo rompe la red); escudo, pirueta y aguijón no.

## Cómo se guarda el progreso
- Un archivo chico `user://progreso.cfg` (`ConfigFile`): niveles terminados, armas destrabadas, armas equipadas y dificultad elegida. Se escribe al terminar un nivel y al cambiar el equipo; nada a mitad de nivel.
- Sin ranuras de guardado ni guardado en medio del nivel (sigue fuera de alcance). "Borrar progreso" en el menú de opciones.
- Para probar: un atajo de desarrollo que destraba todo (solo en el editor).

## Orden sugerido para implementar (una tarea por lote)
1. Cambio de armas (1/2/3, Q/E, rueda) + HUD, con Base y Láser. 2. Archivo de progreso + pantalla de equipo. 3. Escudo explosivo. 4. Misiles. 5. Mega disparo (cuando Rubén elija A o B). 6. Tercera arma.
