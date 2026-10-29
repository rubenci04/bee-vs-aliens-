# Tanda N — ritmo, combo y polen

- Base: `tanda-m-rescate-g` (`56fde05`). Rama: `tanda-n-ritmo-combo`.
- Frenesí arranca en múltiplos de `FRENZY_COMBO=15`, no se renueva activo y espera `FRENZY_COOLDOWN_SECONDS=12` desde que termina; el HUD lo sigue mostrando.
- Tras «ZONA DESPEJADA», el combo conserva sus `COMBO_RESET_SECONDS=3` durante `COMBO_POST_ZONE_GRACE_SECONDS=8` o hasta que se vea otro enemigo.
- `DEAD_AIR_SECONDS=4`; `POST_ZONE_FIRST_EVENT_MAX_SECONDS=3` adelanta el próximo evento. `DEBUT_CLEAR_MAX=5` se conserva.
- Polen: `POLLEN_USE_COOLDOWN_SECONDS=1,5` entre cartuchos. Cura de 25, escudo y doble disparo no cambian.
- D, causa previa: `ROSTER_ARENA_MIN_SECONDS=28` solo tenía un método de consulta; `_update_arena` cerraba al agotarse oleadas, enemigos y pedidos, sin leer ese mínimo. Por eso duraban 15–19 s.
- D, ajuste: nube, escarabajos y arañas usan `ZONE_MIN_SECONDS=25`; si quedan vacías antes, suman hasta `ZONE_EXTENSION_MAX_WAVES=2` refuerzos separados por `ZONE_EXTENSION_INTERVAL_SECONDS=8`, con el cupo existente `MAX_ON_SCREEN_ARENA=10`.
- Prueba manual 1: abrí Godot 4.7.2, F5, elegí Jugar y avanzá por el Nivel 1.
- Prueba manual 2: encadená bajas hasta x15; mirá Frenesí en el HUD, sus 6 s y la espera de 12 s sin renovación.
- Prueba manual 3: despejá una zona; el combo no debe caer enseguida si no aparece otro enemigo, y el próximo evento debe llegar pronto.
- Prueba manual 4: jugá las zonas de nube, escarabajos y arañas; observá un mínimo de 25 s sin superar diez enemigos simultáneos.
- Prueba manual 5: juntá tres cartuchos y usá Q/LT; el segundo uso espera 1,5 s, con la misma cura, escudo y disparo doble.
- Tests Godot 4.7.2: `validate_bee_tanda_n`, `validate_bee_dead_air` (máximo 3,2 s), `validate_bee_tanda_k`, `validate_bee_tanda_k_cloud` (25,02 s), `validate_bee_tanda_a_pollen` y `validate_bee_boot_order`: pasaron.
- Godot avisó que no pudo escribir `user://logs/godot.log` en este entorno y mostró recursos retenidos al salir; no hubo `SCRIPT ERROR` de gameplay.
