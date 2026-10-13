# Informe Lote 15 — Etapas 5 y 6

Rama `lote-14` (sin commit). Etapa 5: robot caminante y tarántula más dinámicos. Etapa 6: solo documento (`docs/ROADMAP_ARMAS.md`).

## Regla común (5.1)
- **Cada fase tiene al menos un ataque apuntado a Bee** (robot: ráfaga del cañón, morteros sobre su columna, láser centrado en ella, salto a su columna; tarántula: abanico, red, escupitajos al moverse, arañitas sobre su columna, embestida).
- **No se subió el daño por golpe**: las balas siguen en 3, pisotón 8, embestida 10, arañita 5, contacto 8. Lo que cambió es cómo se mueven y atacan.
- **Bot quieto** (nuevo, en los dos tests): estacionado en la esquina **superior izquierda** y en la **inferior izquierda**, nunca se mueve, dispara igual que el experto. En Normal tiene que perder **≥ 40**.

## 5.2 Robot caminante (`scripts/levels/walker_miniboss.gd`)
- **Cruza toda la pantalla** (`stride`, de un lado a 1,6 m del otro borde; tramo más largo medido ≈ 11 m) y **salta con aviso** a la columna de Bee (agacharse + sombra en el suelo + columna roja 0,75 s; si Bee está encima salta al otro lado). Al caer: golpe de aterrizaje (8) y ondas por el suelo.
- **Ráfaga apuntada** del cañón (línea fija 0,5 s, 3 tiros de 6), **morteros** (3 sombras: columna de Bee y ±2,4 m, 0,85 s de aviso, caen en vertical), **barrido láser del ojo amarillo** (dos líneas amarillas marcan el sector ±20° centrado en Bee 0,6 s, después el rayo lo barre en 0,7 s; daño 6, no es proyectil), pisotón con banda.
- **Cañón rompible** (vida 70 → 110 para que con Spread alcance a disparar): al romperlo se acaban la ráfaga **y** los morteros; quedan láser, salto y pisotón. **Ojo ×2** igual que antes.
- Patrón con cañón: cañón · morteros · cruce · láser · salto · cañón · morteros · cruce · láser · pisotón. Sin cañón: cruce · láser · salto · láser · pisotón · cruce · salto. Tope de DPS del cuerpo 0,039 → 0,032.

| Robot | Experto: duración / vida perdida | Quieto arriba-izq. | Quieto abajo-izq. |
|---|---|---|---|
| Normal Base | 42,3 s / 55 | 105 | 270 |
| Normal Spread | 34,6 s / 27 | 94 | 160 |
| Fácil Base | 36,8 s / 37 | 68 | 118 |
| Fácil Spread | 32,8 s / 13 | 45 | 80 |

(La vida perdida incluye a los escoltas. Meta 30-45 s con Base y Spread: cumple.)

## 5.3 Tarántula (`scripts/levels/tarantula_boss_01.gd`, `scripts/levels/tarantula_web_net.gd`)
- **Se mueve en todas las direcciones**: en el suelo **acecha** hacia la zona de Bee (se frena a 3,2 m de ella); **salta en diagonal de una esquina a la opuesta** (suelo ↔ techo) con banda roja sobre el recorrido + sombra de aterrizaje (0,8 s); **trepa por el borde superior** cabeza abajo siguiendo a Bee desde arriba (el implante queda mirando hacia abajo); desde el techo **baja colgada de un hilo** (el hilo se dibuja antes, 0,6 s) y **se balancea en péndulo** (±29°, 3 s) disparando, y vuelve a subir. Cuando un movimiento necesita la otra superficie, primero salta.
- **Red que atrapa** (`TarantulaWebNet`): línea blanca de la boca a Bee **0,5 s** (se fija al final), luego vuela la red. Si toca a Bee: **pegada hasta 2 s**, puede disparar pero no moverse, ni pirueta ni aguijón. Se libera **disparando** (cada toque o ráfaga rompe un pedazo: 4 en Normal, 3 en Fácil) o **apretando las teclas de movimiento** (8 en Normal, 6 en Fácil); se pueden combinar. Después: **1,5 s de gracia** en que ninguna red la atrapa. La pirueta rompe una red en vuelo. Si la red atrapa, la tarántula lanza enseguida un abanico apuntado con su aviso normal: liberarse rápido lo evita.
- **Escupitajos**: mientras acecha o trepa, un tiro suelto apuntado cada 0,9 s (la boca brilla 0,45 s antes). Así moverse no es descansar.
- Ataques: abanico apuntado, red, lluvia de arañitas, embestida, pisotón (y el aterrizaje del salto). **Furia**: combinaciones de dos ataques esquivables — salto + abanico, embestida + arañitas, péndulo + dos abanicos — y la cortina.
- Se mantienen: **implante ×2** (se expone tras pisotón, embestida, péndulo y salto desde la fase 2), patas blindadas, **tope de daño por segundo** (0,013 → 0,0095 Normal, 0,0115 → 0,009 Fácil, para la duración pedida), miel en la fase 3, moscas en la fase 2 y la **liberación final**.

