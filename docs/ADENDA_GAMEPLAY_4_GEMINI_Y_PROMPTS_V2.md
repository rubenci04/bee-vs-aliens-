# Bee vs Alien — Adenda 4: informe de Gemini integrado y prompts v2

**Este archivo reemplaza a `ADENDA_GAMEPLAY_3_Y_PROMPTS.md`.** Los prompts de acá ya incluyen las correcciones. Si ya habías pegado T3g o T3h del archivo anterior, no repitas esa tanda: las diferencias están marcadas con (NUEVO) para que pidas solo el extra.

Complementa `INFORME_GAMEPLAY_FUSIONADO.md`, `ADENDA_GAMEPLAY_2.md` y la adenda 3 (H-36 a H-44, que siguen vigentes).

## 1. Cómo evalué el informe de Gemini

Gemini actuó como tester ciego: miró los videos sin conocer el proyecto. Eso sirve para detectar lo que ya no ves de tanto jugarlo. Contrasté cada punto con los fotogramas de `prueba1.mp4` y `prueba2.mp4`.

- **Verificado en video:** se adopta.
- **Parcialmente cierto:** se adapta.
- **No verificable o erróneo:** se descarta o queda como pregunta para Codex.
- **Es una decisión tuya:** se pospone y te la planteo.

### 1.1 Adoptado (verificado en los videos)

| ID | Hallazgo | Evidencia mía |
|---|---|---|
| H-45 | "Mando detectado: XInput Controller" se escribe encima del HUD de vida (A) | `prueba1` 0:00 |
| H-46 | Texto crudo de controles bajo el HUD ("FUEGO A / RT · BOMBA X · PIRUETA B / LB · AGUIJÓN Y / RB") permanente (C) | `prueba1` 0:00–0:30 y otras |
| H-47 | Avisos CHECKPOINT y CHECKPOINT 2 chicos y flotando en plena acción (B) | `prueba2` 2:15–2:30 |
| H-48 | Un letrero LIBERADO por cada insecto y apilados; falta un contador único. Se suma el pedido de **animar la liberación** (el insecto recupera color y sale volando) (C) | `prueba1` 4:03–4:18; `prueba2` 0:00–0:08 |
| H-49 | Destello de golpe en blanco puro que borra el contorno. **Agrego una hipótesis mía:** con el disparo continuo de la T4c (12 ráfagas por segundo) el destello se reinicia en cada impacto y el enemigo queda blanco todo el tiempo. Eso explica por qué el Robot está blanco durante 10 s seguidos (`prueba2` 3:20–3:32), algo que un destello normal no hace (B, hipótesis a confirmar) | `prueba2` 3:20–3:32 |
| H-50 | Bee rígida: casi no se inclina al subir, bajar o retroceder (C). Encaja con tu pedido de animación más cuidada | `prueba1` y `prueba2` en general |
| H-51 | Polen y disparos de Bee comparten tono dorado y forma redonda. Solución propuesta: polen como pequeño hexágono de panal, giratorio, con imán suave (C) | `prueba1` 1:09–1:12, 3:24 |
| H-52 | Hit-stop (congelamiento de 0,04–0,07 s) y sacudida de pantalla, **solo** para Aguijón, pirueta que rompe disparos y ruptura de blindaje de jefe (C). Se hace después de T4b | Gemini |
| H-53 | Cámara: subir un 10–15 % el encuadre durante los jefes. Se suma a H-25 y va dentro de T7a | `prueba2` 4:25, 4:50, 5:10 |
| H-54 | La Tarántula se invierte bruscamente en el borde superior al pasar a fase 2 (B). Va dentro de T7a | `prueba2` 4:25 |

### 1.2 Adaptado

- **Telégrafos con shaders** (ruido en movimiento, brillo, hexágonos con Fresnel): la dirección es buena, pero primero T3h elimina lo plano. Después se evalúa si hace falta más.
- **Domos blancos:** Gemini los llama "escudos". En el video son avisos de ataque de suelo de los gusanos (domo blanco más elipse naranja). Los incorporo a T3h (NUEVO).
- **Etiquetas de enemigos** (MOSCA, AVISPA, MOSCA VERDE, ARAÑA COLGANTE): Gemini dice que ensucian. En los videos aparecen una sola vez por tipo (MOSCA VERDE a 1:30, MARIQUITA a 2:39, HORMIGA a 2:15). O sea que funcionan como presentación de enemigo nuevo. Lo correcto es mostrarlas como banner estilizado de primera aparición y no pegadas al enemigo. Va en T1b, con auditoría previa.
- **Tercera persona:** la recomendación de Gemini coincide con lo que ya teníamos. Hacer primero un shooter con cámara trasera sobre `Path3D`, con fijación suave de objetivo, `SpringArm3D` y transparencia de objetos que tapan la cámara, y volúmenes 3D para los ataques. Se incluye en el prompt T9 como requisito del análisis. El Nivel 1 lateral no se toca.
- **Niveles futuros** (Laguna, Bosque, Ciudad, Mar, Aire, Espacio con un modificador ambiental cada uno): idea útil, pero depende de tu lista de armas y de tu orden de niveles. Queda como referencia, no se implementa.

