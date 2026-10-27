# Bee vs Alien — Adenda 3 y prompts de las próximas tandas

Fuente: `prueba1.mp4` (4:31, pruebas de F5–F8 en el jardín de día) y `prueba2.mp4` (5:28, desde el cruce del hormiguero hasta la pantalla final, de noche).
Complementa `docs/INFORME_GAMEPLAY_FUSIONADO.md` y `docs/ADENDA_GAMEPLAY_2.md`. Los tiempos (m:ss) son de cada video.
Tipos: A = bug confirmado, B = observado, C = mejora de diseño, D = validar.

## 1. Decisiones del desarrollador (quedan fijas)

| Tema | Decisión |
|---|---|
| Tamaño de Bee (F5) | **1.40** (el más grande; "se ve muchísimo mejor") |
| Contorno (F6) | **valor 1, intermedio (fino)**. Es el "anterior al último" de las tres opciones. Si Codex ve que la numeración es otra, que respete "el del medio". |
| Fondo (F7) | Entre 0 y 1. **Se fija 1** hasta ver más partidas. El 2 queda descartado (grisáceo, el suelo no parece suelo). |
| Neón (F8) | **Sin decidir**: no se pudo probar porque el juego se cierra (ver H-36). Queda en 1 hasta probarlo. |
| Disparo de Bee | Aprobado: "mejoró muchísimo, mucha más acción". Se acepta que a veces se ponga demasiado frenético. |
| Estilo | Cel shading aprobado ("parece dibujado y más profesional"). No tocar. |
| Gusanos de la primera fase | **No saltan.** Se quedan en el suelo, se mueven lento y lanzan hacia arriba bolas de plasma en patrones lentos, como los gusanos de la segunda mitad del nivel. |
| Música | Habrá puntos musicales según el avance. Se define después (ver tanda de audio al final). |

## 2. Hallazgos nuevos

**H-36 · F8 cierra el juego (A, hipótesis fuerte)**
- En `prueba1.mp4` a ≈1:52 el juego desaparece y queda el editor de Godot con la consola sin ningún error, solo las líneas de arranque.
- En Godot, **F8 es "Detener" el proyecto en ejecución** (y F5, F6 y F7 también son atajos del editor). El editor se lleva la tecla antes que el juego. No es un fallo del neón.
- Acción: mover los cuatro comparadores a teclas que ni el editor ni el juego usen, y mostrarlas en la línea DEV.

**H-37 · Potenciadores con el aspecto del prototipo (B)**
- En `prueba2.mp4` a 3:42 hay dos potenciadores viejos: un círculo rojo con la letra "B" y una esfera celeste adentro, y un círculo azul con la letra "S" y un cono celeste. Se ven planos y no encajan con el resto.
- Los nuevos ya existen en el mismo video: medallón hexagonal con flecha (0:21 y 2:06 de `prueba1`, 5:21 de `prueba2`), orbe dorado con halo verde (varios), círculo rosa con ícono marrón (2:51).
- Acción: inventariar todos los pickups y unificar los que siguen con el aspecto viejo al lenguaje del medallón nuevo. Un color de anillo por tipo, glifo claro, mismo tamaño, brillo igual al de los nuevos.

**H-38 · Avisos planos que parecen dibujados con Paint (B, desagrada al desarrollador)**
- Franjas naranjas horizontales largas en el suelo (2:42–2:48 y 2:57 de `prueba2`; 1:21–1:51 de `prueba1`).
- Bloque rojo plano de la Tarántula, diagonal (4:12, 4:48, 5:00, 5:09) y **a todo lo ancho** (5:12, tapa a la propia Tarántula).
- Tres líneas verticales finas naranja/blanco con elipse blanca en el suelo (3:20–3:21 de `prueba2`, durante el Robot). Es lo que el desarrollador describe como "dos líneas verticales como dibujadas con Paint". Codex debe confirmar qué ataque las dibuja.
- Láser del Robot: línea celeste fina, y a 3:24 una diagonal celeste gruesa que cruza media pantalla.
- Bloque rojo plano en la esquina inferior derecha (3:32–3:33).
- Línea naranja del Aguijón (sigue viva hasta T4b).
- Pedido: semitransparente, punteado o similar. La T3f ya generó la galería A/B; el desarrollador todavía no eligió, así que se aplica A como base con las excepciones del prompt T3h.

