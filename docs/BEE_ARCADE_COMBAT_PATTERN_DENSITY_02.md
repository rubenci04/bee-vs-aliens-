# BEE ARCADE COMBAT PATTERN & DENSITY PASS 02

Rama `arcade-pressure-01` (sobre `a155a86`, segundo commit del pass; no mergeado). Test: `tests/levels/validate_bee_arcade_combat_patterns_v02.gd`. Herramientas y capturas: `dev/arcade_pressure_review/` (capturas `p2_*`).

## Por qué
El playtest humano no aprobó el pass 01: el nivel seguía fácil, con huecos largos, las Wasp "aparecían, se acercaban y se iban", Probe/Eye/Turret/Walker disparaban poco y sin patrones que obligaran a esquivar. Conservado y aprobado: piedras rompibles e interacción ambiental.

**Principio:** la dificultad no sube con HP, velocidad de bala ni daño (todo igual), sino con presencia sostenida, patrones legibles (AIMED, FAN, oleadas controladas), composición complementaria y evasión. Nada es homing ni aleatorio: cada proyectil sale con una trayectoria recta fija.

## 1. Mediciones BEFORE (pass 01) → AFTER (`sim_level.gd`)
Bot sin esquiva con auto-aim perfecto, a 3 m detrás de la cámara, vida enorme, 60 fps fijos. Tres habilidades de disparo (segundos entre tiros): **0,45** eficiente, **0,6** razonable, **0,8** moderado. BEFORE se midió sobre el commit `a155a86` (el 0,6 no se midió entonces).

| Métrica | BEFORE 0,45 | AFTER 0,45 | AFTER 0,6 | BEFORE 0,8 | AFTER 0,8 |
|---|---|---|---|---|---|
| Enemigos | 53 | **64** | 64 | 53 | **64** |
| Tiempo sin amenaza (hasta el jefe) | 94,3 s (46,9 %) | **68,6 s (33,4 %)** | **58,8 s (27,9 %)** | 71,1 s (33,6 %) | **48,5 s (21,7 %)** |
| Con amenaza a distancia en pantalla | 27 % | 33 % | 44 % | 41 % | **57 %** |
| Disparos hostiles visibles: promedio | 0,28 | **0,68** | 0,76 | 0,46 | **0,95** |
| Pico de disparos hostiles | 4 | 8 | 8 | 6 | 9 |
| Máx. amenazas (enemigos / con disparos) | 3 / 7 | 3 / 10 | 3 / 10 | 3 / 8 | 3 / 11 |
| Disparos hostiles por encuentro | 1,8 | 3,4 | 5,3 | 2,9 | **6,9** |
| Permanencia media de una Wasp (jugador la mata) | 2,6 s | 2,9 s | 3,6 s | 3,9 s | 4,3 s |
| Llegada al jefe | 200,8 s | 205,7 s | 210,9 s | 211,4 s | 223,4 s |

Lectura honesta:
- El objetivo 20–25 % sin amenaza se cumple para el jugador moderado (21,7 %) y casi para el razonable (27,9 %); para el bot eficiente queda en 33 %. Los silencios que quedan son los respiros deliberados: apertura (0–12 m), antes del humano (140 m: 8 s) y los 7 s previos a los hard gates de 254 y 296 m.
- La permanencia de una Wasp sube poco **cuando alguien la mata**, porque un bot con auto-aim acierta un blanco que flota; una Wasp que sobrevive permanece hasta ~15 s (3 pasadas, medido en el test y en un bot de 1,5 s por disparo: 16,3 s). La mejora real es que ahora tiene un ciclo completo de presencia y no se pega.
- Presencia de fuego: ~×2,4 disparos visibles promedio y ~×2,4 por encuentro con ambos jugadores.
- Proyectiles: promedio 0,7–1,0 y pico 8–9 jugando (normal 3–7, intenso 7–10 ✔). El peor caso controlado (tres tiradores pesados vivos 14 s con Bee quieta, sin matarlos) es **pico 14, promedio 8,2** (Probe + Eye + Turret). Con un cuarto tirador (que el nivel no permite: tope 3) llegaría a 17; con dos Probe + Eye, a 16.
- Duración: el scroll no cambió. La llegada al jefe se mueve +5…+12 s según la habilidad (hard gates y pasadas), es decir ~3:25–3:45 hasta el jefe más ~1 min de pelea y cierre: dentro de 4–5 min.
- Daño recibido por el bot que no esquiva: 260 → 284 (0,45) y 500 → 902 (0,8): más presión sin cambiar daño por impacto.

