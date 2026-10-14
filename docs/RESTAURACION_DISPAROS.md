# Restauración de disparos y ataques enemigos

14/10/2026 · rama `lote-16-titulo-intro` · referencia visual: `8373f31^` (`d78e33d`).

Se restauraron las formas, colores, tamaños, transparencias, estelas y materiales anteriores a Tanda 3. La avispa vuelve a su aguja violeta y la mosca verde a su escupitajo verde flúor. Se quitaron los núcleos blancos adelantados y las nuevas envolventes negras de los ataques activos. El pequeño núcleo cian que ya existía antes de Tanda 3 se conserva.

Siguen los cambios de cielo/paleta diurna, hojas/pasto durante combate, contorno de Bee, avisos de suelo y aviso de regadera. La marca de agua sigue avisando **1 segundo** antes; la columna activa vuelve a su celeste translúcido anterior. El hilo de tarántula conserva su aviso mejorado y, al activarse, recupera seda blanca y ancho original. Los disparos de Bee conservan su tratamiento de niebla de Tanda 3.

**No cambiaron colisiones, daños, velocidades, gravedad, cadencias ni duración de ataques.** Los radios de colisión de los once estilos son idénticos a `8373f31`; los tamaños de la tabla son visuales, no hitboxes.

Comprobación de código: 19 funciones de movimiento, lanzamiento, colisiones y transición de agua coinciden con `8373f31` tras normalizar saltos de línea; los once radios y giros coinciden; seis archivos de ambiente/cielo/pasto/estilo de Bee permanecen intactos. Los cambios del diff restante se limitan a construcción de visuales, materiales y separación de avisos.

## Antes vs ahora

“Antes” significa el aspecto de `8373f31` que se acaba de retirar; “ahora” es el aspecto anterior a ese commit, restaurado. Tamaños en metros de mundo, con `BeeShotStyles.VISUAL_SCALE = 1,3`, antes de giro/oscilación. Las medidas aproximadas del cuerpo no incluyen estela ni halo, salvo donde se indica. Todos los estilos conservan el núcleo cian original.

