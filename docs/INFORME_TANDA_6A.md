# T6a — Vida de enemigos según tamaño

Rama `lote-16-titulo-intro`. Auditoría previa completa en `VIDA_POR_TAMANO.md`: instancia real, tamaños, velocidades, multiplicadores, protecciones, movimiento y tiempos. Esta tanda ajusta el elenco común vigente del nivel 1. Familias reservadas/legadas se inventarían pero conservan sus vidas; no se activa nuevo contenido ni se balancean otros niveles. Robot minijefe, Tarántula, UFO y Rana quedan intactos.

## Decisión y fuente única

`scripts/game/bee_enemy_health_settings.gd` centraliza HP comunes, HP legados, medidas de referencia, umbrales y tiempos objetivo. `level_hp()` usa directamente COMMON_HP para el elenco vigente; se quitaron los multiplicadores acumulados de ruta/rol/hard. Escoltas y ruta comparten vida Normal. EASY sigue con el multiplicador 0,75 existente.

Los cinco nombres de `SMALL_ENEMY_HP` se conservan como alias de esta tabla: siguen generando exactamente los mismos acompañantes. No se ampliaron esas claves con especies nuevas. Cantidades, apariciones, cadencias de enemigos, colisiones, daños y DPS de Bee no se modifican.

Se mide largo del cuerpo/modelo con Bee v02 a escala de arte 1 (1,1667 m), sin incluir el aumento visual DEV ×1,40 en la referencia. Los gusanos son bajos pero largos: clasificar solo por altura los convertiría incorrectamente en muy chicos. En el elenco vigente no hay unidades independientes de las clases ≤40 % o 40–70 %; esos rangos quedan configurados para futuras entradas, no se agregan enemigos.

Clases: ≤0,40 → 0,25–0,40 s; ≤0,70 → 0,50–0,80 s; ≤1,20 → 1–1,50 s; >1,20 → 2–3 s. Lento: velocidad <1,3 m/s (mitad de Ant 2,6), tiempo ×0,70. WormA/B repta 0,12; Snail 0,7; hongo 0. **Escarabajo se incluye explícitamente como lento por el pedido**, aunque su marcha 1,4 supera por 0,1 el umbral; su velocidad y embestida 6,5 no se cambiaron.

## Antes y después, impactos perfectos

Base sigue en **36 DPS**, 3 por tiro / 12 tiros/s. Spread sigue en **60 DPS**, 3+1+1 por descarga / 12 descargas/s. Si solo pega el centro, Spread rinde como Base. Tabla al cuerpo (1×); el implante 2× se conserva. Tiempo desde primer impacto: (ceil(HP/3 o HP/5)−1)/12. El primer tiro sale de inmediato; viaje/entrada y fallos quedan fuera de esta tabla. Todos los tiempos nuevos están dentro de su rango de clase, incluido −30 % para lentos.

| Enemigo | Clase / ajuste | HP antes → después | Impactos Base nuevos | Base antes → después (s) | Spread antes → después (s) |
|---|---|---:|---:|---:|---:|
| `FlyCommon` | Bee | 10 → 42 | 14 | 0.250 → 1.083 | 0.083 → 0.667 |
| `FlyGreen` | Bee | 20 → 45 | 15 | 0.500 → 1.167 | 0.250 → 0.667 |
| `FlyCloud` | Grande | 10 → 75 | 25 | 0.250 → 2.000 | 0.083 → 1.167 |
| `Wasp` | Bee | 20 → 45 | 15 | 0.500 → 1.167 | 0.250 → 0.667 |
| `Ant` | Bee | 20 → 42 | 14 | 0.500 → 1.083 | 0.250 → 0.667 |
| `Ladybird` | Bee | 97 → 45 | 15 | 2.667 → 1.167 | 1.583 → 0.667 |
| `WormA` | Grande lento (−30 %) | 97 → 60 | 20 | 2.667 → 1.583 | 1.583 → 0.917 |
| `WormB` | Grande lento (−30 %) | 86 → 60 | 20 | 2.333 → 1.583 | 1.417 → 0.917 |
| `StagBeetle` | Grande lento (−30 %) | 144 → 60 | 20 | 3.917 → 1.583 | 2.333 → 0.917 |
| `Snail` | Grande lento (−30 %) | 144 → 60 | 20 | 3.917 → 1.583 | 2.333 → 0.917 |
| `Spider` | Grande | 106 → 90 | 30 | 2.917 → 2.417 | 1.750 → 1.417 |
| `MushroomCannon` | Grande lento (−30 %) | 70 → 60 | 20 | 1.917 → 1.583 | 1.083 → 0.917 |

**Mariquita:** 97 → 45 HP; 33 → 15 impactos Base de cuerpo, 2,667 → 1,167 s. No tenía armadura efectiva, umbral, regeneración, esquiva reactiva ni inmunidad de entrada que quitar. Su caja cubre el modelo, mayor que la bala. La pasada curva puede hacer fallar disparos, porque la ayuda apunta a posición actual sin adelantar el movimiento; se conserva. No se añadieron señales de defensas inexistentes. El `armored` histórico de Snail/StagBeetle no interviene en el cálculo de daño: tampoco se inventó armadura nueva.

