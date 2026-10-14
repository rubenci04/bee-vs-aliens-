# T3g — Atajos seguros, valores fijos y pickups unificados

Rama `lote-16-titulo-intro`. Cambios localizados de presentación; no cambia el balance del arma, recompensas, condiciones de aparición, vida/daño ni colisiones.

## Teclas y modo desarrollo

| Comparador | Tecla nueva, sin modificadores | Default | Opciones |
|---|---|---|---|
| Tamaño visual de Bee | 9, fila superior | 1,40 | 1 / 1,25 / 1,40 |
| Contorno | 0, fila superior | 1, fino, 1,2 px | apagado / fino / grueso |
| Fondo lejano | I | 1 | 0 / 1; eliminado el gris del nivel 2 |
| Neón | J | 1 | 0 / 1 / 2 |

Se revisaron Input Map y controles de scripts cargados por gameplay. 9/0/I/J están libres. Las teclas 7/8 del ejemplo se descartaron porque la [tabla oficial de atajos del editor Godot 4](https://docs.godotengine.org/en/4.6/tutorials/editor/default_key_mapping.html) también las lista para TileSet. 9/0/I/J sin modificadores no aparecen como atajos en esa tabla. Los laboratorios de arte separados usan números en algunas escenas, pero no se ejecutan dentro del Nivel 1. El handler rechaza Ctrl/Alt/Shift/Meta para no interceptar combinaciones del editor. No asigna F1–F12 a estos comparadores.

La línea DEV muestra las teclas nuevas. Solo se crea en el binario editor/debug; las exportaciones standalone debug y release quedan excluidas, incluso con el antiguo argumento `--debug-readability`. La presentación definitiva se aplica también en exportados; allí no existe el panel ni se aceptan cambios mediante teclas o `set_modes()`. Valores en `scripts/game/bee_readability_settings.gd`. La hitbox de Bee y la boca física del disparo no escalan con el modelo.

F5/F6/F7/F8 conservan sus funciones de ejecutar/ejecutar escena/pausar/detener del editor. Abrir la ventana del juego y darle foco antes de usar los comparadores nuevos.

## Pickups

| Familia/ruta | Cambio |
|---|---|
| Spread toon / S+ toon | Medallón con flecha existente, conservado |
| Bomba toon | Ícono cálido con círculo rosa existente, conservado |
| Polen / racimo ×10 | Orbes dorados y halos existentes, conservados |
| Spread base dinámico / S+ base | Viejo S+cono celeste oculto; hexágono con anillo azul real y glifo triple marfil |
| Bomba base dinámica | Viejo B+esfera celeste oculto; hexágono con anillo ámbar y bomba/mecha marfil |

Inventario completo de escenas, scripts, formas, colores y cantidades: `docs/INVENTARIO_PICKUPS.md`. El problema eran recompensas dinámicas que instanciaban la escena base y no pasaban por el reemplazo de los fijos. El hook existente de Nivel 1 ahora las viste al aparecer. Misma flotación de los modernos, brillo/halo suave y borde claro; sin letras de prototipo, sin anillos cian/magenta/verde neón. No se borraron modelos ni escenas. `docs/pickups_antes_despues.png` compara las ocho variantes en ambas luces.

## Verificación

Cinco pruebas dirigidas aprobadas: `validate_bee_t3g`, `validate_bee_live_readability`, `validate_bee_weapons_powerups_v01`, `validate_bee_items_shots_v04`, `validate_bee_tanda4c_weapons`. Sin suite completa. Se corrigió una anotación de tipo del test nuevo; la prueba antigua de objetos exigía la estela anterior a T4c y apuntaba a un enemigo fuera de pantalla sin actualizar el selector headless. Se ajustaron esos fixtures y se repitieron solo los afectados, sin modificar gameplay para satisfacerlos.

Checks: puerta de acceso editor/export, teclas nuevas y ciclos, defaults, eliminación del fondo 2, invariancia de hitbox/boca de disparo, rediseño automático de cápsulas dinámicas, recurso/radio de colisión original de 0,55 m, recolección de +3 bombas y 20 s de Spread, contratos previos de armas y objetos.

También se abrió el Nivel 1 con GPU y se disparó con neón 0, 1 y 2 (`LEVEL_NEON_OK` en cada caso), sin errores en consola. Se exportó y revisó la comparación de pickups. La exclusión de builds exportadas se valida por la puerta de features y pruebas de ambos perfiles; no se generó un nuevo ejecutable exportado durante esta tanda. Algunas pruebas mantienen avisos de recursos al cerrar Godot, sin errores de script ni aserciones finales.

## Qué mirar / pendientes

- Pulsar 9/0/I/J dentro del juego y comprobar que sigue abierto; I debe volver de 1 a 0 sin tercer valor.
- Comparar Bee ×1,40 y contorno fino; comprobar fondo 1 y neón 1 al iniciar.
- Tras el robot, revisar que bomba y Spread de recompensa ya son medallones con glifos; en tope 5, la bomba debe quedarse disponible.
- Mirar `pickups_antes_despues.png` de día/noche. Validación estética final del desarrollador pendiente; no quedan pasos de implementación de este prompt.

Se incluyen las adendas locales 2 y 4 solicitadas. La adenda 3 y otros archivos ajenos permanecen fuera del commit.
