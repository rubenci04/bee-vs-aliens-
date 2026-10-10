# EXPERIMENTO FORWARD+ (rama `visual-forward-plus-test`)

Aislado: se corrió sobre una **copia** del proyecto (estado de `visual-polish-02`) cambiando solo `project.godot`
(`project_godot.diff`: `rendering_method` y `features` de Compatibility a Forward Plus). El proyecto principal **no se modificó**.
Script: `bench_fwd.gd` (mismo vuelo que `bench_polish.gd`; variantes `plain`, `ssao` y `full` = SSAO + desenfoque de campo lejano + contraste).
Equipo: Intel Arc B580, 1152×648, 5 posiciones del nivel, vsync off (el monitor topa a 100 Hz).

## ¿Arranca / se rompe algo?
- **Arranca sin errores** y reimporta en ~40 s. Los shaders toon (cuerpo, doble cara, contorno por casco invertido) y los GPUParticles de `AmbientFx` funcionan **sin cambios**.
- **El color cambia**, no se rompe: Forward+ usa otra tubería de color (HDR lineal + tonemap), y con los mismos valores de sol / niebla / ambiente la imagen sale **más gris y desaturada**, el cielo más apagado y la niebla más espesa y verdosa (`fwd_plain_x100.png` vs `dev/visual_target/p5after_x100.png` de la rama principal). El realce dorado de Bee al atardecer (emisión + rim) se ve más tenue. Habría que reajustar toda la paleta de luz / niebla / brillo.

## SSAO
Activado (`radius 1.2, intensity 2.0`): oscurece levemente las uniones suelo-roca y base de tallos, pero **casi no se nota** en este arte de colores planos con sombra proyectada del sol (`fwd_ssao_x100.png`). Costo pequeño.

## Desenfoque de campo (DoF) lejano
Con distancia 16 m y transición 10 m el desenfoque **empieza más cerca de lo esperado y difumina también flores, tallos y pilones del plano cercano**, que son los que dan lectura y escala; Bee queda nítida pero se pierde contraste de silueta entre la capa de juego y el fondo inmediato (`fwd_full_x100.png`, `fwd_full_x300.png`). Para el estilo "silueta > realismo" resulta contraproducente; el desenfoque que buscamos ya se logra con la niebla y las capas de velo.

## Rendimiento (render ms medio de 5 posiciones; mediciones ruidosas)
| Variante | CPU render | GPU render |
|---|---|---|
| Compatibility (rama principal) | ~1,2 ms | 1,0–1,8 ms |
| Forward+ plain | ~0,35 ms | ~0,35 ms (0,35–2,3 entre corridas) |
| Forward+ SSAO | ~0,4 ms | ~0,4–1,9 ms |
| Forward+ full (SSAO + DoF) | ~0,4 ms | ~0,6–2,6 ms |
Los tiempos de GPU varían hasta ×6 entre corridas del mismo caso: **no hay conclusión fiable de que Forward+ sea más rápido o más lento**; todo está muy por debajo de los 10 ms del cuadro. El tiempo de CPU de render es menor en Forward+ (otro modelo de envío, no comparable 1:1).

## Veredicto
**No conviene cambiar el renderer por ahora.** Qué mejora: nada visible que el arte necesite (SSAO sutil, DoF dañino). Qué cuesta: reajustar color/luz de todo el nivel, riesgo de compatibilidad (Forward+ exige Vulkan/D3D12; hoy el juego corre en GL Compatibility "Windows PC" sin requisitos) y retests visuales. Si más adelante se quiere probar de nuevo: SSAO suave sin DoF, y rehacer los valores de `BeeLevel01LightProgression` para el nuevo tonemap.