### 1.3 Pospuesto, es tu decisión

- **Recortar el nivel de 10 a 4,5–5 min.** Gemini asumió 10 minutos continuos, y no es así. El primer tramo de `prueba1` (hasta 1:52) fue una partida que se cerró por el F8, y el nivel reinició en 1:58. El nivel real mide unos **8 minutos** (2:32 de `prueba1` más los 5:28 de `prueba2`, con pausas). Aun así 8 minutos es largo para un shooter arcade, y el aviso de repetición de fondos tiene sentido. **No lo cambiaría a ciegas.** Propongo primero T5a: una línea de tiempo real del nivel con dos versiones propuestas, y vos elegís.
- **Cámara con adelanto horizontal (look-ahead):** riesgo alto de marear y de romper la puntería. Se pospone; H-34 cubre las señales de cámara livianas.
- **Regla "cian = dispositivo parásito, disparar donde brille":** es buena para el lore. Pero hoy varios disparos enemigos son cian (mosca común, caracol, rayos del robot), y puede confundirse con un punto débil. No lo cambio. Si en pruebas ves confusión, lo revisamos.

### 1.4 Descartado o no verificado

- "25 a 35 moscas simultáneas": conté unas 15 a 20 en los enjambres (`prueba1` 4:03–4:18, `prueba2` 0:00–0:08). El problema de legibilidad existe, pero está exagerado. No confirmé el solapamiento de mallas entre alas.
- Disparos verdes de Bee en `prueba2` 0:55–1:00: no lo pude confirmar.
- Los tipos de nodo (`MeshInstance3D`, `Line2D`) son suposiciones de Gemini; Codex lo mira en el código.
- Lo que Gemini marca como aprobado coincide con lo que ya decidimos conservar: contorno, cel shading, escala de props, arco de iluminación día a noche, fases de la Tarántula.

## 2. Decisiones del desarrollador que siguen fijas

| Tema | Decisión |
|---|---|
| Tamaño de Bee | 1.40 |
| Contorno | valor 1, intermedio (fino) |
| Fondo | 1 (el 2 descartado) |
| Neón | sin decidir, en 1, hasta poder probarlo |
| Gusanos de la primera fase | no saltan; tiran plasma lento hacia arriba como los de la segunda mitad |
| Avisos de ataque | semitransparentes o punteados, sin barras planas |
| Música | puntos musicales por avance; se define después |

## 3. Mapa de tandas v2

| Orden | Tanda | Modelo / razonamiento | Contenido |
|---|---|---|---|
| 1 | T3g | Sol 6.1, medio | Teclas sin conflicto, valores fijos, potenciadores, línea DEV |
| 2 | T3h | Sol 6.1, medio | Avisos semitransparentes, láser del Robot, domos |
| 3 | T1b | Sol 6.1, medio | HUD y textos: mando, leyenda de controles, checkpoints, contador de liberados, carteles de enemigos |
| 4 | T4e | Sol 6.1, medio | Destello de golpe sostenido más inclinación de Bee |
| 5 | T3i | Sol 6.1, medio | Polen hexagonal con imán |
| 6 | T4b | Sol 6.1, alto | Embestida del Aguijón, daño, hormigas (ya entregado, sin cambios) |
| 7 | T4d | Sol 6.1, medio | Gusanos de la primera fase |
| 8 | T4f | Sol 6.1, medio | Liberación animada y hit-stop (después de T4b) |
| 9 | T2 | Sol 6.1, medio | Menú y pantalla final (ya entregado, sin cambios) |
| 10 | T7a | Sol 6.1, alto | Auditoría de jefes (solo documento) |
| 11 | T5a | Sol 6.1, medio | Línea de tiempo del nivel (solo documento) |
| 12 | T9 | Sol 6.1, alto | Análisis de tercera persona (solo documento) |
| 13 | T8-audio | Sol 6.1, medio | Auditoría de audio (solo documento) |

Después de cada tanda de juego: un video de 2–3 minutos. Si Codex te dice que la tanda es más grande de lo esperado, pedile que la parta antes de empezar.