| Enemigo / identificador real | Antes: Tanda 3 | Ahora: forma y color restaurados | Tamaño visual restaurado | Estela restaurada / colores a revisar |
|---|---|---|---|---|
| Avispa `Wasp` / `WaspEnemy` · `stinger` | Aguja magenta más gruesa, núcleo blanco y borde negro | Cápsula y punta violeta `(0,60; 0,20; 0,95)` | Largo total ~1,03; ancho de cápsula 0,182 | Violeta claro, 0,30 s. Mirar contra sombras violetas |
| Mosca verde `FlyGreen` / `AssetFauna.kind=fly_green` · `acid` | Gota magenta agrandada, blanco/negro | Gota con cola verde flúor `(0,55; 0,95; 0,10)` | Cuerpo Ø0,364; halo Ø0,52 | Verde flúor, 0,30 s. **Puede mezclarse con pasto** |
| Mosca común `FlyCommon` / `fly_common` · `pellet` | Glóbulo cian agrandado, blanco/negro | Bolita casi negra/marrón `(0,10; 0,08; 0,07)` | Ø0,26; polvo Ø0,364 | Polvo gris, 0,30 s. **Oscuro: mirar de noche** |
| Hormiga `Ant` / `ant` · `pebble` | Dardo grueso cian, blanco/negro | Piedra facetada naranja tostado `(0,88; 0,36; 0,08)`, con fragmento y giro | Cuerpo ~0,43 × 0,33 | **Estela marrón**, 0,30 s. **Puede perderse contra tierra/ocres** |
| Mariquita `Ladybird` / `ladybird` · `seed` | Semilla magenta, blanco/negro | Semilla oval roja `(0,85; 0,08; 0,10)` con punto negro | Cuerpo ~0,468 × 0,312 | Roja, 0,30 s. Mirar contra fondo cálido. **Sí dispara**, mediante `BeeImplantShooter`: una semilla lenta |
| Escarabajo `StagBeetle` / `stag_beetle` · `stone` | Piedra magenta, blanco/negro | Piedra facetada gris marrón `(0,50; 0,44; 0,36)`, con fragmento y giro | Cuerpo ~0,486 × 0,376 | **Gris marrón**, 0,30 s. **Puede perderse contra piedras/tierra** |
| Araña `Spider` / `ControlledSpider` · `web` | Hilos cian y borde negro | Nudo de tres hilos cruzados blanco crema `(0,97; 0,97; 0,92)` | Hilos de largo 0,806; ancho 0,0455 | Seda blanca, 0,30 s. Mirar sobre flores claras |
| Caracol `Snail` / `snail` · `bubble` | Orb cian opaco agrandado, blanco/negro | Burbuja translúcida verde pálido `(0,75; 1; 0,85)`, reflejo blanco y oscilación | Ø0,78 | Verde pálido, 0,30 s. Mirar contra fondo claro/verde |
| Gusano B `WormB` / `worm_compost` · `mud` | Glóbulo cian agrandado, blanco/negro | Glóbulo con bulto marrón `(0,30; 0,19; 0,10)` | Cuerpo ~0,499 × 0,374 | **Marrón**, 0,30 s. **Puede perderse contra suelo oscuro** |
| Gusano A `WormA` / `worm_rose` / `WormBehavior` | Rayo cian saturado con blanco/negro | Rayo cian `(0,35; 1; 1; 0,95)` | Ancho 0,196; largo según dirección original | Sin estela; aviso naranja conservado |
| Hongo `MushroomCannon` / `mushroom` · `spore` | Espora magenta con borde negro/núcleo blanco | Espora magenta `(0,92; 0,18; 0,78)` con seis púas | Envolvente ~0,624; centro Ø0,338 | Motas magenta, 0,30 s |
| Tortuga `Turtle` / `BeeGardenTurtle` · `bile` (reservada) | Glóbulo magenta agrandado, blanco/negro | Glóbulo verde oliva `(0,30; 0,55; 0,18)` | Cuerpo ~0,499 × 0,374 | Verde, 0,30 s. **Puede mezclarse con vegetación**. No se agrega al nivel |
| `Mosquito`, `WaveDragonfly`, `Dragonfly`, `Speeder` mediante `BeeImplantShooter` | Orb cian opaco, blanco/negro | Orb genérico: núcleo cian pálido, halo cian y exterior violeta translúcidos | Diámetros 0,16 / 0,34 / 0,52 | Cian, 0,14 s. Una sola muestra compartida en galería |
| `Probe`, `EyeDrone`, `Walker`, `OrganicAlien`, `AlienFighter`, `SeedCarrier`, `Nymph`, `Swarm` (`PopcornDrone` con `shooter=true`) | Misma unificación del orb | Mismo orb genérico, por `BeeShotPalette` en los niveles que conectan su hook | Diámetros 0,16 / 0,34 / 0,52 | Cian, 0,14 s. Patrones distintos, geometría compartida |
| `TarantulaBoss01` · disparo común | Orb unificado; seda afectada por helper compartido | Orb genérico de tamaño normal | Exterior Ø0,52 | Cian, 0,14 s. El aro de seda Ø0,48 que construye `_spawn_web` queda oculto por el hook de paleta del nivel, igual que antes de Tanda 3; no se cambia esa conducta |
| `TarantulaWebNet` · red atrapante | Seda cian con bordes añadidos | Aro de seda blanca `(0,96; 0,96; 0,90; 0,90)` y tres hilos | Aro Ø0,76; hilos largo 0,80, ancho 0,04 | Sin estela. Mirar sobre flores claras |
| `TarantulaBoss01` · hilos activos | Hilo magenta, blanco/negro | Seda blanca `(0,95; 0,95; 0,90; 0,90)` | Ancho 0,06; alto según techo original | Sin estela. Aviso naranja conservado |
| `WalkerMiniboss` · láser | Cian saturado, blanco/negro | Cian pálido `(0,72; 1; 1; 0,95)` | Ancho 0,20 | Sin estela |
| `EyeDroneEnemy` · láser legado | Helper con borde/núcleo agregados | Cian `(0,25; 1; 1; 0,95)` | Ancho 0,10 | Sin estela |
| `AlienMortarShell` · `WalkerMiniboss` / `Turret` | Esfera cian unshaded con blanco/negro | Esfera cian `(0,20; 0,95; 1)`, sombreado y emisión originales | Ø0,44 | Sin estela |
| `AlienMortarShell` · charco activo | Disco más opaco y borde claro/negro | Disco cian, opacidad 0,55 | Radio robot 0,70; predeterminado torreta 1,00; grosor 0,02 | Sin estela. **Casi de canto en vista lateral**; cámara inclinada en galería |
| `BeeGroundShockwave` · robot / tarántula | Cúpula cian opaca, contorno negro y aro blanco | Cúpula cian translúcida `(0,30; 0,95; 1; 0,55)` | Ancho 0,99; escala vertical 1,30 por defecto | Polvo original de `rock_break`, sin alterar emisión/ritmo. Aviso de franja conservado |
| `UfoBoss01` · disparo legado | Orb grande unificado | Orb genérico ×1,3 | Exterior Ø0,676 | Cian, 0,14 s |
| `UfoBoss01` · columna legado | Ya era cian translúcida; no cambió en Tanda 3 | Caja cian `(0,30; 1; 1; 0,55)` | 1,50 × 7,50 × 0,50 | Sin estela; se incluye para inventario |
| `UfoBossMine` · UFO legado | Esfera con blanco/negro añadidos | Esfera magenta `(1; 0,35; 0,85)`, sombreado original | Ø0,52, pulsación original | Sin estela; aro previo **amarillo** `(1; 0,90; 0,30)`, radio según explosión. No hay disparos restaurados amarillo oscuro |
| Polilla `Moth` / `MothBomb` · legado | Modelo existente, helper afectaba su radio de aviso | Modelo `moth_stationary_bomb`, carcasa oscura y lente cian; se conserva | Escala de modelo ×1,5 | Sin estela. **Carcasa oscura: mirar de noche** |
| `BeeLevel01WateringEvent` · regadera | Agua cian más opaca con rieles blancos | Cilindro celeste translúcido `(0,62; 0,86; 1; 0,62)` | Øinferior 1,10; alto 8,50 | Sin estela; aviso cian mejorado de 1 s conservado |

