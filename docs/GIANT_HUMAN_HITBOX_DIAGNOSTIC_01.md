# GIANT HUMAN HITBOX DIAGNOSTIC 01

Solo diagnóstico. No se tocó ninguna hitbox, daño ni movimiento del humano.

## Herramientas (en el juego real, Level 01)
- **Tecla H**: muestra/oculta las hitboxes del humano como volúmenes semitransparentes con su nombre (LeftThigh rojo, LeftLeg naranja, RightThigh amarillo, RightLeg verde, Torso violeta) y la hurtbox de Bee (cian). Un panel de texto lista cada forma (ON/off) con sus límites x/y/z.
- **Daño a Bee**: aparece 2 s `DAÑO: <hitbox>, posición de Bee x/y/z` y se escribe una línea en `dev/logs/giant_human_damage.log` (ignorado por git) con: hitbox culpable según el motor (`area_shape_entered`), Bee menos humano en X, posición del humano y de la cámara, tiempo de la animación, distancia del centro de Bee a cada forma activa y los límites de todas las formas. Los golpes del humano a otras cosas (p. ej. la caja `HumanAreaCrate`) se registran como `OTHER_HIT` sin mensaje en pantalla.
- Código: `scripts/levels/giant_human_hitbox_debug.gd` (nodo `HumanHitboxDebug` en el nivel). Solo lee; se puede quitar el nodo sin efectos.
- Sondas de desarrollo: `dev/diagnostics/human_approach_probe.gd` (headless), `human_ghost_probe.gd`, `capture_human_hitboxes.gd`.

## Qué se midió (sonda de aproximación, 21 intentos)
Bee vuela hacia +X a su velocidad real (7 m/s) a 7 alturas y 3 momentos de salida, con el nivel corriendo.
- **18 de 21 intentos reciben 20 de daño**, 12 de `LeftLeg`/`RightLeg` y 6 de `LeftThigh`/`RightThigh`, siempre con Bee a -1.4..-3.6 m del centro del humano, es decir **antes** de llegar a la columna "segura" de ±1.2 m.
- En 9 golpes a alturas 1.4–2.6 m, el centro de Bee estaba entre 0.14 y 0.70 m del cuerpo **visible** (silueta real de la malla animada, proyectada desde la cámara) y en 3 de ellos a más de 0.3 m (hasta 0.70): daño con espacio visible libre. Ver `dev/diagnostics/human_hitbox_view.png` y `human_hitbox_damage.png`: el volumen verde/naranja de cada pierna es un cuña que rellena el hueco visible junto a la pierna.

## Por qué el test no lo detectó
1. `validate_bee_giant_human_corridor_v01` **teletransporta a Bee cada frame a x = humano ±0.6**, dentro de la columna de ±1.2 m donde el código fuerza que las piernas no dañen. Probaba "una Bee ya dentro de la columna no recibe daño" (verdadero por construcción), no "Bee puede llegar a la columna".
2. En el juego el humano avanza a 2.6 m/s hacia Bee: para entrar a la columna hay que cruzar antes la zona de la pierna delantera (-1.2 .. -2.6 m), y ahí está el daño. El test nunca recorre ese camino.
3. Cada hitbox es el **casco convexo** de la pantorrilla+pie (o del muslo) proyectado. Una pierna inclinada o con la rodilla doblada deja huecos visibles dentro del casco. El test solo comparaba las formas con la columna central y con el fondo del torso, nunca con la silueta visible.
4. Las poses/alturas probadas eran pocas (pose congelada y 4 alturas centradas), sin variar el momento de entrada.
