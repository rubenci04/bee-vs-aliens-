# Bee vs Alien — Adenda 2 (segundo video, Nivel 1 después de la T1)

Complementa `docs/INFORME_GAMEPLAY_FUSIONADO.md`. Mismas reglas: trabajar solo los IDs de la tanda pedida, distinguir A (bug confirmado) / B (observado) / C (mejora de diseño) / D (validar), y no atribuir causas técnicas sin evidencia.
Fuente: grabación de 8 min 32 s (comienza en el menú y termina justo después de la Tarántula, sin pantalla de resultados). Los tiempos (m:ss) son de ese video.

## 1. Estado de la T1 verificado en el video

- **H-01 OK:** el HUD ahora es compacto (VIDA en hexágonos con "96/100", POLEN, bombas, SHIFT, Z) y ya no tapa a Bee ni a los enemigos. COMBO queda arriba a la derecha, también compacto. La leyenda de controles aparece solo un momento (0:30) y como consejo contextual (3:06).
- **H-02 OK:** desapareció el texto cian de debug y el "BASE" suelto. "SPREAD n s" entra sin pisarse.
- **H-03 OK en gameplay:** no se ve el cursor del sistema jugando (sí en el menú, que es normal).
- **H-04 parcial:** los "LIBERADO" ya no se apilan tanto, pero siguen apareciendo textos grandes que tapan enemigos ("+13 LIBERADOS" a 5:36, "+3 LIBERADOS / LIBERADO" juntos a 2:30). Bajar tamaño y opacidad, o anclarlos arriba.
- **H-05 OK:** barra del jefe independiente con "FASE n/4" debajo. La instrucción "PATAS BLINDADAS: APUNTÁ AL IMPLANTE" (7:30) sigue siendo diminuta.
- **H-06 pendiente:** los avisos ("NUBE DE MOSCAS", "MARIQUITA", "GUSANO DE COMPOST") siguen chicos y de bajo contraste, a veces en medio de la pantalla.
- **Pendiente porque T2 no está aplicada:** botón "Laguna (prototipo - debug)" y contador de FPS visibles; pantalla gris lisa antes del nivel (≈0:24).

## 2. Correcciones a hallazgos anteriores

- **H-15 (líneas naranjas) — la hipótesis de la auditoría probablemente era incorrecta.** En las secuencias a 3 fotogramas por segundo (2:23–2:27 y 3:22–3:26) la línea naranja nace en la posición de Bee y termina en el rombo de fijación de un enemigo; en el cuadro siguiente Bee sigue en el mismo lugar. Eso encaja con el **ataque de Aguijón dibujado como un rayo instantáneo**, no con una mira enemiga. Es una inferencia del video: Claude Code debe confirmarla en el código del aguijón antes de actuar (ver H-32).
- **H-23 (FPS) — sigue, y ahora con números.** La base subió a ~90–100 FPS, pero entre ≈2:28 y 2:48 (la "NUBE DE MOSCAS") cae a ~35–70 (mínimo visto ≈35). No hay otra caída comparable en el resto de la partida (81–84 en un par de momentos). La T1 no lo tocó.
- **H-14 (daño) — posible avance a confirmar.** A 5:36 Bee aparece casi blanco y a 8:12 con un anillo blanco. Puede ser un destello de golpe o un estado de invulnerabilidad. Confirmar en el código qué es y si es intencional; si lo es, el hallazgo se reduce a hacerlo más consistente.
- **H-20 (combo) — sigue igual:** vuelve a x0/x1 en 2:54, 3:12 y 4:42, y queda en x0 durante todo el Robot y la Tarántula.
- **H-24 (Robot blanco) — sigue:** a 6:36 aparece una pata/figura totalmente blanca. El robot sigue parcialmente tapado por la lata de fondo y cortado por el borde inferior.
- **H-25 (Tarántula) — sigue:** vuelve a salir del encuadre por arriba (7:18, 7:30–7:36, 7:54, 8:00, 8:18). Mejoró que la barra ya no se pisa. La franja roja de ataque a todo lo ancho vuelve a verse (7:42); las diagonales rojas (7:12, 7:48, 8:06) se leen bien. No se puede evaluar la derrota: el video termina antes de los resultados.

## 3. Hallazgos nuevos

**H-29 · Proyectiles y ataques enemigos casi imperceptibles — ALTA (B)**
- Se ve: disparos de hormiga = rayitas violeta/azul finas y semitransparentes (1:36, 4:18, 4:42, 5:36, 6:00); escupitajo de mosca = estela verde sobre fondo verde/amarillento (1:54, 3:48–4:00); gusanos y caracoles = orbes cian muy chicos a ras del suelo (3:12–4:42) y telegrafiado naranja sobre suelo marrón (arcos y franjas naranjas, 3:12–4:30, 5:36); mariquita: no se ve ningún disparo identificable en todo el video (validar si dispara; si lo hace, es invisible).
- Causa visual: comparten gama con el fondo (verde, amarillo, naranja, marrón, violeta) y los proyectiles son finos, sin borde ni núcleo claro.
- Acción: regla de peligro única para todo ataque que dañe: **núcleo claro/blanco + color saturado (cian o magenta) + borde oscuro + tamaño mínimo**, y mantener el dorado exclusivo de Bee. Distinguir por forma, no solo por color: hormiga = dardos, mosca = glóbulo, gusano/caracol = onda o anillo en el suelo. Telegrafiados de suelo con borde claro y más opacidad. Verificar contra la paleta de día y la de noche. Documentar en una tabla enemigo → forma/color/tamaño elegidos.

