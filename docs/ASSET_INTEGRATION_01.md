# Asset Integration 01 — Garden

Cinco modelos CC0 promovidos a `assets/external/approved/nature/` y `props/`, preservando proveedor/pack, dependencias y licencias. Procedencia completa: `assets/external/ASSET_PROVENANCE.md`. Copia curada equivalente en `D:\proyectos\V_Asset_Library\02_Selected_For_Game`: 5 modelos, 2 BIN, 5 PNG y 3 licencias; originales intactos.

| Asset | Instancias | Escala uniforme |
|---|---:|---|
| CommonTree_1 | 3 | 0,87 / 0,94 / 1,10 |
| Fern_1 | 6 | 2,00–2,50 |
| log_large | 1 | 4,799 |
| flower_purpleA | 4 | 8,247 / 15,260 / 18,144 / 21,855 |
| soda-bottle | 1 | 10,337 |

Reemplazados: tres árboles lejanos, cuatro flores proxy, rama caída y los tres volúmenes de maceta. Conservados: suelo, dos árboles lejanos proxy, tres flores proxy, pastos, piedras, hojas bajas de primer plano, naranjo y sus frutos. Composición importada aislada en `ApprovedScenery`; no depende del laboratorio. Reversible retirando el componente y restaurando sólo la decoración sustituida.

Botella: X=13, Z=-2,7, altura aproximada 6 m; referencia humana dominante detrás del plano de vuelo. Flores altas mantienen el polen cercano. Helechos detrás del plano de vuelo y árboles al fondo reducen ocultación. Quaternius conserva mayor ruido de follaje que Kenney; mezcla aceptable para esta prueba mediante separación de planos, sin recolor ni shaders. La escala insecto sigue siendo estilizada, no una proporción física definitiva.

Colisión: única caja manual del tronco, 4,799 × 2,0 × 2,636 m, centro (1;1;0), sustituye la caja anterior. Botella decorativa, sin collider; ninguna colisión de hojas/flores/árboles.

Métricas aproximadas con Compatibility a 1280×720, actores visibles: MeshInstance3D totales 200 → 169; decoración 113 → 82 piezas/instancias (67 proxies + 15 assets). Vista floral comparable: primitivas/triángulos del frame 7.466 → 19.592 y draw calls 147 → 132. Vista botella: 6.388 → 16.868 y 120 → 113; encuadre final desplazado 2 m para separar Bee/Probe, por lo que esta segunda comparación no es idéntica. Son contadores del render, no benchmark de FPS ni triángulos únicos. El coste principal es el árbol texturado (6.265 tris de malla original por instancia); limitar la repetición antes de ampliar.

Capturas finales: `dev/asset_integration/garden_flowers.png` y `garden_bottle.png`. Runtime gráfico con inputs reales: movimiento X/Y, Z melee, X disparo, recorrido completo, Wasp/Probe activos y visibles, tres pickups presentes; código 0. Suite Bee: 7/7. Cargas directas Garden y Asset Review Lab: código 0. Sin errores/warnings de Godot. Git advierte normalización LF/CRLF.

Mission 01, Combat POC, Bee/Wasp/Probe, cámara, main scene y demás archivos rastreados protegidos permanecen idénticos por SHA256. Sin Blender, commits ni pushes. Abrir `scenes/bee_prototype/bee_garden_poc.tscn` y F6; WASD/flechas, Z melee, X disparo, R tras derrota. Siguiente paso: playtest manual de claridad de combate y escala de botella; no ampliar assets todavía.
