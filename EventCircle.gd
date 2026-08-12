extends Button
class_name EventCircle

var isPaused = false

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
		duration = 0 # we're going to count up
		# show the thing
		circleBar.visible = true
	else:
		# also, stop ticking at this point, since tahts' the initial state
		circleBar.visible = false
	
	var label = get_node("TextureRect")
	if newStatus == "COMPLETED":
		label.texture = preload("res://icons/checked.png")
	else:
		label.texture = preload("res://icons/wip.png") # TODO: more symbols
		
	curStatus = newStatus
	
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
	circleBar.position = Vector2(8, 8)
	circleBar.size = size
	#circleBar.texture_under = makeSimpleColorTexture(Color.RED)
	#circleBar.texture_progress = makeSimpleColorTexture(Color.GREEN)
	circleBar.fill_mode = TextureProgressBar.FILL_CLOCKWISE
	
	var label = get_node("TextureRect")
	label.size = size - Vector2(24, 24)
	label.position = Vector2(12, 12)
	
	#self.connect("mouse_entered", func():
		#var tooltipScene = preload("res://CoolWindow.tscn")
		#tooltip = tooltipScene.instantiate()
		#tooltip.title = eventTitle
		#add_child(tooltip)
		#tooltip.position = Vector2(100, 0)
		#tooltip.size = Vector2(650, 100)
		#tooltip.adjustBounds()
		#tooltip.tweenIn(Vector2(650, 100))
	#)
	#self.connect("mouse_exited", func():
		#if tooltip:
			#tooltip.tweenOut()
	#)

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
		duration += delta
		circleBar.value = 100 * (duration / 5.0) # hardcoded, always takes 5 seconds
		if duration >= 5.0:
			# WE'RE DONE! switch to the next state, and make a grid icon to go back and stuff
			updateStatus("COMPLETED")
			var charBar = get_tree().current_scene.get_node("CharBar")
			# send them back
			charBar.startTravelling(chosenChars, null, position + Vector2(40, 40), Vector2(460, 460))
				

func _input(event):
	if event is InputEventMouseButton:
		#print(get_rect(), event.position, self.get_rect().has_point(event.position))
		if self.get_rect().has_point(event.position):
			print(curStatus)
			if curStatus == "TICKING":
				main.event_selected.emit(eventId)
			if curStatus == "COMPLETED":
				# review it / play animation
				main.event_selected.emit(eventId, true)
			
