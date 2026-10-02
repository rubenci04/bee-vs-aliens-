# Inventario de flora — Pass 01

Inspección local 2026-09-30. Se buscaron nombres de flora, colores, modelos, escenas, materiales y procedencia en Bee y en 01_Extracted/02_Selected_For_Game. No se modificó otra copia de proyecto. "CC0" en un nombre no acredita por sí solo la licencia.

## YA APROBADO / USABLE

Raíz K: `D:\proyectos\V_Asset_Library\01_Extracted\kenney\kenney_nature-kit\Models\GLTF format\`.
Destino K: `D:\proyectos\bee_alien_3d\assets\external\approved\nature\kenney\kenney_nature-kit\Models\GLTF format\`.

| Nombre | Formato / dimensiones nativas (m, X/Y/Z) | Procedencia / aprobación | Uso |
| --- | --- | --- | --- |
| K/flower_purpleA | GLB; 0,159/0,243/0,181 | Kenney Nature Kit; CC0 License.txt local; ya aprobado | Azul/violeta conservado; escala 12–20 |
| K/flower_purpleB | GLB; 0,207/0,209/0,239 | Mismo CC0; promovido ahora | Flor abierta violeta; escala 12–20 |
| K/flower_redA | GLB; 0,159/0,293/0,181 | Mismo CC0; promovido ahora | Zona humana/acentos rojos; escala 12–20 |
| K/flower_yellowA | GLB; 0,159/0,193/0,181 | Mismo CC0; promovido ahora | Inicio; flor amarilla alta; escala 12–20 |
| K/flower_yellowB | GLB; 0,207/0,159/0,239 | Mismo CC0; promovido ahora | Grupos amarillos bajos/abiertos; escala 12–20 |
| recovered_garden_rose | TSCN; 3,259/3,355/0,745 | Geometría original Godot del proyecto, reutilizada | Rosada de cinco pétalos; escala 0,75–1,25 |
| K/flower_purpleC, redB/redC, yellowC | GLB; escala aún no calibrada | Mismo pack CC0; disponibles, no promovidos | Variantes futuras; no copiar pack entero |
| Flower_3/4_Single/Group | glTF + bin/texturas; escala por calibrar | Quaternius Nature MegaKit; CC0 local; no promovidos | Cuatro modelos de biblioteca útiles si hacen falta |
| Fern_1 / CommonTree_1 | glTF; escala 0,6–2,6 aprox. | Quaternius, CC0 local; ya aprobados | Vegetación baja y profundidad |

Raíz Quaternius: `D:\proyectos\V_Asset_Library\01_Extracted\quaternius\Stylized Nature MegaKit[Standard]\glTF\`; licencia en raíz del pack. Las carpetas seleccionadas contienen copia de purpleA, árbol y helecho; se añadieron sólo cuatro flores Kenney verificadas.

Flores antiguas: `scripts/bee_prototype/bee_garden_poc.gd`, función flower y llamada "rose": tallo CylinderMesh, hojas/pétalos SphereMesh, rosado (0,72;0,34;0,43), centro ocre. Escena `scenes/bee_prototype/bee_garden_poc.tscn`. Materiales/proxies de flores también en bee_flight_poc y bee_combat_poc; BEE_GARDEN_POC documenta la paleta inicial rosada/ocre/violeta. Se recuperó la flor rosada comprobable en el código actual como `scenes/decoration/recovered_garden_rose.tscn`; sin editar esos POCs. Aprobación, rutas y hashes: `assets/external/ASSET_PROVENANCE.md`.

## EXISTENTE PERO SIN PROCEDENCIA CLARA

Los GLB nuevos sin evidencia de licencia se detallan abajo. También existe el .blend Coniferous de `01_Extracted/nuevos`, ya pendiente en la auditoría previa; no se usa ni bloquea la mejora.

## NUEVO EN flores

Ruta común: `D:\proyectos\V_Asset_Library\01_Extracted\flores\`.
Recursión: **15 archivos, todos GLB**; sin subdirectorios, .blend/.fbx/.obj, README, LICENSE ni manifest. Texturas embebidas; ninguna URI externa detectada. JSON asset/extras no contiene evidencia de autor/licencia. Todos encontrados; todos **PENDIENTE DE VERIFICACIÓN**, no utilizables/promovidos ahora. Autor que aparece abajo proviene del nombre, no está autenticado. Escala de estos candidatos sin validar en Godot.

| Archivo / pack inferido | KiB / texturas | Licencia clara | Uso sugerido tras verificar |
| --- | ---: | --- | --- |
| eiacreations-tulip-5441.glb | 8223 / 1 | No | Tulipán; revisar costo/materiales |
| gal-b-water-lily-4370.glb | 456 / 2 | No | Nenúfar sólo en zona acuática |
| mohamed_hassan-sunflower-4398.glb | 6459 / 2 | No | Girasol focal, no masa |
| mohamed_hassan-tulip-4418.glb | 6958 / 2 | No | Tulipán, revisar costo |
| plaggy_cc0-plant-pot-573.glb | 13726 / 3 | No; nombre CC0 insuficiente | Maceta: 2–5 en zona humana; revisar costo |
| quaternius_cc0-cactus-flower-778.glb | 65 / 1 | No; nombre CC0 insuficiente | Cactus puntual/maceta o futuro nivel |
| quaternius_cc0-cactus-flower-779.glb | 88 / 1 | No | Igual; no jardín masivo |
| quaternius_cc0-cactus-flower-780.glb | 44 / 1 | No | Igual |
| quaternius_cc0-flower-1014.glb | 5 / 1 | No | Planta/flor verde; inspección visual pendiente |
| quaternius_cc0-flower-1016.glb | 14 / 1 | No | Flor cian/verde candidata |
| quaternius_cc0-flowers-1020.glb | 24 / 1 | No | Grupo de flores cian/amarillas |
| quaternius_cc0-flowers-crop-1018.glb | 9 / 1 | No | Cabezas/flor cosechada; evaluar tallo |
| quaternius_cc0-flowers-harvested-1019.glb | 6 / 1 | No | Planta/flor verde; inspección pendiente |
| quaternius_cc0-sakura-flower-901.glb | 54 / 1 | No | Acento sakura; revisar textura |
| tilixia-summer-tulip-4376.glb | 1535 / 1 | No | Tulipán focal candidato |

No se encontró archivo "stem" independiente. Los candidatos a piezas verdes/tallos no se combinaron: primero falta evidencia de licencia y lectura visual. No se abrió Blender.

## DESCARTABLE / POCO ÚTIL PARA ESTA PASADA

Isometric previews y duplicados OBJ/FBX no agregan modelos jugables frente al GLB disponible. Cactus/nenúfares no corresponden a la composición masiva del jardín actual. Maceta de ~13,4 MiB y tulipanes/girasol de 6–8 MiB quedan reservados; tamaño no prueba densidad, requieren evaluación. No se borró nada.
