# T4d — Gusanos de suelo, sin salto ni láser

Rama `lote-16-titulo-intro`. Alcance: comportamiento de WormA y WormB en el roster del nivel 1. Vida, valores de daño y colisiones existentes conservados. Sin assets, armas ni proyectiles nuevos.

## Auditoría previa

| Banda / enemigo | Escena y comportamiento anterior | Disparo anterior |
|---|---|---|
| GUSANO ROSA / WormA | `asset_fauna/worm_rose.tscn`, AssetFauna `worm_rose` con `WormBehavior`: emerge, se incorpora, láser, salto y entierro | Rayo cian, daño 4; erupción/contacto 5 |
| GUSANO DE COMPOST / WormB | `asset_fauna/worm_compost.tscn`, AssetFauna `worm_compost`: reptar/embestir alternado con escupitajo | Abanico de 3 gotas `mud`, amarillo ácido facetado decidido en T3d, daño 3; embestida 7 |
| ENTRADA DE GUSANOS · CARACOL / Snail | `asset_fauna/snail.tscn`, AssetFauna `spitter` con `lob` | Burbuja cian `bubble` en arco, daño 3 |

No había un tercer gusano distinto ni una variante tardía con plasma cian: rosa y compost reaparecen en las mismas escenas y con el mismo código. La tabla sitúa el debut de rosa en X=156 y el de compost en X=235; los caracoles aparecen desde X=185. La banda de zona «ENTRADA DE GUSANOS» podía hacer interpretar al caracol como otro gusano.

Se aclaró esta diferencia antes de cambiar ataques. **El desarrollador eligió reutilizar la gota amarilla de WormB**, en lugar de la burbuja del caracol o plasma genérico.

Reutilizable existente: `AssetFauna.PROJECTILE` (`scenes/projectiles/toon/alien_bolt.tscn`), `BeeEnemyPatterns.spawn_styled()` y `fan_directions()`, con estilo `mud` de `BeeShotStyles`/`BeeFacetShotStyles`. El escupitajo anterior de WormB ya usa esa fábrica en `_fire_fan_style()`; el adaptador nuevo usa exactamente la misma escena, estilo y velocidad configurada.

## Cambio

`bee_ground_worm.gd` adapta ambos gusanos **solo cuando el director del nivel 1 usa su roster**. Los modelos, ondulación de segmentos, vida y áreas originales se conservan. Las escenas de laboratorio y el código legado de WormBehavior quedan disponibles, pero el nivel 1 deja de ejecutar su salto, láser y erupción ofensiva. Compost deja de embestir y usa únicamente los patrones de disparo.

Se colocan enterrados en un punto visible del suelo, sin desplazamiento visible instantáneo: el cuerpo sale durante 0,45 s con el polvo `rock_break` existente. Después reptan a 0,12 m/s, sin movimiento vertical de la entidad. No se crean líneas, discos, elipses, aros ni domos de aviso. La anticipación es el pulso del cuerpo de T3j, durante 0,5 s.

Los patrones se alternan por gusano: abanico de tres hacia arriba, columna de tres, diagonal de tres. Las diagonales alternan izquierda/derecha. Un desfase de patrón inicial entre ejemplares evita que todos empiecen igual. Un grupo compartido permite **máximo dos gusanos preparando o lanzando una descarga**; los demás esperan, sin soltar disparos atrasados juntos. Las gotas que ya están en vuelo conservan su vida habitual; el límite se refiere a emisores atacando, no a proyectiles existentes.

## Parámetros finales

Todo en `scripts/levels/bee_ground_worm.gd`:

| Parámetro | Valor |
|---|---:|
| Cadencia de rosa respecto de referencia compost | 0,60 |
| Intervalo de descarga compost | 8,696 s, 0,115 descargas/s |
| Intervalo de descarga rosa | 14,493 s, 0,069 descargas/s |
| Proyectiles por descarga, ambos | 3 |
| Promedio de proyectiles/s, compost / rosa | 0,345 / 0,207 |
| Abanico | 3 direcciones, paso 16° alrededor de la vertical |
| Columna y diagonal | 3 gotas separadas por 0,22 s |
| Diagonal | 35° desde la vertical, signo alternado |
| Velocidad del proyectil | Configuración original WormB 4,2 m/s × escala roster 0,8 = 3,36 m/s |
| Daño por gota, rosa / compost | 4 / 3 |
| Valor original del ataque de cuerpo, rosa / compost | 5 / 7; permanece almacenado, sin salto/embestida que lo active |
| Aviso en el cuerpo | 0,5 s |
| Salida desde el suelo | 0,45 s desde profundidad visual 0,65 m + polvo |
| Primer reposo tras salir | 0,25 s |
| Reptar | 0,12 m/s |
| Emisores atacando a la vez | 2 |
| Reintento cuando ambos lugares están ocupados | 0,15 s |
| Punto de entrada enterrado | Cámara X+4 m, separación inicial 0,4 m entre variantes |

Referencia de cadencia: el compost anterior alternaba una embestida y un abanico. Con los reposos tardíos del nivel, su abanico aparecía cada `4×0,6×2,79 + 2×0,6 + 0,35 + 0,45 = 8,696 s`. Se conserva esa media para compost y se divide su frecuencia por 0,60 para rosa. Se descuenta la preparación y los intervalos internos de cada patrón del reposo posterior para que la columna/diagonal no cambien la cadencia nominal. Esperar un lugar libre, quedar fuera de pantalla o el límite global de proyectiles solo puede reducirla. La preparación visual propia queda en 0,5 s; no se modifica la duración de estancia/retirada del director.

Vida: se sigue llamando a `BeeLevel01Controller.level_hp()` y `BeeGameSettings.scaled_hp()` exactamente como antes. No se modificaron tablas de HP ni dificultad. El daño 4 del rosa reutiliza el valor del láser reemplazado; el 3 del compost viene de su `_shot_damage()` original. No se cambian tiros de Bee ni enemigos ajenos.

## Verificación

- Pasaron `validate_bee_t4d`, `validate_bee_t3j`, `validate_bee_asset_fauna_v01` y `validate_bee_lote13_combat_v01`. Solo pruebas relacionadas; sin suite completa.
- La nueva prueba simula 48 s con cuatro gusanos: registra 60 proyectiles, máximo dos emisores atacando, los tres patrones, movimiento Y fijo en el suelo, HP/daños y velocidad de proyectil intactos, ausencia de avisos geométricos y cero saltos/láseres. Liberarlos devuelve los lugares de ataque.
- Se actualizaron expectativas antiguas: T3j ya no espera que el gusano conserve su rayo activo; Lote13 ahora exige patrones ascendentes sin embestida y espera la descarga efectiva antes de evaluar la alternancia.
- `docs/gusanos_fase1.png`: cuatro capturas reales del nivel en X=156 — salida, abanico, columna y diagonal. Herramienta `tools/gusanos_fase1.gd`, con GPU/Compatibility a 1154×648, `--fixed-fps 60`. El scroll/director y Bee se detienen para encuadrar; los dos gusanos ejecutan su nuevo ciclo real y los proyectiles vuelan. No se fuerzan los patrones para las capturas. Render sin errores de consola/script. Headless conserva los avisos habituales de recursos al cerrar algunas pruebas; sin errores de script ni aserciones finales.

## Qué probar

Abrir el nivel 1 y revisar X≈156–183 (rosa), X≈235–259 (compost) y sus apariciones intermedias: salida visible con polvo, desplazamiento lento de suelo, solo gotas amarillas ascendentes, sin salto/láser/domo/elipse. Comparar el ritmo rosa con compost y comprobar que no preparen disparos más de dos a la vez. Las formas y colores son los mismos del compost que elegiste. Pendiente: validar con el jugador si estos intervalos resultan demasiado lentos; no se ajustó vida ni balance general.
