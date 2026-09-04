extends CharacterBody3D
class_name Dice

var x = 0
var model = null
var friction = 0.9

var zeroVec = Vector3(0, 0, 0)

var lookup = {} # Vector2(x, y) -> true
var conns = {} # "id" -> "next": ["id"]
var passData = {} # "pass id" -> "password"
var doorData = {} # door id -> direction of door
var doorLookup = {} # half door pos -> door id
var unlockedIds = {} # set of unlocked door/pass/lock IDs (which are all the same, actually)

var curPos = Vector2(0, 0)
var curId = "start" # start at start

var isMoving = false
var isLocked = false

var curPass = "" # currently input pass dirs
var targetPass = "" # current target pass (valid when == curPass)
var targetDoorId = "" # pass/door id that goes with it

func _enter_tree():
	model = get_node("Model")
	
	if "hackingTint" in Main.gameConfigData:
		model.mesh.material.albedo_color = Main.gameConfigData["hackingTint"]
		model.mesh.material.albedo_color = model.mesh.material.albedo_color.darkened(0.5)


var speed = 12

func _input(event):
	var buttons = ["ui_down", "ui_up", "ui_left", "ui_right"]
	var labels = "dulr"
	if isLocked:
		# enter four inputs
		var subtext = get_node("Sprite2D/SubViewport/CoolWindow/SimpleBody")
		for idx in range(4):
			var button = buttons[idx]
			if event.is_action_pressed(button):
				curPass += labels[idx]
		subtext.text = passToDirs(curPass, targetPass.length())
		if curPass.length() == targetPass.length():
			# is it right? either way though, unlock
			print(curPass, targetPass)
			if curPass == targetPass:
				# mark this door id as unlocked, and make visible the segment on the map
				doorData[targetDoorId].visible = true
				unlockedIds[targetDoorId] = true
			isLocked = false
		return
	# lookup next potential IDs
	var nexts = conns[curId]["next"]
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
			if newPos in lookup:
				# also, we need to have a bridge to this dest too
				if lookup[newPos] in nexts:
					# actually though, if the half pos inbetween is a door, we need it to be unlocked too
					var halfPos = (newPos + curPos) / 2.0
					if halfPos in doorLookup and doorLookup[halfPos] not in unlockedIds:
						continue # can't progress!
					velocity += Vector3(x*speed, 0, y*speed)
					curPos = newPos
					curId = lookup[newPos]
					isMoving = true
				
				var window = get_node("Sprite2D/SubViewport/CoolWindow")

				# if we're now on a password square, show the window (or hide if we're not)
				if "lock" in conns[curId]:
					# TODO: copypasta from below
					var passId = conns[curId]["lock"]
					if passId in unlockedIds:
						 # we don't have to danything
						return
					window.visible = true
					var titleText = window.get_node("TitleText")
					titleText.text = "Password"
					var bodyText = window.get_node("SimpleBody")
					bodyText.visible = true
					targetPass = passData[passId]
					curPass = ""
					targetDoorId = passId
					bodyText.text = passToDirs("", targetPass.length())
					bodyText.size.x = window.size.x
					bodyText.add_theme_font_size_override("font_size", 70)
					window.tweenIn(window.size)
					isLocked = true

				elif "pass" in conns[curId]:
					var passId = conns[curId]["pass"]
					window.visible = true
					var titleText = window.get_node("TitleText")
					titleText.text = "Password"
					var bodyText = window.get_node("SimpleBody")
					bodyText.visible = true
					bodyText.text = passToDirs(passData[passId], passData[passId].length())
					bodyText.size.x = window.size.x
					bodyText.add_theme_font_size_override("font_size", 70)
					window.tweenIn(window.size)
				else:
					if window.visible:
						# hide it
						var tween = window.tweenOut()
						tween.tween_callback(func(): window.visible = false)
			
func passToDirs(password_incoming, size):
	var password = password_incoming.to_lower()
	var dirs = {
		"u": "U",
		"d": "D",
		"r": "R",
		"l": "L"
	}
	var out = ""
	for idx in range(size):
		if idx >= password.length():
			# out of range, aka not filled in, so add placeholders
			out += "_ "
			continue
		var char = password[idx]
		if char in dirs:
			out += dirs[char]
		else:
			out += char
		out += " "
	return out

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
	
	if abs(velocity.x) + abs(velocity.y) + abs(velocity.z) < 1:
		isMoving = false # this var stops earlier, as its more accurate to teh user timings
	
	if abs(velocity.x) + abs(velocity.y) + abs(velocity.z) < 0.01:
		velocity = zeroVec
	
	position = Vector3(position.x, abs(sin(x / 100.0) / 4.0 - 2), position.z)
	
