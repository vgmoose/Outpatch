extends Polygon2D
class_name StarGraph

@export var myWeights: Array[float]
@export 	var R = 300 # radius

@export var thickBordered = false

# various styling that we have to manually manage
# in a few places
var lineSegment = null
var jointPoints = null

func _init(color, isThickBordered=false):
	thickBordered = isThickBordered
	# 5 points, that are percents of how far to go
	myWeights = [1, 1, 1, 1, 1]
	self.color = color
	self.color.a = 0.5
	
func _enter_tree():
	update_graph()

func start_animation(tweenChain):
	print("we are here", polygon)
	var dest = polygon
	polygon = [Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)]
	lineSegment.points =  [Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)]
	for jp in jointPoints:
		jp.position = Vector2(0, 0)
	# animate each point individually
	tweenChain.tween_interval(2)
	for idx in range(5):
		tweenChain.parallel().tween_method((func(cur):
			visible = true
			polygon[idx] = cur
			lineSegment.points[idx] = cur
			jointPoints[idx].position = cur
		), Vector2(0, 0), dest[idx], 2)

	return tweenChain

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
	
	# draw line2d's across the polygon
	if lineSegment:
		# clean up the old line segment
		lineSegment.queue_free()
	if jointPoints:
		for p in jointPoints:
			p.queue_free()
	lineSegment = Line2D.new()
	lineSegment.width = 6
	lineSegment.points = points
	lineSegment.closed = true
	var darkerColor = color.darkened(0.4)
	darkerColor.a = 0xFF
	lineSegment.joint_mode = Line2D.LINE_JOINT_ROUND
	#lineSegment.fill
	print(thickBordered)
	add_child(lineSegment)
	
	lineSegment.default_color = Color.DARK_SLATE_GRAY
	if not thickBordered:
		lineSegment.default_color = darkerColor
		jointPoints = []
		for point in points:
			var ballJoint = Sprite2D.new()
			ballJoint.texture = preload("res://icons/check_round_color.png")
			ballJoint.scale = Vector2(0.25, 0.25)
			ballJoint.modulate = darkerColor
			add_child(ballJoint)
			ballJoint.position = point
			jointPoints.append(ballJoint)
		
	
	