## 4. Cómo usar los prompts en la app de escritorio de Codex

1. Abrí la carpeta `D:\proyectos\bee_alien_3d`.
2. Creá un hilo nuevo.
3. Elegí el modelo y el razonamiento indicados arriba de cada prompt.
4. Pegá el bloque completo y enviá. Si pregunta si puede ejecutar algo, aprobalo.
5. Al terminar tiene que decirte el hash del commit. Pegame su informe si querés que lo revise.

---

## 5. Prompts

### PROMPT T3g — Sol 6.1, razonamiento MEDIO

```
Tanda T3g. Rama lote-16-titulo-intro. Trabajá solo lo que pide este prompt, con cambios mínimos y localizados.

CONTEXTO
Los comparadores de desarrollo F5 (tamaño de Bee), F6 (contorno), F7 (fondo) y F8 (neón de disparos) usan atajos que Godot reserva en el editor: F5 ejecutar, F6 ejecutar escena, F7 pausar, F8 DETENER. Al pulsar F8 con el juego lanzado desde el editor, el proyecto se cierra sin error en consola.

1) TECLAS DE LOS COMPARADORES
- Revisá el Input Map y los scripts. Elegí cuatro teclas que NO usen ni el juego ni los atajos por defecto del editor de Godot 4 (por ejemplo la fila de números 7, 8, 9 y 0 si están libres). No uses F1–F12.
- Reasigná los cuatro comparadores a esas teclas, con el mismo comportamiento.
- Que la línea DEV de abajo a la izquierda muestre las teclas nuevas.
- (NUEVO) Esa línea DEV y los comparadores deben verse y funcionar SOLO en modo desarrollo (bandera de debug o proyecto ejecutado desde el editor). En una build exportada no se ven ni responden.
- Dejá el neón con valor 1 por defecto y comprobá que los niveles 0, 1 y 2 funcionan sin errores en consola.

2) VALORES DEFINITIVOS (decididos por el desarrollador)
- Tamaño visual de Bee: 1.40 (la hitbox no cambia).
- Contorno de Bee: el valor intermedio (el fino). Si la numeración es otra, es el del medio entre apagado y grueso.
- Atenuación de fondo: 1. Eliminá el valor 2 de la lista de opciones (se ve grisáceo y el suelo no parece suelo); quedan 0 y 1.
- Neón de disparos: 1 hasta nueva orden.
Ponelos como defaults en las constantes.

3) POTENCIADORES CON ASPECTO DE PROTOTIPO
- Inventariá todos los pickups del nivel 1 (escena, script, color, forma, ícono) en docs/INVENTARIO_PICKUPS.md. Indicá cuáles tienen el aspecto nuevo (medallón hexagonal con flecha, orbe dorado con halo verde, círculo rosa con ícono marrón) y cuáles el viejo: círculo rojo con letra "B" y esfera celeste, círculo azul con letra "S" y cono celeste.
- Rediseñá los de aspecto viejo con el mismo lenguaje del medallón nuevo: mismo tamaño, anillo del color de su tipo, glifo claro adentro, mismo brillo y misma animación de flotación. No cambies cuánto dan ni cuándo aparecen.
- No uses como color de anillo ninguno que se confunda con los disparos enemigos (cian, magenta, verde neón). El dorado sigue siendo de Bee.
- Generá docs/pickups_antes_despues.png (día y noche) con todos los pickups lado a lado.

4) VERIFICACIÓN
- Ejecutá solo las pruebas relacionadas y abrí el nivel 1 sin errores en consola.
- Escribí docs/INFORME_TANDA_3G.md: teclas elegidas y por qué, valores fijados, tabla de pickups y pendientes.

5) COMMIT Y PUSH
- git add de los archivos modificados y nuevos. Incluí docs/ADENDA_GAMEPLAY_2.md y docs/ADENDA_GAMEPLAY_4_GEMINI_Y_PROMPTS_V2.md si siguen sin seguimiento.
- Commit "T3g: teclas de comparadores sin conflicto con el editor, valores fijos, pickups unificados".
- git push origin lote-16-titulo-intro. Decime el hash.
```

### PROMPT T3h — Sol 6.1, razonamiento MEDIO

