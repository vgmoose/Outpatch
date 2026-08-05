extends ColorRect
class_name EventPrompt

var charBarHeight = 0

func _enter_tree():
	var main = get_tree().current_scene
	charBarHeight = main.get_node("CharBar").size.y

func display(title, details):
	var main = get_tree().current_scene
	get_node("RichTextLabel").text = title
	var para = get_node("RichTextLabel2")
	para.text = details
	para.position.y = 150
	para.position.x = 0.1 * self.size.x
	para.size.x = self.size.x * 0.8
	para.size.y = self.size.y * 0.8
	var button = get_node("Button")
	button.position.x = self.size.x - get_node("Button").size.x - 250
	button.position.y = self.size.y - get_node("Button").size.y - 90
	var cancel = get_node("Button2")
	cancel.connect("pressed", func():
		# unpause everything and return back to business
		main.unpause.emit()
	)
	visible = true
	
#func removeChar(charName):
	#for child in get_children():
		#if child is CSP and child.myName = charName:
			#

func position_csps(skipMe = null):
	var cspCount = 0
	for curCsp in get_children():
		if curCsp is CSP and curCsp != skipMe:
			cspCount += 1
	
	var curOff = self.size.x / 2 - (cspCount * charBarHeight) / 2
	for curCsp in get_children():
		if curCsp is CSP and curCsp != skipMe:
			curCsp.position.x = curOff
			curCsp.position.y = self.position.y + self.size.y - 2*charBarHeight
			curOff += charBarHeight

func addChar(charName):
	# check if we exist first
	for csp in get_children():
		if csp is CSP and csp.myName == charName:
			return
	# create a CSP for this fella
	var csp = CSP.new(charBarHeight, charName)
	add_child(csp)
	csp.selectedPrompt = self
	csp.position.y = self.position.y - charBarHeight
	# update children
	position_csps()
