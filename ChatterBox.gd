extends ColorRect
class_name ChatterBox

var text = null
var isSpeaking = false

# stores current progress and shuffled future
# blurbs for the given type-key combo
var shuffledCache = {}

var ogData = {}
var initialYPos = 0
var initialTextYSize = 0

func _enter_tree():
	text = get_node("ChatterText")
	initialYPos = self.position.y
	initialTextYSize = text.size.y

func toast(chatterType, keyName):
	if isSpeaking:
		print("Would've said " + chatterType + keyName, " but already speaking")
		return
	var comboKey = chatterType + "-" + keyName
	#if comboKey in shuffledCache:
		#print("KEY ", shuffledCache[comboKey].size(), shuffledCache[comboKey].size() == 0)
	if (comboKey not in shuffledCache) or (shuffledCache[comboKey].size() == 0):
		if chatterType not in self.ogData:
			print("missing type for chatter: " + chatterType)
			return
		if keyName not in self.ogData[chatterType]:
			print("chatter data doesn't contain " + keyName)
			return
		# copy over and shuffle the og data
		var outBlurbs = self.ogData[chatterType][keyName].duplicate()
		outBlurbs.shuffle()
		# TODO: check no repeats on shuffle seam
		shuffledCache[comboKey] = outBlurbs
	# take a new blurb TODO: allow interruptions?
	isSpeaking = true
	var chatter = shuffledCache[comboKey].pop_back()
	if chatter is String:
		chatter = [keyName, chatter] # assume keyName is speaker
	var charBar = get_tree().current_scene.get_node("CharBar")
	var formatMsgs = []
	for idx in range(0, chatter.size(), 2):
		var color = charBar.getColor(chatter[idx])
		var msg = "[color=\"" + color.to_html() + "\"][b]" + chatter[idx] + "[/b]:[/color] " + chatter[idx+1]
		formatMsgs.append(msg)
	if formatMsgs.size() == 0:
		print("No messages?")
		return

	var screenWidth = get_viewport_rect().size.x
	# before we set widths, max out our text area
	# (this lets us then get the content width, which is smaller than max)
	self.text.size.x = screenWidth - 100
	
	# reset position
	self.position.y = initialYPos
	text.size.y = initialTextYSize
	# adjust bg size to max text size of all messages
	var allMsgs = "\n".join(formatMsgs).strip_edges()
	text.text = allMsgs
	self.size.x = text.get_content_width()
	text.size.x = text.get_content_width()
	self.size.x = text.size.x + 40
	text.position = Vector2(20, 0)
	# then, set it to the first message, and do the initial centering
	text.text = formatMsgs[0]
	self.position.x = screenWidth / 2.0 - self.size.x / 2.0
	# set height to height of one
	var oneLineHeight = text.get_content_height()
	self.size.y = oneLineHeight + 20
	text.size.y = oneLineHeight + 20
	
	# update the global all text log, for future review
	var allTextLog = get_node("../AllTextLog")
	allTextLog.log(formatMsgs[0], true)
	
	self.modulate = Color.TRANSPARENT
	visible = true
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.25)
	var delayTime = 3.0
	if formatMsgs.size() > 1:
		delayTime /= 2.0 # half time if we haved more msgs
	tween.tween_interval(delayTime)
	
	# for any repeat messages, enqueue them with 3 sec spacing
	for idx in range(1, formatMsgs.size()):
		tween.tween_callback(func():
			text.text += "\n" + formatMsgs[idx]
			allTextLog.log(formatMsgs[idx])
			# extend the height of the bg
			size.y = 20 + oneLineHeight * (idx+1)
			text.position.y += 10
		)
		tween.tween_property(self, "position", Vector2(
			self.position.x,
			initialYPos-(oneLineHeight/2.0)*idx
		), 0.25)
		tween.parallel().tween_interval(3.5) # extra half second for multimsg TODO: 3-part msgs?
	# hide it at teh end
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.25)
	tween.tween_callback(func():
		self.visible = false
		self.isSpeaking = false
	)
