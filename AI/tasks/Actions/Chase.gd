extends BTAction

func _tick(delta: float) -> BT.Status:

	var actor = agent
	var player = blackboard.get_var("player")

	if player == null:
		return BT.FAILURE

	var dir = player.global_position - actor.global_position

	dir.y = 0

	dir = dir.normalized()

	actor.velocity.x = dir.x * actor.speed
	actor.velocity.z = dir.z * actor.speed

	actor.move_and_slide()

	return BT.RUNNING
