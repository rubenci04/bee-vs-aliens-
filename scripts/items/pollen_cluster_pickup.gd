class_name BeePollenCluster
extends BeePollenPickup
## LOTE 13 · ETAPA 1 — POLLEN CLUSTER (replaces the honey jar): a big ball of pollen worth `pollen_value` pollen. It never heals
## by itself: the level's pollen bar (BeeLevel01Juice) heals POLLEN_HEAL_FRACTION of max HP every POLLEN_PER_HEAL pollen.
## It is collected at any HP (the bar just fills).

const CLUSTER_VALUE := 5 ## Pollen in one cluster (half a bar).


func _init() -> void:
	pollen_value = CLUSTER_VALUE
	heal_amount = 0
