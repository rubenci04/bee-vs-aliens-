# Bee vs Alien — Informe de gameplay fusionado

Fuente: grabación de una partida completa del Nivel 1 (9:04 min) + dos análisis independientes (Claude y ChatGPT) fusionados en este documento.
Este archivo es la referencia para Claude Code: cada hallazgo tiene un ID (H-01…H-28) que se cita desde los prompts de cada tanda.

## Cómo usar este documento (para Claude Code)

- Trabajá **solo los IDs de la tanda que se te pide**. No toques el resto.
- Cada hallazgo indica qué se ve en el video, qué hay que verificar en el código y qué hacer. Si algo figura como "a validar", **no asumas la causa**: comprobala en el proyecto antes de cambiar nada.
- Los tiempos (m:ss) son del video de la partida.
- Distinguí siempre entre: (A) bug confirmado, (B) problema observado en el juego, (C) mejora de diseño propuesta, (D) algo que requiere validación manual del desarrollador.

## Restricciones generales (valen para todas las tandas)

1. Conservar la identidad visual: entorno natural cálido y colorido, tecnología alienígena grafito/cian, energía miel-dorada de Bee.
2. Mantener el diseño canónico de Bee y su equipamiento.
3. No agregar enemigos, habilidades, niveles ni assets nuevos. No reemplazar assets existentes.
4. No reestructurar escenas ni cambiar mecánicas que funcionan sin una justificación clara.
5. No modificar mecánicas solo para que pasen los tests: un test verde no garantiza que el juego sea legible o justo.
6. Cambios mínimos y localizados. Nada de refactors grandes.
7. Cada tanda termina con commit y push, y con una lista de qué debe mirar el desarrollador dentro de Godot.
8. Criterio general de evaluación: ¿el jugador pierde por un error que pudo reconocer y evitar, o porque el juego no le dejó entender qué pasaba?

## Decisiones de fusión (donde los dos análisis diferían)

- **Tamaño de Bee (H-13):** un análisis proponía agrandarlo; el otro, no agrandarlo "a ciegas". Se resuelve así: primero contraste, contorno, márgenes y que el HUD deje de taparlo; recién después, si sigue perdiéndose, un aumento moderado (+20–30 %) separando la escala visual de la hitbox.
- **Cámara (H-17, H-21):** no se reescribe el sistema. Solo ajuste de encuadre, límites y señales por encuentro.
- **Variedad de escenario y coherencia artística (H-26, H-27):** son reales pero van al final y sin assets nuevos (se reacomodan los existentes). Primero legibilidad y combate.
- **Rendimiento:** un análisis midió ~41 FPS y otro 44–46 en el mismo tramo (≈2:36–2:41); el resto de la partida marca 54–60. Se trata como una caída real durante el enjambre grande, a perfilar.
- **Audio:** ambos coinciden en que el audio de la grabación es casi inaudible (intro por debajo de −40 dBFS; media global ≈ −42 dB). No se sabe si es del juego o de la captura: validar antes de actuar.

---

## GRUPO 1 — HUD y textos (Tanda 1)

**H-01 · HUD demasiado grande — CRÍTICA**
- Se ve: desde ~0:36 el panel superior izquierdo ocupa ~50 % del ancho y ~⅓ del alto. Bee y los enemigos pasan por detrás (2:36 enjambre, 5:12, 6:06).
- Acción: HUD compacto en tres zonas (vida/polen/bombas arriba a la izquierda, ZONA n/7 arriba al centro con espacio libre para avisos, combo/frenesí arriba a la derecha). La leyenda de controles solo aparece temporalmente (al aprender una habilidad o los primeros segundos), no toda la partida. Reducir opacidad y tamaño.
- Aceptación: el HUD nunca oculta a Bee, enemigos, proyectiles peligrosos ni zonas de impacto, ni siquiera cuando Bee llega a los límites de movimiento.

**H-02 · Textos de debug y superposiciones — ALTA (A: bug confirmado)**
- Se ve: texto cian "BASE · BOMB X1 · C BOMB" encima de los hexágonos de vida durante toda la partida; un "BASE" suelto superpuesto a "AGUIJÓN Y/RB"; "SPREAD n s" encima de ese mismo texto (0:54, 4:06).
- Acción: localizar el/los `Label` responsables, ocultarlos o llevarlos a un modo desarrollo; corregir el layout para que ningún texto se pise.

