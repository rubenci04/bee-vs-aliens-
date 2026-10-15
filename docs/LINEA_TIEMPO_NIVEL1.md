# Línea de tiempo del nivel 1 — T5a

Solo lectura y documentación. Rama `lote-16-titulo-intro`; fuente auditada: `3cfc991`. Fecha: 15/10/2026. Se crean únicamente este documento y `docs/linea_tiempo_nivel1.png`. No se ejecutó Godot ni se alteraron tablas, escenas, código o constantes. El video de ocho minutos no está adjunto: su duración y revisión exactas quedan sin confirmar.

## Qué tabla se juega realmente

`EVENTS_ROSTER` tiene **79 eventos**, incluyendo **tres arenas de siete oleadas internas**, y termina en un gate obligatorio del Robot en **X=294**. `LEVEL01_ROSTER_ONLY=true` selecciona esa tabla (`scripts/levels/bee_level_01_controller.gd:366`, `:480`). La tabla `EVENTS_LEGACY`, con humano, UFO y otros enemigos, no es el recorrido normal. El humano está deshabilitado por defecto (`:99`). No hay que sumar sus cruces ni sus arenas antiguas al nivel actual.

Los actos numéricos no son zonas fiables por sí solos: por ejemplo X=124,2 tiene act=3 y X=128 vuelve a act=2. Aquí agrupo por tramo espacial y conjunto jugable; conservo X e ID para identificar cada fila sin ambigüedad. Los IDs E00–E78 son índices de base cero de la tabla actual; no son IDs guardados por el juego.

## Reloj: tiempos fijos frente a tiempo del jugador

- Crucero: **1,25 m/s**; arena: **0,30 m/s** (`bee_level_01_controller.gd:97`, `:114`). Sin pausas, llegar a X=294 consume **235,2 s**.
- Arenas: mínimo 28 s, objetivo de timeout 36 s; no son una pausa total, la cámara avanza 8,4–10,8 m. Cada una agrega **21,28–27,36 s** respecto de recorrer esos metros a velocidad normal. Se comprueba el campo limpio; con más de siete actores al timeout puede seguir esperando. No hay máximo absoluto de tiempo humano (`:695`, `:700`, `:722`).
- Cada debut espera limpieza y reserva **8 s a una especie**. La limpieza forzada se empieza tras 0,8 s; no es necesariamente el tiempo total de retirada (`:130`, `:597`, `:746`). Diez debuts explícitos; la mosca inicial no lleva `debut` y ya empieza sola. La cola autoral pendiente puede retrasar el siguiente evento aunque la cámara haya alcanzado su X (`:594`).
- Cupo de ruta **4 antes de X=96 y 7 después** en roster, cupo total de arena 10; dos acompañantes para las cinco familias pequeñas, con caducidad de espera de 4 s, separación 0,7 s y entradas mínimas 0,2 s (`:68`, `:791`, `:822`; `scripts/game/bee_game_settings.gd:110`). El escalón de 5 pertenece a la otra ruta de la función, no al roster después de X=96. Los acompañantes pueden no aparecer; una cola programada no equivale a actores vivos.
- El gate final detiene cámara y espera muertes obligatorias. **Si el jugador no derrota al Robot o al jefe, no hay máximo finito**; morir/reintentar agrega tiempo sin límite. Los intervalos de las tablas siguientes son un **presupuesto orientativo**, no extremos garantizados.

Para el reloj de referencia se usa limpieza sin retraso extra, arenas de 28–36 s, sin muertes ni pausas. Para un X dentro de una arena se integra primero a 0,30 m/s, después a crucero. A todos los tiempos se suma **Δ**: cola de entrada, limpieza adicional, retiradas y otras esperas no simuladas. Se ofrece también un escenario central de arena=32 s para el gráfico. Las duraciones de cada oleada no son exclusivas: se solapan.

## Resumen de zonas

| Zona | X | Inicio orientativo +Δ | Duración de desplazamiento/arena | Patrón dominante |
|---|---|---|---|---|
| Césped | 0–65 | 0:00.0–0:00.0 | 52.0–52.0 s | Mosca → hormiga → mariquita, luego mezclas |
| Macizo I | 65–138 | 0:52.0–0:52.0 | 58.4–58.4 s | Avispa → mosca verde, mezclas con hormiga |
| Nube / macizo II | 138–185 | 1:50.4–1:50.4 | 58.9–65.0 s | Arena nube+hormiga; debut gusano rosa y repeticiones |
| Huerta | 185–262 | 2:49.3–2:55.4 | 82.9–89.0 s | Caracol; arena escarabajo; gusano compost y mezclas |
| Sombra | 262–294 | 4:12.2–4:24.3 | 46.9–53.0 s | Arena araña; avispa+hormiga y último gate |
| Robot | 294 fijo | 4:59.0–5:17.3 | **30–45 s de presupuesto**, más limpieza variable; puede ser ilimitado | Robot + 3 escoltas; segunda escolta de 3 condicional |
| Tras Robot | avanza una anchura visible | al terminar el gate | **5,5 s** de respiro/avance, luego **3 s** de entrada del jefe | Curación/provisiones y checkpoint de jefe |
| Tarántula | arena bloqueada tras el respiro | aprox. 5:37.5–6:10.8 +Δ | **80–110 s de presupuesto**; no límite humano | Cuatro fases, redes/arañas y llamadas de hasta 4 moscas en F2 |
| Salida/resultados | hasta 10 m extra | tras liberación | hasta **0,8 s** de salida animada + **5 s** de avance final | Resultados independientes, sin cierre automático |

Los presupuestos de jefes vienen de los comentarios/pruebas históricas, **no de una ejecución de la revisión actual**: `scripts/levels/walker_miniboss.gd:21`, `tests/levels/validate_bee_tarantula_boss_v01.gd:24`. El respiro/entrada/final está en `bee_level_01_controller.gd:1192`, `:1232`, `:1267`; `scripts/game/bee_release_settings.gd:2`; `scripts/bee_prototype/bee_shmup_core_poc.gd:64`. El run-out actual usa `POST_BOSS_SCROLL=2`, **no** la constante 3,2 de una ruta antigua.

