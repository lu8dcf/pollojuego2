extends Node

const PLAYER = preload("uid://bc1ek0bvbgna2")
const TUBE_CONTEXT = preload("uid://chqw3jdoon6c1")

var enet_peer := ENetMultiplayerPeer.new()
var tube_client := TubeClient.new()
var tube_enabled = true

var puerto_actual: int = 9999
var ip_local: String = '127.0.0.1'
var otro_ip :bool = false
var en_lobby: bool = false

# para la pantalla de carga
var cargando: bool = false
var jugadores_listos: Dictionary = {}  # peer_id -> bool
var total_jugadores: int = 0
var pantalla_carga_actual: CanvasLayer = null
const PANTALLA_CARGA = preload("uid://bym6i52jnwycp")

# PAUSA MULTIJUGADOR
var pausa_activa: bool = false
var peer_que_pauso: int = 0

# temporizador de time out de espera
var _timeout_conexion : SceneTreeTimer  = null

func _ready() -> void:
	if tube_enabled:
		tube_client.context = TUBE_CONTEXT
		get_tree().root.add_child.call_deferred(tube_client)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(_on_conexion_fallida)
	
	_actualizar_ip_local()


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
	_iniciar_timeout_conexion(10.0)

func _actualizar_ip_local() -> void:
	if not otro_ip:
		var ips = IP.get_local_addresses() # obtener el ip
		for ip in ips:
			if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
				ip_local = ip
				break
		if ip_local == "127.0.0.1" and ips.size() >0:
			ip_local = ips[0]
			print("ip detectada: ", ip_local)
	#else:
		#print("la ip elegida por el usuario es: ", ip_local)

func empezar_servidor_lan(puerto: int = 9999):
	en_lobby = true
	puerto_actual=puerto
	
	var error = enet_peer.create_server(puerto_actual)
	if error != OK:
		var mensaje = "No se pudo crear el servidor en el puerto " + str(puerto_actual) + ".\n"
		match  error:
			ERR_ALREADY_IN_USE:
				mensaje += "El puerto ya está en uso. Prueba con otro."
			ERR_CANT_CREATE:
				mensaje += "No se pudo crear el servidor. Verifica permisos del firewall."
			_:
				mensaje += "Código de error: " + str(error)
		GlobalSignal.error_conexion.emit(mensaje) # se emite el error de conexion para poder manejarlo en el hud
		return false
		
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(_on_peer_connected_lobby)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected_lobby)
	_iniciar_timeout_conexion(8.0)
	return true

func unirse_servidor_lan(direccion_ip:String, puerto:int)-> bool:
	en_lobby = true
	puerto_actual = puerto
	var error = enet_peer.create_client(direccion_ip, puerto)
	if error != OK:
		var mensaje = "No se pudo conectar a " + direccion_ip + ":" + str(puerto) + ".\n"
		match error:
			ERR_CANT_CONNECT:
				mensaje += "No se pudo conectar. Verifica la IP y el puerto."
			ERR_ALREADY_IN_USE:
				mensaje += "Ya hay una conexión activa."
			_:
				mensaje += "Código de error: " + str(error)
		GlobalSignal.error_conexion.emit(mensaje)
		return false
		
	multiplayer.peer_connected.connect(_on_peer_connected_lobby)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected_lobby)
	multiplayer.connected_to_server.connect(_on_connected_to_server_lobby)
	multiplayer.multiplayer_peer = enet_peer
	return true

# ------------------------------------------------------------
# LOBBY HANDLERS
# ------------------------------------------------------------

func _on_peer_connected_lobby(peer_id: int):
	if GlobalJuego and not GlobalJuego.session_info.has(peer_id):
		GlobalJuego.session_info[peer_id] = {
			"score": 0,
			"username": "Jugador " + str(peer_id),
			"salud": GlobalJuego.SALUD_DEFAULT
		}

func _on_peer_disconnected_lobby(peer_id: int):
	if GlobalJuego and GlobalJuego.session_info.has(peer_id):
		GlobalJuego.session_info.erase(peer_id)

