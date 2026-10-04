# BEE — PROJECT VIABILITY REVIEW 01

Fecha: 2026-10-04. Rama: `level01-threat-camera-boss-03`. Evaluación directa, sin complacencia. Se apoya en
`docs/BEE_ASSET_LIBRARY_DEEP_AUDIT_02.md`, `docs/BEE_ASSET_SHORTLIST_ACTIONABLE_01.md`, los playtests documentados
(`PLAYTEST_FEEDBACK_01..03.md`), los docs de cada pass y el estado real del repo. **No prometo ventas**: evalúo si el
proyecto puede llegar a un demo atractivo y testeable.

## Veredicto en una línea
**YES, BUT WITH CONDITIONS.** La base técnica y el gancho justifican seguir con *este* core; lo que no está probado es
que sea divertido, y el proceso actual gasta demasiado en medir y documentar en lugar de validar con jugadores.

---

## 0. Base de evidencia (números del repo, hoy)

| Dato | Valor |
|---|---|
| Commits | 52, entre 2026-09-29 y 2026-10-04 (26 el 10-02, 20 el 10-03) |
| Código runtime | 90 scripts, **10.106 líneas** (Level 01 específico: ~2.400 líneas en `scripts/levels/bee_level_01_*`) |
| Tests | 38 suites `validate_*`, **7.630 líneas** (0,75 líneas de test por línea de runtime) |
| Herramientas dev | 61 scripts en `dev/`, 37 carpetas de review |
| Documentos | 43 `.md` en `docs/` + `INFORME_MAESTRO.md` de 2.998 líneas |
| Rendimiento | ~100 FPS sostenido (vsync) en jardín, 4 amenazas, rana y boss fase 2 (Intel Arc B580, GL Compatibility); picos de 37–117 ms la **primera** vez que aparece cada shader |
| Nivel | Level 01, 360 m, 44 eventos, 4 actos, checkpoint en 190 m, boss OVNI de 1.300 HP (62–103 s) |
| Playtests humanos documentados | 3. El último que consta en el repo dice "todavía no es suficientemente desafiante ni divertido" (origen del Rebuild 03). **El resultado del playtest posterior al Rebuild 03 no está en el repo.** |
| Suites corridas hoy (sanity, sin cambios de runtime) | `validate_bee_level_01_vertical_slice` y `validate_bee_threat_camera_boss_v03`: código 0, sin SCRIPT ERROR |

---

## 1. Plugins / tools (objetivo 12)

Estado real: `addons/godot_ai/` (v3.2.1) y `addons/sky_3d/` + `demo/` están **sin trackear en git** y **ninguno está
habilitado** en `project.godot` (no hay sección `[editor_plugins]`).

| Categoría | ¿Hace falta? | Motivo |
|---|---|---|
| animation | No | AnimationPlayer + clips de los packs + animación por código (aleteo por hueso) alcanzan |
| toon / shader | No | Style C ya existe (`assets/style/*.gdshader`). Lo que falta (alpha-scissor, agua) son ~20 líneas de shader, no un plugin |
| particles | No | VFX procedurales funcionan y combinan con el estilo |
| level editing | No por ahora | Para un demo de 2 niveles la tabla `EVENTS` alcanza. Si se pasa a 4+ niveles, conviene extraer eventos a un `Resource`, no un plugin |
| camera | No | contrato de encuadre E ya implementado y testeado |
| profiling | No | el profiler y monitores de Godot + `bench_scenes.gd` cubren |
| dialogue | No | el juego no tiene diálogo (storytelling sin diálogo, §110 del informe) |
| audio | No | buses + pipeline WAV propio |

`godot_ai`: es un puente MCP para que asistentes de IA manejen el editor. No es necesario para producir el juego. Si
se usa: requiere `uv` y un servidor Python, y **su telemetría está activada por defecto** (se desactiva con la variable
de entorno `GODOT_AI_DISABLE_TELEMETRY` o desde su dock). Recomendación: no commitearlo al repo del juego.
`sky_3d`: ciclo día/noche; el nivel ya tiene progresión de luz propia. No habilitar.

