extends BTCondition

func _tick(delta: float) -> BT.Status:

	var distance = blackboard.get_var("distance_to_player")

	if distance <= 2.0:
		return BT.SUCCESS

	return BT.FAILURE
