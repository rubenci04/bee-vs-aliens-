# Bee Level 01 — Vertical Slice V01

**Scene:** `res://scenes/levels/bee_level_01_vertical_slice.tscn`. Density & Collision Pass 02: 360 m, scroll 2 m/s (180 s de viaje base), 24 eventos y 38 enemigos. El scroll continúa en los encuentros ligeros. Sólo el humano y tres hard gates interrumpen el avance; tiempo final de partida depende del combate.

## Ruta actual

| X (m) | Unidades / evento | Política |
| --- | --- | --- |
| 12 | Wasp | soft |
| 26 | Wasp + Wasp | soft |
| 40 | Probe + Wasp | soft |
| 54 | Wasp; túnel en 55 | soft |
| 68 | EyeDrone + EyeDrone | soft |
| 82 | Probe | soft |
| 96 | EyeDrone + Wasp; roca alta | soft |
| 110 | Speeder | soft |
| 124 | Wasp | soft |
| 140 | Giant Human; sin combate | especial |
| 156 | Turret | soft |
| 170 | EyeDrone + Turret | soft |
| 184 | Wasp | soft |
| 198 | Probe + Speeder | soft |
| 212 | Turret | soft |
| 226 | Wasp + Wasp | soft |
| 240 | EyeDrone | soft |
| 254 | Organic Alien + Wasp | hard |
| 268 | Probe + EyeDrone | soft |
| 282 | Turret | soft |
| 296 | Walker + EyeDrone | hard |
| 310 | Wasp + Speeder | soft |
| 324 | Probe + EyeDrone + Wasp | soft |
| 340 | Walker + Probe + Turret | hard |

Grupos escalonados cada 0,8 s, con cupo 2 hasta X=300 y 3 después. Los 20 soft encounters permiten retiradas: tras 6 s de presión el enemigo deja de atacar y se desplaza fuera de pantalla; se libera su nodo al salir. Los hard gates requieren bajas y esperan que las amenazas soft previas salgan. El humano conserva telegraph y cruce sin enemigos simultáneos. Mean gap entre umbrales: 7,13 s; máximo 8 s. Inicio a 6 s; última navegación/polen en 343–347 m antes del final. HP locales intactos: Wasp 36, Probe 32, EyeDrone 24, Speeder 30, Turret 40, Organic Alien 47, Walker 60. No se cambian ataques, auto-aim ni escenas reutilizables.

## Navegación y presentación

17 pollen en rutas altas/bajas. 8 cajas de 24 HP en X=18,43,120,153,198,242,282,343: X/Z las destruyen y liberan colisión. 8 rocas sólidas en X=72,96,155,205,241,283,307,345; se pueden sobrevolar. Tronco hueco en 55 y botella en 41: 18 obstáculos contando cajas, rocas y ambos props. El tronco conserva shell de cuatro piezas e inherited collider desactivado.

Escenografía: 350 colocaciones (antes 206). 16 pockets irregulares agregan 80 flores, 48 helechos y 16 árboles, con profundidad/escala/giros diferentes. Foliage nuevo siempre detrás del plano de vuelo; se conserva foreground pequeño. Sólo assets aprobados y rocas/cajas primitivas; ningún import externo ni textura nueva. Daylight y materiales existentes intactos.

Los bounds completos de foliage de fondo quedan detrás de Z=−3. Helechos foreground al 20% de altura para no ocultar la ruta de vuelo baja ni los cuerpos enemigos; se mantienen tamaño horizontal y colocaciones.

Giant Human local: GLB, Run y escala 6× intactos; soles blancos siguen ocultos. Hitboxes de piernas siguen las posiciones animadas foot/calf y se recortan fuera del corredor X local ±1,2 (mínimo 2,4 m). Altura 2,9 m, profundidad 3 m, ancho variable según pose. Torso 4,45×4×1,55 m, centro Y=5,2; empieza en Y=3,2. La colisión es generosa respecto del modelo para preservar la ruta central. Contacto conserva 20 HP una vez por crossing. Diagnóstico y métricas: `docs/PLAYTEST_FEEDBACK_03.md`.

## Asset review

