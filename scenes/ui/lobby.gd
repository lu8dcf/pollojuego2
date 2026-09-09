extends CanvasLayer

@onready var label_id: Label = %LabelId
@onready var margin_contenedor_jugadores: MarginContainer = %MarginContenedorJugadores
@onready var h_box_jugadores: HBoxContainer = %HBoxJugadores
const PANEL_JUGADOR = preload("uid://b4gmxx0tqmgc4")
@onready var label_estado: Label = %LabelEstado
@onready var boton_empezar: Button = $Button

var jugadores_en_lobby: Dictionary = {}  # peer_id -> {nombre: String, panel: Node, listo: bool}
var es_host: bool = false
var lobby_inicializado: bool = false

signal partida_iniciada

func _ready() -> void:
	add_to_group("lobby")
	
	print("=== LOBBY INICIADO ===")
	print("Mi peer_id: ", multiplayer.get_unique_id())
	print("¿Soy servidor?: ", multiplayer.is_server())
	
	if Network:
		Network.tube_client.session_created.connect(_on_session_created)
	
	multiplayer.peer_connected.connect(_on_jugador_conectado)
	multiplayer.peer_disconnected.connect(_on_jugador_desconectado)
	
	es_host = multiplayer.is_server()
	
	if boton_empezar:
		boton_empezar.visible = es_host  # Solo el host ve el botón
		if not boton_empezar.pressed.is_connected(_on_iniciar_partida_pressed):
			boton_empezar.pressed.connect(_on_iniciar_partida_pressed)
		boton_empezar.disabled = true
		boton_empezar.text = "Esperando jugadores..."
	
	mostrar_usuarios()
	
	if es_host:
		_agregar_jugador_al_lobby(1, _obtener_nombre_jugador())
	else:
		_agregar_jugador_al_lobby(multiplayer.get_unique_id(), _obtener_nombre_jugador())
		await get_tree().create_timer(0.5).timeout
		_solicitar_info_jugadores.rpc_id(1)
	
	lobby_inicializado = true

func _obtener_nombre_jugador() -> String:
	if GlobalJuego.nombre_jugador != "":
		return GlobalJuego.nombre_jugador
	elif es_host:
		return "Host"
	else:
		return "Jugador " + str(multiplayer.get_unique_id())

func mostrar_usuarios():
	if not lobby_inicializado:
		if GlobalJuego.un_jugador:
			label_id.hide()
			if boton_empezar:
				boton_empezar.visible = true
				boton_empezar.disabled = false
		else:
			label_id.text = "ID: " + Network.tube_client.session_id

func _on_session_created():
	print("Sesión creada, configurando lobby...")
	es_host = true
	
	if boton_empezar:
		boton_empezar.visible = true
		boton_empezar.disabled = true
		boton_empezar.text = "Esperando jugadores..."
	
	if not jugadores_en_lobby.has(1):
		_agregar_jugador_al_lobby(1, _obtener_nombre_jugador())
	
	if not GlobalJuego.session_info.has(1):
		GlobalJuego.session_info[1] = {
			"score": 0,
			"username": _obtener_nombre_jugador(),
			"salud": GlobalJuego.SALUD_DEFAULT
		}
	
	lobby_inicializado = true

func _on_jugador_conectado(peer_id: int):
	print("Jugador conectado: ", peer_id)
	
	if peer_id == 1 or peer_id == multiplayer.get_unique_id():
		return
	
	await get_tree().create_timer(0.5).timeout
	
	if es_host:
		print("Host pide info al jugador: ", peer_id)
		_solicitar_info_jugador.rpc_id(peer_id)

func _on_jugador_desconectado(peer_id: int):
	print("Jugador desconectado: ", peer_id)
	
	if jugadores_en_lobby.has(peer_id):
		var info = jugadores_en_lobby[peer_id]
		var panel = info.get("panel")
		if panel and is_instance_valid(panel):
			panel.queue_free()
		jugadores_en_lobby.erase(peer_id)
	
	_actualizar_estado_lobby()

