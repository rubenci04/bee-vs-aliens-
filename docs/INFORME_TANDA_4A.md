# Tanda 4a — fuego continuo y puntería

Rama `lote-16-titulo-intro`. Alcance: input de fuego, dirección de los tiros, volumen de daño de los proyectiles de Bee y retícula. No cambian vidas ni valores de daño de Bee/enemigos, armas, assets, velocidad de proyectiles, multiplicadores de implante ni movimiento.

## Auditoría previa, cinco líneas

1. El ratón se proyectaba desde la cámara al plano X/Y (`z=0`).
2. El stick derecho fijaba un punto a 10 m de Bee, con suavizado.
3. El tiro manual iba desde la boca del arma hacia ese punto y tenía prioridad sobre el autoapuntado.
4. Sin entrada manual se elegía el enemigo más cercano dentro de 12 m y un cono frontal de 80°; sin blanco se disparaba recto.
5. La retícula solo aparecía durante el apuntado manual; el ratón caducaba tras 1,5 s y el stick al soltarlo.

Mapa consultado: `docs/AUDITORIA_CONTEXTO.md`, input/disparo/retícula y H-16. La adenda local menciona H-16 en la tabla de tandas, pero no contiene un apartado propio que amplíe ese hallazgo.

## Fuego y DPS

| Modo sostenido | Antes | Ahora | DPS nominal antes → ahora |
|---|---|---|---|
| Base | 3 tiros de 4, separados 0,06 s, en ráfagas a 2,5/s (paquete cada 0,4 s; empieza tras 0,12 s sostenido) | Un tiro de 4 cada `FIRE_INTERVAL = 1/7,5 = 0,13333… s`, sin pausa de ráfaga | `2,5 × 3 × 4 = 30` → `7,5 × 4 = 30` |
| Spread | Abanico de 5 perdigones de 4 a 2,5/s | Mismo abanico, cada `SPREAD_FIRE_INTERVAL = 0,4 s` mientras se mantiene el botón | `2,5 × 5 × 4 = 50` → `50`, si impactan los cinco |

Se mantiene el primer tiro/toque inmediato, de **10 Base** o **3 × 8 Spread**, y los valores existentes de los tiros sostenidos (4 por proyectil). Después siguen los intervalos anteriores. Los valores de daño no se cambiaron. El primer toque añade un transitorio al DPS de una ventana corta; la tabla compara fuego sostenido a largo plazo. Para un enemigo que recibe unos tres de los cinco perdigones Spread, el DPS sostenido aproximado sigue siendo 30. Frenesí conserva su proyectil paralelo y su multiplicador existentes. Mejor puntería, hitboxes más grandes y aciertos en implante pueden aumentar el daño efectivo realizado, aunque el DPS nominal y los multiplicadores sean iguales.

X, clic izquierdo, A y RT siguen usando la misma acción `throw_orange`; no se cambió el mapeo del mando. Soltar no deja tiros pendientes. El código antiguo `start_burst()` se mantiene como entrada compatible para bots, pero solicita un solo tiro y ya no programa tres rondas. Las llamadas directas a `fire()` de bots/tests mantienen su contrato.

## Ayuda y retícula

Todas las constantes nuevas de la tanda están en **`scripts/game/bee_shooting_settings.gd`**:

| Constante | Valor / efecto |
|---|---|
| `AIM_ASSIST_ENABLED` | `true`; `false` restaura la dirección manual/auto anterior y desactiva la nueva prioridad/filtro del autoapuntado |
| `AIM_ASSIST_ANGLE` | 12°, semicono alrededor de la dirección pretendida |
| `AIM_ASSIST_STRENGTH` | 0,5; interpola el ángulo a mitad de camino hacia el blanco |
| `AIM_ASSIST_RANGE` | 12 m |
| `PLAYER_SHOT_HITBOX_SCALE` | 1,25; esfera de daño 0,12 → 0,15 m, sin cambiar la malla visual |
| `RETICLE_IDLE_OPACITY` / `RETICLE_ACTIVE_OPACITY` | 0,35 / 0,85 |
| `RETICLE_DISTANCE` / `RETICLE_RADIUS` / `RETICLE_WIDTH` | 3,5 m desde la boca; aro de 6 px y grosor 1,5 px |
| `RETICLE_SCREEN_MARGIN` | 18 px; recorta la distancia sobre el mismo rayo para no salir de pantalla |
| `AIM_DEBUG_DEFAULT` / `AIM_DEBUG_KEY` | `false` / F4 |

