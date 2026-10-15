# T4f — Liberación animada e hit-stop local

Rama `lote-16-titulo-intro`. Fecha: 15/10/2026. Sin cambios en daño, vida, recompensas, armas o áreas de impacto durante combate. Se desactivan las colisiones de animales ya liberados durante su salida.

## Auditoría

La liberación no era solo un borrado: `AssetFauna._on_died()` ya calentaba colores, ocultaba implantes y hacía una salida de 3 s hacia la izquierda; la avispa, la araña y la libélula tenían variantes propias de varios segundos. La Tarántula caminaba hasta cerrar el nivel. Los efectos de implante, polen y letreros podían ocultar ese movimiento.

`BeeLiberation.free_animal()` lanzaba dos efectos tecnológicos y otro de polen. Además, `BeeLevel01Juice._on_unit_downed()` agregaba una nube de **26 partículas** y llamaba a `BeeJuice.hit_stop()` en cada liberación o muerte grande. Ese helper modificaba **`Engine.time_scale` a 0,02**, sin espera global de 0,5 s. También existían sacudidas por daño, bombas, aterrizajes y muertes.

El cañón del Robot tiene salud propia y `_break_cannon()` es su ruptura destructible. Las patas blindadas de la Tarántula **no se rompen**: `_on_armour_hit()` repone su salud interna y cuenta golpes absorbidos. No se inventó una ruptura de patas ni se alteró esa mecánica.

## Liberación nueva

- `scripts/vfx/bee_release_animation.gd` comparte la salida entre fauna del nivel 1, avispa, araña colgante, libélula y Tarántula. Reutiliza modelos/clips y callbacks finales existentes. Las máquinas conservan su explosión; el hongo conserva su tratamiento de planta liberada en el sitio.
- Implante oculto, chispa azul de **5 partículas durante 0,18 s**, materiales propios con tonos cálidos y emisión alien apagada. Se oculta el `HostileGlow` adicional. Los colores cian del cuerpo se sustituyen por cálido; se mantienen las formas y texturas originales.
- Giro corto, salida hacia **Z negativo** —fondo respecto de la cámara— con algo de desplazamiento arriba/izquierda. Fundido desde 0,18 s hasta **0,80 s**. Cuerpo, alas y pase de contorno se desvanecen juntos: se generan variantes de sus shaders/materiales, sin cambiar recursos compartidos. El include del toon se precarga como recurso para que no dependa de leer un archivo fuente suelto en una exportación.
- Máximo **12 salidas completas simultáneas**. Las restantes mantienen color cálido y fundido, sin giro ni desplazamiento, con chispa de solo **2 partículas**. Tope adicional de **16 emisores** de chispas; si se llena, se omite esa chispa y se conserva el fundido. Los emisores y slots se liberan al terminar.
- Desde la liberación se apagan hitboxes, monitorización y capas/máscaras de colisión; el animal deja de ser objetivo y no sigue atacando. No se modifica la colisión del insecto vivo.
- Se suprimen las explosiones de cuerpo y la nube dorada de 26 partículas por liberación. Son cambios visuales: no se quita polen como recompensa. Sonido de liberación existente, sin archivos nuevos.
- `+N LIBERADOS`, ventana de 0,6 s y máximo de dos letreros individuales al 60 % quedan como en T1b. El callback final se emite una vez, incluido el cierre de la Tarántula.

## Hit-stop y sacudida

`scripts/vfx/bee_local_hit_stop.gd`, invocado mediante `BeeJuice.key_event()`:

| Evento permitido | Punto de integración |
|---|---|
| Aguijón que realmente aplica un impacto durante la embestida | `BeePlayer._on_melee_impact()`; no se activa al iniciar o fallar una embestida |
| Pirueta que rompe un disparo | `BeePlayer.absorb_shot()` con `is_rolling`; incluye la red voladora ya tratada como disparo por el juego |
| Ruptura destructible del jefe | `WalkerMiniboss._break_cannon()` |

Pausa local de **0,05 s**, con espera compartida de **0,50 s desde cada activación**. Se guardan y restauran las funciones de proceso de Bee, del objetivo y de hasta **32 proyectiles** propios/enemigos a **3 m** del impacto. También se pausa/reanuda el tween visual de pirueta/giro/aguijón y, si existe, el controlador de salida del objetivo. No se activa de nuevo un proceso que ya estaba apagado ni se reactiva un animal derrotado.

No se cambia `Engine.time_scale`, el estado de pausa, audio ni temporizadores hijos del enemigo. Los nodos de advertencia y sus timers siguen funcionando: la pausa afecta movimiento/proceso del actor y proyectiles, no su árbol completo. El controlador respeta la pausa del juego; no consume su duración mientras la partida está pausada.

La sacudida usa la dirección del impacto, amplitud **0,035 m**, duración **0,12 s**, con caída suave y regreso a cero. Respeta la opción de temblor del menú. Solo la solicitan esos tres eventos, al aceptar el hit-stop; las llamadas antiguas de sacudida sin dirección quedan sin efecto. Por lo tanto ya no hay sacudida por balas comunes, daño recibido, bombas, aterrizajes ni liberaciones normales.

