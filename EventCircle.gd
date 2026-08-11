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

static func makeSimpleColorTexture(color: Color):
	var out = GradientTexture2D.new()
	out.gradient = Gradient.new()
	out.gradient.set_color(0, color)
	out.gradient.set_color(1, color)
	return out

func updateStatus(newStatus):
	curStatus = newStatus
	# also, stop ticking at this point, since tahts' the initial state
	get_node("CircleBar").visible = false

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
	circleBar.texture_under = makeSimpleColorTexture(Color.RED)
	circleBar.texture_progress = makeSimpleColorTexture(Color.GREEN)
	circleBar.fill_mode = TextureProgressBar.FILL_CLOCKWISE

func _process(delta: float):
	if isPaused or curStatus != "TICKING":
		return
	duration -= delta
	
	var circleBar = get_node("CircleBar")
	circleBar.value = 100 * (duration / startDuration)
	if duration <= 0:
		queue_free()

func _input(event):
	if event is InputEventMouseButton:
		#print(get_rect(), event.position, self.get_rect().has_point(event.position))
		if self.get_rect().has_point(event.position):
			if curStatus == "TICKING":
				main.event_selected.emit(eventId)
			if curStatus == "COMPLETE":
				# review it / play animation
				main.event_selected.emit(eventId, true)
			
