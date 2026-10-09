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

# chat
@onready var chat_input: TextEdit = %ChatInput
@onready var chat_historial: RichTextLabel = %ChatHistorial
@onready var chat_enviar: Button = %ChatEnviar
 # paleta de colores para los peers. se elige por hash del peer_id
# para que sea deterministica: mismo peer = mismo color en todos los clientes.
const COLORES_PEER: Array[Color] = [
	Color("#ff6b6b"),  # rojo
	Color("#4ecdc4"),  # turquesa
	Color("#ffe66d"),  # amarillo
	Color("#a29bfe"),  # violeta
	Color("#55efc4"),  # verde menta
	Color("#fd79a8"),  # rosa
	Color("#74b9ff"),  # celeste
	Color("#fab1a0"),  # salmon
]

# color del host (peer_id == 1) siempre destacado
const COLOR_HOST := Color("#ffd166")
# color de los mensajes de sistema
const COLOR_SISTEMA := Color("#ff5555")
# color del texto en si (el cuerpo del mensaje)
const COLOR_TEXTO := Color("#e0e0e0")


var jugadores_en_lobby: Dictionary = {}  # peer_id -> {nombre: String, panel: Node, listo: bool}
var es_host: bool = false
var lobby_inicializado: bool = false
var partida_iniciada_flag: bool = false

# para saber que pollo esta ya seleccionado
var pollos_asignados: Dictionary = {}

# conjunto inverso para saber rapido si un pollo ya esta tomado
# pollo_id -> peer_id
var pollos_tomados: Dictionary = {}

signal partida_iniciada

func _ready() -> void:
	add_to_group("lobby")
	
	if GlobalJuego.un_jugador:
		_inicilizar_un_jugador()
		return
	
	# APARTADO DE MULTIJUGADOR
	multiplayer.peer_connected.connect(_on_jugador_conectado)
	multiplayer.peer_disconnected.connect(_on_jugador_desconectado)
	multiplayer.server_disconnected.connect(_on_host_desconectado_lobby)

	es_host = multiplayer.is_server()
	if not GlobalJuego.un_jugador:
		if boton_empezar:
			boton_empezar.visible = es_host  # solo el host ve el botón
			if not boton_empezar.pressed.is_connected(_on_iniciar_partida_pressed):
				boton_empezar.pressed.connect(_on_iniciar_partida_pressed)
			boton_empezar.disabled = true
			boton_empezar.cambiar_texto("Esperando jugadores...")
	
	mostrar_usuarios()
	
	if es_host :
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
		Network._solicitar_info_jugadores.rpc_id(1)
		_enviar_mi_info_al_host()
	
	lobby_inicializado = true
	if GlobalJuego.un_jugador:
		chat_input.visible = false
		chat_enviar.visible = false
		
	if chat_enviar and not GlobalJuego.un_jugador:
		chat_enviar.pressed.connect(_on_chat_enviar_pressed)
	
# UN SOLO JUGADOR
func _inicilizar_un_jugador() -> void:
	es_host = true
	
	if boton_empezar:
		label_estado.visible = false
		boton_empezar.visible = true
		boton_empezar.disabled = false
		boton_empezar.cambiar_texto("Comenzar Partida")
		boton_empezar.modulate  =Color.GREEN
		if not boton_empezar.pressed.is_connected(_on_iniciar_partida_pressed):
			boton_empezar.pressed.connect(_on_iniciar_partida_pressed)
			
	label_id.hide()
	label_ip.hide()
	label_puerto.hide()
	
	# agregar al jugador local
	_agregar_jugador_al_lobby(1, _obtener_nombre_jugador())
	if not GlobalJuego.session_info.has(1):
		GlobalJuego.session_info[1] = {
			"score": 0,
			"username": _obtener_nombre_jugador(),
			"salud": GlobalJuego.SALUD_DEFAULT,
			"personaje": 1,
			"ping": 0,
			"inventario": [],
			"armas_actuales": []
		}
	
	lobby_inicializado = true

func _obtener_nombre_jugador() -> String:
	return GlobalJuego.nombre_jugador

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
					label_ip.show()
					label_puerto.show()
					if label_ip: label_ip.text = "IP: "+Network.ip_local
					if label_puerto: label_puerto.text = "Puerto: " + str(Network.puerto_actual)
			else:
				label_id.show()
				label_id.text = "ID: " + Network.tube_client.session_id
				if label_ip: label_ip.text = ""
				if label_puerto: label_puerto.text = ""
				

func _on_jugador_conectado(peer_id: int): #245698
	
	if peer_id == 1 or peer_id == multiplayer.get_unique_id():
		return
	
	await get_tree().create_timer(1.5).timeout
	
	if jugadores_en_lobby.size() > 4:
		Network._error_lobby_lleno.rpc_id(peer_id)
		# desconectar al cliente después de un momento
		await get_tree().create_timer(0.5).timeout
		multiplayer.multiplayer_peer.disconnect_peer(peer_id)
		return
		
	#if es_host:
		#_solicitar_info_jugador.rpc_id(peer_id)
		#_enviar_estado_actual_a_cliente(peer_id)

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

