# Tanda V — golpes con peso y Enjambre libre

- Base: `tanda-u-bee-siente` (`e7b9622`). Rama: `tanda-v-enjambre`. Es la «U» del doc del Plan 2: la T nueva corrió las letras una.
- **No cambió la vida ni el daño por golpe de ningún jefe.**

## Parte 1, peso (`bee_impact_settings.gd`, interruptor `IMPACT_ENABLED`)
- Reusa el congelado local, la sacudida y el juice que ya existían, desde un solo lugar: `scripts/vfx/bee_impact.gd`.
- A. Liberar congela un instante a Bee, al liberado y a las balas cercanas, y suelta un estallido dorado.
  - Un enemigo común congela 40 ms.
  - Uno grande (escarabajo o araña) congela 70 ms y suma una sacudida de 0,04.
- B. El puñetazo o el aguijón que conecta congela 60 ms y acerca la cámara un 3 % durante 0,15 s. Es solo el FOV: los límites de vuelo no cambian.
- C. Bomba:
  - Al explotar hay un destello blanco-dorado de 0,12 s, una sacudida de 0,08, un aro que crece hasta el radio real y Bee pone cara contenta.
  - Cada zona de combate arranca con al menos 2 bombas, y el HUD hace latir las bombas 1 s.
- D. Nunca hay dos sacudidas grandes en menos de 0,25 s. Se respeta la opción de temblor del título.

## Parte 2, Enjambre libre (`bee_free_swarm.gd`, `bee_free_swarm_settings.gd`, interruptor `FREE_SWARM_ENABLED`)
- Cada insecto liberado suma 1 a la barra ENJAMBRE, que está en el HUD debajo de LIBERADOS.
- Con 25, la tecla **E** (en mando, la **cruceta arriba**) llama 6 insectos liberados: moscas y mariquitas con su color natural, sin implante.
  - Orbitan a Bee durante 6 s.
  - Cada uno dispara una aguja dorada de 2 de daño cada 0,6 s al enemigo más cercano en pantalla.
  - Mientras están afuera, la barra no carga.
- Contra jefes hacen la mitad (2 → 1) y nunca apuntan a un jefe durante su entrada.
- Es el séptimo paso del entrenamiento de controles y aparece en la leyenda.
- Medición contra la tarántula (`dev/tanda_v/measure_swarm_boss.gd`): una salida de 6 s le saca 18 de sus 1200 (1,5 %). Aun con tres salidas por pelea queda debajo del 5 %, lejos del tope del 15 %.
- Hallazgo: el bot experto de `validate_bee_tarantula_boss_v01` ya no termina la pelea, y no es por esta tanda: en la corrida de la Tanda R ya daba «inf». Se queda trabado en las fases 2 y 3 (110 s cada una).

## Pruebas y cómo probar
- Test nuevo: `validate_bee_tanda_v`. Cubre los congelados, el zoom, el destello y la onda de la bomba, las bombas al entrar a zona, el tope de sacudidas, la carga, salida, duración y disparos del enjambre, y el daño a la mitad y la entrada protegida de la tarántula.
- Se actualizaron 2 suites porque el entrenamiento pasó de 6 a 7 pasos: `tanda_k` y `tanda_k_training`.
- Núcleo: 152/152 sin `SCRIPT ERROR`.
  - 149 pasaron en la corrida completa; las 2 del entrenamiento, después de su ajuste.
  - `validate_bee_visual` falló una vez con la PC cargada (mide el aleteo en solo 3 cuadros) y pasó 3 de 3 sola. La anoto como frágil.
- Cómo probar: Godot, F5, Jugar.
  - Liberá enemigos: cada uno da un golpecito de pausa y la barra ENJAMBRE sube.
  - Al llegar a 25, apretá E (o la cruceta arriba): aparecen 6 bichitos alrededor de Bee que disparan solos durante 6 s.
  - Tirá una bomba (C) para ver el destello y el aro.
  - Al entrar a una zona de combate, las bombas del HUD laten.
