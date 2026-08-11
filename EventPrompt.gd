extends ColorRect
class_name EventPrompt

var charBarHeight = 0
var wasPressed = false
var allDone = false
var isRunningProbabilityAnimation = false

var ogEvent = {}
var counter = 0
signal finishedBallBouncing
var mainEvent = null

# current chars that are chosen for this prompt
var chosenChars = []

func _enter_tree():
	var main = get_tree().current_scene
	charBarHeight = main.get_node("CharBar").size.y

func display(mainEvent):
	self.ogEvent = mainEvent.ogEvent
	self.mainEvent = mainEvent
	wasPressed = false # init vars
	chosenChars = []
	
	var sideWindow: CoolWindow = get_node("MissionWindow")
	var starGraphHolder = sideWindow.get_node("StarGraphHolder")
	var theBall = starGraphHolder.get_node("BouncyBall")
	theBall.visible = false
	
	var title = mainEvent.eventTitle
	var details = mainEvent.eventDetails
	var eventWeights = mainEvent.stats
	
	var viewport = get_viewport_rect()
	#var viewport = Vector2(3413, 1920)
	var screenHeight = viewport.size.y
	var screenWidth = viewport.size.x
	
	var main = get_tree().current_scene
	var window: CoolWindow = get_node("MainWindow")
	window.title = "Mission Brief"
	sideWindow.title = title
	var mainWinWidth = screenWidth * 0.33
	var mainWinHeight = screenHeight * 0.4
	window.position.x = mainWinWidth * 0.4
	window.position.y = (screenHeight - charBarHeight) * 0.25
	window.size.x = mainWinWidth
	window.size.y = mainWinHeight
	
	var sideWinWidth = screenWidth * 0.3
	var sideWinHeight = (screenHeight - charBarHeight) * 0.8
	sideWindow.position.x = screenWidth * 0.525
	sideWindow.position.y =  (screenHeight - charBarHeight) * 0.075
	sideWindow.size.x = sideWinWidth
	sideWindow.size.y = sideWinHeight
	
	window.adjustBounds()
	sideWindow.adjustBounds()
	
	# animate this in to grow to the size of the parent
	window.tweenIn(size)
	sideWindow.tweenIn(size)
	
	var para = window.get_node("RichTextLabel2")
	para.text = details
	para.position.y = 110
	para.position.x = 0.05 * mainWinWidth
	para.size.x = mainWinWidth * 0.9
	para.size.y = mainWinHeight * 0.9
	var charBar = get_tree().current_scene.get_node("CharBar")
	
	var cancel = window.get_node("Button2")
	cancel.connect("pressed", func():
		# free any assigned units
		for char in chosenChars:
			charBar.updateStatus(char, "READY")
		# unpause everything and return back to business
		dismiss()
	)
	position_csps(null)
	
	var button = window.get_node("Button")
	button.visible = false
	button.position.x = self.size.x - button.size.x - 250
	button.position.y = self.size.y - button.size.y - 90
	
	# TODO: attach these buttons directly to the dialog instead of externally managing them
	cancel.position.y = mainWinHeight - cancel.size.y - 16
	cancel.position.x = int(mainWinWidth / 32) * 32 / 2 - cancel.size.x - 40
	
	button.position.y = mainWinHeight - button.size.y - 16
	button.position.x = int(sideWinWidth / 32) * 32 / 2 + 40
	
	# clear old button events
	for connection in button.get_signal_connection_list("pressed"):
		button.disconnect("pressed", connection["callable"])
	
	button.connect("pressed", func():
		if allDone:
			# clean up for next go around
			mainEvent.queue_free() # TODO: increase score
			dismiss()
			allDone = false
			wasPressed = false
			isRunningProbabilityAnimation = false
			return
		if isRunningProbabilityAnimation:
			return
		var eventDest = mainEvent.position
		charBar.startTravelling(chosenChars, mainEvent, Vector2(500, 500), eventDest)
		mainEvent.updateStatus("BEING_TRAVELED_TO")
		# also, we will store the chosen chars _with_ this event
		mainEvent.chosenChars = chosenChars
		
		dismiss()
	)
	
	visible = true
	