Con esas hipótesis: **7:03.3–8:06.6 +Δ**, desde control de Bee hasta resultados. Escenario central ≈**7:35.0**. Un video de alrededor de ocho minutos es plausible, pero no probado. Título, intro (al menos 27,5 s más fundidos/logo, salvo salto), pausa, muertes y reintentos no están en esa cifra.

## Inventario completo de eventos

En «entrada» se indica el intervalo entre primera y última solicitud de la formación (delays), **no cuánto tarda el jugador en matarla**. «Hasta siguiente» es la ventana nominal de avance hasta el siguiente evento, sin Δ; los enemigos pueden seguir vivos durante ella. Cada unidad blanda puede persistir hasta su `CAMERA_TIME` de **10–15 s** y después retirarse, o ser liberada antes (`bee_level_01_controller.gd:107`, `:1021`). Una arena dura lo descrito arriba; el gate no tiene máximo. El asterisco acompaña un debut de 8 s.

| ID | X | Inicio orientativo +Δ | Oleada/evento | Entrada / hasta siguiente |
|---|---:|---|---|---|
| E00 | 1.5 | 0:01.2–0:01.2 | Mosca×1 | 0 s / 2.0–2.0 s |
| E01 | 4 | 0:03.2–0:03.2 | opening_can | 0 s / 2.0–2.0 s |
| E02 | 6.5 | 0:05.2–0:05.2 | Mosca×1 | 0 s / 4.0–4.0 s |
| E03 | 11.5 | 0:09.2–0:09.2 | Mosca×2 | 0.9 s / 4.0–4.0 s |
| E04 | 16.5 | 0:13.2–0:13.2 | Mosca×2 | 0.6 s / 4.4–4.4 s |
| E05 | 22 | 0:17.6–0:17.6 | Mosca×1 | 0 s / 3.2–3.2 s |
| E06 | 26 | 0:20.8–0:20.8 | Hormiga×1; debut Ant* | 0 s / 2.6–2.6 s |
| E07 | 29.3 | 0:23.4–0:23.4 | Hormiga×1 | 0 s / 2.7–2.7 s |
| E08 | 32.7 | 0:26.2–0:26.2 | Hormiga×2 | 0.8 s / 6.6–6.6 s |
| E09 | 41 | 0:32.8–0:32.8 | Mosca×1, Hormiga×1 | 0.9 s / 2.9–2.9 s |
| E10 | 44.6 | 0:35.7–0:35.7 | Mosca×2, Hormiga×1 | 1.4 s / 2.9–2.9 s |
| E11 | 48.2 | 0:38.6–0:38.6 | Mosca×1, Hormiga×1 | 0.9 s / 3.0–3.0 s |
| E12 | 52 | 0:41.6–0:41.6 | Mariquita×1; debut Ladybird* | 0 s / 2.6–2.6 s |
| E13 | 55.3 | 0:44.2–0:44.2 | Mariquita×1 | 0 s / 2.7–2.7 s |
| E14 | 58.7 | 0:47.0–0:47.0 | Mariquita×1 | 0 s / 5.0–5.0 s |
| E15 | 65 | 0:52.0–0:52.0 | Hormiga×1, Mariquita×2 | 1.4 s / 2.9–2.9 s |
| E16 | 68.6 | 0:54.9–0:54.9 | Hormiga×1 | 0 s / 2.9–2.9 s |
| E17 | 72.2 | 0:57.8–0:57.8 | Hormiga×1, Mariquita×2 | 1.4 s / 3.0–3.0 s |
| E18 | 76 | 1:00.8–1:00.8 | Avispa×1; debut Wasp* | 0 s / 2.6–2.6 s |
| E19 | 79.3 | 1:03.4–1:03.4 | Avispa×1 | 0 s / 2.7–2.7 s |
| E20 | 82.7 | 1:06.2–1:06.2 | Avispa×2 | 0.7 s / 5.0–5.0 s |
| E21 | 89 | 1:11.2–1:11.2 | Avispa×1, Hormiga×1 | 0.7 s / 2.9–2.9 s |
| E22 | 92.6 | 1:14.1–1:14.1 | Hormiga×2, Avispa×1 | 1.4 s / 2.9–2.9 s |
| E23 | 96.2 | 1:17.0–1:17.0 | Avispa×1, Hormiga×1 | 0.6 s / 3.0–3.0 s |
| E24 | 100 | 1:20.0–1:20.0 | Mosca verde×1; debut FlyGreen* | 0 s / 2.6–2.6 s |
| E25 | 103.3 | 1:22.6–1:22.6 | Mosca verde×1 | 0 s / 2.7–2.7 s |
| E26 | 106.7 | 1:25.4–1:25.4 | Mosca verde×2 | 0.8 s / 5.0–5.0 s |
| E27 | 113 | 1:30.4–1:30.4 | Hormiga×1, Mosca verde×1 | 0.7 s / 2.2–2.2 s |
| E28 | 115.8 | 1:32.6–1:32.6 | Mosca verde×2, Hormiga×1 | 1.5 s / 2.2–2.2 s |
| E29 | 118.6 | 1:34.9–1:34.9 | Mosca verde×1, Hormiga×1 | 0.7 s / 2.2–2.2 s |
| E30 | 121.4 | 1:37.1–1:37.1 | Mosca verde×1, Hormiga×1 | 0.8 s / 2.2–2.2 s |
| E31 | 124.2 | 1:39.4–1:39.4 | Hormiga×1, Mosca verde×2 | 1.5 s / 3.0–3.0 s |
| E32 | 128 | 1:42.4–1:42.4 | watering_can | 0 s / 8.0–8.0 s |
| E33 | 138 | 1:50.4–1:50.4 | Nube×3; debut FlyCloud*; arena de 7 | 1.5 s / 30.1–36.2 s |
| E34 | 149 | 2:20.5–2:26.6 | Avispa×1 | 0 s / 1.8–1.8 s |
| E35 | 151.2 | 2:22.2–2:28.3 | Hormiga×1, Avispa×1, Nube×1 | 1.4 s / 1.8–1.8 s |
| E36 | 153.4 | 2:24.0–2:30.1 | Nube×1, Hormiga×1 | 0.9 s / 2.1–2.1 s |
| E37 | 156 | 2:26.1–2:32.2 | Gusano rosa×4; debut WormA* | 2.1 s / 2.6–2.6 s |
| E38 | 159.3 | 2:28.7–2:34.8 | Gusano rosa×3 | 1.5 s / 2.7–2.7 s |
| E39 | 162.7 | 2:31.4–2:37.5 | Gusano rosa×3 | 1.4 s / 5.0–5.0 s |
| E40 | 169 | 2:36.5–2:42.6 | Gusano rosa×1, Mosca×1 | 0.7 s / 1.8–1.8 s |
| E41 | 171.2 | 2:38.2–2:44.3 | Mariquita×1, Gusano rosa×1 | 0.7 s / 1.8–1.8 s |
| E42 | 173.4 | 2:40.0–2:46.1 | Mosca×1, Gusano rosa×1, Mariquita×1 | 1.4 s / 1.8–1.8 s |
| E43 | 175.6 | 2:41.8–2:47.8 | Mosca×2, Gusano rosa×1 | 1.6 s / 1.8–1.8 s |
| E44 | 177.8 | 2:43.5–2:49.6 | Gusano rosa×1 | 0 s / 1.8–1.8 s |
| E45 | 180 | 2:45.3–2:51.4 | Mariquita×1, Gusano rosa×2 | 1.3 s / 1.8–1.8 s |
| E46 | 182.2 | 2:47.0–2:53.1 | Gusano rosa×1, Mariquita×1 | 0.8 s / 2.2–2.2 s |
| E47 | 185 | 2:49.3–2:55.4 | Caracol×3; debut Snail* | 1.4 s / 2.6–2.6 s |
| E48 | 188.3 | 2:51.9–2:58.0 | Caracol×2 | 0.9 s / 2.7–2.7 s |
| E49 | 191.7 | 2:54.6–3:00.7 | Caracol×2 | 0.9 s / 5.0–5.0 s |
| E50 | 198 | 2:59.7–3:05.8 | Mosca verde×2, Caracol×1 | 1.4 s / 1.8–1.8 s |
| E51 | 200.2 | 3:01.4–3:07.5 | Mosca verde×1 | 0 s / 1.8–1.8 s |
| E52 | 202.4 | 3:03.2–3:09.3 | Mosca verde×2, Gusano rosa×1 | 1.3 s / 1.8–1.8 s |
| E53 | 204.6 | 3:05.0–3:11.0 | Mosca verde×2, Caracol×1 | 1.4 s / 1.8–1.8 s |
| E54 | 206.8 | 3:06.7–3:12.8 | Mosca verde×1 | 0 s / 1.8–1.8 s |
| E55 | 209 | 3:08.5–3:14.6 | Mosca verde×2, Caracol×1 | 1.4 s / 4.0–4.0 s |
| E56 | 214 | 3:12.5–3:18.6 | Escarabajo×2; debut StagBeetle*; arena de 7 | 0.7 s / 31.7–37.8 s |
| E57 | 227 | 3:44.2–3:56.3 | Gusano rosa×1, Avispa×1 | 0.9 s / 1.8–1.8 s |
| E58 | 229.2 | 3:45.9–3:58.1 | Avispa×2, Gusano rosa×1 | 1.3 s / 1.8–1.8 s |
| E59 | 231.4 | 3:47.7–3:59.8 | Avispa×1, Gusano rosa×1 | 0.7 s / 2.9–2.9 s |
| E60 | 235 | 3:50.6–4:02.7 | Compost×3; debut WormB* | 1.5 s / 2.6–2.6 s |
| E61 | 238.3 | 3:53.2–4:05.4 | Compost×2 | 0.7 s / 2.7–2.7 s |
| E62 | 241.7 | 3:55.9–4:08.1 | Compost×2 | 0.9 s / 5.0–5.0 s |
| E63 | 248 | 4:01.0–4:13.1 | Mosca×1, Compost×1, Mosca verde×1 | 1.4 s / 1.8–1.8 s |
| E64 | 250.2 | 4:02.7–4:14.9 | Mosca×1 | 0 s / 1.8–1.8 s |
| E65 | 252.4 | 4:04.5–4:16.6 | Mosca verde×1, Compost×1 | 0.8 s / 1.8–1.8 s |
| E66 | 254.6 | 4:06.2–4:18.4 | Mosca×2, Compost×1 | 1.5 s / 1.8–1.8 s |
| E67 | 256.8 | 4:08.0–4:20.2 | Mosca×1, Compost×2 | 1.6 s / 1.8–1.8 s |
| E68 | 259 | 4:09.8–4:21.9 | Mosca verde×1, Compost×1 | 0.7 s / 2.4–2.4 s |
| E69 | 262 | 4:12.2–4:24.3 | Araña×1; debut Spider*; arena de 7 | 0 s / 32.5–38.6 s |
| E70 | 276 | 4:44.6–5:02.9 | Avispa×1 | 0 s / 1.8–1.8 s |
| E71 | 278.2 | 4:46.4–5:04.6 | Avispa×1, Hormiga×1 | 0.9 s / 1.8–1.8 s |
| E72 | 280.4 | 4:48.2–5:06.4 | Escarabajo×2, Avispa×1 | 1.4 s / 2.1–2.1 s |
| E73 | 283 | 4:50.2–5:08.5 | preboss_power | 0 s / 1.2–1.2 s |
| E74 | 284.5 | 4:51.4–5:09.7 | Avispa×2, Hormiga×1 | 1.3 s / 1.8–1.8 s |
| E75 | 286.7 | 4:53.2–5:11.4 | Avispa×1 | 0 s / 1.8–1.8 s |
| E76 | 288.9 | 4:55.0–5:13.2 | Avispa×1, Hormiga×1 | 0.8 s / 1.8–1.8 s |
| E77 | 291.1 | 4:56.7–5:15.0 | Avispa×2, Hormiga×1 | 1.6 s / 2.3–2.3 s |
| E78 | 294 | 4:59.0–5:17.3 | Robot×1, Avispa×1, Mosca×2; gate/minijefe | 3.4 s / gate variable |

