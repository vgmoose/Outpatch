extends Polygon2D
class_name StarGraph

@export var myWeights: Array[float]
@export 	var R = 500 # radius

func _init(color):
	# 5 points, that are percents of how far to go
	myWeights = [1, 1, 1, 1, 1]
	self.color = color
	self.color.a = 0.5
	
func _enter_tree():
	update_graph()

func update_graph(weights: Array[float] = []):
	if weights != []:
		myWeights = weights
	# ok so, pretend it's a circle, but take 5 sample points of 360/5 degrees apart
	var curAngle = -90
	var points = []
	for idx in range(0, 5):
		points.append(Vector2(
			R * myWeights[idx] * cos(deg_to_rad(curAngle)),
			R * myWeights[idx] * sin(deg_to_rad(curAngle))
		))
		curAngle += 360 / 5 # degrees? 
	polygon = points

	# offset by the center of the pentagon
	position = Vector2(R, R)
