extends Node3D
class_name Map

func _enter_tree():
	position -= Vector3(0.03, 0, -0.025)
	var conns = {}
	var lookup = {}
	var passData = {}
	var doorData = {}
		
	# TODO:  load appropriate file for current mission
	var mapFile = FileAccess.open("res://data/hacking1.csv", FileAccess.READ)
	var content = mapFile.get_as_text()
	var y = 0
	var x = 0
	var id = 0
	for line in content.split("\n"):
		var vals = line.split("\t")
		if vals.size() == 0:
			continue
		if vals[0] == "pass":
			passData[vals[1]] = vals[2]
			continue
		if vals[0] == "door":
			doorData[vals[1]] = vals[2]
			continue
		for c in vals:
			x += 1
			if c == "":
				continue
			id += 1
			var curId = str(id)
			if c == "s":
				curId = "start"
			conns[curId] = {
				"pos": Vector2(x, y),
				"next": {}
			}
			if c.begins_with("p"):
				conns[curId]["pass"] = c[1]
			if c.begins_with("l"):
				conns[curId]["lock"] = c[1]
			if c.begins_with("d"):
				conns[curId]["door"] = c[1]
			if c == "g":
				conns[curId]["isGoal"] = true
			lookup[Vector2(x, y)] = curId
		y += 1
		x = 0

	# for each entry, look up any neighbors, and link their cells
	for pos in lookup:
		var neighs = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, 1), Vector2(0, -1)]
		for n in neighs:
			if pos + n in lookup:
				# assume we have a connection between these two
				conns[lookup[pos]]["next"][lookup[pos + n]] = true

	# build a simple look up by coordinate (node ID if valid pos)
	if "start" not in conns:
		print("Missing [start] node")
		return
	
	var doorLookup = {} # map of half-position -> door ID
	for conn in conns:
		if "door" in conns[conn]:
			var doorId = conns[conn]["door"]
			var dir = doorData[doorId]
			var rels = {
				"u": Vector2(0, -1),
				"d": Vector2(0, 1),
				"l": Vector2(-1, 0),
				"r": Vector2(1, 0)
			}
			var halfPos = rels[dir] / 2.0 + conns[conn]["pos"]
			doorLookup[halfPos] = doorId
			
	# start drawing the actual grid
	var doorDataObjMap = {} # map of door id to actual line object
	var seen = {}
	var to_process = ["start"]
	while to_process.size() > 0:
		var curId = to_process.pop_front()
		var cur = conns[curId]
		# draw current circle
		var circleScene = preload("res://hacking/Dot.tscn")
		var circle = circleScene.instantiate()
		add_child(circle)
		
		if "hackingTint" in Main.gameConfigData:
			circle.mesh.material.albedo_color = Main.gameConfigData["hackingTint"]
			circle.mesh.material.albedo_color = circle.mesh.material.albedo_color.darkened(0.5)
		
		if "pass" in conns[curId]:
			circle.mesh = circle.mesh.duplicate()
			circle.mesh.material = circle.mesh.material.duplicate()
			circle.mesh.material.albedo_color = Color.PURPLE
		if "lock" in conns[curId]:
			circle.mesh = circle.mesh.duplicate()
			circle.mesh.material = circle.mesh.material.duplicate()
			circle.mesh.material.albedo_color = Color.DARK_BLUE
		
		var pos = cur["pos"]
		circle.position = Vector3(pos.x, 0, pos.y) * 2
		# link up neighbors
		for n in cur["next"]:
			if n in seen:
				continue
			to_process.append(n)
			seen[n] = true
			# always back link, in case the original data was one way
			conns[n]["next"][curId] = true

			var lineScene = preload("res://hacking/Line.tscn")
			var line = lineScene.instantiate()
			add_child(line)
			var nPos = conns[n]["pos"]
			var newPos = (nPos + pos) / 2.0
			line.position = Vector3(newPos.x, 0, newPos.y) * 2
			# rotate the line as needed
			var normed = abs(pos - nPos).normalized()
			if normed.x == 1:
				line.rotation += Vector3(0, PI/2, 0)
				
			# if there's a door where this line would be though, make it not visibel until later
			var halfPos = (conns[n]["pos"] + conns[curId]["pos"]) / 2.0
			if halfPos in doorLookup:
				line.visible = false
				# also log its location for later
				doorDataObjMap[doorLookup[halfPos]] = line
	
	# assign these maps to the dice
	var dice = get_node("../Dice")
	dice.conns = conns
	dice.lookup = lookup
	
	# also put it in its start pos
	var startPos = conns["start"]["pos"]
	dice.position = Vector3(startPos.x * 2, 0, startPos.y * 2)
	dice.curPos = startPos
	dice.passData = passData
	
	dice.doorData = doorDataObjMap
	dice.doorLookup = doorLookup
