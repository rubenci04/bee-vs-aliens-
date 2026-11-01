# Tanda W — el mundo responde

- Base: `tanda-v-enjambre` (`ebf73b5`). Rama: `tanda-w-mundo-responde`. Es la «V» del doc del Plan 2: la T nueva corrió las letras una.
- **No cambió la vida ni el daño de nada.**

## A. Liberación visible (`bee_release_animation.gd` reusado, constantes en `bee_release_settings.gd`)
- El insecto recupera su color, el implante salta y explota chiquito (chispa cian y un estallido).
- Después da una vuelta alrededor de Bee en 0,6 s. No estorba ni hace daño: sus colisiones ya estaban apagadas.
- Recién entonces se va volando al fondo y se desvanece (0,6 s).
- Uno de cada 4 liberados deja un grano de polen (`POLLEN_DROP_EVERY`).
- Interruptor de la vuelta: `LAP_ENABLED`.
- Los jefes (tarántula y robot) no dan la vuelta: se van como antes. Una tarántula gigante orbitando a Bee quedaba absurda; lo detectó la prueba `t4f`.

## B. Escenas cortas (`bee_story_beats.gd`, `bee_story_settings.gd`, interruptor `STORY_BEATS_ENABLED`)
- Duran de 2,4 a 2,6 s. Mientras corren, el juego está en pausa y hay barras negras arriba y abajo.
- Cualquier tecla, botón o clic las saltea. Durante la escena, Esc y R no abren la pausa ni reinician.
- Las tres escenas:
  1. **Al empezar:** el implante chispea, Bee sacude la cabeza y pasa de cara neutra a concentrada.
  2. **El robot entra en pantalla:** la cámara se abre un 12 %, Bee traga saliva con cara de sorpresa y dice «Uh...».
  3. **La tarántula entra:** Bee mira para arriba, a las telarañas, y dice «¡Arañas no!».
- Cada una sale una vez por partida. Un reintento desde checkpoint no la repite; un reinicio total o volver a jugar desde el título, sí.
- Las frases de jefe de la Tanda U quedan apagadas mientras haya escenas, para que no se dupliquen.
- En modo headless (pruebas y bots) no se disparan solas (`auto_in_headless`), así no frenan a los bots. El test las llama a mano.
- La duración se mide con el reloj real, no con el reloj del juego.

## C. Carteles de jefe
- Al terminar la escena del jefe aparece un cartel de 1,5 s, al 30 % del alto de la pantalla, debajo de la barra de vida:
  - «ROBOT CAMINANTE · Minijefe · rompé su cañón y liberá a su escolta»
  - «LA TARÁNTULA · Jefa final · apuntale al implante cuando brilla»
- Interruptor: `BOSS_CARDS_ENABLED`.

## D. Contador único
- El único aviso de liberación es el contador «LIBERADOS n» del HUD, el mismo número que usa la pantalla de resultados.
- Los carteles «LIBERADO» flotantes se apagan (`FLOATING_TEXT = false`), porque ahora la liberación se ve.

## Pruebas y cómo probar
- Test nuevo: `validate_bee_tanda_w`. Cubre el polen cada 4, que no haya carteles flotantes, la vuelta y la salida del liberado, que la escena pause y ponga barras, el salteo con un botón, una sola vez por partida (y el reintento desde checkpoint), y el fin solo con el cartel del robot.
- Se actualizaron 2 suites:
  - `t4f`: la liberación ahora dura 1,2 s (0,6 de vuelta + 0,6 de salida).
  - `tanda_s`: ya no hay cartel «LIBERADO» flotante.
- Núcleo: 153/153 sin `SCRIPT ERROR`, en una sola corrida completa después del último cambio de juego.
- Capturas con ventana en `dev/tanda_w/` (no van al repo). Muestran las barras, la frase «Uh...» y la cara de sorpresa. Pendiente: con el juego en pausa la ventana de captura repite cuadros, así que el cartel del jefe solo quedó verificado en el test, no en una imagen.
- Cómo probar: Godot, F5, Jugar.
  - Al empezar, Bee sacude la cabeza entre barras negras (apretá cualquier botón para saltear).
  - Al liberar, el insecto da una vuelta alrededor de Bee antes de irse, y cada tanto deja polen.
  - Al aparecer el robot y la tarántula hay una escena corta y después el cartel con su nombre.
