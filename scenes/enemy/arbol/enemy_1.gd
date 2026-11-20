extends CharacterBody3D
class_name EnemigoBase1

# LimboAI


@export var speed := 3.0
@export var attack_distance := 2.0

@onready var ray = $RayCast3D
@onready var agent = $NavigationAgent3D
@onready var btplayer = $BTPlayer

var player

func _ready():
	player = get_tree().get_first_node_in_group("Jugadores")

func _physics_process(delta):

	if player == null:
		return

	var blackboard = btplayer.blackboard

	blackboard.set_var("player", player)

	var distance = global_position.distance_to(player.global_position)

	blackboard.set_var("distance_to_player", distance)

	ray.look_at(player.global_position)

	if ray.is_colliding():

		if ray.get_collider() == player:
			blackboard.set_var("can_see_player", true)
		else:
			blackboard.set_var("can_see_player", false)

	else:
		blackboard.set_var("can_see_player", false)
