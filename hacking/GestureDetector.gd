extends Control

var isMouseDown = false
var startPos = Vector2(0, 0)
var threshold = 200

func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		isMouseDown = true
		startPos = event.position
	if isMouseDown and event is InputEventMouseMotion:
		var diff = event.position - startPos
		if abs(diff.x) > threshold or  abs(diff.y) > threshold:
			isMouseDown = false
			var dice = get_node("../Dice")
			var fake_press = InputEventAction.new()
			fake_press.pressed = true
			var dir = diff.normalized()
			if abs(dir.x) > abs(dir.y):
				# horiz event
				if dir.x < 0:
					fake_press.action = "ui_left"
				else:
					fake_press.action = "ui_right"
			else:
				if dir.y < 0:
					fake_press.action = "ui_up"
				else:
					fake_press.action = "ui_down"
			dice._input(fake_press)
					
