# Informe Lote 16 · HUD y lectura de pantalla

Trabajo realizado en `lote-17-hud`, en seis etapas: HUD gráfico con debug en F3 y nombres de botones dinámicos; mensajes de derrota y cierre sin superposición; flor toon como marca del checkpoint 2 con aro amarillo; restauración del cielo según progreso al reaparecer; encuadre con 0,35 m de margen bajo el punto terrestre configurado; y lectura de la tarántula con destello ámbar tenue y contorno dorado durante la vulnerabilidad.

La referencia de video de 10:50–11:00 no estaba en el repositorio. El código separa dos estados: el destello claro se aplicaba al recibir daño mediante `HitFlash3D`, mientras que la vulnerabilidad abre el caparazón del implante. El destello ahora usa color ámbar con alfa 0,34; el estado vulnerable activa el contorno dorado y lo restaura al cerrar la ventana.

Constantes de presentación nuevas o ajustadas en `scripts/game/bee_game_settings.gd`: panel HUD `560×200`, fila de controles `y=164`, cámara F `height=2.45`, actor terrestre mínimo `y=-0.2` y margen inferior `0.35`; destello de tarántula `Color(1.0, 0.58, 0.12, 0.34)`, contorno expuesto `Color(1.0, 0.62, 0.08, 1.0)` y grosor `0.0035`. Se mantienen configurables también las medidas del panel terminal, flor y aro del checkpoint.

Validación: la suite completa se ejecutó una sola vez: **104/110**. Se corrigieron las expectativas antiguas que dependían de las etiquetas de debug eliminadas, se añadió el refresco compatible del HUD y el estilo toon de la flor; se ajustó el rango temporal de una prueba de jefe para el encuadre nuevo. Después pasaron las pruebas dirigidas de esos casos, junto con HUD, pantalla, controles, checkpoint, encuadre y tarántula. No se repitió la suite completa.

Prueba manual: alterná teclado/ratón y mando y confirmá los nombres de botones; revisá vida, polen, bombas, pirueta y aguijón, y F3; probá derrota y reaparición antes y después del checkpoint; alcanzá el checkpoint 2; reaparecé en el 1 después de llegar al atardecer; y compará un golpe normal a la tarántula con su ventana vulnerable. Falta esa comprobación visual en ejecución con mando y con el video de referencia.

## Título e introducción · rama `lote-16-titulo-intro`

Se incorporaron las siete ilustraciones de título e introducción, conservando las originales en `imagenes_bee_nuevas/`. Las escenas miden 1672×941 px y el logo original 2752×1536 px; el recorte con transparencia está en `assets/ui/title/title_logo_cutout.png` y se puede regenerar con `tools/process_title_logo.py`. El título ahora tiene fondo a proporción, logo animado y menú con Opciones; la introducción tiene cinco escenas con zoom, texto progresivo y salto, y sus textos y duración (5,5 s) se editan en `assets/ui/intro/intro_texts.json`. Las medidas, velocidades y colores de presentación están en constantes de `scripts/game/bee_game_settings.gd`.

Validación final única: **111/111 pruebas aprobadas**. Capturas de revisión (no versionadas): `dev/lote16/title.png` y `dev/lote16/intro_01.png` a `intro_05.png`. Prueba manual recomendada: entrar por Jugar, saltar con Enter/clic/A después de 0,6 s, comprobar la entrada al nivel y luego abrir Opciones para probar dificultad, volúmenes, temblor, controles y reproducción de la introducción.