### Oleadas internas de las tres arenas

W1–W7 son índices humanos desde uno dentro de `arena`; el anfitrión E33/E56/E69 **se cuenta aparte**. Primera solicitud interna a +1,8 s, siguientes cada 3 s; la tercera espera además el fin del debut de 8 s si introduce otra especie. Sin atasco: **+1,8 / +4,8 / +8 / +11 / +14 / +17 / +20 s** aproximadamente. La cola y cupos pueden retrasarlas; al timeout pueden quedar filas sin lanzar. Fuente: `bee_level_01_controller.gd:694`, `:700`, `:734`.

| Arena | Oleada | Formación programada |
|---|---|---|
| X=138 | W1 | Nube×3 |
| X=138 | W2 | Nube×3 |
| X=138 | W3 | Hormiga×2, Nube×1 |
| X=138 | W4 | Hormiga×2, Nube×1 |
| X=138 | W5 | Nube×2, Hormiga×1 |
| X=138 | W6 | Nube×2, Hormiga×1 |
| X=138 | W7 | Nube×1, Hormiga×2 |
| X=214 | W1 | Escarabajo×3 |
| X=214 | W2 | Escarabajo×2 |
| X=214 | W3 | Avispa×2, Gusano rosa×1 |
| X=214 | W4 | Avispa×2, Gusano rosa×1 |
| X=214 | W5 | Gusano rosa×1, Avispa×2 |
| X=214 | W6 | Avispa×1, Gusano rosa×1, Escarabajo×1 |
| X=214 | W7 | Gusano rosa×2, Avispa×1 |
| X=262 | W1 | Araña×1 |
| X=262 | W2 | Araña×1 |
| X=262 | W3 | Avispa×1, Hormiga×2 |
| X=262 | W4 | Avispa×1, Hormiga×2 |
| X=262 | W5 | Hormiga×1, Avispa×1, Escarabajo×1 |
| X=262 | W6 | Avispa×2, Hormiga×1 |
| X=262 | W7 | Hormiga×1, Avispa×1, Escarabajo×1 |

