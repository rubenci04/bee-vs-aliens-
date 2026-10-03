# BEE ARCADE PRESSURE + WORLD INTERACTION PASS 01

Rama `arcade-pressure-01` (desde master `6324fb4`: SHMUP Fairness → UFO Boss → Level 01 Challenge & Balance → este pass). Test: `tests/levels/validate_bee_arcade_pressure_world_interaction_v01.gd`. Herramientas y capturas: `dev/arcade_pressure_review/`.

## Punto de partida (playtest del usuario)
Duración BUENA (no se toca la longitud ni el scroll), Level 01 algo fácil, faltaba contacto con el entorno, demasiados enemigos "se acercan y mueren", pocas amenazas que permanezcan, poco fuego enemigo, piedras estáticas. Sin bullet hell. **No se tocó**: UFO Boss (HP 1300, fases, patrones, approach), Giant Human, Spread (32 × 3 × 8), HP globales, Camera D, Style C, ninguna familia nueva, sin música/UI/Level 02.

## 1. Mediciones BEFORE / AFTER (`sim_level.gd`)
Bot pasivo con puntería perfecta (auto-aim), a 3 m detrás de la cámara, sin esquivar, vida enorme, 60 fps fijos. Se corre con dos habilidades de disparo: 0,45 s entre tiros (~70 % de uso del gatillo) y 0,8 s (un jugador menos eficiente). BEFORE se midió en un worktree de master.

| Métrica | BEFORE 0,45 | AFTER 0,45 | BEFORE 0,8 | AFTER 0,8 |
|---|---|---|---|---|
| Enemigos / eventos | 46 / 24 | **53 / 24** | 46 / 24 | **53 / 24** |
| Amenazas simultáneas (enemigos) | 3 | 3 | 3 | 3 |
| Amenazas incluyendo disparos | 7 | 7 | 7 | 8 |
| Tiempo sin amenaza hasta el jefe | 110,0 s de 197,6 (**55,7 %**) | 94,3 s de 200,8 (**47,0 %**) | 58,8 s de 205,3 (28,6 %) | 71,1 s de 211,4 (33,6 %) |
| Con una amenaza a distancia en pantalla | 21 % | **27 %** | 35 % | **41 %** |
| Disparos hostiles visibles: promedio / pico | 0,16 / 4 | 0,28 / 4 | 0,28 / 4 | **0,46 / 6** |
| Llegada al jefe | 197,6 s | 200,8 s | 205,3 s | 211,4 s |
| Daño recibido por el bot que no esquiva | 162 | 260 | 323 | 500 |
| Encuentros con al menos un enemigo a distancia | 17 / 23 | 18 / 23 | | |

Lectura honesta:
- Con el bot "perfecto" el tiempo sin amenaza baja **8,7 puntos** (55,7 → 47,0 %), algo menos que los 10–20 pedidos. Con el bot menos eficiente sube (28,6 → 33,6 %): la Wasp ahora termina sus dos pasadas y se va, así que ya no queda "persiguiendo" hasta que el nivel la retira, y un blanco que se queda flotando es más fácil de acertar que uno que embiste. El indicador es sensible a cómo juegue el bot; **el cambio fiable es la presencia**: más tiempo con fuego a distancia en pantalla (+6 puntos en ambos casos) y +40–65 % de disparos visibles.
- Los tramos silenciosos que quedan son los respiros diseñados (0–12 m, el humano en X=140, y 7 s previos a los hard gates en 254 y 296 m).
- El pico de proyectiles es 4 con el bot perfecto y **6** con el menos eficiente; con tres enemigos a distancia vivos sin que el jugador dispare (peor caso del test) llega a 8. Dentro del 5–9 orientativo, sin patrones densos.
- Duración: el scroll no cambió, así que sigue en torno a 4:00–4:30 (la llegada al jefe se mueve +3…+6 s por las pasadas de la Wasp en los hard gates).

## 2. Wasp — identidad intacta, comportamiento arcade (solo Level 01)
`WaspEnemy.arcade_mode` (apagado por defecto: los POC y sus tests conservan la persecución original; Level 01 lo activa vía `LEVEL_TUNING`). Misma vida (36), mismo daño (10), sin disparos.

