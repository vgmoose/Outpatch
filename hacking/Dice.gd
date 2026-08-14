extends CharacterBody3D
class_name Dice

var x = 0
var model = null
var friction = 0.9

var zeroVec = Vector3(0, 0, 0)

var lookup = {} # Vector2(x, y) -> true
var conns = {} # "id" -> "next": ["id"]
var passData = {} # "pass id" -> "password"

var curPos = Vector2(0, 0)
var curId = "start" # start at start

func _enter_tree():
	model = get_node("Model")

var speed = 12

func _input(event):
	# lookup next potential IDs
	var nexts = conns[curId]["next"]
	var buttons = ["ui_down", "ui_up", "ui_left", "ui_right"]
	var velocities = [Vector2(0, 1), Vector2(0, -1), Vector2(-1, 0), Vector2(1, 0)]

	#print(nexts)
	#print(lookup)
	#print(curId)
	for idx in range(4):
		var button = buttons[idx]
		var x = velocities[idx].x
		var y = velocities[idx].y
		if event.is_action_pressed(button):
			# must be "true", to be a valid space
			var newPos = curPos + velocities[idx]
			#print(newPos, newPos in lookup)
			if newPos in lookup:
				#print("in", lookup[newPos])
				# also, we need to have a bridge to this dest too
				if lookup[newPos] in nexts:
					velocity += Vector3(x*speed, 0, y*speed)
					curPos = newPos
					curId = lookup[newPos]
	
		# if we're now on a password square, show the window (or hide if we're not)
		var window = get_node("Sprite2D/SubViewport/CoolWindow")
		if "pass" in conns[curId]:
			var passId = conns[curId]["pass"]
			window.visible = true
			var titleText = window.get_node("TitleText")
			titleText.text = "Password"
			var bodyText = window.get_node("SimpleBody")
			bodyText.visible = true
			bodyText.text = passData[passId].to_upper()
			bodyText.size.x = window.size.x
			bodyText.add_theme_font_size_override("font_size", 70)
			window.tweenIn(window.size)
		else:
			if window.visible:
				# hide it
				var tween = window.tweenOut()
				tween.tween_callback(func(): window.visible = false)
			
	
func _physics_process(delta):
	if not model:
		return
	
	if velocity == zeroVec:
		# idle rotating
		model.rotation += Vector3(1, 1, 1) * delta
	else:
		model.rotation -= Vector3(velocity.z, velocity.y, velocity.x) * 0.04
	x += 1
	
	move_and_slide()
	velocity *= friction
	
	if abs(velocity.x) + abs(velocity.y) + abs(velocity.z) < 0.01:
		velocity = zeroVec
	
	position = Vector3(position.x, abs(sin(x / 100.0) / 4.0 - 2), position.z)
	
