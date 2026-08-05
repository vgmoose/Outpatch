extends TextureProgressBar
class_name EventCircle

var trueValue: float = 100.0
var isPaused = false

var eventId = 0
var main: Main = null

static func makeSimpleColorTexture(color: Color):
	var out = GradientTexture2D.new()
	out.gradient = Gradient.new()
	out.gradient.set_color(0, color)
	out.gradient.set_color(1, color)
	return out

func _init(eventId):
	self.eventId = eventId
	
	self.size = Vector2(360, 360)
	self.texture_under = makeSimpleColorTexture(Color.RED)
	self.texture_progress = makeSimpleColorTexture(Color.GREEN)
	self.fill_mode = FILL_CLOCKWISE

func _enter_tree():
	self.main = get_tree().current_scene
	
func _process(delta: float):
	if isPaused:
		return
	trueValue -= delta * 10
	self.value = trueValue
	if trueValue <= 0:
		queue_free()

func _input(event):
	if event is InputEventMouseButton:
		#print(get_rect(), event.position, self.get_rect().has_point(event.position))
		if self.get_rect().has_point(event.position):
			main.event_selected.emit(eventId)
