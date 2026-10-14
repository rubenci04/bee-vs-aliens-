# T1b — HUD y textos limpios

Rama: `lote-16-titulo-intro`. Alcance: presentación del HUD y avisos; sin cambios de gameplay, daños, disparos, colisiones, inventario ni checkpoints guardados.

## Cambios

- Banner común arriba y al centro, con panel oscuro redondeado y borde dorado. Los avisos se encolan cuando otro ocupa el espacio: nunca compiten entre sí, con la vida o con el nombre/barra del jefe.
- El mando se anuncia durante 2 s, con fundido, al cambiar el dispositivo efectivamente usado. Conectar un mando sin usarlo no dispara el aviso. Volver al teclado/ratón muestra su aviso una vez por cambio. Los botones y el Input Map conservan sus asignaciones.
- La leyenda cruda bajo la vida ya no se dibuja. Los botones B/LB y Y/RB siguen en los íconos del HUD. Consejos cortos de Spread/bomba al recogerlos, pirueta cuando hay suficientes disparos enemigos y aguijón cuando hay un objetivo cercano: una vez por tipo en cada instancia del nivel, durante 2,5 s, con fundido.
- CHECKPOINT y CHECKPOINT 2 usan el banner de 1,5 s. Se ocultan sus títulos 3D; se conservan los marcadores, flor y aros originales. El mensaje de protección al reaparecer usa el mismo espacio.
- Cada liberación suma al contador único `+N LIBERADOS`, incluidas las primeras dos. La ventana fija de 0,6 s empieza con la primera liberación y no se prolonga con las siguientes. Cada ventana nueva vuelve a uno. Cuando el espacio está ocupado, su resultado espera en la cola. Como máximo dos `LIBERADO` individuales, de fuente 32 en lugar de 44 y opacidad inicial 60 %, incluidos los bordes; desaparecen con el fundido anterior.
- La instrucción de la Tarántula pasa de fuente 16 a 32, centrada debajo de la barra del jefe, con fondo oscuro y contorno negro. Nombres, barra y duración de las instrucciones de jefes se conservan.

## Auditoría de carteles de especies (punto 5)

`BeeLevel01Controller._spawn()` llama a `_announce_species()`. Esta ya comprueba `species_seen.has(family)` y registra el primer encuentro antes de mostrar nada. **No se repetían en cada oleada**: aparecían una vez por familia e instancia del nivel. Se conserva ese filtro; solo se cambia su presentación a un banner superior más pequeño que la UI del jefe, durante los mismos 1,5 s.

| Nombre interno | Cartel | Antes | Ahora |
|---|---|---|---|
| FlyCommon | MOSCA | Primera aparición | Primera aparición, banner |
| Wasp | AVISPA | Primera aparición | Primera aparición, banner |
| FlyGreen | MOSCA VERDE | Primera aparición | Primera aparición, banner |
| Ant | HORMIGA | Primera aparición | Primera aparición, banner |
| Ladybird | MARIQUITA | Primera aparición | Primera aparición, banner |
| Spider | ARAÑA COLGANTE | Primera aparición | Primera aparición, banner |

También usan el mismo filtro/banderín Nube de moscas, Gusano rosa, Caracol, Escarabajo, Gusano de compost y Hongo cañón. Los nombres internos de eventos contienen especies repetidas, pero no se muestran en el HUD normal: `show_debug_labels` está apagado. Reiniciar/recrear el nivel inicia nuevamente ese registro, como antes.

## Constantes y archivos

`scripts/game/bee_hud_text_settings.gd`: duraciones 2/1,5/2,5 s, fundido 0,45 s, ventana 0,6 s; ancho del banner 440, posición superior 6, altura 38; fuentes 24/20, individual 32/0,6 y jefe 32. `scripts/ui/bee_hud_notices.gd` administra la única zona, la cola y el contador.

Integración localizada en `bee_input_devices.gd`, `bee_weapons_hud.gd`, `bee_checkpoint_qol.gd`, `bee_liberation.gd`, `bee_level_01_controller.gd` y `tarantula_boss_01.gd`.

## Verificación

- Pasaron las seis pruebas dirigidas: `validate_bee_t1b_hud`, `validate_bee_lote14_screen_v01`, `validate_bee_weapons_powerups_v01`, `validate_bee_lote17_checkpoint_v01`, `validate_bee_checkpoint_qol_v01` y `validate_bee_liberation_v01`. Sin suite completa, por pedido del usuario.
- Se actualizaron expectativas visuales antiguas de pistas/checkpoints/letreros. La prueba de liberación normaliza la escala visual 1,40 decidida en T3g al comprobar el tamaño canónico de Bee; no cambia el modelo ni su hitbox.
- Capturas reales con Godot Compatibility, 1154×648, de inicio, checkpoint 2, ocho moscas liberadas y Tarántula. Comparación etiquetada en `docs/hud_antes_despues.png`. La columna anterior usa los seis scripts originales de HEAD previo a T1b; las copias de trabajo se restauraron íntegramente después de capturar. El montaje usa la misma escena/cámara y llamadas reales de liberación. No es una grabación de una partida completa: las situaciones se preparan y detienen para compararlas.
- `tools/hud_antes_despues.gd` genera el montaje con `--after`, usando las capturas anteriores de `dev/t1b_before_*.png`. `dev/` no se incluye en el commit. Apertura/renderizado del nivel sin errores de scripts ni de consola en las cuatro capturas. Algunos tests headless imprimen el aviso conocido del renderer dummy sobre material nulo; no aparece en el render real.

## Qué probar / pendientes

En Godot, abrir `scenes/levels/bee_level_01_vertical_slice.tscn`: alternar mando y teclado/ratón; cruzar ambos checkpoints; liberar varias moscas rápidamente y luego otra después de 0,6 s; repetir una oleada de cada especie; comprobar consejos e íconos; mirar la instrucción de la Tarántula. Verificar que los avisos en cola resulten oportunos durante combate intenso. Pendiente: validación humana con mando real y distintas resoluciones; la comprobación automática se hizo a 1154×648.