| Fase | Antes (persecución) | Ahora |
|---|---|---|
| Entrada | corre contra Bee | vuela hasta quedar a ~4,5 m frente a Bee |
| STALK | no existía | 1,8 / 2,4 / 3,0 s (según el puesto del grupo) a 4,6–5,4 m, sigue la altura de Bee a 2,6 m/s máx. con deriva ±0,45 m; el temporizador solo corre cuando ya está asentada |
| Aviso | 0,30 s | **0,55 s** (squash + telegraph); la dirección **se bloquea al empezar** el aviso |
| Pasada | golpe corto de 0,12 s | dash a 10,5 m/s, 5–8,5 m, **sin homing** (dirección constante, verificado), hitbox solo durante la pasada: 10 de daño una vez |
| Recuperación | 0,6 s casi quieta | 0,9 s alejándose por la línea de la pasada |
| Segunda pasada | no | sí (re-stalk 0,9 s); máx. 2 pasadas |
| Salida | se queda pegada hasta morir | cruza la pantalla hacia la izquierda y se va |

Medido: orden `STALK → WINDUP → DASH → RECOVERY → STALK → WINDUP → DASH → RECOVERY → EXIT`; primer stalk 2,6 s; aviso 0,57 s; pasar por la línea bloqueada cuesta 10 HP, salirse de ella 0; la Wasp está a <1,2 m de Bee el 10 % del tiempo (límite del test: 18 %).

## 3. Enemigos a distancia
Tabla BEFORE → AFTER (solo en Level 01, `LEVEL_TUNING`; las escenas base no cambian). Daño, velocidad de proyectil y telegraph **intactos**.

| Familia | Antes | Ahora | Tiros/s |
|---|---|---|---|
| Probe | 1 tiro, cooldown 1,10 s, mantiene 5–7 m | **ráfaga de 2** (0,30 s entre tiros, cada uno re-apunta), cooldown 1,60 s, mantiene 5–7,5 m, **avanza 0,5 m/s** entre ataques sin bajar de 5 m | 0,65 → 0,85 (+32 %) |
| EyeDrone | 1 tiro, cooldown 1,25 s | **ráfaga de 2** (0,25 s), cooldown 1,70 s | 0,61 → 0,85 (+39 %) |
| Turret | cooldown 1,60 s | 1,45 s | 0,44 → 0,48 (+7 %) |
| Walker | recovery 1,00 s | 0,90 s | ciclo −5 % |
| Speeder, Organic | — | sin cambios | — |

Flujo del Probe: ENTRA → se queda en el tercio derecho (medido x=+4,4 desde el centro) → ráfaga → avanza lentamente (7,5 → 6,7 m en dos ciclos) → se retira a los 8,5 s. Ciclo medido 2,43 s. La regla de fairness (`BeeShmupFairness.can_fire`) se aplica a **cada** tiro de la ráfaga: el test confirma que ninguno sale de fuera de pantalla.

## 4. Densidad y ritmo del recorrido
**46 → 53 enemigos (+7)**, mismos 24 eventos, mismas distancias, mismos respiros. Máx. 3 por encuentro. La concurrencia pasa de 2 a **3 amenazas desde X=150** (antes desde X=300); el tiempo de vida de los enemigos "soft" sube de 6 a 8,5 s para que sus pasadas y ráfagas ocurran antes de retirarse.

| Evento | X | Antes | Ahora |
|---|---|---|---|
| 4 | 68 | Eye + Eye | Eye + Eye + **Probe** |
| 6 | 96 | Eye + Wasp | Eye + Wasp + **Probe** |
| 11 | 170 | Eye + Turret | Eye + Turret + **Wasp** |
| 13 | 198 | Probe + Speeder | Probe + Speeder + **Eye** |
| 15 | 226 | Wasp + Wasp | Wasp + Wasp + **Probe** |
| 16 | 240 | Eye + Speeder | Eye + Speeder + **Wasp** |
| 18 | 268 | Probe + Eye | Probe + Eye + **Turret** |

Se conservan sin cambios los respiros de apertura (eventos 0–2), el evento 8 (antes del humano), el 12 (antes del checkpoint X=190) y el 19.