**H-30 · Hojas y partículas ambientales en exceso durante el combate — ALTA (B)**
- Se ve: 5–10 hojas pardo-anaranjadas cayendo a la vez (1:42, 3:06, 4:00 y más), polvo/partículas amarillas y pasto de primer plano translúcido; las hojas comparten color con hormigas y proyectiles.
- Acción: presupuesto de partículas ambientales ligado a la intensidad del combate (en calma, atmósfera completa; en combate, pocas hojas, menos opacas, desaturadas y más lejos del plano de acción). Que ninguna hoja pueda confundirse con un enemigo o un proyectil.

**H-31 · Paleta de día lavada y de bajo contraste — MEDIA (C)**
- Se ve: bruma amarillenta general, disco solar grande y pálido, fondo beige; todo lo amarillo/verde pierde contraste (afecta a Bee, polen y proyectiles). La noche (violeta) contrasta bastante mejor.
- Acción: ajustar parámetros de ambiente (niebla, brillo y tamaño del sol, contraste) sin tocar assets; el objetivo es que una captura en escala de grises siga permitiendo distinguir a Bee, enemigos y proyectiles.

**H-32 · Animación del Aguijón: debe ser una embestida de Bee — ALTA (C, pedido del desarrollador)**
- Hoy: línea naranja instantánea desde Bee hasta el enemigo fijado; Bee no se mueve.
- Objetivo: al activar el Aguijón, Bee **sale disparada rápidamente hacia el enemigo más cercano en cualquiera de las direcciones** (360°), orientando el cuerpo y golpeando con el aguijón por delante; breve estela de movimiento, impacto con destello y retroceso o reposicionamiento corto. Duración orientativa 0,15–0,3 s.
- Mantener: aguijón siempre disponible (sin carga) tal como está definido, y la regla de que el aguijón es parte vital de Bee (perderlo = perder la vida) si ya está implementada.
- Decisiones a validar con el desarrollador: invulnerabilidad durante la embestida, alcance máximo, qué pasa si no hay enemigo cerca (embestida corta en la dirección de mira o no activar), y cómo convive con la pirueta.

**H-33 · Hormigas "flotando" al salir del hormiguero — MEDIA (A probable)**
- Se ve (≈2:35–2:38): dos hormigas aparecen a media altura al costado del montículo, por encima de la fila de hormigas que camina en el suelo; no hay entrada ni agujero y parecen deslizarse por el aire junto a la ladera.
- Acción: confirmar en el código dónde se instancian y a qué altura (Y); anclarlas al carril del suelo; darles una entrada visible (boca del hormiguero, escala/aparición desde la abertura, polvo) y que bajen al carril con una animación coherente.

**H-34 · Cámara dinámica en eventos de cruce — MEDIA (C, pedido del desarrollador)**
- Hoy la cámara es lateral fija todo el nivel. Se amplía H-21 con señales de cámara ligeras y reversibles, atadas a eventos concretos: leve alejamiento durante la nube de moscas, acercamiento al aparecer un minijefe, desplazamiento/aceleración breve en los eventos de cruce (regadera, enjambres) y una zona de combate controlada al empezar los jefes. Sin reescribir el sistema de cámara.

**H-35 · Posible modo en tercera persona (Star Fox / Kid Icarus) — SOLO ANÁLISIS**
- No implementar nada. Producir `docs/ANALISIS_TERCERA_PERSONA.md` con: qué sistemas actuales se reutilizan sin cambios (HUD, jerarquía visual, implantes/liberación, combo, aguijón, daño), qué hay que rehacer (cámara, límites de movimiento, director de oleadas, orientación de enemigos y suelo, arenas de jefe, escala de assets), qué niveles se prestan (Cielo, Espacio) y un prototipo mínimo propuesto en una rama aparte, con costo estimado. El Nivel 1 lateral no se toca.

## 4. Mapa de tandas actualizado

| Tanda | Contenido | IDs |
|---|---|---|
| T0 | Auditoría de contexto | hecha |
| T1 | HUD y textos | hecha (ver sección 1; H-04 y H-06 quedan para retoques) |
| T2 | Menú, transición, intro, resultados | H-07 a H-10 (sin cambios) |
| T3 | Legibilidad de enemigos y ambiente | H-29, H-30, H-31, H-12, H-13, H-17 |
| T4 | Aguijón, daño y hormigas | H-32, H-14, H-15 (reinterpretado), H-16, H-33 |
| T5 | Oleadas, ritmo, combo y cámara dinámica | H-11, H-19, H-20, H-21, H-34 |
| T6 | Balance y rendimiento | H-22, H-23 |
| T7 | Jefes | H-24, H-25 |
| T8 | Pulido final | H-26, H-27, H-28 |
| T9 | Análisis de tercera persona (solo lectura) | H-35 |
