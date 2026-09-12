extends Node

const PLAYER = preload("uid://bc1ek0bvbgna2")
const TUBE_CONTEXT = preload("uid://chqw3jdoon6c1")

var enet_peer := ENetMultiplayerPeer.new()
var tube_client := TubeClient.new()
var tube_enabled = true

var PORT = 9999
var IP_ADDRESS = '26.47.107.144'

var en_lobby: bool = false

func _ready() -> void:
	if tube_enabled:
		tube_client.context = TUBE_CONTEXT
		get_tree().root.add_child.call_deferred(tube_client)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func tube_create():
	en_lobby = true
	multiplayer.peer_connected.connect(_on_peer_connected_lobby)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected_lobby)
	tube_client.create_session()

func tube_join(session_id: String):
	en_lobby = true
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
# LOBBY HANDLERS
# ------------------------------------------------------------

func _on_peer_connected_lobby(peer_id: int):
	print("Peer conectado en lobby: ", peer_id)
	if GlobalJuego and not GlobalJuego.session_info.has(peer_id):
		GlobalJuego.session_info[peer_id] = {
			"score": 0,
			"username": "Jugador " + str(peer_id),
			"salud": GlobalJuego.SALUD_DEFAULT
		}

func _on_peer_disconnected_lobby(peer_id: int):
	print("Peer desconectado en lobby: ", peer_id)
	if GlobalJuego and GlobalJuego.session_info.has(peer_id):
		GlobalJuego.session_info.erase(peer_id)

func _on_connected_to_server_lobby():
	print("Conectado al servidor en modo lobby")
	var peer_id = multiplayer.get_unique_id()
	if GlobalJuego and not GlobalJuego.session_info.has(peer_id):
		GlobalJuego.session_info[peer_id] = {
			"score": 0,
			"username": GlobalJuego.nombre_jugador if GlobalJuego.nombre_jugador != "" else "Jugador " + str(peer_id),
			"salud": GlobalJuego.SALUD_DEFAULT
		}

# ------------------------------------------------------------
# PARTIDA - CREACIÓN DE JUGADORES
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

func crear_todos_los_jugadores():
	"""SOLO EL HOST llama a esta función"""
	if not multiplayer.is_server():
		return
	
	print("HOST creando jugadores...")
	
	# Esperar a que el mundo exista
	await get_tree().create_timer(0.5).timeout
	
	var mundo = obtener_mundo_actual()
	if not mundo:
		print("ERROR: No hay mundo")
		return
	
	# Crear jugadores localmente Y notificar a los clientes
	for peer_id in GlobalJuego.session_info.keys():
		var username = GlobalJuego.session_info[peer_id].get("username", "Jugador " + str(peer_id))
		var posicion = Vector3(randf_range(15.0, 20.0), 1.0, randf_range(15.0, 20.0))
		
		# Crear localmente
		crear_jugador_en_mundo(mundo, peer_id, username, posicion)
		
		# Notificar a todos los clientes
		spawnear_jugador_rpc.rpc(peer_id, username, posicion)

func crear_jugador_en_mundo(mundo: Node, peer_id: int, username: String, posicion: Vector3):
	"""Crea un jugador en el mundo"""
	# Verificar si ya existe
	for child in mundo.get_children():
		if child.name == str(peer_id):
			print("Jugador ", peer_id, " ya existe")
			return
	
	var jugador = PLAYER.instantiate()
	jugador.name = str(peer_id)
	jugador.position = posicion
	mundo.add_child(jugador, true)
	
	# Configurar nombre
	var nameplate = jugador.get_node_or_null("Nameplate")
	if nameplate:
		nameplate.text = username
	
	print("Jugador creado localmente: ", peer_id, " - ", username)
	
func obtener_mundo_actual() -> Node:
	"""Obtiene el nodo del mundo actual"""
	var mundo = get_tree().current_scene.get_node_or_null("Mundo")
	if mundo:
		return mundo
	
	# Buscar en grupo
	var mundos = get_tree().get_nodes_in_group("mundo")
	if mundos.size() > 0:
		return mundos[0]
	
	# Buscar cualquier Node3D
	for child in get_tree().current_scene.get_children():
		if child is Node3D:
			return child
	
	return null

