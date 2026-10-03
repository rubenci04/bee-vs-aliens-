# BEE LEVEL 01 — ARCADE DIRECTOR BLUEPRINT 01

**Tipo:** diseño de juego + dirección de nivel. **Es un plan: no cambia gameplay, spawn table, balance, escenas ni assets.**
**Estado del código analizado:** `master` en `04f11fa` (Fairness → UFO Boss → Challenge & Balance → Arcade Pressure 01 → Combat Pattern & Density 02), suite 33/33.
**Herramienta de medición (solo lectura):** `dev/director_blueprint/gap_analysis.gd`; eventos y tiempos reales: `dev/arcade_pressure_review/sim_level.gd`.

Referencia de *sensación*, no de contenido: el ritmo de **The Flying Hamster** (pantalla siempre viva, amenazas de distinta escala, formaciones, set pieces cortos, respiros que siguen siendo interesantes, sorpresa y humor visual, bosses claramente distintos al recorrido). No se copian personajes, enemigos, bosses, armas, arte ni patrones.

---

## 1. Baseline (código real, no cifras históricas)

Jugador simulado: bot que sigue la altura del enemigo más cercano, no esquiva, no muere, dispara cada **0,45 s** (eficiente), **0,6 s** (razonable, referencia principal) o **0,8 s** (moderado).

| Dato | Valor actual |
|---|---|
| Longitud / scroll | 360 m a 2 m/s (180 s de viaje base) |
| Eventos / enemigos | **24 eventos / 64 enemigos** (Wasp 22, Probe 16, EyeDrone 13, Turret 6, Speeder 4, Walker 2, Organic 1) |
| Eventos de 4 unidades | 3 (X=170, 310, 340); la 4.ª entra ≥5 s tarde |
| Formaciones con nombre | 4 (A: Probe+Wasp X=40; D: dos Probe X=82; B: Eye+Turret X=170; C: Walker+Eye+Wasp X=296) |
| Llegada al jefe (UFO) | **205 s / 211 s / 223 s** (eficiente / razonable / moderado) |
| Jefe + cierre | approach 3,2 s + pelea ≈45–60 s (HP 1300, DPS razonable ≈21) + muerte 2,3 s + 4 m de scroll ≈2 s |
| **Duración total estimada** | **≈4:20 – 4:50** (razonable ≈4:35). El playtest humano previo a los dos últimos passes fue 4:05 |
| Hard gates | 3 (X=254 Organic, 296 Walker, 340 última defensa) |
| Giant Human | X=140 (≈70 s), alerta + cruce ≈9,5 s, scroll detenido |
| Checkpoint | X=190 (≈104 s) |
| Iluminación | mañana → mediodía X=100–180 (50–90 s); mediodía → atardecer X=210–290 (105–145 s) |
| Pickups | 17 polen, 2 cápsulas Spread (X=22, 222), 2 Bomb (X=166, 318) |
| Destructibles | 8 cajas (X=18, 43, 120, 153, 198, 242, 282, 343) y 8 piedras: 5 pequeñas, 2 medianas, 1 estructural (X=205) |
| Landmarks | botella gigante X=41, tronco hueco X=55, botella lejana X=188, extensión de suelo X=175, tallos/flores y basura (Style C) |
| Amenazas simultáneas | 2 hasta X=150, 3 después; máx. medido 3 enemigos |
| Proyectiles hostiles (jugador razonable) | promedio 0,76, pico 8; peor caso controlado con 3 tiradores vivos y Bee sin disparar: pico 14 / promedio 8 |
| Presencia de fuego a distancia en pantalla | 33 % / **44 %** / 57 % (eficiente / razonable / moderado) |
| Tiempo sin amenaza visible | 23 % / **20 %** / 15 % |

Medido con otra definición (todo enemigo vivo, esté en pantalla o no), el sim del pass 02 da 33 % / 28 % / 22 %. Ambas son válidas; este documento usa la primera (amenaza *visible*).

## 2. Diagnóstico

**Problema principal: no faltan mecánicas ni densidad; falta dirección del ritmo.** El nivel es un metrónomo.

