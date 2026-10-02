# Bee SHMUP Ground Threat POC

Escena aislada: `res://scenes/bee_prototype/bee_shmup_ground_threat_poc.tscn`. Reutiliza stage, cámara lateral y naturaleza aprobada del SHMUP Core. No mezcla enemigos aéreos ni modifica POC previos.

## Asset, apoyo y licencia

`turret_single.glb`, Kenney Space Kit (2.0). Licencia local `License.txt`: **CC0**, confirmada antes de copiar. Sólo GLB autocontenido y licencia se promovieron al proyecto y a `02_Selected_For_Game`; rutas exactas en `res://assets/external/ASSET_PROVENANCE.md`. No se usó Blender ni se editó el modelo.

AABB importado original: **0,60 × 0,90 × 0,72 m** (X/Y/Z); mínimo (1,70; 0,00; 1,13), centro (2,00; 0,45; 1,49) por pivote de exportación desplazado. Escala de instancia **1,50**; volumen aproximado **0,90 × 1,35 × 1,08 m**. `ModelPivot` compensa X −2 y Z −1,5 antes de escalar; la raíz del enemigo está a Y −0,2, con los pies apoyados en la superficie visual. Frente original −Z girado +90° hacia Bee a la izquierda; VisualRoot puede girar en Y si Bee cambia de lado. El cañón se representa visualmente; no se anima por huesos.

## Patrón y valores provisionales

IDLE visible pero inactivo → TRACK al activarse → WINDUP naranja **0,65 s** → un SHOOT → COOLDOWN **1,6 s** → TRACK; DEAD cancela disparos/telegraph y desactiva collider/hurtbox. No se desplaza. Rango **9 m**, **30 HP**, proyectil recto existente `AlienEnemyProjectile` configurado a **9 HP**, **6,5 m/s**, vida **2,5 s**. El disparo toma la posición actual de Bee una sola vez; no es homing. La torreta usa Health, Hurtbox y HitFlash Bee. X y melee bajo la torreta pueden dañarla; auto-aim actual la adquiere desde una trayectoria baja dentro de su cono y rango. La marca cian queda encima; el aviso naranja se aparta hacia el lado del cañón para no cubrir la silueta.

Tres encuentros a X aproximadamente **13 / 30 / (47 y 54) m**, activados por scroll a 5,5 / 22 / (39 y 46) m, esperando que el encuentro anterior se resuelva por destrucción o por quedar atrás del borde izquierdo. Máximo **dos torretas activas**. Sector **62 m**, scroll **2,0 m/s**, cuatro polen opcionales. Tras resolver las cuatro torretas y completar la distancia aparece `SECTOR DESPEJADO`; R tras derrota recarga todo. La botella gigante heredada se oculta sólo en este POC para despejar la lectura del suelo.

## Validación y límites

Test dedicado: `res://tests/bee_prototype/validate_bee_shmup_ground_threat_poc.gd`; comprueba escena, auto-aim hacia abajo, windup/shot, impacto, trayectoria fija, cooldown, daño/HitFlash/melee, muerte, máximo activo, progresión, final y restart. Capturas con render: `res://dev/ground_threat_review/turret_windup.png` y `turret_projectile.png`.

Valores, ubicación y ritmo son provisionales hasta un playtest humano. El modelo conserva su paleta Kenney, diferente del lenguaje alien final. El proyectil no colisiona con todo el decorado; sólo aplica el contrato actual de hitbox/hurtbox. Dejar una torreta atrás la desactiva sin contarla como derrota y permite avanzar; no da recompensa.

