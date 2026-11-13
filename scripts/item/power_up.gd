extends Node

var libre = true  # bandera para que solo lo capture uno
@export var tipo: int = 0 # tipo d item
@onready var power_up_generico = $PowerUpGenerico

func _ready() -> void:
	# 1. Al inicializar (o cuando definas la opción), le pasas el dato al hijo
	configurar_power_up()

func configurar_power_up() -> void:
	#  función del hijo y SE pasa el tipo
	if power_up_generico.has_method("color"):
		power_up_generico.color(tipo)

# Si un jugador lo captura
func _on_body_entered(body: Node3D) -> void:
	if is_multiplayer_authority() and body.is_in_group("Jugadores") and libre:
		# recolectar item
		libre = false
		
		#  Obtenemos el peer_id del jugador que colisionó
		var peer_id_jugador = body.get_multiplayer_authority()
		
		if GlobalJuego.session_info.has(peer_id_jugador): #Verificamos que el peer_id exista en el diccionario
			
			match tipo:
				2: # rojo suma +10 vida
					if body.has_method("recibir_dano"):
						body.recibir_dano(-10)
			
					#GlobalJuego.session_info[peer_id_jugador]["salud"] += 10
				3: # verde aumento de velocidad 
					if body.has_method("powerup_velocidad"):
						body.powerup_velocidad()
				4: # azul repulsion
					if body.has_method("powerup_escudo"):
						body.powerup_escudo()
				5: # amarillo cadencia de la armas
					if GlobalJuego.session_info.has(peer_id_jugador):
						var score = GlobalJuego.session_info[peer_id_jugador]["score"]
						GlobalJuego.session_info[peer_id_jugador]["score"] = score * 2
		else:
			push_error("No se encontró al jugador con peer_id: " + str(peer_id_jugador))
		#print("El jugador con Peer ID: ", peer_id_jugador, " recogió el ítem.",tipo)	
		
		
			# Si esto corre en el servidor, ya sabemos qué jugador fue.
			
		#aplicar_power_up(peer_id_jugador)
		#print ("item capturado")
		rpc("animar_y_eliminar")


func _on_tiempo_vida_timeout() -> void:
	#print ("tiempo elimidado")
	eliminar()
	
func eliminar():
	queue_free()

@rpc("authority", "call_local", "reliable")
func animar_y_eliminar() -> void:
	# 1. Desactivamos la colisión
	$CollisionShape3D.set_deferred("disabled", true)
	
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
