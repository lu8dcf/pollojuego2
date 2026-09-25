extends CanvasLayer

@onready var margin_contenedor_jugadores: MarginContainer = %MarginContenedorJugadores
@onready var h_box_jugadores: HBoxContainer = %HBoxJugadores
const PANEL_JUGADOR = preload("uid://b4gmxx0tqmgc4")
@onready var label_estado: Label = %LabelEstado
@onready var boton_empezar: TextureButtonAnimado = %BotonEmpezar

# vista de puerto e ip
@onready var label_id: Label = %LabelId
@onready var label_ip: Label = %LabelIp
@onready var label_puerto: Label = %LabelPuerto


var jugadores_en_lobby: Dictionary = {}  # peer_id -> {nombre: String, panel: Node, listo: bool}
var es_host: bool = false
var lobby_inicializado: bool = false
var partida_iniciada_flag: bool = false

signal partida_iniciada

func _ready() -> void:
	add_to_group("lobby")
	
	if Network:
		Network.tube_client.session_created.connect(_on_session_created)
	
	multiplayer.peer_connected.connect(_on_jugador_conectado)
	multiplayer.peer_disconnected.connect(_on_jugador_desconectado)
	multiplayer.server_disconnected.connect(_on_host_desconectado_lobby)

	es_host = multiplayer.is_server()
	
	if boton_empezar:
		boton_empezar.visible = es_host  # solo el host ve el botón
		if not boton_empezar.pressed.is_connected(_on_iniciar_partida_pressed):
			boton_empezar.pressed.connect(_on_iniciar_partida_pressed)
		boton_empezar.disabled = true
		boton_empezar.cambiar_texto("Esperando jugadores...")
	
	mostrar_usuarios()
	
	if es_host:
		_agregar_jugador_al_lobby(1, _obtener_nombre_jugador())
		if not GlobalJuego.session_info.has(1):
			GlobalJuego.session_info[1] = {
				"score": 0,
				"username": _obtener_nombre_jugador(),
				"salud": GlobalJuego.SALUD_DEFAULT,
				"personaje": 1,
				"ping":0,
				"inventario":[],
				"armas_actuales":[]
			}
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
	label_id.hide()
	label_ip.hide()
	label_puerto.hide()
	if not lobby_inicializado:
		if GlobalJuego.un_jugador:
			if boton_empezar:
				boton_empezar.visible = true
				boton_empezar.disabled = false
		else:
			if not Network.tube_enabled or Network.tube_client.session_id == "":
				if es_host:
					label_ip.show()
					label_puerto.show()
					if label_ip: label_ip.text = "IP: "+Network.ip_local
					if label_puerto: label_puerto.text = "Puerto: " + str(Network.puerto_actual)
				else:
					if label_ip: label_ip.text = ""
					if label_puerto: label_puerto.text = ""
			else:
				label_id.show()
				label_id.text = "ID: " + Network.tube_client.session_id
				if label_ip: label_ip.text = ""
				if label_puerto: label_puerto.text = ""
				

func _on_session_created():
	es_host = true
	
	if boton_empezar:
		boton_empezar.visible = true
		boton_empezar.disabled = true
		boton_empezar.cambiar_texto("Esperando jugadores...")
	
	if not jugadores_en_lobby.has(1):
		_agregar_jugador_al_lobby(1, _obtener_nombre_jugador())
	
	if not GlobalJuego.session_info.has(1):
		GlobalJuego.session_info[1] = {
			"score": 0,
			"username": _obtener_nombre_jugador(),
			"salud": GlobalJuego.SALUD_DEFAULT,
			"personaje":1,
			"ping":0,
			"inventario":[],
			"armas_actuales":[]
		}
	
	lobby_inicializado = true

func _on_jugador_conectado(peer_id: int): #245698
	
	if peer_id == 1 or peer_id == multiplayer.get_unique_id():
		return
	
	await get_tree().create_timer(0.5).timeout
	
	if es_host:
		_solicitar_info_jugador.rpc_id(peer_id)
		_enviar_estado_actual_a_cliente(peer_id)

