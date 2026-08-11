extends Node2D
class_name CharGridIcon

var dest = Vector2(0, 0) # x, y coor of where to move to over time
var speed = 100

func updateImg(charBar: CharBar, charName: String):
	var inner: Sprite2D = get_node("CharGridIcon/Sprite2D")
	var texture = load("res://csps/" + charName + ".png")
	if not texture:
		texture = load("res://csps/Unknown.jpg")
		inner.scale = Vector2(0.8, 0.7)
	inner.texture = texture
	var border = get_node("Border")
	border.modulate = charBar.getColor(charName).darkened(0.2)
	
	speed = 500 * charBar.getStats(charName)[2] # mobility

func _process(delta):
	var main = get_tree().current_scene
	if not main.isPaused:
		position = position.move_toward(dest + Vector2(40, 40), delta * speed)
