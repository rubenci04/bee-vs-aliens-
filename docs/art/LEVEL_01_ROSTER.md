# Nivel 1 — Jardín de una casa: contrato de elenco

Fecha: 12 de octubre de 2026 (versión 2: la rana pasa al Nivel 2). Decidido por Rubén. Este documento manda sobre cualquier tabla de oleadas anterior.

## Concepto

Es donde empieza la aventura: el jardín de una casa, del día al atardecer. En el Nivel 1 hay SOLO animales, insectos y elementos de jardín. La invasión alien apenas se insinúa (implantes en los animales y un único robot caminante). Los OVNIs y el resto de la tecnología alien quedan para el final del juego, en el espacio.

## Elenco del Nivel 1

Los roles son propuestas de diseño; el estado de cada modelo lo confirma la auditoría contra el disco.

| Unidad | Rol propuesto | Notas |
|---|---|---|
| Mariquita | Aérea media. Abre el caparazón antes de embestir (ahí es vulnerable) | Ya existe |
| Mosca común | Enjambre débil de vuelo errático, embestida suave | Diseño nuevo, verificar |
| Mosca verde | Más rápida, zigzag, escupe gotas lentas apuntadas | Diseño nuevo, verificar |
| Nube de moscas | Unidad de grupo (15-25 moscas diminutas que se mueven como una nube). Llena espacio vacío; la bomba la limpia | Diseño nuevo, verificar |
| Avispa | Ágil, ráfaga de aguijones apuntados y picada con aviso | Ya existe |
| Hormiga | Terrestre, en columna; lanza piedritas en arco | Ya existe |
| Caracol | Terrestre, lento y resistente; baba o burbujas en arco | Ya existe |
| Gusano (tipo A) | Emerge del suelo con marca de aviso | Diseño nuevo, verificar |
| Gusano (tipo B) | Segundo tipo de gusano: otro patrón (por ejemplo, escupe o embiste a ras de suelo) | Diseño nuevo, verificar |
| Escarabajo ciervo | Tanque que embiste con aviso de ~0,8 s | Ya existe |
| Hongos de jardín (varios) | Objetos fijos y destructibles que sueltan polen. El hongo cañón es el único que dispara esporas | Verificar cuáles son de jardín |
| Araña colgante | Baja por un hilo visible, dispara telaraña en abanico y sube | Ya existe (la araña común) |
| Tortuga de jardín | Tanque terrestre lento, mucha vida | Ya existe |
| Robot caminante (único enemigo tecnológico) | Mini-jefe con escoltas de insectos. Ojo amarillo, cañón dorsal | Ya existe |
| Tarántula | Jefe final del nivel | Diseño nuevo, verificar |

## Arco propuesto del nivel (día → atardecer)

1. Césped y entrada (día, suave): moscas comunes, hormigas, mariquitas.
2. Macizo de flores: avispas, moscas verdes, nube de moscas, hongos de jardín.
3. Checkpoint 1, valle de respiro (propuesta): calma breve, ítems de curación y bomba, sin enemigos fuertes. Reemplaza el lugar que ocupaba la rana.
4. Huerta y tierra: gusanos, caracol, tortuga, escarabajo ciervo.
5. Sombra bajo las hojas (tarde): arañas colgantes, escarabajos, hormigas.
6. Checkpoint 2: el robot caminante con escoltas de avispas y moscas.
7. Atardecer: la tarántula, que se anuncia con telarañas.

## Sale del Nivel 1 (no se borra nada; se reubica)

| Asset | Destino |
|---|---|
| Rana (mini-jefe del Lote 10: modelo, escena y código) | Nivel 2 (Laguna). El código queda intacto, apagado en el Nivel 1 con una constante |
| OVNI / jefe UFO y su código | Nivel 7 (Espacio). El código queda intacto, apagado en el Nivel 1 con una constante |
| Organismo morado de un ojo | Nivel 7 |
| Sonda, dron ojo, speeder, torreta, caza alien, semillero alien | `shared/alien_tech` (reutilizables en niveles tardíos); la auditoría puede proponer otro destino |
| Mosquito, libélula | Nivel 2 (Laguna) |
| Polilla | Nivel 3 (Bosque) |
| Luciérnaga | Nivel 3 (Bosque) |
| Hongo de color | Nivel 3 (Bosque) |

## Estado en el Lote 13

- La **tortuga de jardín está aparcada**: no sale en el Nivel 1 hasta que Rubén genere un modelo nuevo (el hexagonal está fuera de estilo). Su comportamiento ya está listo.
- El nivel es **jardín puro** (sin pinos ni restos alien) y **denso**: sin valle de respiro; el tramo del checkpoint 1 es la entrada de los gusanos. Detalle en `docs/INFORME_LOTE_13.md`.

## Reglas del nivel

- Solo se usa el elenco de arriba. Todo lo demás vive en su propia carpeta de nivel.
- Mariposas decorativas e insectos de ambiente quedan permitidos si no atacan.
- Los animales llevan implante cian (se liberan). El robot caminante explota. El cian marca lo hostil; el ojo amarillo del robot se mantiene, pero el cañón y la telegrafía usan cian.
- Se mantienen los objetivos del Lote 11: máximo ~5 s sin amenaza en pantalla (el valle de respiro del checkpoint 1 es la única excepción, de hasta ~20 s), 7 enemigos simultáneos (10 en zonas), 5,5-7 min hasta el jefe.

## Decisiones

- **Luciérnagas:** reservadas para el Bosque. En el Nivel 1 se suman al desorden visual con los disparos dorados de Bee y con el polen; el Bosque las estrena con más fuerza.
- **Rana:** pasa al Nivel 2 (decidido el 12/10).
- **Tarántula:** jefe final con implante (se libera al final); sin exoesqueleto alien.
- **Pendiente:** Nivel 2 (Laguna), que Rubén detallará después; incluirá a la rana.