## Tipos y cantidades por zona

Formato **base + acompañantes máximos**. Base incluye anfitriones y las siete filas internas, suponiendo que todas lleguen a lanzarse; no se duplica el anfitrión. No cuenta props decorativos ni cada mosca del mesh de una nube: `FlyCloud` es **una unidad de juego**. Los acompañantes son solicitudes opcionales susceptibles de caducar, y el timeout puede omitir oleadas internas. Por eso son conteos del guion, **no una promesa del contador final LIBERADOS**.

| Zona | Mosca | Hormiga | Mariquita | Avispa | Verde | Nube | Rosa | Caracol | Escarabajo | Compost | Araña | Robot | Total base / extra máx. |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Césped | 11+22 | 7+14 | 3 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 21 / +36 |
| Macizo I | 0 | 12+24 | 4 | 7+14 | 11+22 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 34 / +60 |
| Nube / macizo II | 4+8 | 10+20 | 4 | 2+4 | 0 | 18+36 | 18 | 0 | 0 | 0 | 0 | 0 | 56 / +68 |
| Huerta | 5+10 | 0 | 0 | 12+24 | 13+26 | 0 | 10 | 10 | 8 | 13 | 0 | 0 | 71 / +60 |
| Sombra | 0 | 11+22 | 0 | 15+30 | 0 | 0 | 0 | 0 | 4 | 0 | 3 | 0 | 33 / +52 |
| Robot | 2 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 4 / +0 |
| **Total hasta gate** | 22+40 | 40+80 | 11 | 37+72 | 24+48 | 18+36 | 28 | 10 | 12 | 13 | 3 | 1 | **219 / +276** |

La segunda escolta del Robot agrega **hasta 3** (avispa, verde, mosca), una vez al bajar de 60 % de HP o tras 14 s (`walker_miniboss.gd:65`, `bee_level_01_controller.gd:1176`). No lleva acompañantes mientras el hard gate está activo. La Tarántula agrega **1 jefe**; su fase 2 puede pedir **dos llamadas de dos FlyCommon** (hasta 4 adicionales) según cupo/muertes. Las arañas pequeñas del jefe se generan por patrón y no tienen un total fijo ni pasan por el contador autoral de oleadas (`tarantula_boss_01.gd:136`, `:492`, `:776`). No sumar esos máximos como si fueran enemigos garantizados.

### Dónde se repite

- Debuts con tres eventos de la misma especie: hormiga E06–08, mariquita E12–14, avispa E18–20, verde E24–26, rosa E37–39, caracol E47–49, compost E60–62. Cumplen enseñanza gradual, pero repiten estructura y se suman acompañantes de cinco familias.
- E09–11, E15–17 y E21–23 reutilizan parejas/tríos con hormiga. E27–31 repiten hormiga+verde; E40–46 repiten gusano rosa y pequeñas variaciones aéreas. E50–55, E63–68 y E70–77 vuelven a la misma lógica «trío / unidad suelta / trío».
- Las arenas repiten la arquitectura anfitrión + dos oleadas de la especie nueva + cinco mezclas. Hay duplicados exactos: nube W1=W2 y W5=W6; escarabajo W3=W4 y W5 tiene el mismo multiconjunto; sombra W1=W2, W3=W4 y W5=W7. Cambiar orden/altura no crea un ataque nuevo.
- El fondo usa un mismo jardín con props repetidos; por ejemplo latas/regaderas reiteradas en `bee_level_01_asset_dressing.gd:70`. La luz sí cambia con progreso (mañana→mediodía X=100–180; atardecer X=210–290, `bee_level_01_light_progression.gd:40`). Que esos fondos resulten monótonos es un juicio visual **sin confirmar** aquí; sus variaciones no cambian el patrón de oleadas.