`D:\proyectos\V_Asset_Library\01_Extracted\nuevos` contains eight files: `Frozen+Penguin+Valley.blend1`, `Low Poly UFO Scene By EdwinRC.3ds`, `Low Poly UFO Scene By EdwinRC.fbx`, `Male_Avatar_Character_Free.blend`, `Space_Rocket.blend`, `Stylized_Foliage_Coniferous_Kit.blend`, `UFO_Wavefront.obj`, and `UFO.blend`. The Coniferous `.blend` is 219,558,286 bytes (~209 MiB). Its name/size and the user's stated download source are consistent with [Mini Stylized Foliage Kit on CGTrader](https://www.cgtrader.com/free-3d-models/plant/conifer/mini-stylized-foliage-kit), whose live listing names cratial3d and a Royalty Free License (no AI). No local README, license file, or download manifest independently ties this particular `.blend` to the listing. Conversion and promotion remain deferred. The other files remain reserved and unused. No files were copied into the approved asset tree or selected-for-game library.

## Validación y playtest

Godot 4.7.2: WASD/flechas volar, X Base/Spread, Z melee, C Alien Bomb, R reiniciar tras derrota. Abrir la escena indicada y F6, o ejecutar:
```powershell
& 'C:\\Users\\rea_0\\Downloads\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe' --path 'D:\\proyectos\\bee_alien_3d' res://scenes/levels/bee_level_01_vertical_slice.tscn
```

El test integrado verifica 24 umbrales, 38 spawns, HP, entradas escalonadas, máximo 3, escape soft, hard gates, cajas X/Z, rocas, túnel, polen, final y reload real con R. El test de colisión sigue el centro del hueco durante todo crossing (~470 frames); cada pierna y torso producen 20 HP una vez. La comprobación aislada suspende el clamp/movimiento de Bee, no Areas físicas. La progresión usa umbrales/frames normales, time_scale=3 sólo para acelerar el test y bajas directas de Health tras observar grupos; no prueba habilidad ni supervivencia humana.

Capturas actuales: `dev/level_01_review/density02_*` y `human_safe_gap_debug.png`; los volúmenes rojos existen sólo durante el test. Capturas previas se conservan. Logs actuales en el mismo directorio. Resultados finales se registran en PLAYTEST_FEEDBACK_03.

Cierre Pass 02: test integrado headless/render aprobado; cargas jugables directas headless/render código 0; suite completa **17/17**, sin regresiones ni errores del motor. Gap seguro durante 471 frames headless / 467 render; piernas/torso mantienen un impacto de 20 HP. Se observaron cuatro escapes soft, 38 enemigos y máximo tres. Muestra final render de 5 s con tres amenazas: 99,96 FPS medios, mínimo 90, peor frame 13,58 ms; pico de nodos integrado 1091. Ver feedback para alcance y límites de las mediciones.

Limitaciones del cierre Pass 02 (histórico): entonces R recargaba todo, sin checkpoint. El log puede ocultar parcialmente a Bee; no transición de campaña. La retirada soft es provisional y el corredor humano deliberadamente tolerante. Necesita playtest humano de entrada/salida del hueco, ritmo, lectura del foreground y dificultad final.

## Flora & Garden Variety Pass 01

Decoración sigue en 350 colocaciones, ahora 134 flores de seis variantes: purpleA 47 (antes 139), purpleB 20, redA 15, yellowA 13, yellowB 32 y rosa recuperada del Garden POC 7. Cinco slots alien se sustituyen por helechos. Paletas de inicio amarilla/violeta, tronco violeta, zona humana roja/rosada, contacto alien bajo y final mixto. Escalas 0,75–1,25 alrededor de base por modelo, agrupación irregular y bounds de fondo detrás de Z=−3 conservados.

Promoción selectiva de cuatro GLB Kenney con CC0 local, sin recolor de fuentes. La biblioteca nueva flores contiene 15 GLB sin evidencia local suficiente: todos reservados, ninguno promovido. No macetas/cactus/tallos nuevos. Gameplay, humano y encuentros intactos. Inventario: FLORA_ASSET_INVENTORY.md; detalle, capturas y cierre: FLORA_VARIETY_PASS_01.md. Capturas en dev/level_01_flora_review, conservando las de Density Pass 02.