1. **Cadencia uniforme.** Los 24 eventos están a 14 m (7 s) uno de otro y todos usan la misma plantilla: *grupo de 2–4 entra por el borde derecho → ataca → muere o se va → hueco → siguiente grupo*. No hay microeventos entre medias, ni eventos largos, ni dos eventos solapados a propósito, ni un evento que ocupe más de 7 s sin ser un hard gate.
2. **Curva plana.** La intensidad se mueve entre 2 y 4 durante ≈190 s (sin valles reales hasta el jefe), así que no hay "pico" porque no hay "valle" que lo contraste.
3. **Un solo eje de variación.** Cambian las familias pero no la *escala*, la *dirección de entrada* (siempre desde la derecha) ni el *contexto*. Los enemigos aéreos miden ≈1 m; solo el humano y el jefe cambian la escala.
4. **El mundo no participa en las peleas.** Piedras, cajas y polen están en posiciones fijas sin relación con los encuentros; no hay eventos ambientales ni "cosas que pasan" fuera de los enemigos.
5. **Respiros que son aire muerto.** Los huecos de 3–7 s tienen solo polen o un landmark estático (sección 3).
6. **Encuentros consecutivos que se sienten iguales.** Ej.: X=198 (Probe+Speeder+Eye) → 212 (Turret+Eye+Probe) → 226 (Wasp+Probe+Wasp) → 240 (Eye+Speeder+Wasp): cuatro grupos de 3 aéreos/terrestres mezclados, mismo tamaño, misma entrada.
7. **Ya conseguido y a conservar:** presión de fuego legible (aimed/fan/burst), Wasp con ciclo completo, piedras rompibles, humano con corredor seguro, jefe.

## 3. Decision gaps

**Definición.** Un segundo es *decision second* si ocurre al menos una de: hay un enemigo vivo en pantalla, un proyectil hostil, el humano/jefe como peligro, una cápsula de poder a la vista, una caja o roca todavía en pie en la ventana visible, o un *momento visual diseñado* (landmark, checkpoint, centro de una transición de luz). El **polen** se mide aparte: es una decisión de ruta pasiva, no cuenta como evento. Un **decision gap** es un segundo sin ninguna de esas cosas. Además se listan los *tramos silenciosos* (≥3 s sin enemigo, proyectil ni peligro) y su contenido.

**Resultado (jugador razonable; entre paréntesis eficiente / moderado):**

| Medida | Valor |
|---|---|
| Decision gaps estrictos ≥2 s | **1** (5 s: la apertura, X=2–10) — igual en los tres jugadores |
| Tramos silenciosos ≥3 s | 7 (8 / 6): 34 s en total |
| Tramos "aburridos" (silencio + solo polen o nada) | 5 s |
| Tramos "débiles" (silencio + solo roca/caja/polen, sin power-up ni momento) | 3 tramos, 14 s |

Tramos silenciosos reales (razonable) y qué los llena:

| # | Tiempo | X | Longitud | Contenido | Clasificación |
|---|---|---|---|---|---|
| 1 | 0–5 s | 2–10 | 5 s | solo polen | **gap aburrido** |
| 2 | 9–12 s | 20–24 | 3 s | cápsula Spread + caja | evento (power moment) |
| 3 | 65–69 s | 132–138 | 4 s | luz de mediodía; precede a la alerta del humano | respiro de tensión |
| 4 | 80–87 s | 143–155 | 7 s | tras el humano: luz, roca y caja a la vista | **débil** (aire muerto tras un set piece) |
| 5 | 104–108 s | 191–197 | 4 s | checkpoint (solo eficiente) | evento |
| 6 | 133–136 s | 249–253 | 3 s | cambio a atardecer | evento visual leve |
| 7 | 142–148 s | 256–266 | 6 s | tras el hard gate del Organic | débil |
| 8 | 173–179 s | 299–309 | 6 s | tras el Walker; solo una roca | **débil** |
| 9 | 207–210 s | 340 | 3 s | espera previa al jefe, rocas | débil |

**Lectura:** el problema no es la cantidad de huecos sino que **ningún respiro es un evento**: son *esperas*. Y fuera de los respiros, el contenido es del mismo tipo. Por eso el playtest humano "siente vacío" aunque el 80 % del tiempo haya amenazas.

## 4. Macro actos (≈4:30)

Tiempos y X salen del jugador razonable.

