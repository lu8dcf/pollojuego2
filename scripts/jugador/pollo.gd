class_name Pollo
extends Node3D

var jugador: Jugador

var habilidad: Habilidad
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var modelo : Node3D

func inicializar(p_jugador: Jugador,p_modelo: Node3D,p_habilidad: Habilidad) -> void:

	jugador = p_jugador
	modelo = p_modelo
	habilidad = p_habilidad

	add_child(modelo)
	add_child(habilidad)

	habilidad.iniciar(jugador)

#func usar_habilidad() -> void:
#
	##if is_instance_valid(habilidad):
	#if(habilidad != null):
		#habilidad.usar()


func usar_habilidad() -> void:
	if habilidad == null:
		return
		
	if multiplayer.is_server():
		#host: ejecuto directamente
		habilidad.usar()
	else:
		# cliente: solicito al servidor
		solicitar_habilidad.rpc_id(1)

@rpc("any_peer", "reliable")
func solicitar_habilidad() -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id() #obtengo a quien llamo la habilidad

	if habilidad == null:
		return

	# Ordeno al cliente que la ejecute
	ejecutar_habilidad.rpc_id(peer_id)


@rpc("any_peer", "reliable")
func ejecutar_habilidad() -> void:
	habilidad.usar()


func mirar_hacia(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.001:
		return
	var angulo := atan2(direction.x,direction.z) + PI #este pi es para invertir la vuelta
	self.rotation.y = lerp_angle(self.rotation.y,angulo,delta * 10.0)

func reproducir_animacion(nombre: StringName) -> void:
	animation_player.play(nombre)
