extends ColorRect
class_name CharBar

# name, stats, status
var charStates = {}

func _init():
	pass

func getColor(charName):
	return charStates[charName]["color"]

func getStatus(charName):
	return charStates[charName]["status"]

func loadChars(charPayload):
	for key in charPayload:
		var normalizedStats = charPayload[key]["stats"].map(func(val): return val / 10.0)
		charStates[key] = {
			"name": key,
			"stats": normalizedStats,
			"color": Color.from_string(charPayload[key]["color"], Color.YELLOW),
			"status": "READY"
		}
func getChars():
	return charStates.keys()

func startTravelling(chosenChars, mainEvent, fromDest, toDest):
	# update states (for target event, and chosen chars) and then dismiss
	for char in chosenChars:
		updateStatus(char, "TRAVELING")
		# create the actual character icon, at their current coors (TODO: don't hardcode)
		var gridIconScene = preload("res://CharGridIcon.tscn")
		var gridIcon: CharGridIcon = gridIconScene.instantiate()
		gridIcon.position = fromDest
		gridIcon.dest = toDest
		gridIcon.eventParent = mainEvent
		gridIcon.updateImg(self, char)
		var main = get_tree().current_scene
		var map = main.get_node("Events")
		map.add_child(gridIcon)
	
func updateStatus(charName, newStatus, checkCounterparts=true):
	var charTarget = null
	for char in get_children():
		if char is CSP and char.myName == charName:
			charTarget = char
			break
	if not charTarget:
		#couldn't find tthem
		return
	charStates[charName]["status"] = newStatus
	charTarget.curState = newStatus
	charTarget.updateStatus()
	
	# TODO: handle transformation characters, until then, mark counterpart unavailable
	if checkCounterparts and (newStatus == "ASSIGNED" or newStatus == "READY"):
		var counterStatus = "UNAVAILABLE"
		if newStatus == "READY":
			counterStatus = "READY"

		if charName == "Toxic-1":
			updateStatus("Toxic-2", counterStatus, false)
		if charName == "Toxic-2":
			updateStatus("Toxic-1", counterStatus, false)


func getStats(charName):
	return charStates[charName]["stats"]