**O** alterna hit-stop y sacudida asociada, encendidos por defecto. Se muestra en la línea DEV. O estaba libre en Input Map y en los handlers del nivel 1; no usa F1–F12 ni intercepta combinaciones como Ctrl+O. El handler existente comprueba desarrollo y rechaza builds exportadas, incluso debug standalone; allí el efecto permanece en su valor predeterminado y no existe un interruptor accesible.

Valores centrales: **`scripts/game/bee_release_settings.gd`** (`SECONDS`, `FULL_LIMIT`, `TURN`, `DEPARTURE`, `FADE_START`, presupuesto/tamaño/color de chispas, duración/espera/radio/límite de proyectiles del hit-stop, amplitud/duración y tecla). `legacy_review` es solo para el banco visual, apagado durante el juego.

## Capturas y FPS

`docs/liberacion_animada.png` (3462×1296): mosca, mariquita y hormiga reales del nivel, controladas y luego liberadas a aproximadamente **0,04 / 0,20 / 0,45 / 0,70 / 0,85 s**. A los 0,85 s ya terminó la animación; aún pueden verse los letreros originales de T1b. Capturas revisadas visualmente; no representan una partida grabada. La herramienta precalienta las variantes de shader antes de capturar y limpia los avisos de ese precalentamiento.

Herramienta: `tools/liberacion_animada.gd`. Ejecutar Godot con `--path . --script res://tools/liberacion_animada.gd`. Agregar `-- --capture-only` para regenerar la secuencia sin benchmark.

Banco de enjambre: seis nubes reales liberadas simultáneamente una vez por segundo, mismos lugares y cámara; se recicla el grupo cada segundo para mantener carga repetible. Antes reconstruye salida sin fundido de 3 s y efectos anteriores; ahora usa salida corta/chispas reducidas. La IA está congelada; animación, efectos y render corren. No se reproduce el viejo time-scale global porque este banco compara coste visual. No mide una partida completa con input o nuevas oleadas aleatorias.

Godot 4.7.2 Compatibility, Intel Arc B580, 1154×648, VSync/tope desactivados. Dos pasadas en orden inverso; 3 s de calentamiento y 4 s de muestra por estado:

| Estado | Pasada 1 | Pasada 2 | Media |
|---|---:|---:|---:|
| Antes | 98,68 FPS | 96,67 FPS | 97,68 FPS |
| Ahora | 113,45 FPS | 107,94 FPS | 110,69 FPS |

**Sin caída superior a 5 FPS**: en este banco hubo aproximadamente **+13,02 FPS** de media. No es una promesa para todos los equipos o escenas; el ahorro incluye retirar explosiones, nube grande y salida visible más larga. Presupuesto final: cinco partículas por salida completa, dos por simple, hasta 16 emisores. Datos crudos/logs en `dev/t4f_fps.json` y `dev/t4f_capture.log`, sin commitear.

Una primera captura medía tiempo de reloj durante compilación y rotulaba mal los instantes; se corrigió usando el tiempo del controlador de animación y precalentamiento. También se cambió el reciclado inmediato de actores del banco por `queue_free`, eliminando avisos del renderer al liberar materiales durante el render. Capturas y benchmark finales sin errores de script/shader ni esos avisos de material.

## Pruebas y revisión pendiente

Pasaron solo pruebas dirigidas: **`validate_bee_t4f`**, `validate_bee_t4b`, `validate_bee_lote11_juice_v01`, `validate_bee_liberation_v01`, `validate_bee_t1b_hud` y `validate_bee_tanda4c_weapons`. Sin suite completa.

La nueva prueba cubre 14 liberaciones simultáneas, 12 slots completos y dos simples, colisiones apagadas, movimiento en Z/giro, fundido de materiales/contorno, finalización en 0,8 s más resolución de frame, retiro de emisores, límite de letreros, restauración exacta del proceso, proyectiles cercanos/lejanos, cooldown, escala global/pausa intactas, timers externos y del propio objetivo, interruptor y gate de exportación. Comprueba los callbacks reales de pirueta, impacto de Aguijón, cañón roto y final único de Tarántula.

Se ajustaron expectativas antiguas: la prueba del Lote 11 ahora pide pausa local y ausencia de nube grande/sacudida por daño; la prueba T4b apaga hit-stop para seguir contando ticks exactos de embestida/pirueta. Los fallos iniciales detectaron desactivación de objetos físicos desde callback, una integración colocada en aterrizaje en lugar de cañón y fixtures antiguos de efectos/timing; corregidos y repetidas solo las pruebas afectadas. El fixture añadido de Tarántula usaba inicialmente `activate`; se corrigió a su API real `begin(camera, bee)`. Los tests headless conservan avisos de recursos al cerrar ya documentados en tandas anteriores; no se afirma haberlos resuelto.

Pendiente humano: mirar la liberación de una mosca y de un enjambre, confirmar que se entiende que escapan vivos y que el azul breve no se confunde con disparos. Comparar con **O** un Aguijón acertado/fallado, pirueta entre disparos y ruptura del cañón del Robot; comprobar que balas normales, bombas y liberaciones no congelan ni sacuden. Pausar/reanudar cerca de un impacto. Revisar cierre de Tarántula y sensibilidad al temblor con mando y ratón. No se agregaron assets ni mecánicas de blindaje nuevas.
