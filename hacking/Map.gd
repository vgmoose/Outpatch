extends Node3D
class_name Map

func _enter_tree():
	position -= Vector3(0.03, 0, -0.025)
	var conns = {
		"start": {
			"pos": [0, 0],
			"next": ["1"]
		},
		"1": {
			"pos": [1, 0],
			"next": ["2", "3"]
		},
		"2": {
			"pos": [2, 0],
			"next": []
		},
		"3": {
			"pos": [1, 1],
			"next": []
		}
	}
	
	# build a simple look up by coordinate (node ID if valid pos)
	var lookup = {}
	
	# convert the next lists into sets, and also make vectors
	for key in conns:
		var oldPos = conns[key]["pos"]
		var oldNext = conns[key]["next"]
		conns[key]["pos"] = Vector2(oldPos[0], oldPos[1])
		conns[key]["next"] = {}
		for n in oldNext:
			conns[key]["next"][n] = true
		lookup[conns[key]["pos"]] = key
	
	var seen = {}
	var to_process = ["start"]
	while to_process.size() > 0:
		var curId = to_process.pop_front()
		var cur = conns[curId]
		# draw current circle
		var circleScene = preload("res://hacking/Dot.tscn")
		var circle = circleScene.instantiate()
		add_child(circle)
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
			# draw the actual line
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
	
	# assign these maps to the dice
	var dice = get_node("../Dice")
	dice.conns = conns
	dice.lookup = lookup
		
