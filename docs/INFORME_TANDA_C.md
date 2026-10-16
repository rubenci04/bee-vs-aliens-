# Tanda C — T6e: personalidad de los enemigos comunes

16/10/2026. Rama `lote-16-titulo-intro`, base `26d2266` (Tanda B). Se conservan sin tocar los cambios previos ajenos (`project.godot`, importaciones de paleta, archivos sin seguimiento). No se tocan moscas (Tanda B), caracol, jefes, daño de Bee ni HP (`BeeEnemyHealthSettings`).

## 1. Auditoría previa (estado antes de la tanda)

Mapeo de nombres de la tabla objetivo contra el roster real (`SPECIES_NAMES` del controlador):

| Pedido | Familia real | Clase / script | Observación |
|---|---|---|---|
| HORMIGA | `Ant` | `AssetFauna` kind `ant`, modo `lunge`, suelo | — |
| MARIQUITA | `Ladybird` | `AssetFauna` kind `ladybird`, modo `sweep`, **aérea** | la tabla pide saltos: pasa a terrestre |
| AVISPA | `Wasp` | `WaspEnemy` (modo arcade) | — |
| GUSANO | `WormA` (rosa) y `WormB` (compost) | `AssetFauna` + `BeeGroundWorm` (adaptador T4d) | el ciclo `WormBehavior` (erupción/láser/salto) ya NO se usa en el nivel; ver abajo |
| ESCARABAJO | `StagBeetle` | `AssetFauna` kind `stag_beetle`, modo `charge`, suelo | — |
| CARACOL | `Snail` | — | sin cambios, como se pidió |
| ARAÑA COLGANTE | `Spider` | `ControlledSpider` | — |

### Movimiento y ataque ANTES de la tanda (en el Nivel 1, `roster_only`)

| Enemigo | Movimiento | Ataque(s) | Cadencia / aviso | Observaciones |
|---|---|---|---|---|
| Hormiga | camina hacia Bee hasta 2,4 m (suelo) | (a) embestida corta `lunge` 3,2 m tras 0,5 s; (b) `BeeImplantShooter`: guijarro en arco (`pebble`) | aviso 0,5 s (pulso `COMMON_CUE`) / disparo cada 3 s × freno de ritmo (1,2–2,79) | dos ataques solapados, sin parada "de escupir" |
| Mariquita | vuela en el aire a 2–5 m, flota cerca de Bee | pasada `sweep` aérea 1,5 s con línea (suprimida) + 1 semilla lenta (`BeeImplantShooter`, cada 5,5 s × freno) | aviso 0,8 s; usa el token de ataque pesado | nunca salta; no toca el suelo |
| Avispa | acecha a 4,5 m, deriva senoidal | embestida con aviso 0,55 s; abanico de 3 agujas desde X≥STING_FROM_X; sobrecarga kamikaze al 35 % de vida (desde X≥OVERLOAD_FROM_X) | acecho 2,2–3,6 s × freno | una sola variante para todas |
| Gusano rosa / compost | semienterrado, repta a 0,12 m/s | `BeeGroundWorm`: abanico de 3 / ráfaga de 3 recta hacia arriba / ráfaga diagonal ±35° | aviso 0,5 s; máx. 2 atacantes (`bee_ground_worm_attacking`) | los proyectiles salen **rectos y no caen** (sin gravedad); `WormBehavior` (láser, salto, cúpula) existe en `asset_fauna.gd` pero el controlador lo desactiva |
| Escarabajo | camina 1,4 m/s | embestida recta 1,3 s a 6,5 m/s tras aviso 0,8 s + lanzamiento de piedras en abanico (`BeeImplantShooter`) | recuperación 1,4 s tras embestir | sin aturdimiento diferenciado; ataca de dos maneras |
| Caracol | repta 0,7 m/s | burbuja de baba en arco | — | **sin cambios** |
| Araña colgante | cuelga a 5,5 m, sigue a Bee por la línea de telaraña | columna (suprimida) + caída `strike` 14→5 dmg y retracción; además abanico de 3 telarañas cada 3 s (`BeeImplantShooter`) | aviso 0,85 s | 1 por oleada (3 apariciones sueltas + 3 en la zona de sombra) |

Reglas transversales verificadas antes de empezar:

