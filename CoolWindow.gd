extends Node2D
class_name CoolWindow

@export var title = "This is a Test"
@export var size = Vector2(1000, 900)

var canBeMoved = false

var isBeingDragged = false
var isBeingResized = false

var dragGrabOffset = Vector2(0, 0)

func resize_tilemap(incSize, tilelayer: TileMapLayer):
	# round up to the nearest 32px
	var size = Vector2(0, 0)
	size.x = int(incSize.x / 32)
	size.y = int(incSize.y / 32)
	# grab the corners and apply them
	#var tiles: TileSet = tilelayer.tile_set
	var topLeft = Vector2(0, 0)
	var topSide = Vector2(1, 0)
	var leftSide = Vector2(0, 1)
	var middle = Vector2(1, 1)
	# get the currently sized rect for this tilelayer, to find the edge tile coordinates
	var usedRect = tilelayer.get_used_rect()
	var botLeft = tilelayer.get_cell_atlas_coords(Vector2(0, usedRect.size.y-1))
	var botRight = tilelayer.get_cell_atlas_coords(Vector2(usedRect.size.x-1, usedRect.size.y-1))
	var topRight = tilelayer.get_cell_atlas_coords(Vector2(usedRect.size.x-1, 0))
	var botSide = tilelayer.get_cell_atlas_coords(Vector2(1, usedRect.size.y-1))
	var rightSide = tilelayer.get_cell_atlas_coords(Vector2(usedRect.size.x-1, 1))
	
	# zero it all out first
	tilelayer.clear()
	
	# fill everything
	for x in range(size.x):
		for y in range(size.y):
			tilelayer.set_cell(Vector2(x, y), 0, middle)

	# top and bot horiz
	for x in range(0, size.x):
		tilelayer.set_cell(Vector2(x, 0), 0, topSide)
		tilelayer.set_cell(Vector2(x, size.y-1), 0, botSide)
	# left and right vert
	for y in range(0, size.y):
		tilelayer.set_cell(Vector2(0, y), 0, leftSide)
		tilelayer.set_cell(Vector2(size.x-1, y), 0, rightSide)
	
	# set the four corners
	tilelayer.set_cell(Vector2(0, 0), 0, topLeft)
	tilelayer.set_cell(Vector2(size.x-1, 0), 0, topRight)
	tilelayer.set_cell(Vector2(0, size.y-1), 0, botLeft)
	tilelayer.set_cell(Vector2(size.x-1, size.y-1), 0, botRight)
	
func _enter_tree():
	var titleText = get_node("TitleText")
	var titleBg = get_node("TitleBg")
	var windowBg = get_node("WindowBg")
	titleText.size.y = 74
	
	windowBg.position = Vector2(0, 64)

	adjustBounds()
	
func adjustBounds():
	var titleText = get_node("TitleText")
	titleText.size.x = size.x
	titleText.text = title
	var titleBg = get_node("TitleBg")
	var windowBg = get_node("WindowBg")
	# resize and update our tile layers based on teh requested size
	resize_tilemap(Vector2(size.x, 96), titleBg)
	resize_tilemap(Vector2(size.x, size.y), windowBg)
	
func _input(event):
	if not canBeMoved:
		# block any changes to window pos/size
		return
	if event is InputEventMouseMotion:
		if isBeingDragged:
			position = get_viewport().get_mouse_position() - dragGrabOffset
		if isBeingResized:
			var newSize = get_viewport().get_mouse_position() - position
			newSize.y = max(128, newSize.y)
			newSize.x = max(256, newSize.x)
			newSize.x = (1 + int(newSize.x / 32)) * 32
			newSize.y = int(newSize.y / 32) * 32
			size = newSize
			adjustBounds()

	var titleBarRect = Rect2(
		Vector2(position),
		Vector2(size.x, 64)
	)
	if event is InputEventMouseButton:
		if event.pressed:
			# got a mouse down, if it's in the status bar, it's draggable
			if titleBarRect.has_point(event.position):
				isBeingDragged = true
				isBeingResized = false
				dragGrabOffset = Vector2(
					event.position.x - position.x,
					event.position.y - position.y
				)
			var corner = Rect2(
				position + size + Vector2(-64, 0),
				Vector2(64, 64)
			)
			print(corner, event.position)
			if corner.has_point(event.position):
				isBeingDragged = false
				isBeingResized = true
			# if it's in the borrom right, it's resizeable
		else:
			# on an up, release both states
			isBeingDragged = false
			isBeingResized = false
