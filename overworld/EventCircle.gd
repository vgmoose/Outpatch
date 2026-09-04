extends Button
class_name EventCircle

var isPaused = false
var wasFreed = false

var eventId = 0
var main: Main = null

var eventTitle = "Unknown"
var eventDetails = "???"
var duration = 0.0
var startDuration = 1.0
var stats: Array[float] = [0, 0, 0, 0, 0]

var ogEvent = {}
var curStatus = "TICKING" # ticking, being_traveled_to, being_worked_on, completed
var chosenChars = [] # list of names of chars assigned to this event

var arrivedCount = 0
var tooltip = null

static func makeSimpleColorTexture(color: Color):
	var out = GradientTexture2D.new()
	out.gradient = Gradient.new()
	out.gradient.set_color(0, color)
	out.gradient.set_color(1, color)
	return out

func updateStatus(newStatus):
	var circleBar = get_node("CircleBar")
	if newStatus == "BEING_WORKED_ON":
		if arrivedCount == 1:
			duration = 0 # we're going to count up, only reset for the first arrival
		# show the thing
		circleBar.visible = true
	else:
		# also, stop ticking at this point, since tahts' the initial state
		circleBar.visible = false
	
	var label = get_node("TextureRect")
	if newStatus == "COMPLETED":
		label.texture = preload("res://images/icons/checked.png")
	else:
		label.texture = preload("res://images/icons/wip.png") # TODO: more symbols
		
	curStatus = newStatus
	
	var circle = get_node("FlatCircle")
	if curStatus == "BEING_TRAVELED_TO" or curStatus == "BEING_WORKED_ON":
		circle.modulate = Color.WEB_GRAY
	
	if curStatus == "COMPLETED":
		circle.modulate = Color.DODGER_BLUE
	
	# TODO: update symbol on circlebar
	
func updateEvent(eventPayload):
	self.ogEvent = eventPayload
	self.eventId = eventPayload.id
	self.eventTitle = eventPayload["title"]
	self.duration = eventPayload["duration"]
	self.startDuration = duration
	self.stats = []
	for stat in eventPayload["stats"]:
		self.stats.append(stat)
	var hintString = "\nDetails:\n"
	for hint in eventPayload["hints"]:
		hintString += "- " + hint + "\n"
	self.eventDetails = eventPayload["details"] + "\n" + hintString
	
	self.size = Vector2(80, 80)
	#var styleBoxRef = load("res://radial_crop.tres")
	#self.add_theme_stylebox_override("normal", styleBoxRef)
	
func _enter_tree():
	self.main = get_tree().current_scene
	
	var circleBar = get_node("CircleBar")
	circleBar.position = Vector2(-8, -8)
	circleBar.size = size 
	#circleBar.texture_under = makeSimpleColorTexture(Color.RED)
	#circleBar.texture_progress = makeSimpleColorTexture(Color.GREEN)
	circleBar.fill_mode = TextureProgressBar.FILL_CLOCKWISE
	
	var label = get_node("TextureRect")
	label.size = size - Vector2(24, 24)
	label.position = Vector2(12, 12)
	label.mouse_filter = MOUSE_FILTER_IGNORE
	
	var circle = get_node("FlatCircle")
	circle.size = label.size + Vector2(12, 12)
	circle.position = label.position - Vector2(6, 6)
	circle.modulate = Color.ORANGE
		
	circle.connect("mouse_entered", func():
		if curStatus != "BEING_TRAVELED_TO" and curStatus != "BEING_WORKED_ON":
			circle.modulate = Color.DARK_ORANGE
			if curStatus == "COMPLETED":
				circle.modulate = Color.DEEP_SKY_BLUE

		var tooltipScene = preload("res://common/CoolWindow.tscn")
		tooltip = tooltipScene.instantiate()
		tooltip.title = eventTitle
		add_child(tooltip)
		tooltip.position = Vector2(100, 0)
		tooltip.size = Vector2(420, 140)
		
		# if the tooltip would go offscreen, put it below and onscreen
		var viewport = get_viewport_rect()
		if tooltip.global_position.x + tooltip.size.x >= viewport.size.x:
			tooltip.position.y = self.size.y + 15
			tooltip.global_position.x = viewport.size.x - tooltip.size.x - 10
		
		tooltip.z_index = 2 # above other events
		if chosenChars.size() == 0:
			# limit height if no chars are assigned
			tooltip.size = Vector2(420, 60)
		tooltip.adjustBounds()
		
		# add CSP stand ins for cur chars on this event,
		# if any
		for idx in range(chosenChars.size()):
			var csp = CSP.new(97, chosenChars[idx], [])
			csp.visualOnly = true
			tooltip.add_child(csp)
			csp.position.y = 80
			csp.position.x = 20 + idx * 102
		
		tooltip.tweenIn(Vector2(650, 100))
	)
	circle.connect("mouse_exited", func():
		if wasFreed:
			return # we were removed
		if tooltip:
			tooltip.tweenOut()
		if curStatus != "BEING_TRAVELED_TO" and curStatus != "BEING_WORKED_ON":
			return
			circle.modulate = Color.ORANGE
			if curStatus == "COMPLETED":
				circle.modulate = Color.DODGER_BLUE
	)
func _exit_tree() -> void:
	wasFreed = true

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		wasFreed = true

func _process(delta: float):
	if isPaused:
		return
		
	var circleBar = get_node("CircleBar")
	if curStatus == "TICKING":
		duration -= delta
		
		circleBar.value = 100 * (duration / startDuration)
		if duration <= 0:
			# TODO: log a miss?
			queue_free()
	
	if curStatus == "BEING_WORKED_ON":
		if chosenChars.size() == 0:
			# this shouldn't happen TODO: error
			print("Event is being worked on, but chosenChars is empty!")
			return
		var arrivedPercent = float(arrivedCount) / chosenChars.size()
		# if we have one char, and it's a lone wolf, halve completion time
		var charBar = get_tree().current_scene.get_node("CharBar")
		if chosenChars.size() == 1 and charBar.getTrait(chosenChars[0]):
			arrivedPercent *= 2
		duration += delta * arrivedPercent # slower by the amount of who has yet to come
		circleBar.value = 100 * (duration / 10.0) # hardcoded, always takes 10 seconds TODO: make dynamic
		if duration >= 10.0 and arrivedPercent >= 1:
			# WE'RE DONE! switch to the next state, and make a grid icon to go back and stuff
			updateStatus("COMPLETED")
			# send them back
			charBar.startTravelling(chosenChars, null, position + Vector2(40, 40), Vector2(460, 460))
				

func _input(event):
	if event is InputEventMouseButton:
		#print(get_rect(), event.position, self.get_rect().has_point(event.position))
		if self.get_rect().has_point(event.position):
			if curStatus == "TICKING":
				main.event_selected.emit(eventId)
			if curStatus == "COMPLETED":
				# review it / play animation
				main.event_selected.emit(eventId, true)
			
