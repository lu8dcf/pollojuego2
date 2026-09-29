class_name HabilidadEscudo
extends Habilidad

@export var duracion: float = 5.0
@export var tiempoColdown: float = 5.0

@onready var tiempoRecarga: Timer = $tiempoRecarga

var escudoEscena = preload("res://scenes/habilidad/escudo.tscn")
@onready var containerHabilidad: Node3D = get_tree().get_first_node_in_group("contenedor_habilidades")

var puedoUsar = true

func usar() -> void:
	if jugador == null or not puedoUsar:
		return
		
	puedoUsar = false
	$tiempoRecarga.start(tiempoColdown)
	var mi_peer_id := multiplayer.get_unique_id()
	
	

	if multiplayer.is_server():
		crearEscudo(mi_peer_id)
	else:
		solicitar_creacion_escudo.rpc_id(1, mi_peer_id)

func crearEscudo(peer_id: int) -> void:
	if containerHabilidad == null: 
		return
	
	var jugador_objetivo = GlobalJuego._obtener_jugador(peer_id)
	if jugador_objetivo == null: return
	
	#si ya hay escudo colgado del jugador lo elimino primero
	var nombre_buscado = "Escudo_" + str(peer_id)
	var escudo_viejo = containerHabilidad.get_node_or_null(nombre_buscado)
	if escudo_viejo:
		escudo_viejo.queue_free()
	
	
	var escudo = escudoEscena.instantiate()
	escudo.name = nombre_buscado
	escudo.set_multiplayer_authority(peer_id)
	
	#le paso al dron su tiempo de vida
	escudo.tiempo_de_vida = 5.0 
	
	containerHabilidad.add_child(escudo, true)
	escudo.inicializar(jugador_objetivo)

#------------------------------------------------------------------------------timer y destruccion

func _on_tiempo_recarga_timeout() -> void:
	#print("habilidadLista para usar")
	puedoUsar = true

func eliminar_escudo_servidor(peer_id: int) -> void:
	if containerHabilidad == null: return
	var nombre_buscado = "Escudo_" + str(peer_id)
	var mi_escudo = containerHabilidad.get_node_or_null(nombre_buscado)
	if mi_escudo:
		mi_escudo.queue_free()

#-----------------------------------------------------------------------------RPC

@rpc("any_peer", "call_local", "reliable")
func solicitar_creacion_escudo(peer_id: int) -> void:
	if not multiplayer.is_server(): return
	# Validacion
	if multiplayer.get_remote_sender_id() != peer_id: return
	
	crearEscudo(peer_id)
