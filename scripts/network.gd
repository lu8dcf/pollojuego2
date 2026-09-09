extends Node

const PLAYER = preload("uid://bc1ek0bvbgna2")
const TUBE_CONTEXT = preload("uid://chqw3jdoon6c1")

var enet_peer := ENetMultiplayerPeer.new()
var tube_client := TubeClient.new()
var tube_enabled = true

var PORT = 9999
var IP_ADDRESS = '26.47.107.144'

# Variable para controlar si estamos en lobby o en partida
var en_lobby: bool = false

func _ready() -> void:
	if tube_enabled:
		tube_client.context = TUBE_CONTEXT
		get_tree().root.add_child.call_deferred(tube_client)

func tube_create():
	en_lobby = true  # Estamos en lobby
	multiplayer.peer_connected.connect(_on_peer_connected_lobby)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected_lobby)
	tube_client.create_session()
	# No crear jugador aquí, solo registrar en session_info

func tube_join(session_id: String):
	en_lobby = true  # Estamos en lobby
	multiplayer.peer_connected.connect(_on_peer_connected_lobby)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected_lobby)
	multiplayer.connected_to_server.connect(_on_connected_to_server_lobby)
	tube_client.join_session(session_id)

func start_server():
	en_lobby = true
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(_on_peer_connected_lobby)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected_lobby)

func join_server():
	en_lobby = true
	enet_peer.create_client(IP_ADDRESS, PORT)
	multiplayer.peer_connected.connect(_on_peer_connected_lobby)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected_lobby)
	multiplayer.connected_to_server.connect(_on_connected_to_server_lobby)
	multiplayer.multiplayer_peer = enet_peer

# ------------------------------------------------------------
# MANEJADORES PARA LOBBY (no crean jugadores)
# ------------------------------------------------------------

func _on_peer_connected_lobby(peer_id: int):
	"""Se llama cuando un peer se conecta durante el lobby"""
	print("Peer conectado en lobby: ", peer_id)
	# Solo registramos en session_info, no creamos jugador
	if GlobalJuego:
		if not GlobalJuego.session_info.has(peer_id):
			GlobalJuego.session_info[peer_id] = {
				"score": 0,
				"username": "Jugador " + str(peer_id),
				"salud": GlobalJuego.SALUD_DEFAULT
			}
	
	## Emitir señal para actualizar lobby
	#if GlobalSignal.has_signal("jugador_conectado"):
		#GlobalSignal.jugador_conectado.emit(peer_id)

func _on_peer_disconnected_lobby(peer_id: int):
	"""Se llama cuando un peer se desconecta durante el lobby"""
	print("Peer desconectado en lobby: ", peer_id)
	
	if GlobalJuego and GlobalJuego.session_info.has(peer_id):
		GlobalJuego.session_info.erase(peer_id)
	
	## Emitir señal para actualizar lobby
	#if GlobalSignal.has_signal("jugador_desconectado"):
		#GlobalSignal.jugador_desconectado.emit(peer_id)

func _on_connected_to_server_lobby():
	"""Se llama cuando nos conectamos al servidor en modo lobby"""
	print("Conectado al servidor en modo lobby")
	# No crear jugador, solo registrar
	var peer_id = multiplayer.get_unique_id()
	if GlobalJuego:
		if not GlobalJuego.session_info.has(peer_id):
			GlobalJuego.session_info[peer_id] = {
				"score": 0,
				"username": GlobalJuego.nombre_jugador if GlobalJuego.nombre_jugador != "" else "Jugador " + str(peer_id),
				"salud": GlobalJuego.SALUD_DEFAULT
			}

# ------------------------------------------------------------
# FUNCIONES PARA INICIAR PARTIDA
# ------------------------------------------------------------

func iniciar_partida_desde_lobby():
	"""Cambia del lobby al modo partida"""
	en_lobby = false
	
	# Desconectar señales de lobby
	if multiplayer.peer_connected.is_connected(_on_peer_connected_lobby):
		multiplayer.peer_connected.disconnect(_on_peer_connected_lobby)
	if multiplayer.peer_disconnected.is_connected(_on_peer_disconnected_lobby):
		multiplayer.peer_disconnected.disconnect(_on_peer_disconnected_lobby)
	
	# Conectar señales de partida
	multiplayer.peer_connected.connect(_on_peer_connected_partida)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected_partida)
	
	# Crear jugadores para todos los que están en session_info
	_crear_jugadores_existentes()

func _crear_jugadores_existentes():
	"""Crea jugadores para todos los peers registrados"""
	if not GlobalJuego:
		return
	
	for peer_id in GlobalJuego.session_info.keys():
		_crear_jugador(peer_id)

