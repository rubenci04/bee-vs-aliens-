# Bee SHMUP Air Variety POC

POC aislado: `res://scenes/bee_prototype/bee_shmup_air_variety_poc.tscn`. Conserva la cámara/stage y naturaleza aprobada del SHMUP Core; no modifica Mission 01 ni el POC original. Scroll +X a 2,0 m/s, sector de 76 m, cuatro polen opcionales, máximo dos enemigos vivos.

## Assets y escala

Licencias locales verificadas antes de copiar: Quaternius Sci-Fi Essentials Kit[Standard] y Kenney Space Kit, ambas CC0. Procedencia y dependencias exactas en `res://assets/external/ASSET_PROVENANCE.md`. Godot importó el glTF+BIN+3 PNG de EyeDrone y el GLB autocontenido de Speeder sin conversión ni Blender.

| Modelo | AABB original Godot (ancho × alto × profundidad) | Escala instancia | AABB resultante aproximado | Orientación |
|---|---:|---:|---:|---|
| Bee referencia | 1,10 × 0,56 × 0,98 m | 1,00 | igual | derecha visual del Player |
| Probe referencia | 1,22 × 0,65 × 1,22 m | 1,00 | igual | facing existente |
| EyeDrone | 1,00 × 1,00 × 0,89 m | uniforme 1,05 | 1,05 × 1,05 × 0,94 m | VisualRoot gira Y según Bee; +90° mira izquierda |
| Speeder | 2,00 × 0,80 × 2,10 m | uniforme 1,10, pivote centrado en instancia | lateral ~2,31 × 0,88 × 2,20 m | modelo Y +90°, punta hacia izquierda |

El EyeDrone es más alto pero más angosto que Probe; la relación Bee < Eye ≲ Probe se interpreta por presencia visual, no por cada eje. El Speeder es claramente mayor, sin escala de boss. Visual Lab: `res://dev/alien_air_review/alien_air_review_lab.tscn`; captura `res://dev/alien_air_review/alien_air_review.png`.

## Patrones provisionales

- **Probe:** comportamiento ranged positional existente, sin cambios.
- **EyeDrone:** ENTER → CHASE X/Y manteniendo 2,5–4 m → WINDUP cian 0,4 s → un disparo recto de 6 HP con el proyectil alienígena existente → COOLDOWN/reposición 1,4 s → DEAD. 18 HP, 4,5 m/s. Usa Health, Hurtbox y HitFlash Bee.
- **Speeder:** ENTER desde derecha → aviso naranja 0,7 s → DASH a la izquierda a 9,5 m/s → EXIT y nueva pasada si sigue vivo. 23 HP; contacto sólo durante DASH: 13 HP. No dispara. Hitbox se desactiva en entrada, aviso, salida y muerte. Usa Health, Hurtbox y HitFlash Bee.

Ambos integran `bee_auto_aim_targets`; Bee conserva su algoritmo. El marcador en esta escena se redujo y elevó para despejar la silueta. Los enemigos muertos desaparecen del target válido.

## Cuatro oleadas

1. Probe desde ~6 m.
2. Dos EyeDrone escalonados desde ~20 m.
3. Speeder desde ~38 m.
4. EyeDrone + Speeder escalonados desde ~55 m.

La siguiente oleada espera resolución de la anterior y su umbral de distancia. Nunca hay más de dos enemigos vivos. Tras resolver la cuarta y avanzar hasta el fin: «SECTOR DESPEJADO». R tras derrota recarga Bee, scroll, oleadas y polen. El POC omite boss, scoring, audio y arte nuevo; Speeder repite pasada mientras viva para evitar bloqueo si se falla el primer ataque. La botella gigante heredada se oculta sólo aquí porque competía visualmente con la Wave 3.

Limitaciones: no se ha balanceado duración/dificultad por playtest humano; el tamaño y paleta de los modelos son provisionales. El EyeDrone es oscuro fuera del telegraph y el Speeder es una nave Kenney aún sin lenguaje cromático alien propio. No se recolorearon fuentes.
