extends CharacterBody2D
class_name BouncyBall

@export var canControl = false
#func _enter_tree():
var eventPrompt = null
var isMoving = false

func _enter_tree():
	# TODO: while this should work, it's kind of a passive way to get a ref to the event prompt
	eventPrompt = get_tree().current_scene.get_node("EventPrompt")

func _input(event):
	if canControl:
		if event is InputEventKey:
			var k = event.keycode
			velocity = 200 * Vector2(
				int(k == KEY_RIGHT) - int(k == KEY_LEFT),
				int(k == KEY_DOWN) - int(k == KEY_UP)
			)

func startMoving():
	isMoving = true
	velocity = 1240 * Vector2(randi_range(-100, 100), randi_range(-100, 100)).normalized() # TODO: do a random direction + decide on speed

func _process(delta):
	if not isMoving:
		return
	var res = move_and_collide(delta * velocity)
	if res:
		# a collision occurred, reflect our new velocity along the collision's normal
		velocity = velocity.bounce(res.get_normal())
	# tick down by our friction value
	var reduceBy = 0.8
	velocity *= (1 - reduceBy*delta)
	if abs(velocity.x) <= 20 and abs(velocity.y) <= 20:
		isMoving = false
		velocity = Vector2(0, 0)
		# we're done! signal up so we can evaluate it
		eventPrompt.finishedBallBouncing.emit()
