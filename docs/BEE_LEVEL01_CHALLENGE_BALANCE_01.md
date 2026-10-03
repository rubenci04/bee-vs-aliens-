# BEE LEVEL 01 — CHALLENGE & BALANCE PASS 01

Rama `level01-challenge-01` (desde `ufo-boss-01`; el UFO Boss todavía no estaba integrado en master). Test: `tests/levels/validate_bee_level01_challenge_balance_v01.gd`. Herramientas y capturas: `dev/level01_challenge_review/`.

## Punto de partida (playtest del usuario, ~4:05)
Duración APROBADA, UFO Boss APROBADO, jardín/Style C APROBADO. Pedidos: reparar el Giant Human, más densidad moderada, Spread más satisfactorio, conservando legibilidad y fairness. **No se tocó**: longitud, velocidad de scroll, familias, HP globales, fases/patrones/approach/HP del jefe, Camera D, Style C.

## 1. Giant Human — corredor seguro
**Antes** (diagnóstico `GIANT_HUMAN_HITBOX_DIAGNOSTIC_01`): 5 envolventes (2 muslos, 2 pantorrillas+pie, torso), 18 de 21 aproximaciones reales recibían 20 HP, casi siempre de una pierna por delante del corredor, a veces con espacio visible libre.

**Ahora** — solo dañan los **zapatos** y el **torso** (20 HP, una vez por cruce):

| Envolvente | Antes | Ahora |
|---|---|---|
| `LeftThigh`, `RightThigh` | casco convexo del muslo, daño | **eliminadas** |
| `LeftLeg`, `RightLeg` | casco de pantorrilla+pie, daño | **eliminadas** → `LeftFoot`, `RightFoot`: solo el hueso `foot_*` (el zapato) |
| `Torso` | pelvis→cabeza, margen 0,12 | pelvis→cabeza, margen **0,30** |
| margen de los zapatos | 0,12 | **0,25** |
| columna central ±1,2 m | las piernas no entran | los **zapatos** no entran |

Cada envolvente sigue siendo el casco convexo de los vértices animados proyectados desde la cámara (`GiantHumanLevelVisual`), recortado hacia dentro. Con el hurtbox de Bee (0,20) el daño empieza algo antes de que el centro de Bee toque el límite visible, pero con margen a favor del jugador. Las piernas por encima del zapato y por debajo de la pelvis son decorativas: **atravesables**. Los nodos de escena `LeftLeg/RightLeg` de `giant_human_hazard.tscn` pasaron a `LeftFoot/RightFoot`. Tecla **H** y el log de diagnóstico se mantienen (colores actualizados). Velocidad, daño (20), no-disparable: sin cambios.

Geometría medida (proyección en Z=0, ciclo Run completo, `human_geometry_probe.gd`): zapato y=-0,3…2,1; pantorrilla 0,9…3,8; muslo 2,7…6,6; pelvis desde y=4,5. Banda segura de Bee: ~2,3 m ≤ y ≤ ~4,2 m (zapato arriba, torso abajo).

**Resultados del test** (aproximación real: Bee vuela a 7 m/s hacia el humano que corre a 2,6 m/s con la animación real; no hay teletransporte al centro):

| Caso | Resultado |
|---|---|
| Corredor medio (y=2,6/3,0/3,4/3,8/4,0 × 2 salidas) | **10/10 sin daño** (≥95 % exigido) |
| Corredor a ras: entrar a media altura, bajar a y=0,9 dentro de la columna central, mantener 0,8 s y subir | 0 de daño |
| Cruce a baja altura (y=0,9 y 1,5) por delante del zapato | 4/4 golpeadas por un zapato (20 HP, nunca más de una vez) |
| Dentro del hueco entre las piernas en zancada ancha | 0 de daño |
| Contacto intencional con `LeftFoot`, `RightFoot` | 20 HP exactos, sin repetición |
| Contacto intencional con `Torso` (pelvis/entrepierna visible) | 20 HP exactos, sin repetición |
| Volar demasiado alto (y≥4,4) hacia el cuerpo | daño (torso) |

Lectura honesta: el corredor "a ras" existe **por la columna central y por el hueco entre zapatos**, no a lo largo de toda la aproximación: para llegar abajo hay que entrar por la banda media y descender entre las piernas. Un vuelo bajo y recto contra el zapato delantero sigue siendo golpe (el zapato está ahí, y el daño solo ocurre donde se ve el zapato).

## 2. Densidad del nivel
**38 → 46 enemigos** (+8) en los **mismos 24 eventos** y las mismas distancias (360 m, mismos umbrales; no se añadieron eventos para no eliminar los respiros). Solo familias existentes, ≤3 por encuentro, y los de 3 unidades solo en el último tercio.

