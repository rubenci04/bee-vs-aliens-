# Vida por tamaño — auditoría T6a, ANTES de editar

Rama `lote-16-titulo-intro`, partida Normal. Inventario instanciado con la fábrica real y Godot headless antes del cambio (`dev/t6a_before.json`, no publicado). Se separa el elenco del nivel vigente de familias reservadas/legadas. Jefes y minijefes quedan excluidos; el Walker regular legado figura solo como referencia, no el Robot minijefe.

**Medida fija de tamaño:** longitud longitudinal del modelo/cuerpo, no alas ni altura de avisos. Bee v02 mide 1,1667 m en su eje Z a escala de arte 1; los animales orientados a X se miden en X. El comparador visual de desarrollo ×1,40 se descuenta: no debe cambiar la clase de vida ni la hitbox. Se conserva además el alto de su modelo para comparar gusanos bajos y largos. No se modifica ningún tamaño. Para tecnología legada, medidas de VisualRoot aproximadas pueden incluir antenas/cañones; no se usan para alterar esta tanda.

**Tiempos calculados, impactos perfectos al cuerpo:** Base T4c = 3 cada 1/12 s, 36 DPS. Spread = 3+1+1 cada 1/12 s, 60 DPS si llegan los tres; solo el centro = 36 DPS. T = (ceil(HP/daño por descarga)−1)/12, desde primer impacto hasta liberación; no incluye viaje, entrada o errores de puntería. HP/DPS es la aproximación continua y añade una descarga de diferencia. Implante 2× reduce los tiempos; no se balancea suponiendo que siempre se acierta al punto débil.

## Elenco común vigente

| Nombre real / nombre | Largo / Bee | Alto modelo (m) | Vida ruta (escolta hard) | Velocidad m/s | Multiplicador / armadura | Invulnerabilidad o entrada | Regeneración / esquiva | T Base / Spread (s), antes |
|---|---:|---:|---:|---|---|---|---|---|
| `FlyCommon` / Mosca común | 0.84 | 0.589 | 10 (10) | 3,6 vuelo / 12 embestida | 1× cuerpo; 2× implante; sin armadura | No durante combate | No regenera ni esquiva reactiva | 0.250 / 0.083 |
| `FlyGreen` / Mosca verde | 0.94 | 0.589 | 20 (20) | 5,0 | 1× cuerpo; 2× implante; sin armadura | No durante combate | No regenera ni esquiva reactiva; zigzag | 0.500 / 0.250 |
| `FlyCloud` / Nube de moscas | 1.96 | 1.595 | 10 (10) | 3,4 | 1× nube completa; sin punto débil | No durante combate | No regenera ni esquiva reactiva | 0.250 / 0.083 |
| `Wasp` / Avispa | 1.08 | 1.078 | 20 (20) | 2,6 acecho / 10,5 picada | 1× cuerpo; 2× línea del implante | No durante combate | No regenera ni esquiva reactiva | 0.500 / 0.250 |
| `Ant` / Hormiga | 1.11 | 0.503 | 20 (20) | 2,6 | 1× cuerpo; 2× implante; sin armadura | Entrada 0,7+0,4 s: inactiva, sale visible | No regenera ni esquiva reactiva | 0.500 / 0.250 |
| `Ladybird` / Mariquita | 0.91 | 0.600 | 97 (81) | 2,2 | 1× cuerpo; 2× implante; sin armadura | No durante combate | No regenera ni esquiva reactiva; pasada curva de 1,5 s | 2.667 / 1.583 |
| `WormA` / Gusano rosa | 2.19 | 0.315 | 97 (81) | 0,12 reptado T4d | 1× cuerpo; 2× implante; sin armadura | Enterrado hasta visible; salida 0,45 s; luego continuo | No regenera ni esquiva reactiva | 2.667 / 1.583 |
| `WormB` / Gusano de compost | 1.67 | 0.475 | 86 (72) | 0,12 reptado T4d | 1× cuerpo; 2× implante; sin armadura | Enterrado hasta visible; salida 0,45 s; luego continuo | No regenera ni esquiva reactiva | 2.333 / 1.417 |
| `StagBeetle` / Escarabajo ciervo | 1.52 | 0.606 | 144 (120) | 1,4 | 1× cuerpo; 2× implante; sin armadura | No durante combate | No regenera ni esquiva reactiva | 3.917 / 2.333 |
| `Snail` / Caracol | 1.31 | 0.989 | 144 (120) | 0,7 | 1× cuerpo; 2× implante; sin armadura | No durante combate | No regenera ni esquiva reactiva | 3.917 / 2.333 |
| `Spider` / Araña colgante | 1.41 | 1.465 | 106 (88) | 3,2 reposición | 1× cuerpo; 2× implante; sin armadura | Entrada desde arriba; luego continuo | No regenera ni esquiva reactiva | 2.917 / 1.750 |
| `MushroomCannon` / Hongo cañón | 1.30 | 1.736 | 70 (70) | 0,0 | 1× cuerpo; 2× implante; sin armadura | No durante combate | No regenera ni esquiva reactiva | 1.917 / 1.083 |

## Por qué la mariquita parece no morir

