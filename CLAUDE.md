# Bee Alien 3D — guía para Claude

Detalle completo: `docs/INFORME_MAESTRO.md`. Reglas base: `AGENTS.md`.

## Identidad del juego
- Shooter aéreo lateral (SHMUP / run-and-gun 3D arcade). Movimiento en plano X/Y, sin salto ni gravedad.
- Una abeja con implante alienígena averiado recupera su libre albedrío, conserva la tecnología y lucha contra una invasión. Escala: jardín → territorio → cielo → invasión → atmósfera → espacio.
- Gancho: "abeja minúscula vs guerra alienígena gigante". Tono: acción + sci-fi + humor + escala insecto.
- Arte: low poly estilizado, arcade, legible. Silueta > realismo. Naturaleza cálida (verdes/ocres) vs tecnología alien (metal gris, cian).
- Motor: Godot 4.7.2, renderer GL Compatibility, Windows PC. Proyecto: `D:\proyectos\bee_alien_3d`.
- Estado: core gameplay funcional (Level 01 de 360 m, 7 familias enemigas, checkpoint, audio, VFX). Visualmente aún prototipo.
- Fase actual: Core Gameplay Closure Audit 01 → luego Art Direction / Visual Target. No inventar features para seguir programando.

## Rutas importantes
- `project.godot` — main_scene: `res://scenes/levels/bee_level_01_vertical_slice.tscn` (Level 01).
- Level 01: `res://scenes/levels/bee_level_01_vertical_slice.tscn` (F5 y F6 lo abren; los POC viejos se juegan con F6 sobre su escena).
- `scenes/bee_prototype/`, `scenes/levels/`, `scenes/decoration/`, `scenes/vfx/` — escenas.
- `scripts/bee_prototype/` (player, enemigos, armas), `scripts/levels/` (controller, checkpoint QoL), `scripts/components/` (HealthComponent), `scripts/audio/`, `scripts/vfx/`.
- `tests/bee_prototype/`, `tests/levels/` — suites `validate_*.gd`.
- `assets/models/`, `assets/external/approved/` (+ `ASSET_PROVENANCE.md`), `audio/sfx/`, `art_source/` (fuentes .blend).
- `dev/` — escenas y capturas de review, logs, copias de trabajo. No es contenido de juego.
- `docs/` — un documento por tarea (`BEE_*_V01.md`, `*_POC.md`, auditorías, inventarios, créditos).
- `default_bus_layout.tres` — buses: Master 0 dB, SFX -3 dB, Music -8 dB (vacío), HardLimiter ~-1 dB.
- Review de audio: `res://dev/audio_review/audio_review.tscn`.
- Biblioteca externa (fuera del repo): `D:\proyectos\V_Asset_Library` (ver reglas de licencias).

## Controles
- Mover: WASD / flechas. Disparo: X. Melee (Sting): Z. Alien Bomb: C.
- Pausa: Esc. Reiniciar tras derrota: R (en checkpoint = respawn); tras ganar, R = reinicio completo. Reinicio total: Shift+R.
- Armas: Base (10 HP, auto-aim ~12 m, sin homing), Spread (3 disparos ±14°, 6 HP c/u, 24 ráfagas), Bomb (radio 3 m, 32 HP, máx. 3 cargas).
- Checkpoint en X=190 m; respawn en (190, 5.4, 0) con 1.25 s de invulnerabilidad.

## Cómo correr los tests
Cada suite es un script `SceneTree`; sale con código 1 si falla. Con el ejecutable de Godot 4.7.2 (detectar uno funcional; no asumir una ruta fija. Última conocida: `C:\Users\rea_0\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`):

```
godot --headless --path D:\proyectos\bee_alien_3d --script res://tests/levels/validate_bee_checkpoint_qol_v01.gd
godot --headless --path D:\proyectos\bee_alien_3d --script res://tests/levels/validate_bee_level_01_vertical_slice.gd
godot --headless --path D:\proyectos\bee_alien_3d --script res://tests/bee_prototype/validate_<nombre>.gd
```
- Sin `--headless` (con render) algunas suites guardan capturas PNG en `res://dev/<...>_review/`. Eso ESCRIBE archivos en `dev/`; avisar antes de correrlas así.
- La suite completa son 28 validaciones (26 previas + `validate_bee_polish_props_v01` + `validate_bee_polish_audio_v01`). Tras tocar algo, correr la suite relacionada y reportar el resultado real, incluidos los fallos.
- Los tests no miden si es divertido: el playtest del usuario manda.
- Logs en `docs/bee_prototype/*.log` y `.godot/` están ignorados por git.

## Licencias de assets
- Aceptar: CC0, dominio público, CC BY (con atribución registrada), royalty-free comercial compatible.
- Rechazar o reservar: CC BY-NC, licencia desconocida, restricciones incompatibles.
- "Gratis" ≠ uso comercial. No asumir CC0 por el nombre del archivo ("cc0" en el filename no basta). Modificar un asset no quita su licencia.
- Registrar todo asset externo aprobado en `assets/external/ASSET_PROVENANCE.md`: fuente, autor, licencia, hash, archivo original, archivo en el juego. Créditos de audio: `docs/THIRD_PARTY_AUDIO_CREDITS.md`.
- Kenney, Lentikula, Quaternius: CC0. FX Laser y Sonniss: comerciales con restricción de redistribución (no redistribuir como asset suelto).
- Candidatos UFO (DUDOSO — sin evidencia local, ver `docs/ASSET_LIBRARY_AUDIT_01.md`).
- No importar assets de la biblioteca externa sin una tarea explícita (AGENTS.md).

## Reglas de trabajo (obligatorias)
- Empezar cada tarea inspeccionando el estado real; leer los docs relevantes antes de tocar nada.
- NO `git reset`, NO `git clean`, NO `git stash`, NO `git checkout --`/restore sobre cambios sin commit.
- NO commit ni push salvo pedido explícito del usuario.
- **Nunca hacer commit hasta que la suite de tests completa haya terminado y pasado. Si un prompt pide commit condicionado a los tests, esperar el resultado final.**
- NO borrar assets, escenas, scripts, tests ni docs. No renombrar/mover sin pedido.
- NO reconstruir sistemas que ya funcionan; cambios mínimos y localizados; preservar gameplay estable.
- UNA tarea significativa por prompt. No mezclar arte, boss, Level 02, audio, menús, etc.
- No modificar `D:\proyectos\tucuman_rush_3d` ni el proyecto 2D.
- No usar Blender (`C:\Program Files\Blender Foundation\Blender 5.2`) sin necesidad. Conservar .blend y exportar GLB.
- POCs pequeños y verificables. No contenido masivo. Evaluar necesidad, costo y alcance antes de agregar features.
- Al terminar: informar archivos cambiados, cómo probar (proyecto, escena, tecla, qué observar) y problemas. Instrucciones al usuario siempre precisas; no pedirle editar código a mano.
- Responder en español.

## Fuera de alcance por ahora
Dash/roll, XP, moneda, árbol de habilidades, tienda, crafting, multi-checkpoint, save system, dificultad configurable, monetización. Score, boss/mini-UFO y música: se decide tras la auditoría.