```
Tanda T3h. Rama lote-16-titulo-intro. Cambios mínimos y localizados. NO cambies daños, áreas de impacto ni tiempos de aviso (se mantienen entre 0,5 y 1 s antes del impacto). Solo cambia cómo se ven los avisos.

CONTEXTO
Tenés tools/galeria_avisos.tscn y docs/AVISOS_ATAQUE_INVENTARIO.md (38 avisos con variantes actual / A marca mínima / B marca más anticipación). El desarrollador no eligió entre A y B, pero dijo que NO le gustan las barras largas planas "que parecen dibujadas con Paint" y que prefiere algo semitransparente, punteado o similar. Se aplica A como base, con las excepciones de abajo.

1) APLICAR A como aspecto por defecto a todos los avisos del inventario.

2) EXCEPCIONES (cada una cambia solo el aspecto)
a) Franjas horizontales largas naranjas en el suelo: fuera. El aviso es una marca en el punto de impacto, o una franja semitransparente (opacidad ≤ 0,3) con borde punteado, que sube a 0,6 solo en los últimos 0,3 s.
b) Bloques rojos de la Tarántula (diagonales y banda a todo lo ancho): relleno semitransparente (opacidad ≤ 0,3) con borde punteado o rayado, y 0,6 solo en los últimos 0,3 s. Dibujá la banda a todo lo ancho DETRÁS de la Tarántula para que no la tape.
c) Láser del Robot caminante: el aviso previo es una línea punteada semitransparente (opacidad ≤ 0,35), no una línea sólida fina. El rayo mantiene el color celeste pero con degradado de brillo hacia los bordes en vez de color plano, y dura lo mismo que hoy.
d) Tres líneas verticales finas naranja y blanco con elipse blanca en el suelo, visibles durante el combate contra el Robot: encontrá qué ataque las dibuja y decime cuál en el informe. Dejá el anillo en el suelo y una columna suave con degradado vertical, sin contorno sólido.
e) Bloque rojo plano en la esquina inferior derecha durante el Robot: identificá qué es y dale el mismo tratamiento que a (b).
f) (NUEVO) Domos semiesféricos blancos con elipse naranja en el suelo (avisos de ataque de los gusanos): domo semitransparente (opacidad ≤ 0,25) con borde punteado; la elipse del suelo con opacidad ≤ 0,4. Aclará en el informe que son avisos de ataque y no escudos.
g) No toques todavía la línea naranja del Aguijón: se reemplaza en T4b.

3) VERIFICACIÓN VISUAL
- Regenerá docs/galeria_avisos_dia.png y docs/galeria_avisos_noche.png con "antes" y "ahora" para cada excepción (a–f), con etiquetas legibles.
- Generá docs/avisos_en_escena_dia.png y _noche.png con tres capturas del nivel: Tarántula (banda ancha), Robot (láser) y enemigos de suelo.
- Comprobá que cada aviso siga visible en escala de grises sobre el fondo de día y de noche.
- Medí FPS en el nivel con y sin los cambios; si bajan más de 3 FPS, decime qué aviso lo causa.

4) Ejecutá solo las pruebas relacionadas. Escribí docs/INFORME_TANDA_3H.md: qué ataque dibujaba cada línea, qué cambió y qué no.

5) COMMIT Y PUSH
- Commit "T3h: avisos de ataque semitransparentes y punteados, láser del Robot y domos sin geometría plana".
- git push origin lote-16-titulo-intro. Decime el hash.
```

### PROMPT T1b — Sol 6.1, razonamiento MEDIO

```
Tanda T1b: limpieza de HUD y textos. Rama lote-16-titulo-intro. Cambios mínimos y localizados. No toques gameplay, daños ni disparos.

1) "Mando detectado: XInput Controller" se escribe encima del texto de vida (visible al arrancar el nivel). Mostralo como aviso breve (2 s, con fundido) arriba y al centro, sin pisar ningún otro texto, y solo cuando cambia el dispositivo de entrada.

2) Texto crudo de controles bajo el HUD ("FUEGO A / RT · BOMBA X · PIRUETA B / LB · AGUIJÓN Y / RB" y "PIRUETA · B / LB: esquiva y rompe disparos"). Reemplazalo por los íconos que ya tiene el HUD (B/LB, Y/RB) y por consejos cortos que aparecen una sola vez por tipo cuando la mecánica es relevante, con fundido de salida. Nada permanente en pantalla.

3) CHECKPOINT y CHECKPOINT 2: hoy son texto blanco chico flotando en plena acción. Mostralos como banner arriba y al centro, tamaño legible, con fundido de 1,5 s, nunca cerca del plano de acción.

4) Contador de liberados: hoy aparece un letrero LIBERADO por cada insecto y se apilan. Hacé:
- Un contador acumulado único ("+N LIBERADOS") arriba y al centro, que suma los liberados dentro de una ventana de 0,6 s y se reinicia después.
- Como máximo 2 letreros individuales a la vez, chicos y con 60 % de opacidad; el resto se acumula en el contador.

5) Carteles de enemigos (MOSCA, AVISPA, MOSCA VERDE, HORMIGA, MARIQUITA, ARAÑA COLGANTE): primero AUDITÁ si aparecen solo la primera vez que sale cada tipo o repetidamente. Si se repiten, limitalos a la primera aparición. En todo caso mostralos como banner estilizado arriba (el mismo estilo del banner de jefes pero más chico), no pegados al enemigo. Los nombres de jefes no cambian.

6) Instrucción "PATAS BLINDADAS: APUNTÁ AL IMPLANTE": hacela al menos el doble de grande y con más contraste, arriba y al centro, debajo de la barra del jefe.

7) VERIFICACIÓN: capturas antes/después en docs/hud_antes_despues.png (inicio del nivel, un checkpoint, un enjambre con muchos liberados, la Tarántula con la instrucción). Pruebas relacionadas solamente. docs/INFORME_TANDA_1B.md con lo que encontraste en el punto 5.

8) COMMIT Y PUSH: commit "T1b: HUD y textos limpios (mando, controles, checkpoints, contador de liberados, carteles)"; git push origin lote-16-titulo-intro. Decime el hash.
```