| Acto | X | Tiempo | Luz | Intensidad | Objetivo |
|---|---|---|---|---|---|
| **1 · AWAKENING** | 0–68 | 0:00–0:34 | mañana | 1 → 2 | mover, disparar, primera Wasp; formación A; escala del jardín (lata/botella gigantes) |
| **2 · CONTROLLED GARDEN** | 68–140 | 0:34–1:10 | mañana → mediodía | 2 → 3 | Probe, Eye, patrones; **primera fauna controlada (libélula)**; Speeder; piedras |
| **3 · HUMAN TERRITORY** | 140–198 | 1:10–1:50 | mediodía | 2 → 4 → 2 | Giant Human, basura, torretas, caja/roca como obstáculo; **checkpoint (X=190)** |
| **4 · ALIEN ESCALATION** | 198–340 | 1:50–3:15 | mediodía → atardecer | 3 → 4 (con valles) | defensas alien, abanicos, ráfagas; **fauna controlada + contaminación**; Organic y Walker como gates; 4a (198–254) tecnología, 4b (254–310) invasión, 4c (310–340) última defensa |
| **5 · FIRST CONTACT** | 340 → jefe | 3:15–4:30 | atardecer → penumbra | 1 → 5 | silencio, la sombra pasa, reveal del UFO, jefe existente |

El acto 4 es el 40 % del recorrido y es donde más hay que variar (hoy es una sola plantilla repetida).

## 5. Timeline completa (bloques de ≈12 s, jugador razonable)

Intensidad 1–5 propuesta a partir de amenazas, proyectiles y gaps medidos. "Evento actual" es lo que existe hoy; "Qué cambiaría" se desarrolla en secciones 6–13.

| Bloque | X | Evento actual | Proy./s | Ambiente · pickup · interacción | Int. | Decisión principal | Función narrativa | Gap / Qué cambiaría |
|---|---|---|---|---|---|---|---|---|
| 0:00–0:12 | 2–24 | 1 Wasp (6 s) | 0 | polen A; caja X=18; **Spread X=22** | 1 | aprender a volar/disparar; coger Spread | despertar de Bee | **gap 0–5 s** → evento visual de apertura |
| 0:12–0:24 | 26–48 | 2 Wasp desfasadas · Formación A (13/20 s) | 0,3 | botella gigante X=41; caja X=43; polen B | 2 | priorizar; esquivar pasada | primer peligro; escala | ok |
| 0:24–0:36 | 50–72 | W+P+W (27 s) · 2 Eye+Probe (34 s) | 0,7 | **tronco hueco X=55**; polen C; roca X=72 | 2→3 | tunel/vuelo bajo + ranged | jardín intervenido | ok; tronco sin evento propio |
| 0:36–0:48 | 74–96 | Formación D (41 s) · Eye+W+P (48 s) | 0,7 | polen D; roca alta X=96 | 3 | priorizar, mover | primeros patrones | ok |
| 0:48–1:00 | 98–120 | Speeder+P+W (55 s) | 0,7 | luz hacia mediodía; polen E; caja X=120 | 3 | Speeder (pasada) + ranged | variedad | tres encuentros seguidos de plantilla igual |
| 1:00–1:12 | 122–140 | 1 Wasp (62 s) · alerta humano (70 s) | 0 | mediodía; polen F | 2 | tensión | "algo enorme viene" | **ev8 → libélula limpia (5)**; 65–69 s se conserva |
| 1:12–1:24 | 140–149 | **Giant Human** (hazard 8 s) | — | scroll parado; pasillo seguro | 3 | cruzar piernas | ESCALA | set piece existente |
| 1:24–1:36 | 151–173 | Turret+W+Eye (87 s) | 0,7 | roca X=155; caja X=153; **Bomb X=166**; suelo extendido X=175 | 3 | fan de Turret + Wasp | territorio humano | **gap débil 80–87 s** → evento post-humano |
| 1:36–1:48 | 175–197 | Formación B 4 u. (94 s) · Wasp (101 s) | 1,2 | botella lejana X=188; **checkpoint X=190** | 3→4→2 | priorizar 4 | recompensa/ancla | breve valle ok |
| 1:48–2:00 | 199–221 | P+S+E (108 s) · T+E+P (115 s) | 0,9 | caja X=198; **roca estructural X=205**; polen | 3 | combinar | alien se instala | repite plantilla |
| 2:00–2:12 | 223–245 | W+P+W (122 s) · E+S+W (129 s) | 1,4 | **Spread X=222**; roca X=241; caja X=242; luz → atardecer | 4 | evasión + prioridad | pico | encuentro 15/16 iguales |
| 2:12–2:24 | 247–258 | Organic+W+E **gate** (136 s) | 0,1 | atardecer pleno | 3 | cazar al Organic | invasión (cuerpo extraño) | ok |
| 2:24–2:36 | 260–282 | P+E+T (149 s) · T+W+P (156 s) | 1,0 | caja X=282 | 3 | combinar | — | **gap débil 142–148 s** |
| 2:36–2:48 | 284–296 | Walker+E+W **gate** (164 s) | 0,8 | roca X=283 | 4 | pesado + pasada | miniboss del recorrido | ok |
| 2:48–3:00 | 296–311 | (cola del gate) | 0,4 | roca X=307 | 4→2 | recoger **Bomb** | respiro | **gap débil 173–179 s** → power moment |
| 3:00–3:12 | 313–335 | Final 4 u. (179 s) · tres amenazas (186 s) | 1,0 | polen | 4 | gestión de espacio | escalada | ok |
| 3:12–3:24 | 337–340 | **última defensa** 4 u. gate (194 s) | 2,4 | caja X=343 | 4–5 | cerrar la defensa | clímax del recorrido | ok |
| 3:24–3:31 | 340 | cola + espera (207 s) | 2,2 | rocas | 5→1 | — | anticipación | **valle de anticipación** (sombra, luz) |
| 3:31–≈4:35 | boss | UFO: reveal, 3 fases, muerte | — | — | 5 | patrones del jefe | **primer contacto** | sin cambios |

