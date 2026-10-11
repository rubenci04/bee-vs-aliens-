# Instrucciones para agentes — Bee Alien 3D

Leé primero [`CLAUDE.md`](CLAUDE.md) y los informes de continuidad pertinentes en `docs/`. CLAUDE.md reúne la guía del proyecto, el ejecutable de Godot, cómo correr pruebas, licencias y rutas importantes.

## Reglas de trabajo

- Proyecto independiente Godot 4.x, renderer Compatibility. Conservá fuentes `.blend` y exportá GLB cuando se creen modelos.
- Antes de editar, revisá rama, estado real y documentos relevantes. No cambies a ramas que no tengan los archivos de arte necesarios.
- No uses `git reset`, `git clean`, `git stash`, `git checkout --`, force-push, amend ni otras operaciones que descarten o reescriban trabajo existente.
- No borres assets ni rehagas modelos existentes. No importes assets de la biblioteca externa sin una tarea explícita.
- No modifiques `D:\proyectos\tucuman_rush_3d` ni el proyecto 2D.
- Mantené el alcance pequeño y verificable. Los valores nuevos de gameplay y presentación deben quedar en constantes configurables.
- Corré pruebas dirigidas durante el trabajo. Corré la suite completa una sola vez al final; si el pedido condiciona commit/push a que esté verde, no publiques antes de ese resultado.
- Al terminar, informá en español los archivos cambiados, cómo probarlo y cualquier problema.

## Referencia

Para identidad, arquitectura, controles y flujo de validación, seguí [`CLAUDE.md`](CLAUDE.md) y `docs/INFORME_MAESTRO.md`.