### PROMPT T4e — Sol 6.1, razonamiento MEDIO

```
Tanda T4e: destello de golpe y animación de Bee. Rama lote-16-titulo-intro. Cambios mínimos y localizados. No cambies daños, vidas, hitboxes ni puntería.

CONTEXTO
En el video, al disparar de forma continua a un enemigo grande (Robot caminante), el modelo queda completamente blanco, sin contorno, durante hasta 10 s seguidos. Hipótesis: el destello de golpe se reinicia en cada impacto (disparo continuo de la T4c, 12 ráfagas por segundo) y nunca termina.

1) AUDITORÍA primero (sin cambiar nada):
- Encontrá el código del destello de golpe de enemigos y jefes (material, color, duración, cómo se reinicia).
- Confirmá o refutá la hipótesis. Decime cuánto dura como máximo el estado blanco seguido y si el destello pisa el pase del contorno.

2) CAMBIO DEL DESTELLO
- El destello dura 0,06 s y no puede reiniciarse hasta 0,2 s después de terminado, aunque lleguen más impactos.
- El color mezcla al 50–60 % con blanco cálido, nunca al 100 %.
- No debe sobrescribir el contorno negro: aplicalo de forma que el pase de contorno siga visible.
- La muerte de enemigos chicos puede conservar un destello algo más fuerte (hasta 80 %), una sola vez.

3) INCLINACIÓN DE BEE (solo el nodo visual)
- Que el nodo visual de Bee se incline según su velocidad: cabeceo hacia arriba al subir, hacia abajo al bajar, y alabeo leve al avanzar o retroceder. Máximo ±15° de cabeceo y ±20° de alabeo, con suavizado de unos 0,12 s y retorno a neutro al detenerse.
- NO cambies la hitbox, la hurtbox, el punto de salida de los disparos, la dirección de puntería ni el modelo del contorno. Comprobá que los disparos siguen saliendo del mismo punto.
- Dejá un interruptor de desarrollo (con una tecla libre, no F1–F12) para comparar con y sin inclinación. Por defecto encendido.

4) VERIFICACIÓN
- docs/destello_antes_despues.png: Robot caminante durante 3 s de fuego continuo, antes y después (3 capturas cada uno).
- docs/inclinacion_bee.png: Bee subiendo, bajando, retrocediendo y quieta.
- Medí FPS con y sin los cambios. Pruebas relacionadas solamente. docs/INFORME_TANDA_4E.md con los resultados de la auditoría.

5) COMMIT Y PUSH: commit "T4e: destello de golpe no sostenido y con contorno, inclinación procedural de Bee"; git push origin lote-16-titulo-intro. Decime el hash.
```

### PROMPT T3i — Sol 6.1, razonamiento MEDIO

