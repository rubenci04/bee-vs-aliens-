# Bee Alien — fauna y próximas tandas

Actualizado: 2026-10-10. Plan de arte basado en las criaturas propuestas por el
usuario. Trabajar en POCs pequeños, normalmente 3–4 piezas por tanda. Esta lista
no implica que los modelos pendientes ya estén generados o integrados al juego.

**Prioridades nuevas del usuario:** ver `LEVEL01_ART_PRIORITIES.md`. V09 y V10
cubren los visuales de prioridad alta en dos POCs verificados. El orden de esa
lista tiene precedencia sobre las propuestas antiguas de esta página.

## Fauna original ya modelada

| Tanda | Criaturas | Estado |
|---|---|---|
| V01 | Mosquito, perca | `.blend`, GLB y escenas visuales liberables |
| V02 | Escarabajo ciervo, caracol | `.blend`, GLB y escenas visuales liberables |
| V03 | Luciérnaga, mariquita en vuelo, búho, mantarraya | `.blend`, GLB y escenas visuales liberables |
| V04 | Bicho palo, paloma en vuelo, ratón | `.blend`, GLB y escenas visuales liberables; tapa de botella como prop |
| V05 | Pulpo, gaviota | `.blend`, GLB y escenas visuales liberables; boya humana como prop |
| V09 | Hormiga, oruga blindada y estudio de sapo gigante | Visuales liberables, hoja canónica y kit de cuatro monturas; sin combate |
| V10 | Libélula, polilla bomba y hongo cañón | Visuales liberables, mina separada y demostraciones de vuelo/minas; sin combate |

Todos conservan anatomía natural y dispositivos externos removibles. Ninguno
de estos nuevos POCs tiene combate o rig terminado. Las galerías están en
`scenes/art_labs/future_biomes_v01.tscn`, `future_biomes_v02.tscn`,
`future_biomes_v03.tscn`, `future_biomes_v04.tscn` y `future_biomes_v05.tscn`.

## Cola de diseño

| Criatura solicitada | Bioma propuesto | Lectura lateral / rol a explorar |
|---|---|---|
| Pelícano | Lago / costa | Pico largo y bolsa natural, sin deformaciones. Amenaza grande ligada al agua. |
| Águila | Bosque / aire | Ala potente, pico curvo y garras. Amenaza aérea mayor con anticipación clara. |
| Rata | Residencial | Hocico y cuerpo más largos que el ratón, cola visible. Evitar que sea sólo un cambio de escala. |
| Serpiente | Orilla / bosque | Curva de cuerpo continua; cabeza reconocible y receptor externo separado. Movimiento futuro con rig. |

Siguiente fauna según la prioridad media: **águila + araña colgante**, en POCs
pequeños. El sapo ya tiene estudio V09, pendiente de rig y pelea. Pelícano,
serpiente y rata siguen en la cola posterior. Los roles no implican combate implementado.

## Tecnología y entorno disponibles

V01 aporta interceptor orbital, nenúfar, totoras y asteroide. V02 aporta nave
de carga y repetidor de señal. Reutilizar esta familia de carcasas grafito y
receptores cian/violeta para nuevas abrazaderas; no convertir toda la fauna en
robots ni toda la vegetación en neón.

V04 aporta una tapa de botella humana terracota, cóncava y sin emisión. Puede
servir como refugio o plataforma al definir las colisiones del nivel residencial.

V05 aporta boya costera naranja/crema con asa y cabo de amarre separados,
sin emisión. El pulpo tiene ocho brazos separados y ventosas agrupadas por brazo;
el siguiente paso de esa pieza es un POC de rig, apoyos y nado, no más detalle.

Después de aprobar cada silueta: preparar rig/animaciones, reducir draw calls,
definir hurtbox del dispositivo y recién entonces integrar un patrón de combate.
La salud corresponde al dispositivo; el animal debe poder liberarse.
