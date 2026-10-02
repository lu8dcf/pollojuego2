class_name HabilidadDrones
extends Habilidad

@export var cantidad_drones: int = 2
var droneScene = preload("res://scenes/habilidad/dron.tscn")
var puedoUsar = true

#markers
#@onready var lado = [1,-1]

#contenedor
@onready var drones_container: Node3D = get_tree().get_first_node_in_group("contenedor_habilidades")


func usar() -> void:
	if jugador == null:
		return
	if(puedoUsar):
		print("uso habilidad")
		puedoUsar = false
		$tiempoRecarga.start()
		var mi_peer_id := multiplayer.get_unique_id()

		if multiplayer.is_server():
			crearDrones(mi_peer_id)
		else:
			solicitar_creacion_drones.rpc_id(1,mi_peer_id)
	
func crearDrones(peer_id: int) -> void:
	var jugador_objetivo = GlobalJuego._obtener_jugador(peer_id)
	
	for i in range(cantidad_drones):
		var dron = droneScene.instantiate()
		var lado := 1 if i == 0 else -1

		#nomrbeUnico, estructura "Dron_ID_Indice"
		dron.name = "Dron_" + str(peer_id) + "_" + str(lado)
		
		# el servidor da autoridad al cliente en el nodo
		dron.set_multiplayer_authority(peer_id)

		#le paso al dron su tiempo de vida
		dron.tiempo_de_vida = 5.0 
		
		#agrego al conedor
		drones_container.add_child(dron, true)


		#el lado al que debe ir
		dron.lado = lado
		#localmente para el servidor
		dron.inicializar(jugador_objetivo, jugador_objetivo.global_position, lado)


#----------------------------------------------------------------------------------------seniales

func _on_tiempo_recarga_timeout() -> void:
	puedoUsar=true
	pass # Replace with function body.


#-----------------------------------------------------------------RPC
@rpc("any_peer","call_local", "reliable")
func solicitar_creacion_drones(peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	var id_del_cliente = multiplayer.get_remote_sender_id()

	# MUY IMPORTANTE:
	# no confíes ciegamente en el peer_id enviado por el cliente.
	if id_del_cliente != peer_id:
		return

	crearDrones(id_del_cliente)