```
Tanda T3i: polen legible. Rama lote-16-titulo-intro. Cambios mínimos y localizados. No cambies cuánto polen da cada recolección ni los datos de combo.

CONTEXTO
El polen del suelo y los disparos de Bee son dorados y redondeados, y en los enjambres se confunden. Se quiere distinguirlos por forma y movimiento, sin tocar el dorado de Bee.

1) AUDITORÍA: encontrá cómo se dibuja y recolecta el polen (escena, script, radio de recolección, valores).
2) CAMBIO
- El polen pasa a ser un pequeño hexágono de panal dorado con contorno, girando despacio, con brillo suave. Mismo tamaño aproximado de hoy.
- Imán suave: cuando Bee está a menos de un radio de atracción razonable (partí del radio de recolección actual multiplicado por 2,5), el polen se acerca a Bee con velocidad creciente. También cuando Bee ejecuta una pirueta cerca. Probá y decime el radio final.
- Los disparos de Bee no cambian de forma ni color.
3) VERIFICACIÓN
- docs/polen_vs_disparos_dia.png y _noche.png: polen y disparos de Bee juntos, en color y en escala de grises, para ver que se distinguen.
- Comprobá que el imán no hace que el polen atraviese enemigos ni se acumule fuera de pantalla. FPS en un enjambre. Pruebas relacionadas solamente. docs/INFORME_TANDA_3I.md.
4) COMMIT Y PUSH: commit "T3i: polen hexagonal con imán suave"; git push origin lote-16-titulo-intro. Decime el hash.
```

### T4b — Sol 6.1, razonamiento ALTO (prompt entregado antes, sin cambios)
Embestida del Aguijón (sin rayo naranja), destello de daño con registro solo para desarrollo, hormigas ancladas al suelo con entrada desde el hormiguero.

### PROMPT T4d — Sol 6.1, razonamiento MEDIO

```
Tanda T4d. Rama lote-16-titulo-intro. Cambios mínimos y localizados.

OBJETIVO
Los gusanos de la primera fase del nivel 1 no deben saltar. Un gusano real casi nunca salta: se mueve lento. Deben comportarse como los gusanos de la segunda mitad del nivel: quietos o reptando lento en el suelo y lanzando hacia arriba bolas de plasma en patrones lentos.

PASO 1 — AUDITORÍA (sin cambiar nada)
- Identificá el enemigo "GUSANO DE COMPOST" de la primera fase (el que salta) y el gusano de la segunda mitad (el que lanza bolas celestes hacia arriba con domo blanco y elipse naranja en el suelo).
- Decime si son enemigos distintos o variantes del mismo, y qué componente reutilizable de ataque existe para el segundo.

PASO 2 — CAMBIO
- Quitá el salto del gusano de la primera fase.
- Hacé que use el MISMO ataque del gusano de la segunda mitad (mismo proyectil y mismo aviso), no uno nuevo.
- Más lento que el de la segunda mitad (cadencia como máximo el 60 % de la del otro). Patrones simples y legibles que se alternen: abanico de 3 hacia arriba, columna recta, diagonal. No más de 2 gusanos atacando a la vez.
- Mantené la vida y el daño actuales. Si el daño por segundo que recibe cambia, decímelo.
- Si el gusano sale del suelo, que se vea la salida (polvo o escala desde el suelo), no que aparezca de golpe.

PASO 3 — VERIFICACIÓN
- Pruebas relacionadas solamente. Abrí el nivel 1 donde aparecen y comprobá que no saltan y que disparan los patrones descritos, sin errores en consola.
- docs/gusanos_fase1.png: secuencia de 4 capturas (aviso, disparo, proyectiles subiendo, enfriamiento).
- docs/INFORME_TANDA_4D.md: qué eran, qué se reutilizó, parámetros finales.

COMMIT Y PUSH: commit "T4d: gusanos de la primera fase atacan hacia arriba sin saltar"; git push origin lote-16-titulo-intro. Decime el hash.
```

### PROMPT T4f — Sol 6.1, razonamiento MEDIO (ejecutar DESPUÉS de T4b y T1b)

```
Tanda T4f: liberación animada y hit-stop. Rama lote-16-titulo-intro. Cambios mínimos y localizados.

1) LIBERACIÓN ANIMADA
Hoy, al romper el implante cian, el insecto simplemente desaparece con un texto. El objetivo narrativo es liberar, no exterminar.
- Al romperse el implante: una chispa eléctrica azul breve (partículas, con presupuesto bajo), el insecto recupera un tono cálido natural (sin cian), da un giro corto y sale volando hacia el fondo de la escena (eje Z) o fuera de pantalla, desvaneciéndose en 0,8 s como máximo. Sin colisión ni daño durante la animación.
- Tope de 12 animaciones simultáneas. Más allá del tope, usá una versión simple (solo chispa y desvanecido).
- El contador "+N LIBERADOS" de T1b se mantiene. El letrero individual queda solo como lo dejó T1b.
- Medí FPS en el enjambre de moscas; si baja más de 5 FPS, reducí partículas hasta que no.

2) HIT-STOP (microcongelamiento)
- Solo en estos eventos: impacto de la embestida del Aguijón, pirueta que rompe un disparo, ruptura de blindaje de un jefe.
- Duración 0,04 a 0,06 s, como máximo una vez cada 0,5 s. Preferí congelar localmente a Bee, el objetivo y proyectiles cercanos antes que cambiar la escala de tiempo global; si usás la escala global, comprobá que no afecta audio, temporizadores de aviso ni el contador de pausa.
- Interruptor de desarrollo para apagarlo (tecla libre, no F1–F12). Por defecto encendido.
- Sacudida de pantalla breve y direccional solo en esos mismos eventos, de baja amplitud.

3) VERIFICACIÓN: secuencia de capturas en docs/liberacion_animada.png. Pruebas relacionadas solamente. docs/INFORME_TANDA_4F.md.

4) COMMIT Y PUSH: commit "T4f: liberación animada de insectos y hit-stop en eventos clave"; git push origin lote-16-titulo-intro. Decime el hash.
```

