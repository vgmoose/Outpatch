extends Node3D

func _enter_tree():
	var goBack = get_node("GoBack")
	goBack.connect("pressed", func():
		var root = get_tree().current_scene
		var dimmer = root.get_node("Dimmer")
		var subview = root.get_node("ExternalScene")
		root.isPaused = false
		var tween = get_tree().create_tween()
		tween.tween_property(dimmer, "modulate:a", 0, 0.4)
		tween.parallel().tween_property(subview, "position", Vector2(subview.position.x, subview.position.y + subview.size.y*2), 0.4)
		tween.tween_callback(func():
			dimmer.visible = false
			subview.visible = false
			queue_free()
		)
	)
