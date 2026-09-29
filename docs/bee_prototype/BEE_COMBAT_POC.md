# Bee Combat POC

## Controles

- WASD o flechas: vuelo lateral X/Y, sin gravedad.
- Z: aguijonazo corto.
- X: disparo energético con auto-aim contextual.
- R: reiniciar después de derrota.

## Combate provisional

BeePlayer conserva 100 HP, vuelo y auto-aim del primer POC. El aguijón causa 15 de daño, alcanza 0,85 m, permanece activo 0,12 s y tiene cooldown de 0,52 s.

WaspEnemy tiene 30 HP, velocidad 5 m/s y estados Idle, Chase, Windup, Attack, Recovery y Dead. Su ataque causa 10, anticipa 0,30 s y recupera durante 0,60 s.

AlienProbeRanged tiene 25 HP, busca una distancia de 5–7 m y usa Idle, Position, Windup, Shoot, Cooldown y Dead. Anticipa 0,45 s, dispara cada 1,25 s y crea un proyectil recto sin homing de 8 de daño, 6 m/s y 2,5 s de vida.

Los equipos `bee` y `alien` impiden daño propio y friendly fire. Todos los actores usan HealthComponent, DamageHitbox3D, DamageHurtbox3D e HitFlash3D.

## Polen y progresión

Cada polen se recoge aun con vida completa, suma al contador y restaura hasta 20 HP sin superar 100.

La escena contiene tres encounters secuenciales:

1. Una WaspEnemy.
2. Una AlienProbeRanged.
3. Una WaspEnemy y una AlienProbeRanged, con máximo dos enemigos simultáneos.

Al derrotar el último encuentro aparece `SECTOR ASEGURADO`. Al llegar a 0 HP se bloquean vuelo, Z y X, aparece `ABEJA DERROTADA · R — REINTENTAR`, y R recarga únicamente esta escena.

## Limitaciones

Combate fácil con proxies, sin animación final, audio, partículas, invulnerabilidad prolongada, ataques adicionales, balance final, historia ni arte Blender.