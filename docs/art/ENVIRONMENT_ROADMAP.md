# Bee Alien — entorno y próximas tandas

Actualizado: 2026-10-10. Ideas del usuario, organizadas en POCs de 3–4 piezas
para revisar silueta y cel shading antes de ampliar cada familia. Los pendientes
de esta lista todavía no están modelados ni integrados.

La nueva prioridad del usuario está en `LEVEL01_ART_PRIORITIES.md`: después de
los enemigos V09/V10, avanzar con herramientas y fondo del jardín. Ese orden
tiene precedencia sobre las propuestas anteriores.

## Disponible en las tandas originales

| Tanda | Entorno / objetos | Galería |
|---|---|---|
| V01 | Nenúfar, totoras, asteroide | `scenes/art_labs/future_biomes_v01.tscn` |
| V04 | Tapa de botella terracota | `scenes/art_labs/future_biomes_v04.tscn` |
| V05 | Boya naranja/crema con cabo | `scenes/art_labs/future_biomes_v05.tscn` |
| V06 | Árbol joven, arbusto con margaritas, lata vacía y caramelo envuelto | `scenes/art_labs/future_biomes_v06.tscn` |
| V07 | Nube continua, sol, luna creciente y grupo de estrellas | `scenes/art_labs/future_biomes_v07.tscn` |
| V08 | Barca hueca con remos, módulo de ola y roca con musgo | `scenes/art_labs/future_biomes_v08.tscn` |

Cada pieza tiene fuente `.blend`, GLB y escena visual de Godot. Las formas
simples de fondo usadas dentro de las galerías son composiciones de revisión,
no modelos adicionales del catálogo.

## Cola de diseño

| Familia | POC siguiente propuesto | Criterio |
|---|---|---|
| Jardín / herramientas | Manguera, regadera, módulo de valla; casa después | Escala humana enorme para Bee, siluetas claras y fondo lejano de bajo contraste. |
| Vegetación | Pino joven, arbusto denso, campanilla | Diversificar siluetas, alturas y formas de hoja/flor; evitar simples recolores. |
| Objetos de suelo | Paquete de cigarrillos vacío, envoltorio abierto, lata deformada | Objetos genéricos sin marcas ni texto; formas limpias y escala humana. |

Siguiente tanda sugerida: **manguera + regadera + módulo de valla**. La fauna
pendiente sigue en `docs/art/FAUNA_ROADMAP.md`; esta propuesta no la reemplaza.

V07 cubre el primer kit de cielo. Sus piezas usan un perfil de contorno más fino,
rim suave y tinte por instancia. Las vistas día/noche son composiciones de arte;
un ciclo horario y un sistema de parallax siguen pendientes de integración.

V08 cubre el primer kit costero. La barca tiene interior real y remos separados;
la ola es una pieza sólida de decoración con espuma crema. Flotación, colisiones
y animación de agua siguen pendientes de integración.

## Criterios comunes

Conservar la biblia de `docs/art/STYLE_BIBLE.md`: 2–3 bandas, contorno fino,
formas suaves y lectura lateral. Vegetación con verdes naturales y ocres;
objetos con colores de pintura/material sin brillo alienígena. Reservar cian
y violeta activos para dispositivos ajenos a estos props.

Probar las piezas con Bee como referencia y luego en estudio neutro. La escala
de estudio ayuda a comparar diseño, no representa proporciones reales entre
árboles, objetos y flores. Ajustar la escala final por instancia en cada nivel.

Los modelos actuales son visuales. Definir colisiones simples, planos de
parallax, animación de viento/agua y presupuesto de superficies al integrarlos.
