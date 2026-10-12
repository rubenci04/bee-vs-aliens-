# Bee alien visual — primera presentación low-poly

Modelo reproducible: tools/bee_prototype/create_bee_visual.py.
Fuente: art_source/blender/shared/bee/bee_alien_visual.blend.
Exportación: assets/models/shared/bee/bee_alien_visual.glb.

1.144 triángulos, 35 piezas, seis materiales planos, sin texturas ni rig.
Abeja dorada con bandas oscuras, cabeza grande, seis patas de dos segmentos,
antenas gruesas y aguijón posterior. Implante de metal y cian, placa levantada
y cable interrumpido. Alas opacas celestes para una importación robusta.

Origen en tórax. Blender +Y frontal pasa a Godot -Z; VisualRoot usa la misma
rotación Y que BeePlayer: -90 grados para derecha y +90 para izquierda.
Dimensiones en reposo: largo 0,981 m, envergadura 1,10 m y alto 0,556 m (incluye apéndices). El cuerpo queda cerca del volumen del proxy. Collider original de radio 0,28 sin cambios.

Wing_L y Wing_R son piezas independientes con pivots en bisagras. bee_visual.gd
bate las alas a 16 Hz y 0,55 radianes, deteniéndose al morir. No bob ni movimiento
del cuerpo físico. El aguijón es presentación: la hitbox frontal Z sigue intacta.

Captura bee_visual_facings.png renderizada por Godot. Se conservaron controlador,
vida, daño, input, cámara y escenas de Flight/Combat. Visual Lab: scenes/bee_prototype/visuals/bee_player_visual_lab.tscn (F6).


Cierre V01: fuente y GLB existentes conservados, sin regenerar ni rediseñar.
Visual Lab presenta ambos facings a escala original sobre fondo neutro, con
batido activo y actores inmóviles. La captura se reproduce con
tools/bee_prototype/capture_bee_visual.gd.
Abrir bee_combat_poc.tscn y pulsar F6 para jugar: WASD/flechas, Z melee, X disparo,
R tras derrota. El disparo nace delante de la cabeza; el implante es decorativo.
El aguijón posterior es legible, pero no representa la hitbox frontal del melee.
No se agregó animación de aguijón ni se cambió el ataque existente.

Validación de cierre: 37/37 scripts aprobados, incluidos Bee Visual, Bee Flight
y Bee Combat (restart real conserva BeeVisual). Flight y Combat ejecutados con
render OpenGL en Godot 4.7.2, salida 0. Captura del laboratorio revisada en ambos
facings. No se realizó una partida manual completa ni se evaluó arte por tests.
