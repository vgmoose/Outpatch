extends TextureButton
class_name CoolButton

@export var initialLabel = ""

func _enter_tree():
	var label = get_node("Label")
	label.size = size
	label.mouse_filter = MOUSE_FILTER_PASS
	if initialLabel:
		label.text = initialLabel

func set_text(labelText):
	var label = get_node("Label")
	label.text = labelText
