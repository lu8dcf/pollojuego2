extends Node3D

@onready var contenedor_spawn: Node3D = $contenedor_spawn
@onready var tiempo_spawn: Timer = $tiempo_spawn

const TARGET = preload("res://scenes/enemy/enemy_0.tscn")

func _ready() -> void:
	Global.forest = self
	Global.contenedor_spawn = contenedor_spawn
	
	tiempo_spawn.timeout.connect(agrega_enemigo)
	

func agrega_enemigo():
	if is_multiplayer_authority() and get_tree().get_node_count_in_group('Targets') < 20:
		for player in get_tree().get_node_count_in_group("Players"):
			var new_target = TARGET.instantiate()
			var rand_x = randf_range(-25.0, 25.0)
			var rand_z = randf_range(-25.0, 25.0)
			new_target.position = Vector3(rand_x, 1.0, rand_z)
			contenedor_spawn.add_child(new_target, true)
