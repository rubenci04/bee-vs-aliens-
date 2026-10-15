# T9 — Análisis de tercera persona para Cielo y Espacio

Fecha: 15/10/2026. Rama de esta entrega: `lote-16-titulo-intro`.
**Alcance: lectura y documento. No se implementa ningún modo, no se crea una rama de prototipo y no se modifica el Nivel 1 lateral.**

## Decisión recomendada

Evaluar primero un **shooter sobre riel con cámara trasera y fases de jefe en arena acotada**. Star Fox y Kid Icarus Uprising sirven como referencias de encuadre, avance y combate en profundidad, sin comprometer el proyecto a reproducir todos sus sistemas. Cielo es el candidato inicial; Espacio puede aprovechar el resultado después de validar identidad, puntería y rendimiento. El vuelo 3D libre queda como una decisión posterior.

La fantasía sigue siendo Bee diminuta contra una invasión gigantesca. La vista trasera debe mostrar alas, cuerpo y aguijón, y conservar referencias de escala: copas y estructuras lejanas en Cielo; piezas de nave, drones y estructuras enormes en Espacio. Cambiar flores por un vacío sin referencias haría perder parte del gancho aunque aumentara la libertad de movimiento.

Hay evidencia previa, no una validación del modo: [el experimento de cámara](CAMERA_FP_SPIKE_REPORT.md) encontró a Bee aproximadamente tres veces más chica, enemigos difíciles de leer a distancia y decoración construida para una única vista lateral. Su evaluación se basó en capturas y simulación, sin playtest de teclado. Las cantidades de scripts y tests que enumera son históricas; no deben usarse como inventario vigente. [ROADMAP_RAIL_SHOOTER.md](ROADMAP_RAIL_SHOOTER.md) ya propone explorar un tramo independiente. T9 concreta sus riesgos y una prueba acotada; no revoca la decisión de conservar el Nivel 1.

## 1. Reutilización real y partes que requieren adaptación

“Sin cambios” se refiere a reglas, valores y recursos estables. No implica que todo el script que hoy los contiene sea independiente del escenario. El código vigente es más preciso que los resúmenes antiguos de controles del informe maestro.

