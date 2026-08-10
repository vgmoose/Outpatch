extends TextureRect
class_name CSP

var mySize = 0.0
var myTexture = null
var myName = "Unknown"
var isChosen = false

var myWeights = [0,0,0,0,0]
var statusLabel = null
var statusStyleRef = null

var curState = "READY" # READY, ASSIGNED, TRAVELING, WORKING, RESTING

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
		if main.isPaused:
			csp.position.y -= 20
	)
	csp.connect("mouse_exited", func():
		if main.isPaused:
			csp.position.y += 20
	)
	var button = Button.new()
	csp.add_child(button)
	button.text = myName.to_upper()
	button.size.x = csp.size.x
	#button.position.y = csp.size.y - button.size.y
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_theme_font_size_override("font_size", 24)
	
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
	if curState == "READY":
		statusLabel.visible = false
	else:
		statusLabel.visible = true
	statusLabel.text = curState # READY, resting, traveling, working

func _input(event):
	var main = get_tree().current_scene
	if event is InputEventMouseButton:
		if event.is_pressed():
			if self.get_global_rect().has_point(event.position):
				if selectedPrompt:
					selectedPrompt.position_csps(self)
					main.choose_char.emit(myName, false)
					queue_free() # delete us
					return
				if isChosen or not main.isPaused:
					return # can't be chosen twice
				isChosen = true
				main.choose_char.emit(myName)
				var overlay = ColorRect.new()
				var transparentGray = Color.DIM_GRAY
				transparentGray.a = 0.5
				overlay.color = transparentGray
				overlay.size = self.size
				#overlay.position = self.position
				self.add_child(overlay)