`FlyCloud` no dispara: ataca con el cuerpo del enjambre. `Swarm` (`PopcornDrone`) dispara una bala genérica solo si tiene `shooter=true`; las demás variantes atacan por contacto. Otros contactos/embestidas conservan sus modelos y mecánicas. El inventario de contenido legado no activa enemigos nuevos.

## Galería

Abrir `tools/galeria_disparos.tscn` en Godot y pulsar **F6**. **1** muestra día; **2** muestra el anochecer real del último tramo; **E** vuelve a guardar ambas capturas. Archivos: `docs/galeria_disparos_dia.png` y `docs/galeria_disparos_noche.png` (2000 × 2080).

Son 27 muestras, incluidos dos avisos conservados para comparación. Los disparos equivalentes comparten muestra y están identificados en la tabla. La galería carga el jardín y la iluminación de Level 01, detiene el combate y reutiliza los constructores de materiales/mallas/partículas del juego. No contiene hitboxes en las muestras. Las cámaras amplían los detalles; agua y columna UFO usan un encuadre más amplio, los rayos muestran un tramo y el charco se ve con cámara inclinada. El movimiento de revisión es más lento para observar la estela, sin tocar velocidades del juego. La captura no evalúa esquiva ni tamaño aparente en la cámara normal.

La imagen nocturna usa `LightProgression.apply_distance(310)` y la diurna `apply_distance(0)`: el jardín actual termina en anochecer cálido/violeta, no en negro. No se inventó una nueva iluminación nocturna. El escenario y sus props mantienen los mismos lugares en ambas capturas.

## Validación

Godot 4.7.2 Compatibility, render real en Intel Arc B580: ambas capturas exportadas y revisadas. Nueve pruebas dirigidas aprobadas: `validate_bee_disparos_restaurados`, `validate_bee_lote13_combat_v01`, `validate_bee_tanda3_legibilidad`, `validate_bee_arcade_combat_patterns_v02`, `validate_bee_lote11_density_v01`, `validate_bee_walker_miniboss_v01`, `validate_bee_tarantula_boss_v01`, `validate_bee_combat_variety_v01`, `validate_bee_ufo_boss_nodo_v02`. Sin suite completa ni timeout externo. Se corrigió un error inicial de inferencia de tipo del nuevo test y se volvió a correr solo la prueba afectada; también se verificaron galería/paleta después de su ajuste final.

La prueba nueva verifica los once radios originales, ausencia de bordes/núcleos añadidos en los ataques restaurados, sombreado original del mortero, retorno del hilo activo a 0,06, conservación de avisos y carga de las 27 muestras en ambos perfiles. La prueba de legibilidad existente conserva checks de hojas/pasto, día y aviso/regadera sin daño previo al segundo; su sección de disparos se actualizó al aspecto restaurado.

Cambios: fábricas `scripts/vfx/bee_shot_{styles,palette}.gd`, `toon_alien_projectile.gd`, `bee_attack_visuals.gd`; apariencia de mortero, onda, gusano, tarántula/red y agua; solo `ROBOT_LASER_COLOR` en ajustes generales; marca explícita de aviso en `ground_turret_enemy.gd` para conservar su aro de suelo cian de Tanda 3; tests relacionados, escena de galería y estas imágenes/documentación. Se repitieron las dos pruebas dirigidas al helper/aviso después de esa separación final. Ningún asset previo borrado ni reemplazado. `dev/` y los archivos locales ajenos quedan fuera del commit.