## 6. Curva de dificultad (propuesta)

`VALLE → PENDIENTE → PICO → RESPIRO → NUEVA PENDIENTE → CLÍMAX`

```
Int  5 |                                                  ·   ▲▲  boss
     4 |             ▲                 ▲▲      ▲▲▲▲▲  ▲▲▲
     3 |        ▲▲  ▲ ▲▲    ▲▲▲  ▲▲▲  ▲   ▲▲▲        ▲
     2 |   ▲▲▲▲        valle  ▲        valle        valle
     1 | ▲                                          ▲▲ (anticipación)
        0:00    0:34     1:10     1:50       2:30        3:15     3:31
        ACT 1   ACT 2    ACT 3    ACT 4a     ACT 4b/c    ACT 5
```

Hoy: 2–4 plano. Propuesto: **cuatro valles con contenido** (≈0:12, ≈1:00, ≈2:50, ≈3:25) y **tres picos** (≈0:45, ≈2:05 formación B/combinación + libélula, ≈3:15 última defensa), nunca más de ≈45 s seguidos en intensidad ≥4.

## 7. Taxonomía de eventos

| Categoría | Función | Qué existe | Coste de reutilizar | Notas |
|---|---|---|---|---|
| **POPCORN FORMATION** | ritmo | Wasp/Probe/Eye en grupos | CHEAP | pequeñas oleadas con `delays`, mismas familias |
| **RANGED PRESSURE** | moverse | Probe, Eye, Turret, Walker | CHEAP | ya con aimed/fan/burst |
| **MELEE PASS** | romper posición segura | Wasp (3 pasadas), Speeder (1), Organic (lunge) | CHEAP | |
| **CONTROLLED FAUNA** | liberar, no matar | — | MODERATE | libélula (sección 11) |
| **ENVIRONMENT INTERACTION** | mundo reactivo | rocas rompibles, cajas, tronco | CHEAP | falta *coreografiarlas* con encuentros |
| **HUMAN-SCALE EVENT** | escala | Giant Human (1) | CHEAP–MODERATE | añadir 1–2 objetos enormes baratos |
| **POWER MOMENT** | cambiar ritmo | 4 cápsulas (Spread ×2, Bomb ×2) | CHEAP | mover/anclarlas a valles |
| **VISUAL RESPITE** | respirar sin vacío | luz, landmarks | CHEAP | hoy son esperas |
| **ALIEN ESCALATION** | invasión | defensas Turret/Walker/Organic | MODERATE | decorado de contaminación |
| **SET PIECE** | recuerdo | humano, jefe | MODERATE | 4–6 nuevos, cortos |

## 8. Formaciones (usar familias existentes; no implementar aún)

Hoy todos los enemigos entran por el borde derecho a alturas fijas por puesto (4,6 / 2,6 / 6,0). Una formación necesita solo parámetros de entrada (altura y retraso por unidad, ya existe `delays`; faltaría `y`/`x` por unidad).

