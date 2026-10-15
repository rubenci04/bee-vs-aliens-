# T4e — Destello de golpe e inclinación de Bee

Rama `lote-16-titulo-intro`. Cambios de presentación localizados. No se modifican daños, vidas, hitboxes/hurtboxes, perfiles de armas, dirección de puntería ni la geometría/shader del modelo de contorno. Fecha: 15/10/2026.

## Auditoría antes de editar

`HitFlash3D` (`scripts/components/hit_flash_3d.gd`) conecta `HealthComponent.health_changed`; ante cambio negativo llama `flash()`. Cada llamada hacía `cancel()` (mata el tween y restaura overlays), ponía de nuevo un `StandardMaterial3D` sin sombreado y transparente en todas las mallas, y creaba otro tween de duración completa. No había espera entre activaciones.

`BeeJuice.attach_hit_flash()` reutiliza el componente y fija **0,06 s y Color(1,1,1,0,9)** para enemigos, incluido el Robot. El valor por defecto del componente era 0,10 s / blanco cálido alfa 0,72. La Tarántula fijaba su acento propio naranja alfa 0,34; sus golpes/liberación también pasan por el mismo componente. Bee conserva la excepción de T4b: 0,12 s / alfa 0,28 al recibir daño.

**Hipótesis confirmada de forma condicional:** una cadena de impactos con separación menor que 0,06 s puede reiniciar el efecto indefinidamente; el código no tenía máximo total. Diez segundos son posibles si esa cadena dura diez segundos, pero no se afirma haber reproducido ese tramo concreto del vídeo. Un único Base de T4c a 12 Hz perfectamente regular tiene 0,08333 s entre impactos y, nominalmente, deja 0,02333 s sin flash: por sí solo no demuestra blanco ininterrumpido. Spread, varias trayectorias/tiempos de llegada y múltiples impactos pueden cerrar las pausas.

Prueba real de tres segundos con Spread continuo sobre el Robot: antes hubo **45 activaciones**, con racha máxima muestreada de **29 frames ≈0,483 s**; no se reprodujeron 10 s seguidos en este banco. Tras el cambio: **9 activaciones**, máximo **4 frames ≈0,067 s**. El máximo lógico ahora es 0,06 s, más la resolución de un tick de física; no depende de cuántas balas lleguen. Ambos Robots terminaron en **517/600 HP**, mismo daño aplicado.

**Contorno:** el código anterior no borraba el `next_pass` del material base. Sí reemplazaba cualquier `material_overlay` anterior por un overlay blanco sin pase propio de contorno, y el color podía lavar o tapar su lectura. No era una eliminación del mesh del contorno. Ahora se conserva el material base con su pase original y se vuelve a dibujar exactamente ese contorno después del tinte: mismo shader, ancho y color, prioridad de render posterior. Así la capa blanca no es la última sobre la silueta. Si el comparador apaga el contorno, el flash no inventa otro.

## Destello nuevo

`scripts/game/bee_feedback_settings.gd` centraliza:

| Constante | Valor |
|---|---:|
| `FLASH_SECONDS` | 0,06 s |
| `FLASH_LOCKOUT` | 0,20 s después de terminar |
| `FLASH_COLOR` | blanco cálido (1 / 0,96 / 0,86), alfa 0,55 |
| `OVERLAY_PRIORITY` / `OUTLINE_PRIORITY` | 1 / 2 |
| `PITCH_DEGREES` / `BANK_DEGREES` | 15° / 20° |
| `TILT_SMOOTH_SECONDS` | 0,12 s |
| `TILT_DEFAULT` / `TILT_KEY` | encendido / U |

Durante el flash o su espera se ignoran nuevas solicitudes **visuales**, nunca impactos ni daño. El tween actual no se cancela por golpes adicionales. Al terminar se restauran los overlays anteriores y empieza la espera de 0,20 s; el ciclo mínimo es aproximadamente 0,26 s. Los materiales con pase final de contorno se guardan por estilo para reutilizarlos, sin reconstruir recursos por cada malla/golpe.

`BeeJuice.HIT_FLASH_COLOR` y el acento de golpe de la Tarántula apuntan a la misma constante al 55 %. La excepción de daño recibido por Bee sigue en 0,12 s / 0,28: no se deshace T4b. Se preservan partículas/efectos de muerte existentes; no se agrega un flash fuerte extra ni se cambia la muerte de enemigos chicos. Los efectos del láser etiquetados como solo visuales no se blanquean con el casco.

## Inclinación visual y disparos

Solo se rota `VisualRoot/BeeVisual`, sin reparentar ni modificar modelos, colliders o hurtboxes. Cabeceo local según velocidad vertical, máximo ±15°; alabeo leve según avance/retroceso relativo a la orientación, máximo ±20°. Interpolación exponencial con constante de tiempo de 0,12 s y retorno a neutro al detenerse. Durante pirueta/Aguijón se lleva hacia neutro para no superponer esa pose con las maniobras existentes.