func _enviar_mi_info_al_host() :
	var mi_id = multiplayer.get_unique_id()
	
	var mi_info = GlobalJuego.session_info.get(mi_id, {})
	if mi_info.is_empty():
		mi_info = {
			"username": _obtener_nombre_jugador(),
			"personaje": 1,
			"listo": false,
			"score": 0,
			"salud": GlobalJuego.SALUD_DEFAULT,
			"ping": 0,
			"inventario": [],
			"armas_actuales": [0, 0]
		}
	
	Network._enviar_info_jugador.rpc_id(1, mi_id, mi_info)

func _actualizar_panel(panel: Node, peer_id: int, nombre: String, listo: bool = false,personaje:int = 1):
	if panel.has_method("actualizar_info"):
		panel.actualizar_info(peer_id, nombre,personaje)
		# También actualizar el estado listo
		if panel.has_method("actualizar_estado_listo"):
			panel.actualizar_estado_listo(listo)

func actualizar_estado_listo(peer_id_jugador: int, estado: bool):
	_procesar_estado_listo(peer_id_jugador,estado)
	#if jugadores_en_lobby.has(peer_id_jugador):
		#var info = jugadores_en_lobby[peer_id_jugador]
		#info["listo"] = estado
		#jugadores_en_lobby[peer_id_jugador] = info
		#
		## Actualizar visualmente el panel
		#var panel = info.get("panel")
		#if panel and is_instance_valid(panel):
			#if panel.has_method("actualizar_estado_listo"):
				#panel.actualizar_estado_listo(estado)
		#
		# Si somos host, reenviar a todos
	if es_host:
		Network._replicar_estado_listo.rpc(peer_id_jugador, estado)
		
		#_actualizar_estado_lobby()
		#_verificar_todos_listos()


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
	
	if label_estado and not GlobalJuego.un_jugador:
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
	if GlobalJuego.un_jugador:
		_comenzar_partida_un_jugador()
		return
		
	
	if es_host and jugadores_en_lobby.size() >= 2:
		var todos_listos = true
		for peer_id in jugadores_en_lobby.keys():
			if not jugadores_en_lobby[peer_id].get("listo", false):
				todos_listos = false
				break
		
		if todos_listos:
			Network._iniciar_carga.rpc()
	

# ============================================================
# SELECCION DE POLLO 
# ============================================================
func seleccionar_pollo(id_pollo:int) ->void:
	pass

# avisar del cambio de personaje, cuando un usuario cambia su eprsonaje, avisa al host para que todos actualicen
func notificar_cambio_personaje_arma(peer_id_jugador: int, id_personaje: int,id_arma:int):
	_procesar_cambio_personaje_arma(peer_id_jugador,id_personaje,id_arma) # primero procesar localmente
	Network._sincronizar_cambio_personaje_arma.rpc(peer_id_jugador, id_personaje,id_arma) # y despues procesar a los demas jugadores
	
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
			"personaje": (id_personaje-1),
			"ping": 0,
			"inventario": [id_arma],  # primera arma
			"armas_actuales":[id_arma,0], # si es cero es que no hay arma en esa mano
			"listo" :false
		}
	else:
		var info_peer = GlobalJuego.session_info[peer_id_jugador] # obtener la data del usuario
		info_peer["personaje"] = (id_personaje-1)
		
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
	
func _comenzar_partida_un_jugador():
	if partida_iniciada_flag:
		return
	partida_iniciada_flag = true
	
	partida_iniciada.emit()
	hide()
	
	
	
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


# ============================================================
# CHAT 
# ============================================================
# devuelve un color estable para un peer_id dado.
# el host siempre usa COLOR_HOST; el resto rota por la paleta.
func _color_para_peer(peer_id:int)->Color:
	if peer_id == 1:
		return COLOR_HOST
		 # indice estable basado en el peer_id (no en el orden de la lista)
	var indice:int = abs(peer_id)%COLORES_PEER.size()
	return COLORES_PEER[indice]


func _on_chat_enviar_pressed()->void:
	
	if not chat_input:
		return
	var texto := chat_input.text.strip_edges()
	if texto == "":
		return

	chat_input.text = ""
	
	# mandamos por rpc (el host lo reemite a todos)
	Network._enviar_mensaje_chat.rpc(texto)

func _recibir_mensaje_chat(nombre: String, texto: String, es_sistema: bool) -> void:
	if not chat_historial:
		return
	var color_nombre = "#ffd166"  # amarillo para host
	var color_texto := "#ffffff"
	
	if es_sistema:
		color_nombre = "#ff5555" # rojo para avisos
		color_texto = "#ff8888"
	elif nombre =="HOST":
		color_nombre = "#ffd166"
	chat_historial.append_text("[color=%s]%s:[/color] [color=%s]%s[/color]\n" % [
		color_nombre, nombre, color_texto, texto
	])