func _enviar_estado_actual_a_cliente(nuevo_cliente_id: int):
	for peer_id in jugadores_en_lobby.keys():
		if peer_id == nuevo_cliente_id:
			continue  # su propia info ya la enviara él mismo
		
		var info_lobby = jugadores_en_lobby[peer_id]
		var info_completa = {
			"username": info_lobby.get("nombre", "Jugador " + str(peer_id)),
			"personaje": info_lobby.get("personaje", 1),
			"listo": info_lobby.get("listo", false),
			"score": GlobalJuego.session_info.get(peer_id, {}).get("score", 0),
			"salud": GlobalJuego.session_info.get(peer_id, {}).get("salud", GlobalJuego.SALUD_DEFAULT),
			"ping": GlobalJuego.session_info.get(peer_id, {}).get("ping",0),
			"inventario":GlobalJuego.session_info.get(peer_id, {}).get("inventario",[]),
			"armas_actuales":GlobalJuego.session_info.get(peer_id,{}).get("armas_actuales",[])
		}
		
		# enviar SOLO al nuevo cliente (no a todos)
		_enviar_info_jugador.rpc_id(nuevo_cliente_id, peer_id, info_completa)
		
func _on_jugador_desconectado(peer_id: int):
	
	if jugadores_en_lobby.has(peer_id):
		var info = jugadores_en_lobby[peer_id]
		var panel = info.get("panel")
		if panel and is_instance_valid(panel):
			panel.queue_free()
		jugadores_en_lobby.erase(peer_id)
	
	_actualizar_estado_lobby()

func _on_host_desconectado_lobby():
	
	if multiplayer.is_server():
		return
	
	# Limpiar y volver al menú
	if Network:
		Network._volver_al_menu_por_desconexion_host()
	else:
		get_tree().reload_current_scene()

func _agregar_jugador_al_lobby(peer_id: int, nombre: String):
	if nombre == "":
		nombre = "Jugador " + str(peer_id)
	
	
	if jugadores_en_lobby.has(peer_id):
		var info_existente = jugadores_en_lobby[peer_id]
		var panel_existente = info_existente.get("panel")
		
		if panel_existente and is_instance_valid(panel_existente):
			_actualizar_panel(panel_existente,
			 peer_id,
			 nombre,
			 info_existente.get("listo", false),
			 info_existente.get("personaje",1)
			)
			
			jugadores_en_lobby[peer_id] = {
				"nombre": nombre,
				"panel": panel_existente,
				"listo": info_existente.get("listo", false),
			 	"personaje":info_existente.get("personaje",1)
			}
			
			_actualizar_estado_lobby()
			return
	# si el jugador no existe, se crea un panel apra ese jugador
	var panel_jugador = PANEL_JUGADOR.instantiate()
	h_box_jugadores.add_child(panel_jugador)
	
	await get_tree().process_frame
	
	_actualizar_panel(panel_jugador, peer_id, nombre, false,1)
	
	jugadores_en_lobby[peer_id] = {
		"nombre": nombre,
		"panel": panel_jugador,
		"listo": false,
		"personaje":1
	}
	
	_actualizar_estado_lobby()
	
func _actualizar_panel(panel: Node, peer_id: int, nombre: String, listo: bool = false,personaje:int = 1):
	if panel.has_method("actualizar_info"):
		panel.actualizar_info(peer_id, nombre,personaje)
		# También actualizar el estado listo
		if panel.has_method("actualizar_estado_listo"):
			panel.actualizar_estado_listo(listo)

func actualizar_estado_listo(peer_id_jugador: int, estado: bool):
	
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
			boton_empezar.cambiar_texto("¡Comenzar partida!")
			boton_empezar.modulate = Color.GREEN
		else:
			boton_empezar.disabled = true
			boton_empezar.cambiar_texto("Esperando jugadores...")
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
	if es_host and jugadores_en_lobby.size() >= 2:
		var todos_listos = true
		for peer_id in jugadores_en_lobby.keys():
			if not jugadores_en_lobby[peer_id].get("listo", false):
				todos_listos = false
				break
		
		if todos_listos:
			_iniciar_carga.rpc()