| Formación | Descripción | Familias | Lectura | Coste |
|---|---|---|---|---|
| Horizontal | 3 Eye en la misma altura, desfasadas 0,6 s | Eye ×3 | muro de aimed bursts | CHEAP |
| Vertical | columna de 3 a alturas 2/4/6 | Eye/Probe | obliga a elegir hueco | CHEAP |
| Diagonal | de arriba-derecha a abajo-izq | Probe ×3 | cruza la pantalla en barrido | CHEAP |
| V | líder + 2 alas retrasadas | Eye (fan en el líder) | "bandada" | MODERATE |
| Escalonada (staggered) | alturas alternadas | Probe+Eye | refuerza desfase | CHEAP |
| Arriba/abajo | Turret abajo + Eye/Probe arriba | Turret+Eye | "tenaza" vertical | CHEAP (existe B) |
| Pareja escalonada | dos Probe a 3 m, ataques desfasados | Probe ×2 | D ya existe | CHEAP |
| Ola | 3 oleadas de 2 con 4 s entre sí | Wasp/Eye | presión continua | CHEAP (`delays`) |
| Escolta | un tanque + dos ligeros | Walker + 2 Probe / Organic + 2 Wasp | "destruye al grande" | CHEAP |

Reglas: primer tercio 1–2 amenazas con patrones simples; segundo 2–3 con combinaciones; tras el checkpoint 2–3 frecuentes; último tercio 3, picos de 4 solo si las dos extras son ligeras (Wasp/Eye) y hay ruta de escape.

## 9. Amenazas persistentes (4–10 s sin HP absurdo)

"Algo grande viene hacia mí y tengo que destruirlo antes de que llegue":
1. **Escolta del Walker** (X≈296): el Walker entra por la derecha y avanza 8–10 s a 1,9 m/s mientras sus escoltas Probe se reposicionan. Ya existe; falta que *las escoltas lleguen primero* y el tanque entre lento.
2. **Probe pesado con reentrada**: el Probe avanza 8 s con ráfagas, se retira a mitad de camino y vuelve a entrar (parámetro nuevo de la IA; sin HP extra).
3. **Wasp de 3 pasadas** (ya existe, ≈15 s de ciclo si sobrevive).
4. **Turret como territorio**: abanico de 3 que bloquea una banda de alturas mientras otra amenaza empuja a esa banda (formación B).
5. **Organic como cazador** (gate X=254): stalk + lunge, ya persistente.
6. **Libélula controlada** (sección 11): pasadas amplias de 4–6 s hasta que se rompe el implante; la amenaza persistente más "grande" del nivel antes del jefe.

## 10. Respiros: ¿vacío o evento?

`RESPIRO ≠ AIRE MUERTO`. Decisión para cada tramo silencioso real:

| # | Tramo | Decisión | Qué lo llena (barato) |
|---|---|---|---|
| 1 | 0–5 s, X=2–10 | **TURN INTO VISUAL EVENT** | lata o envoltorio gigante cruzando el primer plano + zumbido; la primera Wasp entra antes (≈3 s) |
| 2 | 9–12 s, X=20–24 | KEEP (power moment) | cápsula Spread; ya es evento |
| 3 | 65–69 s, X=132–138 | **KEEP AS TRUE RESPITE** | tensión antes de la alerta del humano (sonido, sin enemigos); la libélula va *antes* (≈58–64 s) |
| 4 | 80–87 s, X=143–155 | **TURN INTO VISUAL EVENT** | secuela del humano: polvo asentándose, caja/roca golpeadas, un escarabajo/caracol animado que cruza, sacudida leve de cámara por los pasos que se alejan |
| 5 | 133–136 s, X=249–253 | KEEP | transición a atardecer es el evento |
| 6 | 142–148 s, X=256–266 | **TURN INTO VISUAL EVENT** | flor contaminada con dispositivos cian (decorado) + sonido alien; sin enemigos 3 s |
| 7 | 173–179 s, X=299–309 | **TURN INTO POWER MOMENT** | mover la recarga de **Bomb** de X=318 a ≈X=302, tras el Walker |
| 8 | 207–210 s + 1,6 s, X=340 | **KEEP AS TRUE RESPITE** | anticipación del acto 5: luz que baja, viento, la sombra pasa; sin enemigos |

## 11. Controlled Fauna (diseño; **no implementar todavía**)

Regla narrativa: **Bee destruye el dispositivo, no al animal.** El cuerpo del animal no recibe daño (feedback "rebote"/sin impacto letal); solo el *implante* es blanco.

**Primera aparición recomendada: LIBÉLULA (Dragonfly)**, X≈120–128 (≈58–64 s), sustituyendo a la Wasp en solitario del evento 8. Es limpia por diseño:
- **Aislada**: sin otros enemigos, justo antes del humano.
- **Implante visible**: placa cian pulsante en el tórax (el único elemento cian de la criatura); el resto del cuerpo, color natural.
- **Ataque**: 3 pasadas amplias en arco de borde a borde (más lentas y largas que la Wasp, telegraph de alas); sin proyectiles. Daño de contacto ≈13.
- **Weakpoint**: hurtbox pequeña en el implante (≈40 HP equivalentes); el cuerpo bloquea los disparos con un destello distinto al de daño.
- **Liberación**: al romperse el implante, la placa estalla, la libélula recupera color, hace un giro de agradecimiento y sale volando; un pequeño chorro de polen como recompensa visual. No hay "muerte".
- **Comprensión**: un texto corto una sola vez ("ROMPÉ EL IMPLANTE") y la silueta limpia son suficientes.