### T2 — Sol 6.1, razonamiento MEDIO (prompt entregado antes, sin cambios)
Menú, transición, subtítulos y pantalla final independiente en español con rangos S/A/B. Se suma H-42: el texto de la pantalla final no puede pisar a Bee ni la acción.

### PROMPT T7a — Sol 6.1, razonamiento ALTO (solo lectura y documento)

```
Tanda T7a. Rama lote-16-titulo-intro. SOLO LECTURA Y DOCUMENTO: no modifiques código, escenas ni constantes. Creá docs/INFORME_TANDA_7A.md y hacé commit y push.

OBJETIVO
Entender por qué los jefes se ven y se sienten mal, y proponer cómo subir la dificultad de la Tarántula sin añadir ruido visual. Respondé con evidencia del código (archivo y línea). Si una causa no se puede confirmar leyendo, marcala "sin confirmar".

PREGUNTAS (observadas en video)
1) Robot caminante: se ve completamente blanco durante buena parte del combate. ¿Es un destello de daño, un estado de invulnerabilidad o un material? ¿Cuánto dura y qué lo dispara? (La tanda T4e trata el destello; acá solo decime si hay otro estado distinto.)
2) Robot caminante: aparece cortado por el borde inferior y a ratos tapado por la lata de fondo. ¿Qué altura, posición y capa de dibujo usa? ¿Qué cambio mínimo lo deja entero y por delante?
3) Tarántula: sale del encuadre por arriba en varias fases y al pasar a fase 2 se invierte de golpe en el borde superior. ¿Qué altura y trayectoria usa en cada fase y qué parámetro la limita? Cambio mínimo para mantenerla dentro de pantalla.
4) Cámara de jefes: evaluá el costo de subir un 10–15 % el encuadre (pivote o campo de visión) solo durante los combates de jefe, con transición suave de entrada y salida. Riesgos para la puntería y el HUD.
5) Combo: pasa de x44 a x0 al aparecer la Tarántula y no sube en todo el combate. ¿Dónde se reinicia y dónde se bloquea? ¿Es intencional?
6) Tarántula, dificultad: la vida de Bee solo baja de 100 a 79 en todo el combate. Listá sus ataques por fase (aviso, daño, cadencia, área).

PROPUESTA (solo en el documento)
Para cada una de las 4 fases, como máximo UN elemento nuevo entre:
- Telarañas que atrapan a Bee: la frenan, no la inmovilizan más de 1 s, y la pirueta o el Aguijón las rompen.
- Avispas de refuerzo que entran por un lado.
- Arañas pequeñas que bajan colgando de hilos desde arriba.
Cada elemento con cuándo aparece, aviso previo (lenguaje de T3h: semitransparente, punteado), daño, cuánto aumenta el daño por segundo que recibe Bee, qué escenas y scripts hay que tocar, riesgo y costo en tandas.
Objetivo: que Bee pierda entre 40 y 60 de vida en el combate completo con juego normal. Decime cómo se mediría.

COMMIT Y PUSH: commit "T7a: auditoría de jefes y propuesta de dificultad de la Tarántula (solo documento)"; git push origin lote-16-titulo-intro. Decime el hash.
```

### PROMPT T5a — Sol 6.1, razonamiento MEDIO (solo lectura y documento)

