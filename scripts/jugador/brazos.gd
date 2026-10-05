extends Node3D

#Pruebo la fabrica de armas
@onready
var crear_armas = $fabricaArmas

@onready var mano_izquierda: Marker3D = $izquierdo/mark_izq
@onready var mano_derecha: Marker3D =$derecho/mark_der

var peer_id_jugador: int
var jugadorPadre : Jugador

enum Manos {
	IZQUIERDA,
	DERECHA
}
var ultima_mano: Manos = Manos.IZQUIERDA

func _ready() -> void:
	await get_tree().process_frame

	#obtengo referencia al jugador padre
	peer_id_jugador = get_parent().get_multiplayer_authority()

func obtener_arma(mano: Manos) -> Node:
	if mano == Manos.IZQUIERDA:
		if mano_izquierda.get_child_count() > 0:
			return mano_izquierda.get_child(0)
	else:
		if mano_derecha.get_child_count() > 0:
			return mano_derecha.get_child(0)
	return null


func _unhandled_input(_event: InputEvent) -> void:
	#solo el duenio local de este personaje puede cambiar sus armas
	if not is_multiplayer_authority():
		return
		
	var slot_seleccionado := -1
	if Input.is_action_just_pressed("slot_1"): slot_seleccionado = 0
	elif Input.is_action_just_pressed("slot_2"): slot_seleccionado = 1
	elif Input.is_action_just_pressed("slot_3"): slot_seleccionado = 2
	elif Input.is_action_just_pressed("slot_4"): slot_seleccionado = 3
	elif Input.is_action_just_pressed("slot_5"): slot_seleccionado = 4
	elif Input.is_action_just_pressed("slot_6"): slot_seleccionado = 5

	if slot_seleccionado != -1:
		# Accedemos al globalJuego para saber que arma tenemos
		var inventario = GlobalJuego.inventario_jugador
		var id_arma = inventario[slot_seleccionado]
		
		if id_arma != null:
			solicitar_equipar_arma(id_arma)

func equipar_arma(id_arma: int) -> void:
	var mano: Marker3D
	if ultima_mano == Manos.IZQUIERDA:
		mano = mano_izquierda
	else:
		mano = mano_derecha
	# si esa mano tiene un arma...
	if mano.get_child_count() > 0:
		var arma_actual = mano.get_child(0)
		# si se intenta la misma arma que retorne
		if arma_actual.get("id_arma") == id_arma:
			return
		arma_actual.free()
	# creo una nueva arma
	var nueva_arma = crear_armas.crear_arma(id_arma)
	#nombvro el nodo usando el id del jugador y la mano para evitar errores en red
	var nombre_mano = "Izq" if ultima_mano == Manos.IZQUIERDA else "Der"
	nueva_arma.name = "Arma_" + nombre_mano + "_" + str(peer_id_jugador)
	
	#asigno autoridad
	nueva_arma.set_multiplayer_authority(peer_id_jugador)
	
	# La agrego al arbol
	mano.add_child(nueva_arma, true)
	nueva_arma.transform = Transform3D.IDENTITY
	
	# Cambia de mano para la siguiente arma
	if ultima_mano == Manos.IZQUIERDA:
		ultima_mano = Manos.DERECHA
	else:
		ultima_mano = Manos.IZQUIERDA
	#nueva_arma.name = "ArmaBase"
	#mano.add_child(nueva_arma)
	#nueva_arma.transform = Transform3D.IDENTITY
	## cambia de mano para la siguiente arma
	#if ultima_mano == Manos.IZQUIERDA:
		#ultima_mano = Manos.DERECHA
	#else:
		#ultima_mano = Manos.IZQUIERDA
		
#----------------------------------------------------------------------SERVER

func solicitar_equipar_arma(id_arma: int) -> void:
	if peer_id_jugador != multiplayer.get_unique_id():
		return

	var mano = ultima_mano
	
	if multiplayer.is_server():
		# El servidor puede ser un jugador.
		avisar_arma_equipada.rpc(mano,id_arma)
	else:
		# Le pedimos al servidor que procese el equipamiento.
		solicitar_equipar_arma_rpc.rpc_id(1,mano,id_arma)


@rpc("any_peer", "reliable")
func solicitar_equipar_arma_rpc(mano: Manos, id_arma: int) -> void:
	if not multiplayer.is_server():
		return

	 #Buscamos al Jugador al que pertenece este Brazo.
	var jugador = get_parent()
	var peer_id = multiplayer.get_remote_sender_id()

	#compuebo que son los mismos
	if jugador.get_multiplayer_authority() != peer_id:
		return


	# El servidor decide equipar el arma.
	avisar_arma_equipada.rpc(mano,id_arma)
#

@rpc("any_peer", "call_local", "reliable")
func avisar_arma_equipada(mano: Manos,id_arma: int) -> void:

	#print("Jugador ", peer_id_jugador, " equipa arma en mano: ", mano)
	ultima_mano = mano
	equipar_arma(id_arma)