El ancla gráfica gira con el cuerpo, pero **`firing_origin()` elimina la inclinación al calcular el punto físico de salida**, y conserva la compensación de escala DEV existente. La raíz de movimiento, orientación principal, dirección de puntería y velocidad de bala no cambian. El muzzle flash gráfico conserva su seguimiento del arma visual. Prueba con proyectiles reales: v01/v02, ambas orientaciones, subir/bajar/avanzar/retroceder y coordenadas X=310; diferencia del punto físico menor a 0,0001 m (precisión numérica). Las referencias de los shapes no se reemplazan. El contorno gira junto con el mismo modelo, sin editar su geometría/shader/ancho.

**U sin modificadores** alterna la inclinación solo en desarrollo; se muestra `U inclinación sí/no` en la línea DEV. Input Map y scripts no usan U sola en gameplay. Los atajos de edición que usan modificadores, como Ctrl+U, no se interceptan. Se usa la puerta editor/debug/no-standalone existente; builds exportadas no muestran el texto ni responden a U, pero arrancan con inclinación encendida. No se usa F1–F12. K y los comparadores anteriores se conservan.

## Capturas y rendimiento

- `docs/destello_antes_despues.png` (3462×1296): tres muestras de flash activo dentro de tres segundos de fuego Spread real, antes/ahora. Ventanas alrededor de 0,7–1,0 / 1,7–2,0 / 2,7–3,0 s, tiempos exactos rotulados. El aspecto viejo se reproduce solo desde la herramienta de revisión: mismo overlay blanco al 90 %, material compartido/prioridad original y reinicio en cada golpe; no hay tecla para reactivarlo en gameplay.
- `docs/inclinacion_bee.png` (2308×1296): Bee subiendo, bajando, retrocediendo y quieta. Poses del wrapper real a velocidad fijada, sin mover colliders.
- Herramienta: `tools/destello_inclinacion_bee.gd`, ejecutar Godot con `--path . --fixed-fps 60 --script res://tools/destello_inclinacion_bee.gd`. Capturas revisadas visualmente.

GPU Intel Arc B580, Godot 4.7.2 Compatibility, 1154×648, VSync/tope desactivados. Física simulada a 60 Hz, Robot real en descanso para evitar cambios de ataque durante la comparación, input continuo Spread y balas/impactos reales. HP 600 como el minijefe del nivel, no inmortal ni con daño bloqueado; Bee protegida solo en el banco. Dos pasadas con orden inverso, calentamiento 0,8 s y muestra de 2,5 s por estado. Antes: flash anterior + inclinación apagada; después: flash limitado + inclinación encendida. Bee está quieta para mantener iguales los impactos; las cuatro poses móviles se verifican aparte. No representa el coste total de una partida con todas las escoltas.

| Estado | Pasada 1 FPS | Pasada 2 FPS | Media FPS |
|---|---:|---:|---:|
| Antes | 75.71 | 76.08 | 75.89 |
| Después | 76.89 | 79.24 | 78.06 |

Diferencia media: +2.17 FPS. No hubo caída media en esta corrida; el pequeño aumento no se presenta como mejora garantizada por la variabilidad entre muestras. Datos crudos en `dev/t4e_fps.json`, sin commitear.

## Pruebas y pendientes

Siete pruebas dirigidas aprobadas, sin suite completa y sin timeout externo: `validate_bee_t4e`, `validate_bee_lote11_juice_v01`, `validate_bee_hero_integration_v01`, `validate_bee_t4b`, `validate_bee_t3k`, `validate_bee_tanda4c_weapons` y `validate_bee_live_readability`.

La nueva comprueba límite temporal con solicitudes en cada frame, espera posterior, overlay cálido/contorno conservado, flash de Tarántula, rotaciones máximas, retorno neutro, origen/dirección de proyectiles reales v01/v02 en ambas orientaciones y coordenadas tardías del nivel, shapes sin reemplazo, tecla libre y bloqueo del handler fuera de desarrollo. La prueba de efectos del Lote 11 actualiza solo su expectativa de blanco puro a blanco cálido 55 %. La expectativa de alfa antiguo de la Tarántula también se actualizó; su prueba larga de balance no se corrió (mantiene fallos previos de duración documentados en T3h), y la configuración nueva se verifica en T4e.

El primer test nuevo falló por comparar v01 contra un ancla de muzzle que ese modelo no tiene (su disparo usa el offset antiguo), comparación exacta de alfa float y contar Ctrl+U como conflicto de U sola. Se corrigieron los fixtures: comparar el proyectil real con/sin inclinación, tolerancia float y teclas sin modificadores. Solo se repitió la prueba afectada. Capturas/benchmark finales sin errores de script/shader. Los tests headless conservan algunos avisos de recursos al cerrar; no se afirma que esos avisos previos estén resueltos.

Pendiente del desarrollador: mirar el Robot con Base/Spread durante varios segundos, de día/anochecer, confirmar que sigue leyendo colores y contorno entre golpes. Pulsar U mientras sube/baja/avanza/retrocede, detenerse y alternar disparando con mando/ratón. Revisar pirueta y Aguijón para confirmar que la pose no molesta. No se afirma haber reproducido los 10 s del video; sí se eliminó la posibilidad de reinicio visual ilimitado y se verificó el límite nuevo.