**H-39 · Gusanos de la primera fase: reemplazar salto por tiro en arco hacia arriba (C, pedido)**
- En la segunda mitad del nivel los gusanos ya hacen eso: domo blanco con elipse naranja en el suelo y bolas celestes que suben (por ejemplo 0:06–0:24, 1:21–1:45, 2:15 de `prueba2`).
- Pedido: la primera fase usa ese mismo comportamiento, más lento.

**H-40 · Tarántula demasiado fácil (C, pedido)**
- En todo el combate (3:48–5:20) la vida de Bee solo baja de 100 a 79.
- Pedido: más telarañas que atrapen a Bee, refuerzos de avispas y arañas que bajan colgadas.
- Reglas propuestas: la telaraña frena, no inmoviliza más de 1 s, y la pirueta o el Aguijón la rompen. Un elemento nuevo por fase. Todo con aviso.

**H-41 · Robot caminante (sigue H-24)**
- Se ve totalmente blanco durante buena parte del combate (3:20–3:32, 3:36–3:39): flash o estado de invulnerabilidad sin lectura clara.
- Aparece cortado por el borde inferior y la lata de fondo lo tapa a ratos.

**H-42 · Pantalla final (T2 sigue pendiente)**
- 5:27: "LEVEL 01 COMPLETADO / R — JUGAR DE NUEVO / SECTOR DESPEJADO · LIBERADOS 326/454 / PUNTAJE 135040 · MEJOR COMBO x185" sobre la acción y pisando a Bee. En inglés parcial, sin rango.

**H-43 · Combo (sigue H-20)**
- Llega a x185, pero a 3:45, justo al aparecer la Tarántula, pasa de x44 a x0 y no vuelve a subir en todo el jefe.

**H-44 · Música por puntos de avance (pedido, solo planificación)**
- Auditoría de audio al final (prompt T8-audio).

## 3. Orden recomendado de las tandas

| Orden | Tanda | Modelo / razonamiento | Para qué |
|---|---|---|---|
| 1 | T3g | Sol 6.1, medio | F8 y comparadores, valores fijos, potenciadores |
| 2 | T3h | Sol 6.1, medio | Avisos (A como base) y láser del Robot |
| 3 | T4b | Sol 6.1, alto | Aguijón embestida, daño, hormigas (prompt ya entregado, sin cambios) |
| 4 | T4d | Sol 6.1, medio | Gusanos de la primera fase |
| 5 | T2 | Sol 6.1, medio | Menú, transición, pantalla final (prompt ya entregado) |
| 6 | T7a | Sol 6.1, alto | Auditoría de jefes, sin cambiar código |
| 7 | T8-audio | Sol 6.1, medio | Auditoría de audio, sin cambiar código |

Después de cada tanda: un video de 2–3 minutos.

---

## 4. Prompts

Cómo usarlos en la app de escritorio de Codex: abrí la carpeta `D:\proyectos\bee_alien_3d`, creá un hilo nuevo, elegí el modelo y el razonamiento indicados arriba de cada prompt, pegá el bloque completo y enviá. Si Codex pregunta si puede ejecutar algo, aprobalo. Al terminar tiene que decirte el número de commit.

---

### PROMPT T3g — Sol 6.1, razonamiento MEDIO