@rpc("authority", "call_local", "reliable")
func _iniciar_carga():
	# Cambiar Network a modo partida
	if Network and Network.has_method("iniciar_partida_desde_lobby"):
		Network.iniciar_partida_desde_lobby()
	
	# Emitir la señal para que main_menu libere su mundo
	partida_iniciada.emit()
	hide()
	
	# Esperar un frame a que el main_menu libere su temp_mundo
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Ahora todos empiezan la carga sincronizada
	if Network and Network.has_method("iniciar_carga_sincronizada"):
		Network.iniciar_carga_sincronizada(GlobalJuego.session_info.keys())

# avisar del cambio de personaje, cuando un usuario cambia su eprsonaje, avisa al host para que todos actualicen
func notificar_cambio_personaje_arma(peer_id_jugador: int, id_personaje: int,id_arma:int):
	_sincronizar_cambio_personaje_arma(peer_id_jugador, id_personaje,id_arma)
	# enviar RPC a todos
	_sincronizar_cambio_personaje_arma.rpc(peer_id_jugador, id_personaje,id_arma)


@rpc("any_peer", "call_local", "reliable")
func _sincronizar_cambio_personaje_arma(peer_id_jugador: int, id_personaje: int,id_arma:int):
	"""Sincroniza el cambio de personaje a todos los clientes"""
	_aplicar_cambio_personaje_arma(peer_id_jugador, id_personaje,id_arma)

func _aplicar_cambio_personaje_arma(peer_id_jugador: int, id_personaje: int,id_arma:int): 
	# esto es solo un panel visual
	if jugadores_en_lobby.has(peer_id_jugador):
		var info = jugadores_en_lobby[peer_id_jugador]
		info["personaje"] = id_personaje
		info["arma"]= id_arma
		jugadores_en_lobby[peer_id_jugador] = info
		
		var panel = info.get("panel")
		if panel and is_instance_valid(panel):
			if panel.has_method("actualizar_personaje_remoto"):
				panel.actualizar_personaje_remoto(id_personaje)
			if panel.has_method("actualizar_arma_remoto"):
				panel.actualizar_arma_remoto(id_arma)
	
	if not GlobalJuego.session_info.has(peer_id_jugador):
		if id_personaje==0:
			id_personaje=1
		GlobalJuego.session_info[peer_id_jugador] = {
			"score": 0,
			"username": "Jugador " + str(peer_id_jugador),
			"salud": GlobalJuego.SALUD_DEFAULT,
			"personaje": id_personaje,
			"ping": 0,
			"inventario": [id_arma],  # primera arma
			"armas_actuales":[id_arma,0], # si es cero es que no hay arma en esa mano
			"listo" :false
		}
	else:
		var info_peer = GlobalJuego.session_info[peer_id_jugador] # obtener la data del usuario
		info_peer["personaje"] = id_personaje
		
		# agregar arma al inventario si no está ya
		var armas_actuales :Array = info_peer.get("armas_actuales",[1,0])
		if armas_actuales.is_empty():
			armas_actuales = [id_arma,0]
		else:
			armas_actuales[0] = id_arma
		info_peer["armas_actuales"] = armas_actuales
		
		var inventario: Array = info_peer.get("inventario", [])
		if not id_arma in inventario and inventario.size()<6:
			inventario.append(id_arma)
		info_peer["inventario"] = inventario
				
		GlobalJuego.session_info[peer_id_jugador]= info_peer
	
	# a futuro
	## guardar armas que se estan usando, suelen ser 2, lista de dos armas
	

@rpc("authority", "call_local", "reliable")
func _iniciar_partida():
	_comenzar_partida()