Combinación posterior (Level 01 OPTIONAL): **segunda libélula con escolta** en el acto 4b (X≈262, tras el Organic): libélula + 2 Probe, donde los Probe fuerzan a moverse y la libélula castiga el hover. Tercera (solo si hace falta): un **escarabajo** terrestre cerca de X≈330 (Level 02 por defecto).

**Roster futuro:**

| Fauna | Rol | Escala | Implante | Ataque | Liberación |
|---|---|---|---|---|---|
| **Libélula** (L1) | persecución amplia | ≈2× Wasp | tórax, placa cian | pasadas en arco | placa estalla, giro, se va |
| **Polilla** (L1 tardío / L2) | anti-luz: se acerca a fuentes de luz y arrastra proyectiles | ≈3× Wasp | antenas con "arco" | revoloteo errático controlado + polvo que oculta | rompe antena; vuelo normal |
| **Escarabajo** (terrestre) | tanque a ras de suelo | ≈3× Wasp | dorso | embestida lenta + onda | placa del caparazón |
| **Mariposa** | señuelo/escolta que cubre a otro enemigo | ≈2× Wasp | ala | traza de patrón de aire (ondas) | patrón de alas limpio |
| **Paloma / Gorrión** (L2) | pasadas verticales grandes | ≈6× Wasp | collar | picado desde arriba | collar cae |
| **Gaviota** (L2) | formación de 3 en V | ≈5× Wasp | pata | barrido horizontal | pata |
| **Colibrí** (set piece/miniboss) | rápido, esquivo, mini-jefe | ≈3× Wasp | pico | embestidas + estático | pico |

## 12. Momentos de escala (pocos y memorables)

| Momento | X | Qué es | Coste |
|---|---|---|---|
| **Lata gigante** | ≈10 | lata aplastada en primer plano durante la apertura | CHEAP (reutiliza `small_can`, escalada) |
| **Giant Human** | 140 | ya existe | hecho |
| **Secuela del humano** | 143–155 | polvo, restos, escarabajo cruzando | CHEAP |
| **Gota de agua** (opcional) | ≈215 | gota que cae de una hoja y estalla en el suelo (inofensiva) | CHEAP |
| **Sombra del UFO** | ≈344 | la sombra tapa el jardín antes del reveal | CHEAP (luz/mesh) |

No se proponen zapato aparte, envoltorio animado ni tallo gigante extra.

## 13. Momentos firma (7)

1. **"La lata del despertar"** (X≈10): Bee despierta bajo una lata aplastada enorme y una avispa la ve primero. *CHEAP.*
2. **"A través del tronco"** (X≈55): Formación de Wasp y Probe obligan a elegir entre la boca del tronco hueco y el aire libre. *CHEAP (existe tronco).*
3. **"La primera libélula"** (X≈124): Bee rompe el implante y la libélula, libre, da un giro y se va. *MODERATE.*
4. **"Entre las piernas"** (X≈140): Bee cruza el corredor de un humano gigante mientras una Wasp planea una pasada. *CHEAP (existe + Wasp).*
5. **"Abrir carril"** (X≈205): una Turret dispara su abanico tras la roca estructural; el jugador rompe la piedra vecina para cambiar de altura. *CHEAP.*
6. **"El jardín infectado"** (X≈262): libélula con escolta bajo el atardecer; flores con dispositivos cian. *MODERATE.*
7. **"El último silencio"** (X≈340): se acaba el combate, el viento sube, la luz baja y una sombra enorme cruza la pantalla antes del reveal. *CHEAP.*

(Una octava opcional: **"La Bomb en el hueco"**, X≈302: la recarga de Bomb en la calma tras el Walker.)

## 14. Progresión del lenguaje de proyectiles

| Tramo | Lenguaje | Detalle |
|---|---|---|
| **Temprano** (X<82) | simple | aimed burst del Probe, pasada de Wasp; **Eye sin fan** (solo aimed) |
| **Medio** (X 82–198) | combinado | aparece el **fan** del Eye y de la Turret; Wasp + ranged; formaciones A/D/B |
| **Tardío** (X>198) | composiciones | fan + aimed desde posiciones distintas; ráfaga del Walker; libélula + escoltas; picos controlados (≤14) |
| **Cierre** | silencio → jefe | el jefe hereda aimed/fan (ya implementado) |