**H-03 · Cursor del sistema visible durante el juego — ALTA (A)**
- Se ve: puntero blanco visible casi toda la grabación (desde ~0:38), quieto en medio de la pantalla mientras se juega con mando.
- Acción: ocultar el cursor del sistema en gameplay (revisar `Input.mouse_mode` y el cambio de dispositivo) y dejar solo la retícula propia del juego.

**H-04 · Textos flotantes que se apilan — MEDIA**
- Se ve: varios "LIBERADO" uno encima de otro (1:54, 2:06, 3:00), "+7 LIBERADOS", etc., tapando enemigos.
- Acción: limitar cuántos textos flotantes coexisten, agruparlos ("+3 LIBERADOS") y darles prioridad menor que las amenazas.

**H-05 · Información del jefe amontonada — ALTA**
- Se ve: "FASE 3/4 · PATAS BLINDADAS: APUNTÁ AL IMPLANTE" se pisa con "86/100" de la vida del jugador (7:30–8:18); la barra del jefe queda parcialmente detrás del panel del jugador (7:54); nombre y barra del robot son chicos y quedan pegados al borde superior.
- Acción: indicador de jefe independiente del HUD principal con nombre, salud, fase actual y una instrucción breve y temporal. Debe entenderse sin leer una oración larga mientras se esquivan disparos.

**H-06 · Avisos pequeños y de bajo contraste — BAJA**
- Se ve: toasts como "MOSCA", "MOSCA VERDE", "GUSANO DE COMPOST", "ALGO SE MUEVE EN LAS TELARAÑAS" en gris pequeño arriba.
- Acción: darles zona propia, mejor contraste y duración suficiente (sin pisar el HUD).

## GRUPO 2 — Presentación: menú, transiciones, intro y resultados (Tanda 2)

**H-07 · Elementos de desarrollo visibles — ALTA (A)**
- Se ve: botón "Laguna (prototipo - debug)" en el menú principal; contador de FPS naranja en la esquina de la grabación; el subtítulo "UNA PEQUEÑA ABEJA, UN MUNDO ENORME" se pisa con la cabeza de la abeja del título.
- Acción: separar la configuración de desarrollo de la de presentación (basta una bandera de debug, no hace falta borrar nada). Corregir el solapamiento del subtítulo.

**H-08 · Transición intro → nivel — ALTA (A)**
- Se ve: tras el logo hay ~2 s de negro y ~2 s de pantalla gris lisa (≈0:34–0:37) antes del nivel; parece una escena sin cargar.
- Acción: precargar la escena y usar fundido; evitar cualquier frame gris. Revisar la carga de escena y la presentación.

**H-09 · Intro casi silenciosa y subtítulos — MEDIA**
- Se ve: la secuencia narrativa (≈0:05–0:35) tiene audio extremadamente bajo comparado con el resto.
- Validar: ¿viene del juego o de la configuración de captura? Si es del juego: música ambiental, zumbidos alienígenas y transición musical al inicio jugable. Revisar cuánto tiempo queda cada subtítulo completo tras el efecto de escritura.

**H-10 · Pantalla de victoria — MEDIA**
- Se ve (8:54): "LEVEL 01 COMPLETADO" mezcla inglés con español; textos grandes superpuestos al escenario con el HUD del gameplay todavía visible; "LIBERADOS 410/499 · PUNTAJE 153355 · MEJOR COMBO x73" sin explicación ni rango.
- Acción: pantalla de resultados independiente (sin HUD de juego), todo en español, con los colores del juego; explicar qué significa liberar 410/499 y mostrar un rango simple (S/A/B) para dar motivo de repetir. Conservar la transición Enter/R existente.

## GRUPO 3 — Legibilidad del combate y del jugador (Tanda 3)