## Cruces, checkpoints y pickups

No hay cruce hostil del humano en `EVENTS_ROSTER`. El humano/rana/UFO de `EVENTS_LEGACY` no se añaden a esta cronología. Las mariposas de X=30/132/214 y mosquitos ambientales de X=58/112/164/236/292 pertenecen al decorado (`bee_level_01_living_garden.gd:11`); no son oleadas ni frenan el scroll. Su tiempo visible depende de la cámara, no de un gate de combate. `human_aftermath` no se dispara por la tabla activa.

| Evento / objeto | X o disparador | Momento orientativo +Δ / duración |
|---|---|---|
| Lata de apertura E01 | 4 | 0:03.2–0:03.2; balanceo 0,9 s; sin gate |
| Regadera E32 | 128 | 1:42.4–1:42.4; 0,4 s de inicio + tres avisos separados 3 s; aviso 1 s y agua 0,5 s: ≈7,9 s total |
| Checkpoint 1 | 190 | 2:53.3–2:59.4; instantáneo; se conserva el progreso |
| Checkpoint 2 | 281 | 4:48.6–5:06.9; instantáneo, sujeto a no estar en arena |
| Aviso Spread+ E73 (pulsa el nodo X=334) | 283 | 4:50.2–5:08.5; pulso del pickup; no es pausa |
| Bomba de gate | 285.5 | 4:52.2–5:10.5; hasta recogerla o dejarla atrás |
| Racimo de gate | 287.3 | 4:53.7–5:11.9; igual |
| Checkpoint del jefe | después del Robot y respiro | Antes de instanciar Tarántula; entrada 3 s; mínimo 60 % HP al crear checkpoint |
| Provisiones post-Robot | inicio del respiro | Curación/bombas/polen y pickups relativos a cámara; recolección depende de Bee |
| Racimo de fase 3 | Tarántula al 50 % HP | Tiempo del jugador; no reloj fijo |

Fuentes: `bee_level_01_moments.gd:110`, `bee_level_01_watering_event.gd:8`, `bee_checkpoint_qol.gd:11`, `:20`, `:201`, `:290`; `bee_level_01_controller.gd:1211`; `tarantula_boss_01.gd:1196`. El checkpoint 2 puede demorarse si la cámara aún está en la arena de X=262: se activa al salir de ella, no en un segundo universal.

Pickups físicos de la ruta, con tiempo de cruce de cámara; pueden verse y recogerse antes o después de ese cruce por tamaño de pantalla/imán. Duración en pantalla/recolección no fija:

| Tipo | X | Tiempo de cruce orientativo +Δ |
|---|---:|---|
| Polen suelto PollenA, +1 | 12 | 0:09.6–0:09.6 |
| Polen suelto PollenC, +1 | 55 | 0:44.0–0:44.0 |
| Polen suelto PollenE, +1 | 111 | 1:28.8–1:28.8 |
| Polen suelto PollenG, +1 | 166 | 2:34.1–2:40.2 |
| Polen suelto PollenI, +1 | 223 | 3:41.0–3:48.6 |
| Polen suelto PollenK, +1 | 288 | 4:54.2–5:12.5 |
| Polen suelto PollenM, +1 | 338.4 | 5:34.6–5:52.8 |
| Polen suelto PollenO, +1 | 155 | 2:25.3–2:31.4 |
| Polen suelto PollenQ, +1 | 271 | 4:40.6–4:54.3 |
| Racimo +10 | 148 | 2:19.7–2:23.7 |
| Racimo +10 | 162 | 2:30.9–2:37.0 |
| Racimo +10 | 176 | 2:42.1–2:48.2 |
| Racimo +10 | 190 | 2:53.3–2:59.4 |
| Racimo +10 | 204 | 3:04.5–3:10.6 |
| Racimo +10 | 218 | 3:25.8–3:31.9 |
| Racimo +10 | 232 | 3:48.2–4:00.3 |
| Racimo +10 | 246 | 3:59.4–4:11.5 |
| Racimo +10 | 258 | 4:09.0–4:21.1 |
| Racimo +10 | 268 | 4:32.2–4:44.3 |
| Racimo +10 | 276 | 4:44.6–5:02.9 |
| Racimo +10 | 281 | 4:48.6–5:06.9 |
| Racimo de provisión | 192.5 | 2:55.3–3:01.4 |
| Bomba de provisión | 196 | 2:58.1–3:04.2 |
| Racimo de provisión | 200 | 3:01.3–3:07.4 |

Fuentes de inventario: `bee_level_01_vertical_slice.gd:25`, `:28`, `:30`, `:256` y nodos `Pollen` de la escena. Se conservan **9 de los 17** polen sueltos por `LOOSE_POLLEN_KEEP_EVERY=2`, en el orden de hijos, no por orden de X. Hay además 13 hongos y 15 flores rompibles, inofensivos, colocados por `bee_level_01_garden_mushrooms.gd:6`: sus drops de dos polen dependen de romperlos (`bee_garden_mushroom.gd:18`). MushroomCannon figura en el código y los nombres, pero tiene **cero** entradas en la tabla activa; no confundir estos props con ese enemigo. El polen dinámico por liberaciones/obstáculos y las bombas/Spread dinámicos no tienen inicio ni cantidad fija: dependen de bajas/recolección/cupos. Los racimos no curan directamente; no confundir sus nombres antiguos de “healing” con curación instantánea.


También están los **cinco powerups persistentes** de `scenes/levels/bee_level_01_vertical_slice.tscn:255`:

