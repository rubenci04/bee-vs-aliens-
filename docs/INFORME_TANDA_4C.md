# Tanda 4c — Arma principal: cadencia, triple e impacto

Rama: `lote-16-titulo-intro`. Se consultaron `INFORME_TANDA_4A.md`, constantes y el recorrido real de disparo, daño y presentación. No hay niveles desbloqueables de arma ni un triple independiente: **triple es el Spread existente**. Doble es Frenesí (`honey_left`), que puede combinarse con Spread. `collect_spread_overcharge()` es un alias de recoger Spread, sin otro nivel de potencia.

## Auditoría antes del cambio

DPS nominal: suma del daño por descarga / intervalo, suponiendo que todos los proyectiles impactan. Los toques aquí se comparan a la máxima cadencia admitida por el input; las llamadas directas `fire()` de bots no imponen espera.

| Estado / entrada | Proyectiles por descarga | Intervalo | Velocidad | Daño por proyectil | DPS nominal |
|---|---:|---:|---:|---|---:|
| Base, tocar repetidamente | 1 | 0,13333 s | 14 m/s | 10 | 75 |
| Base, mantener | 1 | 0,13333 s | 14 m/s | 4 | 30 |
| Doble/Frenesí, tocar | 2 paralelos | 0,13333 s | 14 m/s | 10 + 5 | 112,5 |
| Doble/Frenesí, mantener | 2 paralelos | 0,13333 s | 14 m/s | 4 + 2 | 45 |
| Triple/Spread, tocar | 3, abanico ±14° | 0,4 s | 14 m/s | 8 cada uno | 60 |
| Spread, mantener | 5, abanico ±22°/±11°/0° | 0,4 s | 14 m/s | 4 cada uno | 50 |
| Triple/Spread + Frenesí, tocar | 4 | 0,4 s | 14 m/s | 8 + 8 + 8 + 4 | 70 |
| Spread + Frenesí, mantener | 6 | 0,4 s | 14 m/s | 4 × 5 + 2 | 55 |

La hipótesis de la cadencia se confirma: Spread descargaba tres veces menos seguido. **La velocidad de viaje no disminuía**: todos eran 14 m/s. Se sumaba una diferencia entre primer toque y fuego sostenido: cantidad y daño cambiaban dentro del mismo power-up, por dos caminos distintos de implementación.

Además, `DamageHurtbox3D.receive_hit()` aplicaba un mínimo de 10 de daño a tiros no Spread contra las cinco especies pequeñas configuradas en `SMALL_ENEMY_HP`. Así, el base sostenido de 4 producía realmente 10 por impacto en esas especies: hasta 75 DPS de cuerpo, y el doble hasta 150 si ambos conectaban. Los multiplicadores de implante se aplican después. Las cifras de 30/45 de Tanda 4a eran nominales y no describían esa excepción. Los límites de daño e invulnerabilidad de jefes también pueden reducir el DPS efectivo.

## Resultado y constantes

Todos los modos usan el mismo camino `fire()` para toque y fuego sostenido, sin rondas pendientes al soltar. No se incorporó otra arma ni otro pickup.

| Estado actual | Proyectiles / daño por descarga | Intervalo | Velocidad | DPS nominal | Sobre Base nuevo |
|---|---|---:|---:|---:|---:|
| Base | 1: 3 | 1/12 s = 0,08333 s | 14 m/s | 36 | — |
| Doble/Frenesí | 2: 3 + 1 | 0,08333 s | 14 m/s | 48 | +33,3 % |
| Triple/Spread | 3: centro 3, laterales 1 + 1, ±14° | 0,08333 s | 14 m/s | 60 | +66,7 % |
| Triple/Spread + Frenesí | 4: 3 + 1 + 1 + 1 | 0,08333 s | 14 m/s | 72 | +100 % |

La granularidad entera del daño aproxima las propuestas de +30/+60 %. El triple es el power-up ofensivo más fuerte por descarga; la combinación con Frenesí conserva el beneficio adicional existente. Ninguno reduce cadencia ni velocidad. Mantener Spread conserva el mismo triple del toque, eliminando el cambio a cinco perdigones lentos. Contra un blanco que solo recibe el centro, triple hace 36 DPS, igual al base; 60 supone los tres impactos. No se añadió penetración ni seguimiento.

`scripts/game/bee_shooting_settings.gd` concentra `WEAPON_MODES` (intervalo, velocidad y daños), `FIRE_INTERVAL`, `SPREAD_FIRE_INTERVAL`, `SPREAD_ANGLE` y `DOUBLE_OFFSET`. Los exports históricos de ráfaga/ratios se conservan por compatibilidad de escenas, pero ya no ajustan el arma principal.

