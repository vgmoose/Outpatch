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
	

func getStats(charName):
	return charStates[charName]["stats"]
