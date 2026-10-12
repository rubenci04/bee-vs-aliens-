# Moscas del Nivel 01 — común, verde y nube, v01

Fecha: 2026-10-12. Rama conservada: `lote-11`.

## Ficha del pedido

Tanda de tres assets de enemigo para `level_01_garden`: mosca común gris, mosca verde de cuerpo algo más ancho y nube de ocho moscas pequeñas mezcladas. Fuentes originales Blender y exportaciones controladas/liberadas. No reemplazan ningún insecto existente ni agregan luciérnagas.

Función prevista: enemigos voladores individuales y nube móvil como una sola escena de grupo. Se entregan los visuales, animaciones y anclas para su implementación posterior; no se añaden familias al director de oleadas ni IA/HP/daño/colliders en esta tarea de arte.

Silueta: cabeza con ojos rojizos grandes, tórax oscuro, abdomen redondeado, un par de alas, seis patas y antenas cortas en los modelos individuales. Verde natural no emisivo; alas crema/ocre y grises cálidos. Cian solo en núcleo de control externo; violeta solo en nodos de las mochilas individuales. El implante es externo, separado y retirable sin cambiar la anatomía.

## Presupuesto y escala

Bee ≈ 1 unidad. Medidas del GLB en pose de exportación, X/Y/Z Godot; +Y arriba y frente -X. Son enemigos aéreos: el origen raíz es referencia de ubicación y las piezas flotan sobre él, especialmente en la nube.

| Modelo | Tris controlado | Tris liberado | Materiales controlado/liberado | Tamaño X/Y/Z (m) |
|---|---:|---:|---|---|
| Mosca común | 4104 | 3776 | 4/1 | 1.788 / 1.071 / 2.027 |
| Mosca verde | 4104 | 3776 | 4/1 | 2.003 / 1.071 / 2.149 |
| Nube de ocho moscas | 4896 | 4320 | 3/1 | 2.862 / 1.994 / 1.955 |

Todos por debajo de **5.000 triángulos por enemigo**. La nube usa versiones simplificadas: no son ocho copias del modelo individual de 4.104 triángulos. Cada miembro conserva su propio movimiento de posición, alas y patas. El GLB agrupa todos en un mismo asset, pero conserva partes articuladas: no es una optimización de draw calls con MultiMesh. Una futura integración masiva deberá valorar también instancias/materiales, además de triángulos.

La paleta natural está en una textura de 8×2 píxeles empacada en cada `.blend` y embebida en GLB. No requiere descargar texturas ni importar contenido externo.

## Animación y anclas

- `hover`, 1,2 s: vuelo estacionario, dos alas por mosca, movimiento de seis patas y oscilación corporal. En la nube, ocho raíces con fases distintas modifican su separación y profundidad.
- `attack`, 1,2 s: pequeño avance local y aleteo más amplio; presentación para una futura pasada de ataque, sin causar daño.
- `liberate`, 1,6 s: elevación y vuelo relajado. Para quitar tecnología se usa `release_control()` en el wrapper o la variante GLB liberada; el clip por sí mismo no borra materiales ni implantes.
- Pivotes `Fly_00…07`, `Wing_<n>_L/R`, `Leg_<n>_L/R_<0…2>`. Una raíz y dos alas/seis patas en individuales; ocho raíces, dieciséis alas y cuarenta y ocho patas en nube.
- Anclas `MuzzleAnchor_<n>`, `ImplantAnchor_<n>`, `BodyAnchor`, `GroundAnchor`. Muzzle queda como punto frontal para futuros disparos, no implica arma/AI ya implementada.

## Archivos y prueba

- Fuentes: `art_source/blender/levels/level_01_garden/enemies/lvl01_enemy_fly_{common,green,swarm}_v01.blend`, con cámara/luz de estudio y pistas NLA editables.
- GLB: `assets/models/levels/level_01_garden/enemies/lvl01_enemy_fly_{common,green,swarm}_v01.glb` y sufijo `_liberado.glb`.
- Manifiesto conjunto `fly_trio_v01_manifest.json` y manifiesto por modelo, junto a los GLB.
- Constructor: `tools/art/create_fly_trio_v01.py`, Blender headless con `-- common`, `-- green` o `-- swarm` después del script. No genera ni modifica otros modelos.
- Wrapper: `scripts/art/fly_trio_visual.gd` aplica el toon/contorno del proyecto y limita emisión del implante. Los materiales Blender/GLB son PBR portables; el sombreado cel final lo provee Godot.
- Laboratorio: abrir `scenes/art_labs/fly_trio_v01.tscn`, ejecutar **F6**. De izquierda a derecha: común, verde, nube. **1** vuelo, **2** avance de ataque, **3** movimiento de liberación, **L** retirar/colocar implantes.
- Prefabs: `scenes/art_labs/fly_trio_v01/{common,green,swarm}.tscn` y sufijo `_liberated.tscn`.
- Renders reales Godot Compatibility: `concept_art/levels/level_01/fly_trio/overview.png`, `movement_preview.gif`, vistas individuales y hojas `lvl01_enemy_fly_<variante>_concept_v01{,_liberado}.png`. Fondo gris neutro, sin texto, UI, escenario ni suelo.

## Verificación

Blender comprobó geometría cerrada, ausencia de caras degeneradas, triángulos exportados y materiales. Validación dirigida `tests/art/validate_fly_trio_v01.gd`: **PASS**. Cuenta miembros, alas y patas; prueba aleteo, movimiento no rígido de nube, tres clips, toon/contorno, emisión solo tecnológica, liberación y ausencia de físicas. Capturas y GIF revisados; se corrigieron dos errores de sintaxis del laboratorio/test antes de la validación final.

Suite completa ejecutada una sola vez: **89/89 PASS**, 207,1 s, sin errores de script. Logs: `dev/fly_trio_full_suite_result.log` y `dev/fly_trio_full_suite.log`.

Logs: `dev/fly_{common,green,swarm}_build.log`, `dev/fly_trio_import.log`, `dev/fly_trio_validation.log`, `dev/fly_trio_capture.log`, `dev/fly_trio_motion.log`. Blender emitió un aviso no bloqueante al escribir su caché de miniaturas fuera del proyecto; las tres fuentes y los seis GLB se guardaron y validaron correctamente.

No se modificó gameplay ni se hizo commit/push. Pendiente: implementar tres familias/patrones en el juego, balancear HP/daño y agregarlas al Nivel 01.
