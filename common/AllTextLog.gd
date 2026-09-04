extends ColorRect
class_name AllTextLog

var actualText = null
var windowBounds = Vector2(0, 0)
var startPos = Vector2(0, 0)

var startingText = "[Conversation mesages will appear here]"

func _enter_tree():
	actualText = get_node("AllTextText")
	actualText.text = startingText
	actualText.size = size - Vector2(40, 40)
	windowBounds = actualText.size
	startPos = self.position
	
	actualText.position = Vector2(20, 20)
	
	# close window in top right
	var closeWindow = get_node("CloseButton")
	closeWindow.connect("pressed", func():
		dismiss()
	)
	
func dismiss():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", Vector2(startPos.x + self.size.x, 0), 0.33)
	tween.tween_callback(func(): visible = false)

func showLog():
	visible = true
	position.x = startPos.x + self.size.x
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", Vector2(startPos.x, 0), 0.33)

func log(line, newSegment=false):
	# TOOD: timestamp?
	if startingText == actualText.text:
		# clear the beginning text
		actualText.text = ""
	elif newSegment:
		actualText.text += "\n"
	actualText.text += line + "\n"
	actualText.size = windowBounds
