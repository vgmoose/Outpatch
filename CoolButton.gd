extends TextureButton
class_name CoolButton

@export var initialLabel = ""

func _enter_tree():
	var label = get_node("Label")
	label.size = size
	label.mouse_filter = MOUSE_FILTER_PASS
	if initialLabel:
		label.text = initialLabel

	#if "windowTint" in Main.gameConfigData:
		#texture_normal.modulate = Main.gameConfigData["windowTint"]
		#texture_normal.modulate = modulate.darkened(0.2)

func set_text(labelText):
	var label = get_node("Label")
	label.text = labelText
