extends Node

var libre = true  # bandera para que solo lo capture uno
@export var tipo: int = 0 # tipo d item


func _ready() -> void:
	# 1. Al inicializar (o cuando definas la opción), le pasas el dato al hijo
	pass

	
func eliminar():
	queue_free()



func _on_tiempo_vida_timeout() -> void:
	#print ("tiempo elimidado")
	eliminar()# Replace with function body.

# Si un jugador lo captura
func _on_body_entered(body: Node3D) -> void:
	
	if is_multiplayer_authority() and body.is_in_group("Jugadores") and libre:
		print ("moneda")
		# recolectar item
		libre = false
		
		#  Obtenemos el peer_id del jugador que colisionó
		var peer_id_jugador = body.get_multiplayer_authority()
		print("El jugador con Peer ID: ", peer_id_jugador, " moneda.",tipo)	
		
		
			# Si esto corre en el servidor, ya sabemos qué jugador fue.
			
		#aplicar_power_up(peer_id_jugador)
		#print ("item capturado")
		eliminar()
