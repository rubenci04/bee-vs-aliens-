# Asset Review 01

Comparación gráfica de exactamente cinco candidatos CC0, verificados mediante licencias locales y copiados únicamente a `dev/asset_review/external/`. Biblioteca original intacta; `02_Selected_For_Game` vacío. Dimensiones AABB en unidades Godot (X × Y × Z), antes de escalar; escala original de instancia = 1. Las escalas sugeridas son exploratorias, no una convención física definitiva. Bee conserva su escala actual; humano proxy = 1,75 m.

| Asset | Proveedor | Pack | Licencia | Formato | Dimensiones | Meshes | Materiales | Escala sugerida | Evaluación |
|---|---|---|---|---|---|---|---|---|---|
| CommonTree_1 | Quaternius | Stylized Nature MegaKit[Standard] | CC0 1.0 local | GLTF | 4,311 × 7,265 × 4,578 | 1 | 2 | ×0,964; alto 7 m | APTO CON AJUSTES |
| Fern_1 | Quaternius | Stylized Nature MegaKit[Standard] | CC0 1.0 local | GLTF | 2,827 × 0,840 × 2,652 | 1 | 1 | ×2,380; alto 2 m | APTO CON AJUSTES |
| log_large | Kenney | Nature Kit | CC0 local | GLB | 1,000 × 0,417 × 0,549 | 1 | 2 | ×4,799; alto 2 m | APTO |
| flower_purpleA | Kenney | Nature Kit | CC0 local | GLB | 0,159 × 0,242 × 0,181 | 1 | 2 | ×16,495; alto 4 m | APTO |
| soda-bottle | Kenney | Food Kit | CC0 local | GLB | 0,180 × 0,580 × 0,156 | 1 | 1 | ×10,337; alto 6 m | APTO |

Triángulos/texturas: árbol 6.265/3; helecho 288/1; tronco 96/0; flor 76/0; botella 100/1. Todos sin animaciones ni colliders importados. Pivotes compensados únicamente en instancias para apoyar la geometría sobre suelo. Mediciones completas: `dev/asset_review/metrics.json`; procedencia/dependencias: `dev/asset_review/ASSET_PROVENANCE.md`.

Laboratorio: `res://dev/asset_review/asset_review_lab.tscn` (abrir y F6). Captura única: `dev/asset_review/asset_review_lab.png`. Validación gráfica y carga directa headless: código 0. Suite Bee necesaria: 7/7; Garden y Combat cargan. Mission, Garden y main scene intactos por SHA256; ninguna dependencia runtime nueva hacia Tucumán Rush. Una textura externa de botella faltó inicialmente; se copió `Textures/colormap.png` y se reconstruyó su caché importada. Logs finales sin errores/warnings. Sin Blender, commits ni cambios de gameplay.

### Mejor candidato

`soda-bottle`: silueta humana reconocible, 100 tris, un material y una textura; funciona como hito gigante frente a Bee. El contraste naranja complementa el cian alienígena. Su escala ampliada es deliberada; el humano de 1,75 m sirve como patrón dimensional, no representa una escala humana definitiva del mundo microscópico.

### Pack/familia más prometedora

Kenney Nature Kit: superficies planas, formas facetadas y poca complejidad combinan mejor con Bee/Wasp/Probe. Tronco reutilizable; flor legible aunque muy simplificada/cartoon. Food Kit comparte economía visual, pero la botella requiere comprobar saturación al colocarla en una escena real.

### Assets descartados y motivo

Ninguno descartado de esta tanda. Quaternius queda APTO CON AJUSTES: árbol con follaje texturado más ruidoso y 6.265 tris, menos conveniente para repetición densa; helecho muy liviano pero con lectura recortada/texturada que contrasta con los personajes. Evaluar escala, ubicación y contraste antes de aprobarlos para producción; no se alteraron sus materiales.

### Dirección visual sugerida

Priorizar vegetación y objetos de formas facetadas con colores contenidos; mantener el cian para tecnología alienígena. Evitar mezclar indiscriminadamente follaje texturado detallado y masas planas. Definir más adelante una relación dimensional coherente para objetos humanos; esta comparación exagera escalas para evaluar legibilidad, sin cambiar Bee.

### Próxima tanda recomendada

Revisión manual de este laboratorio para aprobar o rechazar los cinco candidatos antes de trasladar cualquiera al Garden o a `02_Selected_For_Game`.
