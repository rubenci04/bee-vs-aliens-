# Tanda 3e — Comparadores de legibilidad en vivo

Rama: `lote-16-titulo-intro`. Alcance: presentación de desarrollo del Nivel 01. Se usó el mapa de `AUDITORIA_CONTEXTO.md`, H-29/H-31 de la adenda y H-12/H-13 del informe fusionado. La adenda no contiene un desarrollo separado de H-13.

## Cambios y constantes

- `scripts/game/bee_readability_settings.gd`: interruptor general `ENABLED`, valores iniciales y todos los niveles configurables. Solo se activa con un binario debug/editor; en exportaciones debug requiere `--debug-readability`; release siempre lo omite.
- `scripts/levels/bee_live_readability.gd`: F5 escala el modelo de Bee (1 / 1,25 / 1,4); F6 usa contorno oscuro en espacio de pantalla (0 / 1,2 / 2,8 píxeles), excluyendo alas transparentes, halos de implante y avisos; F7 modifica copias de materiales de escenografía lejana (saturación 1 / 0,65 / 0,35; contraste 1 / 0,90 / 0,80); F8 modifica copias de materiales de disparos (emisión 1 / 2,4 / 3,6; tamaño visual 1 / 1 / 1,3). Panel pequeño abajo, separado del HUD.
- `assets/style/toon_common.gdshaderinc`: parámetros de saturación/contraste con valores neutros por defecto. Solo las copias lejanas reciben ajustes. No se editaron imágenes ni modelos.
- `scripts/levels/bee_level_01_vertical_slice.gd`: incorpora el controlador de desarrollo.
- `scripts/bee_prototype/bee_visual.gd`: compensa el escalado visual al calcular la boca de disparo para conservar su posición física y dirección de apuntado.

Valores iniciales: Bee ×1,25, contorno fino, fondo 1, neón 1. F3 conserva el HUD debug; F4 conserva la ayuda de puntería; F9 conserva el acceso de prueba de jefes. No hay conflicto con acciones de gameplay. F5/F6 del editor y los atajos `ui_` internos de Godot no son controles de gameplay: dar foco a la ventana del juego.

Compatibility no ofrece bloom nativo. Se implementó un pase aditivo a media resolución con máscara exclusiva de mallas emisivas de proyectiles: cámara aparte, fondo negro, desenfoque y composición. No ilumina casas, cielo, enemigos ni otros objetos claros. Las estelas conservan sus colores y reciben emisión; no se duplican partículas para el pase de bloom. Ajustes: `BLOOM_GAIN`, `BLOOM_RADIUS`, `BLOOM_RESOLUTION_DIVISOR`.

No se cambiaron formas ni colores originales de disparos, colisiones, hitboxes, daño o velocidades. Los tamaños mayores afectan únicamente nodos visuales; la hurtbox de Bee y los radios de daño permanecen iguales.

## Capturas y rendimiento

`docs/legibilidad_antes_despues.png`: tres filas del nivel real (enjambre de moscas de día, hormigas de día, avispas de noche); izquierda todo apagado, derecha valores recomendados. Cada captura mide 1154 × 648; el montaje mide 2308 × 1944. Usa las fábricas, materiales y cámara del juego, con posiciones controladas para comparar. No son ilustraciones recreadas.

El ancho proyectado de los límites de las mallas de Bee pasa de 93,6 a 117,1 px, aproximadamente +25 %. Incluye alas y arma; no es una medición de los píxeles opacos del cuerpo ni directamente comparable con la estimación de 55 px del video.

La medición usa Intel Arc B580, Compatibility, sin VSync ni límite de FPS: 3 FlyCloud + 4 FlyCommon, siete disparos enemigos y cinco de Bee, posiciones congeladas; tres pasadas con orden rotativo (0/1/2, 2/0/1, 1/2/0), 2 s de calentamiento y 6 s de muestra por configuración. Mide el costo de render del montaje, no una partida completa con IA.

| Configuración | Pasada 1 | Pasada 2 | Pasada 3 | Media FPS | Caída vs apagado |
|---|---:|---:|---:|---:|---:|
| Todo apagado: ×1 / 0 / 0 / 0 | 113,3 | 105,4 | 108,3 | 109,0 | — |
| Recomendada: ×1,25 / 1 / 1 / 1 | 99,5 | 88,6 | 94,9 | 94,4 | 14,6 FPS |
| Máxima: ×1,4 / 2 / 2 / 2 | 99,5 | 93,3 | 93,9 | 95,6 | 13,4 FPS |

**La caída supera 5 FPS**, tanto con los valores recomendados como con todo al máximo. Hay variación entre muestras; el pequeño orden inverso entre recomendada y máxima no demuestra que la máxima sea más barata. El pase extra de bloom tiene costo: conviene comparar F8 apagado y ajustar su resolución antes de decidir una configuración definitiva.

## Validación

Pruebas dirigidas: `validate_bee_live_readability`, `validate_bee_tanda4a_fire_aim`, `validate_bee_lote17_sky_v01`, `validate_bee_disparos_b`: 4/4 pasaron. La nueva prueba verifica valores/teclas, tamaño del dibujo y boca de disparo, hurtbox, aislamiento y material efectivo del fondo, forma/color/radio/daño/velocidad del disparo, emisión y restauración al apagar. Se corrigieron las aserciones iniciales del fixture y una conversión de nodo ya destruido en una notificación diferida; se repitieron únicamente las pruebas afectadas y se revisaron sus logs. No se corrió la suite completa, siguiendo el alcance explícito de esta tanda. Algunos tests emiten avisos de recursos al cerrar Godot; no hubo errores de script, llamadas diferidas ni fallos de aserciones en la corrida final.

Herramienta reproducible: `tools/revisar_legibilidad.gd`. Ejecutar con Godot, `--path . --resolution 1154x648 --script res://tools/revisar_legibilidad.gd -- --debug-readability`. Regenera el PNG y guarda las muestras en `dev/legibilidad_fps.json` (ignorado por Git). No ejecutar headless para capturas/FPS.

## Qué comparar en Godot

Abrir el Nivel 01, ejecutarlo y dar foco al juego. Comparar enjambres y hormigas de día, y avispas de noche:

- F5: si Bee se reconoce sin tapar blancos; recordar que el dibujo mayor conserva la hurtbox original.
- F6: si el borde fino ayuda y si el grueso oculta detalles o se nota excesivo.
- F7: si casa, cerca y colinas distraen menos, conservando el plano de acción.
- F8: si los disparos se distinguen mejor sin que el halo tape blancos; comparar también el tamaño del nivel 2 y los FPS.

F4 sigue mostrando la ayuda de puntería. Para reducir costo, probar primero neón 0 o aumentar `BLOOM_RESOLUTION_DIVISOR`; para reducir halo, bajar `BLOOM_GAIN`. Los cambios visuales definitivos quedan pendientes de esta comparación del usuario.