| Evento | X | Antes | Ahora |
|---|---|---|---|
| 3 | 54 | Wasp | Wasp + **Probe** |
| 5 | 82 | Probe | Probe + **Wasp** |
| 7 | 110 | Speeder | Speeder + **Probe** |
| 10 | 156 | Turret | Turret + **Wasp** (suelo + aire, tras el humano) |
| 14 | 212 | Turret | Turret + **EyeDrone** |
| 16 | 240 | EyeDrone | EyeDrone + **Speeder** |
| 19 | 282 | Turret | Turret + **Wasp** |
| 21 | 310 | Wasp + Speeder | Wasp + Speeder + **Probe** |

Respiros conservados a propósito (sin cambios): evento 0 (apertura), 8 (antes del humano), 12 (antes del checkpoint X=190) y los hard gates 17/20/23. Los pares son complementarios (cuerpo a cuerpo + a distancia, suelo + aire, ráfaga + embestida). Nunca hay 4.

### Simulación de ritmo (`sim_level.gd`)
Bot pasivo, sin esquivar, a 3 m detrás de la cámara, dispara cada 0,45 s (≈70 % de uso del gatillo), vida enorme; 60 fps fijos.

| Métrica | Antes | Después |
|---|---|---|
| Enemigos / eventos | 38 / 24 | **46 / 24** |
| Amenazas simultáneas máximas (enemigos) | 3 | 3 |
| Amenazas máximas incluyendo disparos enemigos | 7 | 7 |
| Tiempo sin ninguna amenaza (hasta el jefe) | 113,3 s de 199,3 (57 %) | **93,5 s de 198,8 (47 %)** |
| Tramo más largo sin amenaza | 8,0 s (16 m, tras el humano) | 8,0 s (16 m, el mismo respiro) |
| Llegada al jefe | 199,3 s | 198,8 s |
| Daño recibido por el bot pasivo | 132 | 200 |

Duración estimada: el recorrido sigue gobernado por el scroll (2 m/s × 360 m), así que **no cambia**: ≈ 199 s hasta el jefe en la simulación + aproximación (3,2 s) + pelea (~60 s) + final ≈ 4:30 para un bot perfecto; el playtest humano medido fue 4:05 y no debería moverse más que unos segundos (los hard gates no cambian).

Daño del bot pasivo por familia (impactos): antes Turret 63 (7), Speeder 26 (2), Wasp 20 (2), Walker 9 (1), Probe 8 (1), Eye 6 (1); ahora Turret 63 (7), Wasp 50 (5), Probe 40 (5), Speeder 26 (2), Eye 12 (2), Walker 9 (1).

## 3. Balance de enemigos
HP globales: **sin cambios** (`LEVEL_HP` igual, verificado por el test). Medición previa: Probe y EyeDrone eran las familias menos amenazantes (1 impacto cada una contra un bot que no esquiva). Microajuste solo de **cadencia**, solo en el nivel (`LEVEL_TUNING` aplicado en `_spawn`; las escenas reutilizables y los POC conservan sus valores):

| Parámetro | Antes | Después | Cambio |
|---|---|---|---|
| Probe `cooldown_time` | 1,25 s | 1,10 s | −12 % |
| EyeDrone `cooldown_time` | 1,40 s | 1,25 s | −11 % |

Telegraph (windup 0,45 / 0,4 s), velocidad del proyectil y daño intactos. Razón: subir la presión de las dos familias más débiles sin acortar su aviso. Walker, Turret, Wasp, Speeder y Organic: sin cambios. La regla de Fairness (`BeeShmupFairness.can_fire`) sigue activa; el test comprueba que Probe, EyeDrone y Turret no disparan fuera de pantalla y sí dentro.

## 4. Spread
| | Antes | Después |
|---|---|---|
| Ráfagas por cápsula | 24 | **32** |
| Proyectiles por ráfaga | 3 | 3 |
| Ángulo lateral | ±14° | ±14° (sin cambios) |
| Daño por perdigón | 6 (60 %) | **8 (80 %)** |
| Recoger otra cápsula | recarga al máximo | recarga al máximo (sin acumular) |
| Agotado | vuelve a Base | vuelve a Base |

HUD (`SPREAD x32`), cápsula, checkpoint (guarda las cargas restantes) y reinicio total (0 cargas) se verificaron en el test nuevo; los tests antiguos se actualizaron a 32/8.

El 0,6→0,8 **no estaba previsto**: el prompt lo permitía solo si la medición lo exigía tras corregir la cobertura. Contra el OVNI (`spread_vs_ufo.gd`, jugador que sigue la altura del jefe y pulsa a 3,3 Hz, DPS de Spread / DPS de Base = 33,3):

