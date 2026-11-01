# Tanda X — ritmo, momentos y final

- Base: `tanda-w-mundo-responde` (`2107288`). Rama: `tanda-x-ritmo-final`. Es la «W» del doc del Plan 2: la T nueva corrió las letras una.
- **No cambió la vida ni el daño de ningún jefe.**

## Paso 1: datos (con bot, porque no hubo partidas de Rubén)
- El plan pedía tres `director_log.txt` tuyos; Rubén pidió seguir sin ellos. En su lugar, tres corridas de `dev/tanda_x/measure_run.gd` (semillas 1, 2 y 3).
- Cómo juega el bot: vuela en el tercio izquierdo, dispara, tira bomba con 4 o más enemigos y usa el Enjambre apenas se llena. **No esquiva**: no refleja a un jugador.

| Corrida | Llega al robot | Zonas (s) | Pausas sin enemigos > 4 s | Vida mín. | Bombas | Enjambres | «Muertes» | Liberados |
|---|---|---|---|---|---|---|---|---|
| 1 | 356 s | 25 / 25 / 25 | 1 (X=151) | 27 | 17 | 10 | 2 | 342 |
| 2 | 355 s | 25 / 25 / 25 | ninguna | 29 | 17 | 10 | 2 | 336 |
| 3 | 349 s | 25 / 25 / 26 | 1 (X=235) | 27 | 17 | 10 | 2 | 351 |

## Paso 2: un momento especial por acto (`bee_level_01_set_pieces.gd`, `bee_moment_settings.gd`)
- Acto 1: la regadera, que ya existía.
- **Acto 2 (X=165): gotas de rocío durante 10 s.** Cada gota brilla 0,6 s colgada de la hoja y después cae recta; hace 3 de daño.
- **Acto 3 (X=244,5): la cortadora de césped durante 8 s.** Pasa al fondo, sacude la pantalla y tira pasto cortado por abajo.
  - Primero aparece el cartel «¡VOLÁ ALTO!» y la franja de pasto se marca durante 1,2 s.
  - Después, cada 0,7 s, lastima con 4 de daño a quien esté por debajo de 2,6 m.
- Cada momento espera el campo limpio y frena la tabla mientras dura: no hay enemigos.
- Cada uno tiene su interruptor: `MOMENT_DEW_ENABLED`, `MOMENT_MOWER_ENABLED`.

## Paso 3: pantalla de resultados
- Arriba aparece Bee girando con cara contenta, en su propia ventanita 3D.
- Debajo, de a una cada 0,35 s: tiempo, liberados, puntaje, mejor combo, bombas, enjambres y golpes recibidos.
- El rango llega último, con un golpe de sonido y un «pum» de escala.
- Bee ahora cuenta las bombas que tira (`bombs_used`); solo cuenta, no cambia nada.

## Paso 4: título
- Bee 3D aletea en un ocho lento, abajo, junto a las hormigas. No tapa la abeja pintada del fondo ni el menú, y no recibe clics.

## Paso 5: ajustes con los números
- `SWARM_CHARGE_NEEDED` sube de 25 a **60**.
  - Con 25, el Enjambre salía 10 veces por partida (unos 340 liberados con el bot; en tu video liberaste 368), cada ~35 s, y dejaba de ser especial.
  - Con 60 sale unas 5 o 6 veces, más o menos una por acto.
- Nada más:
  - Las zonas duran 25–26 s, lo que el diseño pide.
  - Casi no hay pausas vacías: como mucho una de 4 s por corrida.
  - Bombas, vida y «muertes» del bot no sirven para ajustar, porque el bot no esquiva.

## Pruebas y cómo probar
- Test nuevo: `validate_bee_tanda_x`. Cubre los momentos en la tabla, el aviso de las gotas, la cortadora (alto no lastima, bajo sí), los textos de la pantalla final, el rango al final y Bee volando en el título.
- Núcleo: 154/154 sin `SCRIPT ERROR`, a la primera.
- Capturas con ventana en `dev/tanda_x/` (no van al repo).
- Cómo probar: Godot, F5.
  - En el título, Bee vuela abajo.
  - Al jugar: en el macizo caen gotas (esquivalas por el brillo) y en la huerta pasa la cortadora (volá alto).
  - Al ganar, mirá las estadísticas aparecer de a una.
