extends ColorRect
class_name CharBar

# name, stats, status
var charStates = {}

func _init():
	pass

func loadChars(charPayload):
	for key in charPayload:
		charStates[key] = {
			"name": key,
			"stats": charPayload[key],
			"status": "READY"
		}
func getChars():
	return charStates.keys()
	
func updateStatus(charName, newStatus):
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


func getStats(charName):
	return charStates[charName]["stats"]
