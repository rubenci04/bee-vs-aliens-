# INFORME LOTE 6 — ASSETS DE CODEX: RESPALDO, CATÁLOGO E INTEGRACIÓN

Ramas: `art-source-codex-01` (solo el respaldo del trabajo de Codex) → mergeada en `assets-integration-01` (desde `visual-polish-02`) donde se integra.
El experimento Forward+ sigue aparte en `visual-forward-plus-test` (no se mezcla).

## 1) Respaldo (rama `art-source-codex-01`)
Commit solo de: `art_source/blender/`, `tests/art/`, `scenes/art_labs/`, `scenes/ui/`, `scripts/art/`, `docs/art/`, `assets/models/future_biomes_*` (574 archivos, 0 de más de 50 MB; el más grande ronda 2 MB).
Push a `origin` y merge sin force a `assets-integration-01`. **Queda sin commitear** lo que no estaba en la lista del pedido: `addons/` (godot_ai, sky_3d), `demo/`, `tools/art/`, `assets/style/future_lake_water.gdshader` y el cambio de fin de línea de `bee_enemy_patterns.gd`.

## 2) Catálogo
`docs/CATALOGO_ASSETS_01.md` + `dev/asset_catalog/` (43 `.blend` renderizados de costado con Blender 5.2 headless, hoja de contactos `contact_sheet.png`).
Hallazgo importante: **los modelos pesan 2 000–28 000 tris** (los visuales de enemigos del juego, ~1 000). Funciona sin problema a esta cantidad de enemigos en pantalla, pero los más pesados (polilla 23k, libélula 16k, hormiga 13k) conviene decimarlos.

## 3) Integración al Level 01
Un solo script nuevo reutilizable (`scripts/levels/asset_fauna.gd`, `AssetFauna`) con una tabla `KINDS` (constantes al inicio) y un modo por especie; escenas mínimas en `scenes/levels/asset_fauna/`. Sigue la **regla de fauna controlada** del nivel: el animal nunca es el objetivo, solo el **implante cian** (HP propio); un escudo de cuerpo absorbe los disparos al caparazón; al romper el implante el animal se **libera** (se apaga el dispositivo, vuela/camina fuera) y deja de contar como amenaza. El Semillero (máquina sin implante) muere por HP. Cada ataque: IDLE → **TELEGRAFÍA (mín. 0,4 s)** → ATTACK → RECOVER, reutilizando `BeeAttackVisuals` (líneas/anillos), `BeeEnemyPatterns` (abanicos), `BeeAttackTokens` (un patrón pesado a la vez), `BeeShmupFairness.can_fire`, `AlienOrbSplitter` y las minas del jefe (`UfoBossMine`, ahora con modelo opcional y desactivación si Bee muere).

| Enemigo | Rol / HP | Patrón | Telegrafía medida | Aparece |
|---|---|---|---|---|
| Mosquito (`controlled_mosquito`) | LIGHT · 36 | vuela errático (nuevo punto cada 0,3 s a 7 m/s); embestida rápida (14 m/s) por una línea fijada | línea naranja **0,52 s** | X=51 (1) y X=274 (2, con el hongo) |
| Mariquita (`controlled_flying_ladybird`) | HEAVY · 130 | lenta (2,2 m/s), barrido ancho de 1,5 s por una trayectoria fijada | línea + hinchazón **0,80 s** | X=194 |
| Libélula ondulante (`controlled_dragonfly`) | LIGHT · 56 | cruza la pantalla en onda senoidal rápida (10 m/s, amplitud 1,1 m) en la altura de Bee | banda de carril **0,65 s** | X=128 |
| Polilla (`controlled_bomb_moth`) | MEDIUM · 60 | flota y suelta **bombas quietas** (mecha 2,0 s, radio 1,4 m, daño 10, máx. 3 vivas) con el anillo que se achica de las minas del jefe | anillo de la bomba (2,0 s) + 0,50 s en la polilla | X=250 |
| Hormiga (`controlled_ant`) | LIGHT · 44 | camina hacia Bee; se levanta y se lanza 3,2 m | línea en el suelo **0,52 s** | X=101 |
| Escarabajo ciervo (`controlled_stag_beetle`) | HEAVY · 110 (blindado) | embestida recta de 1,3 s a 6,5 m/s, luego queda expuesto 1,4 s | línea ancha **0,80 s** | X=218 |
| Caracol (`controlled_woodland_snail`) | MEDIUM · 100 (blindado) | avanza a 0,7 m/s; escupe un orbe lento (4,2 m/s) | brillo y hinchazón **0,60 s** | X=233 |
| Hongo cañón (`controlled_mushroom_cannon`) | MEDIUM · 60 | estático, abanico de 3 tiros (14°) | **0,70 s** | X=274 |
| Semillero alien (`alien_seed_carrier`) | SHOWCASE · 240 | minijefe **opcional** (no bloquea: sale solo como toda unidad blanda): 3 orbes grandes que se dividen en 2 (`AlienOrbSplitter`) | **0,80 s** | X=319,5 |