- Vida real 97 HP: 70 base → round(70×1,15)=81 → round(81×1,2)=97. Escoltas hard no usan el extra final: 81. Mosca/avispa usan la excepción de 10/20. Body-perfect Base necesita **33 impactos / 2,667 s** para la mariquita; mosca cuatro / 0,25 s, avispa siete / 0,5 s. Solo implante perfecto: 17 impactos / 1,333 s para la mariquita.
- `asset_fauna.gd::_build()` construye BodyShield como una caja del cuerpo completo que sí hace 1× de daño a la misma HealthComponent; no es un escudo neutral. Su caja mide 1,062×0,600×1 m. El implante es una esfera con radio ≥0,22 m; la bala T4c tiene radio 0,15 m. Las áreas de la mariquita **no son más chicas que la bala**.
- No hay `limit_hull_damage`, umbral mínimo, regeneración, reducción de daño, invulnerabilidad al aparecer ni esquiva reactiva en Ladybird. ENTER no apaga sus áreas. El rótulo `armored` de caracol/escarabajo es dato histórico sin receptor que reduzca el daño. No hay una defensa invisible que quitar.
- La pasada `sweep` dura 1,5 s y baja 0,9 m con sin(t×PI); el apuntado va a la posición actual del cuerpo, sin anticipar dónde estará al llegar el tiro. A 5 m la bala tarda 0,357 s: un tiro visualmente alineado al salir puede pasar por la posición anterior y fallar. Esto aumenta el tiempo real; la magnitud depende del jugador y no se presenta como medida de una grabación. No se alteran puntería ni movimiento para corregir la vida.
- Los gusanos ya son los de T4d: no tienen ventanas periódicas enterrados tras emerger, salto ni láser; repta 0,12 m/s. El dato KINDS.speed de WormB (1,8) pertenece al comportamiento antiguo y no es su velocidad vigente.

## Familias reservadas y legadas, solo inventario

No se agregan al nivel ni se cambian sus mecánicas. Tamaños aproximados; vida resultante de la fábrica actual, no de una futura fase. Cuerpo 1×, implante 2× si tiene áreas de fauna; no regeneración ni esquiva reactiva. Sin invulnerabilidad periódica, salvo tortuga rodando (implante se oculta). Bosses UFO/Rana/Tarántula y Robot minijefe no están en esta tabla.

| Familia | Largo relativo / alto (m) | Vida | Velocidad m/s | Multiplicadores / protección | T Base / Spread (s), antes |
|---|---|---:|---|---|---|
| `Probe` | 1.04 / 0.650 | 70 | 3 avance / 1,2 reposición | 1×, sin armadura | 1.917 / 1.083 |
| `EyeDrone` | 0.90 / 1.045 | 50 | 2,2 aproximación; retrocede al 35 % | 1×, sin armadura | 1.333 / 0.750 |
| `Turret` | 0.77 / 1.350 | 70 | 0 | 1×, sin armadura | 1.917 / 1.083 |
| `Speeder` | 1.98 / 0.880 | 40 | 4 entrada / 9,5 embestida | 1×, sin armadura | 1.083 / 0.583 |
| `OrganicAlien` | 1.39 / 1.362 | 100 | 3 acecho / 7,2 embestida | 1×, sin armadura | 2.750 / 1.583 |
| `Walker` | 2.09 / 2.539 | 100 | 2,4 marcha | 1×, sin armadura | 2.750 / 1.583 |
| `Dragonfly` | 2.43 / 3.314 | 110 | 4,2 reposición | 1× cuerpo / 2× implante | 3.000 / 1.750 |
| `Swarm` | 0.45 / 0.514 | 10 | 3,4 | 1×, sin armadura | 0.250 / 0.083 |
| `Mosquito` | 0.71 / 0.432 | 36 | 7.0 | 1× cuerpo / 2× implante | 0.917 / 0.583 |
| `WaveDragonfly` | 2.02 / 0.833 | 64 | 6.0 | 1× cuerpo / 2× implante | 1.750 / 1.000 |
| `Moth` | 1.42 / 1.420 | 70 | 2.4 | 1× cuerpo / 2× implante | 1.917 / 1.083 |
| `SeedCarrier` | 2.40 / 1.371 | 220 | 2.0 | 1×, sin armadura | 6.083 / 3.583 |
| `AlienFighter` | 1.61 / 0.645 | 70 | 4.5 | 1× cuerpo / 2× dispositivo | 1.917 / 1.083 |
| `Turtle` | 3.10 / 2.161 (modelo aparcado ×2) | 220 | 0,45 marcha / 7 rodar | Solo implante 1×; cuerpo sin área de daño; implante oculto durante rodar ≤4,5 s | 6.083 / 3.583 (impactos al implante) |

Fuentes: `bee_level_01_controller.gd::level_hp/_spawn`, `BeeGameSettings.SMALL_ENEMY_HP`, `asset_fauna.gd::KINDS/_build/_attack`, `bee_ground_worm.gd`, `bee_fauna_sizes.gd`, `hurtbox_3d.gd`, `bee_shooting_settings.gd`. Hongos decorativos destructibles no son enemigos: no están en esta tabla ni se cambia su vida. Nivel 2/3 y enemigos todavía ajenos al director del nivel 1 se conservan.
