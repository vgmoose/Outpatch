extends Node3D

var fullCodeParts = []
var para = null
var dice = null

var totalDelta = 0 # counter for how often to draw a new bg token

func _enter_tree():
	para = get_node("RichTextLabel")
	para.size = get_node("..").size
	para.scroll_following = true
	
	dice = get_node("Dice")
	
	var fullCodeText = FileAccess.get_file_as_string("res://generated/main.gd.csv")
	for line in fullCodeText.split("\n"):
		var lineStripped = line.strip_edges(true, true)
		if lineStripped.begins_with("#") or lineStripped.begins_with("print"):
			continue # skip comments and prints
		var lineSegs = []
		var commentPos = line.find("#")
		if commentPos >= 0:
			line = line.substr(0, commentPos-1)
		for pos in range(0, line.length(), 3):
			var token = line.substr(pos, 3)
			fullCodeParts.append(token)
		fullCodeParts.append("\n")
	fullCodeParts.reverse()

	var goBack = get_node("GoBack")
	goBack.connect("pressed", func():
		var root = get_tree().current_scene
		var dimmer = root.get_node("Dimmer")
		var subview = root.get_node("ExternalScene")
		root.isPaused = false
		root.animateDimmer(false, true)
		var tween = get_tree().create_tween()
		tween.tween_property(subview, "position", Vector2(subview.position.x, subview.position.y + subview.size.y*2), 0.4)
		tween.tween_callback(func():
			subview.visible = false
			queue_free()
		)
	)

func _process(delta):
	if not dice or not dice.isMoving:
		return
	totalDelta += delta
	if totalDelta < 0.06:
		return 
	totalDelta = 0
	if para:
		if fullCodeParts.size() > 0:
			para.text += fullCodeParts.pop_back()