- `COMMON_CUE` (T3j) ya suprime líneas/franjas/cúpulas de los comunes: la advertencia es una escala 1,0–1,12 con pulso de brillo de 0,5 s (`BeeCommonAttackCue.SECONDS = 0.5`, `MAX_SCALE = 1.12`).
- La paleta de proyectiles por especie ya está definida en `BeeShotStyles` y `BeeCommonAttackCue.color_for`: hormiga `pebble`, mariquita `seed`, escarabajo `stone`, gusano `mud`, avispa `stinger`, araña `web`.
- Tope de atacantes simultáneos: solo existía para el gusano (2) y el token de ataque pesado; no había un tope compartido.

## 2. Resultado por enemigo (un commit lógico cada uno)

Reglas aplicadas a todos: aviso = anticipación propia (escala 1,0–1,12 + pulso de brillo de 0,5 s con `BeeShotWarning`/`COMMON_CUE`), **sin líneas, franjas ni cúpulas visibles**; paleta de proyectil por especie ya definida; reserva compartida de **máximo 2 atacantes a la vez** (`scripts/game/bee_common_slots.gd`, `BeeCommonSlots`, tope `MAX_ATTACKERS = 2`; el gusano mantiene además su propio tope de 2 de T4d); ritmo sin cambios en el resto. Los HP no se tocan.

| Enemigo | Commit | Comportamiento nuevo |
|---|---|---|
| Hormiga | `f2e11db` | Modo `marcher` (suelo, nunca flota): marcha hacia Bee y cada **2,5 s** (periodo fijo disparo a disparo, medido 2,55 s por cuantización de fotogramas) se detiene, avisa 0,5 s y escupe un guijarro en arco al punto donde estaba Bee al empezar el aviso. Pierde la embestida corta y el arma de implante duplicada. |
| Mariquita | `0167a7c` | Pasa de volar a **saltar** (modo `hopper`, terrestre): salto en arco amplio (3 m de altura, ≥2,5 m de alcance, 0,9 s) que cae con un **anillo chico** (r 0,9 m) y golpe breve en el punto de impacto; tras **dos saltos** embiste **rodando** en línea recta (7 m/s, daño todo el trayecto) y queda cansada 1,3 s. Sin daño en el aire. Pierde la semilla del arma de implante. |
| Avispa | `c3a6254` | Dos variantes que alternan al aparecer (1.ª, 3.ª… tiradora; 2.ª, 4.ª… kamikaze): **tiradora** = ráfaga de 3 balas (aviso 0,5 s, se repite, nunca embiste); **kamikaze** = aviso 0,5 s y embestida recta con dirección bloqueada, sin agujas. Variante vacía = comportamiento original (POCs). |
| Gusano | `38fb7a0` | Emerge del suelo (ya lo hacía) y ahora lanza **1 o 2 bolas lentas** (vuelo 1,8 s, gravedad 6,5) que suben y **caen en arco** al punto bloqueado al inicio del aviso; alternan 1 y 2. Sin saltos, láser ni cúpula. Aplica a gusano rosa y de compost. |
| Escarabajo | `b758aeb` | Tanque lento (1,4 m/s): aviso 0,6 s (era 0,8) → embestida recta (6,5 m/s) que termina dentro del encuadre → **aturdido 1,0 s**, inmóvil, inofensivo y con bamboleo. Pierde las piedras del arma de implante. |
| Caracol | — | Sin cambios (como se pidió). |
| Araña colgante | `c5d26af` | Modo `web_mode`: baja por el hilo (1,2 m más abajo), **oscila como péndulo** (±1,3 m; el hilo queda anclado y se inclina) y cada **4,0 s** lanza una telaraña aimada tras un aviso de 0,5 s. Sin golpe de caída, columna ni anillo. **Cantidad: 3 → 5** en el roster (zona «Sombra bajo las hojas»: la apertura pasa de 1 a 2 y la 2.ª oleada de 1 a 2). |

### Decisiones y aclaraciones (leer)