| Distancia | Hurtbox caja, ×0,6 (antes) | Hurtbox silueta, ×0,6 | Hurtbox silueta, **×0,8** (ahora) |
|---|---|---|---|
| 2 m | 1,64× | 1,62× | 2,10× |
| 3 m | 1,62× | 1,32× | 1,70× |
| 4 m | 1,11× | 0,84× | 1,06× |
| 5–8 m | 0,68× | 0,68× | 0,84× |

Con el daño anterior Spread era claramente peor que Base a ≥5 m (la distancia habitual de la pelea, porque los laterales de ±14° pasan por encima y por debajo del casco). No se redujo la cobertura lateral. A corta distancia rinde ~2×: es el riesgo/recompensa de acercarse al OVNI.

### Hurtbox del UFO
Caja 2,5 × 0,85 × 1,4 (esquinas vacías sobre el borde, corta en el centro) → **polígono convexo de platillo** (12 vértices extruidos ±0,6 en Z): borde ±1,28 en el anillo, hombros ±0,7 a y=±0,3, cúpula ±0,3 hasta y=+0,58, núcleo ±0,2 hasta y=−0,48. Está dentro de la silueta visible (anillo ±1,36, y −0,54…+0,74; el test lo verifica) y cubre ≥90 % del ancho del casco y ≥1,0 m de alto. Un perdigón horizontal a dy=+0,3, −0,3 y +0,62 registra; a +1,1 y −0,95 pasa limpio. HP 1300, fases, patrones, approach y contacto: sin cambios.

## 5. Rendimiento (`bench_density.gd`, render 1152×648, Intel Arc B580, distancia 290 → jefe con el bot pasivo)
| Enemigos vivos | Frame medio | FPS | CPU render | Nodos máx. | Disparos enemigos máx. |
|---|---|---|---|---|---|
| 0 | 10,1 ms | 99 | 1,8 ms | 1460 | 2 |
| 1 | 10,7 ms | 94 | 2,4 ms | 1512 | 5 |
| 2 | 10,2 ms | 98 | 2,2 ms | 1524 | 4 |
| 3 | 10,0 ms | 100 | 2,3 ms | 1513 | 5 |
| Total | **10,15 ms** | **99** | | | |

Sin caída sostenida (referencia anterior: arena 10,0 ms / 100 FPS, `BEE_UFO_BOSS_01.md`). La concurrencia máxima no cambió (cap 2 antes de 300 m, 3 después), por lo que el peor caso de render es el mismo. Se registraron picos de 44–58 ms (207 ms el primer Walker) solo en la **primera aparición** de cada familia en un proceso nuevo; no se comparó contra el estado anterior (limitación).

## 6. Test `validate_bee_level01_challenge_balance_v01` (headless y render)
Humano (velocidad/daño/no-disparable; sin muslos ni pantorrillas; 10 cruces de corredor; corredor a ras por la columna; hueco en zancada ancha; zapatos y torso 20 HP exactos una vez), densidad (24 eventos, 44–48 enemigos, +6…+10, ≤3 por encuentro, grupos de 3 solo desde X≥240, HP globales y escenas base intactos, tuning aplicado), sin disparos fuera de pantalla (Probe, EyeDrone, Turret), Spread (pickup/HUD x32, 3 perdigones de 8, recarga con tope, agotamiento → Base), checkpoint (17 cargas → 17) y reinicio total (0), jefe (hurtbox dentro de la silueta, perdigones laterales, DPS de Spread ≥1,2× a 3 m y ≥0,75× a 6 m) y **Level Complete solo tras matar al jefe**. Tests existentes actualizados solo por los números (Spread 32/8, 46 enemigos, nombres de envolventes del humano). La suite completa son 31 validaciones.

## 7. Limitaciones / necesita playtest humano
- El ritmo se midió con un bot que no esquiva y tiene puntería perfecta; la dificultad percibida (46 enemigos, cadencias −11/−12 %) solo la confirma una persona.
- El humano: confirmar que cruzar por el hueco se siente natural aunque Bee atraviese visualmente muslos y pantorrillas sin daño, y que el zapato delantero (vuelo bajo) no se siente injusto.
- Spread con 8 por perdigón es una decisión de balance basada en el UFO; conviene sentirla también contra grupos de enemigos.
- Los picos de primera aparición de familia (shader/resource load) no fueron comparados con el estado previo.
- El UFO Boss aún no estaba mergeado en master al comenzar: esta rama contiene también su commit `036f404`.
