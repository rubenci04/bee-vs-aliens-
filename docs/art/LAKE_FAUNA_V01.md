# Bee Alien · Fauna de las orillas 01

Tanda pequeña para preparar el lago: dos insectos controlados y un módulo de raíces natural. Modelos originales, fuentes editables Blender, exportaciones GLB y shaders toon del proyecto, en Godot 4.7.2 Compatibility. Sin assets externos.

| Modelo | Triángulos reales | Mallas |
| --- | ---: | ---: |
| `controlled_water_strider` · zapatero de agua | 4.872 | 2 |
| `controlled_dragonfly_nymph` · ninfa de libélula | 4.842 | 2 |
| `submerged_root_module` · raíces sumergidas | 1.532 | 1 |

Zapatero: cuerpo esbelto, antenas, seis patas, pares medio y posterior largos. Ninfa: cabeza ancha, abdomen segmentado, seis patas cortas flexionadas y tonos oliva. Ambos llevan el implante canónico grafito/cian/violeta, externo y removible. `NaturalFauna` permanece visible al liberar `AlienControlDevice`. Las raíces son madera cálida sin tecnología ni emisión.

Las fichas individuales son laterales o 3/4, con fondo neutro y sin UI. La composición coloca el zapatero sobre la superficie, la ninfa y las raíces bajo ella, con Bee y las totoras locales como referencias de escala. Usa el agua estilizada existente; no simula flotación ni refracción.

## Archivos creados y modificados

- `art_source/blender/lake_fauna_v01/`: tres fuentes `.blend` y `.gdignore`.
- `assets/models/lake_fauna_v01/`: tres GLB, importaciones y `manifest.json` con cifras y rutas.
- `scenes/art_labs/lake_fauna_v01/`: tres wrappers que aplican toon, rim y contorno.
- `scenes/art_labs/lake_fauna_v01.tscn`: estudio y acceso a composición.
- `scripts/art/lake_fauna_lab.gd`: presentación del lago.
- `tools/art/create_lake_fauna_v01.py`: generador reproducible.
- `tests/art/validate_lake_fauna_v01.gd`: presupuestos, anatomía, materiales y liberación.
- `docs/art/lake_fauna_v01/`: capturas reales de estudio, lago y piezas.
- Modificados: `scripts/art/art_delivery_hub_v01.gd`, para incluir esta tanda; `tools/art/capture_catalog.gd`, para capturar la composición del lago.

## Cómo probar

Abrir `scenes/art_labs/lake_fauna_v01.tscn` y ejecutar con **F6**, o elegir **Zapatero, ninfa y raíces del lago** en la colección de arte.

- **1–3**: seleccionar modelo.
- **V**: vista lateral / 3/4.
- **L**: quitar/restaurar los implantes de la fauna; las raíces permanecen naturales.
- **O**: composición en la orilla.
- **E**: estudio de las tres piezas.
- **H**: ocultar UI.
- **Esc**: volver al índice.

Para llevarlos a un nivel, instanciar los wrappers `.tscn`. Son assets visuales sin rig, colisiones, IA ni animaciones de ataque. La geometría natural se agrupa; se conservan referencias vacías de las seis patas para futuros rigs. No reemplazan enemigos existentes ni modifican el nivel jugable.

## Verificación y límites

Blender comprueba sólidos cerrados y ausencia de caras degeneradas. El validador en Godot confirmó recuentos GLB iguales al manifiesto, presupuestos inferiores a 5.000, seis referencias de patas por insecto, fuentes presentes, toon/contorno y retirada del dispositivo sin pérdida de anatomía: **0 fallos**. Las emisiones activas pertenecen sólo al implante. Se revisaron visualmente estudio, composición y zapatero en 3/4.

Se mantiene la advertencia conocida de caché de shaders `user://` en la sesión restringida. Importación y captura completadas; sin errores nuevos de estos assets. Los presupuestos de geometría no son una medición de FPS; varias superficies y los contornos añaden pases de dibujo.