| Tarántula | Experto: duración / vida perdida | Quieto arriba-izq. | Quieto abajo-izq. |
|---|---|---|---|
| Normal Base | 89,9 s / **62** | 245 | 193 |
| Normal Spread | 98,3 s / **71** | 212 | 153 |
| Fácil Base | 89,9 s / 38 | 168 | 122 |
| Fácil Spread | 94,7 s / 44 | 167 | 118 |

Metas: duración 80-110 s (cumple las 4), experto Normal 55-75 (62 y 71), Fácil duele menos (sí), quieto ≥ 40 (mínimo 118). Antes (Lote 14): 71-84 s y el experto perdía 24-49.

**Ojo:** el bot experto esquiva perfecto todo lo grande (saltos, péndulo, embestidas): su daño viene de las balas. Una persona va a recibir más golpes grandes; si en el playtest la tarántula se siente injusta, la perilla es `SPIT_EVERY` (escupitajos) o `HANG_SWING` (duración del péndulo), no el daño.

## Tests
- `validate_bee_tarantula_boss_v01` reescrito: estructura, reglas de la pirueta (también rompe la red), **red** (atrapa, no se mueve, puede disparar, 4 disparos la rompen, gracia sin encadenar, 8 teclas la rompen, se suelta sola a los 2 s), **movimientos** (suelo/salto/techo en la fase 1, implante adentro de pantalla y mirando abajo en el techo, péndulo adentro de pantalla) y 12 peleas (experto + 2 esquinas × Normal/Fácil × Base/Spread).
- `validate_bee_walker_miniboss_v01`: estructura con los ataques nuevos (al romper el cañón no hay más ráfaga ni morteros y el láser sigue) y 12 peleas; exige que cruce la pantalla (≥ 8 m), que esté en los dos lados y que use salto, láser, morteros y ráfaga.
- Herramientas: `dev/lote15/tarantula.sh` y `dev/lote15/walker.sh` (modo reporte; argumentos `first`, `expert`, `trace`).
- `bee_player.gd`: estado `web_locked` (sin moverse, sin pirueta, sin aguijón), `web_struggles`, `fire_trigger_count`.

## Falta de arte
- **Red**: hoy es un anillo blanco con 3 hebras (código). Falta una red/capullo modelado y una animación de forcejeo de Bee.
- **Tarántula**: no tiene animación de salto, de colgarse ni de caminar cabeza abajo (se reusa `walk`/`idle` rotando el modelo); el hilo es una línea.
- **Robot**: sin animación de salto ni de lanzar morteros; los morteros son esferas cian; el láser es una barra amarilla.
- Sombras de aviso: discos planos oscuros.

## Qué probar jugando
F5 → Jugar Nivel 01 (o F6 en la escena del nivel; con el checkpoint 2 se llega antes).
- **Robot**: que cruce toda la pantalla y te obligue a pasar por arriba; que el salto caiga donde estabas (mirá la sombra); salir de las columnas de los morteros; salir del sector amarillo del láser; romper el cañón con el mouse.
- **Tarántula**: el salto de esquina a esquina (banda roja), cuando trepa por arriba y te sigue, el péndulo (alejarse o pasar por debajo), la **red** (línea blanca: moverse cuando se fija; si te atrapa, disparar y apretar las flechas/WASD), los combos de la furia. Comprobar que nunca te atrapa dos veces seguidas.
- Que el jefe se sienta dinámico y no "más difícil": si una fase quita demasiada vida, decirlo con la fase y el ataque.
