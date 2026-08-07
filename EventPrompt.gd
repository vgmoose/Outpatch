extends ColorRect
class_name EventPrompt

var charBarHeight = 0
var wasPressed = false

func _enter_tree():
	var main = get_tree().current_scene
	charBarHeight = main.get_node("CharBar").size.y

func display(title, details, eventWeights):
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
	button.connect("pressed", func():
		if wasPressed:
			return 
		wasPressed = true
		var starGraphHolder = get_node("StarGraphHolder")
		if starGraphHolder.get_children().size() < 2:
			# we don't have any heroes added
			return
		# remove the previously generated merged graph
		# so that we can retween it in
		var mergedGraph = starGraphHolder.get_children()[starGraphHolder.get_children().size()-1] # assume it's at the end
		starGraphHolder.remove_child(mergedGraph)

		# start the simulation, reveal true probabilities
		var trueGraph = StarGraph.new(Color.DARK_RED)
		trueGraph.update_graph(eventWeights)
		var truePolygon = trueGraph.polygon # update_graph applies our weights to the actual polygon shape
		starGraphHolder.add_child(trueGraph)
		
		# tween our actual probabilities back in
		starGraphHolder.add_child(mergedGraph)
		var tween = get_tree().create_tween()
		
		var finalPolygon = mergedGraph.polygon
		
		# start physics simulation?
		# first, find intersecting polygon

		# and then the area of the outer
		var outer = calculate_area(truePolygon)
		# percent success is straightforwards
		var label = Label.new()
		label.text = "0%"
		label.add_theme_font_size_override("font_size", 65)
		starGraphHolder.add_child(label)
		
		mergedGraph.polygon = [Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)]
		trueGraph.polygon = [Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)]
		
		# tween in the base, then our merged, and update the percent along the way
		tween.tween_property(trueGraph, "polygon", truePolygon, 2)
		tween.tween_property(mergedGraph, "polygon", finalPolygon, 2)
		tween.parallel().tween_method((func(cur):
			# we ignore cur, because we're just going to use the polygon that's growing into place
			# get the area of the inner (overlap/clipped) polygon(s)
			var inner = 0.0
			var commongons = Geometry2D.clip_polygons(trueGraph.polygon, mergedGraph.polygon)
			for common in commongons:
				inner += calculate_area(common)
			label.text = "%0.2f%%" % abs(100 - ((inner / outer) * 100))
		), 0, 0, 2)
		
		tween.tween_callback(func():
			# this is called after the above animations are done, kick off the ball moving in a random direction
			# with the collision of the merged polygon
			var collisionChart = starGraphHolder.get_node("CollisionChart")
			var collider = collisionChart.get_node("CollisionPolygon2D")
			collider.polygon = truePolygon
			# for visualizing only
			#var siblinggon = collisionChart.get_node("Polygon2D")
			#siblinggon.color = Color.BLUE
			#siblinggon.polygon = truePolygon
			var theBall = starGraphHolder.get_node("BouncyBall")
			collisionChart.position = mergedGraph.position
			theBall.position = mergedGraph.position # TODO: this assumes firstchild is the empty chart
			theBall.velocity = Vector2(-640, -570)
			starGraphHolder.remove_child(theBall)
			starGraphHolder.add_child(theBall)
			theBall.visible = true
			
		)
		
	)
	
	var cancel = get_node("Button2")
	cancel.connect("pressed", func():
		# unpause everything and return back to business
		main.unpause.emit()
	)
	visible = true
	
# Gauss's shoelace formula, to get the area of a polygon
# https://gamedev.stackexchange.com/a/211635
func calculate_area(mesh_vertices: PackedVector2Array) -> float:
	var result := 0.0
	var num_vertices := mesh_vertices.size()

	for q in range(num_vertices):
		var p = (q - 1 + num_vertices) % num_vertices
		result += mesh_vertices[q].cross(mesh_vertices[p])

	return abs(result) * 0.5
	
#func removeChar(charName):
	#for child in get_children():
		#if child is CSP and child.myName = charName:
			#

func position_csps(skipMe = null):
	var cspCount = 0
	for curCsp in get_children():
		if curCsp is CSP and curCsp != skipMe:
			cspCount += 1
	
	var curWeights = [] # array of array of weights for each selected char
	var curOff = self.size.x / 2 - (cspCount * charBarHeight) / 2
	for curCsp in get_children():
		if curCsp is CSP and curCsp != skipMe:
			curCsp.position.x = curOff
			curCsp.position.y = self.position.y + self.size.y - 2*charBarHeight
			curOff += charBarHeight
			curWeights.append(curCsp.myWeights)
	
	# clear current star graphs and make new ones for each char
	var starGraphHolder = get_node("StarGraphHolder")
	starGraphHolder.position.x = self.size.x / 2
	for oldGraph in starGraphHolder.get_children():
		if oldGraph is StarGraph:
			starGraphHolder.remove_child(oldGraph)
	
	# background of chart
	var emptyGraph = StarGraph.new(Color.WEB_GRAY)
	starGraphHolder.add_child(emptyGraph)

	# merging logic
	var gold = Color.GOLD
	gold.a = 0.6
	var mergedGraph = StarGraph.new(gold)
	starGraphHolder.add_child(mergedGraph)
	var mergedWeights: Array[float] = [0.0,0.0,0.0,0.0,0.0]
	for weights in curWeights:
		for wIdx in range(5):
			mergedWeights[wIdx] = max(mergedWeights[wIdx], weights[wIdx])
	mergedGraph.update_graph(mergedWeights)
	
	# individual char overlays
	#var colorIdx = 0
	#var colors = [Color.RED, Color.BLUE, Color.GREEN]
	#for weights in curWeights:
		#var newWeights: Array[float] = []
		#for w in weights:
			#newWeights.append(w) # TODO: handle typing issue a better way
		#colors[colorIdx].a = 0.3
		#var starGraph = StarGraph.new(colors[colorIdx])
		#starGraphHolder.add_child(starGraph)
		#colorIdx += 1
		#colorIdx = colorIdx % 3 # TODO: load color from char prefs
		#starGraph.update_graph(newWeights)

func addChar(charName, charWeights):
	# check if we exist first
	for csp in get_children():
		if csp is CSP and csp.myName == charName:
			return
	# create a CSP for this fella
	var csp = CSP.new(charBarHeight, charName, charWeights)
	add_child(csp)
	csp.selectedPrompt = self
	csp.position.y = self.position.y - charBarHeight
	# update children
	position_csps()
