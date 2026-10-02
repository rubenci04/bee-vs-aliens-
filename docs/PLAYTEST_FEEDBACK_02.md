# Level 01 — Playtest Polish Pass 01

Human feedback: level/environment too empty; long waits between enemies; straight flight; few obstacles; desire for breakable objects; enemies dying too quickly; white rectangle underneath giant-human shoes.

## Verified changes

| Metric | Before | After |
| --- | ---: | ---: |
| Length / scroll | 360 m / 2 m/s | unchanged |
| Events (including human) | 9 | 14 |
| Enemies / peak active | 10 / 2 | 17 / 2 |
| Optional pollen | 13 | 17 |
| Dedicated destructibles | 0 | 8 wooden crates, 24 HP |
| Scenery placements | 46 | 206 |
| Mean encounter gap, travel only | 18.875 s | 11.615 s |
| Maximum encounter gap | 25 s | 16 s |

Original thresholds: 28, 78, 108, 140, 185, 216, 252, 294, 330 m. Original gaps: 25, 15, 16, 22.5, 15.5, 18, 21, 18 s. Longest dead zones were 28–78 and 140–185 m.

Current thresholds: 28, 52, 78, 108, 140, 163, 185, 216, 234, 252, 274, 294, 313, 330 m. Gaps: 12, 13, 15, 16, 11.5, 11, 15.5, 9, 9, 11, 10, 9.5, 8.5 s. Crates, low-flight rocks and optional pollen occupy the remaining long intervals. Across all authored interaction opportunities, including entry/end, the greatest gap is 9.5 s. This measures opportunities, not mandatory activity.

Level-only HP: Wasp 30→36 (+20%); Probe 25→32 (+28%); EyeDrone 18→24 (+33%); Speeder 23→30 (+30%); Turret 30→40 (+33%); Organic Alien 35→47 (+34%); Walker 45→60 (+33%). Bee damage and enemy attack values remain unchanged. The seven base enemy scenes remain unchanged.

Eight crates use existing HealthComponent, Hurtbox and HitFlash with solid collision; two Z hits or three X hits break a 24-HP crate. Death hides the mesh and disables collision/hurtbox once. Each offers an overhead alternative; none gates progression. Primitive rocks vary low flight. The approved hollow log remains traversable. New decoration: 45 flowers, 81 ferns, 16 trees and 18 primitive rocks. No library imports or Blender execution.

White rectangles were actual skinned meshes `Rig/Skeleton3D/SoleL` and `SoleR`, using `BottleLabelSoles`, each ~0.23×0.04×0.36 m before 6× scaling. They were not shadows, decals or missing textures. The level-specific human script hides those two slabs; BootL/BootR already extend to local Y=0. Run, skeleton, scale, contact hitboxes, gap and source GLB remain intact. Render review confirms rounded boots without the rectangular plates.

## Validation and limits

Integrated headless/render tests passed and cover real threshold progression, 14 events, 17 enemies, max two, local HP, X/Z destruction, blocked/freed route, rock overhead route, human gap, hollow log, final and R restoration. Direct scene loads returned code 0 in headless and OpenGL3. Complete Bee suite: 17/17, no script errors or regressions. Automated encounters are cleared through health damage; this verifies sequencing, not real combat duration or difficulty. Accelerated test time 25.3 s headless / 25.8 s render at test-only 24 m/s is not human playtime. Authored duration remains 180 s travel + ~9.5 s crossing + combat/navigation. Human 3–5 min target and increased resistance require another user playtest.

Final encounter remains Probe + Turret at 330 m, followed by navigation/pollen and `SECTOR DESPEJADO` at 360 m. Review captures: `dev/level_01_review/polish_01_garden.png` through `polish_09_final_encounter.png`. Known limitation: log mesh can briefly occlude Bee; collision passage is valid. R reloads the full level; there is no checkpoint. No judgment of fun, perfect pacing or final artistic quality is implied.
