extends Polygon2D
class_name StarGraph

@export var myWeights: Array[float]
@export 	var R = 500 # radius

func _init(weights = []):
	# 5 points, that are percents of how far to go
	if weights == []:
		# empty, use all 100%
		myWeights = [1, 1, 1, 1, 1]
		return
	myWeights = weights
	
func _enter_tree():
	# ok so, pretend it's a circle, but take 5 sample points of 360/5 degrees apart
	var curAngle = -90
	var points = []
	for idx in range(0, 5):
		points.append(Vector2(
			R * myWeights[idx] * cos(deg_to_rad(curAngle)),
			R * myWeights[idx] * sin(deg_to_rad(curAngle))
		))
		curAngle += 360 / 5 # degrees? 
	print(points)
	polygon = points

	# offset by the center of the pentagon
	position = Vector2(R, R)