| Sistema actual / evidencia | Qué se conserva sin cambios de diseño | Trabajo necesario en un modo futuro |
|---|---|---|
| HUD: `scripts/bee_prototype/bee_weapons_hud.gd`, `scripts/ui/bee_hud_notices.gd`; [T1b](INFORME_TANDA_1B.md) | Vida, polen, armas, bombas, iconos por dispositivo, banner único, cola y contador de liberaciones. No se rediseña el HUD completo. | Conectar el controlador nuevo a sus datos/señales; reservar el centro para retículas y comprobar resoluciones. Los indicadores espaciales sí son nuevos. |
| Disparos y avisos: `bee_shot_palette.gd`, `bee_shot_styles.gd`, `bee_facet_shot_styles.gd`, `bee_common_attack_cue.gd`; [T3j](INFORME_TANDA_3J.md), [T3k](INFORME_TANDA_3K.md) | Disparo propio cálido; siluetas y colores particulares de cada familia hostil; señales locales en el emisor; marcas puntuales de impacto y carga del jefe. Color, forma y movimiento deben distinguir peligro, recompensa y liberación. | Reorientar efectos y medir tamaño aparente en profundidad. T3j retiró las líneas de los comunes: no recuperarlas como grandes corredores de pantalla. No suponer que todos los tiros enemigos son la misma esfera cian. |
| Implantes y liberación: `scripts/levels/bee_liberation.gd`, `scripts/vfx/bee_release_animation.gd`; [T4f](INFORME_TANDA_4F.md) | Fauna liberada viva, máquinas destruidas; implante vulnerable como objetivo útil; colores cálidos al liberarse, chispa breve, retirada de colisiones/objetivo y recompensa una sola vez. Conservar duración y topes de salidas/emisores de T4f. | Hacer visible el implante desde el frente/atrás según la especie. La salida actual usa `DEPARTURE = Vector3(-1.2, 0.8, -4.0)`: necesita dirección relativa al encuentro/cámara para no escapar hacia Bee o atravesar la arena. Mantener el fundido de cuerpo y contorno. |
| Combo, puntuación, Frenesí y polen: `scripts/levels/bee_level_01_juice.gd` | Reglas actuales: ventana de combo de 3 s, Frenesí cada x8; polen y cura guardada con sus valores vigentes. No sumar economía ni progresión. | Este orquestador tipa `BeeShmupStage`, `BeePlayer` y `BeeLevel01Controller`: no es un módulo intercambiable sin conexión adicional. Un adaptador futuro debe reproducir sus eventos sin instanciar el nivel lateral. Diseñar oleadas con oportunidades reales dentro de la ventana; no cambiar el combo para ocultar huecos del recorrido. |
| Aguijón: `bee_sting_dash.gd`, `bee_sting_settings.gd`; [T4b](INFORME_TANDA_4B.md) | Embestida física, contacto después de viajar, retroceso, invulnerabilidad y espera mutua con pirueta. Daño 30, alcance 2,08 m, avance 0,22 s, contacto 0,06 s y retroceso 0,10 s como baseline. T4b no agrega carga ni recarga: repetir al terminar la animación. | Sustituir selección cercana en 360° por blanco fijado válido y cercano en el modo nuevo; resolver vector, orientación y límites en 3D. El helper actual pone `to_target.z = 0` y `bee.position.z = 0`: no sirve intacto. Ver sección 3. |
| Daño: `scripts/components/health_component.gd`, `hitbox_3d.gd`, `hurtbox_3d.gd`; `scripts/game/bee_damage_trace.gd` | Contratos de salud, equipos, multiplicadores, invulnerabilidad, impacto válido y registro de daño aplicado solo en desarrollo. Mantener valores de referencia; T9 no balancea armas ni enemigos. | Reubicar/orientar hitboxes y hurtboxes y comprobar trayectorias rápidas. Los componentes ya son 3D; los volúmenes y emisores de muchos ataques fueron diseñados para un plano. |
| Pirueta e impacto local: `bee_player.gd`, `bee_local_hit_stop.gd`; T4f | Acción defensiva, ruptura de disparos compatibles, espera y feedback selectivo. Hit-stop local, sin congelar globalmente el juego. | Dirección de la maniobra en el marco de vuelo y sacudida relativa a cámara. Una red o volumen nuevo debe declarar si se puede romper/atravesar; no hereda esa propiedad por su aspecto. |

La ayuda de [T4a](INFORME_TANDA_4A.md) aporta filtros y prioridad a implantes, pero `bee_aim_assist.gd` aplana `delta.z` y `BeePlayer` proyecta el ratón al plano `z=0`. Se conservan intención y filtros; se rehace la geometría de apuntado. No se debe confundir ayuda de dirección inicial con homing: los disparos actuales no corrigen su trayectoria después de salir.

