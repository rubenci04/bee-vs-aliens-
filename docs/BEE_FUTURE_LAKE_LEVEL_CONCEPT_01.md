# BEE — FUTURE LAKE LEVEL CONCEPT 01

Fecha: 2026-10-04 · Rama: `level01-garden-identity-04`. **Documentación únicamente: no hay escenas, scripts ni
assets de este nivel en el runtime.** Propuesta del usuario: un futuro nivel de agua con una rana controlada por los
aliens como gran amenaza o jefe. Este documento ordena la idea con lo que ya existe localmente y lo que faltaría.

## 1. Concepto
**"El estanque"** — Bee sigue la señal del implante hasta el borde de un estanque de jardín. Vuela sobre:
- la **orilla** (piedras, totoras, barro, juguetes olvidados);
- el **espejo de agua** (nenúfares que flotan, reflejos, insectos que patinan);
- un **jardín acuático** (macetas sumergidas, una canoa de juguete, una manguera).

Escala: un nenúfar es una plataforma de 6–8 m; una gota que cae es un proyectil; la rana es un monstruo.
Lectura de juego igual que Level 01: plano X/Y, scroll lateral, cámara E. El agua es un **suelo peligroso**
(salpicaduras, cosas que emergen), no un nuevo sistema de nado.

## 2. Jefe: la rana controlada por implante
- **Narrativa**: la rana no es el enemigo; un **dispositivo de control** está pegado a su cabeza/lomo. Objetivo:
  destruir el dispositivo. La rana **no muere**: al romperlo, se calma y se hunde/salta lejos (mismo lenguaje que la
  libélula liberada de Level 01).
- **Asset base**: Quaternius Frog (CC0, ya importado) con clips `Idle` 2,5 s, `Jump` 0,88 s, `Attack` 0,75 s,
  `Death` 0,83 s. No tiene nadar ni lengua articulada: la lengua sería una pieza procedural (como la columna de la
  araña).
- **Patrones posibles** (no implementados; elegir 3 como máximo para la primera versión):
  | Patrón | Telegraph | Qué exige |
  |---|---|---|
  | Lengua (tongue strike) | la boca se abre + línea que marca la dirección, se fija antes de disparar | cambiar de altura / salir de la línea |
  | Salto + salpicadura (splash) | se agacha (anticipación ya usada en el evento de la rana) | anillo de gotas que suben: buscar el hueco |
  | Desplazar nenúfares | ondas en el agua hacia una plataforma | la cobertura cambia de lugar |
  | Invocar insectos controlados | el implante pulsa cian | prioridad: limpiar enjambre vs dañar el dispositivo |
- **Fases** (como el OVNI): 1 lengua sola → 2 lengua + salto → 3 todo con menos pausa. Barra de vida = del
  dispositivo, no de la rana.

## 3. Otra fauna del nivel (sin inflar el roster)
| Criatura | Asset local | Estado | Rol posible |
|---|---|---|---|
| Serpiente de agua | Quaternius Snake / Snake_angry (CC0) | listo (Idle/Walk/Attack/Jump) | emerge del agua y muerde en arco: amenaza baja |
| Cangrejo | Ultimate Platformer Pack Crab (CC0) | listo (10 clips) | anfibio de orilla, cruza y muerde |
| Mosquito | — | **no hay modelo** | popcorn orgánico del nivel (encargar o modelar simple) |
| Libélula | procedural (Level 01) | existe | fauna liberable, encaja perfecto en el estanque |
| Ave futura | búho Free Wild (licencia por verificar, sin clips) | no usable aún | depredador que pica desde arriba |
| Araña | Quaternius Spider (CC0, en uso desde este pase) | existe | colgando de las totoras |

Recomendación: rana (jefe) + serpiente + cangrejo + mosquito como popcorn + libélula. Nada más en la primera versión.

## 4. Assets locales reutilizables (ya verificados CC0)
- Kenney Nature Kit: `lily_large`, `lily_small`, `ground_river*` (piezas de río/orilla), `canoe`, `canoe_paddle`,
  `cliff_waterfall_*`, `platform_beach`, `plant_flatTall`, rocas.
- Tiny Treats House Plants: macetas, platos y regaderas (jardín acuático doméstico), hojas grandes.
- KayKit Forest: arbustos, pasto, 43 rocas para la orilla.
- Audio (Sonniss, royalty-free): lago "Summer Tennessee Lake Dock" (103 s), olas de lago glacial (92 s, 4 canales),
  croar sintético (2,3 s), gorgoteo de criatura acuática (4,2 s), impacto de agua sci-fi (1,2 s), burbujas (0,9 s).

## 5. Lo que falta (no existe localmente)
- **Shader de agua propio** (superficie con ondas y reflejo falso, compatible con GL Compatibility y Style C). El agua
  de Kenney es translúcida y el toon la vuelve opaca. No requiere plugin: es un shader corto.
- Totoras / juncos con licencia segura (los de `modular_terrain_collection` no tienen licencia).
- Mosquito, pez y zapatero de agua.
- Animación de lengua y de "hundirse" de la rana (procedural en Godot).
- Música del nivel (ver `docs/BEE_LEVEL01_MUSIC_BRIEF_01.md` como plantilla).

## 6. Riesgos y reglas
- Es un **Level 2+**: no empezar hasta que Level 01 cierre su playtest (criterios de
  `docs/BEE_PROJECT_VIABILITY_REVIEW_01.md` §7).
- No convertir el agua en un sistema de nado ni de física: es escenario + hazards telegrafiados.
- Mantener el principio de liberación: la fauna controlada se libera, no se mata.
