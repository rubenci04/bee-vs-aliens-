# T6b — Vida de enemigos comunes: antes y después

Auditoría inicial del 15/10/2026, rama `lote-16-titulo-intro`, anterior a modificar gameplay. Fuente: `scripts/game/bee_enemy_health_settings.gd::COMMON_HP`, fábrica `BeeLevel01Controller.level_hp/_spawn` y `scripts/game/bee_shooting_settings.gd::WEAPON_MODES`.

Alcance: las **12 familias comunes vigentes del Nivel 1** ajustadas en T6a, incluidas sus escoltas. `LEGACY_HP` conserva los valores de familias reservadas/legadas; no se activan ni se balancean otros niveles. Robot minijefe, Tarántula, UFO y Rana quedan excluidos. No se modifica el Aguijón (30 de daño).

Base hace **3 HP por impacto al cuerpo**, a 12 tiros/s: **36 DPS**, sin Frenesí ni implante. Impactos = `ceil(HP / 3)`. En esta tabla **TTK = HP / 36**, la estimación continua pedida; no se resta el primer disparo inmediato. El tiempo discreto desde el primer impacto es `(impactos - 1) / 12`, menor en un intervalo cuando HP es múltiplo de 3. Entrada, viaje, inmunidades temporales y tiros fallados no forman parte del TTK nominal.

Clase grande: longitud de cuerpo/modelo dividida por Bee >1,20, con las mismas medidas canónicas de T6a; el comparador visual DEV no cambia la clase. Máximo: 1,50 s para comunes no grandes y 2,00 s para grandes. Las antiguas duraciones mínimas por clase y el ajuste de tiempo de lentos de T6a dejan de ser objetivos de aceptación en T6b; velocidades y tamaños permanecen intactos.

## Tabla auditada y reducción aplicada

| Enemigo | Clase T6a | HP antes | Daño Base | Impactos antes | TTK antes (s) | HP después | Impactos después | TTK después (s) |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| Mosca común (`FlyCommon`) | Bee | 42 | 3 | 14 | 1,167 | 33 | 11 | 0,917 |
| Mosca verde (`FlyGreen`) | Bee | 45 | 3 | 15 | 1,250 | 36 | 12 | 1,000 |
| Nube de moscas (`FlyCloud`) | Grande | 75 | 3 | 25 | 2,083 | 66 | 22 | 1,833 |
| Avispa (`Wasp`) | Bee | 45 | 3 | 15 | 1,250 | 36 | 12 | 1,000 |
| Hormiga (`Ant`) | Bee | 42 | 3 | 14 | 1,167 | 33 | 11 | 0,917 |
| Mariquita (`Ladybird`) | Bee | 45 | 3 | 15 | 1,250 | 36 | 12 | 1,000 |
| Gusano rosa (`WormA`) | Grande | 60 | 3 | 20 | 1,667 | 51 | 17 | 1,417 |
| Gusano de compost (`WormB`) | Grande | 60 | 3 | 20 | 1,667 | 51 | 17 | 1,417 |
| Escarabajo ciervo (`StagBeetle`) | Grande | 60 | 3 | 20 | 1,667 | 51 | 17 | 1,417 |
| Caracol (`Snail`) | Grande | 60 | 3 | 20 | 1,667 | 51 | 17 | 1,417 |
| Araña colgante (`Spider`) | Grande | 90 | 3 | 30 | 2,500 | 72 | 24 | 2,000 |
| Hongo cañón (`MushroomCannon`) | Grande | 60 | 3 | 20 | 1,667 | 51 | 17 | 1,417 |

La rama `impactos <= 5` no corresponde a ninguna de estas doce familias en el estado T6a. Se conservará la regla solicitada al calcular la propuesta: `max(1, ceil(impactos * 0.55))`; para seis o más, `max(2, impactos - 3)`.

En once familias se restan exactamente tres impactos (9 HP). En la araña, la regla da 27 impactos / 81 HP / 2,25 s: se aplica además el tope de 24 impactos / 72 HP para respetar el máximo explícito de 2 s. Es la única reducción adicional al aplicar el requisito de TTK. No se aumenta el daño de Base ni del Aguijón para resolver ese exceso.

Todos los HP nuevos siguen en `COMMON_HP`; no se recalculan acumulativamente al entrar al nivel. `BeeGameSettings.SMALL_ENEMY_HP` conserva sus cinco alias a esa tabla y la fábrica conserva dificultad/escoltas. No hay una segunda fuente de HP en gameplay: los valores anteriores del test son una fixture de auditoría histórica, y los documentos son registro del cambio.