| Nombre de nodo | X | Momento de acceso orientativo |
|---|---:|---|
| SpreadFirst | 22 | 0:17.6–0:17.6 +Δ |
| BombFirst | 166 | 2:34.1–2:40.2 +Δ |
| SpreadRecharge | 222 | 3:39.1–3:45.2 +Δ |
| BombRecharge | 302 | durante avance post-Robot; también puede verse cerca del borde al final del gate |
| PrebossPower (Spread+) | 334 | **No coincide** con el aviso E73 en X=283; ver observación siguiente |

**Desajuste confirmado de coordenadas:** E73 solo llama al pulso de `Powerups/PrebossPower` (`bee_level_01_moments.gd:244`), no crea una cápsula en X=283. El nodo está en X=334. Tras el Robot, el director avanza aproximadamente una anchura de pantalla (≈14 m con F/16:9) y cierra tras otros 10 m; el centro de cámara puede terminar alrededor de X=318. Alcanzar esa cápsula en una partida roster normal está **sin confirmar**; con esos límites parece quedar fuera del recorrido y del alcance final de Bee. No se debe contar como recompensa garantizada previa al Robot. A y B deberían decidir si alinean evento y pickup antes de prometer conservar la accesibilidad. No se arregló en esta entrega.

## Cómo leer el gráfico de intensidad

`docs/linea_tiempo_nivel1.png` muestra el **escenario central estático**, no telemetría. Incluye dos curvas separadas: unidades activas estimadas y **inicios de ataque/s** estimados; una descarga múltiple cuenta como un ataque, no como cinco. No equivale a daño recibido por segundo. Una caída a cero de inicios tampoco garantiza pantalla vacía: pueden quedar proyectiles ya emitidos, ondas o agua activas. Los segundos son desde gameplay, excluyendo intro/pausa/reintentos.

Método reproducible sin ejecutar el juego: integrar avance y arenas de 32 s; expandir delays y acompañantes programados; admitir entradas cada 0,2 s bajo cupos 4/7 (ruta) o 10 (arena), y caducar acompañantes tras 4 s de espera. Modelo central de residencia activa **5 s**, banda de sensibilidad **3–7 s**; no son tiempos medidos. Se omiten viajes de entrada, retirada y espera/exclusividad de debut/limpieza adicionales, indicados como Δ: puede exagerar solapamientos que el scheduler real evita. Se fuerza el final de población blanda al gate para no fingir que sigue sumada al Robot. Las filas posteriores a arenas se colocan por X, no sumando 32 s enteros al viaje.

Para aproximar ataques se pondera por familia: Ant 0,40, Ladybird 0,23, StagBeetle 0,36, Spider 0,40, FlyCommon 0,30, FlyGreen 0,40, FlyCloud 0,30, Snail 0,25, Wasp 0,35 ataques/s al inicio; reposos de fauna se atenúan por `fire_slowdown(x)`. Son **coeficientes de comparación**, no un emulador exacto: cuerpo e implante pueden atacar por separado, los avisos/cupos/ángulo cambian el resultado. Gusanos usan el intervalo real de T4d: `4×0,6×2,79+2×0,6+0,35+0,45=8,696 s`, rosa /0,6=14,493 s; sus tasas base son 0,115 y 0,069 salvas/s. Fuentes: `bee_implant_shooter.gd:11`, `:18`; `asset_fauna.gd:108`; `wasp_enemy.gd:27`; `bee_ground_worm.gd:36`; `bee_level_01_controller.gd:793`. El techo de proyectiles vivos y `BeeShmupFairness.can_fire` pueden reducir fuego real, por lo que las curvas no son garantías.

Los jefes se dibujan con supuestos agregados, diferenciados por fondo: Robot 37,5 s, Tarántula 95 s, población 1–3 y tasas de ataque por fase de 0,7 / 0,85 / 0,95 / 1,25. **Esas tasas y ocupaciones no están medidas ni extraídas como una constante del juego**; son un proxy explícito para localizar el tramo. No usarlas para balancear daño. La referencia exacta por ataque está en `docs/INFORME_TANDA_7A.md`.

Conclusión prudente: hay **mesetas potenciales por saturación del cupo**, especialmente en las tres arenas, y muchos intervalos cortos con el mismo conjunto de familias. Si el jugador limpia rápido, los mínimos de arena pueden crear una espera final: W7 se solicita aproximadamente a +20 s y la salida mínima es +28 s; si W7 cae en 3 s, quedan ≈5 s sin oleada nueva. Si limpia lento, esa misma zona es saturación, no valle. El gráfico central ilustra ambos extremos con su banda; no demuestra dónde hubo silencio en el video. El mayor intervalo sin nueva solicitud de ruta es E32→E33, X=128→138 (8 s), **pero la regadera ocupa casi todo ese intervalo**, por lo que no es un valle vacío confirmado.

## Versión A — Conservar extensión y cantidad, variar el ritmo

**Mantener los 79 eventos, las 21 oleadas internas, X del Robot=294, velocidad y presupuestos de duración actuales.** No añadir otro minijefe obligatorio: hoy alargaría un recorrido que ya puede rondar ocho minutos.

1. Arenas E33/E56/E69: conservar W1–W7, pero espaciar solicitudes a **+1,8 / +4,8 / +8 / +13 / +18 / +23 / +27 s**, condicionadas a cupo y limpieza final. La intención es distribuir la presión dentro de los 28–36 s existentes, en lugar de lanzar todo hacia +20 y esperar el mínimo. Si W7 no cabe antes del timeout, no lanzarla tarde a la ruta: el prototipo debe verificarlo. Mantener 8 s de debut. Es una agenda propuesta, no una modificación realizada.
2. Repeticiones exactas: mantener cantidades y daños, diferenciar **solo entrada/altura/orden** de nube W2/W6, escarabajo W4/W5 y sombra W2/W4/W7; alternar entrada lateral si la especie lo permite. No prometer que un cambio cosmético resuelva una meseta de cupo. La diferencia debe verse en el recorrido de Bee, sin devolver avisos largos de enemigos comunes.
3. En el posible final vacío de arena, reutilizar un cruce **decorativo e inocuo** de mariposa o escarabajo del jardín, disparado al limpiar el campo y dentro del tiempo de espera restante. Sin daño, pausa, nueva familia ni assets; cancelar si ya empezó una amenaza. Primero confirmar el valle con telemetría: si el jugador sigue combatiendo, no poner el cruce. No colocar otro evento hostil encima de la regadera E32.
4. Fondo: redistribuir props **existentes** en los finales de esas tres arenas para dar un hito visual distinto, conservando suelo y plano de combate; evitar tapar jefes. No cambiar el ciclo de luz basado en progreso ni rehacer el arte.

