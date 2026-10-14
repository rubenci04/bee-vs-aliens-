# T4b — Aguijón como embestida, daño y entrada de hormigas

Rama: `lote-16-titulo-intro`. Alcance localizado: Bee, registro de daño, entrada de hormigas y pruebas/capturas. No se tocaron armas de fuego, daños, vidas ni geometrías de colisión.

## Auditoría previa

- `bee_player.gd`: `ChromeStinger` era un cono cromado de 0,8 m y partículas cálidas, no una línea larga Bee→blanco. El problema confirmado era **habilitar y colocar la hitbox directamente sobre el enemigo al iniciar**, antes de completar el desplazamiento. `_update_melee()` además seguía al blanco con esa hitbox. Se eliminó ese camino instantáneo.
- `bee_visual.gd`: animación `drill_spin`, estela metálica y destello de impacto existentes, reutilizados. `bee_melee` de `BeeCombatVFX` es un efecto local de impacto, no un rayo entre Bee y el blanco.
- Las miras de ataques enemigos son dibujadores independientes. No se encontró una línea naranja larga asociada al Aguijón en esta revisión del código. No se inventó una causa para la línea de la grabación ni se modificaron avisos enemigos. Sin ese fragmento, su origen exacto queda pendiente de contraste visual. La estela cálida del cono ahora es plateada; no se crea ningún rayo ni línea de apuntado para la embestida. La ayuda de puntería/F4 permanece intacta.
- No se encontró una regla de pérdida física del aguijón que mate a Bee: no se agregó una muerte ni otra mecánica nueva.
- Las hormigas se instancian en `BeeLevel01Controller._spawn()`. Con `anthill: true`, `BeeLevel01Anthills.emerge()` las colocaba en `EntranceAnchor`, subía 0,3 m y luego añadía un salto de 0,5 m antes de bajar al carril `y = -0,2`. El anclaje al suelo también se impone ahora a solicitudes de Ant con otra altura.

## Comportamiento y constantes

`scripts/game/bee_sting_settings.gd` concentra la configuración nueva:

| Parámetro | Valor | Función |
|---|---:|---|
| `REACH` | 2,08 m | Alcance anterior conservado; blanco válido más cercano en 360° |
| `DASH_SECONDS` | 0,22 s | Avance mediante movimiento físico y límites existentes |
| `STOP_DISTANCE` | 0,45 m | Separación prevista al llegar al blanco |
| `CONTACT_ALLOWANCE` | 0,35 m | Solo habilitar el golpe si Bee realmente llegó cerca |
| `IMPACT_SECONDS` | 0,06 s | Contacto después de avanzar; misma hitbox y daño 30 |
| `RECOIL_DISTANCE` / `RECOIL_SECONDS` | 0,35 m / 0,10 s | Reposicionamiento corto hacia atrás |
| `EMPTY_DISTANCE` | 1 m | Sin blanco: avanzar hacia el apuntado, sin daño |
| `DAMAGE_FLASH_SECONDS` | 0,12 s | Destello al recibir daño |
| `DAMAGE_FLASH_COLOR` | cálido, alfa 0,28 | Overlay breve; los materiales y su contorno no se reemplazan |
| `DAMAGE_LOG_MAX` | 128 | Límite de registros en memoria durante desarrollo |

`bee_sting_dash.gd` orienta el cuerpo y el cono según el avance. La hitbox viaja con Bee y permanece apagada hasta llegar; nunca se teletransporta sobre el blanco. Bee es invulnerable durante avance/contacto/retroceso. No hay carga ni recarga; se puede repetir al terminar la animación. Aguijón y pirueta se esperan: una solicitud durante la otra queda pendiente, respetando además la espera existente de la pirueta.

`bee_damage_trace.gd` recibe solo daño realmente aplicado por `DamageHurtbox3D`: emisor, nodo del proyectil/ataque, cantidad y segundos monotónicos. Se guarda en memoria y consola exclusivamente en desarrollo; la condición retorna antes de registrar/imprimir en exportaciones, incluso exportaciones debug. No añade texto al HUD ni archivos de registro propios.

Las hormigas conservan polvo y crecimiento existentes, 0,7 s de salida y 0,4 s de descenso final. Ya no suben ni saltan: salen desde la boca y descienden continuamente hasta `GROUND_Y = -0,2`, antes de activarse. `MOUTH_EXIT_FRACTION = 0,35` y `DESCENT_FRACTION = 0,65` son configurables en `bee_level_01_anthills.gd`. Vida, daño, cantidad y calendario de aparición se mantienen.

## Verificación

Cinco pruebas dirigidas aprobadas, sin suite completa ni timeout externo:

- `validate_bee_t4b`: desplazamiento antes del daño, invulnerabilidad, contacto real, espera de ambas maniobras, embestida vacía sin daño, ausencia de carga, flash de 0,12 s, puerta de desarrollo del registro y hormiga con solicitud `y=4` que baja al suelo sin salto.
- `validate_bee_lote14_controls_v01`: alcance, blanco delante/detrás, controles y nueva espera hasta el contacto.
- `validate_bee_weapons_powerups_v01`: armas y power-ups conservados.
- `validate_bee_lote14_screen_v01`: hormigueros, encuadre y legibilidad existentes.
- `validate_bee_hero_integration_v01`: modelo, hurtbox/collider, flash, animación del taladro y pirueta. La expectativa de pirueta inmediata se sustituyó por esperar al fin de la embestida; contempla el hit-stop existente.

También se ejecutaron `validate_bee_audio_basic_v01` y `validate_bee_combat_vfx_v01`: **fallan antes de probar el Aguijón**, por expectativas anteriores a T4c (impacto de bala de 10, muzzle en el origen físico y radio de bala 0,12; hoy el daño base es 3, muzzle visual independiente y radio 0,15). Se dejaron intactas; actualizar esos fixtures de armas queda pendiente fuera de T4b. No se cambió gameplay para satisfacerlos.

Nivel 1 renderizado con Godot 4.7.2 Compatibility/Intel Arc. `tools/aguijon_hormigas.gd` genera la secuencia real de cinco cuadros en `docs/aguijon_embestida.png` y cuatro momentos de salida en `docs/hormigas_entrada.png`; ambas imágenes revisadas. Sin errores de script durante la captura. El renderer GLES3 emite cuatro mensajes `Parameter "material" is null` al liberar/cerrar la escena; persisten con liberación explícita y quedan como diagnóstico de cierre, no ocultados.

`docs/ADENDA_GAMEPLAY_2.md` ya estaba seguida por Git. No se incluyen `dev/`, importaciones automáticas ajenas ni otros documentos locales.

## Qué probar

Abrir `scenes/levels/bee_level_01_vertical_slice.tscn` con F6. Activar Z / Y / RB con blancos delante, detrás, arriba y abajo: Bee debe avanzar con el aguijón delante, dañar al llegar y retroceder. Repetir sin blanco: dash de 1 m, sin daño. Alternar con Shift / B / LB durante ambas animaciones; comprobar la espera sin superposición. Recibir daño normal: destello breve con contorno legible. En los primeros hormigueros, observar salida con polvo, descenso y marcha apoyada en el suelo.

Pendientes: sensación con mando/ratón, identificación de la línea naranja de la grabación, actualización de los dos tests antiguos de armas y diagnóstico de los mensajes GLES3 al cierre. Ningún asset borrado o importado.