func _on_connected_to_server_lobby():

	if _timeout_conexion: # si existe el timeout, cancelarlo
		if _timeout_conexion.timeout.is_connected(_on_timeout_conexion):
			_timeout_conexion.timeout.disconnect(_on_timeout_conexion)
		_timeout_conexion = null
	

	var peer_id = multiplayer.get_unique_id()
	if GlobalJuego and not GlobalJuego.session_info.has(peer_id):
		GlobalJuego.session_info[peer_id] = {
			"score": 0,
			"username": GlobalJuego.nombre_jugador if GlobalJuego.nombre_jugador != "" else "Jugador " + str(peer_id),
			"salud": GlobalJuego.SALUD_DEFAULT,
			"personaje":0
		}

# ------------------------------------------------------------
# PARTIDA - CREACIÓN DE JUGADORES
# ------------------------------------------------------------

func iniciar_partida_desde_lobby(): #Cambia del lobby al modo partida
	en_lobby = false
	
	# Desconectar señales de lobby
	if multiplayer.peer_connected.is_connected(_on_peer_connected_lobby):
		multiplayer.peer_connected.disconnect(_on_peer_connected_lobby)
	if multiplayer.peer_disconnected.is_connected(_on_peer_disconnected_lobby):
		multiplayer.peer_disconnected.disconnect(_on_peer_disconnected_lobby)
	
	# Conectar señales de partida
	multiplayer.peer_connected.connect(_on_peer_connected_partida)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected_partida)

func crear_todos_los_jugadores(): #SOLO EL HOST llama a esta función
	if not multiplayer.is_server():
		return
	
	# Esperar a que el mundo exista
	await get_tree().create_timer(0.5).timeout
	
	var mundo = obtener_mundo_actual()
	if not mundo:
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
	
	for child in mundo.get_children():
		if child.name == str(peer_id): #si el jugador ya existe n el mundo, no se debe crear
			return
	var jugador = PLAYER.instantiate()
	jugador.name = str(peer_id)
	jugador.position = posicion
	jugador.set_multiplayer_authority(peer_id)
	
	mundo.add_child(jugador, true)
	
	
	var nameplate = jugador.get_node_or_null("Nameplate") # aca se configura el nombre
	if nameplate:
		nameplate.text = username
	
	
func obtener_mundo_actual() -> Node:
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
			"salud": GlobalJuego.SALUD_DEFAULT,
			"personaje":0
		}

func _on_peer_disconnected_partida(peer_id: int):
	if peer_id == 1:
		if not multiplayer.is_server():
			_volver_al_menu_por_desconexion_host()
		return
	remove_player(peer_id)
	
	if pausa_activa and peer_id == peer_que_pauso:
		pausa_activa = false
		peer_que_pauso = 0
		_aplicar_pausa.rpc(false, 0)

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

# MANEJO DE ERRORES:

func _iniciar_timeout_conexion(segundos: float = 8.0) -> void:
	# Cancelar timeout anterior si existe
	if _timeout_conexion:
		_timeout_conexion.timeout.disconnect(_on_timeout_conexion)
	
	_timeout_conexion = get_tree().create_timer(segundos)
	_timeout_conexion.timeout.connect(_on_timeout_conexion)
	
	
func _on_timeout_conexion() -> void:
	# Si seguimos en lobby y NO estamos conectados, es un timeout
	if not en_lobby:
		return
	
	# En LAN: comprobar si ya estamos conectados
	if multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		var status = multiplayer.multiplayer_peer.get_connection_status()
		if status == MultiplayerPeer.CONNECTION_CONNECTED:
			return  # Ya estamos conectados, no es timeout
	elif multiplayer.multiplayer_peer is WebRTCMultiplayerPeer:
		# Para Tube, comprobar si estamos conectados al servidor
		if multiplayer.has_multiplayer_peer() and multiplayer.get_unique_id() != 0:
			return
	
	# No nos conectamos a tiempo
	var mensaje = "Tiempo de espera agotado. No se pudo conectar.\n"
	mensaje += "Verifica la IP/puerto o el ID de sesión."
	
	# Limpiar conexión
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	GlobalSignal.error_conexion.emit(mensaje)