**Costo:** 2–3 tandas: telemetría/diagnóstico y agenda; variación de entradas/hito visual; prueba humana de ritmo. **Riesgo:** oleadas retrasadas que se acumulan, campo demasiado lleno, cruce decorativo confundido con enemigo y pequeñas diferencias en cantidad realmente admitida aunque el guion conserve el total. Validar cupos y duración antes de aceptar. **No se toca:** vidas, daños, DPS de Bee, repertorio de ataques, duraciones/HP de jefes, checkpoints, recompensas previstas, extensión del jardín ni las primeras presentaciones de especies. Tiempo esperado parecido al actual; si la queja es duración, esta variante no pretende resolverla.

## Versión B — Condensada a un objetivo de 5–6 minutos

**Objetivo de una partida continua sin muertes/pausa, no límite máximo garantizado.** Mantener los dos jefes y sus cuatro fases/ataques; condensar ruta y repeticiones. No basta borrar oleadas: si quedan los mismos metros a 1,25 m/s, se crean vacíos y se ahorran principalmente esperas, no viaje.

### B1. Lista exacta de fusiones de eventos principales

Se conservan todos los eventos no nombrados. «Queda» indica la única formación resultante, con la familia y el número de **solicitudes autorales**, antes de acompañantes. Los IDs son los de este inventario anterior a editar. La formación usa los delays de la fila conservada, salvo un desplazamiento expresamente indicado.

| Filas actuales | Qué se fusiona/quita | Qué queda |
|---|---|---|
| E03+E04 | Quitar E04 | E03: 2 FlyCommon, X=11,5 |
| E07+E08 | Quitar E08; E07 toma la formación doble | E07: 2 Ant, X=29,3; se mantiene E06 como debut |
| E10+E11 | Quitar E11 | E10: FlyCommon, Ant, FlyCommon |
| E13+E14 | Quitar E14 | E13: 1 Ladybird; E12 sigue siendo debut |
| E15+E16+E17 | Quitar E16; conservar los dos tríos distintos en sus X | E15 y E17: Ant, Ladybird, Ladybird |
| E19+E20 | Quitar E20; E19 toma la formación doble | E19: 2 Wasp; E18 sigue siendo debut |
| E22+E23 | Quitar E23 | E22: Ant, Wasp, Ant |
| E25+E26 | Quitar E26; E25 toma la formación doble | E25: 2 FlyGreen; E24 sigue siendo debut |
| E28+E29+E30 | Quitar E29 y E30 | E28: FlyGreen, Ant, FlyGreen; E27 y E31 siguen |
| E35+E36 | Quitar E36 | E35: Ant, Wasp, FlyCloud |
| E38+E39 | Quitar E39 | E38: 3 WormA; E37 sigue como debut de 4 |
| E41+E42 | Quitar E41; adelantar E42 a X=171,2 | E42: FlyCommon, WormA, Ladybird |
| E43+E44 | Quitar E44 | E43: FlyCommon, WormA, FlyCommon |
| E45+E46 | Quitar E46 | E45: Ladybird, WormA, WormA |
| E48+E49 | Quitar E49 | E48: 2 Snail; E47 sigue como debut de 3 |
| E50+E51 | Quitar E51 | E50: FlyGreen, Snail, FlyGreen |
| E53+E54+E55 | Quitar E54 y E55 | E53: FlyGreen, FlyGreen, Snail; E52 se mantiene |
| E57+E58+E59 | Quitar E57 y E59; adelantar E58 a X=227 | E58: Wasp, Wasp, WormA |
| E61+E62 | Quitar E62 | E61: 2 WormB; E60 sigue como debut de 3 |
| E63+E64 | Quitar E64 | E63: FlyCommon, WormB, FlyGreen |
| E66+E67 | Quitar E67 | E66: FlyCommon, WormB, FlyCommon; E65/E68 siguen |
| E70+E71 | Quitar E70; adelantar E71 a X=276 | E71: Wasp, Ant |
| E74+E75+E76+E77 | Quitar E75 y E76 | E74 y E77 siguen como dos ataques distintos, sin otros duplicados intermedios |

Resultado: **52 eventos principales** en lugar de 79. Se mantienen E01 lata, E32 regadera, E73 Spread+ y E78 Robot. No se elimina una especie ni su primera aparición; no se convierte el inventario de familias en una lista más corta.

### B2. Arenas: cuatro oleadas internas en lugar de siete

Los anfitriones E33/E56/E69 quedan. En cada arena se conservan solo estas filas originales, en este orden; las otras se eliminan y **no** se trasladan a la ruta:

| Arena | Se conservan | Se quitan | Resultado interno |
|---|---|---|---|
| E33 nube | W1, W3, W5, W7 | W2, W4, W6 | 3 nubes; Ant/Nube/Ant; Nube/Ant/Nube; Nube/Ant/Ant |
| E56 escarabajo | W1, W3, W6, W7 | W2, W4, W5 | 3 escarabajos; Wasp/WormA/Wasp; Wasp/WormA/StagBeetle; WormA/WormA/Wasp |
| E69 sombra | W1, W3, W5, W6 | W2, W4, W7 | Spider; Wasp/Ant/Ant; Ant/Wasp/StagBeetle; Wasp/Ant/Wasp |