Base sostenido nominal: **30 → 36 DPS (+20 %)** y 7,5 → 12 tiros/s, daño 4 → 3. Spread sostenido nominal: 50 → 60. Los proyectiles creados por el arma declaran `configured_weapon_damage` y respetan el perfil en el receptor de daño, evitando que el mínimo histórico de 10 anule el balance. No se modificaron vidas, daños de ataques enemigos, multiplicadores de implante, límites de jefes o hitboxes. Los proyectiles antiguos instanciados directamente sin perfil conservan su contrato anterior.

**Consecuencia real en enemigos pequeños:** la mejora del 20 % corresponde al DPS nominal base; no es un aumento del 20 % contra la excepción antigua del mínimo de 10. Allí el daño efectivo por impacto baja para que mande el perfil nuevo.

## Tiempo para liberar

Mosca común real (`FlyCommon`), Normal, 10 HP, cuerpo sin multiplicador, todos los tiros acertados:

- Antes, el primer toque de 10 y el mínimo histórico bastaban para un impacto: tiempo de viaje únicamente.
- Ahora, cuatro impactos de 3: 0,25 s desde el primer impacto hasta el último, más viaje. A 5 m y 14 m/s: aproximadamente **0,36 → 0,61 s** desde disparar. Con implante 2×: dos impactos, aproximadamente 0,44 s. No cambia la vida de la mosca.
- Comparando solo los daños nominales sostenidos (sin primer toque fuerte ni mínimo histórico), 10 HP necesitaban tres impactos de 4 separados por 0,13333 s: 0,2667 s entre primero y último. Ahora son cuatro de 3 cada 0,08333 s: 0,25 s. Para salud grande, HP/30 → HP/36 reduce el tiempo ideal alrededor de 16,7 %, antes de redondeos y límites de jefes.

## Presentación

Se reutilizan sonido base/Spread, destello y retroceso del blaster existentes. Destello de 0,055 s y escala 1,2; en desarrollo sigue la boca visible del modelo, sin mover el origen físico del proyectil. Plasma dorado alargado ×1,65 sobre el eje de viaje, emisión 3 y estela de 0,18 s / 14 partículas. Solo mallas y materiales de Bee: no se tocaron disparos enemigos ni se añadieron assets. Chispa `bee_spark` existente, escala 0,18, añadida al impacto válido; cuerpo neutral conserva su puff sin chispa dañina ni sonido de impacto.

`AIM_ASSIST_TARGET_MARKER = true`: aro dorado pequeño de radio 3 px, opacidad 0,65, desplazado 16 px sobre el punto elegido, visible también con F4 apagado. Desaparece sin blanco válido, en pausa/muerte/final y para objetivos invulnerables/fuera de pantalla. F4 conserva cono y línea completos. Las constantes de longitud/emisión/estela, destello/chispa y marca están junto a los perfiles.

## Pruebas y revisión

Ocho pruebas dirigidas pasaron: `validate_bee_tanda4c_weapons`, `validate_bee_tanda4a_fire_aim`, `validate_bee_lote14_controls_v01`, `validate_bee_weapons_powerups_v01`, `validate_bee_free_aim_v01`, `validate_bee_lote15_input_v01`, `validate_toon_projectiles_v01`, `validate_bee_live_readability`. No se corrió la suite completa ni se impuso timeout externo. Se actualizaron expectativas antiguas de 7,5 Hz/daños y se aisló el proyectil central del fixture de impacto; se repitieron solo las pruebas afectadas. Algunos tests conservan avisos de recursos al cerrar Godot; no hubo errores de script/aserciones/llamadas diferidas en sus logs finales.

La prueba nueva comprueba los cuatro estados reales, daño por descarga y DPS, 25 descargas (una inmediata + 24) en dos segundos, corte al soltar, expiración, hitbox de 0,15 m intacta, HP de Bee intacta, daño real de 3 pese al mínimo histórico, una FlyCommon creada por la fábrica del nivel con 10 HP y liberación al cuarto impacto de cuerpo, plasma/estela, chispa sin daño duplicado y marca con F4 apagado. Capturas de revisión con GPU en `dev/tanda4c_mode_0.png`, `_1.png`, `_2.png`, sin commitearlas.

## Qué probar en Godot

- Base: mantener X/clic/RT y soltar; comparar ritmo, precisión y cuatro impactos de cuerpo para una mosca Normal.
- Doble: conseguir Frenesí por combo; comprobar dos tiros paralelos, ritmo igual al base y que vuelva a base al terminar.
- Triple/Spread: recoger Spread, tocar y mantener; siempre tres tiros, sin pausa de 0,4 s ni cambio de velocidad. Comparar blancos cercanos que reciben varios proyectiles y lejanos que reciben solo el central.
- Spread con Frenesí: cuatro tiros; al terminar cada temporizador debe quedar el estado correcto. Triple y Spread son el mismo power-up, no dos niveles distintos seleccionables.
- Repetir con mando y ratón, apuntando arriba/abajo y cambiando entre enemigos encimados; el aro pequeño marca el blanco elegido y F4 sigue mostrando el cono. Revisar destello, estela y chispa de día/noche, también con F8 apagado para distinguir el efecto permanente del comparador de desarrollo.
