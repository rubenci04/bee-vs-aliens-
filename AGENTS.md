# Bee Alien 3D — guía para agentes (Codex)

`CLAUDE.md` dice lo mismo para Claude Code: si cambiás uno, cambiá el otro. Lo anterior a la Tanda R quedó en `docs/CLAUDE_HISTORICO.md`.

## Quién pide y cómo hablarle
- Rubén es principiante: usa la app de escritorio, no edita código a mano. Explicaciones paso a paso, en español rioplatense simple.
- Al terminar: qué cambió, cómo probarlo (escena, tecla, qué mirar), qué quedó pendiente y qué no se pudo verificar.

## El juego
- Shooter aéreo lateral 3D (plano X/Y). Una abeja con implante alienígena averiado recupera su libre albedrío y libera insectos controlados.
- Godot 4.7.2, renderer GL Compatibility, Windows. Proyecto: `D:\proyectos\bee_alien_3d`.
- Nivel 1 (jardín, 360 m): zonas bloqueantes (nube X=138, escarabajos X=214, arañas X=262), robot caminante (gate X=294), tarántula final, pantalla de resultados.
- Plan vigente: doc «Bee vs Alien — Plan 2: Bee protagonista» (tandas R a X). Informes: `docs/INFORME_TANDA_*.md` (E a R).

## Git
- Remoto: `origin` = github.com/rubenci04/bee-vs-aliens-. `master` es viejo: no usar.
- Cadena lineal de ramas, una por tanda: `tanda-e-…` → … → `tanda-q-validar-g` → `tanda-r-terreno-limpio` → la siguiente sale de la última.
- Prohibido: `git reset`, `git clean`, `git stash` (salvo listar), `git checkout --`/restore sobre cambios sin commit, `commit --amend`, `push --force`.
- No borrar assets, escenas, scripts, tests ni docs (mover sí, con su `.uid`). Los `.uid` de Godot van siempre al repo.
- Commit y push solo cuando el pedido lo dice y después de que las suites pedidas pasen. Una tanda por chat; nadie más usa git a la vez.

## Controles
| Acción | Mando | Teclado / mouse |
| --- | --- | --- |
| Mover | stick izquierdo | WASD / flechas |
| Apuntar | stick derecho | mouse (sin moverlo 2,5 s vuelve el auto-aim) |
| Disparar (tocar = 1, mantener = ráfagas) | RT o A | X o clic izquierdo |
| Bomba | X | C |
| Pirueta (invulnerable un instante) | B o LB | Shift |
| Puñetazo / aguijón | Y o RB | Z |
| Polen: cura + escudo + disparo doble | LT | Q |
| Pausa | Start | Esc |
| Reiniciar tras derrota / reinicio total | Y | R / Shift+R |
| Debug: salto al jefe / HUD / caja negra | — | F9 / F3 / F4 |

## Rutas importantes
- `project.godot` → título `scenes/game/bee_title_screen.tscn`. Nivel 1: `scenes/levels/bee_level_01_vertical_slice.tscn` (F6 lo abre directo).
- Director del nivel: `scripts/levels/bee_level_01_controller.gd` (tabla `EVENTS_ROSTER`). Combo, Frenesí y polen: `scripts/levels/bee_level_01_juice.gd`.
- Constantes: `scripts/game/*_settings.gd` y `bee_game_settings.gd`. Bee: `scripts/bee_prototype/bee_player.gd` y `bee_visual.gd`.
- Jefes: `scripts/levels/walker_miniboss.gd`, `tarantula_boss_01.gd`. Música: autoload `MusicManager` (`scripts/audio/`).
- Caja negra: `user://director_log.txt` (F4 la vuelca). En Godot: Proyecto > Abrir carpeta de datos de usuario.
- `dev/` = herramientas y capturas de trabajo (no es contenido de juego). `tests/legacy_rojos/` = suites apartadas (ver su README).

## Tests
- Ejecutable (detectar uno que funcione; última ruta conocida): `C:\Users\rea_0\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`.
- Una suite: `godot --headless --path D:\proyectos\bee_alien_3d --script res://tests/levels/validate_<nombre>.gd` (sale con 1 si falla).
- Antes de cada commit: `bash dev/tanda_r/run_nucleo.sh` (todas las suites menos `tests/legacy_rojos/` y 5 recorridos largos; ver `docs/SUITES_NUCLEO.md`).
- Un `SCRIPT ERROR` cuenta como fallo aunque el código de salida sea 0.
- Sin `--headless` algunas suites escriben capturas en `dev/`: avisar antes de correrlas así.
- Tras reemplazar audio o modelos, o agregar un `class_name` nuevo: `godot --headless --path . --import` antes de testear.
- Los tests no miden si es divertido: manda el playtest de Rubén.

## Reglas de trabajo
- Empezar mirando el estado real (rama, `git status`, informes). Cambios chicos y localizados; no reconstruir lo que funciona.
- Todo número nuevo de gameplay o presentación va como constante con nombre y comentario corto en español; lo grande, con interruptor.
- No cambiar vida ni daño por golpe de los jefes sin pedido explícito.
- No usar Blender sin necesidad (conservar `.blend`, exportar GLB). No importar de `D:\proyectos\V_Asset_Library` sin tarea explícita.
- No tocar `D:\proyectos\tucuman_rush_3d` ni el proyecto 2D.
- Cada tanda deja `docs/INFORME_TANDA_<letra>.md` corto.

## Licencias de assets
- Aceptar: CC0, dominio público, CC BY (con atribución registrada), royalty-free comercial compatible. Rechazar: CC BY-NC o licencia desconocida.
- «Gratis» no es uso comercial; «cc0» en el nombre del archivo no basta. Registrar todo asset externo en `assets/external/ASSET_PROVENANCE.md`; créditos de audio en `docs/THIRD_PARTY_AUDIO_CREDITS.md`.
- Kenney, Lentikula, Quaternius: CC0. FX Laser y Sonniss: comerciales, sin redistribuir sueltos.