| Parte espacial que hay que rehacer | Motivo y alcance |
|---|---|
| Cámara y encuadre | Reemplazar el seguimiento lateral y sus límites por cámara trasera, horizonte estable, anticipación de curvas y control de oclusión. Cámara de arena con encuadre propio; nunca activar ese comportamiento en N1. |
| Movimiento y límites | `bee_player.gd` limita X/Y y fuerza Z=0. Crear control del modo sobre los ejes locales derecho/arriba, avance del recorrido y desplazamiento longitudinal corto para Aguijón. El movimiento físico debe comprobar el trayecto, no trasladar el cuerpo directamente con el riel. |
| Director de oleadas | `bee_level_01_controller.gd` y sus tablas dependen de X, alturas, bordes laterales, suelo y jefes concretos. Reutilizar la idea de eventos por distancia y presupuestos de amenazas; escribir encuentros por progreso del riel, profundidad y tiempo hasta contacto. No rotar toda la tabla del jardín 90°. |
| Orientación de enemigos y suelo | Entradas, frente del modelo, boca del arma, implantes y puntos débiles necesitan orientación coherente con el trayecto. En Cielo el suelo lejano es referencia visual; una plataforma de combate tiene normal y altura locales. En Espacio se conserva un “arriba” para jugar; no se añade ingravidez de seis grados de libertad. |
| Arenas de jefe | Diseñar fases, puntos débiles, volúmenes y encuadre para profundidad. Los jefes actuales tienen suelo, techo, esquinas y bandas laterales: reutilizar el modelo o las reglas de salud no convierte sus IA en jefes traseros. Un blanco grande sencillo basta para el prototipo. |
| Escala y composición de assets | Revisar siluetas frontales/traseras, grosor de hojas/flores, distancias, niebla y tamaño en píxeles. Acercar encuentros y componer antes de agrandar todo. Un ajuste visual no debe modificar accidentalmente colisiones o salud por tamaño. No rehacer modelos existentes. |
| Validación | Conservar las pruebas laterales y sumar pruebas específicas del modo en su futura rama. No cambiar las expectativas X/Y del jardín para que acepten otra cámara. |

## 2. Camino híbrido: riel y arena