```
Tanda T3g. Rama lote-16-titulo-intro. Trabajá solo lo que pide este prompt, cambios mínimos y localizados.

CONTEXTO
Los comparadores de desarrollo F5 (tamaño de Bee), F6 (contorno), F7 (fondo) y F8 (neón de disparos) son atajos que Godot usa en el editor: F5 ejecutar, F6 ejecutar escena, F7 pausar, F8 DETENER. Al pulsar F8 con el juego lanzado desde el editor, el proyecto se cierra sin error en consola.

1) TECLAS DE LOS COMPARADORES
- Revisá el Input Map del proyecto y los scripts, y elegí cuatro teclas que NO usen ni el juego ni los atajos por defecto del editor de Godot 4 (por ejemplo la fila de números 7, 8, 9 y 0, si están libres). No uses F1–F12.
- Reasigná F5, F6, F7 y F8 a esas teclas, con el mismo comportamiento.
- Actualizá la línea DEV de abajo para que muestre las teclas nuevas.
- Dejá el neón (antes F8) con valor 1 por defecto y asegurate de que los niveles 0, 1 y 2 funcionan sin errores en consola.

2) VALORES DEFINITIVOS (decididos por el desarrollador tras comparar)
- Tamaño visual de Bee: 1.40 (la hitbox no cambia).
- Contorno de Bee: el valor intermedio (1, el fino). Si la numeración es otra, es el del medio entre apagado y grueso.
- Atenuación de fondo: 1. El valor 2 se elimina de la lista de opciones (se ve grisáceo y el suelo no parece suelo); quedan 0 y 1.
- Neón de disparos: 1 hasta nueva orden.
Poné esos valores como defaults en las constantes y mantené los comparadores solo en modo desarrollo.

3) POTENCIADORES CON ASPECTO DE PROTOTIPO
- Inventariá todos los pickups del nivel 1 (escena, script, color, forma, ícono) en una tabla en docs/INVENTARIO_PICKUPS.md. Indicá cuáles tienen el aspecto nuevo (medallón hexagonal con flecha, orbe dorado con halo verde, círculo rosa con ícono marrón) y cuáles el viejo: círculo rojo con letra "B" y esfera celeste, círculo azul con letra "S" y cono celeste.
- Para los que tengan aspecto viejo, rediseñalos con el mismo lenguaje del medallón nuevo: mismo tamaño, anillo del color de su tipo, glifo claro adentro, mismo brillo y misma animación de flotación. No cambies cuánto dan ni cuándo aparecen.
- No uses un color que se confunda con los disparos enemigos (cian, magenta, verde neón) como color de anillo; el dorado sigue siendo de Bee.
- Generá docs/pickups_antes_despues.png (día y noche) con todos los pickups lado a lado.

4) VERIFICACIÓN
- Ejecutá solo las pruebas relacionadas y abrí el nivel 1 comprobando que no hay errores en consola.
- Escribí docs/INFORME_TANDA_3G.md con: teclas elegidas y por qué, valores fijados, tabla de pickups y qué quedó pendiente.

5) COMMIT Y PUSH
- git add de los archivos modificados y nuevos (incluí docs/ADENDA_GAMEPLAY_2.md y docs/ADENDA_GAMEPLAY_3_Y_PROMPTS.md si siguen sin seguimiento).
- Commit con mensaje "T3g: teclas de comparadores sin conflicto con el editor, valores fijos, pickups unificados".
- git push origin lote-16-titulo-intro.
- Decime el hash del commit.
```

---

### PROMPT T3h — Sol 6.1, razonamiento MEDIO

```
Tanda T3h. Rama lote-16-titulo-intro. Cambios mínimos y localizados; NO cambies daños, áreas de impacto ni tiempos de aviso (se mantienen entre 0,5 y 1 s antes del impacto). Solo cambia cómo se ven los avisos.

CONTEXTO
Tenés tools/galeria_avisos.tscn y docs/AVISOS_ATAQUE_INVENTARIO.md (38 avisos con variantes actual / A marca mínima / B marca + anticipación). El desarrollador no eligió entre A y B, pero dijo que NO le gustan las barras largas planas "que parecen dibujadas con Paint" y que prefiere algo semitransparente, punteado o similar. Se aplica A como base, con las excepciones de abajo.

1) APLICAR A como aspecto por defecto a todos los avisos del inventario.

2) EXCEPCIONES (cada una cambia solo el aspecto)
a) Franjas horizontales largas naranjas en el suelo: fuera. Que el aviso sea una marca en el punto de impacto o una franja semitransparente (opacidad ≤ 0,3) con borde punteado, que sube a 0,6 solo en los últimos 0,3 s.
b) Bloques rojos de la Tarántula (diagonales y la banda a todo lo ancho): relleno semitransparente (opacidad ≤ 0,3) con borde punteado o rayado, y a 0,6 solo en los últimos 0,3 s. Dibujá la banda a todo lo ancho DETRÁS de la Tarántula para que no la tape.
c) Láser del Robot caminante: el aviso previo es una línea punteada semitransparente (opacidad ≤ 0,35), no una línea sólida fina. El rayo en sí mantiene su color celeste pero con degradado de brillo hacia los bordes en vez de color plano, y dura lo mismo que hoy.
d) Tres líneas verticales finas naranja/blanco con elipse blanca en el suelo, visibles durante el combate contra el Robot caminante: encontrá qué ataque las dibuja (decime cuál en el informe). Dejá solo el anillo en el suelo y una columna suave con degradado vertical, sin contorno sólido.
e) Bloque rojo plano visible en la esquina inferior derecha durante el Robot caminante: identificá qué es y aplicale el mismo tratamiento que a (b).
f) No toques todavía la línea naranja del Aguijón: se reemplaza en la tanda del Aguijón.

3) VERIFICACIÓN VISUAL
- Regenerá docs/galeria_avisos_dia.png y docs/galeria_avisos_noche.png mostrando "antes" y "ahora" para cada excepción (a–e), con etiquetas legibles.
- Generá docs/avisos_en_escena_dia.png y _noche.png: una captura del nivel con la Tarántula (banda ancha), otra con el Robot (láser) y otra con enemigos de suelo, para ver los avisos en contexto.
- Chequeá que cada aviso siga siendo visible en escala de grises sobre el fondo de día y de noche.
- Medí FPS en el nivel con y sin los cambios; si bajan más de 3 FPS, decime cuál aviso lo causa.

4) Ejecutá solo las pruebas relacionadas. Escribí docs/INFORME_TANDA_3H.md con: qué ataque dibujaba cada línea, qué cambió y qué no.

5) COMMIT Y PUSH
- Commit "T3h: avisos de ataque semitransparentes y punteados, láser del Robot sin líneas sólidas".
- git push origin lote-16-titulo-intro. Decime el hash.
```