func _agregar_jugador_al_lobby(peer_id: int, nombre: String):
	if nombre == "":
		nombre = "Jugador " + str(peer_id)
	
	print("Intentando agregar jugador - peer_id: ", peer_id, " nombre: ", nombre)
	
	if jugadores_en_lobby.has(peer_id):
		var info_existente = jugadores_en_lobby[peer_id]
		var panel_existente = info_existente.get("panel")
		
		if panel_existente and is_instance_valid(panel_existente):
			_actualizar_panel(panel_existente, peer_id, nombre, info_existente.get("listo", false))
			
			jugadores_en_lobby[peer_id] = {
				"nombre": nombre,
				"panel": panel_existente,
				"listo": info_existente.get("listo", false)
			}
			
			_actualizar_estado_lobby()
			return
	
	var panel_jugador = PANEL_JUGADOR.instantiate()
	
	h_box_jugadores.add_child(panel_jugador)
	
	await get_tree().process_frame
	
	_actualizar_panel(panel_jugador, peer_id, nombre, false)
	
	jugadores_en_lobby[peer_id] = {
		"nombre": nombre,
		"panel": panel_jugador,
		"listo": false
	}
	
	_actualizar_estado_lobby()
	
	print("Jugador agregado al lobby: ", peer_id, " - ", nombre, " - Total: ", jugadores_en_lobby.size())
	print("Jugadores en lobby: ", jugadores_en_lobby.keys())

func _actualizar_panel(panel: Node, peer_id: int, nombre: String, listo: bool = false):
	if panel.has_method("actualizar_info"):
		panel.actualizar_info(peer_id, nombre)
		# También actualizar el estado listo
		if panel.has_method("actualizar_estado_listo"):
			panel.actualizar_estado_listo(listo)

func actualizar_estado_listo(peer_id_jugador: int, estado: bool):
	"""Actualiza el estado de listo de un jugador"""
	print("Actualizando estado listo - Jugador: ", peer_id_jugador, " Listo: ", estado)
	
	if jugadores_en_lobby.has(peer_id_jugador):
		var info = jugadores_en_lobby[peer_id_jugador]
		info["listo"] = estado
		jugadores_en_lobby[peer_id_jugador] = info
		
		# Actualizar visualmente el panel
		var panel = info.get("panel")
		if panel and is_instance_valid(panel):
			if panel.has_method("actualizar_estado_listo"):
				panel.actualizar_estado_listo(estado)
		
		# Si somos host, reenviar a todos
		if es_host:
			_replicar_estado_listo.rpc(peer_id_jugador, estado)
		
		_actualizar_estado_lobby()
		_verificar_todos_listos()

@rpc("authority", "call_local", "reliable")
func _replicar_estado_listo(peer_id_jugador: int, estado: bool):
	"""Replica el estado de listo a todos los clientes"""
	print("Replicando estado listo - Jugador: ", peer_id_jugador, " Listo: ", estado)
	
	if jugadores_en_lobby.has(peer_id_jugador):
		var info = jugadores_en_lobby[peer_id_jugador]
		info["listo"] = estado
		jugadores_en_lobby[peer_id_jugador] = info
		
		var panel = info.get("panel")
		if panel and is_instance_valid(panel):
			if panel.has_method("actualizar_estado_listo"):
				panel.actualizar_estado_listo(estado)
		
		_actualizar_estado_lobby()
		_verificar_todos_listos()

func _verificar_todos_listos():
	"""Verifica si todos los jugadores están listos"""
	if not es_host:
		return
	
	var todos_listos = true
	var num_jugadores = jugadores_en_lobby.size()
	
	if num_jugadores < 2:
		todos_listos = false
	
	for peer_id in jugadores_en_lobby.keys():
		var info = jugadores_en_lobby[peer_id]
		if not info.get("listo", false):
			todos_listos = false
			break
	
	if boton_empezar:
		if todos_listos:
			boton_empezar.disabled = false
			boton_empezar.text = "¡Comenzar partida!"
			boton_empezar.modulate = Color.GREEN
		else:
			boton_empezar.disabled = true
			boton_empezar.text = "Esperando jugadores..."
			boton_empezar.modulate = Color.WHITE
	
	if label_estado:
		if todos_listos:
			label_estado.text = "¡Todos listos! El host puede iniciar"
		else:
			var listos = 0
			for peer_id in jugadores_en_lobby.keys():
				if jugadores_en_lobby[peer_id].get("listo", false):
					listos += 1
			label_estado.text = "Listos: " + str(listos) + "/" + str(num_jugadores)

