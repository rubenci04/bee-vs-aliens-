# Análisis y lista de mejoras — Bee vs Alien

Base: commit `579c3fa` (checkpoint). Godot 4.7.2, GL Compatibility, Intel Arc B580, Ryzen 5 7600, 16 GB.

## Cómo se testeó

- **Núcleo de tests:** 154/154 en verde, sin `SCRIPT ERROR`. Es la línea de comparación de todo lo que sigue.
- **Capturas reales** con ventana, un bot que vuela y dispara, Bee invulnerable (`dev/mejora_visual/qa_capture.gd`): título, 10 puntos del nivel, robot y tarántula. Quedan en `qa_screenshots/base/`.
- **Rendimiento real** a 1920×1080, sin vsync (`dev/mejora_visual/perf_probe.gd`).
- **No se pudo probar:** un mando de Xbox 360 físico (se revisó el código y las acciones, no el aparato) ni si es divertido. Eso último lo decide tu playtest.

## Rendimiento medido antes de tocar nada

| Lugar | FPS medio | Peor 1 % (ms) | Draw calls | Triángulos |
|---|---|---|---|---|
| X=12 césped | 58 | 35 | 1629 | 533 mil |
| X=120 macizo | 62 | 58 | 1503 | 438 mil |
| X=262 sombra | 62 | 55 | 1865 | 627 mil |
| X=294 robot | 66 | 47 | 2006 | 670 mil |
| X=340 tarántula | 78 | 24 | 1849 | 600 mil |

Corre, pero con tirones de hasta 64 ms y una cantidad de draw calls muy alta para este estilo. En una PC más modesta se va a notar.

## Código contra lo que me contaste

| Tema | Lo que dice el código | Qué hago |
|---|---|---|
| «El Nivel 1 es 2D lateral» | Es 3D real con cámara lateral fija, con la jugabilidad en el plano X/Y. | Nada que corregir; cambia la decisión de cámara (abajo). |
| Bee a escala 1,40 | Está en **1,2** (`bee_hero_look_settings.gd`). | **Paso a 1,40**, sin agrandar la hurtbox. |
| Pirueta siempre disponible | Tiene **1,2 s** de espera. | **La bajo a casi nada** (ver decisión en el informe final). |
| Robot de ojo amarillo | Los comentarios dicen amarillo, pero **en pantalla se ve rojo**, y el cuerpo rosado y las patitas no imponen. | **Lo corrijo.** |
| Título «Bee vs Alien» | El logo está bien, pero el proyecto se llama «Bee Alien 3D». | **Lo corrijo.** |
| Sin luciérnagas ni humano gigante | Correcto: están apagados. | Dejo el nodo, pero saco un `print` de depuración que corre en cada partida. |
| Gusanos | Correcto: sin salto ni láser, lanzan bolas lentas hacia arriba. | Nada. |
| Vida según tamaño | Correcto: de 27 a 66 de vida; los lentos tardan 1,25 s con 36 de daño por segundo. | Nada. |
| Liberar, no matar | La regla está bien, pero **se ve mal** por el bug 1. | **Lo corrijo.** |
| Tarántula | Ya tiene redes, avispas y arañas, pero con poca presión. | **La endurezco** sin tocar su vida ni su daño por golpe. |

## Lista priorizada

### Impacto alto

1. **Bug: los insectos liberados se ven como siluetas negras.** Al liberar, el material pasa a transparente; sin escritura de profundidad, el contorno se dibuja encima del cuerpo. Se ve en casi todas las capturas, justo en el momento más festejado del juego.
2. **El nivel se ve siempre igual.** Misma cerca, misma casa, mismas hojas durante 360 m; solo cambia el tinte del cielo. El césped, el macizo, la huerta y la sombra se llaman distinto, pero se ven igual. Es exactamente lo que sentías.
3. **Suelo plano sin vida.** Un plano gris-marrón con parches hexagonales. Ocupa el 20 % de la pantalla y es lo más «prototipo» de la imagen.
4. **Cielo liso.** Un degradé sin nubes, con un disco pálido que parece una luna de día.
5. **Cámara clavada.** El mundo se ve como un telón frente a la cámara y se pierde la gracia de que sea 3D.
6. **Explosiones, impactos y disparos con poco peso.** Hay sistema, pero es chico y discreto. La sacudida de pantalla tiene un tope de 9 cm sobre 14 m de ancho: casi no se siente.

### Impacto medio

7. **Rendimiento.** Bajar los draw calls y los tirones.
8. **Jefes con poca presencia.** El robot se ve débil y rosado al atardecer.
9. **Ritmo.** Casi todo entra igual, por teletransporte: faltan formaciones que crucen la pantalla y momentos de calma con premio.
10. **Tarántula.** Más telarañas que atrapan, avispas y arañas colgando, como pediste.
11. **Puntería con enemigos arriba y abajo.** El apuntado automático elige siempre al más cercano y puede saltar de uno a otro.
12. **Título.** El logo queda chico y tapado por el platillo, el menú pisa el dibujo y hay una entrada «Laguna (prototipo - debug)» a la vista.
13. **Coherencia del estilo.** Las hojas y el suelo no tienen el mismo tratamiento que los personajes.

### Impacto bajo

14. Durante las escenas cortas, las barras negras cortan el HUD a la mitad.
15. Algunas flores lejanas se ven de abajo, como discos pálidos, si la cámara se abre.
16. Cuatro errores `Parameter "material" is null` en la consola al cargar el nivel.
17. Sin cruceta para moverse en el mando. Va a quedar así, porque la cruceta arriba ya es el Enjambre y el stick es mejor.

## Cámara

Comparé el mismo instante con cuatro vistas (`qa_screenshots/camara/`):

- **A, lateral:** la de hoy. Se lee perfecto, pero se ve como un telón.
- **B, 2.5D suave (12°) y C, 2.5D fuerte (26°):** el juego sigue en el mismo plano, pero la cámara mira hacia adelante. El mundo gana profundidad enseguida y Bee se ve de tres cuartos.
- **D, desde atrás, estilo Star Fox:** el plano de juego se ve de canto, Bee, los enemigos y las balas quedan en una franja angosta, y del otro lado no hay mundo.

**Decisión: 2.5D dinámica, con un ángulo distinto por zona.** La lateral queda como respaldo con una constante. El detalle y lo que costaría migrar otros niveles quedan en `docs/informe_sesion.md`.
