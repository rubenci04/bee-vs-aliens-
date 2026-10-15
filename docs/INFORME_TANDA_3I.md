# T3i — Polen hexagonal con imán suave

Rama `lote-16-titulo-intro`. Fecha: 15/10/2026. Cambios localizados al dibujo y la atracción del polen. Los proyectiles de Bee, las cantidades recolectadas, la curación y los datos de combo conservan sus valores.

## Auditoría

| Uso | Escena / script | Radio de recolección existente | Valor existente |
|---|---|---:|---:|
| Polen normal del nivel 1 | `scenes/items/toon/pollen.tscn` / `scripts/bee_prototype/pollen_pickup.gd` | 0,48 m | 1 |
| Racimo | `scenes/items/toon/pollen_cluster.tscn` / `scripts/items/pollen_cluster_pickup.gd`, hereda la recolección anterior | 0,70 m | 10 |
| Polen del prototipo | `scenes/bee_prototype/pollen_pickup.tscn` / mismo script base | 0,28 m | 1 |

`BeePollenPickup` es un `Area3D`: capa 8, máscara 1, esfera de trigger; `body_entered` llama a `collect()`. Comprueba que sea Bee, que siga viva y que no se haya recogido ya; emite `collected`, reproduce el sonido/efecto existente y libera el pickup una sola vez. Esta función y sus shapes **no se modificaron**.

El polen normal mostraba `pickup_pollen.glb`, mediante `scenes/art_labs/pickups_toon_v01/pickup_pollen.tscn`, más flotación de `toon_pickup_hover.gd`. Su caja visual era aproximadamente 0,85 × 0,77 × 0,57 m; el racimo, 1,445 × 1,313 × 0,969 m. `BeeItemBeacon` agregaba anillo, halo y columna, con acento lima/verde. El conjunto redondeado se confundía con balas.

Ya existía un imán general en `scripts/levels/bee_level_01_juice.gd::_update_magnet()`: radio 2,4 m y velocidad de 6,5 a 13 m/s según distancia, sin aceleración ni comprobación de enemigos o cámara. Ahora el polen usa su rama específica; bombas y Spread conservan ese comportamiento anterior.

La escena reutilizable de polen normal mantiene `heal_amount=20`. El nivel 1 sustituye ese valor por **0**, como antes, al crear su polen; los drops y racimos también conservan sus ajustes. La barra sigue requiriendo **20 polen para curar 10 %**, con tope de **70/minuto**, una cura guardada y polen de liberaciones según las constantes anteriores. No se tocaron combo, puntuación ni frecuencia/cantidad de drops.

## Dibujo y movimiento nuevos

- Hexágono de panal dorado, borde oscuro y celda central oscura, con giro lento en el plano de pantalla, flotación pequeña y resplandor hexagonal tenue. Mallas procedurales de seis caras; sin assets nuevos. El tamaño se obtiene de la caja visual anterior: aproximadamente **0,85 m** de diámetro exterior para el normal y **1,445 m** para el racimo. El prototipo conserva su escala de aproximadamente 0,32 m.
- El modelo original queda oculto como respaldo; no se elimina ningún asset. Se desactiva su flotación anterior. El beacon circular del polen queda oculto y no construye sus mallas, para evitar halos/columnas apilados; los demás pickups siguen igual.
- Atracción acelerada en el plano X/Y: comienza suavemente y tiene velocidad máxima. Durante la pirueta el alcance aumenta un 25 %, sin cambiar la espera ni duración de la pirueta.
- Una consulta física entre pickup y Bee impide atraerlo a través de las hurtboxes de enemigos vivos; omite las de Bee y las de enemigos ya derrotados. Si hay un enemigo en medio, el polen espera: no busca rutas ni atraviesa su cuerpo para llegar a Bee.
- No se atrae desde fuera de la vista. El polen que quedó detrás del borde izquierdo, con 1 m adicional de margen, se retira. El polen diseñado más adelante se conserva; no desaparece antes de entrar en pantalla. Así no se arrastra una reserva invisible detrás de la cámara.

Parámetros en **`scripts/game/bee_pollen_settings.gd`**:

| Constante | Valor |
|---|---:|
| `ATTRACTION_FACTOR` | 2,5 × radio de recolección |
| `ROLL_RADIUS_FACTOR` | 1,25 |
| `START_SPEED` / `MAX_SPEED` | 0,30 / 2,40 m/s |
| `ACCELERATION` | 3,20 m/s² |
| `ROTATION_SPEED` | 0,28 rad/s, aproximadamente una vuelta cada 22,4 s |
| `BOB_HEIGHT` / `BOB_RATE` | 0,04 m / 1,5 rad/s |
| `EMISSION` / `GLOW_ALPHA` | 0,55 / 0,12 |
| `SCREEN_RETIRE_MARGIN` / `SCREEN_MARGIN_PX` | 1 m / 12 px de tolerancia al borde |