# NO NECESITAMOS MÁS PLUGINS AHORA.

---

## 2. Viability gate (objetivo 13)

### TECHNICAL VIABILITY — **SÍ**
- Godot 4.7.2 / GL Compatibility sostiene el juego con margen (≈100 FPS con vsync, ~1.090 nodos en pico; Style C con
  contorno cuesta ~0,6 ms de CPU con 24 avispas).
- Arquitectura razonable para el tamaño: componentes compartidos (`HealthComponent`, hitbox/hurtbox), tokens de ataque
  (`BeeAttackTokens`) que evitan combinaciones injustas, contrato de cámara del que derivan spawn/fairness/auto-aim,
  checkpoint con snapshot. Nada de esto hay que rehacer.
- Riesgos reales (no bloqueantes): (a) **picos de compilación de shaders** la primera vez (hasta 117 ms) → precalentar
  al cargar; (b) solo se midió en una GPU dedicada moderna: falta probar en un equipo modesto/integrado; (c) cada nivel
  hoy es código específico (~2.400 líneas para Level 01).

### GAMEPLAY VIABILITY — **POSIBLE, NO DEMOSTRADA**
- El core (vuelo en plano, 3 armas, aguijón, bomba, amenazas telegrafiadas con roles, checkpoint, boss en 3 fases) está
  completo y puede volverse divertido **sin rehacerse desde cero**: los problemas detectados son de *ajuste de verbos y
  encuentros*, no de arquitectura.
- Lo que preocupa: el propio Rebuild 03 diagnosticó "ver → disparar → destruir"; se respondió con más patrones y más HP.
  Queda sin probar si el **auto-aim (~12 m) + cadencia alta** quita la habilidad de apuntar que un shmup necesita
  (hipótesis a testear, no conclusión).
- La escala —el gancho— casi no participa del combate: el humano es un cruce, la rana es decorativa, la lata es
  escenario. Hoy el combate sería el mismo con un fondo de espacio.

### ART VIABILITY — **SÍ, y mejoró hoy**
- Style C funciona en abeja y avispa. Con los packs CC0 aparecidos hoy (**KayKit Forest**, **Tiny Treats**) más Kenney
  food, hay material para un jardín doméstico coherente, suave y legible, compatible con toon + rim (ver §7 de la
  auditoría).
- Requiere disciplina: hoy conviven Kenney facetado, Quaternius con alfa, procedural, Style C mid-poly y un humano de
  otro proyecto. Hay que elegir **una familia** (recomendado: "suave estilizado" = Style C + KayKit + Tiny Treats + Kenney
  food) y retirar lo que no encaje.
- Piezas débiles identificadas: bota/jean del Giant Human, boss de primitivas, follaje de un plano. Todas se resuelven con
  1 pieza de Blender o 1 descarga cada una.

### SCOPE VIABILITY — **SÍ PARA UN DEMO; NO PARA LA CAMPAÑA DEL INFORME**
- La velocidad demostrada (Level 01 completo en ~5 días con IA) prueba capacidad de ejecución. El riesgo no es la
  velocidad sino la dirección.
- La campaña de 6 etapas (jardín → territorio → cielo → invasión → atmósfera → espacio) es inviable para un dev + IA sin
  recortes fuertes. Un **demo de 10–15 minutos** (Level 01 pulido + un Level 02 corto + boss) sí es viable.

### COMMERCIAL / DEMO VIABILITY — **SÍ, HAY GANCHO**
- "Una abeja con tecnología alien contra OVNIs en un jardín gigante" se entiende en una captura y es poco común dentro de
  los shmups laterales. Es material de trailer/GIF.
- El nicho shmup es estrecho; el atractivo tiene que venir de la escala y el humor, no de la profundidad shmup.
- Puede llegar a un demo atractivo y testeable si la escala se ve y se juega. No hay forma honesta de prometer más.

---

## 3. Red flags (objetivo 14)

