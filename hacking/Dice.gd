extends CharacterBody3D
class_name Dice

var x = 0
var model = null
var friction = 0.9

var zeroVec = Vector3(0, 0, 0)

func _enter_tree():
	model = get_node("Model")

var speed = 12

func _input(event):
	if event.is_action_pressed("ui_down"):
		velocity += Vector3(0, 0, speed)
	if event.is_action_pressed("ui_up"):
		velocity += Vector3(0, 0, -speed)
	if event.is_action_pressed("ui_left"):
		velocity += Vector3(-speed, 0, 0)
	if event.is_action_pressed("ui_right"):
		velocity += Vector3(speed, 0, 0)
	
func _physics_process(delta):
	if not model:
		return
	
	if velocity == zeroVec:
		# idle rotating
		model.rotation += Vector3(1, 1, 1) * delta
	else:
		model.rotation -= Vector3(velocity.z, velocity.y, velocity.x) * 0.04
	x += 1
	
	move_and_slide()
	velocity *= friction
	
	if abs(velocity.x) + abs(velocity.y) + abs(velocity.z) < 0.01:
		velocity = zeroVec
	
	position = Vector3(position.x, abs(sin(x / 100.0) / 4.0 - 2), position.z)
	
