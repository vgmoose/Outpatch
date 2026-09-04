extends Node2D
class_name Main

var curId = 1

signal event_selected
signal choose_char
signal unpause
signal event_finished

var isPaused = false

var eventStream = [] # ibid

var curTime = 0.0

static var gameConfigData = {} # global attributes about the game

func _init():
	var gameFileData = FileAccess.get_file_as_string("res://data/game.json")
	Main.gameConfigData = JSON.parse_string(gameFileData)
	
	if "cursorTint" in Main.gameConfigData:
		var image = Image.load_from_file("res://images/icons/cursor.png")
		var blendMask = ImageTexture.create_from_image(image).image
		blendMask.fill(Main.gameConfigData["cursorTint"])
		image.fix_alpha_edges()
		image.blend_rect_mask(blendMask, image, blendMask.get_used_rect(), Vector2(0, 0))
		image.fix_alpha_edges()
		image.premultiply_alpha()
		var texture = ImageTexture.create_from_image(image)
		Input.set_custom_mouse_cursor(texture)

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
			if event is EventCircle:
				event.isPaused = false
		isPaused = false
		
	)
	event_finished.connect(func(eventId):
		# stop the respective event circle
		var events = get_node("Events")
		for event in events.get_children():
			event.queue_free() # TODO: another state for finished
	)
	event_selected.connect(func(eventId, isReview = false):
		# if we're paused, don't display anoteh event
		var main = get_tree().current_scene
		if main.isPaused:
			return
		# pause all timers
		var events = get_node("Events")
		var chosenEvent = null
		for event in events.get_children():
			if event is EventCircle:
				event.isPaused = true
				if event.eventId == eventId:
					if isReview:
						if event.curStatus == "COMPLETED":
							chosenEvent = event
						else:
							continue # can only review completed events (prevents ID collision on duplicated/looped/repeating events)
					else:
						# not a review, just consider it found
						chosenEvent = event
		isPaused = true
			# TODO: EXTRACT INTO COMMON PAUSE?
		# display this event
		var prompt = get_node("EventPrompt")
		# TODO: instead of passing IDs and strings, just pass event everywhere
		print("Passing: ", chosenEvent)
		prompt.display(chosenEvent)
		
		if isReview:
			# copy over chosen characters
			var prevChars = chosenEvent.chosenChars.duplicate()
			prompt.chosenChars = chosenEvent.chosenChars
			prompt.playProbabilityAnimation(chosenEvent)
	)
	choose_char.connect(func(charName, isChosen=true):
		var charBar = get_node("CharBar")
		var prompt = get_node("EventPrompt")
		if not isChosen:
			# this is a removal event! remove it from the charBar
			# and update the char's status
			prompt.chosenChars.erase(charName)
			charBar.updateStatus(charName, "READY")
			prompt.position_csps(charBar)
			return
		prompt.addChar(charBar, charName)
		
		# play a chatter for this character
		var chatterBox = get_node("ChatterBox")
		
		# if we have a synergy set, do that too
		if prompt.chosenChars.size() > 1:
			var charCopies = prompt.chosenChars.duplicate()
			charCopies.sort()
			var synergyKey = "-".join(charCopies)
			# always try to fire a synergy event (does nothing if missing)
			chatterBox.toast("synergy", synergyKey)
		chatterBox.toast("onAssign", charName)
	)

