extends Node3D
#fabrica de enemigos

@onready var contenedor_spawn: Node3D = $contenedor_spawn
@onready var tiempo_spawn: Timer = $tiempo_spawn


const TARGET = preload("uid://b8go34qeye00a")

func _ready() -> void:
	
	Global.contenedor_spawn = contenedor_spawn

	GlobalSignal.agrega_enemigo.connect(agrega_enemigo)


func agrega_enemigo(tipo):
	print ("enemigo")
	if is_multiplayer_authority() and get_tree().get_node_count_in_group('enemy') < 20:
		for player in get_tree().get_node_count_in_group("Jugadores"):
			var new_target = TARGET.instantiate()
			var rand_x = randf_range(GlobalJuego.mapa_x_min, GlobalJuego.mapa_x_max)
			var rand_z = randf_range(GlobalJuego.mapa_z_min, GlobalJuego.mapa_z_max)
			#print (rand_x," ",rand_z)
			new_target.position = Vector3(rand_x, 2.0, rand_z)
			contenedor_spawn.add_child(new_target, true)
