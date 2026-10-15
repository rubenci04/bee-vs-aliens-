class_name BeePollenCluster
extends BeePollenPickup
## LOTE 13 · ETAPA 1 — POLLEN CLUSTER (replaces the honey jar): a big ball of pollen worth `pollen_value` pollen. It never heals
## by itself: the level's pollen bar charges the pollen Nova at 20/20 (T3m).
## It is collected at any HP (the bar just fills).

const CLUSTER_VALUE := 10 ## Pollen in one cluster (half a bar of 20; LOTE 14: was 5 of 10).


func _init() -> void:
	pollen_value = CLUSTER_VALUE
	heal_amount = 0