Cierre Flora Pass 01: Level 01 headless/render aprobado; cargas jugables directas código 0; suite Bee **17/17**, sin regresiones ni errores del motor. Muestra local render de 5 s con tres amenazas: 99,998 FPS medios, mínimo 89, peor frame 10,993 ms; pico integrado 1147 nodos. Gameplay y colisión humana mantienen las validaciones previas. Próximo paso mínimo: playtest humano de variedad/lectura, no nuevas armas.

## Weapons + Powerups V01

Disparo Base intacto (10 HP). Spread temporal: X genera tres proyectiles de 6 HP, central con auto-aim y laterales ±14°, 24 pulsaciones, recarga a máximo y retorno automático a Base. C usa Alien Bomb centrada en Bee: 3 m, 32 HP, una descarga por target, máximo tres cargas e inicio con una. Sólo enemigos activos y cajas; humano/rocas/tronco/decoración excluidos.

Cuatro pickups cian: Spread X=22 Y=3,8; Bomb X=166 Y=3; Spread X=222 Y=3,8; Bomb X=318 Y=3,8 (todos Z=0), antes de grupos existentes en 26/170/226/324. Bomb a máximo deja el pickup disponible. HUD aditivo Base/Spread y Bomb; hints breves en primera recogida. Reset total restaura Base/0 Spread/1 Bomb/cuatro pickups/HUD; R desde checkpoint restaura el snapshot indicado abajo. Encuentros, polen, flora, obstáculos y humano permanecen intactos. Parámetros, tests, capturas y performance: `docs/BEE_WEAPONS_POWERUPS_V01.md`; logs en `dev/weapons_powerups_review/`.

Cierre Weapons V01: específico headless/render OK; integrado Level 01 OK; cargas directas headless/render código 0; suite **18/18**, sin regresiones. Muestra render local de 180 frames con tres Probes iniciales: ~100 FPS medios sin/con especiales, peor frame 10,452/10,652 ms. Falta playtest humano para evaluar utilidad, lectura y dificultad; no se inicia VFX/Audio.

## Checkpoint + Quality of Life V01

Checkpoint único de sesión X=190, después del humano y antes de X=198. Cura hasta mínimo 60 HP, guarda Spread/Bomb reales, polen y estado mínimo del tramo. R tras derrota: inicio antes de activar / respawn `(190,5.4,0)` después. Al retomar no reaparecen los 13 eventos anteriores ni sus pickups; segunda mitad se reconstruye y no hay acumulación entre intentos. Protección con blink 1,25 s sin bloquear movimiento/disparo; audio/VFX/proyectiles/target se limpian mediante recarga normal.

Esc pausa/reanuda; Shift+R reinicia todo. Hint inicial X FIRE / Z STING / C BOMB y mensajes CHECKPOINT / RESTART / RESPAWN. Baliza primitiva cian y cue positivo existente. Sin cambios a los 360 m, 24 eventos, 38 enemigos, HP/balance, flora ni arte. Detalle y limitaciones: `docs/BEE_CHECKPOINT_QOL_V01.md`; test específico y review en `dev/checkpoint_qol_review/`. El test integrado conserva final y verifica reset total usando Shift+R.

Cierre Checkpoint/QoL: específico headless/render OK, cargas jugables directas headless/render código 0, suite **22/22**, sin regresiones ni errores/advertencias del motor. Muestra quieta render sin/con procesamiento QoL: 100,00/99,99 FPS; peor frame 10,625/10,340 ms. No sustituye playtest humano.

## UFO BOSS 01 — final del nivel
El final ya no es "último encuentro → SECTOR DESPEJADO". Ahora es: último encuentro → respiro de 1,6 s con arena bloqueada → aproximación del OVNI en profundidad (3,2 s, invulnerable) → combate de 3 fases (`ALIEN SCOUT`, 1300 HP, ~60 s) → muerte (2,3 s, borra sus proyectiles) → `SECTOR DESPEJADO`. Detalle en `docs/BEE_UFO_BOSS_01.md`. Los 360 m, los 24 eventos y los 38 enemigos no cambian.
