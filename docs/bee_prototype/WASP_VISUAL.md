# Wasp Enemy Visual V01

Amenaza natural sin tecnología: abdomen rayado alargado, cintura estrecha,
cabeza angular, seis patas, dos antenas, mandíbulas y aguijón puntiagudo.
Familia low-poly de BeePlayer; alas beige opacas y ojos marrón rojizo oscuro.

## Assets y reproducción
- Generador: tools/bee_prototype/create_wasp_visual.py
- Fuente: art_source/blender/levels/level_01_garden/enemies/wasp_enemy_visual.blend
- Exportación: assets/models/levels/level_01_garden/enemies/wasp_enemy_visual.glb
- Blender: ejecutar con --background --factory-startup --python-exit-code 1 --python.
- 1.014 triángulos, 28 mallas, 5 materiales; sin texturas, rig ni subdivisión.
- Largo 1,171 m (+19% frente a Bee), envergadura 1,22 m (+11%), alto 0,648 m (+17%).
- Origen en tórax; Blender +Y frontal / Z arriba pasa a Godot -Z frontal / Y arriba.
- Escala visual 1:1; collider y hurtbox originales de radio 0,38 m conservados.

## Presentación
VisualRoot/WaspEnemyVisual instancia el GLB sin lógica de combate.
El controlador conserva facing (-90° derecha / +90° izquierda), squash y muerte.
Wing_L/R baten a 19 Hz y amplitud 0,62 rad; se detienen inactivas o muertas.
No bob físico. Telegraph rojo existente y tiempos 0,30/0,12/0,60 s conservados.
HitFlash aplica overlay a las mallas importadas; muerte oculta VisualRoot.
El aguijón posterior acentúa la amenaza; las mandíbulas acompañan el ataque frontal.
No se cambió el melee ni se hizo coincidir la hitbox con el aguijón posterior.

## Inspección y prueba
Abrir scenes/bee_prototype/visuals/wasp_enemy_visual_lab.tscn y F6.
Dos facings de Wasp y Bee a igual escala; fondo neutro, alas activas.
Captura: docs/bee_prototype/wasp_visual_comparison.png.
Reproducir captura: --script res://tools/bee_prototype/capture_wasp_visual.gd.
Jugar: scenes/bee_prototype/bee_combat_poc.tscn, F6.
WASD/flechas = vuelo; Z = melee; X = disparo; R tras derrota.
Test: tests/bee_prototype/validate_wasp_visual.gd.
Valida asset, colisiones, balance, facing, alas, daño real X/Z, HitFlash,
muerte, progresión y reinicio real; no pretende evaluar calidad artística.
