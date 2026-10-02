# Procedencia y aprobación: Alien + Robot Walker

**Verificación:** 2026-09-30 (UTC−03:00). **Alcance:** procedencia/licencia y copias byte a byte; sin integración de gameplay. La [auditoría local de `extras`](EXTRAS_ASSET_LIBRARY_AUDIT.md) sigue describiendo correctamente la ausencia de licencia **dentro de la biblioteca** al momento de esa auditoría. La [revisión visual](EXTRAS_SCIFI_VISUAL_REVIEW_01.md) conserva su evaluación `APTO CON AJUSTES` para ambos modelos.

| Dato | Alien | Robot Enemy Legs Gun |
| --- | --- | --- |
| Autor / proveedor | Quaternius / Poly Pizza | Quaternius / Poly Pizza |
| ID exacto | `sUTLXji0aL` | `lFZfDh2hzP` |
| Ficha directa | https://poly.pizza/m/sUTLXji0aL | https://poly.pizza/m/lFZfDh2hzP |
| Evidencia externa | La ficha identifica **Alien**, **Quaternius**, formato FBX/GLTF y **Public Domain (CC0)** | La ficha identifica **Robot Enemy Legs Gun**, **Quaternius**, formato FBX/GLTF y **Public Domain (CC0)** |
| Licencia verificada | CC0 / dominio público, **externamente** | CC0 / dominio público, **externamente** |
| `License.txt` local archivado | **No existe**; no se fabricó | **No existe**; no se fabricó |
| Archivo original | `D:\proyectos\V_Asset_Library\01_Extracted\extras\Alien by Quaternius - sUTLXji0aL.glb` | `D:\proyectos\V_Asset_Library\01_Extracted\extras\Robot Enemy Legs Gun by Quaternius - lFZfDh2hzP\Enemy_2Legs_Gun.fbx` |
| Copia aprobada Bee | `res://assets/external/approved/alien_ground/quaternius/Alien_sUTLXji0aL/Alien by Quaternius - sUTLXji0aL.glb` | `res://assets/external/approved/alien_ground/quaternius/Robot_Enemy_Legs_Gun_lFZfDh2hzP/Enemy_2Legs_Gun.fbx` |
| Copia seleccionada biblioteca | `D:\proyectos\V_Asset_Library\02_Selected_For_Game\quaternius\Alien_sUTLXji0aL\Alien by Quaternius - sUTLXji0aL.glb` | `D:\proyectos\V_Asset_Library\02_Selected_For_Game\quaternius\Robot_Enemy_Legs_Gun_lFZfDh2hzP\Enemy_2Legs_Gun.fbx` |
| SHA-256: original = Bee = biblioteca | `9EB262825E32CE95207243890A980FF4722E6FD6C443EF62AAC520E3BC996310` | `F220D7D9B9D7E18BE35CB8D5AE1BA4E12037E48C5A9ED4CD2FBF6830273E297A` |
| Dependencias copiadas | Sólo GLB autocontenido | Sólo FBX; ninguna dependencia auxiliar necesaria identificada |
| Estado final | **APROBADO como asset fuente**; no integrado | **APROBADO como asset fuente**; no integrado |

**Correspondencia con el archivo local.** Cada ruta original incluye el ID exacto de su ficha pública y el nombre/autor concordantes. La revisión técnica independiente importó el GLB Alien con 2 meshes, 2.616 tri, rig y 9 clips, y el FBX Walker con 2 meshes, 4.722 tri, rig y 7 clips; ambos renderizaron en Godot. Las fichas públicas no publican un hash de descarga: esa correspondencia es razonable por ID, nombre, formato y contenido, pero no constituye una comparación criptográfica con el servidor. Los hashes anteriores prueban únicamente que **las copias locales son idénticas a los originales locales**.

No se copiaron otros modelos, páginas web completas ni packs. Las copias del Visual Lab en `res://dev/extras_scifi_review/source/` siguen siendo temporales y no son una ruta de integración. Pivot, escala, orientación, materiales, rig y animaciones permanecen intactos. La aprobación de procedencia no aprueba todavía adaptación visual ni comportamiento de enemigo.