- **Nombres**: «GUSANO» se aplicó a ambos gusanos; «ARAÑA COLGANTE» es `Spider`/`ControlledSpider`; «Mosca verde», «nube/grupo de moscas» y moscas comunes no se tocaron.
- **Proyectil «ácido» de la hormiga**: se usó el guijarro naranja (`pebble`) porque la paleta por especie ya definida le asigna esa forma/color (el ácido verde es de la mosca verde). Si se quiere otra forma, es solo el campo `style` de `KINDS.ant`.
- **Bolas «de plasma» del gusano**: conservan el estilo de barro (`mud`) de su paleta por la misma razón.
- **Avispa kamikaze**: la embestida es una pasada que atraviesa a Bee y se retira; **no se autodestruye**, porque la regla de Tanda B es que ningún enemigo desaparezca. La sobrecarga explosiva histórica (<35 % de vida) sigue activa solo en la variante kamikaze; la tiradora la tiene desactivada.
- **Mariquita terrestre**: la tabla pide saltar y caer, así que dejó de ser aérea (sale del suelo y llega por teletransporte al suelo). Es el único cambio de «clase» de movimiento.
- **Cadencias fijas**: la hormiga (2,5 s) y la araña (4 s) usan periodos exactos pedidos y no el freno de ritmo progresivo (`ROSTER_FIRE_SLOWDOWN`) de Lote 14; gusano y escarabajo conservan sus cadencias.
- **Cantidad de arañas**: el +50 % se redondea hacia arriba (3 × 1,5 = 4,5 → 5). Las apariciones sueltas de arañas (X 91/166/315) pertenecen a la tabla histórica `EVENTS_LEGACY`, que no se juega; solo cuenta `EVENTS_ROSTER`.
- **Gusano en el roster**: el ciclo `WormBehavior` (erupción/láser/salto) sigue sin usarse; el cambio está en el adaptador `bee_ground_worm.gd`. Su cadencia (≈ 8,7 s compost, ≈ 14,5 s rosa) no se tocó: es la calibrada en Lote 14.

## 3. TTK (límite de T6b)

HP sin cambios (`BeeEnemyHealthSettings.COMMON_HP`); a 36 DPS de Base: hormiga 33 HP → 0,917 s; mariquita/avispa 36 → 1,000 s (tope común 1,5 s); gusanos, escarabajo y caracol 51 → 1,417 s; araña 72 → 2,000 s (tope grande 2,0 s). **Ninguno supera el tope.** Las unidades que fabrica el nivel llevan exactamente esos HP (`validate_bee_tanda_c_ttk`). Aturdimiento, saltos o más arañas no alteran el TTK nominal; sí alargan el tiempo real de limpieza de la zona de las arañas (5 en vez de 3).

## 4. Pruebas

Nuevas (todas aprobadas): `validate_bee_tanda_c_ant`, `_ladybird`, `_wasp`, `_worm`, `_beetle`, `_spider`, `_ttk`. Comprueban comportamiento (cadencias medidas, pulsos de 0,5 s, orden de saltos/rodada, ráfagas de 3, 1/2 bolas, aturdimiento de 1 s, balanceo, tope de 2 atacantes, ausencia de geometría de aviso visible, HP, liberación que devuelve los cupos).

Pruebas existentes actualizadas por cambio de contrato (no se reparó ninguna ajena):
- `validate_bee_t4d`: los proyectiles del gusano pasan de «abanico/columna/diagonal rectos» a «bolas en arco, 1 y 2 alternadas».
- `validate_bee_lote10_pressure_v01`: usaba la mariquita solo como soporte del arma de implante; ahora usa el mosquito (la mariquita ya no lleva esa arma).

**Suite completa (una sola pasada): 105 aprobadas / 44 fallidas de 149** (142 previas + 7 nuevas). Los 44 fallidos son exactamente los mismos nombres que la base consolidada de Tanda B (98/142): **cero regresiones nuevas y ningún fallo histórico reparado**. Se ejecutó con cierre automático 2 s después de un `SCRIPT ERROR` (cuenta como fallo). Resultados: `dev/cfull_results.txt` y `dev/cfull_log_*.log` (locales, fuera del commit). La suite del repositorio sigue sin estar completamente verde por esos 44.

## 5. Cómo probar

Abrir el proyecto con Godot 4.7.2, escena `scenes/levels/bee_level_01_vertical_slice.tscn`, F6. Observar: hormigas (césped, X≈26+) se detienen cada ~2,5 s y escupen en arco; mariquitas (X≈52+) saltan dos veces con anillo chico y luego ruedan; avispas alternan ráfaga de 3 / embestida; gusanos (huerta, X≈227+) lanzan 1–2 bolas altas; escarabajos embisten y se aturden 1 s; arañas (zona de sombra, X≈262) se balancean y lanzan una red cada 4 s. Playtest humano pendiente para confirmar la sensación (los tests no miden diversión).

## 6. Archivos

Producción: `scripts/levels/asset_fauna.gd`, `scripts/levels/bee_ground_worm.gd`, `scripts/levels/controlled_spider.gd`, `scripts/bee_prototype/wasp_enemy.gd`, `scripts/levels/bee_level_01_controller.gd`, nuevo `scripts/game/bee_common_slots.gd`. Tests: siete nuevos y dos adaptados. No se tocaron modelos, assets, jefes, daño de Bee ni HP. Quedan sin tocar los cambios locales ajenos (`project.godot`, `.import` de paleta, archivos sin seguimiento).