El mismo archivo contiene dorado/borde, espesor y proporciones del hexágono, tamaño del brillo y distancia mínima de llegada. `legacy_review`, apagado por defecto, solo lo habilita la herramienta comparativa para reconstruir el aspecto/imán anteriores; no hay atajo ni opción de juego.

**Radios finales:** normal **1,20 m**, con pirueta **1,50 m**; racimo **1,75 m**, con pirueta **2,1875 m**; prototipo **0,70 / 0,875 m**. El radio de recolección no aumenta.

## Capturas y rendimiento

- `docs/polen_vs_disparos_dia.png` y `docs/polen_vs_disparos_noche.png`: cada imagen mide 2308 × 648; izquierda en color y derecha en gris. Nivel 1 real, mismo encuadre, polen normal/racimo y proyectiles reales de Bee detenidos para comparar sus siluetas a escala de juego. El hexadecimal conserva borde y centro oscuro frente al núcleo claro y forma alargada de la bala. Capturas revisadas visualmente.
- Herramienta reproducible: `tools/polen_disparos.gd`. Ejecutar Godot con `--path . --script res://tools/polen_disparos.gd`; también mide FPS. Para regenerar solo imágenes: agregar `-- --capture-only`.

Banco final: Godot 4.7.2 Compatibility, Intel Arc B580, 1154 × 648, VSync/tope de FPS desactivados; seis nubes reales de moscas, 24 pickups y fuego continuo de Bee. Las nubes mantienen ubicación y daño bloqueado **solo en el banco**, para que no desaparezcan durante la comparación. La IA de desplazamiento está congelada; animaciones, render, proyectiles y consultas del imán siguen funcionando. Los pickups no se consumen en el banco y se recolocan al llegar cerca de Bee para medir atracción sostenida, sin alterar valores del juego. No representa una partida completa con IA y distribución variable.

Dos pasadas en orden inverso, calentamiento de 3 s y muestra de 3 s por estado:

| Estado | Pasada 1 | Pasada 2 | Media |
|---|---:|---:|---:|
| Antes | 71,87 FPS | 71,76 FPS | 71,82 FPS |
| Ahora | 70,16 FPS | 69,65 FPS | 69,90 FPS |

Caída media medida: **1,91 FPS**. Una primera corrida sin bloquear el daño a las nubes tuvo mucha variación y no garantizaba un elenco constante; se descartó. Los números de la tabla son del banco corregido. Datos crudos y logs en `dev/t3i_fps.json` y `dev/t3i_capture.log`, sin commitear. Captura final y benchmark sin errores de script/shader.

## Verificación y pendientes

Pruebas dirigidas aprobadas: `validate_bee_t3i`, `validate_bee_lote11_juice_v01`, `validate_bee_lote14_pollen_v01`, `validate_bee_t3g` y `validate_bee_tanda4c_weapons`. No se corrió la suite completa.

La nueva prueba comprueba radio y valores originales, forma hexagonal, beacon circular oculto, velocidad creciente, refuerzo por pirueta, bloqueo real por una mosca, recolección única con el mismo incremento y combo intacto, retiro detrás de cámara y conservación de pickups futuros o apenas fuera de vista. Se actualizó la posición del fixture de imán del Lote 11 para entrar en el nuevo radio. También se adaptaron las expectativas visuales de `test_items()` en `validate_bee_items_shots_v04`: polen que gira en vez de halo redondo pulsante. Se ejecutó y aprobó **solo esa sección de pickups**, con el modo legado que requiere su fixture; no se afirma haber corrido esa validación histórica completa de armas/enemigos.

El primer test nuevo esperaba incorrectamente curación 0 en la escena reutilizable (sigue siendo 20); se corrigió esa expectativa y se agregó una comprobación independiente de curación 0 en el polen creado por el nivel. El primer fixture aislado de la prueba histórica no activaba su modo legado y esperaba las provisiones en el sitio antiguo; corregido y aprobado. Algunos tests headless conservan avisos de recursos al cerrar, ya presentes en tandas anteriores; no hubo errores de script en las ejecuciones finales.

Pendiente de sensación de juego: abrir `scenes/levels/bee_level_01_vertical_slice.tscn`, comparar polen/balas durante enjambres de día y de noche, pasar a unos 1,2 m y hacer pirueta a unos 1,5 m. Ver que el polen acelera sin saltar a Bee, espera si hay un enemigo en medio y no llega desde fuera de cámara. Confirmar que el giro lento y el centro oscuro permiten reconocerlo sin mirar el color. No se cambian valores para compensar dificultad: la comodidad del radio requiere validación del desarrollador.