func _on_regresar_boton_pressed() -> void:
	if Network:
		Network.leave_server()
	else:
		get_tree().reload_current_scene()

# ============================================================
# FUNCIONES LLAMADAS POR NETWORK 
# ============================================================

func _procesar_info_jugador(peer_id: int, info_jugador: Dictionary):
	
	if peer_id == 1 and es_host:
		return
	
	var nombre = info_jugador.get("username", "Jugador " + str(peer_id))
	var personaje = info_jugador.get("personaje", 1)
	var listo = info_jugador.get("listo", false)
	var armas_actuales = info_jugador.get("armas_actuales", [1, 0])
	
	await _agregar_jugador_al_lobby(peer_id, nombre)
	
	if jugadores_en_lobby.has(peer_id):
		var info = jugadores_en_lobby[peer_id]
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
				if armas_actuales.size() > 0:
					panel.actualizar_arma_remoto(armas_actuales[0])
	
	if not GlobalJuego.session_info.has(peer_id):
		GlobalJuego.session_info[peer_id] = info_jugador
	else:
		for key in info_jugador.keys():
			GlobalJuego.session_info[peer_id][key] = info_jugador[key]
	
	# Reenviar a los demás
	if es_host and peer_id != 1:
		for jugador_id in jugadores_en_lobby.keys():
			if jugador_id != peer_id and jugador_id != 1 and jugador_id != multiplayer.get_unique_id():
				Network._enviar_info_jugador.rpc_id(jugador_id, peer_id, info_jugador)

func _responder_info_jugadores(solicitante_id: int):
	
	for peer_id in jugadores_en_lobby.keys():
		var info_lobby = jugadores_en_lobby[peer_id]
		var session_data = GlobalJuego.session_info.get(peer_id, {})
		
		var info_completa = {
			"username": session_data.get("username", info_lobby.get("nombre", "Jugador " + str(peer_id))),
			"personaje": session_data.get("personaje", info_lobby.get("personaje", 1)),
			"listo": info_lobby.get("listo", false),
			"score": session_data.get("score", 0),
			"salud": session_data.get("salud", GlobalJuego.SALUD_DEFAULT),
			"ping": session_data.get("ping", 0),
			"inventario": session_data.get("inventario", []),
			"armas_actuales": session_data.get("armas_actuales", [1, 0])
		}
		
		Network._enviar_info_jugador.rpc_id(solicitante_id, peer_id, info_completa)

func _procesar_estado_listo(peer_id_jugador: int, estado: bool):
	"""Procesa el cambio de estado listo de un jugador"""
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

func _procesar_cambio_personaje_arma(peer_id_jugador: int, id_personaje: int, id_arma: int):
	"""Procesa el cambio de personaje/arma de un jugador"""
	# Actualizar panel visual
	if jugadores_en_lobby.has(peer_id_jugador):
		var info = jugadores_en_lobby[peer_id_jugador]
		info["personaje"] = id_personaje
		info["arma"] = id_arma
		jugadores_en_lobby[peer_id_jugador] = info
		
		var panel = info.get("panel")
		if panel and is_instance_valid(panel):
			if panel.has_method("actualizar_personaje_remoto"):
				panel.actualizar_personaje_remoto(id_personaje)
			if panel.has_method("actualizar_arma_remoto"):
				panel.actualizar_arma_remoto(id_arma)
	
	# Actualizar session_info
	if not GlobalJuego.session_info.has(peer_id_jugador):
		if id_personaje == 0:
			id_personaje = 1
		GlobalJuego.session_info[peer_id_jugador] = {
			"score": 0,
			"username": "Jugador " + str(peer_id_jugador),
			"salud": GlobalJuego.SALUD_DEFAULT,
			"personaje": id_personaje,
			"ping": 0,
			"inventario": [id_arma],
			"armas_actuales": [id_arma, 0],
			"listo": false
		}
	else:
		var info_peer = GlobalJuego.session_info[peer_id_jugador]
		info_peer["personaje"] = id_personaje
		
		var armas_actuales: Array = info_peer.get("armas_actuales", [1, 0])
		if armas_actuales.is_empty():
			armas_actuales = [id_arma, 0]
		else:
			armas_actuales[0] = id_arma
		info_peer["armas_actuales"] = armas_actuales
		
		var inventario: Array = info_peer.get("inventario", [])
		if not id_arma in inventario and inventario.size() < 6:
			inventario.append(id_arma)
		info_peer["inventario"] = inventario
		
		GlobalJuego.session_info[peer_id_jugador] = info_peer

func _procesar_inicio_partida():
	"""Se llama cuando Network._iniciar_carga se dispara"""
	partida_iniciada.emit()
	hide()
