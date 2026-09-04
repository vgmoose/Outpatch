extends Tree

@export var jsonPath = ""

func _ready():
	var tree = self
	var root = tree.create_item()
	tree.hide_root = true
	
	var eventFileData = FileAccess.get_file_as_string(jsonPath)
	var jsonEventData = JSON.parse_string(eventFileData)
	var eventStream = jsonEventData["events"]
	# let's convert some condensed info into key-value pairs, to make it easier to edit
	for event in eventStream:
		if event["stats"]:
			var vals = event["stats"]
			event.erase("stats")
			var labels = ["com", "vig", "mob", "cha", "int"]
			for v in range(5):
				event["stats_" + labels[v]] = vals[v]
		if event["hints"]:
			var vals = event["hints"]
			event.erase("hints")
			for hIdx in range(4):
				var curHint = ""
				if hIdx < vals.size():
					curHint = vals[hIdx]
				event["hint_" + str(hIdx + 1)] = curHint
			
				
	build_tree(tree, root, eventStream)

func build_tree(tree, root, payload):
	for event in payload:
		var child1 = tree.create_item(root)
		for key in event:
			var child2 = tree.create_item(child1)
			print(key)
			child2.set_text(0, key)
			if event[key] is Array:
				# recurse
				# actually, arrays aren't supported yet (user would need to resize)
				#build_tree(tree, child2, event[key])
				continue
			if event[key] is Object:
				build_tree(tree, child2, event[key])
				continue
			child2.set_editable(1, true)
			if event[key] is float:
				child2.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
				child2.set_range(1, event[key])
			if event[key] is String:
				child2.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
				child2.set_text(1, event[key])