Agenda propuesta **+1,8 / +8 / +11 / +14 s** para conservar los 8 s de debut antes de mezclar familias. Mínimo de arena **18 s**, timeout objetivo **20 s**, siempre con resolución de campo/cupo. Se pasa de 21 a **12 oleadas internas**. Si queda más población de la que admite la ruta, se debe esperar/retirar de forma legible; ese exceso suma Δ y no se esconde para anunciar una duración falsa.

### B3. Condensar metros, hitos y provisiones coherentemente

Mantener el tramo inicial **X≤26** para conservar aproximadamente veinte segundos de moscas solas. En el resto proponer el remapeo continuo:

`Xnuevo = 26 + (Xviejo - 26) × (170 - 26) / (294 - 26)`.

El Robot pasa de X=294 a **170 m**. Aplicar la misma transformación a umbrales de eventos conservados, checkpoints, pickups y distribución de props/hitos de esa zona; después revisar separaciones visibles y que no quede otro pico en el mismo lugar. Para E42/E58/E71 se remapea su X adelantada de B1. Esto es una propuesta de composición de una versión nueva, no mover assets ni editar escenas en esta tanda.

- Checkpoint 1: 190→**114,12 m**; checkpoint 2: 281→**163,01 m**. Mantener sus recompensas/semántica; revisar snapshots, spawn seguro y no ponerlos dentro de una arena.
- Arenas: 138→**86,18**, 214→**127,01**, 262→**152,81 m**. Con 18–20 s a 0,3 m/s avanzan 5,4–6 m; sigue habiendo espacio hasta el siguiente hito.
- La regadera 128→**80,81 m** debe moverse junto con su prop, daño, aviso y las tres salvas. No dejar el agua separada de su regadera.
- Mantener el checkpoint del jefe relativo al final del Robot, el respiro 5,5 s, entrada de Tarántula y run-out. No sumar el tramo antiguo X=294…360 si el director ya cierra por arena y run-out.
- Remapear también los umbrales del ciclo de luz (X=100/180/210/290), no la duración del color en segundos; verificar que la Tarántula siga en atardecer. Conservar cantidades/valores de pickups, accesibilidad y arte. El total liberable baja por diseño y debe recalcularse; revisar objetivos absolutos de puntaje de los rangos de T2, sin alterar su cálculo a escondidas.
- Conservar 8 s de exclusividad de cada debut; si el remapeo hace llegar pronto a la siguiente mezcla, programarla después de esa ventana. El ahorro no se consigue recortando los avisos de ataque ni permitiendo aparición encima de Bee.

**Presupuesto de duración:** viaje al Robot 170/1,25=**136 s**; tres arenas agregan **41,04–45,60 s**; Robot 30–45, respiro/entrada 8,5, Tarántula 80–110, liberación 0,8, salida 5. Total orientativo **5:01,3–5:50,9 +Δ**; escenario central ≈**5:26,1**. Quedan unos nueve segundos hasta seis minutos en el extremo lento del presupuesto. Si colas/debuts/limpiezas superan ese margen, se debe ajustar composición/espaciado y medir de nuevo; no se garantiza 5–6 minutos para todos los jugadores. Pausa, derrotas y tiempo de menú/intro siguen fuera de ese objetivo.

**Costo:** 4–6 tandas: instrumentación y baseline; tabla/fusiones; remapeo de espacio/props/luz; checkpoints/pickups/resultados; validación visual y playtests. **Riesgo alto** frente a A: mezcla de debuts por distancias menores, props que se pisan, demasiada recompensa por minuto, snapshots con coordenadas antiguas y niveles de puntaje/rango desproporcionados. Tener una escena/tabla de comparación evita destruir la versión actual durante una implementación posterior.

**No se toca en B:** familias y modelos existentes, vida/daño de enemigos o Bee, DPS de sus armas, comportamiento y tiempos de ataque/aviso, repertorio de jefes ni la mecánica del polen. Se conservan valores por pickup y sus cantidades autorales, pero su densidad espacial aumenta y hay que probarla; el límite de polen por minuto no se cambia. No se añade minijefe ni evento hostil nuevo. Los ahorros se concentran en redundancia, mínimos de arena y metros, no en acelerar combate injustamente.

## Decisiones que faltan con el desarrollador

1. ¿Los 5–6 minutos incluyen intro, menú o reintentos? Aquí significan solo una partida continua; medir el video desde el primer frame controlable hasta resultados y anotar su commit/dificultad/arma.
2. Elegir A (misma extensión, variedad) o B (recorte real), y si conservar los diez debuts largos es prioritario frente a la duración. No implementarlas simultáneamente sin comparar.
3. Acordar el tiempo de los dos jefes. T7a propone dificultad mayor, no necesariamente más HP/duración; cualquier alargamiento cambia el presupuesto de B.
4. Confirmar qué momentos del video aburren: finales de arena sin actores, colas que mantienen el mismo cupo, repeticiones del mismo conjunto o fondos similares. Cada problema requiere un ajuste distinto.
5. Aprobar la lista exacta B1/B2 y el tratamiento de acompañantes, recompensas y umbrales de rangos después de bajar la población total. No asumir que el número 454 de otro video sea un total fijo del guion.
6. Si se implementa una variante, registrar cada evento solicitado y realmente lanzado, descartes/caducidad, tiempo/X, actor activo, ataque iniciado, fin de arena/gate y pickups recogidos. Comparar tres perfiles de juego (rápido, normal y conservador), mando/ratón, al menos cinco intentos sin muerte por perfil. Reportar mediana y dispersión; bots sirven para cobertura, no para afirmar que un fondo se siente repetido.

## Validación de esta entrega

Extracción estática comprobada: 79 eventos, 3 arenas, 21 filas internas; **219 unidades base** hasta el gate y **hasta 276 solicitudes de acompañantes**. La segunda escolta y el jefe/refuerzos son condicionales y se muestran aparte. Se revisó visualmente el PNG y se contrastaron coordenadas/constantes con sus fuentes. No se ejecutaron tests del juego ni se presenta el modelo como simulación fiel del scheduler completo. Solo estos dos documentos deben formar parte del commit.