Ajustes de integración: los terrestres nuevos se retiran al quedar atrás igual que Walker/Torreta; el hongo nace en pantalla como la torreta; el Level 01 sigue con tope de amenazas simultáneas 2/3/4. No toqué los POC ni las familias existentes.

**Alien:** `alien_signal_relay` reemplaza columna/anillo/punta de los 9 pilones cian (se conservan las chispas del Lote 5). **Ambiente:** luna creciente + 2 grupos de estrellas que aparecen entre X=255 y X=310 (sin niebla ni sombreado: son cielo, fijos a la cámara con una deriva mínima); 3 luciérnagas libres (sin implante) con brillo suave desde X=150, que crece al atardecer. **Decoración** (todo detrás del plano de juego, sin colisión): 2 tapas de botella, 2 latas, 2 caramelos, 4 arbustos con flores y 3 brotes de árbol (`scripts/levels/bee_level_01_asset_dressing.gd`). Todo pasa por el mismo envoltorio toon + contorno + rim del resto (el contorno cambia de color con la luz). Cian solo en tecnología (implantes, relés, orbes).

**No integrado (anotado, no forzado):** oruga blindada (20k tris, se solaparía con el escarabajo), bicho palo (silueta demasiado fina a esta escala), ratón/paloma/búho (zona humana/bosque futura), costa y lago (gaviota, pulpo, nenúfar, barca…), sapo y kit de implantes (solo estudio).

## 4) Rendimiento (mismo banco que el Lote 5: 1152×648, Arc B580, frame topado a 10 ms)
| X | CPU render antes (Lote 5) | CPU render ahora | draw calls antes → ahora |
|---|---|---|---|
| 10 | ~1,2 ms | 1,16 | 292 → 372 |
| 100 | ~1,2 ms | 1,03 | ~290 → 268 |
| 200 | ~1,2 ms | 1,55 | — → 709 |
| 300 | ~1,2 ms | 1,73 | 326 → 780 |
| 355 | ~1,2 ms | 1,68 | — → 744 |
GPU ≈ 1,8–2,1 ms (ruido ±0,4). **Costo de la primera mitad: nulo; de la tarde: +0,4–0,5 ms de CPU** — las luciérnagas (35 mallas cada una, con contorno) y los relés/lata/arbustos duplican los draw calls. Sobran ~8 ms. Si hiciera falta, bajar a 2 luciérnagas o fusionar sus mallas. Los enemigos nuevos solo cuestan mientras están en pantalla.

## 5) Capturas (`dev/visual_target/`)
- Antes (fin del Lote 5): `p5after_x{10,40,100,200,300,355}.png` · Después: `p6after_x{10,100,200,300,355}.png` (relés, luna/estrellas, luciérnagas, caramelo en el suelo).
- Enemigos nuevos: `lote6_{mosquito_idle,mosquito_dash,ladybird_warning,ladybird_sweep,dragonfly_lane,dragonfly_wave,moth_bomb,ant_lunge,stag_warning,stag_charge,snail_spit,mushroom_charge,mushroom_fan,seed_charge,seed_orbs,night_sky}.png`.

## 6) Tests
Nuevo `tests/levels/validate_bee_asset_fauna_v01.gd`: tabla de eventos/HP/roles, telegrafía ≥ 0,4 s medida por familia, cada ataque (movimiento errático, onda, bombas quietas con anillo, abanico, orbes que se dividen…), implante vs cuerpo, liberación, material toon, y la decoración (relés, litter detrás del plano sin colisión, luna/estrellas/luciérnagas según el avance).

## Dudoso / pendiente
- **Sin playtest humano:** daños, ritmos y dificultad vienen de números y capturas; las constantes están al inicio de `asset_fauna.gd`.
- El hongo cañón puede quedar parcialmente tapado por un objeto del primer plano (se vio en una captura); es del propio nivel.
- Escala: la hormiga/escarabajo/caracol miden 2–2,8 m frente a Bee (~1 m): coherente con "insectos gigantes" pero más grandes que la avispa. Si se prefiere más chico, es `scale` en `KINDS`.
- Polilla y libélula (16–23k tris) merecen decimación; no se tocó ningún modelo.

**Resultado de la suite final:** 54/54 PASS (headless, `SCRIPT ERROR` contado como fallo; incluye las suites de `tests/art/`). Tests existentes ajustados por el nuevo contenido: presupuesto de unidades 97→108 y 47→56 eventos, tabla de HP (las 10 familias originales intactas), proporción de encuentros con ataque a distancia (las familias cuerpo a cuerpo nuevas quedan fuera), espaciado de eventos, y dos filtros para nodos `MortarShell` que ya existían.
