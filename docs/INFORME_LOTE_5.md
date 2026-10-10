# INFORME LOTE 5 — VISUAL POLISH 02

Rama `visual-polish-02` (desde `combat-variety-01`). El experimento Forward+ está aparte en la rama `visual-forward-plus-test` (no se mezcla).

## 1) Cel-shading unificado
**Auditoría** (`dev/visual_target/audit_toon.gd`, y ahora el test `validate_bee_visual_polish_v02`): se recorrieron todas las superficies visibles del Level 01. Casi todo ya usaba el shader toon (bandas de luz + rim + contorno): actores, jefe, objetos gigantes de jardín, pozos, hongos, etc. Los que tenían **otro "look"** (StandardMaterial suave) eran:
- la **decoración procedural completa** (tallos, pasto, flores, guijarros, hojas, suelo): ahora usa los mismos shaders toon (`TOON` / `TOON_DOUBLE`), con rim suave (0,22; sin rim en suelo ni pasto para que no se lave), y contorno fino solo en sólidos cerrados (guijarros, centro de flor, tallos) — no en hojas/pétalos finos;
- la **botella de refresco** (gigante y lejana), el **tronco caído**, la **baliza del checkpoint**, los **cristales de polen** y las **cápsulas de arma** (ahora toon con emisión conservada);
- cajas POC bajo el suelo (`Ground`, `GroundExtension`): ocultas (estaban coplanares bajo la capa de mantillo).
Exentos a propósito: los aros brillantes ("Halo") de la cápsula S+, y las gotas reales de la regadera (única partícula con gravedad, a propósito).
- **Humano Gigante:** sigue sin contorno (decisión previa documentada: a su escala lo convertiría en una pegatina) y no lo toqué (en pausa). **Jefe:** ya era toon.
- **Contorno con color según la luz:** `BeeToonStyle.set_outline_tint()`; `BeeLevel01LightProgression` lo mezcla: marrón cálido de día (~0,19/0,09/0,03) y **violeta al atardecer** (~0,17/0,07/0,26). Todos los materiales de contorno compartidos se actualizan juntos.
- Bandas de sombra: se mantienen las 3 del shader (oscuro / medio / claro).

## 2) Partículas (todas `GPUParticles3D`, sin gravedad, presupuesto bajo) — `bee_level_01_ambient_fx.gd`
| Sistema | Qué hace | Presupuesto |
|---|---|---|
| Chispas cian | suben de los anillos de los pilones alienígenas; solo emiten los pilones a <16 m de la cámara | 8 por pilón |
| Polvo de suelo | puff suave bajo Bee cuando vuela bajo (y < 1,9 m) | 10 |
| Brillo de rocío | puntos que titilan en el pasto del fondo (siguen a la cámara) | 22 |
| Bruma de fondo | velos suaves a la deriva a lo lejos; toman el color de la niebla (cálido de día, violeta al atardecer) y suben de 0,10 a 0,16 de opacidad | 7 |
Gravedad cero explícita en todos; el test lo verifica, además de que no haya sistemas CPU con gravedad fuerte (salvo la regadera).

## 3) Ambientación
- **Contraste plano de juego / fondo:** niebla un poco más densa y más cercana (densidad 0,80→0,88, inicio 14→13 m; sigue cumpliendo "detrás del plano de juego") + el nuevo velo de profundidad.
- **Capas de fondo difusas y sin filas repetidas:** `_build_depth_layers` (RNG propio: las secuencias aprobadas de la decoración no cambian): ~26 lotes de **hojas anchas y apagadas** muy atrás (z −20…−13) que la niebla desenfoca, y **grupos de 2-3 tallos con espiga** a distancias irregulares (huecos largos y matas) que rompen las hileras de tallos gigantes.
- **Bee más grande:** `VISUAL_SCALE` 1,2 solo en el visual; cuerpo (r 0,28), hurtbox (0,20) y caja de aguijón **sin tocar** (el test lo verifica).

## 4) Rendimiento (render del nivel, 1152×648, Intel Arc B580, 5 posiciones; el cuadro está topado a 10 ms por el monitor de 100 Hz, así que se compara el tiempo de render)
| | CPU render (ms) | GPU render (ms) | draw calls (x=10 / 300) |
|---|---|---|---|
| Antes (`combat-variety-01`) | 1,18 – 1,27 | 1,05 – 1,79 | 264 / 291 |
| Después | 1,19 – 1,24 | 1,52 – 1,69 | 292 / 326 |
Tres corridas alternadas: **sin diferencia medible** (el ruido de GPU entre corridas, ±0,4 ms, es mayor que la diferencia). Sobran ~8 ms de margen. Los draw calls suben ~10 % (+30: contornos de sólidos de decoración y las capas nuevas).

## 5) Experimento Forward+ (rama `visual-forward-plus-test`, copia del proyecto; el principal sigue en Compatibility)
Ver `docs/FORWARD_PLUS_TEST.md` en esa rama. Resumen: arranca y los shaders toon funcionan sin cambios, pero **cambia el color** (más gris/desaturado, cielo y niebla distintos, el realce dorado de la abeja al atardecer se apaga), SSAO casi no se nota en este arte plano y el desenfoque de campo lejano también difumina las flores y tallos del fondo cercano que dan lectura. **No lo recomiendo ahora.**

## Capturas (`dev/visual_target/`)
Antes: `p5before_x{10,40,100,200,300,355}.png` · Después: `p5after_x{10,40,100,200,300,355}.png`.

## Pendiente / dudoso
- La botella ahora se ve opaca (rojo-marrón toon); antes tenía otra lectura. Si se prefiere translúcida, hace falta un shader toon con alfa (no existe).
- No hubo playtest humano: dust / chispas / rocío están medidos por test y capturas, no por sensación en movimiento.

**Resultado de la suite final:** 53/53 PASS (headless, `SCRIPT ERROR` contado como fallo; incluye suites ajenas sin trackear en `tests/art/`).