**Moscas, avispa y hormiga aumentan su vida** para cumplir 1–1,5 s de su clase; mariquita, gusanos, escarabajo, caracol, araña y hongo bajan. No se cambió Bee para compensar. La nube se clasifica por el grupo completo (una sola unidad/caja/vida), no por cada mosquita decorativa de su GLB: **10 → 75 HP**.

**Nube de moscas:** una unidad necesita 25 impactos Base (2 s desde el primero; HP/36 = 2,083 s), o 15 descargas Spread completas (1,167 s). Banco de nueve unidades —tres iniciales más dos acompañantes por cada una—, input continuo real, proyectiles y áreas físicas: **19,65 s quietas, 16,75 s con entrada/persecución/pasada reales**, ambas <20. No hubo que bajar la vida dentro de su clase. Cámara/director detenidos para no retirar enemigos por tiempo ni sumar nuevas oleadas; Bee protegida y bot mantiene el apuntado sobre la caja actual. Mide limpiar esa tanda presente, no la duración de toda la arena ni errores de un jugador. El máximo global de arena sigue en 10; no se confunde con MAX_SWARM_ALIVE=6, que pertenece al dron legado Swarm.

Consecuencia explícita de la nueva vida: una bomba de 32 ya no elimina por sí sola una nube de 75 (antes sí). No se aumentó el daño de la bomba ni el del Aguijón para ocultar este cambio. Aguijón conserva 30. Las pruebas históricas de roster que exigían nube ≤32 y el ciclo antiguo de salto/láser del gusano describen un contrato anterior; no se reescribió ese banco completo ajeno a las validaciones dirigidas actuales.

**Menos de tres impactos:** ninguno del elenco ajustado. Mínimo 42 HP = 14 impactos de cuerpo; aun EASY/implante necesita más de tres. No se decidió bajar una vida por debajo de ese límite. El dron legado Swarm conserva 10 (cuatro tiros Base) y no se agrega al nivel.

## Reservados: antes = después

Las filas reservadas de VIDA_POR_TAMANO.md conservan exactamente vida y tiempos. Se trasladan sus HP de LEVEL_HP a LEGACY_HP sin cambiar números. El Walker regular/showcase queda en su contrato de 100/130, el minijefe en 600; los demás bosses mantienen sus archivos y constantes. Las mecánicas de tortuga rodando no se retocaron: la tortuga continúa aparcada.

## Pruebas dirigidas

Siete pruebas aprobaron, sin suite completa y sin timeout externo:

- `validate_bee_t6a_health`: las 12 clases/HP de fábrica Normal, mismos HP en escoltas, daño real a través de body hurtbox con Base y Spread, tiempos dentro de rangos, ausencia de protección invisible, perfiles/DPS intactos, Walker/minijefe intactos y limpieza física de las nueve nubes quietas y móviles.
- `validate_bee_tanda4c_weapons`: modos y DPS intactos; la expectativa de FlyCommon 10 HP/cuatro impactos se actualizó a la tabla T6a, manteniendo exactamente 3 por impacto.
- `validate_bee_lote15_hits_v01`: la cuenta antigua uno/dos impactos de 10 se actualizó a HP T6a y Base real de 3; comprueba la ruta proyectil → hitbox → cuerpo → salud.
- `validate_bee_t4d`: patrones/cadencias/entrada de gusanos conservados y vida tomada de la fábrica.
- `validate_bee_lote14_controls_v01`, `validate_bee_t4b`, `validate_bee_weapons_powerups_v01`: controles, embestida y armas conservados.

El banco nuevo falló inicialmente por desactivar el proceso completo de unidades (retiraba áreas de colisión) y después por consultar una nube ya liberada y borrada tras su salida; ambos fixtures se corrigieron y solo se repitió el test afectado. Los logs finales no tienen errores de script ni aserciones. Persisten mensajes de material nulo y recursos al cerrar el renderer headless, ya observados en tandas anteriores; no se presentan como validación de render limpia.

## Qué probar

En el nivel 1, Normal: mantener Base sobre mariquita y compararla con avispa/mosca; probar cuerpo e implante, luego Spread cerca/lejos. Gusanos y escarabajos grandes deben costar menos que antes, sin cambiar su ataque ni movimiento. Limpiar las nubes con fuego continuo, observando el cambio de la bomba y el efecto de tiros fallados. Repetir con mando y ratón. La curva de la mariquita todavía puede hacer fallar tiros: validar sensación, no confundir fallos de puntería con daño ignorado.

Pendiente manual: sensación y errores reales del jugador, especialmente nube (el banco móvil quedó con margen de 3,25 s). No se modificaron assets, jefes, minijefes, áreas de impacto ni daños de enemigos.
