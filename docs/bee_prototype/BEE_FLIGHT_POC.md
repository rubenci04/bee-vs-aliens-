# Bee Flight POC

## Objetivo

Validar en menos de dos minutos el loop vuelo arcade, recolección de polen, auto-aim contextual y disparo contra una sonda aérea.

## Controles y plano de movimiento

W/flecha arriba aumenta Y en pantalla; S/flecha abajo reduce Y; A/D o flechas mueven en X. El movimiento ocurre en el plano lateral X/Y con Z fijado en 0, sin gravedad ni salto. X dispara.

BeePlayer usa CharacterBody3D para movimiento aéreo con colisiones: 7 m/s horizontal, 6 m/s vertical, aceleración 32 m/s² y desaceleración 40 m/s². El área se limita a X -10..10 e Y 0,7..7,2.

## Cámara y combate

BeeArcadeCamera conserva vista lateral, Z fijo a 13 m, suavizado 5,5 y 2,3 m de espacio delante según facing. No rota.

El auto-aim evalúa enemigos activos, vivos y visibles dentro de 12 m y un cono frontal total de 80°. Puntúa distancia y desviación angular; muestra un rombo sutil sobre el mejor candidato. X calcula una dirección inicial hacia ese punto. El proyectil energético continúa recto y no tiene homing. Sin candidato dispara horizontalmente según facing.

La sonda proxy patrulla lateralmente, tiene 25 HP y muere con tres impactos de 10. BeePlayer tiene 100 HP; la sonda todavía no ataca.

## Escala y loop

BeePlayer mide aproximadamente 0,6 m visuales, las flores 1,3–1,8 m y la sonda cerca de 1 m. Es escala de gameplay, no científica.

Loop: volar, recoger tres pólenes, entrar en rango de la sonda, ver el indicador, disparar y eliminarla. Se reutilizan HealthComponent, DamageHurtbox3D, DamageHitbox3D y HitFlash3D. Son nuevos el controlador aéreo, cámara, auto-aim, proyectil energético, sonda proxy y polen.

Limitaciones: geometría proxy, un enemigo sin ataque, sin audio, partículas, historia, upgrades, guardado ni arte final.