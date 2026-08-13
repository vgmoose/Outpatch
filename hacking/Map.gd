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
		circle.position = Vector3(pos[0], 0, pos[1]) * 2
		# link up neighbors
		for n in cur["next"]:
			if n in seen:
				continue
			to_process.append(n)
			seen[n] = true
			# draw the actual line
			var lineScene = preload("res://hacking/Line.tscn")
			var line = lineScene.instantiate()
			add_child(line)
			var nPos = conns[n]["pos"]
			var v1 = Vector2(nPos[0], nPos[1])
			var v2 = Vector2(pos[0], pos[1])
			var newPos = (v1 + v2) / 2.0
			line.position = Vector3(newPos[0], 0, newPos[1]) * 2
			# rotate the line as needed
			var normed = abs(v2 - v1).normalized()
			if normed.x == 1:
				line.rotation += Vector3(0, PI/2, 0)
		