| # | Red flag específica | Evidencia | Recomienda |
|---|---|---|---|
| R1 | **La diversión no está validada** | Rebuild 03 nace de "todavía no es suficientemente desafiante ni divertido"; el resultado posterior no está documentado | A si el próximo playtest pasa; **C** si no |
| R2 | **Métricas usadas como objetivo** | balas visibles promedio, % de ocupación de ataque, TTK por rol, "muertos antes del 2.º ataque", medidos con bots `ghost=1` | B (proceso) |
| R3 | **Costo de proceso por cambio** | 0,75 líneas de test por línea de runtime, 61 scripts dev, 43 docs, informe de 3.000 líneas en 5 días | B |
| R4 | **Churn de dirección** | Arcade Rebuild 02 → Threat/Camera/Boss 03 → Transformation en ~2 días; cámara D→E; HP re-tuneados dos veces | B |
| R5 | **El gancho de escala es decorativo, no mecánico** | rana sin colisión, humano como cruce de 10 s, lata/botella como fondo | **C** (pivotar esa parte: que la escala juegue) |
| R6 | **Cada nivel es código a medida** | ~2.400 líneas `bee_level_01_*`, escena de 62 nodos; la escenografía se genera por script | B (OK para 2 niveles; no para 6) |
| R7 | **Scope del informe maestro** | 6 etapas + mothership + progresión de OVNIs | B |
| R8 | **Identidad audiovisual incompleta** | sin música (bus `Music` vacío), boss de primitivas, humano reutilizado de Tucumán Rush, familias de assets mezcladas | B |
| R9 | **Riesgo de licencia por apuro** | 15 packs nuevos sin auditar hasta hoy; los ítems más tentadores (UFO.blend, male_casual) no tienen licencia | proceso: no integrar sin `License.txt` |
| R10 | Hipótesis: **auto-aim + cadencia alta reducen la habilidad** | el diagnóstico "ver → disparar → destruir" es del propio proyecto | test A/B en playtest (no concluir sin datos) |

No encontré ninguna red flag de nivel **D (abandonar/rehacer)**: el motor rinde, la arquitectura es reutilizable y no hay
deuda que obligue a empezar de cero.

---

## 4. Sunk cost check (objetivo 15)

**Si este proyecto empezara HOY desde su estado actual, ¿valdría la pena seguir construyendo ESTE core?**

# YES, BUT WITH CONDITIONS

Por qué técnicamente sí (sin contar el trabajo ya hecho como argumento):
- Lo que existe es exactamente lo que habría que construir primero para este concepto: movimiento en plano con cámara
  derivada, armas con auto-aim configurable, salud/daño por componentes, ataques telegrafiados con tokens anti-stack,
  checkpoint con snapshot, framework de eventos por distancia, boss por fases. Empezar de cero reproduciría lo mismo.
- El gancho es diferenciador y barato de comunicar.
- Los assets CC0 locales ya alcanzan para un demo coherente; faltan 2–5 piezas concretas, no un pipeline de arte.

Condiciones (si no se cumplen, el veredicto pasa a **PIVOT** de la capa de combate, no del proyecto):
1. Un playtest con 2–3 personas que **no** sean el autor pasa al menos 3 de los 5 criterios de §7.
2. Scope congelado a **demo**: Level 01 + un Level 02 corto + boss. La campaña del informe queda como visión.
3. Una sola familia visual (Style C + KayKit/Tiny Treats/Kenney food).
4. No más familias enemigas ni sistemas hasta pasar el playtest; los próximos cambios mejoran lo que existe.
5. Al menos **una interacción de escala que sea jugable** (no solo decorado) antes del Level 02.

---

## 5. Qué no funcionó en el proceso (objetivo 16)

Sin atacar el trabajo previo —que es sólido técnicamente—, la última etapa muestra estos patrones:

