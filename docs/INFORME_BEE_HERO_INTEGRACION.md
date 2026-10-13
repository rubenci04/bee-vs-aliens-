# Integración del Bee héroe v02

Rama: `lote-15c-bee-integracion`.

- Bee v02 queda como selección predeterminada; `BeeGameSettings.set_bee_model_version("v01")` vuelve al Bee anterior en caliente. v01 y su GLB no se modifican.
- Los proyectiles usan `muzzle` con la dirección de apuntado existente. El destello y retroceso de antena, propulsores CPUParticles dorados/naranjas, taladro con estela y chispas, flash metálico de pirueta y parpadeo cubren las mallas nuevas. No se añade cian a efectos del Bee.
- Escala visual v02: `BEE_VISUAL_SCALE = 1.0`; colisionador y hurtbox conservan radios 0,28 y 0,20. El test confirma que el modelo no altera física ni apuntado. No hizo falta cambiar la cámara.
- Parámetros de presentación y actividad: constantes `BEE_*` en `scripts/game/bee_game_settings.gd`.
- El informe de arte del modelo registra 1,4 m de largo con escala de preview 1,2 y geometría GLB sin escalar de 1,1667 m. Esta integración sigue la instrucción de usar escala 1,0; conviene revisar esa cifra de referencia al comparar en pantalla.
- Roadmap de la escafandra: `docs/ROADMAP_BEE_ESPACIO.md`. No se modeló casco.

Validación dirigida Godot 4.7.2 headless: `validate_bee_hero_integration_v01.gd`, `validate_bee_visual_polish_v02.gd` y `validate_bee_visual.gd` (esta última fuerza v01 para comprobar compatibilidad). Cubre anclas requeridas, cargas v02/v01, salida desde muzzle con yaw a ambos lados, puntería, hitboxes, flash, partículas, taladro y pirueta. No se capturó una imagen de gameplay en esta pasada.

Suite completa (Godot 4.7.2, una corrida): **95/102 PASS**, siete fallos iniciales. Al revisar, cuatro eran expectativas antiguas de pruebas sobre el nombre cian del muzzle, el origen de tiro en el centro, el tamaño de la silueta v02 y un fixture de disparo horizontal; se actualizaron y sus pruebas dirigidas pasan. La trayectoria desde el muzzle se corrigió para que siga pasando por el punto apuntado. La prueba dirigida del jefe UFO midió Base Normal **81,2 s / 66 de daño** y Spread Normal **75,0 s / 86 de daño**; Spread excede el objetivo de daño de 50–70. La prueba dirigida de tarántula Base Normal dio **87,0 s / 63 de daño**. La validación de pacing sigue sin confirmar el umbral de densidad en esa corrida.

La suite completa no se volvió a ejecutar para respetar la instrucción de una sola corrida, por eso el resultado global sigue siendo rojo y no se hizo commit ni push. La cámara conserva el encuadre F existente (distancia 11,2 m); no se capturó una imagen de gameplay con render durante esta tarea.
