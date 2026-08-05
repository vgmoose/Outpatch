extends Node2D
class_name Main

var charData = [
	"Invisigal",
	"Toxic",
	"Armstrong",
	"Coupe",
	"Sonar",
	"White_Lightning",
	"Long",
	"Khopesh"
]

var curId = 1

signal event_selected
signal choose_char

var isPaused = false

#var cache = {}
#
#func _init():
	#cache = preload 
#
#func lookupPreloadTexture(name: String):
	#
func _init():
	event_selected.connect(func(eventId):
		# pause all timers
		var events = get_node("Events")
		for event: EventCircle in events.get_children():
			event.isPaused = true
		isPaused = true
			# TODO: EXTRACT INTO COMMON PAUSE?
		# display this event
		var prompt = get_node("EventPrompt")
		prompt.display("Event ID: " + str(eventId))
	)
	choose_char.connect(func(charName, isChosen=true):
		if not isChosen:
			# it's an unselect event!
			# delete the overlay child
			for csp in get_node("CharBar").get_children():
				if csp.myName == charName:
					for child in csp.get_children():
						child.queue_free()
					csp.isChosen = false
			return
		var prompt = get_node("EventPrompt")
		prompt.addChar(charName)
	)

func _enter_tree() -> void:
	var viewport = get_viewport_rect()
	var screenHeight = viewport.size.y
	var screenWidth = viewport.size.x
	
	# create each CSP icon centered along the bottom
	var charBar: Control = get_node("CharBar")
	charBar.size.x = screenWidth
	charBar.size.y = 200
	charBar.position.y = screenHeight - charBar.size.y

	var map = get_node("Map")
	map.size.x = screenWidth
	map.size.y = screenHeight - charBar.size.y
	
	var prompt = get_node("EventPrompt")
	prompt.position.x = 0.1 * screenWidth
	prompt.position.y = 0.1 * screenHeight
	prompt.size.x = 0.8 * screenWidth
	prompt.size.y = 0.8 * screenHeight - charBar.size.y

	for charName: String in charData:
		var csp = CSP.new(charBar.size.y, charName)
		charBar.add_child(csp)
	
	var curPos = screenWidth  / 2 - (charData.size() * charBar.size.y) / 2
	for child: CSP in charBar.get_children():
		child.position.x = curPos
		curPos += charBar.size.y

func _process(delta: float):
	var events = get_node("Events")
	# decide if we should randomly create an event
	var viewport = get_viewport_rect()
	var screenHeight = viewport.size.y
	var screenWidth = viewport.size.x
	var charBar = get_node("CharBar")
	var playableArea = Rect2(
		Vector2(screenWidth * 0.1, screenHeight * 0.1),
		Vector2(screenWidth * 0.8, screenHeight * 0.8 - charBar.size.y)
	)
	
	if isPaused:
		return # no more events
	
	if randi_range(1, 100) == 27:
		# make an event
		var eventCircle = EventCircle.new(curId)
		curId += 1
		events.add_child(eventCircle)
		eventCircle.position.y = playableArea.position.y + (randf() * playableArea.size.y)
		eventCircle.position.x = playableArea.position.x + (randf() * playableArea.size.x)