| Pregunta | Respuesta | Evidencia |
|---|---|---|
| ¿Cantidad en vez de calidad? | **Sí, en las primeras pasadas** | ante "vacío": enemigos 10→17→38, escenografía 46→206→350, eventos 9→14→24→44. La calidad de cada encuentro recién se atacó en el Rebuild 03 |
| ¿Sobreoptimizar métricas? | **Sí, parcialmente** | gaps en segundos, balas promedio, ocupación de ataque, TTK. Son buenos instrumentos; se volvieron la meta |
| ¿Testear sistemas poco divertidos? | **Sí** | 38 suites verifican secuencias, umbrales y HP; ninguna puede detectar aburrimiento. Ejemplo: `giant_human_hitbox_debug.gd` (351 líneas) para un momento de ~10 s |
| ¿Demasiados micro-passes? | **Sí** | Polish 01/02, Density 02, Challenge Balance, Arcade Director, Rebuild 02, Rebuild 03, Transformation, Style C… cada uno con doc + tests + capturas |
| ¿Assets débiles demasiado tiempo? | **Sí** | Hipster de otro proyecto desde el POC (con parches: ocultar suelas, hitboxes desde vértices); boss de primitivas; la araña y la rata CC0 estaban disponibles desde el 09-29 sin usarse |
| ¿Evitar cambios estructurales por miedo a romper? | **En parte** | la regla "cambios mínimos" llevó a capas (wrapper del humano, re-tuning de HP) en vez de preguntas de fondo (¿auto-aim?, ¿modelo del humano?). El Rebuild 03 sí se animó (cámara E, roles) |

Reorientación: menos pasadas y más grandes, cada una **cerrada con un playtest humano** y no con una métrica; un doc
por hito (no por pasada); tests solo para contratos que se rompen (daño, checkpoint, progresión, fairness), no para
valores de tuning.

---

## 6. Next 3 moves (objetivo 17)

### MOVE 1 — Playtest externo como puerta de decisión (sin código)
- **Qué**: build actual (Rebuild 03), 2–3 personas que no sean el autor, 1 partida completa cada una, pantalla grabada,
  sin explicaciones. Medir los 5 criterios de §7 y anotar dónde mueren y qué recuerdan. Opcional: segunda partida con
  auto-aim reducido para probar R10.
- **Impacto**: máximo (decide si se sigue con el combate tal cual o se pivota esa capa). **Esfuerzo**: 1 tarde.
  **Riesgo**: nulo.

### MOVE 2 — Pase "mundo en miniatura doméstico" con los packs CC0 nuevos (solo presentación)
- **Qué**: en Level 01, sustituir follaje plano Kenney por KayKit Forest; sumar 3 set pieces de escala (macetas de Tiny
  Treats como túnel/estructura, regadera, pala) y hojas gigantes de foreground; basura Kenney food como destructibles.
  Corregir el contorno en geometría de una cara. Sin tocar gameplay ni hitboxes.
- **Impacto**: alto (ataca el gancho y el "visualmente prototipo"). **Esfuerzo**: 1–2 prompts. **Riesgo**: bajo.

### MOVE 3 — Identidad sonora mínima
- **Qué**: 1 pista de música (descarga #5, la elige el usuario) + 5 cambios de SFX ya identificados localmente: muerte de
  enemigo (Epic "Explosion Small Blast Enemy Death"), entrada del OVNI ("Unidentified Encounter"), rayo del boss
  (Lentikula Laser Beam), aviso de embestida de avispa (Insectoid Tremble Attack), croar de la rana.
- **Impacto**: alto en percepción de calidad (playtests y video). **Esfuerzo**: 1 prompt + elegir una pista.
  **Riesgo**: bajo.

(Siguiente candidato si sobra capacidad: zapatilla + jean suaves del Giant Human, modelados en Blender sobre el rig del
Hipster o descarga #1.)

---

## 7. Definition of success (objetivo 18) — máximo 5 criterios humanos

1. **El gancho se entiende solo**: sin explicación, en los primeros 30 s la persona describe el juego como "una abeja
   contra aliens en un jardín gigante" (o equivalente).
2. **"Una más"**: después de perder (o de ganar), la persona vuelve a jugar sin que se lo pidan.
3. **Muertes justas**: cuando recibe daño puede decir por qué ("no vi la línea", "me quedé arriba") y no culpa al juego.
4. **Momentos recordados**: al terminar, nombra espontáneamente al menos 2 momentos (el humano, la rana, el OVNI…).
5. **Se comparte**: un clip de 20–30 s hace que alguien que no jugó pregunte qué es o quiera probarlo.
