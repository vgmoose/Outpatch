extends CharacterBody2D
class_name BouncyBall

@export var canControl = false
#func _enter_tree():

func _input(event):
	if canControl:
		if event is InputEventKey:
			var k = event.keycode
			velocity = 200 * Vector2(
				int(k == KEY_RIGHT) - int(k == KEY_LEFT),
				int(k == KEY_DOWN) - int(k == KEY_UP)
			)
				
func _process(delta):
	var res = move_and_collide(delta * velocity)
	if res:
		# a collision occurred, reflect our new velocity along the collision's normal
		velocity = velocity.bounce(res.get_normal())
	# tick down by our friction value
	velocity *= 0.99