func _actualizar_estado_lobby():
	var num_jugadores = jugadores_en_lobby.size()
	
	if label_estado:
		if es_host:
			var listos = 0
			for peer_id in jugadores_en_lobby.keys():
				if jugadores_en_lobby[peer_id].get("listo", false):
					listos += 1
			
			label_estado.text = "Jugadores: " + str(num_jugadores) + "/4 | Listos: " + str(listos)
			
			if boton_empezar:
				_verificar_todos_listos()
		else:
			label_estado.text = "Esperando al host... (" + str(num_jugadores) + "/4)"
			
			# Los no-host no ven el botón
			if boton_empezar:
				boton_empezar.visible = false

func _on_iniciar_partida_pressed():
	print("Botón presionado - Host: ", es_host, " Jugadores: ", jugadores_en_lobby.size())
	
	if es_host and jugadores_en_lobby.size() >= 2:
		# Verificar que todos estén listos
		var todos_listos = true
		for peer_id in jugadores_en_lobby.keys():
			if not jugadores_en_lobby[peer_id].get("listo", false):
				todos_listos = false
				break
		
		if todos_listos:
			print("Iniciando partida con ", jugadores_en_lobby.size(), " jugadores")
			_iniciar_partida.rpc()
		else:
			print("No todos están listos")

@rpc("authority", "call_local", "reliable")
func _iniciar_partida():
	_comenzar_partida()

func _comenzar_partida():
	print("¡Comenzando partida!")
	if Network and Network.has_method("iniciar_partida_desde_lobby"):
		Network.iniciar_partida_desde_lobby()
	
	partida_iniciada.emit()
	hide()

@rpc("any_peer", "call_local", "reliable")
func _solicitar_info_jugador():
	var solicitante_id = multiplayer.get_remote_sender_id()
	var mi_id = multiplayer.get_unique_id()
	var nombre = _obtener_nombre_jugador()
	
	print("Jugador ", mi_id, " responde a solicitud del host: ", nombre)
	
	_enviar_info_jugador.rpc_id(solicitante_id, mi_id, nombre)

@rpc("any_peer", "call_local", "reliable")
func _enviar_info_jugador(peer_id: int, nombre: String):
	print("Recibida info de jugador: ", peer_id, " - ", nombre)
	
	if peer_id == 1 and es_host:
		return
	
	if peer_id == 1 and not es_host:
		_agregar_jugador_al_lobby(peer_id, nombre)
		return
	
	_agregar_jugador_al_lobby(peer_id, nombre)
	
	if not GlobalJuego.session_info.has(peer_id):
		GlobalJuego.session_info[peer_id] = {
			"score": 0,
			"username": nombre,
			"salud": GlobalJuego.SALUD_DEFAULT
		}
	
	if es_host and peer_id != 1:
		for jugador_id in jugadores_en_lobby.keys():
			if jugador_id != peer_id and jugador_id != 1 and jugador_id != multiplayer.get_unique_id():
				print("Host reenvía info de ", peer_id, " a ", jugador_id)
				_enviar_info_jugador.rpc_id(jugador_id, peer_id, nombre)

@rpc("any_peer", "call_local", "reliable")
func _solicitar_info_jugadores():
	if es_host:
		var solicitante_id = multiplayer.get_remote_sender_id()
		print("Jugador ", solicitante_id, " solicita info de todos")
		
		if jugadores_en_lobby.has(1):
			var info_host = jugadores_en_lobby[1]
			var nombre_host = info_host.get("nombre", "Host")
			print("Enviando info del host al solicitante: 1 - ", nombre_host)
			_enviar_info_jugador.rpc_id(solicitante_id, 1, nombre_host)
		
		for peer_id in jugadores_en_lobby.keys():
			if peer_id != 1 and peer_id != solicitante_id:
				var info = jugadores_en_lobby[peer_id]
				var nombre = info.get("nombre", "Jugador " + str(peer_id))
				print("Enviando info de jugador al solicitante: ", peer_id, " - ", nombre)
				_enviar_info_jugador.rpc_id(solicitante_id, peer_id, nombre)

func _on_regresar_boton_pressed() -> void:
	if Network:
		Network.leave_server()
	else:
		get_tree().reload_current_scene()
