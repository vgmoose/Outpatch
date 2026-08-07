extends Node2D

func cleanup():
	# delete everything that isn't BouncyBall or CollisionChart
	var removeUs = []
	for child in get_children():
		if child is BouncyBall or child is StaticBody2D:
			continue
		removeUs.append(child)
	for child in removeUs:
		remove_child(child)
