# Nivel 2 — «La Laguna» · documento de diseño (Tanda Y)

- Base: `tanda-x-ritmo-final` (`da2d8a0`). Rama: `tanda-y-diseno-nivel2`. Es la «X» del doc del Plan 2: la T nueva corrió las letras una.
- **Solo diseño: no hay código, escenas ni assets nuevos en esta tanda.**
- Junta lo que ya existe:
  - el concepto viejo (`BEE_FUTURE_LAKE_LEVEL_CONCEPT_01.md`);
  - el prototipo jugable de 90 s (botón «Laguna (prototipo - debug)» del título);
  - los modelos de `assets/models/levels/level_02_lake/`;
  - todo lo que el Nivel 1 aprendió en las tandas R a X.

## 1. La idea en una línea
Bee sigue la señal del implante hasta el estanque del fondo del jardín. Ahí los aliens controlan a la fauna de agua, y el agua misma es un peligro.

Es el mismo juego (plano X/Y, scroll lateral, liberar en vez de matar), con dos novedades:
- el **suelo es agua**: salpica, esconde cosas y lo que sale de abajo pega;
- un **movimiento firma nuevo** de Bee (sección 6).

## 2. Lo que ya existe (y se reusa)
| Qué | Dónde | Estado |
|---|---|---|
| Director de 90 s (5 especies, sapo como minijefe) | `scripts/levels/bee_level_02_controller.gd`, escena `bee_level_02_lake.tscn` | prototipo jugable |
| Sapo jefe (salto, ola, espera) | `scripts/levels/level_02_lake/lake_toad_boss.gd` | prototipo |
| Zapatero, ninfa, perca, libélula, mosquito (con implante) | `level_02_lake/enemies/controlled_*.glb` | en uso |
| Garza gigante, salamandra, tortuga, nube de mosquitos, cada uno con versión «liberado» | `level_02_lake/enemies/lvl02_enemy_*` | listos, sin usar |
| Sapo rococó + versión «liberado» | `level_02_lake/bosses/lvl02_boss_rococo_toad_v01*` | listo, sin usar |
| Totoras, nenúfares con flor, rama flotante, roca de orilla, olas, raíz sumergida, bote, boya | `level_02_lake/environment` y `props` | casi todo sin usar |
| Todo lo del Nivel 1 | caras, reacción al golpe, Enjambre, momentos, escenas, resultados | se reusa tal cual |

Lo único que falta de verdad es un **shader de agua** propio, compatible con GL Compatibility y con el estilo toon. Es un shader corto, sin plugins.

## 3. Estructura: 5 actos, unos 6 minutos (como el Nivel 1)
| Acto | Lugar | Qué aprende el jugador | Especie que debuta (sola 8 s) | Momento especial |
|---|---|---|---|---|
| 1 | **Orilla**: piedras, barro, juguetes | el agua salpica cuando algo cae | zapatero (patina y embiste por abajo) | una piedra cae al agua: anillo de gotas que suben, con hueco para pasar |
| 2 | **Juncal**: totoras altas | esquivar entre cobertura vertical | ninfa (sale del agua y escupe) y mosquito | un viento dobla las totoras: se abren y se cierran pasillos |
| 3 | **Espejo de agua**: nenúfares | la cobertura se mueve | perca (salta en arco) y libélula | **zona de combate 1**: nenúfares que giran como escudos |
| 4 | **El bote y la boya** | pelear contra algo grande que no se puede liberar entero | salamandra (trepa la boya) y tortuga (caparazón que rebota) | **minijefe: la garza gigante** (sección 4) |
| 5 | **Guarida del sapo**: raíces sumergidas | todo junto, con menos pausa | nube de mosquitos | **jefe: el sapo rococó** |

- Hay 3 zonas de combate, como en el Nivel 1 (actos 2, 3 y 5), de 25 s cada una, que es lo que dieron los bots de la Tanda X.
- Los potenciadores van antes de lo que conviene usarlos (regla de la Tanda T):
  - triple antes de la nube de mosquitos y de la zona de los nenúfares;
  - bomba antes de la garza;
  - una sola recarga antes del sapo.
- Arranca con la barra de bombas llena, y cada zona empieza con al menos 2 bombas.

## 4. Jefes
**Minijefe: la garza gigante** (asset listo).
- Es enorme: solo se le ven las patas y el pico, que entra desde arriba de la pantalla.
- Se mueve en tres tiempos:
  1. Pica: aviso con su sombra en el agua durante 0,8 s y una línea vertical.
  2. Barre el agua con el pico: ola baja, hay que volar alto.
  3. Levanta vuelo y deja caer peces aturdidos, que son liberables.
- El implante está en el cuello. Al romperlo, la garza se va volando con su color natural; se usa la versión «liberado».
- Duración objetivo: 35–45 s, como el robot. Tiene su escena corta con Bee mirando para arriba y su cartel.

**Jefe: el sapo rococó** (asset listo, reemplaza al sapo del prototipo).
- Cuatro fases, como la tarántula:
  1. Lengua: la boca se abre y una línea marca la dirección, que queda fija antes del golpe.
  2. Salto y salpicadura: anillo de gotas con un hueco.
  3. Mueve nenúfares con ondas: la cobertura cambia de lugar.
  4. Furia: llama mosquitos y combina las anteriores.
