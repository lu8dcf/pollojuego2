extends BTAction

func _tick(delta: float) -> BT.Status:

	var actor = agent

	actor.velocity = Vector3.ZERO
	actor.move_and_slide()

	return BT.RUNNING
