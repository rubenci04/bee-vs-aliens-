# Alien Probe Visual V01
Sonda de vigilancia hostil: carcasa facetada, sensor único frontal, emisor corto,
núcleo inferior y tres estabilizadores. Comparte metal gris verdoso y cian
(.04, .75, .71) con el implante de Bee. Sin alas, texturas, rig ni postprocesado.

- Generador: tools/bee_prototype/create_alien_probe_visual.py.
- Fuente: art_source/blender/bee_prototype/alien_probe_visual.blend.
- GLB: assets/models/bee_prototype/alien_probe_visual.glb.
- 920 triángulos, 18 mallas, 5 materiales.
- Largo 1,215 m; ancho 1,22 m; alto 0,65 m. Escala 1:1.
- Bee: 0,981 / 1,10 / 0,556 m; Wasp: 1,171 / 1,22 / 0,648 m.
  Probe es aproximadamente 4% más larga que Wasp y 24% más larga que Bee.
- Blender +Y frontal / Z arriba; Godot -Z frontal / Y arriba. Pivot central.
- Collider/hurtbox originales: radio 0,55 m, sin cambios.

## Integración
AlienProbeRanged/VisualRoot/AlienProbeVisual contiene el GLB y observa el target.
Su script sólo modifica transformaciones de presentación: orientación hacia
izquierda/derecha, inclinación hacia la altura del objetivo, bob de 0,015 m
a 1,4 Hz y giro lento del collar inferior (0,8 rad/s).
No modifica target, IA, cuerpo físico, daño ni proyectiles.
La animación se detiene inactiva/muerta; el actor oculta VisualRoot al morir.
El telegraph magenta existente y squash de WINDUP siguen a cargo del actor.
HitFlash recorre todas las mallas del modelo. Emisión cian suave de 1,2, sin bloom.

## Límites V01
El emisor es presentación: proyectil nace en el centro original y emerge por
el frente; no se ajustó su spawn. La orientación visual acompaña al target;
los proyectiles mantienen su dirección inicial, sin homing.
El telegraph original cubre parte de la silueta durante la anticipación.
No hay animación de muerte, partículas ni animaciones óseas.

## Inspección
Abrir scenes/bee_prototype/visuals/alien_probe_visual_lab.tscn y F6.
Compara Bee, Wasp y los dos perfiles de Probe a igual escala.
Captura: docs/bee_prototype/alien_probe_comparison.png.
Reproducir con --script res://tools/bee_prototype/capture_alien_probe_visual.gd.
Jugar scenes/bee_prototype/bee_combat_poc.tscn con F6:
WASD/flechas, Z melee, X disparo, R tras derrota.
Test específico: tests/bee_prototype/validate_alien_probe_visual.gd.
Comprueba geometría importada, facing, separación física/visual, estados reales,
proyectil, daño X/Z, HitFlash, muerte, progresión, restart y carga del laboratorio.

## Cierre
Godot 4.7.2: importación y arranque gráfico de Combat con salida 0.
Test específico aprobado tanto headless como con render.
Suite completa: 39/39, cero regresiones; ver probe_suite_summary.log.
Captura comparativa revisada en ambos perfiles. La validación runtime automatizada
no sustituye un playtest manual de legibilidad a velocidad normal.
Blender 5.2.1 exportó con salida 0; avisos de rutas relativas de pinceles incluidos
en Blender, ajenos a las mallas/materiales exportados.