func _enter_tree() -> void:
	# initialize character data
	var charFileData = FileAccess.get_file_as_string("res://data/chars.json")
	var jsonCharData = JSON.parse_string(charFileData)
	var charBar: Control = get_node("CharBar")
	charBar.loadChars(jsonCharData)
	
	# initialzie chatter data
	var chatterFileData = FileAccess.get_file_as_string("res://data/chatters.json")
	var jsonChatterData = JSON.parse_string(chatterFileData)
	var chatterBox = get_node("ChatterBox")
	chatterBox.ogData = jsonChatterData
	
	var viewport = get_viewport_rect()
	var screenHeight = viewport.size.y
	var screenWidth = viewport.size.x
	
	# position AllTextLog
	var allTextLog = get_node("AllTextLog")
	allTextLog.size = Vector2(1100, viewport.size.y)
	allTextLog.position.x = viewport.size.x - allTextLog.size.x
	allTextLog.z_index = 4
	
	var dimmer = get_node("Dimmer")
	var tGray = Color.BLACK
	tGray.a = 0.5
	dimmer.texture = EventCircle.makeSimpleColorTexture(tGray)
	
	var buttonBar = get_node("ButtonBar")
	buttonBar.size = viewport.size
	
	var fullscreen = buttonBar.get_node("Button2")
	fullscreen.connect("pressed", func():
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
			fullscreen.text = "Exit Fullscreen"
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			fullscreen.text = "Fullscreen"
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	)
	var sceneChange = buttonBar.get_node("Button")
	sceneChange.connect("pressed", func():
		if isPaused:
			return # can't do while paused
		isPaused = true
		var subviewContainer = get_node("ExternalScene")
		var subview = subviewContainer.get_node("SubViewport")
		var hackingScene = preload("res://hacking/main2.tscn")
		var hacking = hackingScene.instantiate()
		subviewContainer.visible = true
		subview.add_child(hacking)
		subviewContainer.position = Vector2(viewport.size.x / 2.0 - subview.size.x / 2.0, viewport.size.y + subview.size.y / 2.0)
		
		animateDimmer(true, true)
		
		var tween = get_tree().create_tween()
		tween.tween_property(subviewContainer, "position", viewport.size / 2.0 - subview.size / 2.0, 0.4)
	)
	
	var showChatLog = buttonBar.get_node("Button3")
	showChatLog.connect("pressed", func():
		allTextLog.showLog()
	)
	
	# create each CSP icon centered along the bottom
	charBar.size.x = screenWidth
	charBar.size.y = 200
	charBar.position.y = screenHeight - charBar.size.y

	showChatLog.position.y -= charBar.size.y
	showChatLog.position.y += showChatLog.size.y

	var map = get_node("Map")
	map.size.x = screenWidth
	map.size.y = screenHeight - charBar.size.y
	
	if "bgMapTint" in Main.gameConfigData:
		map.modulate = Main.gameConfigData["bgMapTint"]
	
	var prompt = get_node("EventPrompt")
	
	var charData = charBar.getChars()
	for charName: String in charData:
		var csp = CSP.new(charBar.size.y, charName, charBar.getStats(charName))
		charBar.add_child(csp)
	
	charBar.position_csps()
	
	var chatterBg = get_node("ChatterBox")
	var chatterText = chatterBg.get_node("ChatterText")
	chatterBg.position = Vector2(screenWidth/2.0 - chatterText.size.x/2.0, 50)

func animateDimmer(isIncoming, isFullscreen):
	var tween = get_tree().create_tween()
	var dimmer = get_node("Dimmer")
	var viewport = get_viewport_rect()
	dimmer.size = viewport.size
	if not isFullscreen:
		var charBar = get_node("CharBar")
		dimmer.size.y -= charBar.size.y
	var startA = 0.0
	var destA = 1.0
	if not isIncoming:
		var tmp = startA
		startA = destA
		destA = tmp
	dimmer.modulate.a = startA
	tween.tween_property(dimmer, "modulate:a", destA, 0.4)
	dimmer.visible = true
	if not isIncoming:
		tween.tween_callback(func(): dimmer.visible = false)

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
			var eventCircleScene = preload("res://overworld/EventCircle.tscn")
			var eventCircle = eventCircleScene.instantiate()
			eventCircle.updateEvent(event)
			curId += 1
			events.add_child(eventCircle)
			# TODO: load x, y coors from the event data
			eventCircle.position.y = playableArea.position.y + (randf() * playableArea.size.y)
			eventCircle.position.x = playableArea.position.x + (randf() * playableArea.size.x)
