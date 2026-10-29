# Tanda K — polen y controles

El cartucho de 7 granos cura 25, protege 2,5 s y duplica por 4 s cada proyectil del arma activa, con su mismo daño. Los usos se pueden encadenar cada 0,25 s y suman tiempo hasta 12 s. `BeePollenPowers.POWERS` define los efectos; `docs/POLEN_PODERES.md` explica cómo agregar otros. El HUD muestra la cuenta y el banner anuncia el poder. Spread conserva su tope de 45 s.

| Zona | Antes | Ahora |
|---|---|---|
| Nubes X=138 | Sin Spread previo específico | X=123, a 15 m |
| Escarabajos X=214 | Recarga X=222, después | Recarga X=200, a 14 m |
| Arañas X=262 | Sin Spread previo específico | X=248, a 14 m |
| Robot X=294 | Potenciador X=283 | X=282, a 12 m |
| Tras robot | Provisiones con Spread | Igual |

La zona de nubes queda con apertura de dos grupos y una oleada interna Hormiga–Nube–Hormiga. Vida de cada mosca de nube: 14 → 11 (14 × 0,75, redondeado). El bot lento de la prueba dirigida la completó en unos 12 s, con cada enemigo vivo entre 3 y 6 s. La duración queda por debajo de 35 s.

El entrenamiento aparece la primera vez antes del primer enemigo y espera mover, disparar, pirueta, puñetazo, bomba y polen. Enter o mantener A lo salta. Se repite desde Pausa > Controles. La pantalla de Controles del título usa las mismas explicaciones y agranda la letra. `BeeControlsGuide.STEPS` centraliza botón, función y momento de uso para teclado y mando; `user://bee_training.cfg` recuerda si se vio.

Para probar: iniciá una partida nueva desde el título, completá o salteá el entrenamiento, llená un cartucho y usá Q/LT. Verificá dos balas paralelas y el temporizador. Pasá por X=123, 200, 248 y 282 para ver los Spread, y repetí el entrenamiento desde Pausa. Pruebas dirigidas: `validate_bee_tanda_k.gd`, `validate_bee_tanda_k_cloud.gd`, `validate_bee_tanda_k_training.gd`, `validate_bee_tanda_k_title_controls.gd`, `validate_bee_tanda_a_pollen.gd`, `validate_bee_t3m_pollen_nova.gd`, `validate_bee_t6c_cloud.gd`, `validate_bee_tanda_e2.gd`.

El test de arranque real `validate_bee_boot_order.gd` pasó: título → nivel → robot → tarántula, cero errores capturados. Se corrieron las 25 suites históricas de Tanda E. Mantienen los fallos de aserción ya registrados; cinco recorridos largos llegaron al límite de 120 s, como en J. No aparecieron errores nuevos de parseo, recursos faltantes ni scripts. El test antiguo del roster se actualizó para esperar una sola oleada interna de nube y luego llegó a su fallo anterior sobre el hongo decorativo. Los dos tests de `tests/bee_prototype/` se relanzaron desde su ruta correcta.
