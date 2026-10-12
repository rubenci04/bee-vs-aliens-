# BEE STYLE C APPLY 01

Estilo C (mid poly suave + toon + rim + contorno + alas translúcidas) aplicado a la abeja protagonista y a la avispa. Solo presentación: escala, hitboxes, velocidad y comportamiento no cambian.

## Qué cambió
- `assets/models/shared/bee/bee_mid_poly.glb`, `wasp_mid_poly.glb`: modelos mid poly de la prueba (4540 / 4294 triángulos; los originales tenían 1144 / 1014). Mismos nombres de nodo (`Wing_L/R`, `Stinger`, `Model`...).
- `assets/style/toon_body.gdshader`, `toon_outline.gdshader`, `toon_wing.gdshader`: shaders de la prueba, ahora en carpeta del juego.
- `scripts/style/bee_toon_style.gd` (`BeeToonStyle.apply(model, outline)`): reemplaza materiales de superficie; cachea y comparte materiales.
- `scenes/bee_prototype/bee_player.tscn` y `visuals/wasp_enemy_visual.tscn`: apuntan a los GLB nuevos. Los GLB originales de `assets/models/bee_prototype/` siguen en disco.
- `bee_visual.gd` / `wasp_enemy_visual.gd`: llaman a `BeeToonStyle.apply` en `_ready`. La avispa conserva su paleta (rojo oscuro, ojos cian con emisión).
- `scenes/levels/bee_level_01_vertical_slice.tscn`: glow activado en el Environment (umbral HDR 1.0), para ojos cian y brillo de alas. Afecta solo a lo emisivo/HDR.
- `dev/style_test/` sigue funcionando y lee shaders y modelos desde `assets/style/`.

## Costo (24 avispas en Level 01, GL Compatibility, Intel Arc B580)
| | CPU render ms | GPU ms |
|---|---|---|
| Escena vacía | 1.30 | 0.41 |
| 24 avispas originales | 2.24 | 0.45 |
| 24 avispas C con contorno | 2.52 | 0.46 |
| 24 avispas C sin contorno | 1.94 | 0.42 |

El contorno cuesta ~0.6 ms de CPU con 24 avispas (no hay tantas en pantalla en el juego real). Se deja en la avispa. Para quitarlo: `WASP_OUTLINE := false` en `scripts/bee_prototype/wasp_enemy_visual.gd`.

## Limitaciones conocidas
- GL Compatibility no tiene SSAO ni profundidad de campo; no se usan.
- Las balas son unshaded con color <= 1, por lo que no brillan con glow (no se tocó el proyectil).