func _on_peer_connected_partida(peer_id: int):
	print("Peer conectado en partida: ", peer_id)
	if GlobalJuego and not GlobalJuego.session_info.has(peer_id):
		GlobalJuego.session_info[peer_id] = {
			"score": 0,
			"username": "Jugador " + str(peer_id),
			"salud": GlobalJuego.SALUD_DEFAULT
		}

func _on_peer_disconnected_partida(peer_id: int):
	print("Peer desconectado en partida: ", peer_id)
	if peer_id == 1:
		if not multiplayer.is_server():
			print("El HOST se desconectó. Cerrando partida...")
			_volver_al_menu_por_desconexion_host()
		return
	remove_player(peer_id)

func _on_server_disconnected():
	"""Se llama cuando se pierde la conexión con el servidor (host)"""
	print("¡Se perdió la conexión con el HOST!")
	
	# Solo los clientes deben reaccionar
	if multiplayer.is_server():
		return
	
	_volver_al_menu_por_desconexion_host()

func _volver_al_menu_por_desconexion_host():
	"""Maneja la desconexión del host para los clientes"""
	# Limpiar la conexión
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	
	
	# Mostrar mensaje al jugador (opcional)
	# mostrar_mensaje_desconexion("El host se ha desconectado")
	
	# Volver al menú principal
	await get_tree().create_timer(0.5).timeout
	get_tree().reload_current_scene()

func remove_player(peer_id):
	var mundo = obtener_mundo_actual()
	if mundo:
		var jugador = mundo.get_node_or_null(str(peer_id))
		if jugador:
			jugador.queue_free()

func leave_server():
	if tube_enabled:
		tube_client.leave_session()
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	get_tree().reload_current_scene()

# ------------------------------------------------------------
# RPC PARA SINCRONIZAR JUGADORES
# ------------------------------------------------------------
@rpc("authority", "call_local", "reliable")
func spawnear_jugador_rpc(peer_id: int, nombre: String, posicion: Vector3):
	"""El host ordena spawnear un jugador en todos los clientes"""
	print("RPC: Spawneando jugador: ", peer_id, " - ", nombre)
	

	var mundo = obtener_mundo_actual()
	if not mundo:
		print("ERROR: No hay mundo para spawnear en cliente")
		return
	
	# Verificar si ya existe
	for child in mundo.get_children():
		if child.name == str(peer_id):
			print("Jugador ", peer_id, " ya existe en cliente")
			return
	
	var jugador = PLAYER.instantiate()
	jugador.name = str(peer_id)
	jugador.position = posicion
	mundo.add_child(jugador, true)
	
	var nameplate = jugador.get_node_or_null("Nameplate")
	if nameplate:
		nameplate.text = nombre
	
	print("Jugador spawneado en cliente: ", peer_id, " - ", nombre)
#
#func clean_up_signals():
	#multiplayer.peer_connected.disconnect(add_player) 
	#multiplayer.peer_disconnected.disconnect(remove_player)
	#multiplayer.connected_to_server.disconnect(on_connected_to_server)

func _exit_tree() -> void:
	if tube_enabled:
		tube_client.leave_session()


#----------------------------------------------------- Interacciones Jugador
@rpc("any_peer", "call_local")
func pedir_salvar_rpc(objetivo_id: int) -> void:

	if not multiplayer.is_server():
		return

	var salvador_id := multiplayer.get_remote_sender_id()

	var salvador := GlobalJuego._obtener_jugador(salvador_id)
	var objetivo := GlobalJuego._obtener_jugador(objetivo_id)

	if salvador == null or objetivo == null:
		return

	# comprobar que el objetivo esta caido
	if objetivo.estadoActual != Jugador.Estado.CAIDO:
		print("El jugador no está caido")
		return

	# Cambiar el estado del objetivo
	objetivo.cambiar_estado(Jugador.Estado.OLEADA)
	print("¡Salvado!")