func _comenzar_partida():
	if partida_iniciada_flag:
		return
	partida_iniciada_flag = true
		
	# Cambiar Network a modo partida
	if Network and Network.has_method("iniciar_partida_desde_lobby"):
		Network.iniciar_partida_desde_lobby()
	
	# Emitir señal SOLAMENTE
	partida_iniciada.emit()
	hide()

@rpc("any_peer", "call_local", "reliable")
func _solicitar_info_jugador():
	var solicitante_id = multiplayer.get_remote_sender_id()
	var mi_id = multiplayer.get_unique_id()
	
	var mi_info = GlobalJuego.session_info.get(mi_id, {})
	if mi_info.is_empty():
		mi_info = {
			"username": _obtener_nombre_jugador(),
			"personaje": 1,
			"listo": false,
			"score": 0,
			"salud": GlobalJuego.SALUD_DEFAULT,
			"ping":0
		}
	
	_enviar_info_jugador.rpc_id(solicitante_id, mi_id, mi_info)

@rpc("any_peer", "call_local", "reliable")
func _enviar_info_jugador(peer_id: int, info_jugador: Dictionary):	
	if peer_id == 1 and es_host:
		return
	var nombre = info_jugador.get("username","Jugador " +str(peer_id))
	var personaje = info_jugador.get("personaje",1)
	var listo= info_jugador.get("listo",false)
	var armas_actuales= info_jugador.get("armas_actuales",[1,0])
	
	_agregar_jugador_al_lobby(peer_id,nombre)
	
	if jugadores_en_lobby.has(peer_id):
		var info = jugadores_en_lobby[peer_id] # se obtiene la info de cada jugadro
		info["personaje"] = personaje
		info["listo"] = listo
		jugadores_en_lobby[peer_id] = info
		
		var panel = info.get("panel")
		if panel and is_instance_valid(panel):
			if panel.has_method("actualizar_personaje_remoto"):
				panel.actualizar_personaje_remoto(personaje)
			if panel.has_method("actualizar_estado_listo"):
				panel.actualizar_estado_listo(listo)
			if panel.has_method("actualizar_arma_remoto"):
				if armas_actuales.size()>0:
					panel.actualizar_arma_remoto(armas_actuales[0])
		
	if not GlobalJuego.session_info.has(peer_id):
		GlobalJuego.session_info[peer_id] = info_jugador
	else:
		for key in info_jugador.keys(): # combinacion de todos los clave valor de l dict session_info
			GlobalJuego.session_info[peer_id][key] = info_jugador[key]
	
	if es_host and peer_id != 1:
		for jugador_id in jugadores_en_lobby.keys():
			if jugador_id != peer_id and jugador_id != 1 and jugador_id != multiplayer.get_unique_id():
				_enviar_info_jugador.rpc_id(jugador_id, peer_id, nombre)

@rpc("any_peer", "call_local", "reliable")
func _solicitar_info_jugadores():
	if not es_host:
		return
	
	var solicitante_id = multiplayer.get_remote_sender_id()
	
	# eenviar info completa de CADA jugador en el lobby
	for peer_id in jugadores_en_lobby.keys():
		var info_lobby = jugadores_en_lobby[peer_id]
		var session_panel = GlobalJuego.session_info.get(peer_id,{})
		
		# construir info completa y despues pasarla
		var info_completa = {
			"username": info_lobby.get("nombre", "Jugador " + str(peer_id)),
			"personaje": info_lobby.get("personaje", 1),
			"listo": info_lobby.get("listo", false),
			"score": session_panel.get(peer_id, {}).get("score", 0),
			"salud": session_panel.get(peer_id, {}).get("salud", GlobalJuego.SALUD_DEFAULT),
			"ping": session_panel.get(peer_id, {}).get("ping", 0),
			"inventario":session_panel.get(peer_id, {}).get("inventario", []),
			"armas_actuales": session_panel.get("armas_actuales", [1, 0])
		}
		
		_enviar_info_jugador.rpc_id(solicitante_id, peer_id, info_completa)
		
func _on_regresar_boton_pressed() -> void:
	if Network:
		Network.leave_server()
	else:
		get_tree().reload_current_scene()