```
Tanda T5a. Rama lote-16-titulo-intro. SOLO LECTURA Y DOCUMENTO: no modifiques código ni escenas. Creá docs/LINEA_TIEMPO_NIVEL1.md y docs/linea_tiempo_nivel1.png, y hacé commit y push.

CONTEXTO
Una revisión externa sostiene que el nivel 1 es largo (unos 8 min según el video del desarrollador) y repite fondos y bucles de oleadas. Antes de decidir si se recorta, hay que ver los datos reales.

INCLUÍ
1) Línea de tiempo del nivel 1 tomada del código de oleadas y eventos: zonas, oleadas, minijefe, jefe, cruces, checkpoints, pickups, con tiempo de inicio y duración. Si el tiempo depende del jugador, indicá el rango.
2) Tabla de tipos de enemigo por zona y cuántos aparecen, para ver dónde se repite el mismo bucle.
3) Gráfico (PNG) de intensidad estimada a lo largo del nivel (enemigos activos y ataques por segundo), para ver los valles y las zonas planas.
4) Dos propuestas, solo en el documento:
   - Versión A: el nivel actual con ajustes de ritmo sin recortar (por ejemplo un evento de cruce o minijefe en los valles largos).
   - Versión B: versión condensada de 5 a 6 minutos. Indicá exactamente qué oleadas se fusionan o se quitan.
   Para cada una: costo en tandas, riesgo, qué no se toca.
5) Lo que habría que decidir con el desarrollador.

COMMIT Y PUSH: commit "T5a: línea de tiempo del nivel 1 y propuestas de ritmo (solo documento)"; git push origin lote-16-titulo-intro. Decime el hash.
```

### PROMPT T9 — Sol 6.1, razonamiento ALTO (solo lectura y documento)

```
Tanda T9. Rama lote-16-titulo-intro. SOLO LECTURA Y DOCUMENTO: no implementes nada. Creá docs/ANALISIS_TERCERA_PERSONA.md y hacé commit y push. El nivel 1 lateral no se toca.

OBJETIVO
Evaluar un modo en tercera persona estilo Star Fox / Kid Icarus Uprising para niveles futuros (Cielo, Espacio).

INCLUÍ
1) Qué sistemas actuales se reutilizan sin cambios (HUD, jerarquía visual de disparos y avisos, implantes y liberación, combo, Aguijón, daño) y cuáles hay que rehacer (cámara, límites de movimiento, director de oleadas, orientación de enemigos y suelo, arenas de jefe, escala de assets).
2) Camino híbrido recomendado antes del vuelo 3D libre: shooter sobre riel con cámara trasera usando Path3D y PathFollow3D, y fases de jefe en arena. Compará esa opción con el vuelo libre en costo y riesgo.
3) Puntería en 3D: fijación suave de objetivo (cono proyectado desde la cámara con ShapeCast3D), doble retícula o ligero homing para el disparo, y el Aguijón como embestida dirigida al objetivo fijado (continuidad con T4b).
4) Cámara y oclusión: SpringArm3D con máscaras de colisión solo para paredes grandes, y transparencia por proximidad (dither o desvanecido por distancia) para tallos, hojas y macetas que tapan a Bee.
5) Ataques enemigos: cómo convertir los ataques lineales 2D (bandas, abanicos) en volúmenes 3D (ondas esféricas, anillos, barridos horizontales, redes en cono) para que sigan obligando a usar pirueta y vuelo vertical.
6) Prototipo mínimo propuesto en una rama aparte, con alcance, costo en tandas y criterio de "va / no va".

COMMIT Y PUSH: commit "T9: análisis de tercera persona (solo documento)"; git push origin lote-16-titulo-intro. Decime el hash.
```

### PROMPT T8-audio — Sol 6.1, razonamiento MEDIO (solo lectura y documento)

```
Tanda T8-audio. Rama lote-16-titulo-intro. SOLO LECTURA Y DOCUMENTO: no modifiques código ni assets. Creá docs/AUDITORIA_AUDIO.md y hacé commit y push.

OBJETIVO
El desarrollador quiere distintos puntos musicales según el avance del juego (se definirán después). Dejá preparado el análisis técnico.

INCLUÍ
1) Inventario del audio actual: música, efectos, buses, volúmenes por defecto y dónde se reproducen (archivo y línea). Formato de cada archivo.
2) Cómo se controla hoy la música: ¿una pista en bucle, cambia por escena, hay fundidos? ¿Existe un gestor de música?
3) Momentos del nivel 1 que podrían tener cambio musical y qué señal del código los marca (inicio, oleadas intensas, cruces, Robot caminante, Tarántula, victoria, derrota, pausa, menú).
4) Arquitectura mínima propuesta: un gestor con puntos musicales disparados por eventos del nivel, con fundido cruzado y capas de intensidad opcionales. Costo en tandas y riesgos.
5) Lo que hay que decidir con el desarrollador antes de implementar (pistas, estilo, loops).

COMMIT Y PUSH: commit "T8-audio: auditoría de audio y propuesta de puntos musicales (solo documento)"; git push origin lote-16-titulo-intro. Decime el hash.
```