## Tanda 3c — doce propuestas, sin aplicar al juego

Se agregó **solo** `tools/galeria_propuestas.tscn` y su script de inspección. Las fábricas del juego, los seis disparos actuales, el resto de los ataques y la galería restaurada permanecen intactos. Las propuestas no tienen colisiones/hitboxes; no cambian daños ni velocidades. A utiliza copias de las mallas actuales, con geometría y escala originales; B utiliza mallas nuevas de pocas caras construidas exclusivamente en la herramienta. Todos los materiales modificados son copias propias, sin alterar la caché compartida del juego.

| Enemigo | Opción | Propuesta solo de galería |
|---|---|---|
| Hormiga `Ant` | A | Piedra original de ~0,43 m, magenta intenso `#EF16CF`, emisión, estela magenta y halo claro tenue. |
| Hormiga `Ant` | B | Dardo corto facetado de ~0,60 m, mismo magenta, emisión, estela y halo tenue. |
| Mariquita `Ladybird` | A | Semilla original de ~0,47 m, carmesí `#D70C43`, emisión, estela carmesí y halo blanco cálido `#FFF0D5` translúcido. |
| Mariquita `Ladybird` | B | Semilla angular de ~0,56 m, con marca carmesí más oscura, misma emisión/estela y halo blanco cálido. |
| Escarabajo `StagBeetle` | A | Piedra original de ~0,49 m, azul eléctrico `#135FFF`, núcleo celeste `#69CEFF`, emisión, estela azul y halo tenue. |
| Escarabajo `StagBeetle` | B | Cristal hexagonal de ~0,56 m, mismo azul, núcleo celeste pequeño, emisión y estela azul. |
| Gusano B `WormB` | A | Glóbulo con bulto original de ~0,50 m, amarillo ácido `#DFEF16`, núcleo claro `#F7FFD0`, emisión, estela amarilla y halo tenue. |
| Gusano B `WormB` | B | Gota con punta facetada de ~0,62 m, mismo amarillo, núcleo claro pequeño, emisión y estela amarilla. |
| Mosca común `FlyCommon` | A | Bolita original Ø0,26 m, cian brillante `#00EAFF`, emisión, estela cian y halo claro tenue; se conserva el tamaño para comparar. |
| Mosca común `FlyCommon` | B | Perdigón facetado Ø0,38 m, mismo cian, emisión, estela y halo tenue; el aumento es exclusivamente visual. |
| Caracol `Snail` | A | Burbuja original Ø0,78 m, borde circular y núcleo cian saturado `#00D9F5`, volumen translúcido, emisión y estela cian. |
| Caracol `Snail` | B | Burbuja facetada Ø0,84 m con borde decagonal y núcleo cian, misma emisión, transparencia y estela. |

Abrir **`tools/galeria_propuestas.tscn` → F6**. Columna izquierda A, derecha B. **1** día, **2** anochecer real del nivel, **E** exportar. Capturas: `docs/galeria_propuestas_dia.png` y `docs/galeria_propuestas_noche.png`, 1600 × 2100 px. Cada par utiliza exactamente el mismo jardín, posición y cámara; las muestras se aíslan por capas de render. Cámaras ampliadas, movimiento lento de revisión para ver estelas, sin simular una nueva velocidad de gameplay. Los halos son volúmenes 3D de opacidad 0,10: no hay contornos negros añadidos ni discos blancos opacos. Compatibility no aporta bloom HDR; la emisión mantiene el color y el halo tenue se representa con geometría translúcida. Los cuerpos conservan sombreado y facetas.

Colores, núcleos, halos, radios B, emisión (`EMISSION_GAIN=0,8`), aporte de albedo (`ALBEDO_GAIN=0,35`) y estelas (`TRAIL_ALPHA=0,55`) se configuran en constantes al inicio de `tools/galeria_propuestas.gd`. **Ninguna opción está elegida ni conectada al juego.** El tamaño visual mayor de algunas B no requiere ajustar nada para esta galería; si se eligieran para gameplay, su silueta podría exceder la hitbox actual. No se ajustó ninguna hitbox.

Validación Tanda 3c: ambas capturas renderizadas en Godot 4.7.2 Compatibility y revisadas de día y noche. Solo pruebas de galería relacionadas: `validate_bee_galeria_propuestas` y `validate_bee_disparos_restaurados`, aprobadas. La primera verifica las doce opciones, geometría/escala original de A, emisión de las estelas, ausencia de colisiones, ambos perfiles y que no se modifiquen los materiales cacheados del juego. Se corrigió un problema de texto de las capturas usando una fuente propia de la galería. No se corrió suite completa.