func playProbabilityAnimation(targetEvent):
	# if we don't have chosen chars, don't even bother, dog
	if chosenChars.size() == 0:
		print("Somehow, there were no chosen chars")
		return
	# for some reason, removing below breaks chart animation even hough this func is called once
	# TODO: figure that out
	#if isRunningProbabilityAnimation: # no double presses
		#return
	isRunningProbabilityAnimation = true
	# hide our CSPs
	for child in get_children():
		if child is CSP:
			child.queue_free()
	
	chosenChars = targetEvent.chosenChars
	var charBar = get_tree().current_scene.get_node("CharBar")
	position_csps(charBar)
	var mainWindow = get_node("MainWindow")
	var button = mainWindow.get_node("Button")
	var cancel = mainWindow.get_node("Button2")
	var starGraphHolder = get_node("MissionWindow/StarGraphHolder")
	var theBall = starGraphHolder.get_node("BouncyBall")
	# hide our buttons while our main event is running
	# TODO: don't just do this all here?
	button.visible = false
	cancel.visible = false
	if starGraphHolder.get_children().size() < 2:
		# we don't have any heroes added
		return
	# remove the previously generated merged graph
	# so that we can retween it in
	var mergedGraph = starGraphHolder.get_children()[starGraphHolder.get_children().size()-1] # assume it's at the end
	starGraphHolder.remove_child(mergedGraph)

	# start the simulation, reveal true probabilities
	var trueGraph = StarGraph.new(Color.DARK_BLUE)

	var eventWeights = targetEvent.stats
	trueGraph.update_graph(eventWeights)
	var truePolygon = trueGraph.polygon # update_graph applies our weights to the actual polygon shape
	starGraphHolder.add_child(trueGraph)
	
	# tween our actual probabilities back in
	starGraphHolder.add_child(mergedGraph)
	var tween = get_tree().create_tween()
	
	var finalPolygon = mergedGraph.polygon
	
	# start physics simulation?
	# first, find intersecting polygon

	# and then the area of the outer
	var outer = calculate_area(truePolygon)
	# percent success is straightforwards
	var label = Button.new()
	label.text = "0%"
	label.add_theme_font_size_override("font_size", 65)
	starGraphHolder.add_child(label)
	
	# tween in the base, then our merged, and update the percent along the way
	trueGraph.visible = false
	mergedGraph.visible = false
	trueGraph.start_animation(tween)
	mergedGraph.start_animation(tween)
	
	tween.parallel().tween_method((func(cur):
		# we ignore cur, because we're just going to use the polygon that's growing into place
		# get the area of the inner (overlap/clipped) polygon(s)
		var inner = 0.0
		var commongons = Geometry2D.intersect_polygons(trueGraph.polygon, mergedGraph.polygon)
		for common in commongons:
			inner += calculate_area(common)
		label.text = "%0.2f%%" % abs((inner / outer) * 100)
	), 0, 0, 2)
	
	tween.tween_callback(func():
		# show the ball
		theBall.position = mergedGraph.position # TODO: this assumes firstchild is the empty chart
		theBall.visible = true
		
		# move it to the front
		starGraphHolder.remove_child(theBall)
		starGraphHolder.add_child(theBall)
	)
	tween.tween_interval(0.4)
	tween.tween_callback(func():
		# this is called after the above animations are done, kick off the ball moving in a random direction
		# with the collision of the merged polygon
		var collisionChart = starGraphHolder.get_node("CollisionChart")
		var collider = collisionChart.get_node("CollisionPolygon2D")
		collider.polygon = truePolygon
		# for visualizing only
		#var siblinggon = collisionChart.get_node("Polygon2D")
		#siblinggon.color = Color.BLUE
		#siblinggon.polygon = truePolygon
		collisionChart.position = mergedGraph.position
		
		theBall.startMoving()
	)
	
	# remove old connections
	for conn in finishedBallBouncing.get_connections():
		finishedBallBouncing.disconnect(conn.callable)
	print("Totalconns ", finishedBallBouncing.get_connections())
	finishedBallBouncing.connect(func():
		print("We're done moving, are we inside?")
		# aka, is the ball's point within our merged graph's polygon
		var ogBallPos = theBall.position - mergedGraph.position # polygon coors are not relative, so we need to offset by ball's visual position
		var res = Geometry2D.is_point_in_polygon(ogBallPos, mergedGraph.polygon)
		print("We are: " + str(res), " ", ogBallPos, mergedGraph.polygon)
		
		# re-get and re-draw the _final_ state of the commongons (the common area)
		# so that we can properly highlight the mixed/overlap at this stage
		var commongons = Geometry2D.intersect_polygons(trueGraph.polygon, mergedGraph.polygon)
		for commongon in commongons:
			var chartSegment = Polygon2D.new()
			chartSegment.polygon = commongon
			starGraphHolder.add_child(chartSegment)
			chartSegment.position = mergedGraph.position
			if res:
				chartSegment.color = Color.GREEN
			else:
				chartSegment.color = Color.RED
			chartSegment.color.a = 0.5
		
		# show the success or failure text
		if res:
			button.set_text(ogEvent["success"])
		else:
			button.set_text(ogEvent["failure"])
			
		button.visible = true
		# also bring the button to front
		remove_child(button)
		add_child(button)
		wasPressed = false
		allDone = true # next press will dismiss
	)
	