**H-12 · Jerarquía visual de colores y efectos — ALTA**
- Se ve: la separación conceptual dorado (Bee) / cian (aliens) es buena, pero en las olas intensas se acumulan proyectiles cian, implantes, círculos de liberación, proyectiles dorados, partículas de recompensa y destellos. En el nivel de día (≈0:36–4:00) Bee, sus balas y el polen son amarillos sobre fondo beige/amarillo.
- Acción: jerarquía estricta — disparos de Bee: miel-dorado, silueta compacta; proyectiles peligrosos: cian intenso con borde muy definido; implantes: cian fijo y reconocible; liberación: expansión suave y breve, distinta de un proyectil; polen: amarillo cálido menos luminoso; ataques especiales: forma y señal propias; partículas ambientales: menos brillo y densidad en combate. Reducir las partículas tras liberar muchos enemigos a la vez. Los efectos deben ayudar a entender qué pasó, no ocultar lo que viene.

**H-13 · Bee necesita más protagonismo visual — ALTA**
- Se ve: Bee mide ~60 px sobre 1152 y se pierde entre partículas, pasto y enjambres; también cerca de los bordes del encuadre.
- Acción (en este orden): revisar escala aparente según la cámara, márgenes de movimiento dentro del viewport, contraste y contorno de Bee contra el fondo, visibilidad de los disparos de su blíster, encuadre en movimientos verticales. Solo si sigue perdiéndose, aumento moderado (+20–30 %) separando escala visual de hitbox.
- Aceptación: siempre se responde al instante: ¿dónde está Bee?, ¿hacia dónde ataca?, ¿qué amenaza tiene más cerca?

**H-14 · Feedback de daño e invulnerabilidad — ALTA**
- Se ve: la vida pasa de 80 a 35 entre 3:18 y 3:24 sin una causa visible ni una señal de daño clara. Después hay un "+10% VIDA" (≈3:24).
- Acción: señal breve y clara al recibir daño (destello, sacudida leve, indicador de dirección o tipo), e intervalo de invulnerabilidad coherente si esa es la regla elegida.
- Validar en código: que ningún proyectil invisible, enemigo fuera de pantalla o efecto ya eliminado pueda dañar. No afirmar colisiones rotas sin revisarlas.

**H-15 · Líneas naranjas largas sin significado claro — MEDIA (D)**
- Se ve: líneas naranjas que cruzan media pantalla (0:36, 1:24, 2:42, 3:30). No está claro si son telegrafiado de un ataque enemigo o un efecto del jugador.
- Acción: identificar qué son en el código. Si dañan, que se lean inequívocamente como peligro (forma y color propios del peligro); si son decorativas o de otra mecánica, diferenciarlas o reducirlas.

**H-16 · Mecánica de apuntado poco clara — MEDIA (D)**
- Se ve: la retícula aparece solo a ratos y lejos de Bee (6:06, 6:30). No es evidente si se apunta libremente o se dispara en línea recta.
- Acción: determinar el esquema real en el código. Si hay mira, que esté siempre visible y se distinga del resto; si no la hay, no mostrar una retícula engañosa.

**H-17 · Encuadre y oclusión — ALTA**
- Se ve: enemigos de suelo (hormigas, gusanos, robot) pegados y cortados por el borde inferior (1:00, 4:12, 5:24, 6:12–6:36), con una franja jugable de suelo muy angosta; pasto de primer plano grande que tapa a Bee; columnas azules translúcidas a pantalla casi completa (2:24, 2:30) de las que no se sabe el origen (¿agua/manguera?).
- Acción: ajustar parámetros de encuadre y límites de movimiento (no reescribir la cámara); que los enemigos de suelo se vean completos; limitar la opacidad/tamaño de elementos de primer plano durante el combate; identificar y, si hace falta, rediseñar la columna azul.

## GRUPO 4 — Ritmo, oleadas y combo (Tanda 4)

