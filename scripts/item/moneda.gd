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
	
	if not body.is_in_group("Jugadores"): #debe estar en el gruppo de jugadores
		return
	if not libre:
		return

	# solo el dueño de ese jugador procesa su propia colision
	if not body.is_multiplayer_authority():
		return

	libre = false

	var peer_id_jugador: int = multiplayer.get_unique_id()

	if GlobalJuego.un_jugador or multiplayer.is_server():
		# host: modifico y replico directo
		GlobalJuego.session_info[peer_id_jugador]["score"] = \
			int(GlobalJuego.session_info[peer_id_jugador].get("score", 0)) + 10
		GlobalJuego._replicar_session_info.rpc(GlobalJuego.session_info)
	else:
		# cliente: le pido al host
		Network.solicitar_sumar_monedas.rpc_id(1, peer_id_jugador, 10)
	rpc("animar_y_eliminar")

@rpc("any_peer", "call_local", "reliable")
func animar_y_eliminar() -> void:
	# 1. Desactivamos la colisión
	$CollisionShape3D.set_deferred("disabled", true)
	Sonidos.sonidoRecoleccionMonedas()
	# 2. Guardamos la posición Y actual en una variable local
	var posicion_y_actual = self.global_position.y
	var nueva_posicion = Vector3(self.global_position.x, posicion_y_actual + 4.0, self.global_position.z)
	
	# 3. Creamos el Tween
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Usamos la variable para el objetivo
	tween.tween_property(self, "global_position", nueva_posicion, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "scale", Vector3(1.5, 1.5, 1.5), 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	await tween.finished
	
	var tween_achicar = create_tween()
	tween_achicar.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
	await tween_achicar.finished
	queue_free()
