extends Node

var libre = true  # bandera para que solo lo capture uno
var tipo = 0 # tipo de item

# Si un jugador lo captura
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Jugadores") and libre:
		# recolectar item
		libre = false
		
			
		print ("item capturado")
		eliminar()


func _on_tiempo_vida_timeout() -> void:
	print ("tiempo elimidado")
	eliminar()
	
func eliminar():
	queue_free()