# Gauss's shoelace formula, to get the area of a polygon
# https://gamedev.stackexchange.com/a/211635
func calculate_area(mesh_vertices: PackedVector2Array) -> float:
	var result := 0.0
	var num_vertices := mesh_vertices.size()

	for q in range(num_vertices):
		var p = (q - 1 + num_vertices) % num_vertices
		result += mesh_vertices[q].cross(mesh_vertices[p])

	return abs(result) * 0.5
	
#func removeChar(charName):
	#for child in get_children():
		#if child is CSP and child.myName = charName:
			#

func dismiss():
	# animate oureslves disappearing
	var mainWindow = get_node("MainWindow")
	var sideWindow = get_node("MissionWindow")
	var cancel = mainWindow.get_node("Button2")
	var button = mainWindow.get_node("Button")
	var starGraphHolder = sideWindow.get_node("StarGraphHolder")
	var main = get_tree().current_scene
	cancel.visible = true
	starGraphHolder.cleanup()
	button.set_text("Start")
	
	mainWindow.tweenOut()
	sideWindow.tweenOut()
	
	var tween = get_tree().create_tween()
	tween.tween_interval(0.25) #  TODO: matches inner window dismiss speed
	tween.tween_callback(func():
		visible = false
		main.unpause.emit()
	)
	
func position_csps(charBar):
	var button = get_node("MainWindow/Button")
	if chosenChars.size() > 0:
		# enable start button
		button.visible = true
		remove_child(button)
		add_child(button)
	else:
		button.visible = false
		
	var window = get_node("MissionWindow")
	for child in window.get_children():
		# clear any existing CSPs, sicne we're about to recreate them
		if child is CSP:
			child.queue_free()
	
	var curWeights = []
	if charBar: # if null, it's the first init
		for charName in chosenChars:
			curWeights.append(charBar.getStats(charName))
		
		var curOff = window.size.x - (chosenChars.size() * charBar.size.y) / 2
			
		for charName in chosenChars:
			var curCsp = CSP.new(charBar.size.y, charName, [])
			curCsp.selectedPrompt = self
			window.add_child(curCsp)
			curCsp.position.x = curOff
			curCsp.position.y = window.size.y * 3 + 15
			curOff += charBarHeight
			curWeights.append(charBar.getStats(charName)) # always source stats from CharBar ref
	
	# clear current star graphs and make new ones for each char
	var starGraphHolder = get_node("MissionWindow/StarGraphHolder")
	starGraphHolder.position.x = 80
	starGraphHolder.position.y = 155
	for oldGraph in starGraphHolder.get_children():
		if oldGraph is StarGraph:
			starGraphHolder.remove_child(oldGraph)
	
	# background of chart
	var emptyGraph = StarGraph.new(Color.WEB_GRAY, true)
	starGraphHolder.add_child(emptyGraph)

	# merging logic
	var gold = Color.DARK_RED
	gold.a = 0.6
	var mergedGraph = StarGraph.new(gold)
	starGraphHolder.add_child(mergedGraph)
	var mergedWeights: Array[float] = [0.0,0.0,0.0,0.0,0.0]
	for weights in curWeights:
		for wIdx in range(5):
			mergedWeights[wIdx] = max(mergedWeights[wIdx], weights[wIdx])
	mergedGraph.update_graph(mergedWeights)

func addChar(charBar, charName):
	# we can only add if the event is in the tikcing state
	if not mainEvent or mainEvent.curStatus != "TICKING":
		return
	# if we have two chosen already, don 't allow more
	if chosenChars.size() >= 2:
		return
	# accept the char and block it off
	chosenChars.append(charName)
	charBar.updateStatus(charName, "ASSIGNED")
	position_csps(charBar)
