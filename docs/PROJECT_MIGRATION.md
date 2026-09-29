# Project migration
Origen: D:\proyectos\tucuman_rush_3d.
Destino: D:\proyectos\bee_alien_3d.
Copia selectiva: 109 archivos (97 Bee).
Se copiaron todos los POCs, visuales, fuentes, generadores, tests y docs Bee.
Dependencias genéricas: scenes/components/health_component.tscn, scenes/components/hit_flash_3d.tscn, scenes/components/hitbox_3d.tscn, scenes/components/hurtbox_3d.tscn, scripts/components/health_component.gd, scripts/components/health_component.gd.uid, scripts/components/hit_flash_3d.gd, scripts/components/hit_flash_3d.gd.uid, scripts/components/hitbox_3d.gd, scripts/components/hitbox_3d.gd.uid, scripts/components/hurtbox_3d.gd, scripts/components/hurtbox_3d.gd.uid.
Mapa: dependency_map.json. APIs y rutas res:// preservadas.
Main: Bee Garden POC. Mission 01 se conserva como experimento con duración pendiente.
InputMap: WASD/flechas, Z, X, R; sin autoloads ni configuración histórica.
Excluidos: caches .godot/.import, logs antiguos, assets y tests ajenos a Bee.
Siete tests Bee trasladados. Ningún asset externo importado.
Origen sólo leído; huellas SHA256 completas en original_integrity_manifest.json.

Validación: importación GLB y main con renderer gráfico, código 0; 7/7 tests Bee.
No referencias runtime al proyecto original ni recursos literales faltantes.
art_source/.gdignore conserva .blend y evita importación directa/uso de Blender.
Verificación SHA256: los 1324 archivos del original permanecen idénticos.
Mission 01 conserva su limitación de duración; no se eligió como main.

Biblioteca externa: D:\proyectos\V_Asset_Library, inventario y shortlist separados.
26 ZIP copiados desde bee_asset_library; no se importó ningún asset externo.
Git local inicializado con identidad existente; sin push.