Hoy el fan del Eye aparece desde el primer Eye (X=68): cambiar el *gating* por distancia es parte del Pass A.

## 15. Level 2 — visión breve

Cielo. Menos terreno rígido, más profundidad y velocidad: **aves controladas** (paloma, gaviota, colibrí), formaciones en V, **nubes** como cobertura y parallax, **UFOs** que cruzan, enemigos que entran desde Z (cerca/lejos), objetos humanos flotando (globos, cometas, drones civiles). Jardín → cielo con una *transición* (ascenso). Sin diseñar el nivel completo.

## 16. Level 3 — visión breve

Espacio. Flotas y naves como terreno móvil, organismos alien grandes, patrones más densos (sin bullet hell), grandes naves como plataformas/obstáculos, fauna ya no solo "liberable" sino aliada puntual.

## 17. Freshness check (por segmento)

Pregunta por cada tramo: ¿introduce, desarrolla, combina o repite?

| Tramo | Veredicto | Acción |
|---|---|---|
| 0–34 s | introduce (Wasp, Formación A, escala) | añadir lata gigante |
| 34–70 s | introduce (Eye/Probe/Speeder) pero **tres encuentros seguidos iguales** | variar eje (altura/entrada) |
| 70–90 s | introduce escala (humano) | llenar la secuela |
| 90–110 s | combina (B) | ok |
| 110–150 s | **repite** (4 grupos de 3 mezclados) | insertar valle + libélula/formación distinta |
| 150–200 s | desarrolla (gates, Walker) | power moment tras el Walker |
| 200–210 s | combina (última defensa) | ok |
| Jefe | introduce | ok |

Regla: nunca tres encuentros consecutivos con la misma forma de entrada o tamaño.

## 18. Alcance y producibilidad

| Propuesta | Clasificación | Coste |
|---|---|---|
| Ritmo variable (eventos a 9–20 m, microeventos entre grupos), gating del fan por distancia, `y`/`x` por unidad | **LEVEL 01 MUST** | CHEAP |
| Opening visual (lata gigante) + secuela del humano + sombra pre-boss + recarga de Bomb reubicada | **LEVEL 01 MUST** | CHEAP |
| Primera libélula (Controlled Fauna) | **LEVEL 01 MUST** | MODERATE |
| Segunda libélula con escolta, flor infectada, gota de agua | LEVEL 01 OPTIONAL | MODERATE / CHEAP |
| Escarabajo, polilla, mariposa | LEVEL 02 | MODERATE |
| Aves, colibrí miniboss, nubes, entradas desde Z | LEVEL 02 / FUTURE | MODERATE–EXPENSIVE |
| Flotas/naves como terreno | FUTURE | EXPENSIVE |
| Más familias de enemigos, segundo jefe en L1, bullet hell, música/UI/outline en este pass | **DO NOT DO** (aquí) | — |

**Qué NO cambiaría:** longitud/scroll (360 m, 2 m/s), UFO Boss, Giant Human y su corredor seguro, HP y daño por familia, telegraphs, regla de fairness (sin disparo desde fuera de pantalla), HP/ubicación de piedras, Spread (32 × 3 × 8), checkpoint X=190, cámara D y Style C, 4–5 min de duración.

## 19. Roadmap de implementación

Cada pass: rama propia, suite completa antes/después, sin mergear sin tu playtest.

