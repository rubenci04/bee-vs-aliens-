# BEE SHMUP FAIRNESS PASS 01

Rama `shmup-fairness-01`. No se agregaron enemigos, armas ni boss; Level Design, cámara D, estilo C y Giant Human no se tocaron. Test: `tests/levels/validate_bee_shmup_fairness_v01.gd`.

## 1. Hitbox de Bee (cambió)
Silueta visible (modelo sin alas, ejes del modelo): 0.52 ancho × **0.53 alto** × 0.98 largo, con patas y antenas.

| | Antes | Después |
|---|---|---|
| Hurtbox (daño recibido) | esfera r 0.28 (⌀ 0.56 ≥ alto visible 0.53) | esfera **r 0.20** (⌀ 0.40 = 75 % del alto visible) |
| Colisión de cuerpo (CharacterBody) | r 0.28 | r 0.28 (sin cambios: rocas, límites) |

La hurtbox compartía el recurso con el cuerpo; ahora tiene el suyo (`hurt_shape`). Contacto efectivo con un proyectil enemigo: antes 0.28+0.17 = 0.45 m del centro (más que la silueta), ahora 0.20+0.11 = **0.31 m** (~73 % del contacto visual 0.16+0.265). También rebaja la zona letal frente a mordidas, embestidas y contacto de enemigos, que usan la misma hurtbox. HP y escala visual intactos. No es una hitbox de píxel: ⌀ 0.40 m.

## 2. Proyectiles enemigos (cambió el collider)
Un único `alien_enemy_projectile.tscn` para Probe, EyeDrone, Turret y Walker. Mesh r 0.16; collider **0.17 → 0.11** (69 % del núcleo visible). Daño (8, o el del emisor), velocidad (6, o la del emisor) y vida (2.5 s) sin cambios.

## 3. Fuego fuera de pantalla y 4. ceasefire trasero (nuevo)
`BeeShmupFairness.can_fire(enemy)` (`scripts/bee_prototype/bee_shmup_fairness.gd`): el enemigo solo dispara si su centro está al menos `ENTRY_MARGIN` = 0.4 m dentro del borde visible, medido contra la cámara activa y a la profundidad del enemigo (no depende del preset de Level 01). Cubre los dos casos: todavía no entró (derecha) y quedó atrás (izquierda).
- Se evalúa solo en el instante del disparo (sin sondeo por frame). Llamado desde `_shoot` (Probe/Turret), `_shoot_at_bee` (EyeDrone) y `_fire_projectile` (Walker).
- Si no puede disparar: se omite el proyectil, la IA sigue su ciclo normal (windup→cooldown), no se mata ni se retira a nadie. Se cuenta en `suppressed_shot_count`.
- Real: el Probe/EyeDrone se detienen a 5–7 m de Bee, por lo que con Bee en el borde derecho antes disparaban desde fuera de pantalla.
- Los proyectiles ya en vuelo no se cancelan al salir.

## 5. Visibilidad del peligro
- Proyectiles y enemigos viven en z=0; la decoración está detrás (z ≤ −3) o debajo de la banda en pantalla (foreground limitado por el test del Visual Target), así que tallos, peñascos de fondo y foreground no los tapan.
- Cambió: el material del proyectil era opaco y los VFX (muerte, explosión, bomba) son transparentes con prioridad 0 y podían cubrirlo. Ahora es `TRANSPARENCY_ALPHA` (alpha 1) con `render_priority = 50`: se dibuja encima de los VFX, sigue ocluido por la geometría opaca delante.
- Peñascos sólidos en z=0 (FlightRock) sí pueden ocultar un proyectil que pasa detrás de ellos; es oclusión real del 3D y se deja (el peñasco también es un obstáculo visible).

## 6. Alien Bomb y proyectiles — estudio
- Hoy: Bomb es una consulta instantánea de esfera r 3 m contra hurtboxes (máscara 2); los proyectiles enemigos no tienen hurtbox, así que no los afecta. Máx. 3 cargas.
- Medido en la simulación automática (Probe+EyeDrone+Turret+Walker a la vez, 12 s): **pico de 4 proyectiles simultáneos**, 13 disparos. En el nivel real hay como mucho 3 enemigos a la vez.
- Opciones: A mantener solo ofensiva; B cancelar proyectiles dentro de 3 m; C cancelar todos los visibles; D otra.
- **Decisión: A** (sin cambios). B sería técnicamente simple (grupo `alien_projectiles` ya existe, un barrido en `_discharge`) y coherente con el anillo, pero convierte la bomba en botón de pánico y cambia el balance de las puertas duras; eso es una decisión de diseño del dueño, no de equidad. C descartada (borra toda amenaza). Si se quiere B: añadir en `BeeAlienBomb._discharge` el barrido de `alien_projectiles` a ≤ `radius` en XY y un test; el test actual fija el comportamiento A.

## Sin cambios necesarios
Daño, velocidad y vida de proyectiles; IA de los cuatro enemigos; HP de Bee; colisión de cuerpo de Bee; Giant Human; foreground y decoración.

## Limitaciones y reservado
- La regla mira solo el ancho visible (X), no el alto; los enemigos nunca nacen sobre el borde superior.
- Contacto de enemigos (avispa, orgánico, Speeder) no se auditó en tamaño más allá del efecto de la hurtbox de Bee.
- Reservado para boss/Danmaku: densidad de balas, patrones, cancelación por bomba, hitbox de pixel con foco, y prioridad de render de balas por tipo.