func _on_conexion_fallida():
	if _timeout_conexion:
		if _timeout_conexion.timeout.is_connected(_on_timeout_conexion):
			_timeout_conexion.timeout.disconnect(_on_timeout_conexion)
		_timeout_conexion = null
	
	var mensaje = "No se pudo conectar al servidor.\n"
	mensaje += "Verifica que la IP y el puerto sean correctos,\n"
	mensaje += "y que el host esté ejecutando el juego."
	
	# Limpiar conexión
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	GlobalSignal.error_conexion.emit(mensaje)

# ------------------------------------------------------------
# MANEJO DE PANTALLA DE CARGA
# ------------------------------------------------------------
func iniciar_carga_sincronizada(lista_peer_ids: Array) -> void:
	"""Se llama en todos los clientes cuando empieza la carga"""
	cargando = true
	total_jugadores = lista_peer_ids.size()
	jugadores_listos.clear()
	for id in lista_peer_ids:
		jugadores_listos[id] = false
	
	# Mostrar pantalla de carga
	_mostrar_pantalla_carga(lista_peer_ids)
	
	# Cada cliente comienza a cargar el mundo
	_cargar_mundo_local()

func _mostrar_pantalla_carga(lista_peer_ids: Array) -> void:
	if pantalla_carga_actual and is_instance_valid(pantalla_carga_actual):
		pantalla_carga_actual.queue_free()
	
	pantalla_carga_actual = PANTALLA_CARGA.instantiate()
	get_tree().current_scene.add_child(pantalla_carga_actual)
	pantalla_carga_actual.configurar_jugadores(lista_peer_ids)

func _cargar_mundo_local() -> void: # cada usuario carga su mundo
	var main_menu = get_tree().current_scene
	var MUNDO = load("uid://yubh30707eb7")
	
	# Instanciar mundo si no existe
	var mundo_existente = obtener_mundo_actual()
	if not mundo_existente:
		# liberar el mundo temporal del menu:
		var temp = main_menu.get_node_or_null("MundoTemporal")
		if temp and is_instance_valid(temp):
			# Desactivar la cámara del menú primero
			var cam = temp.get_node_or_null("Camera3D")
			if cam:
				cam.current = false
			temp.queue_free()
			await get_tree().process_frame
	
		var nuevo_mundo = MUNDO.instantiate()
		nuevo_mundo.name = "Mundo"
		nuevo_mundo.add_to_group("mundo")
		get_tree().current_scene.add_child(nuevo_mundo)
		
		# Esperar un frame para que el mundo esté listo
		await get_tree().process_frame
		await get_tree().process_frame
	# una vez que el mundo está cargado, avisar al host que estamos listos
	notificar_listo()

func notificar_listo() -> void:
	"""Cada cliente avisa al host que terminó de cargar"""
	var mi_id = multiplayer.get_unique_id()
	if mi_id == 0:
		mi_id = 1
	
	if multiplayer.is_server():
		# Si soy host, me marco listo localmente
		_marcar_jugador_listo(mi_id)
		# Y también aviso (por consistencia)
		_jugador_listo_rpc.rpc_id(1, mi_id)
	else:
		# Cliente avisa al host
		_jugador_listo_rpc.rpc_id(1, mi_id)

func _marcar_jugador_listo(peer_id: int) -> void:
	jugadores_listos[peer_id] = true
	
	# Actualizar la pantalla de carga local (host)
	if pantalla_carga_actual and is_instance_valid(pantalla_carga_actual):
		pantalla_carga_actual.marcar_jugador_listo(peer_id)
	
	# Notificar a TODOS los clientes del nuevo estado
	_actualizar_estado_carga_rpc.rpc(peer_id)
	
	# Comprobar si todos están listos
	_comprobar_todos_listos()

