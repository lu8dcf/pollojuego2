extends BTCondition

func _tick(delta: float) -> BT.Status:

	var can_see = blackboard.get_var("can_see_player")

	if can_see:
		return BT.SUCCESS

	return BT.FAILURE
