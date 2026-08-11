extends TextureRect
class_name CSP

var mySize = 0.0
var myTexture = null
var myName = "Unknown"

var overlay = null

var myWeights = [0,0,0,0,0]
var statusLabel = null
var statusStyleRef = null

var curState = "READY" # READY, TRAVELING, WORKING, RESTING

# if this CSP was chosen / is in the prompt
var selectedPrompt = null

func _init(dimen, charName, charWeights):
	mySize = dimen
	myName = charName
	myTexture = load("res://csps/" + charName + ".png")
	if not myTexture:
		# fallback
		myTexture = load("res://csps/Unknown.jpg")
	myWeights = charWeights

func _enter_tree():
	var csp = self
	var main = get_tree().current_scene
	csp.size.x = mySize
	csp.size.y = mySize
	csp.texture = myTexture
	csp.expand_mode = TextureRect.ExpandMode.EXPAND_FIT_HEIGHT_PROPORTIONAL
	csp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	csp.connect("mouse_entered", func():
		if curState != "READY":
			return
		if main.isPaused:
			var dest = Vector2(position.x, position.y - 20)
			var tween = get_tree().create_tween()
			tween.tween_property(csp, "position", dest, 0.1)
	)
	csp.connect("mouse_exited", func():
		if csp.position.y == 0:
			return
		var dest = Vector2(position.x, 0)
		if selectedPrompt:
			dest = Vector2(position.x, position.y + 20) # has to be relative, for mini icon
		if main.isPaused:
			var tween = get_tree().create_tween()
			tween.tween_property(csp, "position", dest, 0.1)
	)
	var button = Button.new()
	csp.add_child(button)
	button.text = myName.to_upper()
	button.size.x = csp.size.x
	#button.position.y = csp.size.y - button.size.y
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_theme_font_size_override("font_size", 24)
	
	overlay = ColorRect.new()
	overlay.color = Color.DIM_GRAY
	overlay.color.a = 0.45
	overlay.size = csp.size
	overlay.visible = true
	csp.add_child(overlay)
	
	statusLabel = Button.new()
	csp.add_child(statusLabel)
	statusLabel.size.x = csp.size.x
	statusLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	statusStyleRef = StyleBoxFlat.new()
	statusLabel.add_theme_font_size_override("font_size", 24)
	statusLabel.add_theme_stylebox_override("normal", statusStyleRef)
	updateStatus()

func updateStatus():
	statusStyleRef.bg_color = Color.DARK_SLATE_BLUE
	if curState == "READY" or curState == "ASSIGNED":
		statusLabel.visible = false
	else:
		statusLabel.visible = true
	statusLabel.text = curState # READY, resting, traveling, working
	overlay.visible = curState == "ASSIGNED"

func _input(event):
	var main = get_tree().current_scene
	if event is InputEventMouseButton:
		if event.is_pressed():
			if self.get_global_rect().has_point(event.position):
				if selectedPrompt:
					main.choose_char.emit(myName, false)
					return
				if curState != "READY" or not main.isPaused:
					return # can't be chosen twice
				main.choose_char.emit(myName)
				