**H-11 · Saturación por enjambres — CRÍTICA**
- Se ve: ≈2:34–2:54, ~30 moscas formando una sola masa oscura, concentradas arriba a la derecha y detrás del HUD, con disparos, efectos de liberación, partículas y mensajes simultáneos. Se repite en oleadas posteriores. Los enemigos dejan de leerse como amenazas independientes.
- Acción: cambiar la filosofía de generación — la dificultad sube por la combinación de enemigos y patrones, no por la cantidad. Ejemplo de encuentro: dos voladores con ataques dirigidos + tres hormigas por el suelo + una amenaza fija que obligue a moverse; la siguiente oleada altera el patrón de movimiento. Presupuesto de amenazas activas (máximo de enemigos que disparan a la vez, de proyectiles hostiles simultáneos y prioridad de efectos). Los enjambres gigantes se reservan para momentos especiales con formaciones legibles.

**H-19 · Ritmo demasiado uniforme — ALTA**
- Se ve: casi 5 minutos con la misma intensidad (≈0:36–6:00); el único cambio es el color de la hora del día y los carteles "ZONA n/7".
- Propuesta orientativa (no tiempos obligatorios): introducción jugable (baja) → primeras oleadas presentando enemigos por separado (media) → primer pico (alta) → respiro y checkpoint (baja) → tramo avanzado y minijefe (creciente) → jefe final. Dejar intervalos de 3–4 s sin enemigos para respirar y ver el jardín.

**H-20 · Combo vs. transiciones — ALTA**
- Se ve: el combo llega a x72 y vuelve a x0 en varios momentos (≈2:25–2:32, 3:18, 4:42), coincidiendo con huecos entre oleadas. "META x8" no se entiende. La relación polen–combo–Frenesí no es evidente para un jugador nuevo.
- Validar en código: ¿el temporizador del combo sigue corriendo cuando no hay ningún enemigo disponible?
- Acción: diferenciar tiempo de combate activo / transición sin objetivos / error del jugador; pausar el temporizador durante las transiciones controladas por el director de oleadas. Indicación visual breve al llenar el polen y activar el Frenesí, en vez de instrucciones permanentes en el HUD.

**H-21 · Dirección de cámara por encuentro — MEDIA**
- Es un shoot 'em up lateral de avance automático; funciona. No transformar el sistema.
- Acción ligera: la cámara prepara el encuadre cuando se acerca una oleada, da protagonismo a un enemigo importante y establece una zona de combate controlada al comenzar un jefe.

## GRUPO 5 — Balance y rendimiento (Tanda 5)

**H-22 · Daño, curación, checkpoints y recuperación — ALTA (a validar)**
- Se ve: la vida casi no baja entre 1:00 y 3:00; cae bruscamente en 3:18–3:24; llega a 19/100 (~5:18) y 29/100 (~5:24); empieza el jefe final con la salud recuperada (~6:56). No se ve el origen ni la frecuencia de curación.
- Acción: auditar la curva de daño/curación, la política de recuperación entre encuentros y el uso de polen y bombas; correr partidas completas con métricas antes de tocar números.

**H-23 · Caída de FPS — ALTA (a perfilar)**
- Se ve: ~44–46 FPS (otro análisis: ~41) en ≈2:36–2:41, coincidiendo con la oleada más cargada; el resto marca 54–60. Podría intervenir el software de grabación, pero justifica investigar.
- Acción: perfilar cantidad máxima de enemigos activos, proyectiles simultáneos, partículas de liberación, objetos instanciados y eliminados por segundo, tiempo en física y scripts, coste de renderizado. Primero identificar el cuello de botella; **no** bajar los gráficos en general. Objetivo: estabilizarse cerca de 60 FPS en el hardware de referencia antes de permitir oleadas mayores.

## GRUPO 6 — Jefes (Tanda 6)

**H-24 · Robot Caminante (≈6:08–6:52) — ALTA**
- Funciona: el telegrafiado rojo en el suelo se lee bien, la idea cambia el tipo de combate.
- Se ve: el modelo se pone completamente blanco en algunos frames (6:12, 6:18, 6:36) — parece un destello de impacto demasiado fuerte o largo, o un material faltante (a validar); queda tapado por el prop de la lata (6:06–6:30) y cortado por el borde inferior; nombre y barra poco legibles.
- Acción: cada ataque importante con secuencia reconocible: preparación → ataque → recuperación → nueva oportunidad (el jugador aprende observando, no recibiendo daño). Revisar el feedback de daño para que el enemigo no parezca simplemente parpadear. Barra de vida independiente del HUD (ver H-05).

