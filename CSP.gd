extends TextureRect
class_name CSP

var mySize = 0.0
var myTexture = null
var myName = "Unknown"
var isChosen = false

var myWeights = [0,0,0,0,0]

# if this CSP was chosen / is in the prompt
var selectedPrompt = null

func _init(dimen, charName, charWeights):
	mySize = dimen
	myName = charName
	myTexture = load("res://csps/" + charName + ".webp.png")
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