---

### PROMPT T4d — Sol 6.1, razonamiento MEDIO

```
Tanda T4d. Rama lote-16-titulo-intro. Cambios mínimos y localizados.

OBJETIVO
Los gusanos de la primera fase del nivel 1 no deben saltar. Un gusano real casi nunca salta: se mueve lento. Deben comportarse como los gusanos de la segunda mitad del nivel: quietos o reptando lento en el suelo y lanzando hacia arriba bolas de plasma en patrones lentos.

PASO 1 — AUDITORÍA (sin cambiar nada todavía)
- Identificá en el código el enemigo "GUSANO DE COMPOST" de la primera fase (el que salta) y el gusano de la segunda mitad (el que lanza bolas celestes hacia arriba con domo blanco y elipse naranja en el suelo).
- Decime si son enemigos distintos o variantes del mismo, y qué componente reutilizable de ataque existe para el segundo.

PASO 2 — CAMBIO
- Quitá el salto del gusano de la primera fase.
- Hacé que use el MISMO ataque del gusano de la segunda mitad (mismo proyectil, mismo aviso), no uno nuevo.
- Parámetros: más lento que el de la segunda mitad (cadencia como máximo el 60 % de la del otro), patrones simples y legibles que se alternen: abanico de 3 hacia arriba, columna recta, diagonal. No más de 2 gusanos atacando a la vez.
- Mantené la vida y el daño actuales del gusano de la primera fase. Si el daño por segundo del jugador contra él cambia, decímelo.
- Si el gusano sale del suelo, que se vea la salida (polvo o escala desde el suelo), no que aparezca de golpe.

PASO 3 — VERIFICACIÓN
- Ejecutá solo las pruebas relacionadas. Abrí el nivel 1, ubicate donde aparecen estos gusanos y comprobá que no saltan y que disparan los patrones descritos. Sin errores en consola.
- Generá docs/gusanos_fase1.png con una secuencia de 4 capturas (aviso, disparo, proyectiles subiendo, enfriamiento).
- Escribí docs/INFORME_TANDA_4D.md: qué eran, qué se reutilizó, parámetros finales.

COMMIT Y PUSH
- Commit "T4d: gusanos de la primera fase atacan hacia arriba sin saltar".
- git push origin lote-16-titulo-intro. Decime el hash.
```

---

### PROMPT T7a — Sol 6.1, razonamiento ALTO (solo lectura y propuesta)