func _crear_jugador(peer_id: int):
	"""Crea un jugador en el mundo"""
	if peer_id == multiplayer.get_unique_id():
		# Es el jugador local
		var new_player = PLAYER.instantiate()
		new_player.name = str(peer_id)
		
		var rand_x = randf_range(15.0, 20.0)
		var rand_z = randf_range(15.0, 20.0)
		
		new_player.position = Vector3(rand_x, 1.0, rand_z)
		
		# Buscar el mundo actual para agregar el jugador
		var mundo_actual = get_tree().current_scene.get_node_or_null("Mundo")
		if not mundo_actual:
			# Buscar cualquier nodo Node3D que sea el mundo
			for child in get_tree().current_scene.get_children():
				if child is Node3D and child.name.to_lower().contains("mundo"):
					mundo_actual = child
					break
		
		if mundo_actual:
			mundo_actual.add_child(new_player, true)
		else:
			get_tree().current_scene.add_child(new_player, true)
		
		# Configurar nombre de usuario
		if GlobalJuego.session_info.has(peer_id):
			var username = GlobalJuego.session_info[peer_id]["username"]
			if new_player.has_method("set_username"):
				new_player.set_username(username)
			elif new_player.has_node("Nameplate"):
				var nameplate = new_player.get_node("Nameplate")
				if nameplate is Label:
					nameplate.text = username
	else:
		# Es un jugador remoto (ya debería estar creado por su propio cliente)
		pass

func _on_peer_connected_partida(peer_id: int):
	"""Se llama cuando un peer se conecta durante la partida"""
	print("Peer conectado en partida: ", peer_id)
	# En partida, solo registrar en session_info
	if GlobalJuego:
		if not GlobalJuego.session_info.has(peer_id):
			GlobalJuego.session_info[peer_id] = {
				"score": 0,
				"username": "Jugador " + str(peer_id),
				"salud": GlobalJuego.SALUD_DEFAULT
			}

func _on_peer_disconnected_partida(peer_id: int):
	"""Se llama cuando un peer se desconecta durante la partida"""
	print("Peer desconectado en partida: ", peer_id)
	remove_player(peer_id)

# ------------------------------------------------------------
# FUNCIONES ORIGINALES (modificadas)
# ------------------------------------------------------------

func on_connected_to_server():
	# Esta función ya no se usa para crear jugadores
	pass

func add_player(peer_id: int):
	# Esta función ahora solo se usa en modo partida
	if en_lobby:
		return  # No crear jugadores en lobby
	
	if peer_id == 1 and multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		return
	
	_crear_jugador(peer_id)

func remove_player(peer_id):
	if peer_id == 1:
		leave_server()
		return
	
	var players: Array[Node] = get_tree().get_nodes_in_group('Jugadores')
	var player_to_remove = players.find_custom(func(item): return item.name == str(peer_id))
	if player_to_remove != -1:
		players[player_to_remove].queue_free()

func leave_server():
	if tube_enabled:
		tube_client.leave_session()

	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	clean_up_signals()
	get_tree().reload_current_scene()
	
func clean_up_signals():
	# Desconectar todas las señales posibles
	if multiplayer.peer_connected.is_connected(_on_peer_connected_lobby):
		multiplayer.peer_connected.disconnect(_on_peer_connected_lobby)
	if multiplayer.peer_disconnected.is_connected(_on_peer_disconnected_lobby):
		multiplayer.peer_disconnected.disconnect(_on_peer_disconnected_lobby)
	if multiplayer.peer_connected.is_connected(_on_peer_connected_partida):
		multiplayer.peer_connected.disconnect(_on_peer_connected_partida)
	if multiplayer.peer_disconnected.is_connected(_on_peer_disconnected_partida):
		multiplayer.peer_disconnected.disconnect(_on_peer_disconnected_partida)
	if multiplayer.connected_to_server.is_connected(_on_connected_to_server_lobby):
		multiplayer.connected_to_server.disconnect(_on_connected_to_server_lobby)
	if multiplayer.connected_to_server.is_connected(on_connected_to_server):
		multiplayer.connected_to_server.disconnect(on_connected_to_server)

func _exit_tree() -> void:
	if tube_enabled:
		tube_client.leave_session()

#----------------------------------------------------- Interacciones Jugador

@rpc("any_peer")
func pedir_salvar_rpc(objetivo_id: int) -> void:
	if not multiplayer.is_server():
		return

	var salvador_id = multiplayer.get_remote_sender_id()

	var salvador = GlobalJuego._obtener_jugador(salvador_id)
	var objetivo = GlobalJuego._obtener_jugador(objetivo_id)

	if salvador == null or objetivo == null:
		return
	if objetivo.estadoActual != objetivo.estados.CAIDO:
		return

	objetivo.estadoActual = objetivo.estados.OLEADA
	print("salvado!")
