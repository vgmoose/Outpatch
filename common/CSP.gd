extends TextureRect
class_name CSP

var mySize = 0.0
var myTexture = null
var myName = "Unknown"
var displayName = null

var visualOnly = false

var overlay = null
var restMeter = 15

var myWeights = [0,0,0,0,0]
var statusLabel = null
var statusStyleRef = null
var main = null

var curState = "READY" # READY, TRAVELING, WORKING, RESTING

var charBarRef = null
# if this CSP was chosen / is in the prompt
var selectedPrompt = null
var recoveryBar = null

var startPositionY = null

func _init(dimen, charName, charWeights):
	mySize = dimen
	myName = charName
	self.displayName = displayName
	myTexture = load("res://images/csps/Unknown.jpg")
	myWeights = charWeights

func _enter_tree():
	var csp = self
	main = get_tree().current_scene
	charBarRef = main.get_node("CharBar")
	csp.size.x = mySize
	csp.size.y = mySize
	
	# setup the actual CSP image
	myTexture = CSP.loadCharTexture(charBarRef, myName)
	
	# set the texture directly
	
	csp.texture = myTexture
	csp.expand_mode = TextureRect.ExpandMode.EXPAND_FIT_HEIGHT_PROPORTIONAL
	csp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	if visualOnly:
		return # no text label in this case
	if "displayName" in charBarRef.charStates[myName]:
		displayName = charBarRef.charStates[myName]["displayName"]
	
	csp.connect("mouse_entered", func():
		if startPositionY == null:
			# we set this _one time_ at the first mouse over, as our reference point for future up/down tweens
			startPositionY = position.y
		if curState != "READY" and curState != "ASSIGNED":
			return
		if selectedPrompt and charBarRef.getStatus(myName) != "ASSIGNED":
			return # no mouse over events for mini CSP's if not on the assignment phase
		if main.isPaused:
			z_index = 2
			var dest = Vector2(position.x, startPositionY - 20)
			var tween = get_tree().create_tween()
			tween.tween_property(csp, "position", dest, 0.1)
	)
	csp.connect("mouse_exited", func():
		if csp.position.y == 0:
			return
		if selectedPrompt and charBarRef.getStatus(myName) != "ASSIGNED":
			return # no mouse over events for mini CSP's if not on the assignment phase
		var dest = Vector2(position.x, startPositionY) # back to initial pos
		if main.isPaused:
			var tween = get_tree().create_tween()
			tween.tween_property(csp, "position", dest, 0.1)
			tween.tween_callback(func(): z_index = 0)
	)
	var button = Button.new()
	csp.add_child(button)
	button.text = myName.to_upper()
	if displayName:
		button.text = displayName.to_upper()
	button.size.x = csp.size.x
	#button.position.y = csp.size.y - button.size.y
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_theme_font_size_override("font_size", 24)
	
	if selectedPrompt:
		# this csp is being displayed in the selector prompt, if it has an altName, display a switcher buttone
		var isAssignScreen = charBarRef.getStatus(myName) == "ASSIGNED"
		if isAssignScreen and "altName" in charBarRef.charStates[myName]:
			var swappa = Button.new()
			csp.add_child(swappa)
			swappa.text = "Change Form"
			swappa.size.x = csp.size.x
			swappa.position.y = csp.size.y
			swappa.connect("pressed", func():
				var altName = charBarRef.charStates[myName]["altName"]
				#csp.texture = load("res://images/csps/" + altName + ".png")
				charBarRef.markSeenHidden(myName, altName)
				
				var chosenChars = selectedPrompt.chosenChars.duplicate()
				# remove all chars
				for char in chosenChars:
					main.choose_char.emit(char, false)
				# then re-add all, but swapping out myName -> altName
				for char in chosenChars:
					if char == myName:
						main.choose_char.emit(altName)
					else:
						main.choose_char.emit(char)
			)
			swappa.add_theme_font_size_override("font_size", 24)
		#return
	
	overlay = ColorRect.new()
	overlay.color = Color.DIM_GRAY
	overlay.color.a = 0.45
	overlay.size = csp.size
	overlay.visible = true
	overlay.mouse_filter = MOUSE_FILTER_IGNORE
	csp.add_child(overlay)
	
	statusLabel = Button.new()
	csp.add_child(statusLabel)
	statusLabel.size.x = csp.size.x
	statusLabel.text = curState # so the height is right later
	statusLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	statusStyleRef = StyleBoxFlat.new()
	statusLabel.add_theme_font_size_override("font_size", 24)
	statusLabel.add_theme_stylebox_override("normal", statusStyleRef)
	updateStatus()
	
	# simple progress bar that will show their recovery status
	recoveryBar = ProgressBar.new()
	csp.add_child(recoveryBar)
	recoveryBar.size.x = statusLabel.size.x
	recoveryBar.size.y = statusLabel.size.y
	recoveryBar.show_percentage = false
	recoveryBar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recoveryBar.value = 0.5
	recoveryBar.visible = false
	
	
static func loadCharTexture(charBar, charName):
	# TODO: allow loading from an external folder, for easy customization
	var cspImage = Image.load_from_file("res://images/csps/" + charName + ".png")
	var bgColor = ImageTexture.create_from_image(cspImage).image
	var charBg = charBar.getColor(charName)
	bgColor.fill(charBg.darkened(0.75))
	bgColor.blend_rect(cspImage, bgColor.get_used_rect(), Vector2(0, 0))
	var texture = ImageTexture.create_from_image(bgColor)
	if texture:
		return texture
	return load("res://images/csps/Unknown.jpg") # placeholder


func updateStatus():
	statusStyleRef.bg_color = Color.DARK_SLATE_BLUE
	if curState == "READY" or curState == "ASSIGNED":
		statusLabel.visible = false
	else:
		statusLabel.visible = true
	statusLabel.text = curState # READY, resting, traveling, working
	overlay.visible = curState == "ASSIGNED" or curState == "UNAVAILABLE"

func _input(event):
	if visualOnly:
		return
	var main = get_tree().current_scene
	if event is InputEventMouseButton:
		if event.is_pressed() and visible:
			if self.get_global_rect().has_point(event.position):
				if selectedPrompt or curState == "ASSIGNED":
					# unassaign!
					# actually, make sure that our char name is assigned in the first place
					if charBarRef.getStatus(myName) == "ASSIGNED":
						main.choose_char.emit(myName, false)
					return
				if curState != "READY" or not main.isPaused:
					return # can't be chosen twice
				main.choose_char.emit(myName)

func _process(delta):
	if visualOnly:
		return
	if not charBarRef:
		return
	if main.isPaused:
		return
	if selectedPrompt:
		return # ON the Prompt screen, don't do any tick downs
	# if resting, tick down our restMeter
	if charBarRef.getStatus(myName) == "RESTING":
		recoveryBar.visible = true
		restMeter -= delta
		recoveryBar.value = 100 * (restMeter / 15.0)
		if restMeter <= 0:
			# we're recovered!
			restMeter = 15 # for next time
			charBarRef.updateStatus(myName, "READY")
			recoveryBar.visible = false
			