| Pass | Objetivo | Archivos principales | Riesgo | Tests | Depende de |
|---|---|---|---|---|---|
| **A · Director / event restructuring** | `EVENTS` v2 con cadencia variable, microeventos, `y/x` por unidad, gating de patrones por X (Eye fan desde ≈X=96), reubicar Bomb a ≈X=302, mover tramos aburridos; sin assets | `bee_level_01_controller.gd`, `eye_drone_enemy.gd` (gating), escena (cápsula Bomb), tests de nivel/vertical slice | bajo–medio (cambia números de tests) | nuevo `validate_bee_level01_director_v01` (timeline, gaps con `gap_analysis`, 4–5 min, cap de amenazas), suite completa | ninguna |
| **B · Respiros / escala (cheap)** | lata gigante de apertura, secuela del humano (polvo, escarabajo cruzando), sombra pre-boss, flor contaminada | `bee_level_01_scenery.gd`, `bee_level_01_light_progression.gd`, `giant_human_level_visual.gd` (secuela), decor nuevo | bajo | test de props/visual, captura de review | A (posiciones) |
| **C · Controlled Fauna (libélula)** | libélula limpia en X≈124: implante, bloqueo de cuerpo, liberación | script nuevo + escena (código/lofted como el UFO), cue de audio aprobado, controlador | **medio–alto** | nuevo test de fauna (implante vs cuerpo, liberación, checkpoint, fairness), suite | A |
| **D · Alien escalation + set pieces** | segunda libélula con escolta, "abrir carril", jardín infectado, formaciones tardías | controlador, scenery, fauna | medio | test de formaciones/set pieces | A, C |
| **E · Playtest tuning** | ajustar con tu playtest: duración, picos, gaps | solo números | bajo | gap/sim comparados | A–D |
| **F · Visual identity / art polish** | outline polish, identidad visual final | estilo/shaders | medio | tests visuales | E |

**Siguiente tarea exacta recomendada:** *PASS A — Level 01 Director / event restructuring* (solo datos y gating; sin modelos ni sonidos nuevos). Entregables: `EVENTS` v2 con cadencia variable y microeventos según las secciones 5–10, gating del fan del Eye por distancia, `y/x` por unidad, Bomb reubicada a ≈X=302, y un test que verifique **duración estimada 4–5 min, 0 decision gaps estrictos ≥3 s, ningún tramo silencioso ≥6 s sin evento visual y el tope de proyectiles**.

---

### Anexo: cómo reproducir el baseline

```
godot --headless --fixed-fps 60 --path . --script res://dev/arcade_pressure_review/sim_level.gd -- fire=0.6
godot --headless --fixed-fps 60 --path . --script res://dev/director_blueprint/gap_analysis.gd -- fire=0.6
```
`gap_analysis.gd` solo mide: no modifica el runtime. Los *momentos visuales diseñados* que cuenta como decisión son una lista editable en el propio script (`MOMENTS`) y son un criterio de diseño, no una medición física. Limitación: el bot no esquiva ni recoge; los tiempos reales dependen del jugador.

---

## Estado de implementación (Level 01 Transformation Pass 01)

El diseño de arriba se conserva como histórico. Detalle y cifras: `docs/BEE_LEVEL01_TRANSFORMATION_PASS_01.md`.

| Propuesta del blueprint | Estado | Nota |
|---|---|---|
| Ritmo variable, microeventos, `y`/`x` por unidad (Pass A) | **IMPLEMENTED** | EVENTS V2: 31 eventos, 4–16 m, 10 formaciones, 5 actos internos |
| Gating del fan del Eye por X | **IMPLEMENTED** | desde X=96 |
| Bomb reubicada tras el Walker | **IMPLEMENTED** | X=318 → 302 + pulso de recompensa |
| Lata gigante de apertura | **IMPLEMENTED** | código, Style C, detrás del plano |
| Secuela del humano (polvo + escarabajo) | **IMPLEMENTED** | sin sacudida de cámara |
| Sombra pre-boss / "el último silencio" | **IMPLEMENTED** | + caída de luz, zumbido aprobado, respiro 1,6 → 2,6 s |
| Flor / jardín contaminado | **IMPLEMENTED** | con dispositivo disparable que libera la flor |
| Primera libélula controlada (X≈124, sola) | **IMPLEMENTED** | implante 60 HP, 3 pasadas, liberación |
| Segunda libélula con escolta (X≈262) | **CHANGED** | escolta de 1 Probe (no 2), nace en el jardín contaminado |
| Tercera aparición (escarabajo, X≈330) | **DEFERRED** | Level 02 |
| "Abrir carril" (roca + Turret) | **CHANGED** | la roca de X=205 es estructural: se resuelve subiendo, no rompiéndola |
| "Entre las piernas" con Wasp | **DEFERRED** | descartado por fairness: la pasada empujaría a Bee fuera del corredor seguro |
| Gota de agua | **DEFERRED** | opcional |
| Feedback de impacto en sólidos | **IMPLEMENTED** | tronco hueco y roca estructural; la botella no es sólida |
| Reacción de vegetación | **IMPLEMENTED (barata)** | solo helechos de primer plano, tween |
| Escarabajo / polilla / mariposa / aves / colibrí | **DEFERRED** | Level 02 / futuro |
| Pass F visual (contorno, coherencia, lenguaje alien) | **IMPLEMENTED** | contorno por categoría, `BeeAlienPalette` derivada del UFO |
