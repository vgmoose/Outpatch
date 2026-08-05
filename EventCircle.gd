extends TextureProgressBar
class_name EventCircle

var isPaused = false

var eventId = 0
var main: Main = null

var eventTitle = "Unknown"
var eventDetails = "???"
var duration = 0.0
var startDuration = 1.0
var stats: Array[float] = [0, 0, 0, 0, 0]

static func makeSimpleColorTexture(color: Color):
	var out = GradientTexture2D.new()
	out.gradient = Gradient.new()
	out.gradient.set_color(0, color)
	out.gradient.set_color(1, color)
	return out

func _init(eventPayload):
	self.eventId = eventPayload.id
	self.eventTitle = eventPayload["title"]
	self.duration = eventPayload["duration"]
	self.startDuration = duration
	self.stats = []
	for stat in eventPayload["stats"]:
		self.stats.append(stat)
	var hintString = ""
	for hint in eventPayload["hints"]:
		hintString += hint + "\n\nHints:\n"
	self.eventDetails = eventPayload["details"] + "\n" + hintString
	
	self.size = Vector2(360, 360)
	self.texture_under = makeSimpleColorTexture(Color.RED)
	self.texture_progress = makeSimpleColorTexture(Color.GREEN)
	self.fill_mode = FILL_CLOCKWISE

func _enter_tree():
	self.main = get_tree().current_scene
	
func _process(delta: float):
	if isPaused:
		return
	duration -= delta
	self.value = 100 * (duration / startDuration)
	if duration <= 0:
		queue_free()

func _input(event):
	if event is InputEventMouseButton:
		#print(get_rect(), event.position, self.get_rect().has_point(event.position))
		if self.get_rect().has_point(event.position):
			main.event_selected.emit(eventId)