```
Tanda T7a. Rama lote-16-titulo-intro. SOLO LECTURA Y DOCUMENTO: no modifiques código, escenas ni constantes. Solo creá docs/INFORME_TANDA_7A.md y hacé commit y push.

OBJETIVO
Entender por qué los jefes se ven y se sienten mal, y proponer cómo subir la dificultad de la Tarántula sin añadir ruido visual. Contestá con evidencia del código (archivo y línea), no con suposiciones. Si una causa no se puede confirmar leyendo, marcala como "sin confirmar".

PREGUNTAS (observadas en video por el desarrollador)
1) Robot caminante: se ve completamente blanco durante buena parte del combate. ¿Es un destello de daño, un estado de invulnerabilidad o un material? ¿Cuánto dura y qué lo dispara?
2) Robot caminante: aparece cortado por el borde inferior y a ratos tapado por la lata de fondo. ¿Qué altura, posición y capa de dibujo usa? ¿Qué cambio mínimo lo deja entero y por delante?
3) Tarántula: sale del encuadre por arriba en varias fases. ¿Qué altura y qué trayectoria usa en cada fase y qué parámetro la limita? ¿Cuál es el cambio mínimo para mantenerla dentro de la pantalla?
4) Combo: pasa de x44 a x0 al aparecer la Tarántula y no sube en todo el combate. ¿Dónde se reinicia y dónde se bloquea? ¿Es intencional?
5) Tarántula, dificultad: en el combate completo la vida de Bee solo baja de 100 a 79. Listá sus ataques actuales por fase (aviso, daño, cadencia, área).

PROPUESTA (solo en el documento)
Para cada una de las 4 fases, proponé como máximo UN elemento nuevo, elegido entre:
- Telarañas que atrapan a Bee: la frenan, no la inmovilizan más de 1 s, y la pirueta o el Aguijón las rompen.
- Avispas de refuerzo que entran por un lado.
- Arañas pequeñas que bajan colgando de hilos desde arriba.
Cada elemento con: cuándo aparece, aviso previo (usando el lenguaje visual de T3h: semitransparente, punteado), daño, cuánto aumenta el daño por segundo que recibe Bee, qué escenas y scripts hay que tocar, riesgo y costo estimado en tandas.
Objetivo de dificultad: que Bee pierda entre 40 y 60 de vida en el combate completo con juego normal. Decime cómo se mediría.

COMMIT Y PUSH
- Commit "T7a: auditoría de jefes y propuesta de dificultad de la Tarántula (solo documento)".
- git push origin lote-16-titulo-intro. Decime el hash.
```

---

### PROMPT T8-audio — Sol 6.1, razonamiento MEDIO (solo lectura y propuesta)

```
Tanda T8-audio. Rama lote-16-titulo-intro. SOLO LECTURA Y DOCUMENTO: no modifiques código ni assets. Solo creá docs/AUDITORIA_AUDIO.md y hacé commit y push.

OBJETIVO
El desarrollador quiere distintos puntos musicales según el avance del juego (se definirán después). Dejá preparado el análisis técnico.

INCLUÍ
1) Inventario del audio actual: música, efectos, buses, volúmenes por defecto y dónde se reproducen (archivo y línea). Formato de cada archivo.
2) Cómo se controla hoy la música: ¿una sola pista en bucle, cambia por escena, hay fundidos? ¿Existe algún gestor de música?
3) Lista de momentos del nivel 1 que podrían tener cambio musical y qué señal del código los marca (por ejemplo inicio del nivel, oleadas intensas, cruces, minijefe Robot caminante, jefe Tarántula, victoria, derrota, pausa, menú).
4) Propuesta de arquitectura mínima: un gestor con "puntos musicales" disparados por eventos del nivel, con fundido cruzado, y capas de intensidad opcionales. Costo en tandas y riesgos.
5) Lista de lo que habría que decidir con el desarrollador antes de implementar (pistas, estilo, loops).

COMMIT Y PUSH
- Commit "T8-audio: auditoría de audio y propuesta de puntos musicales (solo documento)".
- git push origin lote-16-titulo-intro. Decime el hash.
```

---

### Prompts ya entregados que siguen vigentes
- **T4b** (Aguijón embestida, destello de daño con registro solo en desarrollo, hormigas ancladas al suelo con entrada visible desde el hormiguero): sin cambios, Sol 6.1 razonamiento alto. Cuando se ejecute después de T3h, la línea naranja del Aguijón desaparece.
- **T2** (menú, transición, subtítulos, pantalla final independiente en español con rangos S/A/B): sin cambios, Sol 6.1 razonamiento medio. Ahora incluye H-42: que el texto no pise a Bee ni la acción.
