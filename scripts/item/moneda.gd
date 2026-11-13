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
		
		# recolectar item
		libre = false
		
		#  Obtenemos el peer_id del jugador que colisionó
		var peer_id_jugador = body.get_multiplayer_authority()
		
		if GlobalJuego.session_info.has(peer_id_jugador): #Verificamos que el peer_id exista en el diccionario
			# 2. Sumamos la cantidad al score actual
			GlobalJuego.session_info[peer_id_jugador]["score"] += 10
			# Si esto corre en el servidor, ya sabemos qué jugador fue.
			# Opcional: imprimir para verificar
			# print("Jugador ", peer_id_jugador, " ahora tiene ", GlobalJuego.session_info[peer_id_jugador]["score"], " puntos.")
		else:
			push_error("No se encontró al jugador con peer_id: " + str(peer_id_jugador))
		#aplicar_power_up(peer_id_jugador)
		#print ("item capturado")
		eliminar()