## 2. Patrones por familia (solo Level 01, vía `LEVEL_TUNING`; las escenas base y los POC no cambian)
Daño, velocidad de proyectil, telegraph (windup) y HP: **intactos**. Cada tiro pasa por `BeeShmupFairness.can_fire` (un volley fuera de pantalla se suprime completo). Helper nuevo: `BeeEnemyPatterns` (aimed/fan, paso angular 12–18° según distancia).

| Familia | BEFORE (pass 01) | AFTER |
|---|---|---|
| **Probe** | ráfaga de 2, cooldown 1,6 s, avance 0,5 m/s | **AIMED burst de 3** (0,2 s entre tiros, cada uno re-apunta a Bee al salir y luego va recto) → **recuperación corta 0,8 s** → burst de 3 → **cooldown 2,0 s** con avance lento y reposición vertical; tercio derecho; primer aviso desfasado 0,35 s por puesto. Medido: burst-a-burst 1,8 s, luego 2,95 s |
| **EyeDrone** | ráfaga de 2, cooldown 1,7 s | **alterna** AIMED burst de 3 (aviso cian, 0,4 s) y **FAN de 5** (aviso violeta, 0,6 s) centrado en Bee, paso 14° a ~3,9 m (**hueco entre carriles 0,98 m** frente a 0,68 m de contacto); el fan solo se usa a ≥3 m; cooldown 2,0 s. Medido: aimed3, fan5, aimed3, fan5 |
| **Turret** | un tiro, cooldown 1,45 s | **abanico de 3** a 14° centrado en Bee (carriles de 1,78 m a 6 m), aviso de 0,65 s intacto, cooldown 1,55 s |
| **Walker** | un tiro, recovery 0,9 s | **ráfaga lenta de 3** (0,35 s, cada una re-apunta), 3,65 s entre ráfagas; HP 60, velocidad 1,9 y daño 9 intactos (no es una ametralladora) |
| **Wasp** | 2 pasadas, recuperación 0,9 s | **3 pasadas**, recuperación visible 1,1 s, stalk inicial 2,2/2,9/3,6 s según puesto (medido 3,0 s con el acercamiento), deriva ±0,8 m, **líneas de hover distintas** (0 / +1,1 / −1,1 m) y **nunca dos en WINDUP/DASH a la vez** (0 fotogramas simultáneos con 2 Wasp; ambas atacan 221/223 fotogramas). Sin disparos, dash en línea recta bloqueada |

Ciclo de la Wasp medido: `STALK → WINDUP → DASH → RECOVERY` ×3 con re-stalk de 1,0 s, y `EXIT`. La vida "soft" de los enemigos sube de 11 a **14 s** para que el ciclo completo de la Wasp (~15 s) no sea cortado por el retiro del nivel.

Nota de fairness: el fan se centra en Bee (obliga a moverse) y solo se dispara cuando el hueco entre carriles es ≥0,85 m; por eso el Eye cae a ráfaga aimed si Bee está a menos de 3 m.

## 3. Densidad y formaciones
**53 → 64 enemigos (+11)** en los mismos 24 eventos y las mismas distancias. Por familia ahora: Wasp 22, Probe 16, EyeDrone 13, Turret 6, Speeder 4, Walker 2, Organic 1. Los eventos pueden llevar `delays` (segundos de entrada de cada unidad) para oleadas controladas sin cambiar umbrales; el cap de amenazas simultáneas sigue siendo 2 antes de X=150 y 3 después, así que los eventos de 4 hacen entrar la cuarta unidad ≥4,5 s tarde.

