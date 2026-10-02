extends "res://scripts/bee_prototype/bee_garden_approved_scenery.gd"
## Sparse presentation across the scrolling corridor; only two large objects collide.
func _ready() -> void:
	for entry in [[6.0,-10.0,0.9],[24.0,-10.0,1.0],[43.0,-10.0,0.85],[61.0,-10.0,0.95]]:
		place(TREE,"Tree%d" % get_child_count(),Vector3(entry[0],0,entry[1]),entry[2],0.2)
	for entry in [[3.0,-3.5],[12.0,-4.2],[19.0,-3.4],[29.0,-4.0],[37.0,-3.5],[48.0,-4.1],[57.0,-3.4]]:
		place(FERN,"Fern%d" % get_child_count(),Vector3(entry[0],0,entry[1]),2.1,0.3)
	for entry in [[10.0,-3.0],[30.0,-3.1],[46.0,-3.2]]:
		place(FLOWER,"Flower%d" % get_child_count(),Vector3(entry[0],0,entry[1]),14.0,0.0)
	place(LOG,"FallenLog",Vector3(25,0,0),4.799,0)
	place(BOTTLE,"GiantBottle",Vector3(41,0,0),10.337,0.15)

