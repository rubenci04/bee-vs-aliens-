# Guía de export de la demo (Windows)

## Estado (NOCHE 01 · ETAPA 5)
- `export_presets.cfg` tiene el preset **"Windows Desktop"**: x86_64, PCK embebido, sin firma de código, salida en `builds/windows/BeeAlien.exe`. Excluye `dev/`, `docs/`, `tests/`, `tools/`, `demo/` y `art_source/`. Lo commiteé con `git add -f`, porque `.gitignore` lo ignoraba (no tiene secretos: no hay firma ni claves).
- `builds/` está en `.gitignore`.
- **No se pudo generar el build:** en esta máquina **no están instaladas las plantillas de exportación** de Godot 4.7.2 (`%APPDATA%\Godot\export_templates\` está vacía). No las instalé a ciegas. Error real de `--export-release`: *"No se encontró una plantilla de exportación en la ruta: C:/Users/…/Godot/export_templates/4.7.2.stable/windows_release_x86_64.exe"*.

## Cómo instalar las plantillas (una vez)
1. Abrí el proyecto en Godot 4.7.2 (el mismo ejecutable con el que se desarrolla).
2. Menú **Editor → Administrar plantillas de exportación… (Manage Export Templates)**.
3. **Descargar e instalar** (elige el espejo oficial; son las plantillas `4.7.2.stable`, unos 1 GB). O bajá `Godot_v4.7.2-stable_export_templates.tpz` desde godotengine.org → *Download* → *Export templates* y usá **Instalar desde archivo**.
4. Verificá que exista `%APPDATA%\Godot\export_templates\4.7.2.stable\windows_release_x86_64.exe`.

## Cómo exportar
- Desde el editor: **Proyecto → Exportar… → Windows Desktop → Exportar proyecto** (desmarcar "Exportar con depuración" para la demo).
- O por consola (desde la carpeta del proyecto):
  ```
  godot --headless --path . --export-release "Windows Desktop" builds/windows/BeeAlien.exe
  ```
- Probá el `.exe` en otra carpeta: debe abrir el **título** (Jugar Nivel 01 / Dificultad / Salir). En el build exportado no aparecen "Colección de arte" ni "Laguna" (son de modo debug).

## Qué revisar en el build
- Arranque al título, partida completa, regreso al título al terminar, R (reintento) y Shift+R.
- Sonido (buses), mouse/mira, pantalla completa/ventana (por ahora, ventana 1152×648).
- Rendimiento: el render del Level 01 mide ~2 ms de CPU y ~2 ms de GPU en una Arc B580; conviene probar en una PC más modesta.
