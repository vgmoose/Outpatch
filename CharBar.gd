extends ColorRect
class_name CharBar

# name, stats, status
var charStates = {}

func _init():
	pass

func getTrait(charName):
	if "trait" in charStates[charName]:
		return charStates[charName]["trait"]
	return ""

func getColor(charName):
	return charStates[charName]["color"]

func getStatus(charName):
	return charStates[charName]["status"]

func getFlying(charName):
	return charStates[charName]["flying"]

func loadChars(charPayload):
	for key in charPayload:
		var normalizedStats = charPayload[key]["stats"].map(func(val): return val / 10.0)
		# TODO: at this point, probably just make a real Character class
		charStates[key] = {
			"name": key,
			"stats": normalizedStats,
			"color": Color.from_string(charPayload[key]["color"], Color.YELLOW),
			"status": "READY",
			"flying": "flying" in charPayload[key],
			"isHidden": "altName" in charPayload[key],
		}
		if "trait" in charPayload[key]:
			charStates[key]["trait"] = charPayload[key]["trait"]
		
		if "altName" in charPayload[key]:
			var altName = charPayload[key]["altName"]
			# doubly link alts
			charPayload[key]["altName"] = altName
			charStates[key]["altName"] = altName
			charStates[altName]["altName"] = key
			# store the original name as the display name for later (one way)
			charStates[key]["displayName"] = altName

func markSeenHidden(oldName, newName):
	charStates[oldName]["isHidden"] = true
	charStates[newName]["isHidden"] = false
	position_csps() # redraws our bottom bar

func position_csps():
	var curPos = size.x  / 2 - (getChars(true).size() * size.y) / 2
	for child: CSP in get_children():
		if charStates[child.myName]["isHidden"]:
			child.visible = false
			continue
		child.visible = true
		child.position.x = curPos
		curPos += size.y

func getChars(skipHidden=false):
	var keys = []
	for key in charStates.keys():
		if skipHidden and charStates[key]["isHidden"]:
			continue
		keys.append(key)
	return keys

func startTravelling(chosenChars, mainEvent, fromDest, toDest):
	# update states (for target event, and chosen chars) and then dismiss
	for char in chosenChars:
		var newStatus = "RETURNING" # assume on the way back
		if mainEvent:
			newStatus = "TRAVELING" # on the way there
		updateStatus(char, newStatus)
		# create the actual character icon, at their current coors (TODO: don't hardcode)
		var gridIconScene = preload("res://CharGridIcon.tscn")
		var gridIcon: CharGridIcon = gridIconScene.instantiate()
		gridIcon.position = fromDest
		gridIcon.dest = toDest
		gridIcon.eventParent = mainEvent
		gridIcon.updateImg(self, char, chosenChars)
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
	if newStatus == "READY":
		# if we're marking them ready, ensure no event exists with them assigned to it
		# since then we ahve to use waiting instead
		var events = get_node("../Events")
		for event in events.get_children():
			if event is EventCircle and event.curStatus == "COMPLETED":
				if event.chosenChars.has(charName):
					# in an unreviewed job, mark waiting
					updateStatus(charName, "WAITING")
					return
					
	charStates[charName]["status"] = newStatus
	charTarget.curState = newStatus
	charTarget.updateStatus()

	if checkCounterparts and (newStatus == "ASSIGNED" or newStatus == "READY"):
		var counterStatus = "UNAVAILABLE"
		if newStatus == "READY":
			counterStatus = "READY"

		if charName == "Toxic":
			updateStatus("Toxic-Acid", counterStatus, false)
		if charName == "Toxic-Acid":
			updateStatus("Toxic", counterStatus, false)

func getStats(charName):
	return charStates[charName]["stats"]