| Evento | X | Antes | Ahora |
|---|---|---|---|
| 1 | 26 | Wasp, Wasp | Wasp, Wasp (desfasadas 2,2 s) |
| 2 | 40 | Probe, Wasp | **Formación A** Probe + Wasp (entra 1,5 s después) |
| 3 | 54 | Wasp, Probe | Wasp, Probe, **Wasp** |
| 5 | 82 | Probe, Wasp | Probe, Wasp, **Probe** (**Formación D**: dos Probe desfasadas) |
| 7 | 110 | Speeder, Probe | Speeder, Probe, **Wasp** |
| 10 | 156 | Turret, Wasp | Turret, Wasp, **Eye** |
| 11 | 170 | Eye, Turret, Wasp | **Formación B** Eye + Turret + Wasp, **Probe** al final |
| 14 | 212 | Turret, Eye | Turret, Eye, **Probe** |
| 17 | 254 | Organic, Wasp (hard) | Organic, Wasp, **Eye** |
| 19 | 282 | Turret, Wasp | Turret, Wasp, **Probe** |
| 20 | 296 | Walker, Eye (hard) | **Formación C** Walker + Eye + **Wasp** |
| 21 | 310 | Wasp, Speeder, Probe | Wasp, Speeder, Probe, **Eye** (tarde) |
| 23 | 340 | Walker, Probe, Turret (hard) | Walker, Probe, Turret, **Wasp** (tarde) |

Progresión: primer tercio 1–2 amenazas con patrones simples (el primer ataque del Eye siempre es aimed); segundo tercio 2–3 con combinaciones; tras el checkpoint (X=190) 2–3 frecuentes; último tercio 3 con la cuarta unidad como oleada tardía. Respiros intactos: eventos 0, 8, 12 y la apertura.

## 4. Rendimiento (`bench_density.gd`, render 1152×648, Intel Arc B580, tramo 290 m → jefe)
| | Frame medio | FPS | CPU render | Nodos máx. | Disparos hostiles máx. |
|---|---|---|---|---|---|
| BEFORE (`a155a86` / master) | 10,11 ms | 99 | 1,1–1,8 ms | 1560 | 5 |
| AFTER | **10,08 ms** | 99 | 1,2–1,5 ms | 1572 | 8 |

Sin regresión. Picos de ~170 ms solo en la primera aparición de cada familia en un proceso nuevo (como antes).

## 5. Test `validate_bee_arcade_combat_patterns_v02`
Probe (bursts de 3 con 9–15 fotogramas de separación, cada tiro apunta a Bee en el instante de disparo, trayectoria fija sin homing, recuperación corta < cooldown largo, daño igual al de la escena, burst suprimido fuera de pantalla), EyeDrone (orden aimed3/fan5/aimed3/fan5, telegraph violeta solo en el fan, 5 tiros en el mismo fotograma, centro apuntado a Bee, pasos 12–18°, hueco >0,85 m, trayectorias rectas), Turret (abanico de 3, aviso ≥0,6 s visible, paso 12–16°, hueco, dispersión vertical), Walker (burst de 3 a ~0,35 s, re-apunta, daño 9, ≥2,5 s entre ráfagas, HP/velocidad intactos), Wasp (stalk ≥2,2 s, 3 pasadas exactas, líneas rectas, salida, presencia ≥9 s; dos Wasp: líneas distintas y 0 ataques simultáneos), nivel (64 = +11 sobre 53, 24 eventos y distancias iguales, `delays` ascendentes y cuarta unidad tardía, HP globales intactos, techo controlado de proyectiles 6–14 con promedio ≤10, sin disparos desde fuera de pantalla en las cuatro familias, checkpoint, UFO 1300 HP/approach 3,2 s, Level Complete tras la muerte del jefe). Tests existentes actualizados solo por números (64 enemigos, vida soft 14 s, ráfagas de 3, techo de proyectiles 14).

## 6. Limitaciones / necesita playtest humano
- Todas las cifras de ritmo salen de un bot que no esquiva y apunta perfecto; la permanencia de la Wasp y la sensación de presión dependen de cómo juegue una persona.
- Fuego enemigo ≈2,4× el del pass 01. Si resulta excesivo, las palancas de una línea están en `LEVEL_TUNING` (cooldowns, `short_recovery`, `fan_every`, `fan_count`). El peor caso sostenido es pico 14 / promedio 8 con tres tiradores vivos y Bee sin disparar.
- Los silencios de 7–8 s antes de hard gates y del humano se conservaron como respiros; si se siguen sintiendo vacíos hay que decidir si añadir una unidad tardía allí.
- No se midió BEFORE para el jugador de 0,6 s.
- Sin cambios: UFO Boss, Giant Human, piedras, Spread, HP, daño.