**H-25 · La Tarántula (≈6:56–8:48, 1 min 52 s) — ALTA**
- Funciona: buena base — grande, movimientos verticales, implante identificable, cuatro fases en la barra.
- Se ve: sale parcialmente del encuadre (≈7:12, 7:20, 7:52, 8:06, 8:36–8:42) y queda solo con patas visibles, así que el punto débil casi no se ve; modelo marrón oscuro que se funde con el fondo violeta y las rocas grandes; franja roja de ataque a todo lo ancho (7:54, 8:30); instrucción en texto diminuto; durante buena parte del combate el combo queda en x0.
- Acción: límites verticales y encuadre propios de la arena; si la salida de pantalla es intencional, con señal anticipatoria clara. Implante vulnerable: cian pulsante con contorno y reacción diferenciada; superficie blindada: rebote breve sin aspecto de daño efectivo; cambio de fase con animación reconocible y ventana breve para reposicionarse. Cada fase con personalidad propia: 1 Presentación (movimientos y ataques básicos) → 2 Blindaje (mecánica del punto débil) → 3 Presión (combina patrones aprendidos) → 4 Furia (más ritmo y un ataque característico de cierre). No sumar proyectiles por sumarlos. Mejorar contraste de silueta contra el fondo.
- Derrota (≈8:44–8:50): hoy la araña camina fuera de pantalla. Es coherente con la regla "los animales no mueren, se les destruye el implante y recuperan la libertad", pero falta el momento de recompensa: estallido del implante, pausa o cámara lenta, animación de alivio/liberación elaborada, sonido de victoria y una breve transición hacia los resultados.

## GRUPO 7 — Pulido final (Tanda 7, más adelante)

**H-26 · Coherencia artística — MEDIA (C)**
- La intro/título (arte pintado, Bee con armadura, taladro y cañón en antena) no coincide con el juego (Bee pequeño y simple; mundo low poly de sombreado plano, sin contorno). El robot y la araña tienen más detalle que el mundo. Estilo elegido: toon/cel shading con contorno. Se aborda cuando las mecánicas estén cerradas, sin sacrificar la identidad actual.

**H-27 · Variedad y repetición del escenario — MEDIA (C)**
- Cerca y casa de fondo planas que se repiten, mismo set de props, suelo plano; poco parallax; sin puntos de referencia únicos. Reacomodar los assets existentes por zona; no encargar assets nuevos todavía.

**H-28 · Audio — ALTA (a validar)**
- Música ambiental, SFX de disparo/impacto/liberación y transiciones. Validar primero si el volumen bajo de la grabación es del juego o de la captura.

---

## Lo que ya funciona (no tocar)

- Identidad artística: jardín gigante visto desde la escala de una abeja, transición del atardecer a la noche violeta.
- Separación conceptual de colores: energía miel-dorada de Bee vs. tecnología cian alienígena.
- Mecánica de liberar animales controlados (implante cian como objetivo).
- Telegrafiado rojo del robot; fases segmentadas en la barra de la tarántula.
- Cambio automático entre pistas de controles de teclado y mando.

## Tandas y criterio de cierre

| Tanda | IDs | Cierre |
|---|---|---|
| T0 | Auditoría de contexto (solo lectura) | `docs/AUDITORIA_CONTEXTO.md` |
| T1 | H-01 a H-06 | HUD no tapa nada; sin textos pisados ni cursor |
| T2 | H-07 a H-10 | Menú limpio, sin frame gris, resultados claros |
| T3 | H-12 a H-17 | Bee/amenazas se identifican al instante; daño con feedback |
| T4 | H-11, H-19, H-20, H-21 | Sin masas ilegibles; combo justo; ritmo con picos y respiros |
| T5 | H-22, H-23 | Curva de daño razonable; FPS estables ~60 |
| T6 | H-24, H-25 | Jefes legibles, con estados claros y derrota memorable |
| T7 | H-26 a H-28 | Pulido final |

Después de cada tanda: el desarrollador juega el mismo tramo, graba 2–3 minutos y compara contra este informe antes de pasar a la siguiente.