func _comprobar_todos_listos() -> void:
	if not multiplayer.is_server():
		return
	
	var todos_listos = true
	for peer_id in jugadores_listos.keys():
		if not jugadores_listos[peer_id]:
			todos_listos = false
			break
	
	if todos_listos:
		print("¡TODOS LISTOS! Arrancando partida...")
		# Dar la orden de arrancar a todos
		_arrancar_partida_rpc.rpc()
		
# ------------------------------------------------------------
# RPC PARA SINCRONIZAR JUGADORES
# ------------------------------------------------------------
@rpc("authority", "call_local", "reliable")
func _actualizar_estado_carga_rpc(peer_id: int) -> void:
	"""Todos los clientes actualizan su pantalla de carga"""
	if pantalla_carga_actual and is_instance_valid(pantalla_carga_actual):
		pantalla_carga_actual.marcar_jugador_listo(peer_id)

@rpc("authority", "call_local", "reliable")
func _arrancar_partida_rpc() -> void:
	"""Todos arrancan la partida al mismo tiempo"""
	cargando = false
	
	# Ocultar pantalla de carga
	if pantalla_carga_actual and is_instance_valid(pantalla_carga_actual):
		pantalla_carga_actual.queue_free()
	pantalla_carga_actual = null
	
	# El host crea los jugadores en el mundo
	if multiplayer.is_server():
		crear_todos_los_jugadores()
	
		
@rpc("any_peer", "reliable")
func _jugador_listo_rpc(peer_id: int) -> void:
	"""El host recibe el aviso de que un cliente terminó de cargar"""
	if not multiplayer.is_server():
		return
	
	print("Host recibió: jugador ", peer_id, " está listo")
	_marcar_jugador_listo(peer_id)

@rpc("authority", "call_local", "reliable")
func spawnear_jugador_rpc(peer_id: int, nombre: String, posicion: Vector3):
	
	var mundo = obtener_mundo_actual()
	if not mundo:
		return
	
	for child in mundo.get_children():
		if child.name == str(peer_id): # verificar si ya exisste el jugador en el mundo
			return
	
	var jugador = PLAYER.instantiate()
	jugador.name = str(peer_id)
	jugador.position = posicion
	jugador.set_multiplayer_authority(peer_id)

	mundo.add_child(jugador, true)
	
	#var nameplate = jugador.get_node_or_null("Nameplate")
	#if nameplate:
		#nameplate.text = nombre
	
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


# ------------------------------------------------------------
# PAUSA MULTIJUGADOR
# ------------------------------------------------------------
@rpc("any_peer", "call_local", "reliable")
func solicitar_pausa(activar: bool) -> void: # CUALQUIERO PERSONA PUEDE PAUSAR PERO SOLO ESA MISMA PERSONA PUEDE DESPAUSAR
	var peer_solicitante = multiplayer.get_remote_sender_id()
	if peer_solicitante == 0:
		peer_solicitante = multiplayer.get_unique_id()  # si es local
	
	print("Solicitud de pausa: activar=", activar, " de peer=", peer_solicitante)
	
	# Solo el host valida y distribuye
	if not multiplayer.is_server():
		return
	
	if activar:
		# Si ya está pausado, no hacer nada (evitar doble pausa)
		if pausa_activa:
			return
		
		pausa_activa = true
		peer_que_pauso = peer_solicitante
		_aplicar_pausa.rpc(true, peer_solicitante)
	else:
		# Solo quien pausó puede despausar
		if not pausa_activa:
			return
		if peer_solicitante != peer_que_pauso:
			print("Peer ", peer_solicitante, " intentó despausar pero no es quien pausó (", peer_que_pauso, ")")
			return
		
		pausa_activa = false
		peer_que_pauso = 0
		_aplicar_pausa.rpc(false, 0)

@rpc("authority", "call_local", "reliable")
func _aplicar_pausa(activar: bool, quien_pauso: int) -> void: # el host autoriza la pausa o despausa y actualiza a todos
	print("Aplicando pausa: ", activar, " por peer ", quien_pauso)
	
	pausa_activa = activar
	peer_que_pauso = quien_pauso
	
	# Notificar a la UI
	GlobalSignal.pausa_cambiada.emit(activar, quien_pauso)
	get_tree().paused = activar