Con ratón/stick se mantiene el punto manual original y solo se corrige dentro del cono; un enemigo fuera del cono no atrae los tiros. Entre candidatos, primero implante vulnerable y luego distancia. Sin apuntado manual se conserva la adquisición frontal de 80°/12 m existente, ahora con prioridad a implantes disponibles y filtro de visibilidad/invulnerabilidad; sobre esa dirección actúa la ayuda suave de 12°. No hay seguimiento del proyectil después del disparo.

El helper comprueba que el enemigo y el punto elegido estén en pantalla y que su salud/implante acepte daño. Se excluyen jefes invulnerables. La ayuda no atraviesa objetos ni salta enemigos: los proyectiles siguen chocando con lo primero que encuentran. Enemigos encimados pueden interceptar un tiro dirigido al de atrás.

La retícula muestra el rayo final desde la boca del arma, no el cursor sin corregir. Es un aro abierto, fino y sin centro relleno ni corchetes grandes. Sigue visible al soltar el stick o caducar el ratón; se oculta al pausar, morir o terminar el sector. F4 dibuja los dos bordes del cono y marca el objetivo elegido; se apaga con F4 otra vez.

La ampliación de hitbox usa una copia de la forma por proyectil para no acumular escalas ni tocar recursos compartidos. Solo afecta proyectiles derivados de `BeeEnergyProjectile`; los enemigos y sus disparos conservan sus colisiones. No afecta al daño del aguijón ni de bombas.

## Pruebas

Siete pruebas dirigidas aprobadas: `validate_bee_tanda4a_fire_aim`, `validate_bee_lote14_controls_v01`, `validate_bee_free_aim_v01`, `validate_bee_lote15_input_v01`, `validate_bee_weapons_powerups_v01`, `validate_toon_projectiles_v01` y `validate_bee_readability_v03`. Sin suite completa y sin timeout externo. La prueba de armas falló primero por exigir la dirección vieja al centro del cuerpo; se actualizó esa expectativa y el impacto único de Spread permite el multiplicador de implante de 2× que ya existía. Se volvió a correr solo esa prueba. La prueba nueva también verifica un impacto físico de refilón de 10 de daño, con un blanco cuyo desplazamiento de 0,16 m quedaba fuera del radio antiguo; se corrigió la capa de ese blanco de prueba y pasó al repetirla.

Checks nuevos: 16 disparos (el primero + 15 automáticos) en 2 s; cero ráfagas pendientes; cero tiros después de soltar; corrección de 10° a 5°; prioridad vulnerable, exclusión de invulnerables/fuera de pantalla/fuera del cono; blanco inferior; retícula alineada y visible en reposo; F4; recurso original de 0,12 m intacto y copias de 0,15 m; impacto físico único sin cambiar daño. Las pruebas existentes cubren mouse, ocho direcciones, stick, umbral RT 0,3, Spread, Frenesí/armas y aspectos de legibilidad.

## Qué probar a mano

- Mantener y soltar X, clic y RT: ritmo uniforme, corte inmediato y ninguna ráfaga final; repetir con Spread y al caducar el power-up.
- Enemigos arriba y abajo simultáneamente: mover mouse/stick hacia cada uno sin desplazar mucho a Bee; comprobar que la ayuda no salta al que queda fuera del cono.
- Enemigos encimados: revisar la prioridad del implante y si el primer cuerpo intercepta los tiros; esta tanda no añade penetración.
- Comparar ratón y mando, apuntar detrás/arriba/abajo, soltar el stick: retícula visible y tenue, sin cursor del sistema durante gameplay.
- Con F4 comprobar el cono/objetivo en bordes y durante invulnerabilidad de jefes. Probar pausa, muerte y final de nivel.
- Si se siente muy pegado: bajar `AIM_ASSIST_STRENGTH` a 0,25–0,35 o `AIM_ASSIST_ANGLE` a 8°. Si se siente flojo: subir fuerza a 0,65–0,75 o ángulo a 14–16°. Cambiar una constante por vez; usar `AIM_ASSIST_ENABLED=false` para comparar.
- Si la retícula molesta: bajar su opacidad o radio. Si los impactos parecen demasiado generosos: bajar `PLAYER_SHOT_HITBOX_SCALE` hacia 1,10; 1,0 vuelve al radio anterior. Variar `FIRE_INTERVAL` sí cambia el DPS sostenido.

Archivos funcionales: `bee_player.gd`, `bee_energy_projectile.gd`, `bee_level_01_crosshair.gd`, nuevo helper `bee_aim_assist.gd` y nuevas constantes `bee_shooting_settings.gd`; pruebas relacionadas, controles y este informe. No se incluyeron `dev/`, el archivo local de la adenda ni otros cambios ajenos.
