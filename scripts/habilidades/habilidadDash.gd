class_name HabilidadDash
extends Habilidad

@onready var tiempoRecarga = $tiempoRecarga

var disponible := true



func usar() -> void:
	if not jugador.puede_usar_habilidad():
		return
	if not disponible:
		return
	disponible = false
	jugador.iniciar_dash()
	tiempoRecarga.start()
	



func _on_tiempo_recarga_timeout() -> void:
	#print("habilidadDisponible")
	disponible = true
	pass # Replace with function body.
