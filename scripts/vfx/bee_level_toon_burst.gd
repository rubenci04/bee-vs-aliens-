extends "res://scripts/art/toon_burst_visual.gd"
## NOCHE 01 · ETAPA 2 — Codex toon burst used by BeeCombatVFX in Level 01. Carries the same `kind` / `direction` / `extent`
## fields as the old BeeCombatVFX so the rest of the game (and its tests) can still tell which effect it is.
var kind: StringName
var direction := Vector3.RIGHT
var extent := 1.0
