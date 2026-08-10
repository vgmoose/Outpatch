extends Node2D
class_name Main

var curId = 1

signal event_selected
signal choose_char
signal unpause
signal event_finished

var isPaused = false

var charData ={} # populated via json load
var eventStream = [] # ibid

var curTime = 0.0

func _init():
	# initialize character data
	var charFileData = FileAccess.get_file_as_string("res://data/chars.json")
	var jsonCharData = JSON.parse_string(charFileData)
	for charName in jsonCharData:
		charData[charName] = jsonCharData[charName]
	
	# initialize event data
	var eventFileData = FileAccess.get_file_as_string("res://data/events.json")
	var jsonEventData = JSON.parse_string(eventFileData)
	var curId = 0
	for event in jsonEventData["events"]:
		event.hasFired = false
		event.id = curId
		curId += 1
		eventStream.append(event)

	unpause.connect(func():
		var events = get_node("Events")
		for event in events.get_children():
			event.isPaused = false
		get_node("EventPrompt").visible = false
		isPaused = false
	)
	event_finished.connect(func(eventId):
		# stop the respective event circle
		var events = get_node("Events")
		for event in events.get_children():
			event.queue_free() # TODO: another state for finished
	)
	event_selected.connect(func(eventId):
		# pause all timers
		var events = get_node("Events")
		var chosenEvent = null
		for event: EventCircle in events.get_children():
			event.isPaused = true
			if event.eventId == eventId:
				chosenEvent = event
		isPaused = true
			# TODO: EXTRACT INTO COMMON PAUSE?
		# display this event
		var prompt = get_node("EventPrompt")
		# TODO: instead of passing IDs and strings, just pass event everywhere
		print("Passing: ", chosenEvent)
		prompt.display(chosenEvent)
	)
	choose_char.connect(func(charName, isChosen=true):
		if not isChosen:
			# it's an unselect event!
			# delete the overlay child
			for csp in get_node("CharBar").get_children():
				if csp.myName == charName:
					for child in csp.get_children():
						if child is Button:
							continue # their nametag
						child.queue_free()
					csp.isChosen = false
			return
		var prompt = get_node("EventPrompt")
		prompt.addChar(charName, charData[charName])
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
	
	for charName: String in charData:
		var csp = CSP.new(charBar.size.y, charName, charData[charName])
		charBar.add_child(csp)
	
	var curPos = screenWidth  / 2 - (charData.size() * charBar.size.y) / 2
	for child: CSP in charBar.get_children():
		child.position.x = curPos
		curPos += charBar.size.y

func _process(delta: float):
	# Debug: loop time after 20 seconds
	if curTime > 20:
		curTime = float(int(curTime) % 20)
		# also reset all events
		for event in eventStream:
			event.hasFired = false
	# advance our cur time!
	if not isPaused:
		curTime += delta
		get_node("Clock").text = " %0.2f" % curTime
	
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
	
	# see if we have any events that need to fire
	# TODO: don't check every event every frame? some other kind of data structure
	for event in eventStream:
		if event.hasFired:
			continue # already done it!
		if event.timing <= curTime:
			event.hasFired = true # don't double process

			# make an event circle from this event data
			var eventCircleScene = preload("res://EventCircle.tscn")
			var eventCircle = eventCircleScene.instantiate()
			eventCircle.updateEvent(event)
			curId += 1
			events.add_child(eventCircle)
			# TODO: load x, y coors from the event data
			eventCircle.position.y = playableArea.position.y + (randf() * playableArea.size.y)
			eventCircle.position.x = playableArea.position.x + (randf() * playableArea.size.x)
