# Plantilla de pedido de assets

Copiar, completar y entregar. Un pedido = una tanda pequeña y verificable. Antes de pedir, revisar `ASSET_MANIFEST.md`: puede que ya exista.

```
Nombre del asset:
Nivel (level_01_garden … level_07_space, shared, rail_mode):
Categoría (enemigo / entorno / jefe / ítem / fx / ui):
Función en juego (qué hace, cuánto dura en pantalla, cómo se destruye o se libera):
Escala respecto de Bee (Bee ≈ 1 unidad de largo):
Silueta / lectura a distancia (qué debe reconocerse en 0,3 s):
Paleta (naturaleza cálida o tecnología alien gris/cian; colores prohibidos):
Presupuesto de triángulos (referencia: ~5.000 enemigos comunes, ≤ 12.000 jefes/montura):
Variantes (controlado / liberado, dañado, etc.):
Anclas necesarias (MuzzleAnchor, hurtbox, punto de implante):
Animación (ninguna / rig / procedural en Godot):
Referencias (imágenes o assets del manifiesto):
Licencia/origen (propio / externo aprobado; ver reglas en CLAUDE.md):
```

Entrega esperada: `.blend` en `art_source/blender/…`, GLB en `assets/models/…`, escena de laboratorio, `manifest.json` de la tanda y fila nueva en `ASSET_MANIFEST.md`.