Propuesta conceptual: `Path3D` con una `Curve3D` define la ruta; su hijo `PathFollow3D` aporta posición/orientación por distancia `s`. El progreso avanza con la velocidad de crucero; `loop=false` evita volver al inicio al finalizar. `PathFollow3D.progress` se mide en unidades del recorrido, de modo que los eventos pueden referenciar `s` y no X global. [Referencia oficial de PathFollow3D](https://docs.godotengine.org/en/stable/classes/class_pathfollow3d.html).

Usar ese marco para calcular posiciones deseadas del jugador y cámara; resolver el desplazamiento del `CharacterBody3D` por física. Bee se mueve a derecha/izquierda y arriba/abajo dentro de una ventana local, mientras el riel controla el avance. Mantener por separado el pequeño desplazamiento longitudinal temporal del Aguijón. La curva orienta el viaje, pero el alabeo de Bee es principalmente visual; no debe rotar el horizonte con cada input. Evitar bucles y giros bruscos en la primera prueba.

La cámara sigue un ancla estable del trayecto y acompaña parcialmente el desplazamiento de Bee. Mirar ligeramente por delante permite anunciar una curva u obstáculo antes de llegar. Ni el dash de 0,22 s ni el retroceso deben arrastrar toda la cámara y convertir un golpe en un latigazo.

Al llegar a la arena: detener el progreso y nuevas oleadas, completar/cancelar los ataques de transición explícitamente y mezclar posición/orientación de cámara sin cambiar los ejes de input de golpe. Primera arena: volumen limitado, cámara orientada al jefe y desplazamiento derecho/arriba; profundidad controlada para acercamiento/Aguijón. No es vuelo libre de 360°. Al finalizar, retornar al riel con la misma continuidad y estado de salud/armas/combo; no emitir liberación o recompensas dos veces.

| Aspecto | Riel + arena acotada | Vuelo 3D libre |
|---|---|---|
| Control y aprendizaje | Dos ejes principales, avance automático, cámara previsible. | Traslación, giro, velocidad y cámara deben coordinarse; decidir asistencia y límites del espacio. |
| Encuentros | Franja visible y profundidad conocidas; permite presupuestar amenazas y anticipación. | Ataques desde cualquier rumbo; requiere adquisición fuera de pantalla, retorno al combate y control de persecuciones. |
| Nivel y arte | Corredor compuesto y una arena pequeña. Hay que inspeccionar frente y espalda de assets visibles. | Contenido visible alrededor del jugador, reversos, orientación y referencias de navegación en un volumen mucho mayor. |
| Jefes | Encuadre y zonas seguras predecibles; puntos débiles controlados. | Órbita/persecución, cámara de múltiples ángulos y riesgo de quedarse detrás o salir del encuentro. |
| Rendimiento y pruebas | Profundidad visible y actores acotados. Riesgo medio de oclusión/lectura. | Más combinaciones de visibilidad, trayectorias y cámara. Riesgo alto de mareo, desorientación y coste de contenido. |
| Estimación de prototipo equivalente | **6–8 tandas**, con primera decisión tras 2. | **12–18 tandas** para una prueba comparable, sin un nivel completo; confianza menor. |

Son estimaciones de planificación, no horas medidas ni promesas. Una tanda significa una tarea pequeña con implementación, validación y revisión jugable; depende de cuánto cambien los acoplamientos encontrados. El vuelo libre no cuesta solo “desbloquear Z”: exige diseñar navegación, cámara, enemigos y límites para todos los rumbos. Solo reconsiderarlo si el híbrido resulta divertido y aparece una necesidad concreta que el riel no resuelve.

## 3. Puntería 3D y Aguijón

### Fijación suave desde la cámara

El cursor o stick define un rayo de cámara. Un **cono de adquisición alrededor de ese rayo**, con alcance limitado, recoge objetivos delante de la cámara, vivos, vulnerables y visibles. La prioridad combina cercanía angular a la intención, implante vulnerable y distancia; un blanco central debe pesar más que uno lateral cercano. Mantener el blanco con histéresis evita saltos entre enemigos encimados; apuntar fuera del cono lo suelta. No girar automáticamente la cámara para perseguirlo.

`ShapeCast3D` sirve para obtener candidatos en volumen, pero **no tiene un cono de adquisición incorporado**: barre una `Shape3D`. Usar una forma convexa que aproxime el cono con consulta de solapamiento (`target_position=Vector3.ZERO` y actualización inmediata cuando corresponda), o una forma amplia seguida de filtro angular/distancia. Activar consulta de `Area3D` para hurtboxes y limitar máscara/resultados. Deduplicar por enemigo. Un cast amplio puede saturarse: registrar ese caso y limitar actores. Consultar solo con la frecuencia necesaria y comprobar línea de visión aparte. [Referencia oficial de ShapeCast3D](https://docs.godotengine.org/en/stable/classes/class_shapecast3d.html).

La visibilidad debe comprobarse desde la cámara **y la boca del arma** al punto elegido: ver el implante no garantiza que el disparo no choque con una pared al salir. El cast selecciona candidatos, no da permiso para atravesar obstáculos. Descartar liberados, invulnerables, blancos detrás de Bee o fuera de alcance y objetivos que desaparecen. Conservar la intención manual y permitir disparar sin fijación.

### Doble retícula primero; homing solo como alternativa medida

Una retícula tenue indica la dirección solicitada a profundidad de referencia; otra pequeña marca el punto de convergencia real, sobre el blanco válido o la primera obstrucción. Si coinciden, se leen como una. El disparo sale desde la boca hacia ese punto: resuelve el paralaje y evita fingir que el centro de pantalla es siempre la trayectoria. No dibujar líneas largas Bee→blanco ni tapar implantes con corchetes enormes.

El baseline mantiene proyectiles de trayectoria fija con corrección inicial suave. Si el playtest muestra fallos por profundidad pese a una retícula clara, comparar **ligero homing** en una variante: giro máximo por segundo, duración y cono limitados, sin reacquirir otro enemigo ni doblar detrás de obstáculos. Perder blanco devuelve trayectoria balística. Probarlo separado de cambios de hitbox/daño; de otro modo no se puede saber qué resolvió la dificultad. El homing cambia daño efectivo y puede volver irrelevante el implante si se automatiza demasiado.

### Continuidad con T4b

Z solicita una embestida al objetivo fijado **solo si está dentro del alcance de Aguijón** y el trayecto cabe en el volumen jugable. La fijación del arma puede alcanzar más lejos; no habilita un dash de toda la pantalla. Sin blanco cercano válido, conservar el avance vacío de 1 m hacia la intención, sin daño.

Conservar la secuencia avance físico → contacto cercano → retroceso. La hitbox viaja con Bee y se activa al llegar, nunca sobre un blanco remoto. Calcular dirección y orientación completas en 3D, con separación final y comprobación de obstáculos; no perseguir indefinidamente a un objetivo móvil. Si se libera, desaparece o se bloquea el trayecto durante el avance, no aplicar un impacto remoto. Mantener invulnerabilidad temporal, restauración del estado anterior, ausencia de recarga nueva y espera mutua con pirueta. El hit-stop T4f ocurre por impacto realmente aplicado, no por fijar o fallar.

La maniobra usa un desplazamiento temporal respecto del riel y retorna suavemente a su ventana; no adelanta eventos del director ni atraviesa el borde de la arena. Si un objetivo queda muy cerca de una pared o límite, cancelar o acortar con física y aceptar el fallo; nunca forzar un acierto teletransportando a Bee.

## 4. Cámara y oclusión en Compatibility

Usar un ancla de seguimiento, un pivote estable, `SpringArm3D` y `Camera3D` como hija directa del brazo. La máscara del brazo consulta **solo paredes grandes, masas de roca y estructuras** que realmente bloquean la cámara. Excluir el cuerpo de Bee; enemigos, proyectiles, pickups y follaje pequeño no acortan el brazo. Ajustar margen/forma y suavizar la recuperación sin permitir penetración. [Referencia oficial de SpringArm3D](https://docs.godotengine.org/en/stable/classes/class_springarm3d.html).

No incluir cada tallo o pétalo: provocaría acercamientos y alejamientos continuos. Para **tallos, hojas y macetas decorativas que tapan a Bee**, detectar intersección con un corredor corto cámara→Bee y una zona de proximidad a la cámara. Desvanecer solo los objetos afectados, con entrada/salida gradual e histéresis; restaurarlos al despejarse. La mera cercanía de una planta que no tapa a Bee no debe borrar todo el jardín. Clasificar las macetas: una estructura maciza que actúa como pared pertenece al brazo; su borde o adorno oclusor puede pertenecer al fundido.

Dos alternativas a contrastar con GPU real: dither en shader de material con descarte gradual, que conserva mejor la lectura de profundidad, o alfa por distancia en materiales propios. Revisar ruido del dither, contornos y sombras; con alfa, revisar orden de transparencia y sobrecarga de píxeles superpuestos. El fundido debe cubrir todas las superficies y el pase de contorno del prop, sin cambiar recursos compartidos de otras instancias. Reutilizar la experiencia de T4f, sin aplicar su animación de liberación a decorados.

**Restricción del renderer:** `GeometryInstance3D.transparency` y los modos de fundido de rango de visibilidad dependen de Forward+ y no resuelven esto en Compatibility. Implementar la variante futura en el material/shader compatible y verificarla; no cambiar de renderer para obtener el efecto. [Referencia oficial de GeometryInstance3D](https://docs.godotengine.org/en/stable/classes/class_geometryinstance3d.html#class-geometryinstance3d-property-transparency).

La transparencia es solo visual: no elimina colisiones ni vuelve atravesable una maceta sólida. No desvanecer peligros activos o enemigos para despejar la cámara. Si una pared obliga al brazo a comprimir demasiado y Bee deja de leerse, corregir el corredor/arena. Mantener horizonte, FOV moderado y sacudida opcional de T4f; no añadir balanceo permanente ni cambios de FOV por cada disparo.

## 5. De patrones 2D a amenazas 3D legibles

No alcanza con sumar proyectiles en Z. Hay que conservar la intención de cada patrón —elegir altura, cruzar una abertura o gastar pirueta— y mostrar cuándo alcanzará el volumen de Bee. Un volumen nuevo requiere colisión propia, correspondencia visual y límite de impactos por pasada; no se obtiene rotando una banda plana invisible.

| Intención lateral | Traducción propuesta | Lectura y respuesta exigida |
|---|---|---|
| Abanico radial / presión desde un emisor | **Onda esférica segmentada** que se expande, con sector abierto y espesor finito. Empezar con pocas trayectorias o segmentos de colisión, no cientos de balas. | Pulso del emisor y crecimiento visible. Subir/bajar hacia la abertura o cruzar con pirueta si el ataque lo permite. Una esfera cerrada inevitable dentro del corredor sería injusta. |
| Banda / cortina frontal | **Anillo** que viaja hacia Bee, con hueco desplazado en horizontal y vertical. El peligro es el aro, no todo su interior. | Ver el hueco y su profundidad con anticipación; variar su altura obliga a usar vuelo vertical. El margen libre incluye el tamaño real de Bee, no solo el centro de la retícula. |
| Láser o banda rasante | **Barrido horizontal** a altura definida, con grosor vertical/profundidad limitada y dirección anunciada. | Subir o bajar para evitarlo, o atravesarlo con la invulnerabilidad de pirueta si es compatible. No usar una pared de altura completa que elimine esa decisión. El aviso local y el frente activo deben distinguirse. |
| Abanico dirigido / red | **Red en cono**, una malla de proyectiles o filamentos con huecos reales; dirección fijada tras la preparación. | Leer el eje desde el emisor y los huecos al acercarse. Salir vertical/lateralmente o romper filamentos compatibles con pirueta. Una malla decorativa no puede prometer huecos que su collider macizo bloquea. |

La pirueta aporta cruce breve de peligro y ruptura de disparos compatibles; el vuelo vertical permite esquivar sin gastar esa ventana. Ambos deben tener oportunidades útiles. La secuencia de prueba alterna hueco alto/bajo, barrido medio y red dirigida; no exige pirueta en todos los ataques ni encadena patrones antes de que termine su espera.

Para cada patrón propuesto configurar aviso, alcance, velocidad relativa al avance, espesor, hueco, frecuencia, daño y cupo simultáneo. Medir **tiempo hasta contacto** con Bee en movimiento: la distancia por sí sola no garantiza reacción. El hueco debe admitir diámetro de la hurtbox más margen; el aviso debe superar reacción prevista más tiempo de llegar al hueco desde las posiciones permitidas. No generar ataques detrás de cámara ni superponer volúmenes sin una ruta segura o una defensa disponible.

Conservar señales locales de T3j y jerarquía T3k, adaptando orientación y tamaño aparente; no llenar el cielo con bandas de aviso. Separar ayuda de apuntado, liberación y peligro por forma/movimiento además del color. Topar proyectiles y actores antes de aumentar densidad. Validar cada patrón solo y luego combinaciones; un bot inmóvil mide presión, pero no certifica lectura ni diversión humana.

## 6. Prototipo mínimo futuro y decisión “va / no va”

**Rama propuesta, todavía no creada:** `codex/t9-prototipo-riel-3d`, desde una revisión que conserve los assets necesarios. Escena de laboratorio propuesta: `dev/third_person_rail/third_person_rail.tscn`, abierta con F6, sin enlace desde el título ni desde N1. No usar esta entrega documental como autorización para implementarla.

Alcance jugable: **60–90 s de riel y 30–45 s de arena**. Un tramo recto, una curva amplia y una variación de altura; un espacio abierto y otro con hojas/tallo/maceta y una pared grande para contrastar las dos soluciones de oclusión. Dos tipos de blanco con modelos disponibles, uno con implante liberable y otro tecnológico, más un blanco grande de jefe con una ventana vulnerable. Son comportamientos mínimos de laboratorio, no integración de todas las IA actuales ni un jefe de producción.

Incluir movimiento local, pirueta, Base, Aguijón 3D, daño, HUD y eventos de combo/liberación conectados con las reglas existentes. Spread/bomba conservan su estado y presentación al conectar el HUD; su comportamiento espacial completo queda para una tanda posterior si no es necesario para decidir. Probar tres patrones: anillo, barrido y red; la onda esférica queda como extensión, sin bloquear el mínimo. Teclado/ratón y mando con los mapeos actuales; doble retícula y ayuda inicial primero, homing solo si aparece el problema descrito.

Excluir: campaña, niveles completos de Cielo/Espacio, navegación libre, nuevos modelos, importaciones externas, casco espacial, cambios de N1 y refactor general de sus controladores. Si luego se requiere arte, pedirlo con [ASSET_REQUEST_TEMPLATE.md](art/ASSET_REQUEST_TEMPLATE.md), conservar `.blend` y exportar GLB; [ROADMAP_BEE_ESPACIO.md](ROADMAP_BEE_ESPACIO.md) sigue siendo futuro.

| Tanda futura | Entrega y puerta de revisión |
|---|---|
| P1 | Riel, movimiento físico, límites y cámara trasera con silueta legible. Revisar control/horizonte antes de introducir combate. |
| P2 | Fijación, doble retícula, Base y Aguijón con contacto real. Primera decisión: si apuntar exige pelear con cámara/paralaje o Bee deja de reconocerse, detener o revisar antes de seguir. |
| P3 | Dos emisores, anillo/barrido/red, daño y pirueta; conexión de implante, liberación, HUD y combo. Comprobar reutilización real sin cargar N1. |
| P4 | Arena mínima y transición riel→arena→salida; sin reescribir Robot ni Tarántula. |
| P5 | Paredes/SpringArm y oclusores/fundido; inspección de assets y perfil de Compatibility con carga acotada. |
| P6 | Pruebas de integración, playtest comparativo, medición y dictamen. |
| Reserva P7–P8 | Una corrección acotada de control/legibilidad y repetición dirigida, o variante de homing si está justificada. No añadir contenido para mejorar artificialmente la impresión. |

**Coste total previsto: 6 tandas base + hasta 2 de reserva**, incluidas pruebas y revisión; no equivale al coste de producir un nivel. Si conectar los sistemas exige una refactorización amplia, registrar el hallazgo y recortar/detener el prototipo antes de exceder esa reserva.

### Criterios propuestos, medibles y todavía sin resultados

Estos umbrales son objetivos de decisión, no mediciones realizadas en T9. Llevar sus valores a constantes/configuración de laboratorio cuando se autorice el prototipo; no fijarlos dispersos en scripts compartidos.

| Área | “Va” para una primera sección híbrida | “No va” / acción |
|---|---|---|
| Identidad y control | Al menos 3 personas, 2 intentos de familiarización y 3 medidos; al menos 2/3 completan riel+arena sin indicaciones continuas y reconocen Bee, implante y salida de fauna viva. Probar ambos dispositivos disponibles y registrar diferencias. | Bee se pierde, las ayudas dominan la imagen o hay desorientación repetida. Reencuadrar una vez; no compensar con más contenido. |
| Puntería | En una serie fija de 20 blancos por intento, al menos 80 % de aciertos con Base para 2/3 participantes; registrar oportunidades, tiros y blancos, sin contar homing y ayuda inicial como la misma variante. Fijación estable y liberación manual previsible. | Fallos de profundidad dominantes, saltos de blanco o daño a través de paredes. Revisar retículas/selección; homing limitado solo como comparación posterior. |
| Aguijón | Pruebas verifican alcance, blanco fuera del plano, pared, límite, objetivo perdido, avance vacío y espera con pirueta. Cero daño remoto o atravesamiento; humanos entienden cuándo está al alcance. | Necesita teletransportar, aumentar mucho alcance o arrastrar la cámara para acertar: corregir el movimiento o suspender esa adaptación. |
| Defensa y patrones | Los tres patrones tienen escape desde posiciones válidas con la anticipación configurada. En secuencias que alternan altura, 2/3 participantes usan vuelo vertical y pirueta de forma útil tras familiarizarse. | Solo funciona quedarse en una esquina, o aparecen golpes inevitables por volumen/visibilidad/recarga. Reducir simultaneidad antes de subir asistencia. |
| Cámara y oclusión | Cero penetraciones en la secuencia de pared; ninguna ocultación continua de Bee superior a 0,25 s en la ruta de prueba con props. Sin bombeo repetido del brazo; registrar mareo por persona. | Si persiste el mareo o la ocultación tras una revisión de cámara/escenario, detener la propuesta para producción. |
| Rendimiento | Medir en GPU real, Compatibility, misma resolución/carga y hardware registrado: tras calentamiento, al menos 95 % de frames ≤16,7 ms en el recorrido de referencia; comparar con fundido apagado y registrar CPU/GPU, actores y partículas. | Headless o FPS medios solos no aprueban. Si la carga mínima no sostiene el objetivo tras acotar transparencia/actores, no escalar al nivel completo. |
| Integridad y coste | Ningún archivo funcional de N1 alterado; contratos de daño/implante/recompensa conservados; pruebas nuevas pertinentes y regresión lateral verificadas. Resultado dentro de 6–8 tandas. | Si requiere rediseñar el jardín o una refactorización general, detener y documentar el coste antes de continuar. |

La aprobación humana final pertenece al desarrollador. Un “va” autoriza proponer una primera sección corta de Cielo; **no aprueba automáticamente vuelo libre, campaña ni Espacio**. Un “no va” conserva el lateral y el informe del experimento; no obliga a borrar assets ni a seguir programando hasta justificar el esfuerzo.

## Fuentes y verificación de esta entrega

Revisión local de `CLAUDE.md`, [INFORME_MAESTRO.md](INFORME_MAESTRO.md), [INFORME_LOTE_16.md](INFORME_LOTE_16.md), T1b, T3j, T3k, T4a, T4b, T4f, [T6a](INFORME_TANDA_6A.md), [T7a](INFORME_TANDA_7A.md), los roadmaps y el experimento citados; contraste con los scripts indicados. Las API se contrastaron con documentación oficial estable de Godot enlazada junto a cada propuesta; su comportamiento deberá comprobarse en el Godot 4.7.2 Compatibility del proyecto durante el prototipo.

T9 entrega únicamente este archivo Markdown. No hay escena nueva que ejecutar, cambios de gameplay ni resultados de un prototipo 3D. Comprobación documental dirigida: seis apartados presentes, enlaces locales existentes y diff limitado a este archivo, sin errores de espacios. Los umbrales de playtest, rendimiento y coste anteriores permanecen sin medir.

Validación del repositorio: una pasada headless con Godot 4.7.2 por las **131 validaciones existentes: 86 aprobadas y 45 fallidas**. Un `SCRIPT ERROR` cuenta como fallo aunque la salida sea 0. Nueve procesos de prueba se cerraron después de errores de script que dejaban el motor abierto; se incluyen entre los fallidos, no se aprobaron ni se repitieron. Pasaron T1b, T3g–T3k, T4a, T4b, T4c, T4d–T4f y T6a. Los fallos incluyen expectativas anteriores de armas/Aguijón/HitFlash, accesos a escenarios nulos y pruebas de jefes; no se repararon scripts ni fixtures por el alcance exclusivamente documental.

Resumen y salidas locales no versionadas: `dev/t9_suite_result.log`, `dev/t9_log_*.log` y `dev/t9_err_*.log`. El sandbox también impidió escribir el log automático `user://logs/godot.log`; las salidas se capturaron en los archivos anteriores. Este resultado no permite declarar verde el repositorio y no constituye una prueba del modo propuesto.