- La barra de vida es la del implante, no la del sapo. Al final el sapo se calma y se hunde feliz (versión «liberado»).
- Duración objetivo: 80–110 s. Igual que en el Nivel 1, la vida y el daño por golpe se fijan una vez y no se tocan después; el ritmo se ajusta con los tiempos.

## 5. El agua como peligro (la mecánica del nivel)
- Volar muy bajo (por debajo de ~1 m) sobre el agua no lastima, pero **frena un 25 %** y salpica. Así se lee que abajo no conviene estar, sin castigar de golpe.
- Lo que sale del agua (ninfas, percas, la lengua del sapo) siempre avisa con burbujas y un anillo en la superficie durante al menos 0,4 s.
- Los nenúfares son **cobertura móvil**: frenan los disparos enemigos y los de Bee, se pueden romper y vuelven a crecer.
- En este nivel el pasillo limpio de la Tanda S trata a las totoras como «decorado que tapa».

## 6. La pregunta del plan: ¿qué movimiento firma nuevo gana Bee?
En el Nivel 1 Bee ganó el **Enjambre libre** (ataque con ayuda). El del Nivel 2 tiene que ser de otro tipo y salir del agua. Tres opciones:

| Opción | Qué hace | A favor | En contra |
|---|---|---|---|
| **A. Zambullida** (recomendada) | Bee se tira al agua 0,6 s (invulnerable, solo una sombra), sale disparada para arriba y suelta un anillo de gotas doradas que lastima lo que tiene encima. Recarga 6 s. | Usa la identidad del nivel; es movimiento + ataque (el Enjambre es ataque con ayuda); responde a «lo que sale de abajo»; se aprende en 1 s. | Hay que cuidar que no sea una segunda pirueta: solo funciona cerca del agua (por debajo de ~2 m). |
| B. Burbuja de miel | Encierra a Bee en una burbuja que rebota disparos 3 s. | Fácil de entender. | Se parece al escudo del polen (Tanda O). |
| C. Corriente | Bee arrastra una estela que empuja a los enemigos chicos. | Original. | Difícil de leer en pantalla y de balancear. |

**Recomendación: A, la Zambullida.**
- Va en el mismo botón del mando (cruceta abajo) y en el teclado con la **F**.
- Se suma al entrenamiento de controles como paso 8, solo desde el Nivel 2.
- Interruptor `DIVE_ENABLED`. No le da daño extra a los jefes: contra ellos hace la mitad, como el Enjambre.

## 7. Clásico pero novedoso (lo que pediste en la Tanda T)
- **Clásico:**
  - tabla de oleadas fija y aprendible;
  - potenciadores antes de cada amenaza;
  - bombas llenas al empezar;
  - jefes con fases y avisos;
  - rango al final.
- **Novedoso:**
  - liberar en vez de matar, con el Enjambre;
  - el agua que esconde cosas y la Zambullida para usarla a favor;
  - cobertura que se mueve (los nenúfares);
  - escenas cortas con la cara de Bee.
- **Idea para probar, no para prometer** (`ROADMAP_RAIL_SHOOTER.md`): un tramo de 15 s en el acto 4 donde la cámara gira y Bee vuela *hacia el fondo* persiguiendo a la garza, al estilo Star Fox. Solo si un prototipo chico demuestra que se lee bien y no marea. Si no, se descarta sin tocar el resto.

## 8. Lo que hay que hacer, en tandas (una por chat, como hasta ahora)
| Tanda | Qué | Riesgo |
|---|---|---|
| L2-A | Shader de agua y escenario de los 5 actos con los assets existentes (sin enemigos nuevos) | medio: es el look del nivel |
| L2-B | Director del Nivel 2 (tabla de 5 actos, debuts, 3 zonas) con la fauna ya hecha | bajo |
| L2-C | Salamandra, tortuga y nube de mosquitos con sus versiones «liberado» | medio |
| L2-D | Garza gigante (minijefe) con bot de prueba | medio-alto |
| L2-E | Sapo rococó (jefe, 4 fases) con bot de prueba | alto |
| L2-F | Zambullida (movimiento firma) y su entrenamiento | medio |
| L2-G | Momentos, escenas, música y pantalla final del Nivel 2 | bajo |

Antes de L2-D hay que arreglar el bot experto de la tarántula: no termina la pelea desde antes de la Tanda R (ver `INFORME_TANDA_V.md`). Los jefes nuevos necesitan un bot que sí mida la pelea entera.

## 9. Decisiones que necesito de vos
1. ¿Te copa la **Zambullida** como movimiento firma del Nivel 2, o preferís la burbuja?
2. ¿El minijefe es la **garza** y el jefe el **sapo rococó**, o al revés?
3. ¿Probamos el **tramo hacia el fondo** (estilo Star Fox) o lo dejamos para más adelante?
4. ¿Hace falta **música propia** para la laguna? Hoy solo hay temas del Nivel 1.