## 5. Piedras rompibles
Las 8 piedras de vuelo de Level 01 (`FlightRock*`) pasan de `StaticBody3D` a `BreakableRock` (hereda de `StaticBody3D`: mismas capas, collider y malla; sin sistema nuevo) y reutilizan `HealthComponent`, `Hurtbox3D`, `HitFlash3D`, el cue aprobado `crate` y el sistema de VFX.

| Piedra | HP | Base | Bomb |
|---|---|---|---|
| Pequeñas (X=72, 155, 241, 283, 345; radio 0,72) | 32 | 4 tiros (~0,9 s sostenido) | 1 |
| Medianas (X=96, 307; radio 1,15) | 64 | 7 tiros (~1,8 s) | 2 |
| **Estructural** (X=205, alta) | 100000 | no se rompe (recibe impactos con polvo y flash) | no se rompe |

Spread: 2 ráfagas rompen una pequeña a 2,5 m. Qué ocurre: impacto con polvo gris (`rock_hit`) y flash; al romperse, fragmentos con gravedad + polvo (`rock_break`), cue `crate`, collider/capa/hurtbox/malla apagados (Bee puede atravesar el hueco). Los disparos enemigos **no** dañan las piedras ni las usan de cobertura (equipo `alien`). Bomb las rompe (`bee_alien_bomb.gd` reconoce `BreakableRock`).
- **Checkpoint** (X=190): las rotas antes del checkpoint siguen rotas tras el respawn, sin repetir VFX ni audio; las rotas después se reconstruyen. **Shift+R** reconstruye todas.
- Las piedras de fondo (`BackdropRock*`) siguen siendo decoración. El tronco y el resto de sólidos no recibieron este feedback (ver postergado).

## 6. Rendimiento (`bench_density.gd`, render 1152×648, Intel Arc B580, distancia 290 → jefe)
| | Frame medio | FPS | Peor frame | CPU render | Nodos máx. |
|---|---|---|---|---|---|
| BEFORE (master) | 10,11 ms | 99 | 166,7 ms* | 1,2–1,7 ms | 1524 |
| AFTER | 10,11 ms | 99 | 171,3 ms* | 1,1–1,8 ms | 1560 |

\*Picos de primera aparición de cada familia en un proceso nuevo, presentes en ambos. Sin regresión sostenida.

## 7. Test `validate_bee_arcade_pressure_world_interaction_v01`
Wasp (orden de estados, stalk 1,5–3,8 s a 3–6,6 m, aviso ≥0,5 s visible, dirección constante en la pasada, dos pasadas exactas y salida, no se queda encima, 10 HP por pasada alcanzada y 0 al esquivar), ranged (burst gap, hold derecho, avance lento, ciclo 2,0–2,8 s, escenas base intactas, sin disparos fuera de pantalla con ráfagas, pico de proyectiles 3–9), piedras (HP/jerarquía, 4 y 7 tiros de Base, Spread ≤2 ráfagas, Bomb, estructural, collider y capa fuera, malla oculta, VFX, audio, disparos enemigos ignorados, checkpoint, reinicio), nivel (53 enemigos = +4…+8, ≤3 por encuentro, ≥75 % de encuentros con amenaza a distancia, HP globales, UFO 1300 HP / approach 3,2 s, Level Complete tras la muerte del jefe). Tests existentes actualizados solo por números (53 enemigos, tope de concurrencia, tabla de tuning del Challenge test).

## 8. Postergado deliberadamente
Vegetación destructible, tronco/otros sólidos con feedback de impacto, estado "agrietada" al 50 %, drops, música, UI, nueva familia, rediseño del humano, cambios al UFO.

## 9. Limitaciones / necesita playtest humano
- El ritmo se mide con un bot sin esquiva; el indicador de "tiempo sin amenaza" es sensible (ver 1). La sensación real de presión solo la confirma una persona.
- El avance lento del Probe y las ráfagas de Probe/Eye (+32/+39 % tiros) pueden sentirse más duras de lo esperado; son números de una línea en `LEVEL_TUNING`.
- Las piedras ya no son un muro permanente: un jugador puede abrir camino disparando. Revisar si alguna composición (X=96, 307) queda trivial.
- Los grupos de 3 aparecen desde X=68 (antes, X≥310); el tope de 3 simultáneos desde X=150.
