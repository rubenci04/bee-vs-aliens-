# Tanda 3 — Legibilidad de enemigos y ambiente

Rama: `lote-16-titulo-intro`. Alcance: H-29, H-30, H-31, H-13 y H-17, con la jerarquía de H-12 como referencia. Se usó el mapa de `AUDITORIA_CONTEXTO.md`. No se modificaron modelos, texturas, hitboxes, daño, velocidad de desplazamiento, cadencia ni oleadas.

## Ataques y paleta (H-29)

Los proyectiles tienen núcleo blanco frío `#F0FFFF`, cuerpo cian `#05DBFF` o magenta `#FF0AA6` y contorno casi negro `#03050A`. Son materiales sin sombreado ni niebla; se construyen antes del primer cuadro en los disparos toon. El dorado sigue identificando el disparo de Bee. Los tamaños siguientes son visuales, en metros, sin el margen adicional del contorno; los radios de colisión anteriores se conservan.

| Enemigo / evento | Forma | Color | Tamaño visual elegido |
|---|---|---|---|
| Hormiga | Dardo grueso; conserva el arco y giro anteriores | Cian | ≈1,03 de largo × 0,42 de ancho |
| Avispa | Aguja con punta | Magenta | ≈1,03 × 0,36 |
| Mosca común | Glóbulo redondo | Cian | Diámetro 0,47 |
| Mosca verde | Glóbulo con cola corta; sin verde | Magenta | Diámetro del cuerpo 0,52 |
| Nube de moscas | No dispara: barrido corporal | Implantes cian; aviso reforzado | Modelo y ataque existentes |
| Mariquita | Semilla ovalada, **un tiro lento por descarga** | Magenta | ≈0,70 × 0,47 |
| Gusano de compost | Orbe irregular cerca del suelo | Cian | ≈0,81 × 0,61 |
| Gusano rosa | Rayo con núcleo claro; discos/arcos de aviso | Cian; aviso naranja con borde claro | Rayo visual 0,20 de grosor; marcas de radio 1–1,5 |
| Caracol | Orbe opaco grande que conserva el bamboleo | Cian | Diámetro 0,83 |
| Escarabajo | Piedra facetada | Magenta | Cuerpo ≈0,51 × 0,40 |
| Araña | Nudo de hilos cruzados | Cian | ≈0,81 de extensión |
| Hongo cañón | Espora con puntas | Magenta | ≈0,62 de extensión |
| Robot y otros emisores sin estilo propio | Orbe; mortero; láser; onda baja | Cian, núcleo claro y borde oscuro | Orbe 0,52 exterior; mortero 0,44 de cuerpo; láser 0,20; onda conserva dimensiones |
| Tarántula | Orbes, red y hilos activos | Orbes cian; red/hilos magenta | Orbe exterior 0,52; red de diámetro 0,76; hilos mínimo visual 0,07 |
| Regadera | Columna con dos bordes blancos; disco y franja visibles durante el aviso | Cian | Ancho 1,10 existente; bordes de 0,055 |

La mariquita sí dispara: `bee_level_01_controller.gd` le añade `BeeImplantShooter`, cuya tabla usa el estilo `seed`, un tiro a velocidad 2,6 y pausa de 5,5 s. Esos valores se conservaron. Los avisos naranjas mantienen su temporización; ahora las franjas tienen alfa mínimo 0,72 y borde claro, y los discos tienen perímetro claro con borde oscuro exterior. Al activarse, los hilos de la tarántula cambian a magenta con núcleo claro y borde oscuro.

## Ambiente y Bee (H-30, H-31, H-13, H-17)

Una presión visual de 0 a 1 se calcula con enemigos y disparos cercanos; los jefes con barra visible la llevan a 1. La transición se suaviza y afecta solo a presentación. En calma se mantienen seis hojas y 42 motas. En combate intenso quedan dos hojas con alfa 0,18, tintes grisáceos y centro de emisión en Z=-9; ocho motas neutras detrás de la acción. Los sistemas GPU reducen su emisión a 0,18 y su opacidad; las mariposas decorativas se ocultan bajo presión alta. Las partículas ambientales no llevan núcleo brillante ni borde de proyectil. El pasto de primer plano conserva un 22 % de su opacidad normal durante el combate intenso.

De día bajaron energía solar y ambiente, niebla y bruma sobre el cielo; el contraste es 1,12, el disco solar ocupa 12 % de la altura de pantalla y su halo tiene alfa 0,32. La progresión conserva la paleta de atardecer. Bee tiene contorno 0,0038 y un mínimo de luz de borde, sin agrandar modelo ni hitbox ni aumentar su emisión corporal diurna. La regadera conserva **un segundo de aviso, 0,5 s activa y cinco de daño**.

Constantes: `BeeGameSettings.DANGER_*`, `WARNING_*`, `COMBAT_*`, `AMBIENT_*`, `FOREGROUND_COMBAT_ALPHA_SCALE`, `BEE_READABILITY_*`; tamaños específicos en `BeeShotStyles`; presupuesto y tintes en `BeeLevel01LivingGarden`; parámetros de día en `BeeLevel01LightProgression` y sol en `BeeLevel01AssetDressing`.

## Validación y revisión manual

Diez pruebas relacionadas aprobadas: legibilidad T3, combate por especie, patrones de ataque, densidad/regadera, lectura del corredor, pulido visual, cielo, integración de Bee, robot y tarántula. Tras el último ajuste de núcleo, constantes y bordes, se repitieron únicamente las seis directamente afectadas: **6/6 aprobadas**. Runner sin límite de tiempo externo; no se ejecutó la suite completa en esta tanda. El test nuevo es `tests/levels/validate_bee_tanda3_legibilidad.gd`; logs y runner quedan en `dev/tanda3_checks/` y `dev/tanda3_checks.py`, sin versionar.

Las pruebas de patrones y combate conservan avisos de recursos al cerrar que también aparecen en los logs anteriores de `dev/lote15_checks/`; no hay errores de script ni fallos de validación en la ejecución final.

En Godot, abrir `scenes/levels/bee_level_01_vertical_slice.tscn` y ejecutar con F6:

- **Día, inicio y macizo:** identificar al instante Bee, los dardos de hormiga, glóbulos de mosca y semillas de mariquita; comprobar que cada proyectil tenga centro claro y silueta oscura aun sobre pasto o sol. El sol debe ser menor y la escena menos beige, sin apagar a los enemigos.
- **Calma frente a combate:** comparar hojas/motas con cero, uno y varios enemigos. Bajo fuego deben quedar pocas hojas apagadas detrás del plano de acción; el pasto delantero debe volverse tenue y recuperarse al terminar.
- **Suelo:** mirar los orbes de gusano/caracol y los arcos/franjas de aviso: no deben perderse en tierra marrón ni confundirse con polen o partículas decorativas.
- **Regadera, cerca de X=128:** comprobar marca en el suelo y franja vertical visibles un segundo antes del agua; distinguir sus bordes durante la caída y reconocer que es peligrosa.
- **Atardecer/noche, robot y tramo final:** repetir la lectura de núcleo/color/borde sobre fondo violeta; revisar morteros, láser, ondas bajas y redes/hilos magenta. Bee debe mantener su tamaño y destacarse por contorno y luz de borde.

La apariencia perceptual de día y noche queda pendiente del playtest en pantalla; las pruebas headless verifican materiales, estados y reglas, no la facilidad humana para reconocerlos.
