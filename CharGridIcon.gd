extends Node2D
class_name CharGridIcon

var dest = Vector2(0, 0) # x, y coor of where to move to over time
var speed = 100
var eventParent = null
var myCharName = "Unknown"
var isWalker = true

func updateImg(charBar: CharBar, charName: String):
	var inner: TextureRect = get_node("CharGridIcon/Texture2D")
	var texture = load("res://csps/" + charName + ".png")
	if not texture:
		texture = load("res://csps/Unknown.jpg")
	inner.texture = texture
	var border = get_node("Border")
	border.modulate = charBar.getColor(charName).darkened(0.2)
	
	speed = 500 * charBar.getStats(charName)[2] # mobility
	myCharName = charName
	
	isWalker = not charBar.getFlying(myCharName)

func _process(delta):
	var main = get_tree().current_scene
	if not main.isPaused:
		var destMod = dest + Vector2(40, 40)
		if position == destMod:
			# we've arrived, update the corresponding event
			var charBar = get_tree().current_scene.get_node("CharBar") # TODO: get a static helper to obtain these refs
			if eventParent:
				# if there's 2 characters, we need them both to arrive
				eventParent.arrivedCount += 1
				if eventParent.arrivedCount == eventParent.chosenChars.size():
					eventParent.updateStatus("BEING_WORKED_ON")
					for charName in eventParent.chosenChars:
						charBar.updateStatus(charName, "WORKING")
				else:
					charBar.updateStatus(myCharName, "WAITING")
				
			else:
				# this was a going home tween, no event
				charBar.updateStatus(myCharName, "RESTING")

			queue_free()
		var newPos = position.move_toward(destMod, delta * speed)
		var stepAmount = position - newPos
		if isWalker and stepAmount.x != 0 and stepAmount.y != 0:
			# walkers only step vert or horiz for a period of time, if both potential step directions aren't zero
			if (int(position.distance_to(destMod)) % 600) < 300:
				destMod.x = position.x
			else:
				destMod.y = position.y
			newPos = position.move_toward(destMod, delta * speed)
		position = newPos
