# Bee Garden POC
Objetivo: probar vuelo y combate dentro de un jardín/naranjal enorme a escala
de insecto. Recorrido lateral de 30 m (X -15 a +15), altura 0,7–8,2 m, Z fijo.

Composición: zona floral inicial, Wasp, vegetación intermedia, Probe y naranjo
en maceta gigante. Tres flores principales rosada/ocre/violeta, dos grupos
secundarios de dos flores, tallos/hojas, 16 matas de pasto, piedras, tierra,
rama caída y fondo rural apagado. Foreground bajo y escaso para no tapar combate.
Naranjo sugerido con ramas, tres masas de follaje y siete frutos naranjas.
La maceta es la referencia de escala humana; no es arte final.
114 instancias decorativas / 18 mallas compartidas. Colisiones sólo en suelo
y rama; límites por parámetros de la instancia BeePlayer. No collider en hojas.
Wasp se activa en X -7; Probe en X +4. Un ejemplar de cada enemigo.
Tres polenes junto a flores: X/Y = -11/4.3, -3/5.9 y 6/4.9, siempre Z=0; curación original de 20 HP.
Cámara BeeArcadeCamera original, FOV 48°, distancia Z 13, mismo seguimiento.
Luz diurna sencilla, sin sombras, shaders ni postprocesado adicionales.

Abrir scenes/bee_prototype/bee_garden_poc.tscn y F6.
WASD/flechas = vuelo; Z = melee; X = disparo; R después de derrota.
Reinicio recarga escena y restablece enemigos y pickups.
Limitaciones: geometría proxy creada al cargar (no visible antes de ejecutar),
sin objetivo final ni encadenamiento de niveles, sin arte final ni audio.

